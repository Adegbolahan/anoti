#!/usr/bin/env bats
# S-GAP1 REGRESSION (iron rule, mandatory)
#
# Claim: the commit gate is anchored to '^git commit' while every safety
# blocker in the same hook file is unanchored. Claude routinely emits compound
# commands, so `cd frontend && git commit -m x` walks straight past the gate.
#
# This is a second, independent hole in the same gate as D1.
#
# The false-positive test at the bottom passes TODAY (anchoring makes it
# impossible) and must keep passing after the anchor is removed -- that is the
# tradeoff decision 7A explicitly accepted.

setup() {
  load '../helpers/setup'
  make_project
  stub_path
  # Seed a phase the gate DOES handle, so these tests isolate the anchoring
  # bug rather than re-testing D1.
  seed_state implementation_in_progress
}

@test "CONTROL: a plain git commit is caught" {
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "wip"')"
  assert_blocked
}

@test "S-GAP1: 'cd frontend && git commit' must block" {
  run_hook PreToolUse Bash "$(payload_bash 'cd frontend && git commit -m "wip"')"
  assert_blocked
}

@test "S-GAP1: 'git add -A && git commit' must block" {
  run_hook PreToolUse Bash "$(payload_bash 'git add -A && git commit -m "wip"')"
  assert_blocked
}

@test "S-GAP1: 'npm test; git commit' must block" {
  run_hook PreToolUse Bash "$(payload_bash 'npm test; git commit -m "wip"')"
  assert_blocked
}

@test "S-GAP1: 'git -C . commit' must block" {
  run_hook PreToolUse Bash "$(payload_bash 'git -C . commit -m "wip"')"
  assert_blocked
}

@test "the unanchored safety blockers already catch compound commands" {
  # Proof that unanchored matching is the established pattern in this file:
  # the force-push blocker uses no anchor and catches the compound form.
  run_hook PreToolUse Bash "$(payload_bash 'cd frontend && git push --force')"
  assert_blocked
}

@test "ACCEPTED TRADEOFF: 'git commit' inside an echo DOES block" {
  # This is a false positive, and it is the documented cost of decision 7A
  # ("unanchored match, same as the safety blockers"). The gate cannot tell a
  # command from a quoted string without parsing shell syntax.
  #
  # It is asserted rather than deleted so the behaviour is a decision on the
  # record instead of a surprise. If it starts biting in practice, decision 7B
  # (strip quoted strings and heredocs before matching) is the upgrade, and
  # this test flips back to assert_allowed.
  run_hook PreToolUse Bash "$(payload_bash 'echo "remember to git commit later"')"
  assert_blocked
}

@test "the match is narrow enough to spare 'git log --grep=commit'" {
  # Requiring whitespace immediately before `commit` keeps the unanchored
  # pattern from swallowing every git command that merely mentions the word.
  run_hook PreToolUse Bash "$(payload_bash 'git log --grep=commit --oneline')"
  assert_allowed
}

@test "non-git commands mentioning commit are untouched" {
  run_hook PreToolUse Bash "$(payload_bash 'grep -rn commit src/')"
  assert_allowed
}
