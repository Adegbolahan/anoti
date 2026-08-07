#!/usr/bin/env bats
# The shim at .claude/project/workflow-state.sh.
#
# It has three ways to find the plugin, tried in order, because a plugin update
# can move the directory out from under a baked-in path:
#
#   1. $CLAUDE_PLUGIN_ROOT      set by Claude Code inside a hook
#   2. the path baked in at scaffold time
#   3. a search of ~/.claude/plugins
#
# If all three miss it must say so clearly, not fail silently — this is the file
# users are told to run when the gate blocks them.

setup() {
  load '../helpers/setup'
  _install_plugin
  SHIM_SRC="$PLUGIN_SRC/resources/templates/.claude/project/workflow-state.sh"
  PROJECT_DIR="${BATS_TEST_TMPDIR}/proj"
  mkdir -p "$PROJECT_DIR/.claude/project"
  git -C "$PROJECT_DIR" init -q
  SHIM="$PROJECT_DIR/.claude/project/workflow-state.sh"
}

# Install the shim with a given baked path.
install_shim() {
  sed "s|\[PLUGIN_ROOT\]|${1:-/nonexistent/plugin}|g" "$SHIM_SRC" > "$SHIM"
  chmod +x "$SHIM"
}

@test "resolves via the baked-in path" {
  install_shim "$PLUGIN_DIR"
  unset CLAUDE_PLUGIN_ROOT
  run bash "$SHIM" --help
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'Usage: workflow-state.sh'
}

@test "prefers CLAUDE_PLUGIN_ROOT over the baked path" {
  # Baked path is wrong; the env var is right. This is the hook case.
  install_shim "/nonexistent/plugin"
  CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" run bash "$SHIM" --help
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'Usage: workflow-state.sh'
}

@test "ignores CLAUDE_PLUGIN_ROOT when it points somewhere without the binary" {
  # A stale env var must not shadow a good baked path.
  install_shim "$PLUGIN_DIR"
  CLAUDE_PLUGIN_ROOT="${BATS_TEST_TMPDIR}/empty" run bash "$SHIM" --help
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'Usage: workflow-state.sh'
}

@test "falls back to searching ~/.claude/plugins when both paths are dead" {
  install_shim "/nonexistent/plugin"
  fake_home="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$fake_home/.claude/plugins/somewhere/project-scaffolder"
  cp -R "$PLUGIN_DIR/bin" "$fake_home/.claude/plugins/somewhere/project-scaffolder/bin"
  unset CLAUDE_PLUGIN_ROOT
  HOME="$fake_home" run bash "$SHIM" --help
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'Usage: workflow-state.sh'
}

@test "fails loudly, with instructions, when the plugin is gone entirely" {
  install_shim "/nonexistent/plugin"
  unset CLAUDE_PLUGIN_ROOT
  HOME="${BATS_TEST_TMPDIR}/empty-home" run bash "$SHIM" why-blocked
  [ "$status" -ne 0 ]
  printf '%s' "$output" | grep -qi 'cannot find the project-scaffolder plugin'
  printf '%s' "$output" | grep -q '/plugin install'
}

@test "passes arguments through, not just --help" {
  install_shim "$PLUGIN_DIR"
  unset CLAUDE_PLUGIN_ROOT
  export CLAUDE_PROJECT_DIR="$PROJECT_DIR"
  ( cd "$PROJECT_DIR" && bash "$SHIM" start US-042 "Shim test" )
  run bash -c "cd '$PROJECT_DIR' && bash '$SHIM' get-story"
  [ "$status" -eq 0 ]
  [ "$output" = "US-042" ]
}

@test "the shim carries no logic of its own" {
  # If this file ever grows behaviour, it becomes something that can drift —
  # which is the entire reason the state machine moved into the plugin.
  install_shim "$PLUGIN_DIR"
  for forbidden in 'phase_rank' 'advance)' 'jq ' 'write_state'; do
    if grep -q "$forbidden" "$SHIM"; then
      echo "shim contains '$forbidden' — it should only resolve and exec"
      return 1
    fi
  done
}
