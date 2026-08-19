# every plan declares its governing authority: a spec file or an explicit none+authority
for f in "$ROOT"/docs/plans/*.md; do
  grep -qE '^\*\*Spec:\*\*' "$f"
  assert_ok $? "plan declares its spec: $(basename "$f")"
done
# declared spec files must exist (when a path is given)
for f in "$ROOT"/docs/plans/*.md; do
  ref="$(grep -m1 -oE 'docs/specs/[a-zA-Z0-9._-]+\.md' "$f" | head -1)"
  if [ -n "$ref" ]; then
    [ -f "$ROOT/$ref" ]; assert_ok $? "declared spec exists: $(basename "$f") -> $ref"
  fi
done
grep -q "Cross-project citations" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md" && \
  grep -qE "2026-08-13 — amended" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"
assert_ok $? "longitudinal spec carries the dated seventh-source amendment"
grep -qE "2026-08-13 — recall metric" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"
assert_ok $? "#4a longitudinal metric clarified by dated amendment"

# --- jit-recall spec §4.9: review-work checklist gains Evidence kind ---
grep -q "Evidence kind" "$ROOT/commands/review-work.md" && grep -q "G004/G008" "$ROOT/commands/review-work.md"
assert_ok $? "review-work checklist carries the Evidence kind dimension"
# anchored to the bulleted checklist items specifically -- "Frontend" also
# appears unrelatedly in the Step 4 report-format template
# (commands/review-work.md:68), which a bare /Frontend/ pattern would
# match instead of the intended checklist bullet.
awk '/^- \*\*Frontend\*\*/{a=NR} /^- \*\*Evidence kind\*\*/{b=NR} END{exit !(a && b && a<b)}' "$ROOT/commands/review-work.md"
assert_ok $? "Evidence kind bullet follows the Frontend bullet"
