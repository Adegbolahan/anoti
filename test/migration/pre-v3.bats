#!/usr/bin/env bats
# migrate-pre-v3.sh -- moving copied workflow components out of a project.
#
# This deletes from a user's repository, which is why it is a script with tests
# rather than prose for a model to interpret. Every test here is about NOT
# destroying something.

setup() {
  load '../helpers/setup'
  _install_plugin
  MIGRATE="$PLUGIN_DIR/bin/migrate-pre-v3.sh"
  PROJECT_DIR="${BATS_TEST_TMPDIR}/legacy"
  mkdir -p "$PROJECT_DIR"
  git -C "$PROJECT_DIR" init -q
  export CLAUDE_PROJECT_DIR="$PROJECT_DIR"
}

# A project as it looked before v3: workflow components copied in.
make_pre_v3_project() {
  mkdir -p "$PROJECT_DIR/.claude/commands" \
           "$PROJECT_DIR/.claude/skills/development-workflow" \
           "$PROJECT_DIR/.claude/project/hooks" \
           "$PROJECT_DIR/.claude/project/features" \
           "$PROJECT_DIR/.claude/project/plans"
  echo "old implement" > "$PROJECT_DIR/.claude/commands/implement.md"
  echo "old review"    > "$PROJECT_DIR/.claude/commands/review.md"
  echo "old skill"     > "$PROJECT_DIR/.claude/skills/development-workflow/SKILL.md"
  echo "old hook"      > "$PROJECT_DIR/.claude/project/hooks/pre-bash.sh"
  echo "#!/usr/bin/env bash
# the old state machine, not a shim
echo old" > "$PROJECT_DIR/.claude/project/workflow-state.sh"
  # The user's own work, which must survive untouched.
  echo "my project"   > "$PROJECT_DIR/CLAUDE.md"
  echo "US-001 spec"  > "$PROJECT_DIR/.claude/project/features/us-001-login.md"
  echo "US-001 plan"  > "$PROJECT_DIR/.claude/project/plans/us-001-plan.md"
  echo "my roadmap"   > "$PROJECT_DIR/.claude/project/roadmap.md"
  "$JQ_REAL" -n '{scaffoldVersion:"2.1.0", permissions:{allow:["Read(x)"]},
                  hooks:{PreToolUse:[{matcher:"Bash",hooks:[{type:"command",command:"old"}]}]}}' \
    > "$PROJECT_DIR/.claude/settings.json"
}

run_migrate() { ( cd "$PROJECT_DIR" && bash "$MIGRATE" "$@" ); }

# --------------------------------------------------------------------------
# Refusals — the tests that matter most
# --------------------------------------------------------------------------

@test "refuses to run outside a scaffolded project" {
  # No .claude at all. Must not touch anything.
  mkdir -p "$PROJECT_DIR/src"
  echo "important" > "$PROJECT_DIR/src/app.ts"
  run run_migrate
  [ "$status" -ne 0 ]
  [ -f "$PROJECT_DIR/src/app.ts" ]
}

@test "refuses when .claude exists but settings.json does not" {
  # A bare .claude directory is not proof this plugin scaffolded it.
  mkdir -p "$PROJECT_DIR/.claude/commands"
  echo "someone else's file" > "$PROJECT_DIR/.claude/commands/thing.md"
  run run_migrate
  [ "$status" -ne 0 ]
  [ -f "$PROJECT_DIR/.claude/commands/thing.md" ]
}

@test "a project with nothing to migrate exits cleanly and changes nothing" {
  mkdir -p "$PROJECT_DIR/.claude/project"
  echo '{"scaffoldVersion":"3.0.0"}' > "$PROJECT_DIR/.claude/settings.json"
  run run_migrate
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -qi 'nothing to migrate'
  [ ! -d "$PROJECT_DIR/.claude/.backup-pre-v3" ]
}

# --------------------------------------------------------------------------
# Dry run
# --------------------------------------------------------------------------

@test "--dry-run reports what would move and moves nothing" {
  make_pre_v3_project
  run run_migrate --dry-run
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'would move'
  [ -d "$PROJECT_DIR/.claude/commands" ]
  [ -d "$PROJECT_DIR/.claude/skills" ]
  [ ! -d "$PROJECT_DIR/.claude/.backup-pre-v3" ]
}

