#!/usr/bin/env bash
# PreToolUse:Bash -- safety blockers (global) and the commit gate (scoped).
#
#                          payload
#                             |
#              +--------------v---------------+
#              | 1. safety blockers (GLOBAL)  |  force-push, reset --hard,
#              |    run in every repository   |  clean -f, branch -D,
#              +--------------+---------------+  --no-verify, checkout .
#                             |
#              +--------------v---------------+
#              | 2. scope guard               |  no .claude/project/ ?
#              |    exit 0, silently          |  -> stand down
#              +--------------+---------------+
#                             |
#              +--------------v---------------+
#              | 3. commit gate (FAIL CLOSED) |  anything unconfirmable
#              +------------------------------+  blocks and explains

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/_common.sh"

read_payload
CMD="$(payload_field '.tool_input.command' || true)"
HAY="$(haystack "$CMD")"

match() { printf '%s' "$HAY" | grep -qE "$1"; }

# --------------------------------------------------------------------------
# 1. Global safety blockers
#
# These are unanchored by design and apply everywhere, scaffolded or not.
# Blocking a force-push is worth doing in any repo you happen to open.
# --------------------------------------------------------------------------

match 'git[[:space:]]+push[^;&|]*(-f|--force)' &&
  block 'BLOCKED: git push --force is forbidden. Use a regular git push.'
match 'git[[:space:]]+reset[^;&|]*--hard' &&
  block 'BLOCKED: git reset --hard is forbidden. Use git stash or a backup branch.'
match 'git[[:space:]]+(checkout|restore)[[:space:]]+(--[[:space:]]+)?\.' &&
  block 'BLOCKED: discarding all changes is forbidden. Be selective.'
match 'git[[:space:]]+clean[^;&|]*-f' &&
  block 'BLOCKED: git clean -f is forbidden. Use git stash.'
match 'git[[:space:]]+branch[[:space:]]+-D' &&
  block 'BLOCKED: git branch -D is forbidden. Use -d for a safe delete.'
match '\-\-no-verify' &&
  block 'BLOCKED: --no-verify is forbidden. Fix the failing hook instead of bypassing it.'

# --------------------------------------------------------------------------
# 2. Scope guard
# --------------------------------------------------------------------------

require_scaffolded

# --------------------------------------------------------------------------
# 3. Commit gate
# --------------------------------------------------------------------------

# is_commit() lives in _common.sh so the gate and the completion tracker cannot
# drift apart on what counts as a commit.
is_commit "$HAY" || exit 0

SNAP="$(WF snapshot 2>/dev/null)"; RC=$?

case "$RC" in
  3)
    # No state file: no story is being tracked. Committing is fine.
    exit 0
    ;;
  4)
    # State exists but cannot be evaluated. THIS is the case that used to
    # silently disable the gate: workflow-state.sh exited nonzero, every
    # caller swallowed it with `|| echo none`, and the commit sailed through.
    if ! jq_works; then
      block 'COMMIT GATE: cannot evaluate workflow state because jq is not available.
  Install it:  brew install jq   (macOS)  /  apt-get install jq   (Linux)
  If jq is installed, check it runs:  jq --version
  The gate blocks rather than letting an unreviewed commit through.'
    fi
    block 'COMMIT GATE: workflow state exists but could not be read (corrupt or unreadable).
  Inspect:  .claude/project/.workflow-state.json
  Reset:    .claude/project/workflow-state.sh clear
  The gate blocks rather than letting an unreviewed commit through.'
    ;;
  0) : ;;
  *)
    block "COMMIT GATE: unexpected error reading workflow state (exit $RC)."
    ;;
esac

PHASE="$(printf '%s' "$SNAP" | cut -f1)"
STORY="$(printf '%s' "$SNAP" | cut -f2)"
FINDINGS="$(printf '%s' "$SNAP" | cut -f3)"
OVERRIDE="$(printf '%s' "$SNAP" | cut -f5)"

# No active story: nothing to gate.
[ -z "$STORY" ] && exit 0

# A recorded one-shot bypass. Spending it is logged.
if [ -n "$OVERRIDE" ] && WF consume-override >/dev/null 2>&1; then
  notice "COMMIT GATE: bypassed via a recorded override. This override is now spent."
  exit 0
fi

case "$PHASE" in
  review_passed|complete)
    exit 0
    ;;
  discovery_started|discovery_complete|plan_created|plan_approved)
    block "COMMIT GATE: $STORY has not been implemented and reviewed yet (phase: $PHASE).
  Finish the work, then run /review before committing.
  Details:  .claude/project/workflow-state.sh why-blocked"
    ;;
  implementation_in_progress)
    block "COMMIT GATE: $STORY has not been reviewed. Run /review before committing.
  Details:  .claude/project/workflow-state.sh why-blocked"
    ;;
  under_review)
    block "COMMIT GATE: review of $STORY is still in progress. Wait for it to finish."
    ;;
  changes_requested)
    block "COMMIT GATE: review found $FINDINGS blocker(s) in $STORY.
  Read them:  .claude/project/workflow-state.sh why-blocked
  Fix them, then run /review again."
    ;;
  *)
    block "COMMIT GATE: unrecognised workflow phase '$PHASE'.
  The gate blocks on any state it cannot confirm as reviewed.
  Reset:  .claude/project/workflow-state.sh clear"
    ;;
esac
