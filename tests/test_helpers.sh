tmp="$(mktemp -d)"; ( cd "$tmp"
# --- append-classification: creates state, appends safely, logs telemetry ---
mkdir -p .anoti  # anchor: #13 writers refuse unanchored dirs
"$ROOT/scripts/append-classification" s1 slow "ambiguous ask: needs frame, budget"
assert_ok $? "append-classification exits 0"
assert_eq "$(yq -r '.classifications | length' .anoti/sessions/s1.yaml)" "1" "one classification appended"
"$ROOT/scripts/append-classification" s1 fast "routine lookup, no consequence: none"
assert_eq "$(yq -r '.classifications | length' .anoti/sessions/s1.yaml)" "2" "second appended, no duplication"
assert_eq "$(yq -r '.classifications[0].reason' .anoti/sessions/s1.yaml)" "ambiguous ask: needs frame, budget" "colon/comma reason survives intact"
yq -e '.' .anoti/sessions/s1.yaml >/dev/null 2>&1; assert_ok $? "state file stays parseable"
[ -f .anoti/telemetry.log ] && [ "$(wc -l < .anoti/telemetry.log | tr -d ' ')" = "2" ]
assert_ok $? "telemetry log has one line per classification"
"$ROOT/scripts/append-classification" s1 bogus "x" 2>/dev/null
assert_eq "$?" "1" "invalid verdict rejected"
# --- set-episode ---
"$ROOT/scripts/set-episode" s1 candidate-detected
assert_ok $? "set-episode exits 0"
assert_eq "$(yq -r '.episode' .anoti/sessions/s1.yaml)" "candidate-detected" "episode transitioned"
"$ROOT/scripts/set-episode" s1 nonsense 2>/dev/null
assert_eq "$?" "1" "invalid episode rejected"
assert_eq "$(yq -r '.episode' .anoti/sessions/s1.yaml)" "candidate-detected" "state untouched on rejection"
# --- append-event: tricky note lands intact; store still validates ---
cp "$ROOT/tests/fixtures/store_valid.yaml" store.yaml
"$ROOT/scripts/append-event" store.yaml D001 promoted human "probable -> established: two sessions, distinct tasks"
assert_ok $? "append-event exits 0"
assert_eq "$(yq -r '.records[] | select(.id=="D001") | .events[-1].note' store.yaml)" "probable -> established: two sessions, distinct tasks" "tricky note survives intact"
"$ROOT/scripts/validate-workspace" store.yaml >/dev/null 2>&1; assert_ok $? "store validates after event append"
before="$(cat store.yaml)"
"$ROOT/scripts/append-event" store.yaml NOPE promoted human "x" 2>/dev/null
assert_eq "$?" "1" "unknown record id rejected"
assert_eq "$(cat store.yaml)" "$before" "store untouched on rejection"
# --- append-record: JSON in, validated + indexed + trusted store out ---
printf '%s' '{"id":"D099","date":"2026-08-13","type":"claim","topic":"helper.test","statement":"Statement with: colon, and comma","epistemic_status":"speculative","ratification":"pending","source":{"type":"observation","context":"helper test, tricky path"},"evidence":[],"events":[{"date":"2026-08-13","action":"created","by":"session"}]}' | "$ROOT/scripts/append-record" store.yaml
assert_ok $? "append-record exits 0"
assert_eq "$(yq -r '.records[] | select(.id=="D099") | .statement' store.yaml)" "Statement with: colon, and comma" "tricky statement survives intact"
assert_eq "$(yq -r '.index | length' store.yaml)" "$(yq -r '.records | length' store.yaml)" "index regenerated after append"
grep -qs "$(shasum -a 256 store.yaml | cut -d' ' -f1)" .anoti/trust; assert_ok $? "store re-trusted after append"
printf 'not json' | "$ROOT/scripts/append-record" store.yaml 2>/dev/null
assert_eq "$?" "1" "garbage JSON rejected"
"$ROOT/scripts/validate-workspace" store.yaml >/dev/null 2>&1; assert_ok $? "store still valid after rejected append"
); rm -rf "$tmp"

# --- append-evidence: mechanical evidence attach (gap found during backfill) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
"$ROOT/scripts/append-evidence" s.yaml D001 literature "canonical sources: attention, memory" "Miller (1956)" "Vaswani et al. (2017)"
assert_ok $? "append-evidence exits 0"
assert_eq "$(yq -r '.records[] | select(.id=="D001") | .evidence | length' s.yaml)" "1" "evidence entry appended"
assert_eq "$(yq -r '.records[] | select(.id=="D001") | .evidence[0].refs | length' s.yaml)" "2" "refs list carried intact"
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1; assert_ok $? "store valid after evidence append"
"$ROOT/scripts/append-evidence" s.yaml NOPE literature x r 2>/dev/null
assert_eq "$?" "1" "unknown record id rejected"
); rm -rf "$tmp"

# --- configurable state dir: ANOTI_DIR > .claude/anoti.local.md > default ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
ANOTI_DIR=".claude/anoti" "$ROOT/scripts/append-classification" cfg fast "override test"
[ -f .claude/anoti/sessions/cfg.yaml ]; assert_ok $? "ANOTI_DIR override honored"
[ ! -d .anoti ]; assert_ok $? "default dir untouched under override"
mkdir -p .claude
printf -- '---\nstate_dir: .claude/anoti2\n---\n' > .claude/anoti.local.md
"$ROOT/scripts/append-classification" cfg2 fast "settings test"
[ -f .claude/anoti2/sessions/cfg2.yaml ]; assert_ok $? "settings-file state_dir honored"
rm .claude/anoti.local.md
mkdir -p .anoti  # the workspace dir itself is the anchor (#13)
"$ROOT/scripts/append-classification" cfg3 fast "default test"
[ -f .anoti/sessions/cfg3.yaml ]; assert_ok $? "default .anoti without any knob"
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
ANOTI_DIR=".claude/anoti" "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
out="$(printf '{"session_id":"cfg"}' | ANOTI_DIR=".claude/anoti" "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$out" | grep -q "2 records"; assert_ok $? "retrieve trust check honors ANOTI_DIR"
); rm -rf "$tmp"

