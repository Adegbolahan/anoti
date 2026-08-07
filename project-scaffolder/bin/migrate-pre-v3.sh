#!/usr/bin/env bash
# Migrate a pre-v3 project: move the copied workflow components out of the repo
# so the plugin's versions are the ones that run.
#
# WHY THIS IS A SCRIPT AND NOT PROSE IN /update
#
# It deletes files from a user's repository. A destructive operation described
# in markdown and carried out by a model is precisely the failure mode this
# plugin exists to prevent. Here it is deterministic, refuses to run outside a
# scaffolded project, backs up before removing anything, prints a manifest, and
# has tests.
#
#   .claude/commands/                 ─┐
#   .claude/skills/                    ├─ mv ─> .claude/.backup-pre-v3/
#   .claude/project/hooks/             │
#   .claude/project/workflow-state.sh ─┘        (then replaced by the shim)
#
# NEVER touched: CLAUDE.md, features/, plans/, roadmap.md,
# high-level-user-stories.md, or anything else the user wrote.
#
# Usage:
#   migrate-pre-v3.sh [--dry-run]
#
# Exit codes: 0 done or nothing to do · 1 refused (not a scaffolded project)

set -uo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

resolve_project_root() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"; return 0
  fi
  local top
  if top=$(git rev-parse --show-toplevel 2>/dev/null) && [ -d "$top/.claude" ]; then
    printf '%s' "$top"; return 0
  fi
  [ -d "$PWD/.claude" ] && { printf '%s' "$PWD"; return 0; }
  return 1
}

ROOT="$(resolve_project_root || true)"
if [ -z "$ROOT" ]; then
  echo "migrate: not inside a scaffolded project (no .claude directory found)" >&2
  exit 1
fi
if [ ! -f "$ROOT/.claude/settings.json" ]; then
  echo "migrate: $ROOT/.claude/settings.json is missing — refusing to touch this directory" >&2
  exit 1
fi

BACKUP="$ROOT/.claude/.backup-pre-v3"

# Only these four. Everything else in .claude/project/ is the user's.
CANDIDATES=(
  ".claude/commands"
  ".claude/skills"
  ".claude/project/hooks"
)

moved=0
say() { [ "$DRY_RUN" = 1 ] && printf 'would %s\n' "$*" || printf '%s\n' "$*"; }

for rel in "${CANDIDATES[@]}"; do
  [ -e "$ROOT/$rel" ] || continue
  say "move $rel -> .claude/.backup-pre-v3/$(basename "$rel")"
  if [ "$DRY_RUN" = 0 ]; then
    mkdir -p "$BACKUP"
    rm -rf "${BACKUP:?}/$(basename "$rel")"
    mv "$ROOT/$rel" "$BACKUP/" || { echo "migrate: failed to move $rel" >&2; exit 1; }
  fi
  moved=$(( moved + 1 ))
done

# workflow-state.sh is special: it is replaced by the shim rather than just
# removed, and a project already on v3 has the shim (not the state machine).
WS="$ROOT/.claude/project/workflow-state.sh"
if [ -f "$WS" ] && ! grep -q 'Shim\. The real state machine ships inside' "$WS" 2>/dev/null; then
  say "move .claude/project/workflow-state.sh -> .claude/.backup-pre-v3/ (replaced by a shim)"
  if [ "$DRY_RUN" = 0 ]; then
    mkdir -p "$BACKUP"
    rm -f "$BACKUP/workflow-state.sh"
    mv "$WS" "$BACKUP/workflow-state.sh"
  fi
  moved=$(( moved + 1 ))
fi

if [ "$moved" -eq 0 ]; then
  echo "Nothing to migrate — this project has no pre-v3 copies."
  exit 0
fi

if [ "$DRY_RUN" = 1 ]; then
  printf '\n%d item(s) would move. Re-run without --dry-run to apply.\n' "$moved"
  exit 0
fi

# Install the shim, with this plugin's path baked in.
TEMPLATE="$PLUGIN_ROOT/resources/templates/.claude/project/workflow-state.sh"
if [ ! -f "$TEMPLATE" ]; then
  echo "migrate: the plugin is missing its shim template at $TEMPLATE" >&2
  echo "  Your files are safe in .claude/.backup-pre-v3/ — nothing was deleted." >&2
  exit 1
fi
mkdir -p "$ROOT/.claude/project"
sed "s|\[PLUGIN_ROOT\]|$PLUGIN_ROOT|g" "$TEMPLATE" > "$WS"
chmod +x "$WS"

# Prove it resolves before claiming success. A shim that cannot find the plugin
# leaves every documented workflow command broken.
#
# Assert on OUTPUT, not the exit code. `bash empty-file` exits 0, so an
# exit-code-only check passes on a shim that is completely empty -- which is
# exactly what happened when this template was missing.
if ! bash "$WS" --help 2>/dev/null | grep -q 'Usage: workflow-state.sh'; then
  echo "migrate: the shim was installed but cannot reach the plugin." >&2
  echo "  Your files are safe in .claude/.backup-pre-v3/ — nothing was deleted." >&2
  exit 1
fi
say "install .claude/project/workflow-state.sh (shim -> $PLUGIN_ROOT)"

# Hooks come from the plugin now. A hooks block left here would shadow them.
if command -v jq >/dev/null 2>&1; then
  S="$ROOT/.claude/settings.json"
  if jq -e '.hooks' "$S" >/dev/null 2>&1; then
    tmp="$S.tmp.$$"
    if jq 'del(.hooks)' "$S" > "$tmp" && [ -s "$tmp" ]; then
      mv "$tmp" "$S"; say "remove the hooks block from .claude/settings.json"
    else
      rm -f "$tmp"
      echo "migrate: could not rewrite settings.json — remove its hooks block by hand" >&2
    fi
  fi
fi

# Hook config is only read at session start, so the new hooks are not live yet.
date -u +%Y-%m-%dT%H:%M:%SZ > "$ROOT/.claude/project/.upgrade-pending"

cat <<EOF

Migrated $moved item(s). Originals are in .claude/.backup-pre-v3/ — nothing was
deleted, only moved. Delete that directory once you are happy.

RESTART CLAUDE CODE NOW. Hook configuration is read at session start, so this
session is still running the old hooks. SessionStart will confirm when the new
ones are live.
EOF
