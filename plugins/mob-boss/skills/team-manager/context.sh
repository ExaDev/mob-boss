#!/usr/bin/env bash
# Loads team-manager context. Called from SKILL.md during skill loading.
#
# Agent-profile precedence:
#   1. Project-local overrides at .claude/agents/main/       (per-package customisation)
#   2. Mob-boss evolved set at ~/.mob-boss/agents/main/      (the working set
#      that mob-boss iterates on — this is the set almost all dispatches should use)
#   3. Plugin canonical profiles at ${CLAUDE_SKILL_DIR}/../mob-boss/agents/main/
#      (baseline fallback — read-only, shipped with the plugin)

if ls .claude/agents/main/*.md &>/dev/null; then
    AGENTS_DIR=".claude/agents/main"
elif ls "$HOME/.mob-boss/agents/main/"*.md &>/dev/null; then
    AGENTS_DIR="$HOME/.mob-boss/agents/main"
elif [[ -n "${CLAUDE_SKILL_DIR:-}" ]] && ls "${CLAUDE_SKILL_DIR}/../mob-boss/agents/main/"*.md &>/dev/null; then
    AGENTS_DIR="${CLAUDE_SKILL_DIR}/../mob-boss/agents/main"
else
    AGENTS_DIR="$HOME/.mob-boss/agents/main"
fi

echo "=== Project Context (first 80 lines of CLAUDE.md) ==="
head -80 CLAUDE.md 2>/dev/null || echo "No CLAUDE.md found"
echo ""

echo "=== Agents loaded from: $AGENTS_DIR ==="
echo ""

for role in developer designer architect reviewer project-expert; do
  role_file="$AGENTS_DIR/$role.md"
  # Display header: capitalise words, replace '-' with ' '
  header="$(echo "$role" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)$i=toupper(substr($i,1,1))substr($i,2)}1')"
  echo "=== $header ==="
  if [[ -f "$role_file" ]]; then
    cat "$role_file"
  else
    echo "$header profile not found at $role_file"
  fi
  echo ""
done
