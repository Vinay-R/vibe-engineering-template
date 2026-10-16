#!/usr/bin/env bash
# Vibe Engineering context-system lint. Read-only; exits 1 on errors, 0 on warnings only.
#   scripts/ve-check.sh            — check this repo
#   scripts/ve-check.sh <repo>     — check another checkout
# Checks: hook anchors present, hook output size + truncation, size budgets, section sizes,
# DECISIONS title length (new entries) + duplicates + newest-first, decisions/INDEX.md
# coverage, architecture/ pointers, worklog length + index coverage, unresolved
# {{PLACEHOLDERS}}, broken relative links, machine-local paths.

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd -P)}"
cd "$ROOT" || { echo "no such dir: $ROOT"; exit 1; }
VE="${VE_DIR:-Vibe Engineering}"
HOOK=".claude/hooks/session-start.sh"
TITLE_RULE_SINCE="${VE_TITLE_RULE_SINCE:-0000-00-00}"   # ≤120-char titles enforced for entries dated on/after this
errors=0; warns=0
err()  { echo "ERROR  $*"; errors=$((errors+1)); }
warn() { echo "WARN   $*"; warns=$((warns+1)); }
ok()   { echo "ok     $*"; }
size() { LC_ALL=C wc -c < "$1" | tr -d ' '; }

# --- files + anchors ------------------------------------------------------------------
for f in "$VE/STATUS.md" "$VE/ARCHITECTURE.md" "$VE/DECISIONS.md" "$VE/worklogs/INDEX.md" "$HOOK" AGENTS.md; do
  [ -e "$f" ] || err "missing $f"
done
[ -e CLAUDE.md ] && ! grep -q '^@AGENTS.md' CLAUDE.md && warn "CLAUDE.md does not import AGENTS.md (@AGENTS.md)"
for a in "## Active work" "## Milestones" "## Current status" "## Worklog index"; do
  grep -q "^$a" "$VE/STATUS.md" 2>/dev/null || err "STATUS.md lacks hook anchor '$a'"
done
for a in "## Invariants" "## Stack"; do
  grep -q "^$a" "$VE/ARCHITECTURE.md" 2>/dev/null || err "ARCHITECTURE.md lacks hook anchor '$a'"
done
grep -Eq '^## ([0-9]{4}-[0-9]{2}-[0-9]{2}|\{\{DATE\}\}) — ' "$VE/DECISIONS.md" 2>/dev/null || err "DECISIONS.md has no '## YYYY-MM-DD — title' entries"
[ -x "$HOOK" ] || err "$HOOK is not executable"
[ -L .codex/hooks/session-start.sh ] || warn ".codex/hooks/session-start.sh is not a symlink to the .claude hook (Codex parity)"

# --- hook output ----------------------------------------------------------------------
if [ -x "$HOOK" ]; then
  out="$(LC_ALL=C bash "$HOOK" 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"], end="")' 2>/dev/null || true)"
  [ -n "$out" ] || out="$(LC_ALL=C bash "$HOOK" --print 2>/dev/null)"
  bytes=$(printf '%s' "$out" | LC_ALL=C wc -c | tr -d ' ')
  sections=$(printf '%s' "$out" | grep -c '^=== ')
  trunc=$(printf '%s' "$out" | grep -c 'truncated at')
  empty=$(printf '%s' "$out" | grep -c 'extracted EMPTY')
  [ "$sections" -eq 5 ] && ok "hook emits 5 sections ($bytes bytes)" || err "hook emits $sections sections, expected 5"
  [ "$empty" -eq 0 ] || err "hook: $empty section(s) extracted EMPTY — heading drift"
  [ "$bytes" -le 9200 ] || err "hook output $bytes bytes > 9200 (would spill to a file preview)"
  [ "$trunc" -eq 0 ] && ok "hook: nothing truncated" || warn "hook: $trunc section(s) truncated — trim STATUS/DECISIONS per their roll-up rules"
  inv=$(printf '%s' "$out" | grep -c '^- \*\*INV-')
  total_inv=$(sed -n '/^## Invariants/,/^## Stack/p' "$VE/ARCHITECTURE.md" | grep -c '^- \*\*INV-')
  [ "$inv" -eq "$total_inv" ] && ok "hook: all $total_inv invariants injected" || warn "hook: $inv of $total_inv invariants injected — condense the Invariants section"
