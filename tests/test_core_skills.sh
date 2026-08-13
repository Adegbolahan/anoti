for s in attend deliberate consolidate skillify; do
  f="$ROOT/skills/$s/SKILL.md"
  [ -s "$f" ]; assert_ok $? "core skill exists: $s"
  assert_eq "$(sed -n 's/^name: //p' "$f" | head -1)" "$s" "frontmatter name matches: $s"
  [ -n "$(sed -n 's/^description: //p' "$f" | head -1)" ]; assert_ok $? "description non-empty: $s"
done
grep -q "evidence_plan" "$ROOT/skills/attend/SKILL.md" 2>/dev/null && grep -q "roadmap_ref" "$ROOT/skills/attend/SKILL.md" 2>/dev/null
assert_ok $? "attend carries full frame schema"
grep -qi "cascade" "$ROOT/skills/deliberate/SKILL.md" 2>/dev/null && grep -qi "conductor" "$ROOT/skills/deliberate/SKILL.md" 2>/dev/null
assert_ok $? "deliberate contains the cascade + conductor"
grep -qi "Roadmap gate" "$ROOT/skills/deliberate/SKILL.md" 2>/dev/null && grep -qi "blocks for the human" "$ROOT/skills/deliberate/SKILL.md" 2>/dev/null
assert_ok $? "deliberate carries the human gates"
ok=0
for t in claim preference decision goal policy; do grep -q "$t" "$ROOT/skills/consolidate/SKILL.md" 2>/dev/null || ok=1; done
grep -q "regen-index" "$ROOT/skills/consolidate/SKILL.md" 2>/dev/null || ok=1
assert_eq "$ok" "0" "consolidate covers all record types + regen-index"
grep -qi "idempotent" "$ROOT/skills/skillify/SKILL.md" 2>/dev/null && grep -qi "dry-run" "$ROOT/skills/skillify/SKILL.md" 2>/dev/null
assert_ok $? "skillify covers idempotent bootstrap + dry-run"
grep -qi "lifetime" "$ROOT/skills/deliberate/SKILL.md" 2>/dev/null && grep -q "plans/" "$ROOT/skills/deliberate/SKILL.md" 2>/dev/null
assert_ok $? "deliberate carries the plan-persistence lifetime rule"
grep -qi "resume the original builder" "$ROOT/skills/deliberate/SKILL.md" 2>/dev/null && grep -qi "pre-fix snapshot" "$ROOT/skills/deliberate/SKILL.md" 2>/dev/null
assert_ok $? "deliberate codifies D011 fix-round continuation"
