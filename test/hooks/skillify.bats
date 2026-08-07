#!/usr/bin/env bats
# skillify-check.sh -- the capture suggestion at story completion.
#
# Two properties matter more than the feature itself:
#   1. it fires ONLY on a completed story, once, ever
#   2. it can never fail the turn
#
# A suggestion that appears on every Stop is noise, and noise here trains people
# to ignore everything the hook suite says.

setup() {
  load '../helpers/setup'
  make_project
  stub_path
  CHECK="$PLUGIN_DIR/hooks/skillify-check.sh"
  STATE_DIR="$PROJECT_DIR/.claude/project"
}

check() { bash "$CHECK" "$STATE_DIR" 2>&1; }

# --------------------------------------------------------------------------
# When it must stay silent
# --------------------------------------------------------------------------

@test "silent when no state file exists" {
  run check
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent at every phase except complete" {
  for p in discovery_started plan_approved implementation_in_progress \
           under_review changes_requested review_passed; do
    seed_state "$p"
    run check
    [ "$status" -eq 0 ]
    if [ -n "$output" ]; then
      echo "fired at phase=$p, should only fire at complete"
      echo "$output"; return 1
    fi
  done
}

@test "silent when jq is unavailable" {
  seed_state complete
  hide_jq
  run check
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when there is no active story" {
  "$JQ_REAL" -n '{schemaVersion:2, phase:"complete", activeStory:null}' \
    > "$STATE_DIR/.workflow-state.json"
  run check
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when handed a directory that does not exist" {
  run bash "$CHECK" "/nope/not/here"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when handed no argument at all" {
  run bash "$CHECK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --------------------------------------------------------------------------
# When it should fire
# --------------------------------------------------------------------------

@test "fires once when a story completes" {
  seed_state complete US-007
  run check
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'US-007'
  printf '%s' "$output" | grep -qi 'worth capturing'
}

@test "carries the worth-it bar so the model applies it" {
  seed_state complete
  run check
  printf '%s' "$output" | grep -qi 'two or more stories'
  printf '%s' "$output" | grep -qi 'convention'
  printf '%s' "$output" | grep -qi 'non-obvious'
}

@test "tells the model to say nothing when the bar is not met" {
  seed_state complete
  run check
  printf '%s' "$output" | grep -qi 'say nothing and move on'
}

@test "lists existing skills so duplicates can be ruled out" {
  mkdir -p "$PROJECT_DIR/.claude/skills/tenant-isolation"
  echo "x" > "$PROJECT_DIR/.claude/skills/tenant-isolation/SKILL.md"
  seed_state complete
  run check
  printf '%s' "$output" | grep -q 'tenant-isolation'
  # And the plugin's own skills, which a proposal must not duplicate either.
  printf '%s' "$output" | grep -q 'development-workflow'
}

@test "does not create anything on its own" {
  seed_state complete
  check >/dev/null
  [ ! -d "$PROJECT_DIR/.claude/skills" ] || \
    [ -z "$(ls -A "$PROJECT_DIR/.claude/skills" 2>/dev/null)" ]
}

# --------------------------------------------------------------------------
# GUARD: once per story, ever
# --------------------------------------------------------------------------

@test "never fires twice for the same story" {
  seed_state complete US-007
  first="$(check)"
  [ -n "$first" ]
  second="$(check)"
  if [ -n "$second" ]; then
    echo "fired a second time for the same story"; echo "$second"; return 1
  fi
}

@test "re-entering complete does not re-fire" {
  # An amended commit can land the phase back on complete.
  seed_state complete US-007
  check >/dev/null
  seed_state review_passed US-007
  seed_state complete US-007
  run check
  [ -z "$output" ]
}

@test "a different story still gets its own suggestion" {
  seed_state complete US-007
  check >/dev/null
  seed_state complete US-008
  run check
  printf '%s' "$output" | grep -q 'US-008'
}

# --------------------------------------------------------------------------
# It must never fail the turn
# --------------------------------------------------------------------------

@test "exits 0 even when the state file is corrupt" {
  printf 'not json{{{' > "$STATE_DIR/.workflow-state.json"
  run check
  [ "$status" -eq 0 ]
}

@test "exits 0 when the marker file cannot be written" {
  seed_state complete
  chmod 500 "$STATE_DIR"
  run check
  status_seen="$status"
  chmod 755 "$STATE_DIR"
  [ "$status_seen" -eq 0 ]
}

@test "the Stop hook still succeeds when skillify would fire" {
  seed_state complete US-007
  run bash "$PLUGIN_DIR/hooks/stop.sh" </dev/null
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -q 'US-007'
}