fi

# --- size budgets ---------------------------------------------------------------------
s=$(size "$VE/STATUS.md");       [ "$s" -le 20000 ] && ok "STATUS.md $s bytes" || warn "STATUS.md is $s bytes (budget 20 KB) — roll milestones/owner history into STATUS-archive.md"
s=$(size AGENTS.md);             [ "$s" -le 6000 ]  && ok "AGENTS.md $s bytes" || warn "AGENTS.md is $s bytes (budget 6 KB) — it is read on every session"
s=$(size "$VE/ARCHITECTURE.md"); [ "$s" -le 30000 ] && ok "ARCHITECTURE.md $s bytes" || warn "ARCHITECTURE.md is $s bytes (budget 30 KB) — move detail to architecture/<area>.md"
inv=$(sed -n '/^## Invariants/,/^## Stack/p' "$VE/ARCHITECTURE.md" | LC_ALL=C wc -c | tr -d ' ')
[ "$inv" -le 3000 ] && ok "ARCHITECTURE invariants $inv bytes" || warn "ARCHITECTURE invariants are $inv bytes; the hook caps them at 3000 — later invariants are cut"
sed -n '/^## Current status/,/^## Worklog index/p' "$VE/STATUS.md" | awk '
  /^### / {if (name) printf "%s\t%d\n", name, n; name=substr($0,5); n=0; next}
  {n++}
  END {if (name) printf "%s\t%d\n", name, n}
' | while IFS=$'\t' read -r name n; do
  [ "$n" -le 40 ] && ok "Current status block '$name': $n lines" || warn "Current status block '$name' is $n lines (target ≤ 40) — narrative belongs in worklogs / STATUS-archive.md"
done
grep -n '^## ' "$VE/ARCHITECTURE.md" | awk -F: 'NR>1{printf "%s\t%d\n", prev, $1-p} {p=$1; prev=$2}' | while IFS=$'\t' read -r name n; do
  [ "$n" -le 120 ] || warn "ARCHITECTURE section '$name' is $n lines (rule: split past ~100 into architecture/<section>.md)"
done
# architecture/ pointers resolve
grep -o 'architecture/[a-z0-9-]*\.md' "$VE/ARCHITECTURE.md" | sort -u | while read -r f; do
  [ -e "$VE/$f" ] || echo "$f"
done | while read -r f; do err "ARCHITECTURE.md points at missing $VE/$f"; done

# --- DECISIONS ------------------------------------------------------------------------
long=$(grep '^## ' "$VE/DECISIONS.md" | awk -v since="$TITLE_RULE_SINCE" 'substr($0,4,10) >= since && length($0) > 123 {c++} END {print c+0}')
[ "$long" -eq 0 ] && ok "DECISIONS titles since $TITLE_RULE_SINCE all ≤ 120 chars" || warn "DECISIONS: $long title(s) dated ≥ $TITLE_RULE_SINCE longer than 120 chars — one decision per entry"
all_titles="$(cat "$VE/DECISIONS.md" "$VE"/decisions/archive-*.md 2>/dev/null | grep -E '^## ([0-9]|\{\{DATE)')"
dups=$(printf '%s\n' "$all_titles" | sort | uniq -d | grep -c . || true)
[ "$dups" -eq 0 ] || err "DECISIONS: $dups duplicated title(s): $(printf '%s\n' "$all_titles" | sort | uniq -d | head -1)"
first=$(grep -m1 '^## [0-9]' "$VE/DECISIONS.md" | cut -c4-13); last=$(grep '^## [0-9]' "$VE/DECISIONS.md" | tail -1 | cut -c4-13)
[ -z "$first" ] || [ "$first" \> "$last" ] || [ "$first" = "$last" ] || warn "DECISIONS: first entry ($first) is older than last ($last) — entries must be newest first"
if [ -e "$VE/decisions/INDEX.md" ]; then
  entries=$(printf '%s\n' "$all_titles" | grep -c .)
  rows=$(grep -cE '^\| (20[0-9]{2}-|\{\{DATE)' "$VE/decisions/INDEX.md")
  [ "$rows" -eq "$entries" ] && ok "decisions/INDEX.md: $rows rows = $entries entries" || err "decisions/INDEX.md has $rows rows but DECISIONS.md + archives have $entries entries — add the missing row(s)"
  longsum=$(grep -E '^\| (20[0-9]{2}-|\{\{DATE)' "$VE/decisions/INDEX.md" | awk -F'|' '{ s=$5; gsub(/^ +| +$/, "", s); if (length(s) > 100) c++ } END {print c+0}')
  [ "$longsum" -eq 0 ] && ok "decisions/INDEX.md summaries all ≤ 100 chars" || warn "decisions/INDEX.md: $longsum summary(ies) longer than 100 chars"
  grep -q '^| 20' "$VE/decisions/INDEX.md" && [ "$(grep -m1 '^| 20' "$VE/decisions/INDEX.md" | cut -c3-12)" \< "$(grep '^| 20' "$VE/decisions/INDEX.md" | tail -1 | cut -c3-12)" ] && warn "decisions/INDEX.md is not newest first"
