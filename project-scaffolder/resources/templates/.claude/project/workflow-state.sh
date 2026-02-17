#!/usr/bin/env bash
# Workflow phase state management for development workflow automation
# Used by hooks in .claude/settings.json
#
# Phases (in order):
#   none -> discovery_started -> discovery_complete -> plan_created ->
#   plan_approved -> implementation_in_progress ->
#   under_review <-> changes_requested -> review_passed -> complete
#
# The review cycle (under_review <-> changes_requested) is the only
# allowed backward transition. Everything else is forward-only.
#
# Usage:
#   workflow-state.sh get                    # Full state JSON
#   workflow-state.sh get-field <field>      # Single field
#   workflow-state.sh advance <phase>        # Advance phase (forward only, except review cycle)
#   workflow-state.sh start <ID> [title]     # Start tracking a story
#   workflow-state.sh complete               # Mark story done
#   workflow-state.sh clear                  # Reset for next story
#   workflow-state.sh next-action            # Formatted next-step prompt
#   workflow-state.sh set-findings <json>    # Store review findings (blockers array)
#   workflow-state.sh get-findings           # Get stored review findings
#   workflow-state.sh review-cycle           # Get current review cycle count

set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "workflow-state: jq is required but not installed. Install with: brew install jq (macOS) or apt-get install jq (Linux)"; exit 1; }

STATE_FILE="$(cd "$(dirname "$0")" && pwd)/.workflow-state.json"

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
    *)                          echo 0 ;;
  esac
}

ensure_state() {
  if [ ! -f "$STATE_FILE" ]; then
    echo '{"activeStory":null,"phase":"none","storyTitle":null,"reviewCycle":0,"reviewFindings":[],"timestamps":{}}' > "$STATE_FILE"
  fi
  # Ensure reviewCycle and reviewFindings exist for older state files
  if ! jq -e '.reviewCycle' "$STATE_FILE" >/dev/null 2>&1; then
    jq '.reviewCycle = 0 | .reviewFindings = []' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  fi
}

case "${1:-help}" in
  get)
    ensure_state
    cat "$STATE_FILE"
    ;;

  get-field)
    ensure_state
    jq -r ".${2:?field required} // \"none\"" "$STATE_FILE"
    ;;

  advance)
    ensure_state
    target="${2:?phase required}"
    current=$(jq -r '.phase // "none"' "$STATE_FILE")
    target_rank=$(phase_rank "$target")
    current_rank=$(phase_rank "$current")

    # Allow forward progression
    allowed=false
    if [ "$target_rank" -gt "$current_rank" ]; then
      allowed=true
    fi

    # Allow review cycle: changes_requested -> under_review (backward)
    if [ "$current" = "changes_requested" ] && [ "$target" = "under_review" ]; then
      allowed=true
    fi

    if [ "$allowed" = "true" ]; then
      ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

      # Increment review cycle counter when entering under_review
      if [ "$target" = "under_review" ]; then
        jq --arg p "$target" --arg ts "$ts" \
          '.phase = $p | .timestamps[$p] = $ts | .reviewCycle = (.reviewCycle + 1)' \
          "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
      # Clear findings when review passes
      elif [ "$target" = "review_passed" ]; then
        jq --arg p "$target" --arg ts "$ts" \
          '.phase = $p | .timestamps[$p] = $ts | .reviewFindings = []' \
          "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
      else
        jq --arg p "$target" --arg ts "$ts" \
          '.phase = $p | .timestamps[$p] = $ts' \
          "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
      fi
    fi
    ;;

  start)
    story="${2:?story ID required}"
    title="${3:-}"
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq -n --arg s "$story" --arg t "$title" --arg ts "$ts" \
      '{activeStory:$s, storyTitle:$t, phase:"discovery_started", reviewCycle:0, reviewFindings:[], timestamps:{discovery_started:$ts}}' \
      > "$STATE_FILE"
    ;;

  complete)
    ensure_state
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq --arg ts "$ts" '.phase = "complete" | .timestamps.complete = $ts' \
      "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    ;;

  clear)
    echo '{"activeStory":null,"phase":"none","storyTitle":null,"reviewCycle":0,"reviewFindings":[],"timestamps":{}}' > "$STATE_FILE"
    ;;

  set-findings)
    ensure_state
    findings="${2:?findings JSON array required}"
    jq --argjson f "$findings" '.reviewFindings = $f' \
      "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    ;;

  get-findings)
    ensure_state
    jq -r '.reviewFindings[]' "$STATE_FILE"
    ;;

  review-cycle)
    ensure_state
    jq -r '.reviewCycle // 0' "$STATE_FILE"
    ;;

  next-action)
    ensure_state
    story=$(jq -r '.activeStory // empty' "$STATE_FILE")
    [ -z "$story" ] && exit 0
    phase=$(jq -r '.phase // "none"' "$STATE_FILE")
    title=$(jq -r '.storyTitle // ""' "$STATE_FILE")
    cycle=$(jq -r '.reviewCycle // 0' "$STATE_FILE")
    findings_count=$(jq -r '.reviewFindings | length' "$STATE_FILE")
    case "$phase" in
      discovery_started)
        echo "WORKFLOW: $story ($title) | Phase: Discovery | Resolve ALL questions, then write feature spec to .claude/project/features/ (mandatory gate)" ;;
      discovery_complete)
        echo "WORKFLOW: $story: Discovery complete | Next: Create plan in .claude/project/plans/, present for approval" ;;
      plan_created)
        echo "WORKFLOW: $story: Plan ready | Next: Present plan summary, ask user to approve" ;;
      plan_approved)
        echo "WORKFLOW: $story: Plan approved | Next: Write context handoff summary (Phase 1f), then begin implementation" ;;
      implementation_in_progress)
        echo "WORKFLOW: $story: Implementing | When done: run /review (mandatory before commit)" ;;
      under_review)
        echo "WORKFLOW: $story: Under review (cycle $cycle) | Review in progress via sub-agents. Do not edit source files until review completes." ;;
      changes_requested)
        echo "WORKFLOW: $story: Changes requested (cycle $cycle, $findings_count blockers) | Fix all blockers, then run /review again. Commit is blocked until review passes." ;;
      review_passed)
        echo "WORKFLOW: $story: Review passed (cycle $cycle) | Ready to commit. Run: git commit" ;;
      complete)
        echo "WORKFLOW: $story: Complete! | Run: .claude/project/workflow-state.sh clear for next story" ;;
    esac
    ;;

  help|*)
    echo "Usage: workflow-state.sh {get|get-field|advance|start|complete|clear|next-action|set-findings|get-findings|review-cycle}"
    ;;
esac
