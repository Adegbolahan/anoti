#!/usr/bin/env bash
# Shared harness for hook tests.
#
# Design note: these tests do NOT assert against hook command strings. They read
# .claude/settings.json with jq, extract every command registered for an
# event+matcher, pipe a payload into each, and treat the hook as BLOCKING if any
# command exits 2 -- which is how Claude Code actually behaves.
#
# That indirection is deliberate. Phase A moved hook bodies from inline strings
# into scripts, and Phase B relocates them into the plugin. Both times
# settings.json keeps registering the same events, so these tests keep working
# without a rewrite.
#
#   payload (JSON on stdin)
#        |
#        v
#   [ jq: read every command for event+matcher ]
#        |
#        +--> bash -c cmd_1 --> exit code ---+
#        +--> bash -c cmd_2 --> exit code ---+--> any 2? -> BLOCKED
#        +--> bash -c cmd_N --> exit code ---+          else -> ALLOWED

# shellcheck disable=SC2016
# The single-quoted blocks below are jq filter programs. Their $s / $p / $c
# are jq variables bound with --arg, not shell expansions, so single quotes
# are correct and required. Scoped to this file rather than per-line because
# every jq program here is affected.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATES_DIR="$REPO_ROOT/project-scaffolder/resources/templates"
FIXTURES_BIN="$REPO_ROOT/test/fixtures/bin"

# Resolve jq once, by absolute path. The harness needs jq even in tests that
# deliberately remove jq from the hook subprocess's PATH (see hide_jq).
JQ_REAL="$(command -v jq)"

# ---------------------------------------------------------------------------
# Project fixtures
# ---------------------------------------------------------------------------