# state dir is self-ignoring: creators drop .gitignore('*') inside it
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
"$ROOT/scripts/append-classification" gi fast "gitignore test"
[ -f .anoti/.gitignore ] && [ "$(cat .anoti/.gitignore)" = "*" ]
assert_ok $? "state dir self-ignoring via .anoti/.gitignore"
); rm -rf "$tmp"

# --- global trust adjacency (spec: global-memory-tier) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME/.claude/anoti"
cp "$ROOT/tests/fixtures/store_valid.yaml" "$HOME/.claude/anoti/GROUNDING.yaml"
"$ROOT/scripts/trust" "$HOME/.claude/anoti/GROUNDING.yaml" 2>/dev/null
assert_eq "$?" "1" "global store without --global refused"
[ ! -f "$HOME/.claude/anoti/trust" ]; assert_ok $? "no trust written on refusal"
"$ROOT/scripts/trust" --global "$HOME/.claude/anoti/GROUNDING.yaml" >/dev/null
assert_ok $? "global trust with --global succeeds"
[ -f "$HOME/.claude/anoti/trust" ]; assert_ok $? "trust adjacent to global store"
[ ! -f .anoti/trust ]; assert_ok $? "project trust untouched by global op"
ln -s "$HOME/.claude/anoti" "$tmp/link"
"$ROOT/scripts/trust" "$tmp/link/GROUNDING.yaml" 2>/dev/null
assert_eq "$?" "1" "symlinked global path refused without --global (realpath)"
"$ROOT/scripts/trust" --global "$HOME/.claude/anoti/missing.yaml" 2>/dev/null
assert_eq "$?" "1" "missing store file is an error, never false success"
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
[ -f .anoti/trust ]; assert_ok $? "project store trust unchanged"
ls "$HOME/.claude/anoti/"*.tmp 2>/dev/null | grep -q . && f8=1 || f8=0
assert_eq "$f8" "0" "no tmp residue (atomic write)"
# helper parity on the global store: append works; auto-trust stays project-only
printf '%s' '{"id":"G001","date":"2026-08-13","type":"preference","topic":"user.style","statement":"Terse commits","ratification":"approved","events":[{"date":"2026-08-13","action":"created","by":"session"}]}' \
  | "$ROOT/scripts/append-record" "$HOME/.claude/anoti/GROUNDING.yaml" 2>/dev/null
assert_ok $? "append-record works on the global store"
"$ROOT/scripts/append-event" "$HOME/.claude/anoti/GROUNDING.yaml" G001 scoped-exception session "project overrides in-project" >/dev/null
assert_ok $? "scoped-exception event appends on a global record (precedence mechanics)"
); rm -rf "$tmp"

# --- field-report fixes (0.5.2) ---
# #3: atomic writers preserve store mode (0600 global stores must stay 0600)
tmp="$(mktemp -d)"; ( cd "$tmp"
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml && chmod 600 s.yaml
"$ROOT/scripts/append-event" s.yaml D001 test session "mode check" >/dev/null
assert_eq "$(stat -c %a s.yaml 2>/dev/null || stat -f %Lp s.yaml 2>/dev/null)" "600" "append-event preserves 600"
"$ROOT/scripts/regen-index" s.yaml
assert_eq "$(stat -c %a s.yaml 2>/dev/null || stat -f %Lp s.yaml 2>/dev/null)" "600" "regen-index preserves 600"
printf '%s' '{"id":"M001","date":"2026-08-13","type":"policy","topic":"t.m","statement":"Mode test","ratification":"approved","events":[{"date":"2026-08-13","action":"created","by":"session"}]}' | "$ROOT/scripts/append-record" s.yaml 2>/dev/null
assert_eq "$(stat -c %a s.yaml 2>/dev/null || stat -f %Lp s.yaml 2>/dev/null)" "600" "append-record preserves 600"
); rm -rf "$tmp"
# #1/#2: session-append covers every list the skills instruct; frames are a list
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
printf '%s' '{"id":"F1","goal":"first workstream","status":"active"}' | "$ROOT/scripts/session-append" sa frames
assert_ok $? "session-append frames works"
printf '%s' '{"id":"F2","goal":"second workstream","status":"active"}' | "$ROOT/scripts/session-append" sa frames
assert_eq "$(yq -r '.frames | length' .anoti/sessions/sa.yaml)" "2" "frames are a list — no clobber"
printf '%s' '{"id":"H1","statement":"x","predicted":"y"}' | "$ROOT/scripts/session-append" sa hypotheses
assert_ok $? "session-append hypotheses works"
printf '%s' '{"type":"claim","statement":"z"}' | "$ROOT/scripts/session-append" sa candidates
assert_eq "$(yq -r '.candidates | length' .anoti/sessions/sa.yaml)" "1" "candidates appended"
printf '{}' | "$ROOT/scripts/session-append" sa bogus 2>/dev/null
assert_eq "$?" "1" "unknown key rejected"
printf 'not json' | "$ROOT/scripts/session-append" sa frames 2>/dev/null
assert_eq "$?" "1" "garbage JSON rejected"
); rm -rf "$tmp"
# #8c: append-question — mechanical open_questions writes
tmp="$(mktemp -d)"; ( cd "$tmp"
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
printf '%s' '{"id":"Q100","date":"2026-08-13","question":"Does it work?","raised_by":"session","context":"test","status":"open","refs":[]}' | "$ROOT/scripts/append-question" s.yaml
assert_ok $? "append-question works"
assert_eq "$(yq -r '.open_questions[-1].id' s.yaml)" "Q100" "question appended"
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1; assert_ok $? "store valid after question append"
printf 'junk' | "$ROOT/scripts/append-question" s.yaml 2>/dev/null
assert_eq "$?" "1" "garbage rejected, store untouched"
); rm -rf "$tmp"

