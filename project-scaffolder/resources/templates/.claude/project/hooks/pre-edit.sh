#!/usr/bin/env bash
# PreToolUse:Edit|Write -- secrets blocker (global) and workflow gate (scoped).

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/_common.sh"

read_payload
FILE="$(payload_field '.tool_input.file_path' || true)"
[ -z "$FILE" ] && exit 0

BASE="$(basename "$FILE")"

# --------------------------------------------------------------------------
# 1. Secrets blocker -- GLOBAL, runs before the scope guard.
#
# S-GAP2: the old list matched .env*, credentials.json, .pem, .key, .p12 and
# .pfx, and missed .envrc, keys with no extension (id_rsa), terraform.tfvars,
# java keystores, and the package-manager rc files that hold auth tokens.
# --------------------------------------------------------------------------

# `*` matches the empty string, so `*.env` already covers a bare `.env` and
# `*.env.example` already covers `.env.example`. Listing both forms is dead
# weight, and shellcheck flags it (SC2221/SC2222).
case "$BASE" in
  # Allowlist first: these are templates, meant to be edited and committed.
  *.env.example|*.env.sample|*.env.template)
    ;;
  *.env|*.env.*|.envrc|\
  *credentials.json|\
  id_rsa|id_dsa|id_ecdsa|id_ed25519|*.pem|*.key|*.p12|*.pfx|*.jks|*.keystore|*.crt|\
  .npmrc|.pypirc|.netrc|\
  *.tfvars)
    block "BLOCKED: $BASE looks like a secrets or credentials file.
  Ask the user for explicit confirmation before editing it directly."
    ;;
esac

# --------------------------------------------------------------------------
# 2. Workflow gate -- scoped to this project only.
# --------------------------------------------------------------------------

require_scaffolded

REL="${FILE#"$PROJECT_ROOT"/}"
case "$REL" in
  .claude/*|.git/*|*.md) exit 0 ;;
esac

STORY="$(WF get-story 2>/dev/null || true)"
[ -z "$STORY" ] && exit 0
PHASE="$(WF get-phase 2>/dev/null || echo none)"

case "$PHASE" in
  discovery_started|discovery_complete|plan_created)
    notice "WORKFLOW GATE: editing source for $STORY but the plan is not approved yet (phase: $PHASE). Get approval first."
    ;;
  under_review)
    notice "WORKFLOW GATE: review of $STORY is in progress. Wait for it to finish before editing source."
    ;;
  changes_requested)
    notice "WORKFLOW GATE: fixing review blockers for $STORY. Run /review again when done."
    ;;
esac

exit 0
