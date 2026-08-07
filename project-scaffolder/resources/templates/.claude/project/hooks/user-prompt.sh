#!/usr/bin/env bash
# UserPromptSubmit -- suggest /implement, and detect plan approval.

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/_common.sh"

read_payload
require_scaffolded

PROMPT="$(payload_field '.prompt' || true)"
[ -z "$PROMPT" ] && PROMPT="$(payload_field '.user_prompt' || true)"
[ -z "$PROMPT" ] && exit 0

if printf '%s' "$PROMPT" | grep -qiE '(implement|build|add|create).{0,30}(feature|endpoint|module|page|component|story)|implement[[:space:]]+US-'; then
  notice 'Use /implement for the full feature workflow, or /review before committing.'
fi

# Plan approval advances the phase. Only meaningful while a plan is pending.
PHASE="$(WF get-phase 2>/dev/null || echo none)"
if [ "$PHASE" = "plan_created" ] &&
   printf '%s' "$PROMPT" | grep -qiE '(approve[d]?|lgtm|looks good|go ahead|proceed|ship it|^(y|yes|yep|yeah)$|yes.*(plan|proceed|implement))'; then
  WF advance plan_approved >/dev/null 2>&1 || true
  WF next-action 2>/dev/null || true
fi

exit 0
