#!/usr/bin/env bash
# PostToolUse:Bash -- a successful commit from review_passed completes the story.

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/_common.sh"

read_payload
require_scaffolded

CMD="$(payload_field '.tool_input.command' || true)"
HAY="$(haystack "$CMD")"

is_commit "$HAY" || exit 0

STORY="$(WF get-story 2>/dev/null || true)"
[ -z "$STORY" ] && exit 0

PHASE="$(WF get-phase 2>/dev/null || echo none)"
if [ "$PHASE" = "review_passed" ]; then
  WF advance complete >/dev/null 2>&1 || true
  notice "WORKFLOW: $STORY committed and complete. Run .claude/project/workflow-state.sh clear when you start the next story."
fi

exit 0
