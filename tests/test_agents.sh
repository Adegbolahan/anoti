for a in consolidator explorer skeptic practitioner; do
  f="$ROOT/agents/$a.md"
  [ -s "$f" ]; assert_ok $? "agent exists: $a"
  assert_eq "$(sed -n 's/^name: //p' "$f" | head -1)" "$a" "agent name matches: $a"
  [ -n "$(sed -n 's/^description: //p' "$f" | head -1)" ]; assert_ok $? "agent description non-empty: $a"
  grep -qi "judgment" "$f" && grep -qi "questions" "$f"; assert_ok $? "agent carries report contract: $a"
done
assert_eq "$(sed -n 's/^tools: //p' "$ROOT/agents/consolidator.md" | head -1)" "Read, Grep, Glob" "consolidator tools allowlist"
assert_eq "$(sed -n 's/^tools: //p' "$ROOT/agents/explorer.md" | head -1)" "Read, Grep, Glob" "explorer tools allowlist"
assert_eq "$(sed -n 's/^tools: //p' "$ROOT/agents/skeptic.md" | head -1)" "Read, Grep, Glob, Bash" "skeptic tools allowlist"
assert_eq "$(sed -n 's/^model: //p' "$ROOT/agents/consolidator.md" | head -1)" "sonnet" "consolidator model"
assert_eq "$(sed -n 's/^model: //p' "$ROOT/agents/explorer.md" | head -1)" "haiku" "explorer model"
assert_eq "$(sed -n 's/^model: //p' "$ROOT/agents/skeptic.md" | head -1)" "inherit" "skeptic model"
grep -q "never" "$ROOT/agents/practitioner.md" 2>/dev/null; assert_ok $? "practitioner forbids memory-organ writes"
