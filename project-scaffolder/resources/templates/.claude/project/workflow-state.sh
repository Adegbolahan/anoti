#!/usr/bin/env bash
# Shim. The real state machine ships inside the project-scaffolder plugin and
# is versioned with it; this file only finds it and hands off.
#
# It exists so the invocation printed by the commit gate, the README and the
# scaffolded CLAUDE.md keeps working:
#
#     .claude/project/workflow-state.sh why-blocked
#     .claude/project/workflow-state.sh override "reason"
#
# There is no logic here on purpose. Nothing to drift, nothing to migrate.
# If the plugin is updated, this file still points at whatever it resolves to.

set -uo pipefail

find_state_machine() {
  # 1. Inside a hook, Claude Code sets this.
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT/bin/workflow-state.sh" ]; then
    printf '%s' "$CLAUDE_PLUGIN_ROOT/bin/workflow-state.sh"; return 0
  fi
  # 2. The path recorded when this project was scaffolded.
  if [ -f "[PLUGIN_ROOT]/bin/workflow-state.sh" ]; then
    printf '%s' "[PLUGIN_ROOT]/bin/workflow-state.sh"; return 0
  fi
  # 3. Search the plugin tree. Covers the case where an update moved it.
  local found
  found=$(find "$HOME/.claude/plugins" -type f \
            -path '*/project-scaffolder/bin/workflow-state.sh' 2>/dev/null | head -1)
  [ -n "$found" ] && { printf '%s' "$found"; return 0; }
  return 1
}

BIN="$(find_state_machine || true)"
if [ -z "$BIN" ]; then
  echo "workflow-state: cannot find the project-scaffolder plugin." >&2
  echo "  Is it still installed?  /plugin install project-scaffolder@getting-started-claude" >&2
  echo "  Then re-run /update to refresh this shim." >&2
  exit 1
fi

exec bash "$BIN" "$@"
