#!/usr/bin/env bash
# Shared by every hook script. Sourced, never executed directly.
#
# ORDERING RULE -- the most important thing in this file.
#
#   1. scope guard   : is this a scaffolded project at all?  If not, exit 0.
#   2. fail closed   : inside a scaffolded project, anything we cannot
#                      positively confirm blocks.
#
# That order is load-bearing. Plugin hooks are installed user-wide and fire in
# EVERY repository ("Plugin hooks merge with user's hooks and run in parallel"
# -- plugin-dev/skills/hook-development/SKILL.md:383). There is no built-in
# project scoping. Reverse these two steps and "this repo has no
# .claude/project/" reads as an unconfirmable state, and the gate blocks
# git commit in every unrelated repo on the machine.
#
# test/gate/f1-bystander.bats is the guard rail for exactly that.

set -uo pipefail

# --------------------------------------------------------------------------
# Project root
# --------------------------------------------------------------------------
# Three chances to identify a scaffolded project. Only if all three come up
# empty do we conclude "not scaffolded" and stand down.

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

PROJECT_ROOT="$(resolve_project_root || true)"

# STEP 1. Call this before any gating logic. Exits 0 and says nothing when
# this is not a scaffolded project.
require_scaffolded() {
  [ -n "$PROJECT_ROOT" ] || exit 0
  [ -d "$PROJECT_ROOT/.claude/project" ] || exit 0
}

WF() { "$PROJECT_ROOT/.claude/project/workflow-state.sh" "$@"; }

# --------------------------------------------------------------------------
# Payload
# --------------------------------------------------------------------------

read_payload() { PAYLOAD="$(cat)"; }

# Test that jq WORKS, not merely that a file named jq is on PATH. A jq that is
# present but broken is as useless as a missing one, and gating code must treat
# them the same.
jq_works() { jq --version >/dev/null 2>&1; }

# Extract a field, or print nothing if jq is unavailable. Callers that gate on
# the result must handle the empty case explicitly -- see haystack().
payload_field() {
  jq_works || return 1
  printf '%s' "$PAYLOAD" | jq -r "$1 // empty" 2>/dev/null
}

# What to pattern-match against. Prefers the cleanly extracted field; falls
# back to the raw payload when jq is missing, so a `git commit` still gets
# recognised on a machine that cannot parse JSON. Recognising it is what lets
# us block with an explanation instead of silently waving it through.
haystack() {
  local extracted="$1"
  if [ -n "$extracted" ]; then printf '%s' "$extracted"; else printf '%s' "$PAYLOAD"; fi
}

# --------------------------------------------------------------------------
# Command classification
# --------------------------------------------------------------------------

# Does this command invoke `git commit`?
#
# ONE definition, used by both the gate (pre-bash) and the completion tracker
# (post-bash). It was duplicated byte-for-byte in both, which matters here
# because decision 7A knowingly accepted a false positive in this pattern --
# so it is a regex that WILL get tuned, and tuning one copy would leave the two
# hooks disagreeing about what a commit is, silently.
#
# Unanchored, matching the safety blockers, so `cd frontend && git commit` is
# caught. The required whitespace before `commit` keeps `git log --grep=commit`
# from tripping it. Accepted cost: the literal text inside an echo matches too.
is_commit() {
  printf '%s' "$1" | grep -qE '\bgit\b[[:space:]]([^;&|]*[[:space:]])?commit\b'
}

# --------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------

# Exit 2 feeds stderr back to Claude as a blocking error.
block() { printf '%s\n' "$*" >&2; exit 2; }
notice() { printf '%s\n' "$*"; }
