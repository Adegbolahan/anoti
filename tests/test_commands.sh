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
grep -q "skillify" "$ROOT/commands/new.md" && grep -qi "never scaffold into the plugin" "$ROOT/commands/new.md"
assert_ok $? "new wraps skillify with the plugin-dir safety check"
grep -q "docs/HIGH-LEVEL-STORIES.md" "$ROOT/commands/implement.md" && grep -qi "spec skill" "$ROOT/commands/implement.md" && grep -q "review-work" "$ROOT/commands/implement.md"
assert_ok $? "implement drives discovery over direction docs + spec gate + review-work"
grep -qi "cycle" "$ROOT/commands/review-work.md" && grep -qi "evidence" "$ROOT/commands/review-work.md" && grep -qi "rubber-stamp" "$ROOT/commands/review-work.md"
assert_ok $? "review-work keeps evidence contract, cycle cap, no-rubber-stamp"
grep -qi "never downgrade\|newer than the installed" "$ROOT/commands/update.md" && grep -q "skillify" "$ROOT/commands/update.md"
assert_ok $? "update wraps skillify migration with never-downgrade"

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
