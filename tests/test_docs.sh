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
