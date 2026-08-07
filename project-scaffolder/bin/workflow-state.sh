#!/usr/bin/env bash
# Workflow phase state management. Called by the hook scripts in
# .claude/project/hooks/ and usable directly from the CLI.
#
# PHASE MACHINE
#
#   none -> discovery_started -> discovery_complete -> plan_created ->
#   plan_approved -> implementation_in_progress -> under_review
#                                                    |        ^
#                                     changes_requested <-----+
#                                                    |
#                                          review_passed -> complete
#
#   Allowed backward edges (everything else is forward-only):
#     changes_requested -> under_review   re-review after fixes
#     review_passed     -> under_review   re-review after a post-pass edit
#
# EXIT CODES
#   0  success
#   1  usage / illegal transition (with a message on stderr)
#   3  no state file -- no story is being tracked. NOT an error.
#   4  state exists but cannot be evaluated (no jq, corrupt, unreadable).
#      Callers that gate on state MUST treat 4 as "block", never as "allow".
#
# The 3-vs-4 distinction is the whole point. "No story yet" and "I cannot tell
# you" look identical if you collapse them, and collapsing them is what let the
# commit gate silently disable itself on machines without jq.

# shellcheck disable=SC2016
# The single-quoted strings passed to jq below are jq filter programs. Their
# $p / $ts / $f / $r are jq variables bound with --arg or --argjson, not shell
# expansions, so single quotes are correct and required throughout this file.
# This must sit before the first command to apply file-wide.

set -uo pipefail

# --------------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------------

# Resolve the project root without depending on where this script lives, so
# the same file works when it is copied into a project (Phase A) and when it
# is shipped inside the plugin and shared across projects (Phase B).
resolve_project_root() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR/.claude/project" ]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"; return 0
  fi
  local top
  if top=$(git rev-parse --show-toplevel 2>/dev/null) && [ -d "$top/.claude/project" ]; then
    printf '%s' "$top"; return 0
  fi
  if [ -d "$PWD/.claude/project" ]; then
    printf '%s' "$PWD"; return 0
  fi
  return 1
}

usage() {
  cat <<'USAGE'
Usage: workflow-state.sh <command>

  snapshot              phase, story, findings, cycle, override as one TSV line
  get-phase             current phase
  get-story             active story ID
  get-review-cycle      review cycle counter
  get-findings-count    number of stored blockers

  start <ID> [title]    begin tracking a story
  advance <phase>       move forward (nonzero exit on an illegal transition)
                        `advance complete` ends the story
  advance review_passed --evidence <path>
                        passing review REQUIRES a review report that exists and
                        is newer than the last source edit. Path and a content
                        hash go into the audit log.
  mark-source-edit      stamp "source was touched now" (called by post-edit.sh)
  clear                 reset for the next story

  set-findings <json>   store review blockers (validated JSON array)
  override <reason>     arm a one-shot, recorded commit bypass
  consume-override      spend the armed override

  next-action           phase bar plus the next step
  why-blocked           why a commit is being blocked right now

Exit codes: 0 ok · 1 usage/illegal · 3 no state file · 4 state unevaluable
USAGE
}

# Usage must be reachable from anywhere, including outside a project.
case "${1:-help}" in
  help|-h|--help) usage; exit 0 ;;
esac

PROJECT_ROOT="$(resolve_project_root || true)"
if [ -z "$PROJECT_ROOT" ]; then
  echo "workflow-state: not inside a scaffolded project (.claude/project not found)" >&2
  echo "  Looked at: \$CLAUDE_PROJECT_DIR, the git toplevel, and \$PWD." >&2
  exit 1
fi

STATE_DIR="$PROJECT_ROOT/.claude/project"
STATE_FILE="$STATE_DIR/.workflow-state.json"
LOCK_DIR="$STATE_DIR/.workflow-state.lock"
SCHEMA_VERSION=2

# --------------------------------------------------------------------------
# Phases
# --------------------------------------------------------------------------

phase_rank() {
  case "${1:-none}" in
    none)                       echo 0 ;;
    discovery_started)          echo 1 ;;
    discovery_complete)         echo 2 ;;
    plan_created)               echo 3 ;;
    plan_approved)              echo 4 ;;
    implementation_in_progress) echo 5 ;;
    under_review)               echo 6 ;;
    changes_requested)          echo 7 ;;
    review_passed)              echo 8 ;;
    complete)                   echo 9 ;;
    *)                          echo -1 ;;
  esac
}

is_known_phase() { [ "$(phase_rank "$1")" -ge 0 ]; }

