for c in review recall consolidate; do
  f="$ROOT/commands/$c.md"
  [ -s "$f" ]; assert_ok $? "command exists: $c"
  [ -n "$(sed -n 's/^description: //p' "$f" | head -1)" ]; assert_ok $? "command description non-empty: $c"
done
grep -q '\$ARGUMENTS' "$ROOT/commands/recall.md" 2>/dev/null; assert_ok $? "recall uses \$ARGUMENTS"
grep -q "regen-index" "$ROOT/commands/consolidate.md" 2>/dev/null; assert_ok $? "consolidate runs regen-index"
grep -qi "demot" "$ROOT/commands/review.md" 2>/dev/null; assert_ok $? "review supports demotion"

# adopted workflow commands (from the deprecated scaffolder, anoti-native)
for c in new implement review-work update; do
  f="$ROOT/commands/$c.md"
  [ -s "$f" ]; assert_ok $? "command exists: $c"
  [ -n "$(sed -n 's/^description: //p' "$f" | head -1)" ]; assert_ok $? "command description non-empty: $c"
done
grep -q "bootstrap skill" "$ROOT/commands/new.md" && grep -qi "never scaffold into the plugin" "$ROOT/commands/new.md"
assert_ok $? "new wraps the bootstrap skill with the plugin-dir safety check"
grep -q "docs/HIGH-LEVEL-STORIES.md" "$ROOT/commands/implement.md" && grep -qi "spec skill" "$ROOT/commands/implement.md" && grep -q "review-work" "$ROOT/commands/implement.md"
assert_ok $? "implement drives discovery over direction docs + spec gate + review-work"
grep -qi "cycle" "$ROOT/commands/review-work.md" && grep -qi "evidence" "$ROOT/commands/review-work.md" && grep -qi "rubber-stamp" "$ROOT/commands/review-work.md"
assert_ok $? "review-work keeps evidence contract, cycle cap, no-rubber-stamp"
grep -qi "never downgrade\|newer than the installed" "$ROOT/commands/update.md" && grep -q "bootstrap skill" "$ROOT/commands/update.md"
assert_ok $? "update wraps the bootstrap skill's migration with never-downgrade"

# /anoti:audit — the longitudinal audit + staleness sweep, loop-schedulable
f="$ROOT/commands/audit.md"
[ -s "$f" ]; assert_ok $? "command exists: audit"
grep -q "exp-longitudinal" "$f" && grep -qi "stale" "$f" && grep -qi "/loop" "$f"
assert_ok $? "audit implements the longitudinal spec + staleness sweep + loop wiring"
grep -qi "reverify_after_days" "$f"; assert_ok $? "audit checks record reverify windows"
grep -qi "organ writes" "$ROOT/commands/audit.md"; assert_ok $? "#2 audit says organ writes"
grep -qi "plugin root\|plugin's copy" "$ROOT/commands/audit.md" && grep -qi "cadence" "$ROOT/commands/audit.md"
assert_ok $? "#3 audit resolves spec via plugin + surfaces cadence"
grep -q "set-ratification" "$ROOT/commands/review.md"
assert_ok $? "#10 review ritual applies ratification via set-ratification"
grep -q "set-status" "$ROOT/commands/review.md"
assert_ok $? "#10 review ritual applies promotions via set-status"
grep -q "complete-todo" "$ROOT/commands/audit.md"
assert_ok $? "#12 audit staleness sweep can close satisfied todos mechanically"
grep -qi "release" "$ROOT/commands/audit.md" && grep -qi "newest.*tag\|latest.*tag\|newer release" "$ROOT/commands/audit.md"
assert_ok $? "gap 4: audit checks installed plugin against the newest release"
grep -q "anoti digest" "$ROOT/commands/update.md"
assert_ok $? "#21 update names the runnable digest action"
grep -qi "recall coverage\|triggers" "$ROOT/commands/update.md"
assert_ok $? "#20 update reports trigger coverage on migration"

# --- architect-led contract lifecycle (spec: docs/specs/2026-09-12-architect-led-lifecycle-design.md) ---
IMP="$ROOT/commands/implement.md"
ok=0
for r in requirements-analyst architect qa reviewer explorer skeptic ui-designer; do
  grep -q -- "$r" "$IMP" || { echo "implement does not name role: $r" >&2; ok=1; }
done
assert_eq "$ok" "0" "implement names every hat its phases dispatch"

for k in requires produces "verified by" "rejects to"; do
  assert_eq "$(grep -c -- "^- $k" "$IMP")" "8" "implement: all 8 phases declare '$k'"
done

qal="$(grep -n '^## Phase 3: Acceptance tests' "$IMP" | cut -d: -f1)"
bl="$(grep -n '^## Phase 4: Build' "$IMP" | cut -d: -f1)"
[ -n "$qal" ] && [ -n "$bl" ] && [ "$qal" -lt "$bl" ]
assert_ok $? "implement: acceptance tests precede the build phase"

grep -q '^## Phase 3-gate: the architect ratifies the tests' "$IMP" \
  && grep -q 'never the builder' "$IMP" \
  && grep -qi 'does not begin until' "$IMP"
assert_ok $? "implement: architect ratifies the tests, findings to qa, builder blocked"

