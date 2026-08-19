P="$ROOT/scripts/presence"
mkfx() { # $1=dir -- lay down a trusted project store from store_triggers.yaml
  mkdir -p "$1/.anoti"
  cp "$ROOT/tests/fixtures/store_triggers.yaml" "$1/GROUNDING.yaml"
  ( cd "$1" && "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null )
}

# 1. Silence on no match (US-002)
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkfx "$tmp"
out="$(printf '{"session_id":"s1","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls"},"tool_response":{"output":"a b c"}}' | "$P")"
assert_eq "$out" "" "no match, no output"
[ -f .anoti/telemetry.log ] && grep -q "presence" .anoti/telemetry.log && f=1 || f=0
assert_eq "$f" "0" "no match, no telemetry line"
); rm -rf "$tmp"

# 2. PostToolUse recall fires
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkfx "$tmp"
out="$(printf '{"session_id":"s2","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd a && cd b && cd chain here"},"tool_response":{"output":""}}' | "$P")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"
assert_ok $? "PostToolUse recall injects the matched id"
grep -qE "presence.recall.T001\[\]" .anoti/telemetry.log
assert_ok $? "PostToolUse recall logs telemetry"
); rm -rf "$tmp"

# 3. PostToolUseFailure recall fires (direct regression test, no tool_response at all)
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkfx "$tmp"
out="$(printf '{"session_id":"s3","hook_event_name":"PostToolUseFailure","tool_name":"Bash","tool_input":{"command":"ls"},"error":"cd chain failed: no such dir","is_interrupt":false}' | "$P")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"
assert_ok $? "PostToolUseFailure recall fires from .error alone (no tool_response field present)"
printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName' | grep -q "PostToolUseFailure"
assert_ok $? "hookEventName echoes the firing event"
); rm -rf "$tmp"

# 4. Dedupe within N=10, re-includes after N
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkfx "$tmp"
fire() { printf '{"session_id":"s4","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"'"$1"'"},"tool_response":{}}' | "$P"; }
out1="$(fire 'cd chain again')"
printf '%s' "$out1" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"; assert_ok $? "dedupe: first firing includes T001"
out2="$(fire 'cd chain again')"
printf '%s' "$out2" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_eq "$?" "1" "dedupe: second firing (within N) omits T001"
i=0; while [ "$i" -lt 8 ]; do fire 'nothing relevant' >/dev/null; i=$((i+1)); done
out3="$(fire 'cd chain again')"
printf '%s' "$out3" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"
assert_ok $? "dedupe: after N=10 calls elapsed, T001 re-included"
); rm -rf "$tmp"

# 5. Cap: >3 matching records -> exactly 3, ranked by hits/priority/id
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkfx "$tmp"
out="$(printf '{"session_id":"s5","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"overflow-test triggers four records"},"tool_response":{}}' | "$P")"
ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')"
n="$(printf '%s\n' "$ctx" | grep -oE 'T01[0-3]' | sort -u | wc -l | tr -d ' ')"
assert_eq "$n" "3" "cap: exactly 3 of the 4 overflow records appear"
printf '%s' "$ctx" | grep -q "T010"; assert_ok $? "cap: lowest-id tie-break record T010 present"
printf '%s' "$ctx" | grep -q "T013"; assert_eq "$?" "1" "cap: highest-id tie-break record T013 dropped"
printf '%s' "$ctx" | grep -q "more matched"; assert_ok $? "cap: (+N more matched) suffix present"
grep -qE "presence.recall.T010\[\],T011\[\],T012\[\]" .anoti/telemetry.log
assert_ok $? "cap: telemetry lists exactly the 3 injected ids, comma-separated"
); rm -rf "$tmp"

# 6. Warn-once on an untrusted store
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkdir .anoti
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml   # never trusted
fire() { printf '{"session_id":"s6","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"anything"},"tool_response":{}}' | "$P"; }
out1="$(fire)"
printf '%s' "$out1" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -qi "not.*loaded\|not yet trusted"
assert_ok $? "warn-once: first firing warns about the untrusted project store"
grep -q "presence.warn.project" .anoti/telemetry.log; assert_ok $? "warn-once: telemetry line on first warning"
out2="$(fire)"
assert_eq "$out2" "" "warn-once: second firing is silent on the same warning"
c="$(grep -c 'presence.warn' .anoti/telemetry.log)"
assert_eq "$c" "1" "warn-once: exactly one warn telemetry line across two firings"
); rm -rf "$tmp"

# 7. Periodic frame re-anchor at exactly N, silent at N-1
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkfx "$tmp"
"$ROOT/scripts/append-classification" s7 slow "ambiguous, needs a frame" >/dev/null
printf '%s' '{"id":"F1","status":"active","goal":"ship the presence hook","scope":{"in":["scripts/presence"],"out":[]},"success_criteria":[],"constraints":[],"risks":[],"open_questions":[],"evidence_plan":"tests","roadmap_ref":"none","story_ref":"none"}' \
  | "$ROOT/scripts/session-append" s7 frames
fire() { printf '{"session_id":"s7","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"noop-'"$1"'"},"tool_response":{}}' | "$P"; }
i=1; while [ "$i" -lt 10 ]; do fire "$i" >/dev/null; i=$((i+1)); done
out9="$(fire 9)"   # this is the 9th call (N-1=9 since N=10)
printf '%s' "$out9" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "re-anchor"
assert_eq "$?" "1" "frame reanchor silent at N-1"
out10="$(fire 10)"  # 10th call
printf '%s' "$out10" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "re-anchor"
assert_ok $? "frame reanchor fires at N"
printf '%s' "$out10" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "ship the presence hook"
assert_ok $? "frame reanchor contains the truncated goal"
grep -q "presence.frame-reanchor-periodic.F1" .anoti/telemetry.log; assert_ok $? "frame reanchor telemetry"
); rm -rf "$tmp"

