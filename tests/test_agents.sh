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
grep -qi "newest" "$ROOT/agents/practitioner.md" && grep -qi "bare role name" "$ROOT/agents/practitioner.md"
assert_ok $? "practitioner resolves bare role names from the newest plugin root"

# --- #19: dispatch vocabulary visible at dispatch time ---
ok=1; for r in "$ROOT"/roles/*.md; do
  n="$(basename "$r" .md)"
  sed -n 's/^description: //p' "$ROOT/agents/practitioner.md" | grep -q -- "$n" || { echo "practitioner description missing role: $n" >&2; ok=0; }
done; [ "$ok" = 1 ]
assert_ok $? "#19 practitioner description enumerates every role in roles/ (invariant)"
grep -q "skills/policy-<name>" "$ROOT/agents/practitioner.md" && grep -qi "bare" "$ROOT/agents/practitioner.md"
assert_ok $? "#19 practitioner states the bare-name -> policy-<name> convention"
grep -qi "bare name" "$ROOT/skills/deliberate/SKILL.md" || grep -qi "policy-<name>" "$ROOT/skills/deliberate/SKILL.md"
assert_ok $? "#19 deliberate states the policy naming convention where hats are assigned"
grep -q "anoti help" "$ROOT/README.md"
assert_ok $? "#19 README names the helper index (anoti help)"
