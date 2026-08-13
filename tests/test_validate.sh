v="$ROOT/scripts/validate-workspace"
"$v" "$ROOT/tests/fixtures/store_valid.yaml" >/dev/null 2>&1
assert_ok $? "valid store passes validation"
"$v" "$ROOT/tests/fixtures/store_invalid.yaml" >/dev/null 2>&1
assert_eq "$?" "1" "invalid store fails validation"
errs="$("$v" "$ROOT/tests/fixtures/store_invalid.yaml" 2>&1 >/dev/null | grep -c '^invalid:')"
[ "$errs" -ge 4 ]; assert_ok $? "invalid store reports at least 4 reasons (schema, epistemic, type, ratification/dup)"
"$v" "$ROOT/templates/GROUNDING.yaml" >/dev/null 2>&1
assert_ok $? "shipped template validates"
