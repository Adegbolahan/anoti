#!/usr/bin/env bash
# PostToolUse:Edit|Write -- formatting, turn bookkeeping, phase advancement.
#
# One hook per event (eng review decision 4). This used to be two separate
# hook groups on the same event, which ran in parallel, could not see each
# other, and raced on the state file.

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/_common.sh"

read_payload
FILE="$(payload_field '.tool_input.file_path' || true)"
[ -z "$FILE" ] && exit 0

require_scaffolded

REL="${FILE#"$PROJECT_ROOT"/}"

# --------------------------------------------------------------------------
# 1. Formatting -- only when the project actually configures a formatter.
#
# The old hook ran `npx prettier --write` on every js/ts/json/css/html/md edit
# with stderr discarded. In a project without prettier, npx tries to FETCH it
# from the network on every single edit, silently. Detect config first.
# --------------------------------------------------------------------------

has_prettier_config() {
  # Test each candidate individually. `ls a* b*` exits nonzero when EITHER
  # glob misses, so a project with .prettierrc but no prettier.config.js read
  # as unconfigured and never got formatted.
  local f
  for f in "$PROJECT_ROOT"/.prettierrc* "$PROJECT_ROOT"/prettier.config.*; do
    [ -e "$f" ] && return 0
  done
  [ -f "$PROJECT_ROOT/package.json" ] &&
    grep -q '"prettier"' "$PROJECT_ROOT/package.json" 2>/dev/null && return 0
  return 1
}
has_black_config() {
  [ -f "$PROJECT_ROOT/pyproject.toml" ] &&
    grep -q '\[tool.black\]' "$PROJECT_ROOT/pyproject.toml" 2>/dev/null
}
has_rustfmt_config() {
  [ -f "$PROJECT_ROOT/rustfmt.toml" ] || [ -f "$PROJECT_ROOT/.rustfmt.toml" ]
}

case "$FILE" in
  *.js|*.ts|*.jsx|*.tsx|*.json|*.css|*.html|*.md)
    has_prettier_config && command -v prettier >/dev/null 2>&1 && prettier --write "$FILE" >/dev/null 2>&1
    ;;
  *.py)
    has_black_config && command -v black >/dev/null 2>&1 && black "$FILE" >/dev/null 2>&1
    ;;
  *.rs)
    has_rustfmt_config && command -v rustfmt >/dev/null 2>&1 && rustfmt "$FILE" >/dev/null 2>&1
    ;;
esac

# --------------------------------------------------------------------------
# 2. Record touched types for the Stop hook.
#
# Typechecking moved off the per-edit path (it was a full `npx tsc --noEmit`
# under a 30s timeout, per edit). Stop reads this and only typechecks when a
# TS file was actually touched this turn.
# --------------------------------------------------------------------------

TOUCH_FILE="$PROJECT_ROOT/.claude/project/.turn-touched"
case "$FILE" in
  *.ts|*.tsx) echo "ts" >> "$TOUCH_FILE" 2>/dev/null || true ;;
esac

# --------------------------------------------------------------------------
# 3. Phase advancement
# --------------------------------------------------------------------------

case "$REL" in
  .claude/project/features/us-*|*/.claude/project/features/us-*)
    STORY="$(printf '%s' "$FILE" | grep -oE '[Uu][Ss]-[0-9]+' | head -1 | tr '[:lower:]' '[:upper:]')"
    CURRENT="$(WF get-story 2>/dev/null || true)"
    if [ -z "$CURRENT" ] && [ -n "$STORY" ]; then
      TITLE="$(basename "$FILE" .md | sed 's/^[Uu][Ss]-[0-9]*-//;s/-/ /g')"
      WF start "$STORY" "$TITLE" >/dev/null 2>&1 || true
    fi
    WF advance discovery_complete >/dev/null 2>&1 || true
    ;;

  .claude/project/plans/us-*|*/.claude/project/plans/us-*)
    PHASE="$(WF get-phase 2>/dev/null || echo none)"
    if [ "$PHASE" = "none" ] || [ "$PHASE" = "discovery_started" ]; then
      notice 'WORKFLOW GATE: writing a plan but no feature spec exists yet. Create the story in .claude/project/features/ first (Phase 0e of /implement).'
    fi
    WF advance discovery_complete >/dev/null 2>&1 || true
    WF advance plan_created >/dev/null 2>&1 || true
    ;;

  .claude/*|.git/*|*.md)
    # Tracking files and docs are not implementation.
    ;;

  *)
    # D1 ROOT CAUSE FIX.
    #
    # Nothing used to advance to implementation_in_progress, so after plan
    # approval the phase sat at plan_approved forever and the commit gate's
    # branch for it was dead code. A source edit after approval IS the start
    # of implementation -- record it.
    #
    # D8 FIX: the old gate matched only */src/*, so it never fired on a
    # Next.js app/, a Go cmd/, or a root-level Python package. Anything in the
    # project that is not .claude/, .git/, or markdown counts as source.
    PHASE="$(WF get-phase 2>/dev/null || echo none)"
    if [ "$PHASE" = "plan_approved" ]; then
      WF advance implementation_in_progress >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
