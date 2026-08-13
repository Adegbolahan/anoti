# manifest exists, is valid JSON, has name/description/version
m="$ROOT/.claude-plugin/plugin.json"
[ -f "$m" ]; assert_ok $? "plugin.json exists"
jq -e '.name == "anoti" and (.description|length) > 0 and (.version|length) > 0' "$m" >/dev/null 2>&1
assert_ok $? "plugin.json has name=anoti, description, version"

# Task 9: workspace templates exist and are non-empty
for t in ROADMAP.md HIGH-LEVEL-STORIES.md TODOS.md LESSONS-LEARNT.md gitignore-fragment; do
  [ -s "$ROOT/templates/$t" ]; assert_ok $? "template exists and non-empty: $t"
done
grep -q '^\.anoti/' "$ROOT/templates/gitignore-fragment"; assert_ok $? "gitignore fragment ignores .anoti/"
