tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"   # hermetic: no real global store
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
# Untrusted store: mentioned but not loaded
out="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "not yet trusted"
assert_ok $? "untrusted store is reported, not loaded"
# Trusted store: digest with counts inside untrusted-data envelope
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
out="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve")"
ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$ctx" | grep -q "REFERENCE DATA"; assert_ok $? "envelope marks digest as data, not instructions"
printf '%s' "$ctx" | grep -q "2 records"; assert_ok $? "digest reports record count"
printf '%s' "$ctx" | grep -q "1 awaiting ratification"; assert_ok $? "digest reports pending ratification"
# Tampered store loses trust
printf '\n# tampered\n' >> GROUNDING.yaml
out="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "not yet trusted"
assert_ok $? "modified store requires re-trust"
# Abandoned session surfaced
mkdir -p .anoti/sessions; printf 'episode: candidate-detected\n' > .anoti/sessions/x.abandoned.yaml
printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "abandoned session"
assert_ok $? "abandoned session state surfaced"
# Empty project: silent
rm -rf .anoti GROUNDING.yaml
out="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve")"
assert_eq "$out" "" "nothing to say -> no output"
); rm -rf "$tmp"

# --- digest enrichment within the ~1k-token budget (spec: Retrieval) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
cp "$ROOT/tests/fixtures/store_rich.yaml" GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
ctx="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$ctx" | grep -q "R001"; assert_ok $? "small index inlined in digest"
printf '%s' "$ctx" | grep -q "rich.alpha"; assert_ok $? "index rows carry topic"
printf '%s' "$ctx" | grep -q "Q001"; assert_ok $? "open question surfaced in digest"
printf '%s' "$ctx" | grep -q "retrieval budget?"; assert_ok $? "open question text included"
! printf '%s' "$ctx" | grep -q "Q002"; assert_ok $? "resolved question omitted"
printf '%s' "$ctx" | grep -q "review recommended"; assert_ok $? "nudge fires on aged probable record"
); rm -rf "$tmp"

# No nudge when probable records are few and fresh (dates rewritten to today)
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
sed "s/2026-08-12/$(date +%F)/g" "$ROOT/tests/fixtures/store_valid.yaml" > GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
ctx="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
! printf '%s' "$ctx" | grep -q "review recommended"; assert_ok $? "no nudge for few fresh probables"
); rm -rf "$tmp"

# --- budget enforcement: oversized index degrades to counts-only ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
long="$(printf 'x%.0s' $(seq 1 300))"
{
  printf 'meta:\n  schema_version: 3\n  scope: project\n  policy: { entries_immutable: true, events_append_only: true, reverify_after_days: 180 }\nindex:\n'
  i=1; while [ "$i" -le 40 ]; do
    printf -- '- { ref: B%03d, type: claim, topic: bulk.topic%d, statement: "%s" }\n' "$i" "$i" "$long"
    i=$((i+1))
  done
  printf 'records:\n'
  i=1; while [ "$i" -le 40 ]; do
    printf -- '- { id: B%03d, date: 2020-01-01, type: claim, topic: bulk.topic%d, statement: "s", epistemic_status: established, ratification: approved, events: [] }\n' "$i" "$i"
    i=$((i+1))
  done
  printf 'open_questions: []\n'
} > GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
ctx="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$ctx" | grep -q "40 records"; assert_ok $? "counts survive when index is too large"
! printf '%s' "$ctx" | grep -q "B001"; assert_ok $? "oversized index omitted from digest"
[ "${#ctx}" -le 4200 ]; assert_ok $? "digest stays within ~1k-token budget (got ${#ctx} chars)"
); rm -rf "$tmp"

# roadmap line prefers the phase marked "current" over the first heading
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME" docs
printf '# R\n\n## Phase 1 — done\n\n## Phase 2 — now <- current\n' > docs/ROADMAP.md
ctx="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$ctx" | grep -q "Phase 2"; assert_ok $? "digest shows the current phase"
! printf '%s' "$ctx" | grep -q "roadmap phase: Phase 1"; assert_ok $? "not the first heading"
); rm -rf "$tmp"

# empty git project must receive a bootstrap offer; non-git stays silent
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
git init -q .
out="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null)"
printf '%s' "$out" | grep -qi "skillify"; assert_ok $? "bare git repo gets skillify bootstrap offer"
); rm -rf "$tmp"
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
out="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve")"
assert_eq "$out" "" "bare non-git dir stays silent"
); rm -rf "$tmp"