# --- issue batch 0.5.4 ---
# #1: set-episode + inhibit write telemetry lines
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
"$ROOT/scripts/append-classification" t1 fast "seed" >/dev/null 2>&1
printf '{"session_id":"t1","tool_name":"Write","tool_input":{"file_path":"GROUNDING.yaml"}}' | "$ROOT/scripts/inhibit" >/dev/null
grep -q "inhibit	deny" .anoti/telemetry.log
assert_ok $? "inhibit denial logs a telemetry line (episode idle)"
"$ROOT/scripts/set-episode" t1 awaiting-approval
grep -q "episode	awaiting-approval" .anoti/telemetry.log
assert_ok $? "set-episode logs a telemetry line"
); rm -rf "$tmp"
# #2: denial message names the unblock commands with the session id
tmp="$(mktemp -d)"; ( cd "$tmp"
out="$(printf '{"session_id":"sX","tool_name":"Write","tool_input":{"file_path":"TODOS.md"}}' | "$ROOT/scripts/inhibit" | jq -r '.hookSpecificOutput.permissionDecisionReason')"
printf '%s' "$out" | grep -q "set-episode sX awaiting-approval"; assert_ok $? "denial prints exact unblock command"
); rm -rf "$tmp"
# #2: append-todo / append-lesson complete the organ-helper set
tmp="$(mktemp -d)"; ( cd "$tmp"
printf '# Todos\n\n- [ ] existing\n' > TODOS.md
"$ROOT/scripts/append-todo" TODOS.md "new item from audit"
grep -q "^- \[ \] new item from audit (raised " TODOS.md; assert_ok $? "append-todo appends dated item"
printf '# Lessons Learnt\n' > LESSONS-LEARNT.md
"$ROOT/scripts/append-lesson" LESSONS-LEARNT.md "a lesson. Why: x. Apply by: y."
grep -q "^- .* — a lesson" LESSONS-LEARNT.md; assert_ok $? "append-lesson appends dated entry"
); rm -rf "$tmp"
# #5: amends chain validated
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
printf '%s' '{"id":"F1","goal":"g","status":"active"}' | "$ROOT/scripts/session-append" am frames
printf '%s' '{"id":"F1b","amends":"F1","goal":"g+","status":"active"}' | "$ROOT/scripts/session-append" am frames
assert_ok $? "valid amends target accepted"
printf '%s' '{"id":"F2","amends":"NOPE","goal":"g","status":"active"}' | "$ROOT/scripts/session-append" am frames 2>/dev/null
assert_eq "$?" "1" "typo'd amends target fails loudly"
); rm -rf "$tmp"

# --- inhibit branch protection: no edit actions on the default branch ---
tmp="$(mktemp -d)"; (
cd "$tmp"
git init -q -b main repo && cd repo
git -c user.email=t@t.t -c user.name=t commit --allow-empty -m init -q
mkdir -p .anoti
out="$(printf '%s' '{"session_id":"bp","tool_name":"Edit","tool_input":{"file_path":"README.md"}}' | "$ROOT/scripts/inhibit")"
printf '%s' "$out" | grep -q '"permissionDecision": *"deny"'
assert_ok $? "edit on default branch (main) is denied"
printf '%s' "$out" | grep -q "feature branch or worktree"
assert_ok $? "branch denial names the remedy"
git switch -q -c feature-x
out="$(printf '%s' '{"session_id":"bp","tool_name":"Edit","tool_input":{"file_path":"README.md"}}' | "$ROOT/scripts/inhibit")"
[ -z "$out" ]; assert_ok $? "edit on a feature branch is allowed"
git switch -q main
mkdir -p .anoti; printf '*\n' > .anoti/.gitignore
out="$(printf '%s' '{"session_id":"bp","tool_name":"Write","tool_input":{"file_path":".anoti/scratch.md"}}' | "$ROOT/scripts/inhibit")"
[ -z "$out" ]; assert_ok $? "gitignored state-dir write allowed on main"
touch .anoti/allow-default-branch
out="$(printf '%s' '{"session_id":"bp","tool_name":"Edit","tool_input":{"file_path":"README.md"}}' | "$ROOT/scripts/inhibit")"
[ -z "$out" ]; assert_ok $? "human override file allows edits on main"
rm .anoti/allow-default-branch
"$ROOT/scripts/append-classification" bp fast "seed" >/dev/null 2>&1
"$ROOT/scripts/set-episode" bp awaiting-approval >/dev/null 2>&1
out="$(printf '%s' '{"session_id":"bp","tool_name":"Write","tool_input":{"file_path":"GROUNDING.yaml"}}' | "$ROOT/scripts/inhibit")"
[ -z "$out" ]; assert_ok $? "organ write with open episode allowed on main (episode gate governs)"
cd "$tmp"; mkdir plain && cd plain
out="$(printf '%s' '{"session_id":"bp","tool_name":"Edit","tool_input":{"file_path":"note.md"}}' | "$ROOT/scripts/inhibit")"
[ -z "$out" ]; assert_ok $? "non-git directory is fail-open allowed"
); rm -rf "$tmp"

# --- #9 session-consume: mark-applied candidate consumption ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
printf '%s' '{"id":"c1","type":"claim","statement":"first"}' | "$ROOT/scripts/session-append" sc candidates
printf '%s' '{"id":"c2","type":"lesson","statement":"second"}' | "$ROOT/scripts/session-append" sc candidates
"$ROOT/scripts/session-consume" sc candidates --ids c1
assert_ok $? "session-consume exits 0 for a named id"
assert_eq "$(yq -r '.candidates[] | select(.id=="c1") | .applied' .anoti/sessions/sc.yaml)" "true" "named candidate marked applied"
assert_eq "$(yq -r '.candidates[] | select(.id=="c2") | .applied // "absent"' .anoti/sessions/sc.yaml)" "absent" "unnamed candidate untouched"
assert_eq "$(yq -r '.candidates | length' .anoti/sessions/sc.yaml)" "2" "nothing deleted — mark-applied, never removal"
"$ROOT/scripts/session-consume" sc candidates
assert_ok $? "no --ids consumes all unapplied"
assert_eq "$(yq -r '[.candidates[] | select(.applied == true)] | length' .anoti/sessions/sc.yaml)" "2" "all candidates now applied"
yq -e '.candidates[0].applied_date' .anoti/sessions/sc.yaml >/dev/null 2>&1
assert_ok $? "applied entries carry a date"
"$ROOT/scripts/session-consume" sc candidates --ids NOPE 2>/dev/null
assert_eq "$?" "1" "unknown candidate id fails loudly"
printf '%s' '{"id":"c*","type":"claim","statement":"glob id"}' | "$ROOT/scripts/session-append" sc candidates
touch c1file c2file
"$ROOT/scripts/session-consume" sc candidates --ids 'c*'
assert_ok $? "glob-shaped id matches literally, never expands against the cwd"
assert_eq "$(yq -r '.candidates[2].applied' .anoti/sessions/sc.yaml)" "true" "glob-shaped id marked applied (index-checked: yq == wildcards)"
yq -e '.' .anoti/sessions/sc.yaml >/dev/null 2>&1; assert_ok $? "session state stays parseable"
); rm -rf "$tmp"

