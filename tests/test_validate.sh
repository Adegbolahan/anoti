v="$ROOT/scripts/validate-workspace"
"$v" "$ROOT/tests/fixtures/store_valid.yaml" >/dev/null 2>&1
assert_ok $? "valid store passes validation"
"$v" "$ROOT/tests/fixtures/store_invalid.yaml" >/dev/null 2>&1
assert_eq "$?" "1" "invalid store fails validation"
errs="$("$v" "$ROOT/tests/fixtures/store_invalid.yaml" 2>&1 >/dev/null | grep -c '^invalid:')"
[ "$errs" -ge 4 ]; assert_ok $? "invalid store reports at least 4 reasons (schema, epistemic, type, ratification/dup)"
"$v" "$ROOT/templates/GROUNDING.yaml" >/dev/null 2>&1
assert_ok $? "shipped template validates"

# regression: missing or null records list must fail validation
tmpv="$(mktemp -d)"
printf 'meta: { schema_version: 3 }\nopen_questions: []\n' > "$tmpv/norec.yaml"
"$v" "$tmpv/norec.yaml" >/dev/null 2>&1
assert_eq "$?" "1" "store with missing records key fails validation"
printf 'meta: { schema_version: 3 }\nrecords: null\n' > "$tmpv/nullrec.yaml"
"$v" "$tmpv/nullrec.yaml" >/dev/null 2>&1
assert_eq "$?" "1" "store with null records fails validation"
rm -rf "$tmpv"

# unknown keys in source/events/evidence = unquoted-scalar split; must fail
tmpm="$(mktemp -d)"
cat > "$tmpm/mangled.yaml" <<'YAML'
meta:
  schema_version: 3
  scope: project
  policy: {entries_immutable: true, events_append_only: true, reverify_after_days: 180}
index: []
records:
  - id: M001
    date: 2026-08-13
    type: claim
    topic: mangle.test
    statement: A statement.
    epistemic_status: probable
    ratification: approved
    source: {type: session, context: build, extra fragment: ''}
    events:
      - {date: 2026-08-13, action: created, by: session, note: part one, part two: ''}
open_questions: []
YAML
"$v" "$tmpm/mangled.yaml" >/dev/null 2>&1
assert_eq "$?" "1" "split-scalar corruption fails validation"
"$v" "$tmpm/mangled.yaml" 2>&1 >/dev/null | grep -q "unexpected key"
assert_ok $? "corruption reported as unexpected key"
rm -rf "$tmpm"

# meta.scope location mismatch warns without failing (spec: global tier)
tmpg="$(mktemp -d)"; ( cd "$tmpg"
HOME="$tmpg/home"; export HOME; mkdir -p "$HOME"
sed 's/scope: project/scope: global/' "$ROOT/tests/fixtures/store_valid.yaml" > s.yaml
err="$("$v" s.yaml 2>&1 >/dev/null)"; rc=$?
assert_eq "$rc" "0" "scope mismatch alone does not fail validation"
printf '%s' "$err" | grep -qi "warning: meta.scope"; assert_ok $? "scope mismatch warned on stderr"
); rm -rf "$tmpg"

# triggers shape check (spec: jit-recall §4.5)
tmpt="$(mktemp -d)"
mk() { printf 'meta: { schema_version: 3 }\nrecords:\n  - { id: X, date: 2026-08-19, type: claim, topic: t, statement: s, epistemic_status: established, ratification: approved, triggers: %s }\nopen_questions: []\n' "$1" > "$tmpt/f.yaml"; }
mk '[]'
"$v" "$tmpt/f.yaml" >/dev/null 2>&1; assert_ok $? "triggers: [] passes"
mk '["a", "b"]'
"$v" "$tmpt/f.yaml" >/dev/null 2>&1; assert_ok $? "triggers: [a,b] passes"
mk '[""]'
"$v" "$tmpt/f.yaml" >/dev/null 2>&1; assert_eq "$?" "1" "triggers: [\"\"] fails"
mk '"x"'
"$v" "$tmpt/f.yaml" >/dev/null 2>&1; assert_eq "$?" "1" "triggers: bare scalar fails"
mk '[1]'
"$v" "$tmpt/f.yaml" >/dev/null 2>&1; assert_eq "$?" "1" "triggers: [1] fails (non-string element)"
printf 'meta: { schema_version: 3 }\nrecords:\n  - { id: X, date: 2026-08-19, type: claim, topic: t, statement: s, epistemic_status: established, ratification: approved }\nopen_questions: []\n' > "$tmpt/f.yaml"
"$v" "$tmpt/f.yaml" >/dev/null 2>&1; assert_ok $? "absent triggers passes (optional field)"
rm -rf "$tmpt"
