#!/usr/bin/env bats
# F1 BYSTANDER (eng review, Section 1, confidence 10/10)
#
# Plugin hooks are installed user-wide and fire in EVERY repository:
#   "Plugin hooks merge with user's hooks and run in parallel."
#   -- plugin-dev/skills/hook-development/SKILL.md:383
#
# There is no project-scoping mechanism. So once Phase B moves the hook suite
# into the plugin, these hooks run in every repo the user opens.
#
# IMPORTANT: these tests PASS today, and that is the point. Today the gate
# fails OPEN, which happens to give the right answer for a bystander repo. The
# moment fail-closed lands (CEO decision 1), "no .claude/project/" becomes an
# unconfirmable state and the gate would block commits in every unrelated
# repository on the machine.
#
# This file is the guard rail for that fix. It must stay green through it.

setup() {
  load '../helpers/setup'
  make_bystander_repo
  stub_path
}

@test "F1: commit gate must not block in a repo with no .claude/project/" {
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "unrelated work"')"
  assert_allowed
}

@test "F1: gate must not block a compound commit in a bystander repo" {
  # After S-GAP1 unanchors the match, this is the case most likely to regress.
  run_hook PreToolUse Bash "$(payload_bash 'cd sub && git commit -m "unrelated"')"
  assert_allowed
}

@test "F1: hooks must stay silent in a bystander repo" {
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "unrelated work"')"
  cleaned="$(printf '%s' "$hook_output" | tr -d '[:space:]')"
  if [ -n "$cleaned" ]; then
    echo "EXPECTED no output in an unscaffolded repo"
    echo "GOT: $hook_output"
    return 1
  fi
}

@test "F1: source edits must not be gated in a bystander repo" {
  echo "const x = 1" > "$PROJECT_DIR/src/app.ts"
  run_hook PreToolUse "Edit|Write" "$(payload_edit "$PROJECT_DIR/src/app.ts")"
  assert_allowed
}

@test "F1: no state file may be created in a bystander repo" {
  run_hook PreToolUse Bash "$(payload_bash 'git commit -m "unrelated work"')"
  run_hook PostToolUse Bash "$(payload_bash 'git commit -m "unrelated work"')"
  if [ -e "$PROJECT_DIR/.claude/project/.workflow-state.json" ]; then
    echo "hooks created workflow state in a repo that was never scaffolded"
    return 1
  fi
}

@test "F1: the safety blockers SHOULD still fire in a bystander repo" {
  # Deliberate asymmetry. The workflow gate is project-scoped; blocking
  # force-push and --no-verify is a global safety property worth keeping.
  run_hook PreToolUse Bash "$(payload_bash 'git push --force')"
  assert_blocked
}