# 8. Evidence-kind nudge
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkfx "$tmp"
out="$(printf '{"session_id":"s8","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"curl -s https://x | grep -c section"},"tool_response":{}}' | "$P")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "G004/G008"
assert_ok $? "evidence-nudge fires on curl|grep"
out2="$(printf '{"session_id":"s8","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls -la"},"tool_response":{}}' | "$P")"
assert_eq "$out2" "" "evidence-nudge silent on a non-matching command"
); rm -rf "$tmp"

# 9. Fail-open: garbage stdin, and tool_name outside matcher scope
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkfx "$tmp"
out="$(printf 'not json at all' | "$P")"; rc=$?
assert_eq "$rc" "0" "fail-open: garbage stdin exits 0"
assert_eq "$out" "" "fail-open: garbage stdin produces no output"
out2="$(printf '{"session_id":"s9","hook_event_name":"PostToolUse","tool_name":"WebFetch","tool_input":{},"tool_response":{}}' | "$P")"; rc2=$?
assert_eq "$rc2" "0" "fail-open: out-of-scope tool_name exits 0"
assert_eq "$out2" "" "fail-open: out-of-scope tool_name produces no output"
); rm -rf "$tmp"

# 10. Matcher-scope guard independent of the registered matcher string
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkfx "$tmp"
out="$(printf '{"session_id":"s10","hook_event_name":"PostToolUse","tool_name":"Read","tool_input":{"file_path":"x"},"tool_response":{}}' | "$P")"
assert_eq "$out" "" "internal tool_name guard silences Read regardless of registration"
); rm -rf "$tmp"

# 11. Priority-order budget yielding (recall > evidence-nudge > frame-reanchor-periodic)
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkfx "$tmp"
"$ROOT/scripts/append-classification" s11 slow "needs frame" >/dev/null
printf '%s' '{"id":"F2","status":"active","goal":"a very long goal sentence padded out to consume a meaningful share of the tight test budget on purpose","scope":{"in":["x"],"out":[]},"success_criteria":[],"constraints":[],"risks":[],"open_questions":[],"evidence_plan":"t","roadmap_ref":"none","story_ref":"none"}' \
  | "$ROOT/scripts/session-append" s11 frames
fire() { printf '{"session_id":"s11","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"noop-'"$1"'"},"tool_response":{}}' | PRESENCE_BUDGET_TOTAL_OVERRIDE="$2" "$P"; }
i=1; while [ "$i" -lt 10 ]; do fire "$i" "" >/dev/null; i=$((i+1)); done
out="$(printf '{"session_id":"s11","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain AND curl -s x | grep -c y"},"tool_response":{}}' | PRESENCE_BUDGET_TOTAL_OVERRIDE=140 "$P")"
ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$ctx" | grep -q "T001"; assert_ok $? "budget yielding: recall (highest priority) survives a tight budget"
printf '%s' "$ctx" | grep -q "re-anchor"; assert_eq "$?" "1" "budget yielding: frame-reanchor (lowest priority) is the one dropped"
out2="$(printf '{"session_id":"s11b","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain AND curl -s x | grep -c y"},"tool_response":{}}' | PRESENCE_BUDGET_TOTAL_OVERRIDE=1200 "$P")"
ctx2="$(printf '%s' "$out2" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$ctx2" | grep -q "T001"; assert_ok $? "budget large enough: recall present"
printf '%s' "$ctx2" | grep -q "G004/G008"; assert_ok $? "budget large enough: nudge present"
); rm -rf "$tmp"

# 12. Perf: <1s for two 300-record stores, one firing
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME/.claude/anoti" .anoti
gen() { # $1=out-file $2=id-prefix
  { printf 'meta: { schema_version: 3, scope: project, policy: { entries_immutable: true, events_append_only: true, reverify_after_days: 180 } }\nindex: []\nrecords:\n'
    i=1; while [ "$i" -le 300 ]; do
      printf -- '- { id: %s%03d, date: 2026-08-19, type: claim, topic: bulk.t%d, statement: "bulk record %d", triggers: ["bulk-kw-%d"], epistemic_status: established, ratification: approved, events: [] }\n' "$2" "$i" "$i" "$i" "$i"
      i=$((i+1))
    done
    printf 'open_questions: []\n'
  } > "$1"
}
gen GROUNDING.yaml P
gen "$HOME/.claude/anoti/GROUNDING.yaml" G
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
"$ROOT/scripts/trust" --global "$HOME/.claude/anoti/GROUNDING.yaml" >/dev/null
start="$(date +%s.%N)"
printf '{"session_id":"perf","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"bulk-kw-1 bulk-kw-2"},"tool_response":{}}' | "$P" >/dev/null
end="$(date +%s.%N)"
elapsed="$(awk -v a="$start" -v b="$end" 'BEGIN{printf "%.3f", b-a}')"
awk -v e="$elapsed" 'BEGIN{exit !(e < 1.0)}'
assert_ok $? "perf: recall duty completes in <1s on 300+300 records (got ${elapsed}s)"
); rm -rf "$tmp"