# value standard surfaced when HIGH-LEVEL-STORIES.md exists
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME" docs
printf '# Stories\n\n- As a user, I need X. Done means: Y.\n- As a maintainer, I need Z. Done means: W.\n' > docs/HIGH-LEVEL-STORIES.md
ctx="$(printf '{"session_id":"s1"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$ctx" | grep -q "value standard"; assert_ok $? "stories surfaced as value standard"
printf '%s' "$ctx" | grep -q "2 stor"; assert_ok $? "story count included"
); rm -rf "$tmp"

# --- global store digestion (spec: global-memory-tier) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME/.claude/anoti"
cp "$ROOT/tests/fixtures/store_valid.yaml" "$HOME/.claude/anoti/GROUNDING.yaml"
out="$(printf '{"session_id":"g"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$out" | grep -q "not yet trusted"; assert_ok $? "untrusted global refused"
"$ROOT/scripts/trust" --global "$HOME/.claude/anoti/GROUNDING.yaml" >/dev/null
out="$(printf '{"session_id":"g"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
# NOTE (explicit coupling): the second [global] line comes deterministically
# from the scope-drift emit — the fixture carries scope: project while
# placed at the global path. If the fixture's scope field ever changes,
# give this test its own fixture rather than weakening the assertion.
n=$(printf '%s\n' "$out" | grep -c "\[global\]")
[ "$n" -ge 2 ]; assert_ok $? "every global-sourced line labeled [global] (got $n)"
printf '%s' "$out" | grep -q "2 records"; assert_ok $? "trusted global digested"
); rm -rf "$tmp"
# scope/location mismatch surfaces in the digest
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
sed 's/scope: project/scope: global/' "$ROOT/tests/fixtures/store_valid.yaml" > GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
out="$(printf '{"session_id":"g"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$out" | grep -qi "scope mismatch"; assert_ok $? "scope/location drift reported"
); rm -rf "$tmp"

# #8a: zero counts render on one line (grep -c exit-1 newline bug)
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
printf '# T\n\n- [x] done\n' > TODOS.md
out="$(printf '{"session_id":"z"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s\n' "$out" | grep -q "open todos: 0 (see TODOS.md)"; assert_ok $? "zero todos renders on one line"
! printf '%s\n' "$out" | grep -qE '^0 \(see'; assert_ok $? "no orphaned count line"
); rm -rf "$tmp"

# --- #11 case-exact organ resolution ---
grep -q "grep -qxF" "$ROOT/scripts/retrieve"
assert_ok $? "#11 retrieve resolves organs by exact-case directory listing"
tmp="$(mktemp -d)"; ( cd "$tmp"
touch .probe-AB
if [ -e .probe-ab ]; then
  git init -q -b main .
  printf '## Overview\nunrelated project planning doc\n' > roadmap.md
  printf 'schema_version: 3\n' > /dev/null
  out="$(printf '{"session_id":"cs"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""' 2>/dev/null)"
  printf '%s' "$out" | grep -qi "roadmap phase"
  assert_eq "$?" "1" "#11 lowercase roadmap.md is not adopted as the ROADMAP organ (case-insensitive fs)"
else
  echo "  (skip: case-sensitive filesystem — #11 scenario cannot reproduce here)"
fi
); rm -rf "$tmp"

# --- lessons surfacing: the write-only organ gets a digest line ---
tmp="$(mktemp -d)"; ( cd "$tmp"
git init -q -b main .
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
mkdir -p .anoti && "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null 2>&1
printf -- '- 2026-08-12 — first lesson: assert on replace\n- 2026-08-13 — yq string == does wildcard matching; resolve ids to indices first\n' > LESSONS-LEARNT.md
out="$(printf '{"session_id":"lx"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -q "lessons: 2"
assert_ok $? "digest carries the lessons count"
printf '%s' "$out" | grep -q "wildcard"
assert_ok $? "digest shows the latest lesson (truncated)"
rm LESSONS-LEARNT.md
out="$(printf '{"session_id":"lx"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -qi "lessons:"
assert_eq "$?" "1" "no lessons organ -> no lessons line"
); rm -rf "$tmp"
grep -q 'fx "$LL"' "$ROOT/scripts/retrieve" && grep -q 'LL=LESSONS-LEARNT.md' "$ROOT/scripts/retrieve"
assert_ok $? "lessons organ resolved case-exactly with configurable path (mechanism pin)"
tmp="$(mktemp -d)"; ( cd "$tmp"
touch .probe-AB
if [ -e .probe-ab ]; then
  git init -q -b main .
  cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
  mkdir -p .anoti && "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null 2>&1
  printf -- '- 2026-08-13 — lowercase impostor lesson\n' > lessons-learnt.md
  out="$(printf '{"session_id":"lc"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
  printf '%s' "$out" | grep -qi "lessons:"
  assert_eq "$?" "1" "lowercase lessons-learnt.md is not adopted as the organ (case-insensitive fs)"
else
  echo "  (skip: case-sensitive filesystem — lessons case scenario cannot reproduce here)"
fi
); rm -rf "$tmp"

