POLICIES="epistemic trace-to-frame escalate-destructive retrospect parallel-breadth adversarial-handoff test-driven visual-verify reversible-change draft-for-ratification reader-run"
for p in $POLICIES; do
  f="$ROOT/skills/policy-$p/SKILL.md"
  [ -s "$f" ]; assert_ok $? "policy skill exists: $p"
  assert_eq "$(sed -n 's/^name: //p' "$f" | head -1)" "policy-$p" "frontmatter name matches: $p"
  [ -n "$(sed -n 's/^description: //p' "$f" | head -1)" ]; assert_ok $? "description non-empty: $p"
done
grep -qi "cite" "$ROOT/skills/policy-epistemic/SKILL.md" 2>/dev/null && grep -qi "judgment" "$ROOT/skills/policy-epistemic/SKILL.md" 2>/dev/null
assert_ok $? "epistemic covers cite+judgment"
grep -qi "ratif" "$ROOT/skills/policy-draft-for-ratification/SKILL.md" 2>/dev/null
assert_ok $? "draft-for-ratification covers ratification"
grep -qi "never edits" "$ROOT/skills/policy-adversarial-handoff/SKILL.md" 2>/dev/null
assert_ok $? "adversarial-handoff: judge never edits"
grep -qi "went well" "$ROOT/skills/policy-retrospect/SKILL.md" 2>/dev/null && grep -qi "skillif" "$ROOT/skills/policy-retrospect/SKILL.md" 2>/dev/null && grep -qi "cannot be automated" "$ROOT/skills/policy-retrospect/SKILL.md" 2>/dev/null
assert_ok $? "retrospect covers went-well/skillify/cannot-be-automated"
grep -qi "issue" "$ROOT/skills/policy-retrospect/SKILL.md" && grep -qi "outward-facing" "$ROOT/skills/policy-retrospect/SKILL.md"
assert_ok $? "retrospect routes anoti friction to human-gated issues"
grep -qi "cite it by ID" "$ROOT/skills/policy-epistemic/SKILL.md"
assert_ok $? "#4a epistemic: implementing artifacts cite record IDs"
