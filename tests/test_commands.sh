for c in review recall consolidate; do
  f="$ROOT/commands/$c.md"
  [ -s "$f" ]; assert_ok $? "command exists: $c"
  [ -n "$(sed -n 's/^description: //p' "$f" | head -1)" ]; assert_ok $? "command description non-empty: $c"
done
grep -q '\$ARGUMENTS' "$ROOT/commands/recall.md" 2>/dev/null; assert_ok $? "recall uses \$ARGUMENTS"
grep -q "regen-index" "$ROOT/commands/consolidate.md" 2>/dev/null; assert_ok $? "consolidate runs regen-index"
grep -qi "demot" "$ROOT/commands/review.md" 2>/dev/null; assert_ok $? "review supports demotion"