fi

# --- worklogs -------------------------------------------------------------------------
for w in "$VE"/worklogs/20*.md; do
  [ -e "$w" ] || continue
  base=$(basename "$w")
  n=$(wc -l < "$w" | tr -d ' ')
  [ "$n" -le 100 ] || warn "worklog $base is $n lines (hard cap 100)"
  grep -q "$base" "$VE/worklogs/INDEX.md" || warn "worklog $base has no line in worklogs/INDEX.md"
  echo "$base" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+-[a-z0-9-]+\.md$' || warn "worklog $base does not match YYYY-MM-DD-<author>-<slug>.md"
done

# --- placeholders, machine-local paths, links ------------------------------------------
ph=$(grep -rlE '\{\{[^}]{1,80}\}\}' "$VE" AGENTS.md docs .claude/skills 2>/dev/null | wc -l | tr -d ' ')
[ "$ph" -eq 0 ] && ok "no unresolved {{placeholders}}" || warn "$ph file(s) still contain {{placeholders}}: $(grep -rlE '\{\{[^}]{1,80}\}\}' "$VE" AGENTS.md docs .claude/skills 2>/dev/null | head -3 | tr '\n' ' ')"
ml=$(grep -rn -E '~/\.claude/|/Users/[a-z]+/|/home/[a-z]+/' "$VE/STATUS.md" "$VE/ARCHITECTURE.md" "$VE/DECISIONS.md" "$VE"/architecture "$VE"/decisions AGENTS.md .claude/hooks .codex 2>/dev/null | wc -l | tr -d ' ')
[ "$ml" -eq 0 ] && ok "no machine-local paths in always-read docs" || warn "$ml machine-local path reference(s) (~/.claude/…, /Users/…) in always-read docs or hook wiring — collaborators cannot open them"
for f in "$VE/STATUS.md" "$VE/STATUS-archive.md" "$VE/ARCHITECTURE.md" "$VE/worklogs/INDEX.md" "$VE"/architecture/*.md "$VE"/decisions/*.md; do
  [ -e "$f" ] || continue
  dir=$(dirname "$f")
  grep -o '](\([^)#]*\.md\))' "$f" | sed 's/^](//; s/)$//' | sort -u | while read -r link; do
    case "$link" in http*|/*) continue;; esac
    [ -e "$dir/$link" ] || echo "$f → $link"
  done
done | while read -r line; do warn "broken link: $line"; done
[ "$(find "$VE" -name .DS_Store | wc -l | tr -d ' ')" -eq 0 ] || warn ".DS_Store inside $VE (gitignored; delete it locally)"

echo "---"
echo "$errors error(s), $warns warning(s)"
[ "$errors" -eq 0 ]
