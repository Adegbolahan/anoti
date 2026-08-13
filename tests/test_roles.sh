ROLES="conductor project-manager architect frontend backend database qa reviewer security technical-writer"
for r in $ROLES; do
  f="$ROOT/roles/$r.md"
  [ -s "$f" ]; assert_ok $? "role exists: $r"
  assert_eq "$(sed -n 's/^name: //p' "$f" | head -1)" "$r" "role name matches: $r"
  [ -n "$(sed -n 's/^phase: //p' "$f" | head -1)" ]; assert_ok $? "role phase present: $r"
  cls="$(sed -n 's/^class: //p' "$f" | head -1)"
  case "$cls" in advisory|builder|reviewer) ok=0 ;; *) ok=1 ;; esac
  assert_eq "$ok" "0" "role class valid: $r ($cls)"
  # every listed policy resolves to a policy skill
  for p in $(sed -n 's/^policies: \[\(.*\)\]/\1/p' "$f" | tr ',' ' '); do
    [ -f "$ROOT/skills/policy-$p/SKILL.md" ]; assert_ok $? "policy resolves: $r -> $p"
  done
done
grep -qi "cascade plan" "$ROOT/roles/conductor.md" 2>/dev/null && grep -qi "executive function" "$ROOT/roles/conductor.md" 2>/dev/null && grep -qi "never dispatches" "$ROOT/roles/conductor.md" 2>/dev/null
assert_ok $? "conductor: cascade plan + executive function + never dispatches"
grep -qi "never edits" "$ROOT/roles/reviewer.md" 2>/dev/null; assert_ok $? "reviewer never edits"