# gate sequence: architect reads, skeptic hunts gaps, the ORIGINAL qa spawn fixes,
# then the builder is dispatched with fresh context
grep -qi 'Gap hunt' "$IMP" && grep -q 'skeptic' "$IMP"
assert_ok $? "implement: a skeptic hunts gaps in the ratified suite"
grep -qi 'resume the original `qa` spawn' "$IMP" && grep -q 'D011' "$IMP" && grep -qi 'verbatim' "$IMP"
assert_ok $? "implement: fix rounds resume the original qa spawn, findings verbatim (D011)"
grep -qi 'dispatch the builder with fresh context' "$IMP"
assert_ok $? "implement: the builder is dispatched with fresh context"
grep -qi 'skeptic' "$ROOT/roles/architect.md"
assert_ok $? "architect role commissions the gap hunt"
grep -q 'D011' "$ROOT/roles/qa.md" && grep -qi 'fresh context' "$ROOT/roles/qa.md"
assert_ok $? "qa role knows fix rounds resume it and the builder starts fresh"

grep -qi 'interface contract' "$IMP"; assert_ok $? "implement: names the interface contract"
grep -qi 'no edits to the tests' "$IMP" && grep -qi 'back through the Phase 3 gate' "$IMP"
assert_ok $? "implement: builder cannot edit QA's tests"
grep -qi 'RED transcript' "$IMP" && grep -qi 'citing its AC id' "$IMP"
assert_ok $? "implement: RED transcript and AC-id citation required"
grep -qi 'only dispatcher' "$IMP" && grep -q '3 concurrent' "$IMP" && grep -q '8 per session' "$IMP"
assert_ok $? "implement: single-dispatcher rule and spawn budget stated"

# the conductor is scoped out of this path in all three places that must agree
grep -qi 'conductor is not in this path' "$IMP" \
  && grep -qi 'architect-led' "$ROOT/skills/deliberate/SKILL.md" \
  && grep -qi 'non-feature' "$ROOT/roles/conductor.md"
assert_ok $? "conductor scoped out of the feature lifecycle in command, skill and role"

# the hats carry their own contract duties -- a command alone would not bind a spawn
grep -qi 'interface contract' "$ROOT/roles/architect.md" \
  && grep -qi 'ratifying the acceptance tests' "$ROOT/roles/architect.md"
assert_ok $? "architect role owns the interface contract and the test gate"
grep -qi 'RED transcript' "$ROOT/roles/qa.md" && grep -q 'requirements-analyst' "$ROOT/roles/qa.md"
assert_ok $? "qa role authors RED tests and bounces unobservable criteria"
grep -qi 'stable id' "$ROOT/roles/requirements-analyst.md"
assert_ok $? "requirements-analyst role gives criteria stable ids"
grep -qi 'folded into the interface contract' "$ROOT/roles/ui-designer.md"
assert_ok $? "ui-designer role hands its states into the contract"
grep -qi 'split ownership' "$ROOT/skills/policy-test-driven/SKILL.md"
assert_ok $? "test-driven policy splits RED/GREEN ownership across qa and builder"

# --- R6 cycle-1 findings: entry test, honest budget, dual rework owners ---
grep -qi 'Entry test' "$IMP" && grep -q 'US-002' "$IMP" && grep -q 'review-work' "$IMP"
assert_ok $? "implement: an entry test keeps trivial work out (cites US-002)"
# prose wraps across lines, so collapse whitespace before matching
IMPFLAT="$(tr '\n' ' ' < "$IMP" | tr -s ' ')"
printf '%s' "$IMPFLAT" | grep -qi 'six spawns are mandatory' \
  && printf '%s' "$IMPFLAT" | grep -qi 'ask the human to raise the cap'
assert_ok $? "implement: states 6 mandatory spawns and requires a human raise above the cap"
grep -q 'rejects to: `qa` when a test is wrong' "$IMP" \
  && grep -qi 'cannot be made to fail' "$IMP"
assert_ok $? "implement: Phase 3 names both rework owners with the criterion bounce capped"
printf '%s' "$IMPFLAT" | grep -qi 'one continuous spawn' \
  && printf '%s' "$IMPFLAT" | grep -qi 'One architect spawn serves the whole lifecycle'
assert_ok $? "implement: one architect spawn serves Phase 2 and the ratification gate"
# the command must not reference infrastructure absent from this release
# Structural, not keyword-based: the real defect was prose pointing at
# infrastructure absent from the release, and a keyword guard only catches the
# phrasings you thought of (R6 cycle-3 residue). Every path the command names
# must resolve on disk.
missing=""
for ref in $(grep -oE '`(skills|scripts|templates|docs)/[A-Za-z0-9_./-]+`' "$IMP" | tr -d '`' | sort -u); do
  [ -e "$ROOT/$ref" ] || missing="$missing $ref"
done
grep -q 'scripts/anoti board' "$IMP" && { [ -x "$ROOT/scripts/board" ] || missing="$missing scripts/board"; }
grep -q 'board skill' "$IMP" && { [ -f "$ROOT/skills/board/SKILL.md" ] || missing="$missing skills/board/SKILL.md"; }
[ -z "$missing" ]; assert_ok $? "implement references only infrastructure that exists -- missing:$missing"