# --- gap 4: restart-drift line when the session runs an older cache version ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p cache/anoti/anoti/0.5.9 cache/anoti/anoti/0.5.11
cp -R "$ROOT/scripts" cache/anoti/anoti/0.5.9/scripts
mkdir -p proj && cd proj
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
mkdir -p .anoti && "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null 2>&1
out="$(printf '{"session_id":"dr"}' | "$tmp/cache/anoti/anoti/0.5.9/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -q "0.5.11" && printf '%s' "$out" | grep -qi "restart"
assert_ok $? "gap 4: digest surfaces newer installed version + restart nudge"
out="$(printf '{"session_id":"dr"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -qi "restart to load"
assert_eq "$?" "1" "no drift line when not running from a version cache"
touch "$tmp/cache/anoti/anoti/zzz-notes.txt"
mkdir -p "$tmp/cache/anoti/anoti/0.5.11/scripts" 2>/dev/null
cp -R "$ROOT/scripts/." "$tmp/cache/anoti/anoti/0.5.11/scripts/" 2>/dev/null
out="$(printf '{"session_id":"dr"}' | "$tmp/cache/anoti/anoti/0.5.11/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -q "zzz-notes"
assert_eq "$?" "1" "stray cache files never counted as versions (newest filter)"
printf '%s' "$out" | grep -qi "restart to load"
assert_eq "$?" "1" "no drift line when already on the newest version"
cd "$tmp" && mkdir ungov fakehome && cd ungov
out="$(printf '{"session_id":"dr"}' | HOME="$tmp/fakehome" "$tmp/cache/anoti/anoti/0.5.9/scripts/retrieve")"
[ -z "$out" ]
assert_ok $? "drift line never manufactures a digest for an ungoverned dir (lines guard)"
); rm -rf "$tmp"

# --- #18 organ-path adoption: the four hook-read organs get the #16 treatment ---
tmp="$(mktemp -d)"; ( cd "$tmp"
git init -q -b main .
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
mkdir -p .anoti && "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null 2>&1
mkdir -p dev-docs .claude
printf -- '- [ ] field item (raised 2026-08-18)\n' > dev-docs/TODOS.md
printf -- '- 2026-08-18 — field lesson\n' > dev-docs/LESSONS-LEARNT.md
printf '## Phase 9: Field ← current\n' > dev-docs/roadmap.md
printf '## Register\n- US-001 x\n- US-002 y\n' > dev-docs/stories.md
printf -- '---\ntodos_path: dev-docs/TODOS.md\nlessons_path: dev-docs/LESSONS-LEARNT.md\nroadmap_path: dev-docs/roadmap.md\nstory_path: dev-docs/stories.md\n---\n' > .claude/anoti.local.md
out="$(printf '{"session_id":"o18"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -q "open todos: 1"
assert_ok $? "#18 todos_path honored"
printf '%s' "$out" | grep -q "lessons: 1"
assert_ok $? "#18 lessons_path honored"
printf '%s' "$out" | grep -q "Phase 9"
assert_ok $? "#18 roadmap_path honored (custom basename)"
printf '%s' "$out" | grep -qi "value standard"
assert_ok $? "#18 story_path honored"
rm .claude/anoti.local.md
out="$(printf '{"session_id":"o18"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -qi "roadmap organ not found\|no roadmap organ"
assert_ok $? "#18 silent gap becomes a loud digest line (roadmap)"
printf '%s' "$out" | grep -qi "stories organ not found\|no stories organ\|value-standard organ"
assert_ok $? "#18 silent gap becomes a loud digest line (stories)"
printf -- '---\nroadmap_path: dev-docs/GONE.md\n---\n' > .claude/anoti.local.md
out="$(printf '{"session_id":"o18"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -q "roadmap_path: 'dev-docs/GONE.md' does not resolve"
assert_ok $? "#18 a dangling configured path is named, not generic"
cd "$tmp" && mkdir plain fakehome && cd plain
printf -- '- [ ] stray todo\n' > TODOS.md
out="$(printf '{"session_id":"o18b"}' | HOME="$tmp/fakehome" "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""' 2>/dev/null)"
printf '%s' "$out" | grep -qi "organ not found"
assert_eq "$?" "1" "#18 no project store, no warnings — ungoverned dirs stay unnagged"
); rm -rf "$tmp"