# --- #8 append-evidence: JSON-stdin mode joins the helper convention ---
tmp="$(mktemp -d)"; ( cd "$tmp"
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
printf '%s' '{"type":"observation","note":"json-mode evidence: colon, comma","refs":["trial X"]}' | "$ROOT/scripts/append-evidence" s.yaml D001
assert_ok $? "append-evidence accepts JSON on stdin (2-arg form)"
assert_eq "$(yq -r '.records[] | select(.id=="D001") | .evidence[-1].note' s.yaml)" "json-mode evidence: colon, comma" "json-mode note lands intact"
yq -e '.records[] | select(.id=="D001") | .evidence[-1].date' s.yaml >/dev/null 2>&1
assert_ok $? "json-mode defaults the date"
"$ROOT/scripts/append-evidence" s.yaml D001 literature "positional still works" "ref1"
assert_ok $? "positional form still accepted"
printf 'not json' | "$ROOT/scripts/append-evidence" s.yaml D001 2>/dev/null
assert_eq "$?" "1" "garbage JSON rejected in stdin mode"
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1; assert_ok $? "store valid after both modes"
); rm -rf "$tmp"

# --- #7 classify: machine-notification turns are exempt ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
out="$(printf '%s' '{"session_id":"cx","prompt":"[SYSTEM NOTIFICATION - NOT USER INPUT] subagent skeptic completed"}' | "$ROOT/scripts/classify")"
[ -z "$out" ]; assert_ok $? "bracketed system notification skips the attention tax"
out="$(printf '%s' '{"session_id":"cx","prompt":"<task-notification>workflow wf_x finished</task-notification>"}' | "$ROOT/scripts/classify")"
[ -z "$out" ]; assert_ok $? "task-notification turns skip the attention tax"
out="$(printf '%s' '{"session_id":"cx","prompt":"fix the login bug"}' | "$ROOT/scripts/classify")"
printf '%s' "$out" | grep -q "anoti-attend"
assert_ok $? "real prompts still get the classifier context"
out="$(printf '%s' '{"session_id":"cx","prompt":"why does my log show [SYSTEM NOTIFICATION - NOT USER INPUT] lines?"}' | "$ROOT/scripts/classify")"
printf '%s' "$out" | grep -q "anoti-attend"
assert_ok $? "a prompt merely quoting the marker is still classified (prefix match only)"
); rm -rf "$tmp"

# --- #10 set-ratification / set-status: the ritual can effect decisions ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
"$ROOT/scripts/set-ratification" s.yaml D001 approved "two sessions, distinct tasks"
assert_ok $? "set-ratification exits 0"
assert_eq "$(yq -r '.records[] | select(.id=="D001") | .ratification' s.yaml)" "approved" "ratification field actually changes"
assert_eq "$(yq -r '.records[] | select(.id=="D001") | .events[-1].by' s.yaml)" "human" "audit event appended, by human"
grep -q "distinct tasks" s.yaml; assert_ok $? "decision note lands in the event"
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1; assert_ok $? "store valid after ratification write"
grep -qs "$(shasum -a 256 s.yaml | cut -d' ' -f1)" .anoti/trust; assert_ok $? "store re-trusted after ratification"
"$ROOT/scripts/set-ratification" s.yaml D001 bogus "x" 2>/dev/null
assert_eq "$?" "1" "invalid ratification value rejected"
"$ROOT/scripts/set-ratification" s.yaml NOPE approved "x" 2>/dev/null
assert_eq "$?" "1" "unknown record id rejected (ratification)"
"$ROOT/scripts/set-status" s.yaml D001 established "independent evidence: second session"
assert_ok $? "set-status exits 0"
assert_eq "$(yq -r '.records[] | select(.id=="D001") | .epistemic_status' s.yaml)" "established" "epistemic_status field actually changes"
"$ROOT/scripts/set-status" s.yaml D001 bogus "x" 2>/dev/null
assert_eq "$?" "1" "invalid status value rejected"
"$ROOT/scripts/set-status" s.yaml D002 established "x" 2>/dev/null
assert_eq "$?" "1" "epistemic moves are claims-only: non-claim record rejected"
yq -i '.index = []' s.yaml
"$ROOT/scripts/set-ratification" s.yaml D001 pending "reopen to test index regen"
assert_eq "$(yq -r '.index | length' s.yaml)" "$(yq -r '.records | length' s.yaml)" "set-ratification regenerates the index (mutation-proof)"
grep -q "trust --global" "$ROOT/scripts/set-ratification" && grep -q "trust --global" "$ROOT/scripts/set-status"
assert_ok $? "set-* helpers warn loudly when global trust needs explicit consent"
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1; assert_ok $? "store valid after status write"
); rm -rf "$tmp"

