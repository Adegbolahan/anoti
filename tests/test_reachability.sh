# every skill must be reachable: >=1 precise referrer outside its own dir
for d in "$ROOT"/skills/*/; do
  n=$(basename "$d")
  bare="${n#policy-}"
  refs=0
  # prose references (full name or "<name> skill" / skills/<name>/)
  c=$(grep -rlE "($n|the $bare skill|\($bare skill\)|skills/$n/)" "$ROOT/scripts" "$ROOT/commands" "$ROOT/agents" "$ROOT/roles" "$ROOT/skills" 2>/dev/null | grep -v "skills/$n/" | wc -l | tr -d ' ')
  refs=$((refs + c))
  # role-stack references for policies (bare token in a policies list)
  case "$n" in policy-*)
    c=$(grep -l "policies:" "$ROOT"/roles/*.md 2>/dev/null | xargs grep -lE "(\[|, |^    )$bare(,|\]|$)" 2>/dev/null | wc -l | tr -d ' ')
    refs=$((refs + c)) ;;
  esac
  [ "$refs" -ge 1 ]; assert_ok $? "skill reachable: $n ($refs referrers)"
done
# the cycle's spine is explicitly chained, never description-luck
grep -q "attend" "$ROOT/scripts/classify"; assert_ok $? "chain: classify -> attend"
grep -qi "deliberate skill" "$ROOT/skills/attend/SKILL.md"; assert_ok $? "chain: attend -> deliberate"
grep -q "consolidate" "$ROOT/scripts/consolidation-gate"; assert_ok $? "chain: gate -> consolidate"
grep -qi "retrospect" "$ROOT/skills/consolidate/SKILL.md"; assert_ok $? "chain: consolidate -> retrospect"
grep -qi "spec skill" "$ROOT/roles/architect.md"; assert_ok $? "chain: architect -> spec skill"
