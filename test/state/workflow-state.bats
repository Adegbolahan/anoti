#!/usr/bin/env bats
# workflow-state.sh -- the state machine itself, exercised through its CLI.

setup() {
  load '../helpers/setup'
  make_project
  WF="$PROJECT_DIR/.claude/project/workflow-state.sh"
}

wf() { ( cd "$PROJECT_DIR" && bash "$WF" "$@" ); }
phase_now() { "$JQ_REAL" -r '.phase' "$PROJECT_DIR/.claude/project/.workflow-state.json"; }

# --------------------------------------------------------------------------
# Exit-code contract. The 3-vs-4 distinction is the whole reason the gate
# can tell "no story yet" apart from "I cannot tell you".
# --------------------------------------------------------------------------

@test "snapshot exits 3 when no state file exists" {
  run wf snapshot
  [ "$status" -eq 3 ]
}

@test "snapshot exits 4 when the state file is corrupt" {
  printf 'not json{{' > "$PROJECT_DIR/.claude/project/.workflow-state.json"
  run wf snapshot
  [ "$status" -eq 4 ]
}

@test "snapshot returns every gate-relevant field in one line" {
  seed_state changes_requested US-042 '["blocker one","blocker two"]'
  run wf snapshot
  [ "$status" -eq 0 ]
  # phase <TAB> story <TAB> findings <TAB> cycle <TAB> override
  [ "$(printf '%s' "$output" | cut -f1)" = "changes_requested" ]
  [ "$(printf '%s' "$output" | cut -f2)" = "US-042" ]
  [ "$(printf '%s' "$output" | cut -f3)" = "2" ]
}

@test "named accessors agree with snapshot" {
  seed_state under_review US-042 '["x"]'
  [ "$(wf get-phase)" = "under_review" ]
  [ "$(wf get-story)" = "US-042" ]
  [ "$(wf get-findings-count)" = "1" ]
}

@test "help works from outside a scaffolded project" {
  run bash -c "cd / && bash '$WF' --help"
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'Usage: workflow-state.sh'
}

@test "an unknown command exits nonzero" {
  run wf definitely-not-a-command
  [ "$status" -ne 0 ]
}

# --------------------------------------------------------------------------
# Transitions
# --------------------------------------------------------------------------

@test "forward transitions are allowed" {
  wf start US-001 "Test"
  wf advance discovery_complete
  wf advance plan_created
  wf advance plan_approved
  [ "$(phase_now)" = "plan_approved" ]
}

@test "D7: an illegal transition exits nonzero and says so" {
  seed_state review_passed
  run wf advance plan_created
  [ "$status" -ne 0 ]
  printf '%s' "$output" | grep -qi 'illegal transition' || {
    echo "expected an explanatory message, got: $output"; return 1; }
  [ "$(phase_now)" = "review_passed" ]   # unchanged
}

@test "an unknown phase name is rejected" {
  seed_state plan_approved
  run wf advance not_a_real_phase
  [ "$status" -ne 0 ]
  [ "$(phase_now)" = "plan_approved" ]
}

@test "changes_requested can go back to under_review" {
  seed_state changes_requested
  wf advance under_review
  [ "$(phase_now)" = "under_review" ]
}

@test "D4: review_passed can go back to under_review for a re-review" {
  # Without this edge, review_passed is a permanent pardon: pass once, then
  # rewrite anything and commit freely.
  seed_state review_passed
  wf advance under_review
  [ "$(phase_now)" = "under_review" ]
}

@test "entering under_review increments the review cycle" {
  seed_state implementation_in_progress
  wf advance under_review
  [ "$(wf get-review-cycle)" = "1" ]
  wf advance changes_requested
  wf advance under_review
  [ "$(wf get-review-cycle)" = "2" ]
}

@test "passing review clears stored findings" {
  seed_state changes_requested US-001 '["a","b"]'
  wf advance review_passed
  [ "$(wf get-findings-count)" = "0" ]
}

# --------------------------------------------------------------------------
# set-findings validation (eng review decision 6)
# --------------------------------------------------------------------------

