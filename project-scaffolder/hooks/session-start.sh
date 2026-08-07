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

# Confirm an upgrade took effect. /update writes this marker because hook
# configuration is only read at session start -- so between running /update and
# restarting, the session is still running the OLD hooks. This message firing at
# all proves the new ones are loaded, because it is one of them.
PENDING="$PROJECT_ROOT/.claude/project/.upgrade-pending"
if [ -f "$PENDING" ]; then
  notice "Workflow hooks upgraded and now active (marker from $(cat "$PENDING" 2>/dev/null))."
  rm -f "$PENDING" 2>/dev/null || true
fi

WF next-action 2>/dev/null || true
exit 0
