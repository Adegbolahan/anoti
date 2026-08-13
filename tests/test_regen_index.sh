tmp="$(mktemp -d)"; cp "$ROOT/tests/fixtures/store_valid.yaml" "$tmp/s.yaml"
"$ROOT/scripts/regen-index" "$tmp/s.yaml"
assert_ok $? "regen-index exits 0 on valid store"
assert_eq "$(yq -r '.index | length' "$tmp/s.yaml")" "2" "index has one row per record"
assert_eq "$(yq -r '.index[0].ref' "$tmp/s.yaml")" "D001" "index row uses ref (not id)"
assert_eq "$(yq -r '.index[1].statement' "$tmp/s.yaml")" "Prefer reversible deployments." "index carries statement"
cp "$ROOT/tests/fixtures/store_invalid.yaml" "$tmp/bad.yaml"
before="$(cat "$tmp/bad.yaml")"
"$ROOT/scripts/regen-index" "$tmp/bad.yaml" 2>/dev/null
assert_eq "$?" "1" "regen-index refuses invalid store"
assert_eq "$(cat "$tmp/bad.yaml")" "$before" "invalid store left untouched"
rm -rf "$tmp"

# regen-index must NOT re-serialize records (round-tripping mangles scalars)
tmp="$(mktemp -d)"
cat > "$tmp/tricky.yaml" <<'YAML'
meta:
  schema_version: 3
  scope: project
  policy: {entries_immutable: true, events_append_only: true, reverify_after_days: 180}
index: []
records:
  - id: T001
    date: 2026-08-13
    type: claim
    topic: tricky.notes
    statement: "Statement with: colon, and comma"
    epistemic_status: probable
    ratification: approved
    source: {type: observation, context: "live session, tricky task"}
    evidence: []
    events:
      - {date: 2026-08-13, action: created, by: session, note: "second run, cascade; approved: yes"}
open_questions: []
YAML
before_rec="$(sed -n '/^records:/,/^open_questions:/p' "$tmp/tricky.yaml")"
"$ROOT/scripts/regen-index" "$tmp/tricky.yaml"
assert_ok $? "regen-index handles colon/comma scalars"
after_rec="$(sed -n '/^records:/,/^open_questions:/p' "$tmp/tricky.yaml")"
assert_eq "$after_rec" "$before_rec" "records section byte-identical after regen"
assert_eq "$(yq -r '.index | length' "$tmp/tricky.yaml")" "1" "tricky index regenerated"
assert_eq "$(yq -r '.index[0].statement' "$tmp/tricky.yaml")" "Statement with: colon, and comma" "index statement survives intact"
rm -rf "$tmp"