@test "set-findings accepts a JSON array" {
  seed_state under_review
  wf set-findings '["missing auth check","no error path test"]'
  [ "$(wf get-findings-count)" = "2" ]
}

@test "set-findings rejects malformed input and leaves state alone" {
  seed_state under_review
  run wf set-findings 'not json at all'
  [ "$status" -ne 0 ]
  [ "$(phase_now)" = "under_review" ]
  [ "$(wf get-findings-count)" = "0" ]
}

@test "set-findings rejects a JSON object" {
  seed_state under_review
  run wf set-findings '{"blocker":"x"}'
  [ "$status" -ne 0 ]
}

# --------------------------------------------------------------------------
# Override
# --------------------------------------------------------------------------

@test "override is one-shot: the second consume fails" {
  seed_state implementation_in_progress
  wf override "hotfix, reviewer unavailable"
  wf consume-override
  run wf consume-override
  [ "$status" -ne 0 ]
}

@test "override records the reason" {
  seed_state implementation_in_progress
  wf override "hotfix, reviewer unavailable"
  reason="$("$JQ_REAL" -r '.override.reason' "$PROJECT_DIR/.claude/project/.workflow-state.json")"
  [ "$reason" = "hotfix, reviewer unavailable" ]
}

@test "an armed override lets exactly one commit through, then re-blocks" {
  cd "$PROJECT_DIR"
  seed_state implementation_in_progress
  wf override "justified"

  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "first"')"
  assert_allowed

  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "second"')"
  assert_blocked
}

# --------------------------------------------------------------------------
# Schema migration
# --------------------------------------------------------------------------

@test "a state file with no schemaVersion is migrated forward" {
  "$JQ_REAL" -n '{activeStory:"US-001", phase:"plan_created", storyTitle:"old"}' \
    > "$PROJECT_DIR/.claude/project/.workflow-state.json"
  wf advance plan_approved
  v="$("$JQ_REAL" -r '.schemaVersion' "$PROJECT_DIR/.claude/project/.workflow-state.json")"
  [ "$v" = "1" ]
  [ "$(phase_now)" = "plan_approved" ]
}

@test "a state file from a NEWER version is refused, not corrupted" {
  "$JQ_REAL" -n '{schemaVersion:99, activeStory:"US-001", phase:"plan_created"}' \
    > "$PROJECT_DIR/.claude/project/.workflow-state.json"
  run wf advance plan_approved
  [ "$status" -eq 4 ]
  [ "$(phase_now)" = "plan_created" ]   # untouched
}

# --------------------------------------------------------------------------
# Locking (eng review decision 8)
# --------------------------------------------------------------------------

@test "the lock is released after a write" {
  seed_state plan_created
  wf advance plan_approved
  [ ! -d "$PROJECT_DIR/.claude/project/.workflow-state.lock" ]
}

@test "a stale lock is reaped rather than deadlocking" {
  seed_state plan_created
  mkdir -p "$PROJECT_DIR/.claude/project/.workflow-state.lock"
  # Backdate it well past the timeout.
  touch -t 200001010000 "$PROJECT_DIR/.claude/project/.workflow-state.lock"
  WORKFLOW_LOCK_TIMEOUT=1 run bash -c "cd '$PROJECT_DIR' && bash '$WF' advance plan_approved"
  [ "$status" -eq 0 ]
  [ "$(phase_now)" = "plan_approved" ]
}

# --------------------------------------------------------------------------
# Audit trail and messaging
# --------------------------------------------------------------------------

@test "transitions are appended to the audit log" {
  wf start US-001 "Test"
  wf advance discovery_complete
  log="$PROJECT_DIR/.claude/project/.workflow-log.jsonl"
  [ -s "$log" ] || { echo "no audit log written"; return 1; }
  grep -q 'discovery_complete' "$log"
}

@test "why-blocked lists the stored blockers" {
  seed_state changes_requested US-001 '["missing auth check"]'
  run wf why-blocked
  printf '%s' "$output" | grep -q 'missing auth check'
}

@test "next-action renders a phase bar" {
  seed_state plan_approved
  run wf next-action
  printf '%s' "$output" | grep -q '\[approved\]'
  printf '%s' "$output" | grep -q 'US-001'
}