# A scaffolded project: full .claude tree, git-initialised, state file absent.
make_project() {
  PROJECT_DIR="${BATS_TEST_TMPDIR:-$(mktemp -d)}/proj"
  mkdir -p "$PROJECT_DIR"
  cp -R "$TEMPLATES_DIR/.claude" "$PROJECT_DIR/.claude"
  chmod +x "$PROJECT_DIR/.claude/project/workflow-state.sh"
  chmod +x "$PROJECT_DIR"/.claude/project/hooks/*.sh
  git -C "$PROJECT_DIR" init -q
  git -C "$PROJECT_DIR" config user.email test@example.com
  git -C "$PROJECT_DIR" config user.name Test
  cd "$PROJECT_DIR" || return 1
}

# A bystander repo: hooks REGISTERED and present, but the project was never
# scaffolded -- no .claude/project/ at all.
#
# This simulates PHASE B, where the hook scripts ship inside the plugin and are
# therefore installed user-wide. That is the only arrangement in which the F1
# condition is reachable: in Phase A the scripts live under .claude/project/,
# so a repo cannot have the hooks without being scaffolded.
#
#   plugin/                       <- stands in for ${CLAUDE_PLUGIN_ROOT}
#     hooks/*.sh
#     workflow-state.sh
#   bystander/                    <- an ordinary repo you happen to open
#     .claude/settings.json       <- hooks registered, pointing at plugin/
#     src/
#     (no .claude/project/)
make_bystander_repo() {
  local root="${BATS_TEST_TMPDIR:-$(mktemp -d)}"
  PLUGIN_DIR="$root/plugin"
  mkdir -p "$PLUGIN_DIR"
  cp -R "$TEMPLATES_DIR/.claude/project/hooks" "$PLUGIN_DIR/hooks"
  cp "$TEMPLATES_DIR/.claude/project/workflow-state.sh" "$PLUGIN_DIR/workflow-state.sh"
  chmod +x "$PLUGIN_DIR"/hooks/*.sh "$PLUGIN_DIR/workflow-state.sh"

  PROJECT_DIR="$root/bystander"
  mkdir -p "$PROJECT_DIR/src" "$PROJECT_DIR/.claude"
  git -C "$PROJECT_DIR" init -q
  git -C "$PROJECT_DIR" config user.email test@example.com
  git -C "$PROJECT_DIR" config user.name Test

  # Repoint every hook command at the plugin location.
  "$JQ_REAL" --arg p "$PLUGIN_DIR" \
    '(.hooks[][].hooks[].command) |= sub("\\.claude/project/hooks/"; $p + "/hooks/")' \
    "$TEMPLATES_DIR/.claude/settings.json" > "$PROJECT_DIR/.claude/settings.json"

  cd "$PROJECT_DIR" || return 1
}

# Write the workflow state file directly, bypassing the CLI.
# Usage: seed_state <phase> [story] [findings-json]
seed_state() {
  local phase="$1" story="${2:-US-001}" findings="${3:-[]}"
  "$JQ_REAL" -n \
    --arg p "$phase" --arg s "$story" --argjson f "$findings" \
    '{schemaVersion:2, activeStory:$s, phase:$p, storyTitle:"Test Story",
      reviewCycle:0, reviewFindings:$f, override:null,
      lastSourceEditEpoch:0, reviewEvidence:null, timestamps:{}}' \
    > "$PROJECT_DIR/.claude/project/.workflow-state.json"
}

# The schema version the script under test considers current. Read it from the
# source rather than hardcoding, so a bump does not silently break tests that
# only care that migration happened.
current_schema_version() {
  grep -oE '^SCHEMA_VERSION=[0-9]+' \
    "$TEMPLATES_DIR/.claude/project/workflow-state.sh" | cut -d= -f2
}

# Write a review report and echo its path. Evidence must be newer than the last
# source edit; a freshly written file satisfies that.
write_evidence() {
  local dir="$PROJECT_DIR/.claude/project/reviews"
  mkdir -p "$dir"
  local f="$dir/${1:-report}.md"
  printf 'REVIEW: US-001 — clean\nACs: 3/3 met\nBlockers: none\n' > "$f"
  printf '%s' "$f"
}

# ---------------------------------------------------------------------------
# PATH control
# ---------------------------------------------------------------------------

# Prepend the stub bin so hooks get fake prettier/black/rustfmt/tsc/npx that
# record their invocations instead of touching the network or the real tools.
stub_path() {
  STUB_LOG="${BATS_TEST_TMPDIR:-/tmp}/invocations.log"
  : > "$STUB_LOG"
  export STUB_LOG
  export PATH="$FIXTURES_BIN:$PATH"
}

# Make jq non-functional for the hook subprocess.
#
# Two rejected approaches, both instructive:
#   - shim a jq that exits 127, and have production code test `command -v jq`.
#     The shim exists and is executable, so command -v succeeds and the code
#     takes the "jq is fine" branch.
#   - drop every PATH entry containing jq. That also removes dirname, git and
#     the rest of coreutils, so the hook fails for an unrelated reason.
#
# What actually works: shim jq to fail, and have production code test whether
# jq WORKS (`jq --version`) rather than whether a file named jq exists. That
# is the more honest check anyway -- a broken jq is as useless as a missing
# one, and both must block.
hide_jq() {
  local shim="${BATS_TEST_TMPDIR:-/tmp}/nojq"
  mkdir -p "$shim"
  printf '#!/usr/bin/env bash\nexit 127\n' > "$shim/jq"
  chmod +x "$shim/jq"
  export PATH="$shim:$PATH"
}

# Did any stub get invoked with the given substring?
stub_invoked() {
  [ -f "${STUB_LOG:-}" ] && grep -q -- "$1" "$STUB_LOG"
}

# ---------------------------------------------------------------------------
# Payload builders
# ---------------------------------------------------------------------------

payload_bash() {
  "$JQ_REAL" -nc --arg c "$1" \
    '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$c}}'
}

payload_edit() {
  "$JQ_REAL" -nc --arg f "$1" \
    '{hook_event_name:"PreToolUse", tool_name:"Edit", tool_input:{file_path:$f}}'
}

payload_prompt() {
  "$JQ_REAL" -nc --arg p "$1" '{hook_event_name:"UserPromptSubmit", prompt:$p}'
}

# ---------------------------------------------------------------------------
# Hook runner
# ---------------------------------------------------------------------------

# run_hook <event> <matcher|-> <payload>
# Sets: hook_status (0 allowed / 2 blocked), hook_output, hook_cmd_count
# A matcher of "-" selects hook groups that declare no matcher.
run_hook() {
  local event="$1" matcher="$2" payload="$3"
  local settings="$PROJECT_DIR/.claude/settings.json"
  local filter cmd out rc

  hook_output=""
  hook_status=0
  hook_cmd_count=0

  [ -f "$settings" ] || return 0

  if [ "$matcher" = "-" ]; then
    filter='.hooks[$e][]? | select(has("matcher") | not) | .hooks[].command'
  else
    filter='.hooks[$e][]? | select(.matcher == $m) | .hooks[].command'
  fi

  # One command per line. Hook commands in settings.json are single-line by
  # construction; ci.yml asserts that so this stays true.
  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    hook_cmd_count=$(( hook_cmd_count + 1 ))
    # Capture rc without touching set -e state (bats manages that itself).
    out="$(printf '%s' "$payload" | bash -c "$cmd" 2>&1)" && rc=0 || rc=$?
    hook_output="${hook_output}${out}"$'\n'
    # Claude Code blocks the tool call if ANY hook exits 2.
    [ "$rc" -eq 2 ] && hook_status=2
  done < <("$JQ_REAL" -r --arg e "$event" --arg m "$matcher" "$filter" "$settings" 2>/dev/null)

  return 0
}

# ---------------------------------------------------------------------------
# Assertions that say what actually went wrong
# ---------------------------------------------------------------------------

assert_blocked() {
  if [ "$hook_status" -ne 2 ]; then
    echo "EXPECTED BLOCK (exit 2), GOT ALLOW (exit $hook_status)"
    echo "commands run: $hook_cmd_count"
    echo "hook output: $hook_output"
    return 1
  fi
}

assert_allowed() {
  if [ "$hook_status" -ne 0 ]; then
    echo "EXPECTED ALLOW (exit 0), GOT BLOCK (exit $hook_status)"
    echo "commands run: $hook_cmd_count"
    echo "hook output: $hook_output"
    return 1
  fi
}
