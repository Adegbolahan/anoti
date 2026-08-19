ROLES="conductor project-manager architect frontend backend database qa reviewer security technical-writer"
for r in $ROLES; do
  f="$ROOT/roles/$r.md"
  [ -s "$f" ]; assert_ok $? "role exists: $r"
  assert_eq "$(sed -n 's/^name: //p' "$f" | head -1)" "$r" "role name matches: $r"
  [ -n "$(sed -n 's/^phase: //p' "$f" | head -1)" ]; assert_ok $? "role phase present: $r"
  cls="$(sed -n 's/^class: //p' "$f" | head -1)"
  case "$cls" in advisory|builder|reviewer) ok=0 ;; *) ok=1 ;; esac
  assert_eq "$ok" "0" "role class valid: $r ($cls)"
  # every listed policy resolves to a policy skill (handles single- and multi-line lists)
  pol="$(awk '/^policies:/{f=1} f{print; if (/\]/) exit}' "$f" | tr -d '\n' | sed 's/.*\[//; s/\].*//; s/,/ /g')"
  [ -n "$pol" ]; assert_ok $? "policies extracted (nonzero): $r"
  for p in $pol; do
    [ -f "$ROOT/skills/policy-$p/SKILL.md" ]; assert_ok $? "policy resolves: $r -> $p"
  done
done
grep -qi "cascade plan" "$ROOT/roles/conductor.md" 2>/dev/null && grep -qi "executive function" "$ROOT/roles/conductor.md" 2>/dev/null && grep -qi "never dispatches" "$ROOT/roles/conductor.md" 2>/dev/null
assert_ok $? "conductor: cascade plan + executive function + never dispatches"
grep -qi "never edits" "$ROOT/roles/reviewer.md" 2>/dev/null; assert_ok $? "reviewer never edits"

# --- v1.1 roles: same frontmatter/policy contract as core-10 ---
ROLES_V11="visionary product-manager requirements-analyst ux-researcher ui-designer mobile ai-ml devops performance sales marketing legal support"
for r in $ROLES_V11; do
  f="$ROOT/roles/$r.md"
  [ -s "$f" ]; assert_ok $? "role exists: $r"
  assert_eq "$(sed -n 's/^name: //p' "$f" | head -1)" "$r" "role name matches: $r"
  [ -n "$(sed -n 's/^phase: //p' "$f" | head -1)" ]; assert_ok $? "role phase present: $r"
  cls="$(sed -n 's/^class: //p' "$f" | head -1)"
  case "$cls" in advisory|builder|reviewer) ok=0 ;; *) ok=1 ;; esac
  assert_eq "$ok" "0" "role class valid: $r ($cls)"
  pol="$(awk '/^policies:/{f=1} f{print; if (/\]/) exit}' "$f" | tr -d '\n' | sed 's/.*\[//; s/\].*//; s/,/ /g')"
  [ -n "$pol" ]; assert_ok $? "policies extracted (nonzero): $r"
  for p in $pol; do
    [ -f "$ROOT/skills/policy-$p/SKILL.md" ]; assert_ok $? "policy resolves: $r -> $p"
  done
done
# binding content per role, keyed to the spec role table
grep -qi "falsifiable" "$ROOT/roles/visionary.md" 2>/dev/null; assert_ok $? "visionary: falsifiable success metrics"
grep -qi "trade-off" "$ROOT/roles/product-manager.md" 2>/dev/null; assert_ok $? "product-manager: trade-off-first"
grep -qi "acceptance" "$ROOT/roles/requirements-analyst.md" 2>/dev/null; assert_ok $? "requirements-analyst: acceptance-first"
grep -qi "observation over assumption" "$ROOT/roles/ux-researcher.md" 2>/dev/null; assert_ok $? "ux-researcher: evidence-first"
grep -qi "mockup" "$ROOT/roles/ui-designer.md" 2>/dev/null; assert_ok $? "ui-designer: mockups before pixels-in-code"
grep -qi "offline" "$ROOT/roles/mobile.md" 2>/dev/null; assert_ok $? "mobile: offline states"
grep -qi "eval" "$ROOT/roles/ai-ml.md" 2>/dev/null; assert_ok $? "ai-ml: eval-first"
grep -qi "rollback" "$ROOT/roles/devops.md" 2>/dev/null; assert_ok $? "devops: rollback proven"
grep -qi "baseline" "$ROOT/roles/performance.md" 2>/dev/null; assert_ok $? "performance: measured baseline"
grep -qi "objection" "$ROOT/roles/sales.md" 2>/dev/null; assert_ok $? "sales: objection-first"
grep -qi "segment" "$ROOT/roles/marketing.md" 2>/dev/null; assert_ok $? "marketing: audience segments"
grep -qi "never counsel" "$ROOT/roles/legal.md" 2>/dev/null; assert_ok $? "legal: drafts for counsel, never counsel"
grep -qi "friction" "$ROOT/roles/support.md" 2>/dev/null; assert_ok $? "support: friction-first"
grep -qi "RED transcript" "$ROOT/roles/reviewer.md" && grep -qi "scratch copy" "$ROOT/roles/reviewer.md" && grep -qi "zero residue" "$ROOT/roles/reviewer.md"
assert_ok $? "reviewer: optional empirical RED-transcript evidence codified"

# --- jit-recall spec §4.9: reviewer role names the evidence-kind check ---
grep -qE "G004/G008" "$ROOT/roles/reviewer.md"
assert_ok $? "reviewer role names the evidence-kind check"
grep -q "distrust the report" "$ROOT/roles/reviewer.md"
assert_ok $? "existing distrust-the-report sentence preserved"
