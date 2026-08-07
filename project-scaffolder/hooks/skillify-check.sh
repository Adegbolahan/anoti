#!/usr/bin/env bash
# Called by stop.sh. Decides whether finishing this story is worth capturing as
# a skill, and if so hands the judgment to the model.
#
# SPLIT OF RESPONSIBILITY
#
#   bash (here)   deterministic gating: did a story just complete? has this one
#                 already been offered? what skills already exist?
#   the model     the judgment: is this pattern actually worth capturing?
#
# Doing it this way means no model call happens unless the cheap checks already
# passed. A prompt-type hook would evaluate on every single Stop, including the
# thousands that end nowhere near a completed story.
#
# NEVER blocks. Exits 0 on every path, including every failure path. A capture
# suggestion that can wedge the session would be a bad trade for a nice-to-have.

set -uo pipefail

SKILLIFY_STATE_DIR="${1:-}"
[ -n "$SKILLIFY_STATE_DIR" ] || exit 0
[ -d "$SKILLIFY_STATE_DIR" ] || exit 0

STATE="$SKILLIFY_STATE_DIR/.workflow-state.json"
[ -f "$STATE" ] || exit 0
jq --version >/dev/null 2>&1 || exit 0

PHASE=$(jq -r '.phase // ""' "$STATE" 2>/dev/null) || exit 0
[ "$PHASE" = "complete" ] || exit 0

STORY=$(jq -r '.activeStory // ""' "$STATE" 2>/dev/null)
TITLE=$(jq -r '.storyTitle // ""' "$STATE" 2>/dev/null)
[ -n "$STORY" ] || exit 0

# GUARD 1: one suggestion per story, ever. The state machine can re-enter
# `complete` (an amended commit, a cleared and restarted story), and a prompt
# the user already ignored is noise the second time.
MARKER="$SKILLIFY_STATE_DIR/.skillify-offered"
if [ -f "$MARKER" ] && grep -qxF "$STORY" "$MARKER" 2>/dev/null; then
  exit 0
fi
printf '%s\n' "$STORY" >> "$MARKER" 2>/dev/null || true

# GUARD 2: what already exists, so the model can rule out duplicates rather
# than proposing a skill that overlaps one of these.
PROJECT_ROOT="$(cd "$SKILLIFY_STATE_DIR/../.." && pwd)"
# Not `cd ... && pwd || true`: A && B || C is not if-then-else, and C runs when
# B fails too (SC2015).
PLUGIN_SKILLS=""
if _skills_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../skills" 2>/dev/null && pwd); then
  PLUGIN_SKILLS="$_skills_dir"
fi
existing=""
for d in "$PROJECT_ROOT/.claude/skills"/*/ "$PLUGIN_SKILLS"/*/; do
  [ -d "$d" ] || continue
  existing="${existing}  - $(basename "$d")"$'\n'
done
[ -n "$existing" ] || existing="  (none)"$'\n'

story_lc=$(printf '%s' "$STORY" | tr '[:upper:]' '[:lower:]')
SPEC=$(find "$PROJECT_ROOT/.claude/project/features" -maxdepth 1 -name "*${story_lc}*" -type f 2>/dev/null | head -1)

cat <<EOF

$STORY ($TITLE) is complete. Consider whether it is worth capturing as a skill.

GUARD 3 — the worth-it bar. Propose a skill ONLY if at least one holds:
  - the same pattern has now come up in two or more stories
  - it encodes a project convention you discovered while building, that is not
    obvious from reading the code
  - the sequence is non-obvious enough that redoing it later would cost real time

If none holds, say nothing and move on. A skill per story is noise, and noise
here trains people to ignore everything this hook says.

Skills that already exist — do not propose anything overlapping these:
$existing
${SPEC:+Story spec: $SPEC}

If the bar is met, say what you would capture and why, and offer to run
/skillify. Do not create anything without the user agreeing.
EOF

exit 0
