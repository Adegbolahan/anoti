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
grep -qi "retrospect" "$ROOT/skills/consolidate/SKILL.md" 2>/dev/null
assert_ok $? "consolidate runs the session retrospective"
for s in spec plan; do
  f="$ROOT/skills/$s/SKILL.md"
  [ -s "$f" ]; assert_ok $? "document skill exists: $s"
  assert_eq "$(sed -n 's/^name: //p' "$f" | head -1)" "$s" "frontmatter name matches: $s"
done
grep -q "docs/specs/" "$ROOT/skills/spec/SKILL.md" 2>/dev/null && grep -qi "pre-registered\|pre-registration" "$ROOT/skills/spec/SKILL.md" 2>/dev/null && grep -qi "success criteria" "$ROOT/skills/spec/SKILL.md" 2>/dev/null
assert_ok $? "spec skill: filing path + experiment pre-registration + success criteria"
grep -q "docs/plans/" "$ROOT/skills/plan/SKILL.md" 2>/dev/null && grep -qi "no placeholder" "$ROOT/skills/plan/SKILL.md" 2>/dev/null && grep -qi "cascade plan" "$ROOT/skills/plan/SKILL.md" 2>/dev/null
assert_ok $? "plan skill: filing path + no-placeholders + cascade plan format"
grep -q "plan skill" "$ROOT/skills/deliberate/SKILL.md" 2>/dev/null
assert_ok $? "deliberate references the plan skill"
grep -q "story_ref" "$ROOT/skills/attend/SKILL.md" 2>/dev/null && grep -qi "HIGH-LEVEL-STORIES" "$ROOT/skills/attend/SKILL.md" 2>/dev/null
assert_ok $? "attend frames carry story_ref against the value standard"
f="$ROOT/skills/direction/SKILL.md"
[ -s "$f" ]; assert_ok $? "direction skill exists"
assert_eq "$(sed -n 's/^name: //p' "$f" | head -1)" "direction" "direction skill name matches"
grep -q "ROADMAP.md" "$f" && grep -q "HIGH-LEVEL-STORIES.md" "$f"; assert_ok $? "direction covers both organs"
grep -q "As a" "$f" && grep -qi "draft-for-ratification" "$f"; assert_ok $? "direction carries story shape + ratification rule"
grep -qi "visionary\|product-manager" "$f"; assert_ok $? "direction names its managing roles"
grep -q "direction skill" "$ROOT/roles/visionary.md" && grep -q "direction skill" "$ROOT/roles/product-manager.md" && grep -q "direction skill" "$ROOT/roles/requirements-analyst.md"
assert_ok $? "all three managing roles reference the direction skill"
grep -q "mkdir -m 700" "$ROOT/skills/consolidate/SKILL.md" && \
  grep -q "umask 077" "$ROOT/skills/consolidate/SKILL.md" && \
  awk '/mkdir -m 700/{a=NR} /umask 077/{if(!b)b=NR} /trust --global/{if(!c)c=NR} END{exit !(a && b && c && a<=b && b<=c)}' "$ROOT/skills/consolidate/SKILL.md"
assert_ok $? "consolidate creation flow in load-bearing order (mkdir -> umask cp -> trust --global)"
awk '/project store as a normal record/{a=NR} /scope-deferred/{if(!b)b=NR} END{exit !(a && b && a<b)}' "$ROOT/skills/consolidate/SKILL.md"
assert_ok $? "deferral is record-then-event, in that order"
grep -qi "routing classes" "$ROOT/skills/consolidate/SKILL.md" && grep -qi "scoped-exception" "$ROOT/skills/consolidate/SKILL.md"
assert_ok $? "consolidate carries routing classes + cross-tier precedence"
