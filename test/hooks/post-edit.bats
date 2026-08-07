#!/usr/bin/env bats
# post-edit.sh -- formatter dispatch, turn bookkeeping, phase advancement.

setup() {
  load '../helpers/setup'
  make_project
  stub_path
  mkdir -p "$PROJECT_DIR/src" "$PROJECT_DIR/app" "$PROJECT_DIR/cmd"
}

phase_now() {
  "$JQ_REAL" -r '.phase // "none"' "$PROJECT_DIR/.claude/project/.workflow-state.json"
}

edit_file() {
  echo "content" > "$PROJECT_DIR/$1"
  run_hook PostToolUse "Edit|Write" "$(payload_edit "$PROJECT_DIR/$1")"
}

# --------------------------------------------------------------------------
# D6 -- the formatter must not reach for the network
# --------------------------------------------------------------------------

@test "D6: no formatter config means npx is NEVER invoked" {
  # The old hook ran `npx prettier --write` on every js/ts/json/css/html/md
  # edit with stderr discarded. In a project without prettier that is a silent
  # network fetch on every single edit.
  seed_state plan_approved
  edit_file "src/app.ts"
  if stub_invoked npx; then
    echo "npx was invoked in a project with no formatter config"
    cat "$STUB_LOG"
    return 1
  fi
}

@test "D6: no formatter config means prettier is not invoked either" {
  seed_state plan_approved
  edit_file "src/styles.css"
  if stub_invoked prettier; then
    echo "prettier was invoked with no config present"
    cat "$STUB_LOG"
    return 1
  fi
}

@test "formatter runs when the project actually configures one" {
  echo '{}' > "$PROJECT_DIR/.prettierrc"
  seed_state plan_approved
  edit_file "src/app.ts"
  stub_invoked prettier || {
    echo "expected prettier to run when .prettierrc exists"
    cat "$STUB_LOG"; return 1; }
}

@test "python files only format when black is configured" {
  seed_state plan_approved
  edit_file "src/main.py"
  if stub_invoked black; then echo "black ran with no [tool.black] config"; return 1; fi

  printf '[tool.black]\n' > "$PROJECT_DIR/pyproject.toml"
  edit_file "src/other.py"
  stub_invoked black || { echo "black should run once configured"; cat "$STUB_LOG"; return 1; }
}

# --------------------------------------------------------------------------
# D5 / decision 12 -- typecheck bookkeeping moved off the per-edit path
# --------------------------------------------------------------------------

@test "D5: editing TS records the turn but does not typecheck inline" {
  seed_state plan_approved
  edit_file "src/app.ts"
  if stub_invoked tsc; then
    echo "tsc ran on the per-edit path; it belongs on Stop"
    cat "$STUB_LOG"; return 1
  fi
  [ -s "$PROJECT_DIR/.claude/project/.turn-touched" ] || {
    echo "expected the turn to be recorded for the Stop hook"; return 1; }
}

@test "editing non-TS files does not record a typecheck turn" {
  seed_state plan_approved
  edit_file "src/notes.txt"
  [ ! -s "$PROJECT_DIR/.claude/project/.turn-touched" ] || {
    echo "a .txt edit should not schedule a typecheck"; return 1; }
}

# --------------------------------------------------------------------------
# D1 / D8 -- phase advancement on source edits
# --------------------------------------------------------------------------

@test "D8: source detection covers app/, cmd/ and root packages, not just src/" {
  for f in "app/page.tsx" "cmd/main.go" "setup.py" "lib/util.rb"; do
    seed_state plan_approved
    mkdir -p "$PROJECT_DIR/$(dirname "$f")"
    edit_file "$f"
    got="$(phase_now)"
    if [ "$got" != "implementation_in_progress" ]; then
      echo "editing $f left phase at $got; the old gate only matched */src/*"
      return 1
    fi
  done
}

@test "markdown and tracking files do not start implementation" {
  for f in "README.md" "docs/notes.md"; do
    seed_state plan_approved
    mkdir -p "$PROJECT_DIR/$(dirname "$f")"
    edit_file "$f"
    got="$(phase_now)"
    if [ "$got" != "plan_approved" ]; then
      echo "editing $f advanced the phase to $got; docs are not implementation"
      return 1
    fi
  done
}

@test "a source edit during changes_requested does NOT reset the phase" {
  seed_state changes_requested
  edit_file "src/app.ts"
  got="$(phase_now)"
  [ "$got" = "changes_requested" ] || {
    echo "fixing review blockers must not rewind to implementation_in_progress"
    echo "phase is now: $got"; return 1; }
}

@test "writing a story file starts tracking and advances to discovery_complete" {
  mkdir -p "$PROJECT_DIR/.claude/project/features"
  edit_file ".claude/project/features/us-007-add-login.md"
  got="$(phase_now)"
  [ "$got" = "discovery_complete" ] || { echo "phase is $got"; return 1; }
  story="$("$JQ_REAL" -r '.activeStory' "$PROJECT_DIR/.claude/project/.workflow-state.json")"
  [ "$story" = "US-007" ] || { echo "story is $story, expected US-007"; return 1; }
}

@test "writing a plan advances to plan_created" {
  seed_state discovery_complete
  mkdir -p "$PROJECT_DIR/.claude/project/plans"
  edit_file ".claude/project/plans/us-007-plan.md"
  got="$(phase_now)"
  [ "$got" = "plan_created" ] || { echo "phase is $got"; return 1; }
}

@test "writing a plan with no story yet warns" {
  mkdir -p "$PROJECT_DIR/.claude/project/plans"
  edit_file ".claude/project/plans/us-009-plan.md"
  printf '%s' "$hook_output" | grep -q 'WORKFLOW GATE' || {
    echo "expected a warning about the missing feature spec"
    echo "$hook_output"; return 1; }
}
