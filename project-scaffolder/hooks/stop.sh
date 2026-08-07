#!/usr/bin/env bash
# Stop -- end-of-turn checks: uncommitted work, typecheck, next action.

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/_common.sh"

require_scaffolded

# --------------------------------------------------------------------------
# Typecheck, bounded (eng review decision 12).
#
# This used to run per-edit as `npx tsc --noEmit` under a 30s timeout, which a
# real project blows past mid-run. Moving it here fixed that but created a new
# problem: a full typecheck on EVERY turn, before the turn can end. So: only
# when a TS file was actually touched this turn, and incrementally.
# --------------------------------------------------------------------------

TOUCH_FILE="$PROJECT_ROOT/.claude/project/.turn-touched"
if [ -s "$TOUCH_FILE" ] && grep -q '^ts$' "$TOUCH_FILE" 2>/dev/null; then
  if [ -f "$PROJECT_ROOT/tsconfig.json" ] && command -v tsc >/dev/null 2>&1; then
    ( cd "$PROJECT_ROOT" && tsc --noEmit --incremental --pretty 2>&1 | head -20 ) || true
  fi
fi
rm -f "$TOUCH_FILE" 2>/dev/null || true

# --------------------------------------------------------------------------
# Uncommitted work and next step
# --------------------------------------------------------------------------

if ! ( git -C "$PROJECT_ROOT" diff --quiet 2>/dev/null && \
       git -C "$PROJECT_ROOT" diff --cached --quiet 2>/dev/null ); then
  notice 'UNCOMMITTED CHANGES: run your verification checklist (tests, lint, type checking) before committing.'
fi

WF next-action 2>/dev/null || true

# Skill capture, only when a story just completed. One hook per event, so this
# is a call rather than a second Stop registration -- hooks in the same event
# run in parallel and cannot see each other.
#
# Never allowed to fail the turn: a capture suggestion is a nice-to-have and
# must not be able to wedge the session.
bash "$HOOKS_DIR/skillify-check.sh" "$PROJECT_ROOT/.claude/project" 2>/dev/null || true

exit 0
