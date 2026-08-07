#!/usr/bin/env bats
# D1 REGRESSION (iron rule, mandatory)
#
# Claim: the commit gate never fires in real use.
#
# The gate in settings.json matches only implementation_in_progress,
# under_review, and changes_requested. Nothing in settings.json or review.md
# ever advances the phase TO implementation_in_progress, so after plan approval
# the phase sits at plan_approved, the case falls through, and git commit
# succeeds unreviewed.
#
# Two halves, tested separately:
#   1. the gate has no plan_approved branch  (symptom)
#   2. nothing advances to implementation_in_progress  (root cause)

setup() {
  load '../helpers/setup'
  make_project
  stub_path
  mkdir -p "$PROJECT_DIR/src"
}

phase_now() {
  "$JQ_REAL" -r '.phase // "none"' "$PROJECT_DIR/.claude/project/.workflow-state.json"
}

@test "CONTROL: the gate does block at implementation_in_progress" {
  # Proves the gate mechanism works at all, so the failures below isolate
  # reachability rather than a broken hook.
  seed_state implementation_in_progress
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "wip"')"
  assert_blocked
}

@test "D1 symptom: gate must block a commit at plan_approved" {
  seed_state plan_approved
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "wip"')"
  assert_blocked
}

@test "D1 root cause: editing source after approval must advance to implementation_in_progress" {
  seed_state plan_approved
  echo "export const x = 1" > "$PROJECT_DIR/src/app.ts"
  run_hook PostToolUse "Edit|Write" "$(payload_edit "$PROJECT_DIR/src/app.ts")"

  got="$(phase_now)"
  if [ "$got" != "implementation_in_progress" ]; then
    echo "EXPECTED phase=implementation_in_progress after a source edit"
    echo "GOT      phase=$got"
    echo "Nothing in the hook suite advances to this phase, which is why the"
    echo "commit gate's implementation_in_progress branch is dead code."
    return 1
  fi
}

@test "D1: gate must also block at discovery and planning phases" {
  for p in discovery_started discovery_complete plan_created; do
    seed_state "$p"
    run_hook PreToolUse Bash "$(payload_bash 'git commit -m "wip"')"
    if [ "$hook_status" -ne 2 ]; then
      echo "phase=$p allowed the commit (exit $hook_status)"
      return 1
    fi
  done
}

@test "gate must ALLOW a commit at review_passed" {
  seed_state review_passed
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "feat: done"')"
  assert_allowed
}
