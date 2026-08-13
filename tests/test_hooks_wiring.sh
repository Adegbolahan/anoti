h="$ROOT/hooks/hooks.json"
[ -f "$h" ]; assert_ok $? "hooks.json exists"
jq -e '.hooks | has("SessionStart") and has("UserPromptSubmit") and has("PreToolUse") and has("PreCompact") and has("Stop") and has("SessionEnd")' "$h" >/dev/null 2>&1
assert_ok $? "all six events wired"
assert_eq "$(jq -r '.hooks.SessionStart[0].hooks[0].timeout' "$h")" "10" "retrieve timeout 10s"
assert_eq "$(jq -r '.hooks.PreToolUse[0].matcher' "$h")" "Bash|Write|Edit" "inhibition matcher scoped"
# every referenced script exists and is executable (resolve ${CLAUDE_PLUGIN_ROOT} to repo root)
for cmd in $(jq -r '.. | .command? // empty' "$h"); do
  real="${cmd/\$\{CLAUDE_PLUGIN_ROOT\}/$ROOT}"
  [ -x "$real" ]; assert_ok $? "wired script exists+executable: $real"
done
n="$("$ROOT/scripts/classify" </dev/null | jq -r '.hookSpecificOutput.additionalContext' | wc -l | tr -d ' ')"
[ "$n" -le 10 ]; assert_ok $? "classifier injection is <= 10 lines (attention tax)"