# --- wildcard-equality audit closure: ids meet yq only after exact resolution ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
"$ROOT/scripts/append-event" s.yaml 'D*' promoted human "wildcard must not match D001" 2>/dev/null
assert_eq "$?" "1" "append-event rejects a wildcard-shaped id with no literal match"
printf '%s' '{"type":"observation","note":"x"}' | "$ROOT/scripts/append-evidence" s.yaml 'D0*' 2>/dev/null
assert_eq "$?" "1" "append-evidence rejects a wildcard-shaped id with no literal match"
printf '%s' '{"id":"F1","goal":"g","status":"active"}' | "$ROOT/scripts/session-append" wc frames
printf '%s' '{"id":"F2","amends":"F*","goal":"g2","status":"active"}' | "$ROOT/scripts/session-append" wc frames 2>/dev/null
assert_eq "$?" "1" "amends target must match literally, never as a pattern"
); rm -rf "$tmp"

# --- #12 complete-todo: the tick half of the TODOS contract ---
tmp="$(mktemp -d)"; ( cd "$tmp"
touch T.md
"$ROOT/scripts/append-todo" T.md "alpha task: verify the widget"
"$ROOT/scripts/append-todo" T.md "beta task: ship the gadget"
"$ROOT/scripts/complete-todo" T.md "alpha" "verified in batch 12"
assert_ok $? "complete-todo exits 0 on a single match"
grep -q '^- \[x\] alpha task' T.md
assert_ok $? "matched item flipped to checked"
grep -q 'DONE.*verified in batch 12' T.md
assert_ok $? "DONE date + note appended"
grep -q '^- \[ \] beta task' T.md
assert_ok $? "other items untouched"
assert_eq "$(grep -c '^- ' T.md)" "2" "never deletes — checked items are history"
"$ROOT/scripts/complete-todo" T.md "alpha" "again" 2>/dev/null
assert_eq "$?" "1" "checked items never re-match: zero-match refused"
"$ROOT/scripts/append-todo" T.md "dup pair one"
"$ROOT/scripts/append-todo" T.md "dup pair two"
"$ROOT/scripts/complete-todo" T.md "dup pair" "ambiguous" 2>/dev/null
assert_eq "$?" "1" "multiple matches refused loudly"
assert_eq "$(grep -c '^- \[ \] dup pair' T.md)" "2" "file untouched on refusal"
"$ROOT/scripts/append-todo" T.md "weird * glob [item]"
"$ROOT/scripts/complete-todo" T.md "* glob [item]" "fixed-string match"
assert_ok $? "glob-shaped match text matches literally, never as a pattern"
grep -q '^- \[x\] weird \* glob \[item\]' T.md
assert_ok $? "the glob-shaped item is the one ticked"
n="note with \"quotes\" and \\backslash and :colons"
"$ROOT/scripts/append-todo" T.md "gamma item"
"$ROOT/scripts/complete-todo" T.md "gamma" "$n"
grep -qF "$n" T.md
assert_ok $? "hostile note text survives intact"
); rm -rf "$tmp"
tmp="$(mktemp -d)"; ( cd "$tmp"
printf -- '- [ ] crlf task\r\n- [ ] other item\r\n' > C.md
"$ROOT/scripts/complete-todo" C.md "crlf" "closed"
assert_ok $? "complete-todo handles a CRLF file"
grep '^\- \[x\]' C.md | grep -c "$(printf '\r')" | grep -q '^0$'
assert_ok $? "no stray carriage return embedded in the ticked line"
grep -q 'DONE.*closed' C.md
assert_ok $? "DONE suffix lands at end of the CRLF-origin line"
); rm -rf "$tmp"

# --- #13 anoti-dir: root-anchored resolution, no stray stores ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p proj/sub/inner
mkdir proj/.anoti
cd proj/sub/inner
root="$(cd ../.. && pwd -P)"
assert_eq "$("$ROOT/scripts/anoti-dir")" "$root/.anoti" "walk-up finds the root .anoti from a nested subdir"
cd "$tmp"; mkdir -p g/sub && cp "$ROOT/tests/fixtures/store_valid.yaml" g/GROUNDING.yaml
cd g/sub
groot="$(cd .. && pwd -P)"
assert_eq "$("$ROOT/scripts/anoti-dir")" "$groot/.anoti" "GROUNDING.yaml anchors resolution from a subdir"
"$ROOT/scripts/append-classification" s13 fast "subdir write test"
assert_ok $? "writer succeeds from a subdir of a governed project"
[ -f "$groot/.anoti/sessions/s13.yaml" ]
assert_ok $? "the write landed in the ROOT store"
[ ! -d .anoti ]
assert_ok $? "no stray state dir minted in the subdir"
cd "$tmp"; mkdir -p ov/sub
printf -- '---\nstate_dir: custom-state\n---\n' > /dev/null
mkdir -p ov/.claude && printf -- '---\nstate_dir: custom-state\n---\n' > ov/.claude/anoti.local.md
cd ov/sub
oroot="$(cd .. && pwd -P)"
assert_eq "$("$ROOT/scripts/anoti-dir")" "$oroot/custom-state" "state_dir override found by walk-up from a subdir"
cd "$tmp"; mkdir bare && cd bare
assert_eq "$("$ROOT/scripts/anoti-dir")" ".anoti" "unanchored plain call keeps the back-compat default"
"$ROOT/scripts/anoti-dir" --require >/dev/null 2>&1
assert_eq "$?" "1" "unanchored --require fails loudly"
"$ROOT/scripts/append-classification" s13 fast "should refuse" 2>/dev/null
assert_eq "$?" "1" "writer refuses when unanchored"
[ ! -d .anoti ]
assert_ok $? "refusal mints no stray store"
printf '%s' '{"id":"F1","goal":"g","status":"active"}' | "$ROOT/scripts/session-append" s13 frames 2>/dev/null
assert_eq "$?" "1" "session-append refuses when unanchored"
ANOTI_DIR="$tmp/explicit" "$ROOT/scripts/anoti-dir"
assert_eq "$(ANOTI_DIR="$tmp/explicit" "$ROOT/scripts/anoti-dir")" "$tmp/explicit" "ANOTI_DIR env still wins over everything"
out="$(printf '%s' '{"session_id":"cu","prompt":"fix the login bug"}' | "$ROOT/scripts/classify")"
[ -z "$out" ]
assert_ok $? "classify is silent where no workspace anchors (US-002)"
cd "$tmp"; cd g
out="$(printf '%s' '{"session_id":"cg","prompt":"fix the login bug"}' | "$ROOT/scripts/classify")"
printf '%s' "$out" | grep -q "anoti-attend"
assert_ok $? "classify still fires in a governed project"
touch "$tmp/.probe-AB"
if [ -e "$tmp/.probe-ab" ]; then
  cd "$tmp"; mkdir ci && cd ci
  cp "$ROOT/tests/fixtures/store_valid.yaml" grounding.yaml
  assert_eq "$("$ROOT/scripts/anoti-dir")" ".anoti" "lowercase grounding.yaml is not a marker (case-insensitive fs)"
