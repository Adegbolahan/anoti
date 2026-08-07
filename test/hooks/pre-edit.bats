#!/usr/bin/env bats
# pre-edit.sh -- secrets blocker (global) and workflow gate (scoped).
#
# The secrets blocker runs BEFORE the scope guard, deliberately: refusing to
# edit a private key is worth doing in any repo you happen to open.

setup() {
  load '../helpers/setup'
  make_project
  stub_path
}

edit_should_block() {
  run_hook PreToolUse "Edit|Write" "$(payload_edit "$PROJECT_DIR/$1")"
  if [ "$hook_status" -ne 2 ]; then
    echo "EXPECTED $1 to be blocked, got exit $hook_status"
    echo "$hook_output"
    return 1
  fi
}

edit_should_allow() {
  run_hook PreToolUse "Edit|Write" "$(payload_edit "$PROJECT_DIR/$1")"
  if [ "$hook_status" -ne 0 ]; then
    echo "EXPECTED $1 to be allowed, got exit $hook_status"
    echo "$hook_output"
    return 1
  fi
}

@test "secrets: classic patterns are blocked" {
  edit_should_block ".env"
  edit_should_block ".env.production"
  edit_should_block "credentials.json"
  edit_should_block "server.pem"
  edit_should_block "private.key"
  edit_should_block "cert.p12"
  edit_should_block "cert.pfx"
}

@test "S-GAP2: patterns the old blocker missed are now caught" {
  edit_should_block ".envrc"
  edit_should_block "id_rsa"          # no extension
  edit_should_block "id_ed25519"
  edit_should_block "terraform.tfvars"
  edit_should_block "keystore.jks"
  edit_should_block "server.crt"
  edit_should_block ".npmrc"          # holds auth tokens
  edit_should_block ".pypirc"
  edit_should_block ".netrc"
}

@test "secrets: example and template files stay editable" {
  edit_should_allow ".env.example"
  edit_should_allow ".env.sample"
  edit_should_allow ".env.template"
}

@test "secrets: ordinary source files are untouched" {
  edit_should_allow "src/app.ts"
  edit_should_allow "README.md"
  edit_should_allow "package.json"
}

@test "workflow gate warns when editing source before approval" {
  seed_state plan_created
  run_hook PreToolUse "Edit|Write" "$(payload_edit "$PROJECT_DIR/src/app.ts")"
  assert_allowed   # a warning, not a block
  printf '%s' "$hook_output" | grep -q 'WORKFLOW GATE' || {
    echo "expected a workflow gate warning, got: $hook_output"; return 1; }
}

@test "workflow gate warns while a review is in progress" {
  seed_state under_review
  run_hook PreToolUse "Edit|Write" "$(payload_edit "$PROJECT_DIR/src/app.ts")"
  assert_allowed
  printf '%s' "$hook_output" | grep -qi 'review' || {
    echo "expected a review-in-progress warning, got: $hook_output"; return 1; }
}

@test "workflow gate stays quiet once the plan is approved" {
  seed_state plan_approved
  run_hook PreToolUse "Edit|Write" "$(payload_edit "$PROJECT_DIR/src/app.ts")"
  assert_allowed
  if printf '%s' "$hook_output" | grep -q 'WORKFLOW GATE'; then
    echo "should not warn during the phase where coding is expected"
    echo "$hook_output"; return 1
  fi
}

@test "workflow gate does not fire on tracking files or docs" {
  seed_state plan_created
  run_hook PreToolUse "Edit|Write" "$(payload_edit "$PROJECT_DIR/.claude/project/roadmap.md")"
  assert_allowed
  if printf '%s' "$hook_output" | grep -q 'WORKFLOW GATE'; then
    echo "editing project tracking is not implementation"; return 1
  fi
}
