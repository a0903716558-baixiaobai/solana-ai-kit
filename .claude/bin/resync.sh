#!/usr/bin/env bash
set -euo pipefail

# Solana Claude Config — Submodule Resync
# Updates external skill submodules to latest and verifies integrity.
#
# Usage:
#   bash .claude/bin/resync.sh

TARGET_DIR="$(pwd)"

if [ ! -d "$TARGET_DIR/.claude/skills/ext" ]; then
  echo "Error: .claude/skills/ext/ not found. Run from your project root."
  exit 1
fi

echo "Updating external skill submodules..."
git submodule update --remote --merge || {
  echo "Submodule update failed. Attempting init first..."
  git submodule update --init --recursive
  git submodule update --remote --merge
}
echo ""

echo "Changes in submodules:"
git diff --submodule=diff
echo ""

echo "Submodule status:"
git submodule status
echo ""

# Verify skill paths
SKILL_HUB=".claude/skills/SKILL.md"
SKILL_DIR=".claude/skills"
MISSING=0

if [ -f "$SKILL_HUB" ]; then
  echo "Verifying skill paths referenced in SKILL.md..."

  while IFS= read -r ref; do
    FULL_PATH="$SKILL_DIR/$ref"
    if [ ! -f "$FULL_PATH" ]; then
      echo "  MISSING: $ref -> $FULL_PATH"
      MISSING=$((MISSING + 1))
    fi
  done < <(grep -oE '\]\([^)]+\.md\)' "$SKILL_HUB" | sed 's/\](//' | sed 's/)//' | grep -v '^http')

  while IFS= read -r ref; do
    FULL_PATH="$SKILL_DIR/$ref"
    if [ ! -d "$FULL_PATH" ]; then
      echo "  MISSING DIR: $ref -> $FULL_PATH"
      MISSING=$((MISSING + 1))
    fi
  done < <(grep -oE '\]\([^)]+/\)' "$SKILL_HUB" | sed 's/\](//' | sed 's/)//' | grep -v '^http')

  if [ "$MISSING" -eq 0 ]; then
    echo "  All skill paths resolve correctly."
  else
    echo ""
    echo "  $MISSING broken path(s) found. Fix SKILL.md or check submodule state."
  fi
fi
echo ""

echo "=== Submodule Summary ==="
echo ""
git submodule foreach --quiet '
  LATEST=$(git log -1 --format="%h %s" 2>/dev/null)
  echo "  $name: $LATEST"
'
echo ""
echo "Run 'git add .gitmodules .claude/skills/ext/' and commit to lock updates."
