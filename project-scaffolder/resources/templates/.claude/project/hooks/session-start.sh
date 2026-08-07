#!/usr/bin/env bash
# SessionStart -- branch context and where the workflow left off.

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/_common.sh"

require_scaffolded

BRANCH="$(git -C "$PROJECT_ROOT" branch --show-current 2>/dev/null || echo unknown)"
CHANGES="$(git -C "$PROJECT_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
notice "Branch: $BRANCH | $CHANGES uncommitted file(s)"

# A stale turn-scratch file means the previous session ended mid-turn.
rm -f "$PROJECT_ROOT/.claude/project/.turn-touched" 2>/dev/null || true

WF next-action 2>/dev/null || true
exit 0