# --------------------------------------------------------------------------
# Locking (eng review decision 8)
#
# mkdir is atomic on every POSIX filesystem; flock is not in macOS base
# userland. Claude issues parallel Edits, and every write here is
# read-modify-write, so without this two hooks can silently drop a transition.
# --------------------------------------------------------------------------

# Portable file helpers. BSD stat and GNU stat disagree on flags, and macOS
# ships shasum while most Linux images ship sha256sum.
#
# mtime_of validates that the OUTPUT is a number rather than trusting the exit
# code, because the exit code lies here. On Linux, `stat -f` is --file-system:
# it SUCCEEDS and prints a multi-line filesystem report, so an
# `stat -f || stat -c` chain never reaches the GNU form and hands the caller
# text like `  File: "/path"`. Arithmetic on that then died with
# "File: unbound variable" under set -u, breaking both the stale-lock reaper and
# the evidence freshness check.
mtime_of() {
  local m
  m=$(stat -c %Y "$1" 2>/dev/null); case "$m" in ''|*[!0-9]*) ;; *) printf '%s' "$m"; return 0 ;; esac
  m=$(stat -f %m "$1" 2>/dev/null); case "$m" in ''|*[!0-9]*) ;; *) printf '%s' "$m"; return 0 ;; esac
  printf '0'
}
hash_of() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" 2>/dev/null | cut -d' ' -f1
  else echo "unhashed"; fi
}

LOCK_TIMEOUT="${WORKFLOW_LOCK_TIMEOUT:-5}"

acquire_lock() {
  local waited=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    # Reap a lock left behind by a killed hook.
    if [ -d "$LOCK_DIR" ]; then
      local age
      age=$(( $(date +%s) - $(mtime_of "$LOCK_DIR") ))
      if [ "$age" -gt "$LOCK_TIMEOUT" ]; then
        rmdir "$LOCK_DIR" 2>/dev/null || true
        continue
      fi
    fi
    sleep 0.1
    waited=$(( waited + 1 ))
    [ "$waited" -gt $(( LOCK_TIMEOUT * 10 )) ] && return 1
  done
  return 0
}

release_lock() { rmdir "$LOCK_DIR" 2>/dev/null || true; }

# --------------------------------------------------------------------------
# State access
# --------------------------------------------------------------------------

# Test that jq WORKS, not merely that a file named jq is on PATH. A jq that
# is present but broken (bad install, wrong arch, shimmed) is as useless as a
# missing one, and both must lead to a block rather than a silent pass.
have_jq() { jq --version >/dev/null 2>&1; }

# Distinguish absent (3) from unevaluable (4) before touching jq.
state_readable() {
  [ -e "$STATE_FILE" ] || return 3
  [ -r "$STATE_FILE" ] || return 4
  have_jq || return 4
  jq -e . "$STATE_FILE" >/dev/null 2>&1 || return 4
  return 0
}

