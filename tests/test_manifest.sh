# manifest exists, is valid JSON, has name/description/version
m="$ROOT/.claude-plugin/plugin.json"
[ -f "$m" ]; assert_ok $? "plugin.json exists"
jq -e '.name == "anoti" and (.description|length) > 0 and (.version|length) > 0' "$m" >/dev/null 2>&1
assert_ok $? "plugin.json has name=anoti, description, version"
