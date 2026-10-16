#!/usr/bin/env bash
# Install the Vibe Engineering context system.
#
#   ./install.sh <target-repo> --name "<Project>" [--owner <shortname>] [--force]
#       Copy the template into an existing repo. Never overwrites an existing
#       file unless --force.
#
#   ./install.sh --in-place --name "<Project>" [--owner <shortname>]
#       Turn THIS checkout into your project (use after GitHub's "Use this
#       template"): fills the placeholders here, replaces the template README
#       with a project stub, and deletes install.sh.
#
# Both modes substitute {{PROJECT}} / {{project}} / {{OWNER}} / {{DATE}} and leave
# the other {{placeholders}} for you to fill; scripts/ve-check.sh lists them.
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd -P)"
TARGET=""; NAME=""; OWNER="${USER:-me}"; FORCE=0; INPLACE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="$2"; shift 2;;
    --owner) OWNER="$2"; shift 2;;
    --force) FORCE=1; shift;;
    --in-place|init) INPLACE=1; shift;;
    -h|--help) sed -n '2,14p' "$0"; exit 0;;
    *) TARGET="$1"; shift;;
  esac
done
usage() {
  echo "usage: $0 <target-repo> --name <Project> [--owner <shortname>] [--force]"
  echo "       $0 --in-place --name <Project> [--owner <shortname>]"
  exit 1
}
[ -n "$NAME" ] || usage
DATE="$(date +%F)"
SLUG="$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9\n' '-' | sed 's/-*$//')"
# Escape \, & and the / delimiter in user-supplied values so names like "R&D" or "a/b" survive sed.
sed_escape() { printf '%s' "$1" | sed 's/[\\&/]/\\&/g'; }
SUBST=(-e "s/{{PROJECT}}/$(sed_escape "$NAME")/g" -e "s/{{project}}/$SLUG/g"
       -e "s/{{OWNER}}/$(sed_escape "$OWNER")/g" -e "s/{{DATE}}/$DATE/g")

if [ "$INPLACE" -eq 1 ]; then
  # ---- In-place mode: this checkout becomes the project -------------------------------
  [ -z "$TARGET" ] || usage
  cd "$SRC"
  find . -type f -not -path './.git/*' -not -name '.DS_Store' \
         -not -path './install.sh' -not -path './README.md' -not -path './LICENSE' \
  | while read -r rel; do
      rel="${rel#./}"
      grep -q '{{' "$rel" 2>/dev/null || continue
      tmp="$rel.ve-tmp"
      # Never redirect a file onto itself: write a sibling temp file, then move it over.
      sed "${SUBST[@]}" "$rel" > "$tmp"
      [ -x "$rel" ] && chmod +x "$tmp"
      mv "$tmp" "$rel"
      echo "fill   $rel"
    done
  cat > README.md <<EOF
# $NAME

<!-- One-paragraph project description. -->

- Agent rules: [AGENTS.md](AGENTS.md) (CLAUDE.md just imports it)
- Context system: [Vibe Engineering/README.md](Vibe%20Engineering/README.md)
- Onboarding: [docs/ONBOARDING.md](docs/ONBOARDING.md)
EOF
  echo "write  README.md (project stub replacing the template README)"
  rm -f install.sh
  echo "remove install.sh (template-only)"
  TARGET="$SRC"
else
  # ---- Copy mode: install into another repo --------------------------------------------
  [ -n "$TARGET" ] || usage
  [ -d "$TARGET" ] || { echo "no such dir: $TARGET"; exit 1; }
  TARGET="$(cd "$TARGET" && pwd -P)"
  if [ "$TARGET" = "$SRC" ]; then
    echo "target is this template checkout itself — use: $0 --in-place --name \"$NAME\""
    exit 1
  fi
  # Files first (symlinks are recreated below, not copied as files).
  ( cd "$SRC" && find . -type f \
      -not -path './.git/*' -not -name '.DS_Store' -not -name 'install.sh' \
      -not -path './README.md' -not -path './LICENSE' \
      -not -path './.agents/*' -not -path './.codex/hooks/*' ) | while read -r rel; do
    rel="${rel#./}"
    dest="$TARGET/$rel"
    if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then echo "skip   $rel (exists)"; continue; fi
    mkdir -p "$(dirname "$dest")"
    sed "${SUBST[@]}" "$SRC/$rel" > "$dest"
    [ -x "$SRC/$rel" ] && chmod +x "$dest"
    echo "write  $rel"
  done
  mkdir -p "$TARGET/.codex/hooks" "$TARGET/.agents"
  [ -e "$TARGET/.codex/hooks/session-start.sh" ] || ln -s ../../.claude/hooks/session-start.sh "$TARGET/.codex/hooks/session-start.sh"
  [ -e "$TARGET/.agents/skills" ] || ln -s ../.claude/skills "$TARGET/.agents/skills"
  grep -q '^\.DS_Store' "$TARGET/.gitignore" 2>/dev/null || echo ".DS_Store" >> "$TARGET/.gitignore"
  grep -q '^\.claude/settings\.local\.json' "$TARGET/.gitignore" 2>/dev/null || echo ".claude/settings.local.json" >> "$TARGET/.gitignore"
fi

echo
echo "Installed into $TARGET. Next:"
echo "  1. Fill the {{placeholders}}: grep -rn '{{' 'Vibe Engineering' AGENTS.md docs .claude/skills"
echo "  2. Write 2–6 real invariants in Vibe Engineering/ARCHITECTURE.md and the Stack section."
echo "  3. Run scripts/ve-check.sh, then .claude/hooks/session-start.sh --print to see the bootstrap."
echo "  4. Commit. Open a fresh Claude Code session; it should show five '===' sections."