else
  echo "  (skip: case-sensitive filesystem — marker case scenario cannot reproduce here)"
fi
); rm -rf "$tmp"
tmp="$(mktemp -d)"; ( cd "$tmp"
printf '{"session_id":"pc9"}' | "$ROOT/scripts/persist-session"
assert_ok $? "persist-session fails open when unanchored"
[ ! -d .anoti ]
assert_ok $? "persist-session mints no stray store (hook contract + #13)"
printf 'a: 1\n' > lone.yaml
"$ROOT/scripts/trust" lone.yaml >/dev/null 2>&1
assert_eq "$?" "1" "trust refuses a store outside any workspace"
[ ! -d .anoti ]
assert_ok $? "trust refusal mints no stray store"
err="$(printf '{"session_id":"ib9","tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' | "$ROOT/scripts/inhibit" 2>&1 >/dev/null)"
[ -z "$err" ]
assert_ok $? "inhibit deny in an unanchored dir leaks nothing to stderr"
mkdir -p ws/.claude && printf -- '---\nstate_dir: padded-state   \n---\n' > ws/.claude/anoti.local.md
cd ws
r="$("$ROOT/scripts/anoti-dir")"
[ "$r" = "$(pwd -P)/padded-state" ]
assert_ok $? "state_dir trailing whitespace stripped from the resolved path"
); rm -rf "$tmp"

# --- gap 2: organ-aware denial — the unblock path is true for every organ ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
out="$(printf '{"session_id":"g2","tool_name":"Edit","tool_input":{"file_path":"docs/ROADMAP.md"}}' | "$ROOT/scripts/inhibit")"
printf '%s' "$out" | grep -qi "direction skill" && printf '%s' "$out" | grep -qi "human-ratified draft"
assert_ok $? "direction-organ denial matches draft-for-ratification (no phantom helpers, no invented mode)"
out="$(printf '%s' "$out")"
printf '%s' "$out" | grep -q "write via the helpers"
assert_eq "$?" "1" "direction-organ denial does not promise helpers that do not exist"
out="$(printf '{"session_id":"g2","tool_name":"Edit","tool_input":{"file_path":"TODOS.md"}}' | "$ROOT/scripts/inhibit")"
printf '%s' "$out" | grep -q "write via the helpers"
assert_ok $? "memory-organ denial still routes via the helpers"
); rm -rf "$tmp"

# --- #14 resolve-question: the retire half of the open_questions contract ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
printf '%s' '{"id":"Q009","date":"2026-08-15","question":"is the retire half missing?","raised_by":"session","status":"open"}' | "$ROOT/scripts/append-question" s.yaml
printf '%s' '{"id":"Q010","date":"2026-08-15","question":"still open after sibling resolves?","raised_by":"session","status":"open"}' | "$ROOT/scripts/append-question" s.yaml
"$ROOT/scripts/resolve-question" s.yaml Q009 "answered upstream: helper shipped in 0.5.14 (#14)"
assert_ok $? "resolve-question exits 0 on an open match"
assert_eq "$(yq -r '.open_questions[] | select(.id=="Q009") | .status' s.yaml)" "answered" "status flips to answered (store convention)"
yq -r '.open_questions[] | select(.id=="Q009") | .resolution' s.yaml | grep -q "helper shipped"
assert_ok $? "dated resolution note recorded"
assert_eq "$(yq -r '.open_questions[] | select(.id=="Q010") | .status' s.yaml)" "open" "sibling question untouched"
assert_eq "$(yq -r '.open_questions | length' s.yaml)" "2" "never deletes — both entries remain"
"$ROOT/scripts/resolve-question" s.yaml Q009 "again" 2>/dev/null
assert_eq "$?" "1" "already-answered refused — no silent re-closure"
"$ROOT/scripts/resolve-question" s.yaml NOPE "x" 2>/dev/null
assert_eq "$?" "1" "unknown question id refused"
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1
assert_ok $? "store valid after resolution"
grep -qs "$(shasum -a 256 s.yaml | cut -d' ' -f1)" .anoti/trust
assert_ok $? "store re-trusted after resolution"
yq -i '.index = []' s.yaml
"$ROOT/scripts/resolve-question" s.yaml Q010 "second closure to test index regen"
assert_eq "$(yq -r '.index | length' s.yaml)" "$(yq -r '.records | length' s.yaml)" "resolve-question regenerates the index (mutation-proof)"
cp s.yaml GROUNDING.yaml && "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null 2>&1
out="$(printf '{"session_id":"q14"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -q "Q009"
assert_eq "$?" "1" "answered question no longer surfaces in the digest (end-to-end)"
); rm -rf "$tmp"

