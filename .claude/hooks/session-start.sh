#!/usr/bin/env bash
# SessionStart hook (Claude Code + Codex): deterministically inject the context system's
# session bootstrap. Also runnable by hand: `session-start.sh --print` prints the raw text
# (use it after a resume/compaction, where no hook fires — see the `session-context` skill).
#
# Budget: 9,000 bytes total. Claude Code inlines hook context up to ~10 KB and beyond that
# persists it to a file with a 2 KB preview (measured: 9,000 inlined, 10,200 spilled).
# Codex's default additionalContextLimit is ~2,500 tokens (.codex/hooks.json sets
# 0 = unlimited). Sections land in PRIORITY order, each with its own cap, so the small
# load-bearing ones always arrive and the big ones truncate visibly (with a marker) instead
# of silently dropping everything after them. A truncation marker is
# the signal to TRIM the source doc per its own roll-up rules, never to raise the budget.
#
# One script, two wirings: .claude/settings.json and .codex/hooks.json both run this file
# (.codex/hooks/session-start.sh is a symlink). The repo root is resolved from the script's
# own path — Codex sets no project-dir variable and runs hooks with the session cwd, which
# may be a subdirectory. Never creates files; always exits 0 (fail-open).
#
# Section anchors (headings the extraction depends on — scripts/ve-check.sh verifies them):
#   STATUS.md          "## Active work" … "## Milestones" … "## Current status" … "## Worklog index",
#                      "### Shared / project-wide" then one "### @<owner>" block per owner
#   ARCHITECTURE.md    "## Invariants" … "## Stack"
#   decisions/INDEX.md one "| YYYY-MM-DD | area | status | summary | file |" row per entry, newest first

ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd -P)" || exit 0
cd "$ROOT" 2>/dev/null || exit 0
export LC_ALL=C            # ${#var} counts bytes, matching what the tools measure
VE="${VE_DIR:-Vibe Engineering}"
BUDGET="${VE_BUDGET:-9000}"
OWNER_HEAD=400             # bytes of each "### @owner" block injected (Shared is injected whole)
DECISION_ROWS=10            # newest index rows injected
MODE=json; [ "${1:-}" = "--print" ] && MODE=print
used=0

