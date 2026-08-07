#!/usr/bin/env bats
# A2 REGRESSION (iron rule, mandatory)
#
# Claim: jq is a hard dependency and a single point of failure that silently
# DISABLES the gate.
#
# workflow-state.sh exits 1 when jq is absent. Every caller in settings.json
# swallows that with `2>/dev/null || echo none`, so phase becomes "none", the
# case statement has no "none" branch, it falls through, and the commit is
# allowed. On any machine without jq the enforcement suite is off and says
# nothing about it.
#
# Same shape for a corrupt or unwritable state file: every path that cannot
# read state ends in exit 0.

setup() {
  load '../helpers/setup'
  make_project
  stub_path
}

@test "CONTROL: the gate blocks while jq is available" {
  seed_state implementation_in_progress
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "wip"')"
  assert_blocked
}

@test "A2: missing jq must block, not silently disable the gate" {
  seed_state implementation_in_progress
  hide_jq
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "wip"')"
  assert_blocked
}

@test "A2: a corrupt state file must block" {
  seed_state implementation_in_progress
  printf 'this is not json{{{' > "$PROJECT_DIR/.claude/project/.workflow-state.json"
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "wip"')"
  assert_blocked
}

@test "A2: an unrecognised phase string must block" {
  seed_state totally_bogus_phase
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "wip"')"
  assert_blocked
}

@test "A2: an unreadable state file must block" {
  seed_state implementation_in_progress
  chmod 000 "$PROJECT_DIR/.claude/project/.workflow-state.json"
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "wip"')"
  status_seen="$hook_status"
  chmod 644 "$PROJECT_DIR/.claude/project/.workflow-state.json"
  [ "$status_seen" -eq 2 ]
}

@test "A2: a block caused by missing jq must explain itself" {
  seed_state implementation_in_progress
  hide_jq
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "wip"')"

  # Fail-closed is only half the fix. A block with no explanation is a block
  # the user cannot act on. Assert the block FIRST -- otherwise a stray
  # "jq: command not found" on stderr satisfies the grep while the gate is
  # wide open.
  assert_blocked

  if ! printf '%s' "$hook_output" | grep -qi 'COMMIT GATE'; then
    echo "EXPECTED a deliberate gate message, not an incidental shell error"
    echo "GOT: $hook_output"
    return 1
  fi
  if ! printf '%s' "$hook_output" | grep -qi 'jq'; then
    echo "EXPECTED the gate message to name jq as the missing dependency"
    echo "GOT: $hook_output"
    return 1
  fi
}