# --- anoti dispatcher: one entry point, action = script name ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
"$ROOT/scripts/anoti" append-classification d1 fast "via dispatcher"
assert_ok $? "dispatcher runs a helper by action name"
assert_eq "$(yq -r '.classifications | length' .anoti/sessions/d1.yaml)" "1" "the dispatched write landed"
printf '%s' '{"id":"F1","goal":"g","status":"active"}' | "$ROOT/scripts/anoti" session-append d1 frames
assert_ok $? "stdin passes through the dispatcher"
"$ROOT/scripts/anoti" set-episode d1 bogus 2>/dev/null
assert_eq "$?" "1" "exit codes pass through"
"$ROOT/scripts/anoti" no-such-action 2>/dev/null
assert_eq "$?" "1" "unknown action refused"
"$ROOT/scripts/anoti" ../etc/passwd 2>/dev/null
assert_eq "$?" "1" "path traversal refused"
"$ROOT/scripts/anoti" anoti 2>/dev/null
assert_eq "$?" "1" "self-dispatch refused"
"$ROOT/scripts/anoti" help | grep -q "append-record"
assert_ok $? "help lists the actions"
"$ROOT/scripts/anoti" help | grep "classify" | grep -qi "hook"
assert_ok $? "hook entry points labeled as hooks, not given false CLI usage"
"$ROOT/scripts/anoti" help | grep -q "trust \[--global\]"
assert_ok $? "usage lines are whole, not mid-sentence truncations"
grep -q '^exec ' "$ROOT/scripts/anoti"
assert_ok $? "dispatch uses exec — no double-fork (mechanism pin)"
); rm -rf "$tmp"

# --- #15 write serialization: concurrent writers never silently lose ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
lost=0
for i in 1 2 3 4 5 6 7 8 9 10; do
  "$ROOT/scripts/append-evidence" s.yaml D001 observation "A-$i" &
  "$ROOT/scripts/append-evidence" s.yaml D002 observation "B-$i" &
  wait
  grep -q "A-$i" s.yaml || lost=$((lost+1))
  grep -q "B-$i" s.yaml || lost=$((lost+1))
done
assert_eq "$lost" "0" "10 concurrent rounds, zero lost writes (#15 repro)"
[ ! -d s.yaml.lock ]
assert_ok $? "lock released after concurrent rounds"
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1
assert_ok $? "store valid after 20 concurrent writes"
printf 'bogus: [unclosed' > bad.yaml
"$ROOT/scripts/append-event" bad.yaml D001 test session "x" 2>/dev/null
[ ! -d bad.yaml.lock ]
assert_ok $? "lock released on failure paths (trap EXIT)"
mkdir s.yaml.lock && touch -t 202501010000 s.yaml.lock
"$ROOT/scripts/append-evidence" s.yaml D001 observation "after stale steal"
assert_ok $? "stale lock (>30s) stolen, write proceeds"
grep -q "after stale steal" s.yaml
assert_ok $? "the post-steal write landed"
grep -c '^' /dev/null >/dev/null
command ls s.yaml.tmp* 2>/dev/null | grep -q .
assert_eq "$?" "1" "no scratch files left behind"
grep -q 'tmp\.\$\$' "$ROOT/scripts/set-status" && grep -q "store-lock" "$ROOT/scripts/set-ratification"
assert_ok $? "unique scratch paths + shared lock lib in the mutators (mechanism pin)"
grep -qi "verify" "$ROOT/scripts/set-status" || grep -q 'got=' "$ROOT/scripts/set-status"
assert_ok $? "decision helpers read the field back after the write"
); rm -rf "$tmp"
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
i=1
while [ "$i" -le 12 ]; do
  printf '%s' "{\"id\":\"F$i\",\"goal\":\"g$i\",\"status\":\"active\"}" | "$ROOT/scripts/session-append" cs frames &
  i=$((i+1))
done
wait
assert_eq "$(yq -r '.frames | length' .anoti/sessions/cs.yaml)" "12" "12 concurrent session-appends, zero lost (#15 session path)"
printf '%s' '{"id":"c1","type":"claim","statement":"x"}' | "$ROOT/scripts/session-append" cs candidates
printf '%s' '{"id":"c2","type":"claim","statement":"y"}' | "$ROOT/scripts/session-append" cs candidates
( "$ROOT/scripts/session-consume" cs candidates & printf '%s' '{"id":"c3","type":"claim","statement":"z"}' | "$ROOT/scripts/session-append" cs candidates & wait )
assert_eq "$(yq -r '.candidates | length' .anoti/sessions/cs.yaml)" "3" "consume racing append loses nothing (default branch locked)"
mkdir -p .anoti/sessions 2>/dev/null
mkdir .anoti/sessions/cs.yaml.lock 2>/dev/null && touch -t 202501010000 .anoti/sessions/cs.yaml.lock
j=1
while [ "$j" -le 8 ]; do
  printf '%s' "{\"id\":\"S$j\",\"statement\":\"h$j\"}" | "$ROOT/scripts/session-append" cs hypotheses &
  j=$((j+1))
done
wait
assert_eq "$(yq -r '.hypotheses | length' .anoti/sessions/cs.yaml)" "8" "8 writers through a stale-lock steal, zero lost (atomic-rename steal)"
); rm -rf "$tmp"

# --- TODO line-41 closure: unreadable state is loud on EVERY organ branch ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti/sessions
printf 'episode: "unterminated\n' > .anoti/sessions/bad.yaml
err="$(printf '{"session_id":"bad","tool_name":"Edit","tool_input":{"file_path":"docs/ROADMAP.md"}}' | "$ROOT/scripts/inhibit" 2>&1 >/dev/null)"
printf '%s' "$err" | grep -q "session state unreadable"
assert_ok $? "direction-organ branch warns on unreadable state (0.5.12 regression closed)"
err="$(printf '%s' '{"id":"F2","amends":"F1","goal":"g","status":"active"}' | "$ROOT/scripts/session-append" bad frames 2>&1 >/dev/null)"
printf '%s' "$err" | grep -q "unreadable"
assert_ok $? "amends check names unreadable state, never a misleading data miss"
); rm -rf "$tmp"