# emit <title> <max_bytes> <read-more hint>   (body on stdin; result in $EMIT)
# Caps the block at a line boundary and appends a visible marker when it truncates.
emit() {
  local title="$1" max="$2" hint="$3" body block n
  EMIT=""
  body="$(cat)"
  if [ -z "$body" ]; then
    # Every section is expected non-empty; an empty extraction means a heading/format
    # drifted in the source file. Fail VISIBLY, not silently (still exit 0 overall).
    EMIT="[$title — extracted EMPTY: heading drift? open $hint; run scripts/ve-check.sh]
"
    used=$((used + ${#EMIT} + 1))
    return 0
  fi
  local remaining=$((BUDGET - used))
  [ "$max" -le "$remaining" ] || max=$remaining
  if [ "$max" -le 300 ]; then
    # Budget exhausted by earlier sections — leave a visible stub, never a silent drop.
    EMIT="[$title — omitted: session-context budget exhausted; open $hint]
"
    used=$((used + ${#EMIT} + 1))
    return 0
  fi
  block="=== $title ===
$body"
  n=${#block}
  if [ "$n" -gt "$max" ]; then
    block="$(printf '%s' "$block" | head -c $((max - 120)) | sed '$d')
[... truncated at ${max} bytes — open $hint for the rest]"
    n=${#block}
  fi
  EMIT="$block
"
  used=$((used + n + 2))
}

# ---- Priority order (what gets budget first) --------------------------------------------
emit "Session protocol (details: worklog skill)" 700 "the worklog skill" <<'TXT'
1. Real work? Claim it first: add a row to STATUS.md Active work.
2. Start the worklog file (YYYY-MM-DD-<author>-<slug>.md) when work begins — not for Q&A-only sessions.
3. Session end: update STATUS (your rows/block only); promote durable facts to ARCHITECTURE / architecture/<area>.md / DECISIONS + a decisions/INDEX.md row / skills; run scripts/ve-check.sh.
Not injected: STATUS Milestones + owner-block tails; the ARCHITECTURE map + architecture/<area>.md (read yours before code work); the full decisions index + bodies.
Resumed/compacted session? `.claude/hooks/session-start.sh --print` (session-context skill).
TXT
s_protocol="$EMIT"

emit "$VE/STATUS.md § Active work (claim before working; don't take a row someone else holds)" 1800 "$VE/STATUS.md" \
  < <(sed -n '/^## Active work/,/^## Milestones/p' "$VE/STATUS.md" 2>/dev/null | grep '^|')
s_active="$EMIT"

emit "Invariants (from $VE/ARCHITECTURE.md — read the map + the architecture/ file for your area before structural/code work)" 3000 "$VE/ARCHITECTURE.md" \
  < <(sed -n '/^## Invariants/,/^## Stack/p' "$VE/ARCHITECTURE.md" 2>/dev/null | sed '1d;$d' | grep -v '^Long form')
s_invariants="$EMIT"

# Current status: the Shared block whole, then the first OWNER_HEAD bytes of every "### @owner"
# block (cut at a space, so multibyte text stays intact) with a marker — every owner's headline
# reaches every session.
emit "$VE/STATUS.md § Current status → immediate next (Shared block whole; each owner block's first ${OWNER_HEAD} B — open STATUS.md for the rest)" 2800 "$VE/STATUS.md" \
  < <(sed -n '/^## Current status/,/^## Worklog index/p' "$VE/STATUS.md" 2>/dev/null | sed '1d;$d' | sed '/^$/N;/^\n$/D' \
      | awk -v cap="$OWNER_HEAD" '
          function flush() {
            if (!inown || text == "") return
            if (length(text) <= cap) { printf "%s", text }
            else {
              s = substr(text, 1, cap); i = match(s, / [^ ]*$/); if (i > 0) s = substr(s, 1, i - 1)
              printf "%s\n[… more — open STATUS.md § %s]\n", s, substr(owner, 5)
            }
            text = ""; inown = 0
          }
          /^### @/ { flush(); owner = $0; text = ""; inown = 1; print; next }
          /^### /  { flush(); print; next }
          inown    { text = text $0 "\n"; next }
          { print }
          END { flush() }
        ')
s_current="$EMIT"

# Decision inventory: newest rows of decisions/INDEX.md (date — summary (area, status)).
idx="$VE/decisions/INDEX.md"
total=$(grep -cE '^\| (20[0-9]{2}-|\{\{DATE)' "$idx" 2>/dev/null); total=${total:-0}
emit "Decision inventory (newest $DECISION_ROWS of $total, from $VE/decisions/INDEX.md — open the entry before re-deciding anything it covers)" "$BUDGET" "$VE/decisions/INDEX.md" \
  < <({ grep -E '^\| (20[0-9]{2}-|\{\{DATE)' "$idx" 2>/dev/null | head -n "$DECISION_ROWS" \
        | awk -F'|' '{ for (i=2;i<=5;i++) { gsub(/^ +| +$/, "", $i) } print $2 " — " $5 " (" $3 ", " $4 ")" }';
        [ "$total" -gt "$DECISION_ROWS" ] && echo "($((total - DECISION_ROWS)) more rows in decisions/INDEX.md; bodies in DECISIONS.md / decisions/archive-*.md)"; })
s_decisions="$EMIT"

# ---- Reading order ----------------------------------------------------------------------
# Backstop derived from BUDGET (accounting already bounds output at ~BUDGET; the +200
# covers joins). Both stay inside the measured inline band (9,000 inlined, 10,200 spilled).
ctx="$(printf '%s\n%s\n%s\n%s\n%s' "$s_active" "$s_current" "$s_invariants" "$s_decisions" "$s_protocol" | head -c $((BUDGET + 200)))"

if [ "$MODE" = "print" ]; then
  printf '%s\n' "$ctx"
elif command -v python3 >/dev/null 2>&1; then
  printf '%s\n' "$ctx" | python3 -c '
import json, sys
ctx = sys.stdin.read().rstrip() + "\n"
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": ctx}}))
' 2>/dev/null
elif command -v jq >/dev/null 2>&1; then
  printf '%s\n' "$ctx" | jq -Rs '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:.}}' 2>/dev/null
fi

exit 0