ensure_state() {
  have_jq || { echo "workflow-state: jq is required. Install: brew install jq (macOS) / apt-get install jq (Linux)" >&2; exit 4; }
  if [ ! -f "$STATE_FILE" ]; then
    jq -n --argjson v "$SCHEMA_VERSION" \
      '{schemaVersion:$v, activeStory:null, phase:"none", storyTitle:null,
        reviewCycle:0, reviewFindings:[], override:null,
        lastSourceEditEpoch:0, reviewEvidence:null, timestamps:{}}' \
      > "$STATE_FILE"
    return 0
  fi
  jq -e . "$STATE_FILE" >/dev/null 2>&1 || {
    echo "workflow-state: $STATE_FILE is not valid JSON. Refusing to overwrite it." >&2
    exit 4
  }
  # Forward migration. Refuse to touch a file written by a newer version
  # rather than silently corrupting it.
  local v
  v=$(jq -r '.schemaVersion // 0' "$STATE_FILE")
  if [ "$v" -gt "$SCHEMA_VERSION" ] 2>/dev/null; then
    echo "workflow-state: state file schemaVersion $v is newer than this script ($SCHEMA_VERSION). Upgrade the plugin." >&2
    exit 4
  fi
  if [ "$v" -lt "$SCHEMA_VERSION" ] 2>/dev/null; then
    write_state '.schemaVersion = '"$SCHEMA_VERSION"'
                 | .reviewCycle = (.reviewCycle // 0)
                 | .reviewFindings = (.reviewFindings // [])
                 | .override = (.override // null)
                 | .lastSourceEditEpoch = (.lastSourceEditEpoch // 0)
                 | .reviewEvidence = (.reviewEvidence // null)'
  fi
}

# write_state <jq-program> [--argjson name value ...]
write_state() {
  local prog="$1"; shift
  acquire_lock || { echo "workflow-state: could not acquire lock" >&2; return 1; }
  local tmp="${STATE_FILE}.tmp.$$"
  if jq "$@" "$prog" "$STATE_FILE" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
    mv "$tmp" "$STATE_FILE"
    release_lock
    return 0
  fi
  rm -f "$tmp"
  release_lock
  return 1
}

log_event() {
  # Append-only audit trail. Best-effort: never fail a hook over logging.
  local logf="$STATE_DIR/.workflow-log.jsonl"
  have_jq || return 0
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg ev "$1" --arg detail "${2:-}" \
    '{ts:$ts, event:$ev, detail:$detail}' >> "$logf" 2>/dev/null || true
}

# --------------------------------------------------------------------------
# Commands
# --------------------------------------------------------------------------

case "${1:-help}" in

  # snapshot: everything a gating hook needs, in ONE jq call.
  # Hooks call this instead of several accessors -- the gate runs on every
  # Bash tool call, and three accessor round-trips was ~6 process spawns.
  # Output: phase<TAB>story<TAB>findings_count<TAB>review_cycle<TAB>override
  snapshot)
    state_readable; rc=$?
    [ "$rc" -ne 0 ] && exit "$rc"
    # Every field must be a scalar: @tsv rejects objects, and .override IS an
    # object. Emitting it raw made jq exit 5, which the gate read as an
    # unexpected error and blocked -- refusing the exact commit the override
    # existed to allow. Flatten it to a marker here.
    jq -r '[(.phase // "none"),
            (.activeStory // ""),
            ((.reviewFindings // []) | length | tostring),
            ((.reviewCycle // 0) | tostring),
            (if (.override != null and .override.used == false)
             then "armed" else "" end)] | @tsv' "$STATE_FILE"
    ;;

  # Named accessors, replacing the old generic `get-field` which interpolated
  # its argument straight into a jq program -- an arbitrary-jq eval wearing a
  # field-access name.
  #
  # Deliberately few. `snapshot` above already returns phase, story, findings
  # count, cycle and override in one call, so accessors only exist where a
  # caller genuinely wants one field: the hooks read phase and story, and
  # /review reads the cycle counter for its loop cap.
  #
  # A `get` (whole JSON), `get-story-title` and `get-findings` were dropped as
  # dead surface -- `cat .workflow-state.json` and `why-blocked` cover both.
  get-phase)          state_readable || exit $?; jq -r '.phase // "none"' "$STATE_FILE" ;;
  get-story)          state_readable || exit $?; jq -r '.activeStory // ""' "$STATE_FILE" ;;
  get-review-cycle)   state_readable || exit $?; jq -r '.reviewCycle // 0' "$STATE_FILE" ;;
  get-findings-count) state_readable || exit $?; jq -r '(.reviewFindings // []) | length' "$STATE_FILE" ;;

  # Stamp the moment source was last touched. Called by post-edit.sh, which is
  # the one place that already knows what counts as source (the D8-widened
  # detection covering app/, cmd/ and root packages). The evidence check below
  # measures review reports against this.
  mark-source-edit)
    ensure_state
    write_state '.lastSourceEditEpoch = $e' --argjson e "$(date +%s)" || exit 1
    ;;

  advance)
    ensure_state
    target="${2:?phase required}"
    if ! is_known_phase "$target"; then
      echo "workflow-state: unknown phase '$target'" >&2
      exit 1
    fi

    # --evidence <path>, required when passing review.
    evidence=""
    shift 2 2>/dev/null || shift $#
    while [ $# -gt 0 ]; do
      case "$1" in
        --evidence) evidence="${2:-}"; shift 2 || true ;;
        *)          shift ;;
      esac
    done

    current=$(jq -r '.phase // "none"' "$STATE_FILE")
    tr_rank=$(phase_rank "$target"); cur_rank=$(phase_rank "$current")

    allowed=false
    [ "$tr_rank" -gt "$cur_rank" ] && allowed=true
    # Re-review edges.
    [ "$current" = "changes_requested" ] && [ "$target" = "under_review" ] && allowed=true
    # D4: a post-pass edit must be re-reviewable, otherwise review_passed is a
    # permanent pardon and you can rewrite anything after passing.
    [ "$current" = "review_passed" ] && [ "$target" = "under_review" ] && allowed=true

    if [ "$allowed" != "true" ]; then
      # D7: an illegal transition used to be indistinguishable from success.
      echo "workflow-state: illegal transition $current -> $target" >&2
      exit 1
    fi

    # ----------------------------------------------------------------------
    # Evidence gate on review_passed.
    #
    # WHY THIS EXISTS. pre-bash.sh blocks `git commit` but does not block the
    # command that opens the gate, so the agent being gated could unblock
    # itself with a bare `advance review_passed` -- and the audit log recorded
    # it identically to a real review pass.
    #
    # WHAT THIS IS NOT. An agent with shell access in this filesystem can write
    # a file and pass the check. This does not stop that and cannot. What it
    # does is turn a silent two-command bypass into an explicit act that leaves
    # a forged artifact in the diff, where a human reviewing the PR can see it.
    # A guardrail against drift and accident, not an adversarial control.
    # ----------------------------------------------------------------------
    evidence_hash=""
    if [ "$target" = "review_passed" ]; then
      if [ -z "$evidence" ]; then
        echo "workflow-state: advance review_passed requires --evidence <path>" >&2
        echo "  Point it at the review report. The gate records the path and a" >&2
        echo "  content hash so a pass can be traced back to what produced it." >&2
        exit 1
      fi
      if [ ! -f "$evidence" ]; then
        echo "workflow-state: evidence file not found: $evidence" >&2
        exit 1
      fi
      last_edit=$(jq -r '.lastSourceEditEpoch // 0' "$STATE_FILE")
      ev_mtime=$(mtime_of "$evidence")
      if [ "$ev_mtime" -lt "$last_edit" ] 2>/dev/null; then
        echo "workflow-state: evidence predates the last source edit." >&2
        echo "  $evidence is older than the code it claims to review." >&2
        echo "  Re-run the review, then pass the fresh report." >&2
        exit 1
      fi
      evidence_hash="$(hash_of "$evidence")"
    fi

    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    prog='.phase = $p | .timestamps[$p] = $ts'
    case "$target" in
      under_review)  prog="$prog"' | .reviewCycle = ((.reviewCycle // 0) + 1)' ;;
      review_passed) prog="$prog"' | .reviewFindings = []
                                   | .reviewEvidence = {path:$ev, hash:$evh, at:$ts}' ;;
    esac
    write_state "$prog" --arg p "$target" --arg ts "$ts" \
      --arg ev "$evidence" --arg evh "$evidence_hash" || exit 1
    if [ -n "$evidence" ]; then
      log_event transition "$current -> $target (evidence: $evidence sha256:${evidence_hash:0:12})"
    else
      log_event transition "$current -> $target"
    fi
    ;;

  start)
    ensure_state
    story="${2:?story ID required}"
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    acquire_lock || exit 1
    jq -n --arg s "$story" --arg t "${3:-}" --arg ts "$ts" --argjson v "$SCHEMA_VERSION" \
      '{schemaVersion:$v, activeStory:$s, storyTitle:$t, phase:"discovery_started",
        reviewCycle:0, reviewFindings:[], override:null,
        lastSourceEditEpoch:0, reviewEvidence:null,
        timestamps:{discovery_started:$ts}}' > "$STATE_FILE"
    release_lock
    log_event start "$story"
    ;;

  # No `complete` subcommand: `advance complete` is the one way to reach the
  # terminal phase, so it goes through the same rank check and audit log as
  # every other transition. A second path would be a second set of rules.

  clear)
    ensure_state
    acquire_lock || exit 1
    jq -n --argjson v "$SCHEMA_VERSION" \
      '{schemaVersion:$v, activeStory:null, phase:"none", storyTitle:null,
        reviewCycle:0, reviewFindings:[], override:null,
        lastSourceEditEpoch:0, reviewEvidence:null, timestamps:{}}' > "$STATE_FILE"
    release_lock
    log_event clear ""
    ;;

  set-findings)
    ensure_state
    findings="${2:?findings JSON array required}"
    # Eng review decision 6: validate before writing. Silently unsaved
    # findings produce a blocked commit reporting zero blockers, which reads
    # as a malfunctioning gate.
    if ! printf '%s' "$findings" | jq -e 'type == "array"' >/dev/null 2>&1; then
      echo "workflow-state: set-findings expects a JSON array, got: $findings" >&2
      echo "workflow-state: state left unchanged; phase stays $(jq -r '.phase' "$STATE_FILE")" >&2
      exit 1
    fi
    write_state '.reviewFindings = $f' --argjson f "$findings" || exit 1
    log_event set-findings "$(printf '%s' "$findings" | jq -r 'length') blocker(s)"
    ;;

  # One-shot, recorded bypass. The only alternative today is deleting the
  # state file, which teaches people to delete state files and destroys the
  # audit trail.
  override)
    ensure_state
    reason="${2:?a reason is required}"
    write_state '.override = {reason:$r, at:$ts, used:false}' \
      --arg r "$reason" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" || exit 1
    log_event override-set "$reason"
    echo "Override armed for ONE commit: $reason"
    ;;

  consume-override)
    ensure_state
    active=$(jq -r 'if (.override != null and .override.used == false) then "yes" else "no" end' "$STATE_FILE")
    [ "$active" != "yes" ] && exit 1
    write_state '.override.used = true' || exit 1
    log_event override-used "$(jq -r '.override.reason // ""' "$STATE_FILE")"
    ;;

  next-action)
    state_readable || exit 0
    story=$(jq -r '.activeStory // empty' "$STATE_FILE")
    [ -z "$story" ] && exit 0
    phase=$(jq -r '.phase // "none"' "$STATE_FILE")
    title=$(jq -r '.storyTitle // ""' "$STATE_FILE")
    cycle=$(jq -r '.reviewCycle // 0' "$STATE_FILE")
    n=$(jq -r '(.reviewFindings // []) | length' "$STATE_FILE")

    # Phase bar (E3). Seeing where you are should not require a command.
    bar=""
    for step in discovery:discovery_complete plan:plan_created approved:plan_approved \
                build:implementation_in_progress review:under_review commit:review_passed; do
      label="${step%%:*}"; at="${step##*:}"
      if [ "$(phase_rank "$phase")" -ge "$(phase_rank "$at")" ]; then
        bar="$bar [$label]"
      else
        bar="$bar $label"
      fi
    done
    echo "WORKFLOW $story ($title)"
    echo "        ${bar# } "
    case "$phase" in
      discovery_started)  echo "  Next: resolve all questions, then write the spec to .claude/project/features/ (mandatory gate)" ;;
      discovery_complete) echo "  Next: create the plan in .claude/project/plans/, then present it for approval" ;;
      plan_created)       echo "  Next: present the plan summary and ask for approval" ;;
      plan_approved)      echo "  Next: write the context handoff summary, then start implementing" ;;
      implementation_in_progress) echo "  Next: run /review (mandatory before commit)" ;;
      under_review)       echo "  Under review (cycle $cycle). Do not edit source until it completes." ;;
      changes_requested)  echo "  $n blocker(s) (cycle $cycle). Fix them, then run /review again. Commit is blocked." ;;
      review_passed)      echo "  Review passed (cycle $cycle). Ready to commit." ;;
      complete)           echo "  Complete. Run: .claude/project/workflow-state.sh clear" ;;
    esac
    ;;

  why-blocked)
    # E3: a blocked commit that names the blockers and how to read them.
    state_readable; rc=$?
    if [ "$rc" -eq 4 ]; then echo "State exists but cannot be read. Check jq is installed and $STATE_FILE is valid JSON."; exit 0; fi
    [ "$rc" -ne 0 ] && { echo "No active story."; exit 0; }
    phase=$(jq -r '.phase // "none"' "$STATE_FILE")
    echo "Phase: $phase"
    n=$(jq -r '(.reviewFindings // []) | length' "$STATE_FILE")
    if [ "$n" -gt 0 ]; then
      echo "$n blocker(s):"
      jq -r '(.reviewFindings // [])[] | "  - " + .' "$STATE_FILE"
    else
      echo "No stored blockers. Run /review to evaluate."
    fi

    # Show what a pass was based on, so an unattested one is visible rather
    # than implicit.
    ev_path=$(jq -r '.reviewEvidence.path // ""' "$STATE_FILE")
    if [ "$phase" = "review_passed" ]; then
      if [ -n "$ev_path" ]; then
        echo "Review evidence: $ev_path (sha256:$(jq -r '.reviewEvidence.hash // "" | .[0:12]' "$STATE_FILE"))"
        [ -f "$PROJECT_ROOT/$ev_path" ] || [ -f "$ev_path" ] || \
          echo "  WARNING: the evidence file no longer exists."
      else
        echo "Review evidence: NONE. This pass was not attested to any report."
      fi
    fi
    ;;

  *)
    echo "workflow-state: unknown command '$1'" >&2
    usage >&2
    exit 1
    ;;
esac