# --- TODO: append-relationship — refines/contradicts get a mechanical path ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
"$ROOT/scripts/append-relationship" s.yaml D002 refines D001 "narrows the pipeline claim to the attention stage"
assert_ok $? "append-relationship exits 0"
assert_eq "$(yq -r '.records[] | select(.id=="D002") | .relationships[-1].type' s.yaml)" "refines" "relationship type recorded"
assert_eq "$(yq -r '.records[] | select(.id=="D002") | .relationships[-1].target' s.yaml)" "D001" "relationship target recorded"
yq -r '.records[] | select(.id=="D002") | .events[-1].note' s.yaml | grep -q "narrows"
assert_ok $? "audit event carries the note"
"$ROOT/scripts/append-relationship" s.yaml D002 bogus D001 "x" 2>/dev/null
assert_eq "$?" "1" "unknown relationship type rejected"
"$ROOT/scripts/append-relationship" s.yaml D002 refines NOPE "x" 2>/dev/null
assert_eq "$?" "1" "unknown target rejected (exact match)"
"$ROOT/scripts/append-relationship" s.yaml NOPE refines D001 "x" 2>/dev/null
assert_eq "$?" "1" "unknown source rejected"
"$ROOT/scripts/append-relationship" s.yaml D001 refines D001 "x" 2>/dev/null
assert_eq "$?" "1" "self-reference rejected"
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1
assert_ok $? "store valid after relationship append"
grep -q "store-lock" "$ROOT/scripts/append-relationship"
assert_ok $? "relationship writer carries the lock (mechanism pin)"
); rm -rf "$tmp"
tmp="$(mktemp -d)"; ( cd "$tmp"
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
yq -i '.records[1].relationships += [{"type":"refines","target":"GHOST"}]' s.yaml
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1
assert_eq "$?" "1" "validator refuses a dangling relationship target"
yq -i '.records[1].relationships = [{"type":"bogus","target":"D001"}]' s.yaml
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1
assert_eq "$?" "1" "validator refuses an unknown relationship type"
yq -i '.records[1].relationships = [{"type":"refines","target":"D001","note":"legacy shape, no date"}]' s.yaml
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1
assert_ok $? "legacy relationship shape (no date, inline note) stays valid"
); rm -rf "$tmp"

# --- TODO: reopen-question — the lifecycle loop closes ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
printf '%s' '{"id":"Q101","date":"2026-08-18","question":"scale-dependent?","raised_by":"session","status":"open"}' | "$ROOT/scripts/append-question" s.yaml
"$ROOT/scripts/resolve-question" s.yaml Q101 "ceilinged at small scale"
"$ROOT/scripts/reopen-question" s.yaml Q101 "scaled comprehension test now exists — the named reopen condition"
assert_ok $? "reopen-question exits 0 on an answered entry"
assert_eq "$(yq -r '.open_questions[] | select(.id=="Q101") | .status' s.yaml)" "open" "status flips back to open"
yq -r '.open_questions[] | select(.id=="Q101") | .reopened' s.yaml | grep -q "reopen condition"
assert_ok $? "dated reopen note recorded"
yq -r '.open_questions[] | select(.id=="Q101") | .resolution' s.yaml | grep -q "ceilinged"
assert_ok $? "prior resolution kept as history — never deleted"
"$ROOT/scripts/reopen-question" s.yaml Q101 "again" 2>/dev/null
assert_eq "$?" "1" "already-open refused"
"$ROOT/scripts/reopen-question" s.yaml NOPE "x" 2>/dev/null
assert_eq "$?" "1" "unknown id refused"
"$ROOT/scripts/validate-workspace" s.yaml >/dev/null 2>&1
assert_ok $? "store valid after reopen"
grep -q "store-lock" "$ROOT/scripts/reopen-question"
assert_ok $? "reopen carries the lock (mechanism pin)"
); rm -rf "$tmp"
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
cp "$ROOT/tests/fixtures/store_valid.yaml" s.yaml
printf '%s' '{"id":"QR1","date":"2026-08-18","question":"race target","raised_by":"session","status":"open"}' | "$ROOT/scripts/append-question" s.yaml
"$ROOT/scripts/resolve-question" s.yaml QR1 "first closure"
ok=0
"$ROOT/scripts/reopen-question" s.yaml QR1 "racer A" 2>/dev/null && ok=$((ok+1)) &
p1=$!
"$ROOT/scripts/reopen-question" s.yaml QR1 "racer B" 2>/dev/null && ok=$((ok+1)) &
p2=$!
wait "$p1"; r1=$?
wait "$p2"; r2=$?
[ $((r1 + r2)) -eq 1 ]
assert_ok $? "concurrent reopens: exactly one wins, one refuses (check under lock)"
assert_eq "$(yq -r '.open_questions[] | select(.id=="QR1") | .status' s.yaml)" "open" "final state deterministic"
); rm -rf "$tmp"

# --- TODO: append-pending — the single human-absent surface gets its contract ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
"$ROOT/scripts/append-pending" "queued feedback draft: .anoti/feedback/x.md — propose when a human is present"
assert_ok $? "append-pending exits 0"
grep -q '^- \[ \] .*queued feedback draft' .anoti/pending.md
assert_ok $? "pending line is a dated checkbox item"
"$ROOT/scripts/append-pending" "escalation: merge decision awaited"
assert_eq "$(grep -c '^- \[ \]' .anoti/pending.md)" "2" "entries accumulate"
"$ROOT/scripts/complete-todo" .anoti/pending.md "merge decision" "human ruled: merge (session xyz)"
assert_ok $? "resolve-pending IS complete-todo on pending.md — one mechanism (D024)"
assert_eq "$(grep -c '^- \[ \]' .anoti/pending.md)" "1" "resolved entry ticked, history kept"
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null 2>&1
out="$(printf '{"session_id":"pp"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -q "pending human-absent"
assert_ok $? "digest surfaces pending while unresolved items exist"
printf '%s' "$out" | grep -q "1 unresolved"
assert_ok $? "digest counts unresolved, not total"
"$ROOT/scripts/complete-todo" .anoti/pending.md "feedback draft" "proposed and filed as issue"
out="$(printf '{"session_id":"pp"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext // ""')"
printf '%s' "$out" | grep -q "pending human-absent"
assert_eq "$?" "1" "all resolved -> pending line gone"
); rm -rf "$tmp"
grep -q "store-lock" "$ROOT/scripts/append-pending"
assert_ok $? "append-pending carries the lock (mechanism pin)"
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
"$ROOT/scripts/append-pending" "line one
line two smuggled"
assert_eq "$(grep -c '^' .anoti/pending.md)" "1" "embedded newlines flattened — no orphan continuation lines"
); rm -rf "$tmp"