# --------------------------------------------------------------------------
# The migration itself
# --------------------------------------------------------------------------

@test "moves the copied components and leaves originals in the backup" {
  make_pre_v3_project
  run run_migrate
  [ "$status" -eq 0 ]
  [ ! -d "$PROJECT_DIR/.claude/commands" ]
  [ ! -d "$PROJECT_DIR/.claude/skills" ]
  [ ! -d "$PROJECT_DIR/.claude/project/hooks" ]
  # Nothing was destroyed, only moved.
  [ -f "$PROJECT_DIR/.claude/.backup-pre-v3/commands/implement.md" ]
  [ -f "$PROJECT_DIR/.claude/.backup-pre-v3/skills/development-workflow/SKILL.md" ]
  [ -f "$PROJECT_DIR/.claude/.backup-pre-v3/hooks/pre-bash.sh" ]
  [ -f "$PROJECT_DIR/.claude/.backup-pre-v3/workflow-state.sh" ]
}

@test "NEVER touches the user's own work" {
  make_pre_v3_project
  run_migrate
  [ "$(cat "$PROJECT_DIR/CLAUDE.md")" = "my project" ]
  [ "$(cat "$PROJECT_DIR/.claude/project/features/us-001-login.md")" = "US-001 spec" ]
  [ "$(cat "$PROJECT_DIR/.claude/project/plans/us-001-plan.md")" = "US-001 plan" ]
  [ "$(cat "$PROJECT_DIR/.claude/project/roadmap.md")" = "my roadmap" ]
}

@test "installs a working shim in place of the old state machine" {
  make_pre_v3_project
  run_migrate
  W="$PROJECT_DIR/.claude/project/workflow-state.sh"
  [ -f "$W" ]
  grep -q 'Shim' "$W"
  # And it actually reaches the plugin.
  run bash "$W" --help
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'Usage: workflow-state.sh'
}

@test "strips the hooks block from settings.json but keeps permissions" {
  make_pre_v3_project
  run_migrate
  S="$PROJECT_DIR/.claude/settings.json"
  # A hooks block left behind would shadow the plugin's hooks.
  run "$JQ_REAL" -e '.hooks' "$S"
  [ "$status" -ne 0 ]
  [ "$("$JQ_REAL" -r '.permissions.allow[0]' "$S")" = "Read(x)" ]
}

@test "writes the restart marker, because hooks load at session start" {
  make_pre_v3_project
  run_migrate
  [ -s "$PROJECT_DIR/.claude/project/.upgrade-pending" ]
}

@test "says restart, loudly" {
  make_pre_v3_project
  run run_migrate
  printf '%s' "$output" | grep -qi 'RESTART CLAUDE CODE'
}

@test "prints a manifest naming every item it moved" {
  make_pre_v3_project
  run run_migrate
  for f in commands skills hooks workflow-state.sh; do
    printf '%s' "$output" | grep -q "$f" || {
      echo "manifest never mentioned $f"; echo "$output"; return 1; }
  done
}

# --------------------------------------------------------------------------
# Idempotency — /update may be run twice
# --------------------------------------------------------------------------

@test "running twice is safe and does not clobber the first backup" {
  make_pre_v3_project
  run_migrate
  first="$(cat "$PROJECT_DIR/.claude/.backup-pre-v3/commands/implement.md")"

  run run_migrate
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -qi 'nothing to migrate'
  # The shim is not mistaken for the old state machine and re-moved.
  [ "$(cat "$PROJECT_DIR/.claude/.backup-pre-v3/commands/implement.md")" = "$first" ]
  grep -q 'Shim' "$PROJECT_DIR/.claude/project/workflow-state.sh"
}

# --------------------------------------------------------------------------
# SessionStart clears the marker
# --------------------------------------------------------------------------

@test "SessionStart confirms the upgrade and clears the marker" {
  make_pre_v3_project
  run_migrate
  mkdir -p "$PROJECT_DIR/.claude/project"
  run bash "$PLUGIN_DIR/hooks/session-start.sh" </dev/null
  printf '%s' "$output" | grep -qi 'upgraded and now active'
  [ ! -f "$PROJECT_DIR/.claude/project/.upgrade-pending" ]
}
