#!/usr/bin/env bash
# Shared harness for hook tests.
#
# Since v3.0.0 the hooks ship INSIDE the plugin and are registered by
# hooks/hooks.json, not by the project's settings.json. The fixtures mirror
# that arrangement exactly:
#
#   $TMPDIR/plugin/               <- stands in for ${CLAUDE_PLUGIN_ROOT}
#     hooks/hooks.json
#     hooks/*.sh
#     bin/workflow-state.sh
#   $TMPDIR/proj/                 <- the project
#     .claude/settings.json       (version tracking only, no hooks)
#     .claude/project/            tracking files + the shim
#
# Tests never assert against hook command strings. They read hooks.json,
# extract every command registered for an event+matcher, expand
# ${CLAUDE_PLUGIN_ROOT}, pipe a payload in, and treat the hook as BLOCKING if
# any command exits 2 -- which is how Claude Code actually behaves.
#
#   payload (JSON on stdin)
#        |
#        v
#   [ jq: every command for event+matcher, from hooks.json ]
#        |
#        +--> bash -c cmd_1 --> exit code ---+
#        +--> bash -c cmd_N --> exit code ---+--> any 2? -> BLOCKED
#                                                    else -> ALLOWED

# shellcheck disable=SC2016
# The single-quoted blocks below are jq filter programs. Their $s / $p / $c are
# jq variables bound with --arg, not shell expansions, so single quotes are
# correct and required. Scoped to this file because every jq program here is
# affected.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLUGIN_SRC="$REPO_ROOT/project-scaffolder"
TEMPLATES_DIR="$PLUGIN_SRC/resources/templates"
FIXTURES_BIN="$REPO_ROOT/test/fixtures/bin"

# Resolve jq once, by absolute path. The harness needs jq even in tests that
# deliberately break jq for the hook subprocess (see hide_jq).
JQ_REAL="$(command -v jq)"

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

# Stand up a copy of the plugin. Sets PLUGIN_DIR.
_install_plugin() {
  PLUGIN_DIR="${BATS_TEST_TMPDIR:-$(mktemp -d)}/plugin"
  mkdir -p "$PLUGIN_DIR"
  cp -R "$PLUGIN_SRC/hooks"     "$PLUGIN_DIR/hooks"
  cp -R "$PLUGIN_SRC/bin"       "$PLUGIN_DIR/bin"
  # resources/ carries the shim template that migrate-pre-v3.sh installs.
  # Omitting it made the migration write an EMPTY shim that still passed its
  # own verification, because `bash empty-file` exits 0.
  cp -R "$PLUGIN_SRC/resources" "$PLUGIN_DIR/resources"
  chmod +x "$PLUGIN_DIR"/hooks/*.sh "$PLUGIN_DIR"/bin/*.sh
}

# A scaffolded project with the plugin installed.
make_project() {
  _install_plugin
  PROJECT_DIR="${BATS_TEST_TMPDIR:-$(mktemp -d)}/proj"
  mkdir -p "$PROJECT_DIR"
  cp -R "$TEMPLATES_DIR/.claude" "$PROJECT_DIR/.claude"
  # /new bakes the resolved plugin path into the shim; do the same here.
  sed -i.bak "s|\[PLUGIN_ROOT\]|$PLUGIN_DIR|g" \
    "$PROJECT_DIR/.claude/project/workflow-state.sh"
  rm -f "$PROJECT_DIR/.claude/project/workflow-state.sh.bak"
  chmod +x "$PROJECT_DIR/.claude/project/workflow-state.sh"
  git -C "$PROJECT_DIR" init -q
  git -C "$PROJECT_DIR" config user.email test@example.com
  git -C "$PROJECT_DIR" config user.name Test
  export CLAUDE_PROJECT_DIR="$PROJECT_DIR"
  cd "$PROJECT_DIR" || return 1
}

# A repo the plugin is installed for but which was never scaffolded -- no
# .claude/project/ at all. This is every other repository on the machine once
# the plugin is installed user-wide (finding F1).
make_bystander_repo() {
  _install_plugin
  PROJECT_DIR="${BATS_TEST_TMPDIR:-$(mktemp -d)}/bystander"
  mkdir -p "$PROJECT_DIR/src"
  git -C "$PROJECT_DIR" init -q
  git -C "$PROJECT_DIR" config user.email test@example.com
  git -C "$PROJECT_DIR" config user.name Test
  export CLAUDE_PROJECT_DIR="$PROJECT_DIR"
  cd "$PROJECT_DIR" || return 1
}

# Write the workflow state file directly, bypassing the CLI.
seed_state() {
  local phase="$1" story="${2:-US-001}" findings="${3:-[]}"
  "$JQ_REAL" -n \
    --arg p "$phase" --arg s "$story" --argjson f "$findings" \
    '{schemaVersion:2, activeStory:$s, phase:$p, storyTitle:"Test Story",
      reviewCycle:0, reviewFindings:$f, override:null,
      lastSourceEditEpoch:0, reviewEvidence:null, timestamps:{}}' \
    > "$PROJECT_DIR/.claude/project/.workflow-state.json"
}

# The schema version the script under test considers current. Read from source
# rather than hardcoded, so a bump does not break tests that only care that
# migration ran.
current_schema_version() {
  grep -oE '^SCHEMA_VERSION=[0-9]+' "$PLUGIN_SRC/bin/workflow-state.sh" | cut -d= -f2
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

stub_path() {
  STUB_LOG="${BATS_TEST_TMPDIR:-/tmp}/invocations.log"
  : > "$STUB_LOG"
  export STUB_LOG
  export PATH="$FIXTURES_BIN:$PATH"
}

# Make jq non-functional for the hook subprocess.
#
# Shimming a jq that exits 127 only works because production code tests whether
# jq WORKS (`jq --version`) rather than whether a file named jq exists. Dropping
# every PATH entry containing jq was tried and removes coreutils with it.
hide_jq() {
  local shim="${BATS_TEST_TMPDIR:-/tmp}/nojq"
  mkdir -p "$shim"
  printf '#!/usr/bin/env bash\nexit 127\n' > "$shim/jq"
  chmod +x "$shim/jq"
  export PATH="$shim:$PATH"
}

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

# run_hook <event> <matcher> <payload>
# Sets: hook_status (0 allowed / 2 blocked), hook_output, hook_cmd_count
run_hook() {
  local event="$1" matcher="$2" payload="$3"
  local manifest="$PLUGIN_DIR/hooks/hooks.json"
  local cmd out rc

  hook_output=""
  hook_status=0
  hook_cmd_count=0

  [ -f "$manifest" ] || return 0

  # One command per line. ci.yml asserts hook commands are single-line.
  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    # Claude Code expands this; the harness must too.
    cmd="${cmd//\$\{CLAUDE_PLUGIN_ROOT\}/$PLUGIN_DIR}"
    hook_cmd_count=$(( hook_cmd_count + 1 ))
    out="$(printf '%s' "$payload" | bash -c "$cmd" 2>&1)" && rc=0 || rc=$?
    hook_output="${hook_output}${out}"$'\n'
    # Claude Code blocks the tool call if ANY hook exits 2.
    [ "$rc" -eq 2 ] && hook_status=2
  done < <("$JQ_REAL" -r --arg e "$event" --arg m "$matcher" \
             '.hooks[$e][]? | select(.matcher == $m or .matcher == "*") | .hooks[].command' \
             "$manifest" 2>/dev/null)

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
