#!/bin/bash
# review-debt ledger (spec docs/specs/2026-08-19-review-debt-design.md §6)
RD="$ROOT/scripts/review-debt"
rd_mkfx() { # $1=dir -- trusted project store + git repo on main with one commit + docs/specs
  mkdir -p "$1/.anoti" "$1/docs/specs" "$1/docs/plans"
  cp "$ROOT/tests/fixtures/store_valid.yaml" "$1/GROUNDING.yaml"
  ( cd "$1" && git init -q -b main . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init && "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null )
}

# --- 1. add / list / close / defer (§4.2) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
rd_mkfx "$tmp"
out="$("$RD" list)"
assert_eq "$out" "review-debt: no review-debt.tsv yet (no review debt)" "list: missing ledger message, exit 0"
id="$("$RD" add s1 "batch: feedback helper")"; assert_eq "$id" "R1" "add allocates R1"
id="$("$RD" add s1 "batch: feedback helper")"; assert_eq "$id" "R1" "add of an already-open subject returns the existing id"
c="$(grep -c . .anoti/review-debt.tsv)"; assert_eq "$c" "1" "duplicate add wrote no second row"
id="$("$RD" add s2 "docs/specs/us-9-x.md")"; assert_eq "$id" "R2" "add allocates R2"
"$RD" list | grep -qE $'^R2\t[0-9-]+\ts2\tdocs/specs/us-9-x.md\topen\t[0-9-]+\t$'; assert_ok $? "list shows the 7-column row (open, empty note)"
"$RD" defer R2 "" 2>/dev/null; assert_eq "$?" "1" "defer refuses an empty reason"
grep -q $'^R2\t.*\topen\t' .anoti/review-debt.tsv; assert_ok $? "refused defer left the row open"
id="$("$RD" defer R2 "reviewer unavailable until the 2026-08-20 audit")"; assert_eq "$id" "R2" "defer with a reason exits 0 and prints the id"
grep -q $'^R2\t.*\tdeferred\t[0-9-]*\treviewer unavailable until the 2026-08-20 audit$' .anoti/review-debt.tsv; assert_ok $? "defer wrote status + reason"
id="$("$RD" add s3 "docs/specs/us-9-x.md")"; assert_eq "$id" "R2" "add of a DEFERRED subject returns the existing id (no duplicate debt)"
"$RD" close R1 "skeptic: COMPLIANT, two minors fixed" >/dev/null; assert_ok $? "close exits 0"
grep -q $'^R1\t.*\tclosed\t[0-9-]*\tskeptic: COMPLIANT, two minors fixed$' .anoti/review-debt.tsv; assert_ok $? "close wrote status + note"
"$RD" close R1 "again" 2>/dev/null; assert_eq "$?" "1" "close refuses an already-closed row"
"$RD" close R9 "x" 2>/dev/null; assert_eq "$?" "1" "close refuses an unknown id"
"$RD" defer R1 "x" 2>/dev/null; assert_eq "$?" "1" "defer refuses a closed row"
id="$("$RD" add s1 "batch: feedback helper")"; assert_eq "$id" "R3" "a closed subject can be re-opened as a NEW row (ids never reused)"
c="$(grep -c $'\treview-debt\t' .anoti/telemetry.log)"; assert_eq "$c" "5" "telemetry: one row per add/defer/close (5 writes)"
grep -q $'\ts1\treview-debt\tadd\tR1 batch: feedback helper$' .anoti/telemetry.log; assert_ok $? "telemetry add row carries the caller session, id and subject"
grep -q $'\treview-debt\tdefer\tR2 ' .anoti/telemetry.log && grep -q $'\treview-debt\tclose\tR1 ' .anoti/telemetry.log; assert_ok $? "telemetry verbs are the subcommands (close/defer), not the statuses"
"$RD" add 'C:\temp\new' 'C:\temp\new' >/dev/null; id="$("$RD" add 'C:\temp\new' 'C:\temp\new')"
c="$(grep -c $'\tC:\\\\temp\\\\new\topen' .anoti/review-debt.tsv)"; assert_eq "$c" "1" "backslash subjects dedupe (ENVIRON, not awk -v)"
"$RD" add "$(printf 's\t1')" "tabbed sid" 2>/dev/null; assert_eq "$?" "1" "post-write shape check refuses a row that would break the 7-column shape (tab in sid)"
c="$(grep -c 'tabbed sid' .anoti/review-debt.tsv)"; assert_eq "$c" "0" "…and the ledger is untouched"
"$RD" add s1 "a
b	c" >/dev/null
grep -q $'\ta b c\topen' .anoti/review-debt.tsv; assert_ok $? "newlines/tabs in a subject are flattened to spaces"
# shape check: a corrupt ledger is refused and untouched
cp .anoti/review-debt.tsv "$tmp/before"; printf 'garbage line\n' >> .anoti/review-debt.tsv; cp .anoti/review-debt.tsv "$tmp/corrupt"
"$RD" add s1 "new" 2>/dev/null; assert_eq "$?" "1" "add refuses to write through a malformed ledger"
cmp -s .anoti/review-debt.tsv "$tmp/corrupt"; assert_ok $? "refused write left the malformed ledger byte-identical"
"$RD" list >/dev/null 2>&1; assert_eq "$?" "1" "list reports a malformed ledger (exit 1)"
cp "$tmp/before" .anoti/review-debt.tsv
und="$(mktemp -d)"; ( cd "$und" && "$RD" add s1 "x" 2>/dev/null ); assert_eq "$?" "1" "add refuses outside a governed workspace (anchoring)"; rm -rf "$und"
); rm -rf "$tmp"

# --- 1b. fresh clone: no state dir yet (reviewer: lock_store spun ~60s) + anoti-dir --root ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
t0="$(date +%s)"; id="$(timeout 8 "$RD" add s1 "fresh" 2>/dev/null || "$RD" add s1 "fresh")"; t1="$(date +%s)"
assert_eq "$id" "R1" "add creates the state dir on a fresh clone instead of spinning"
[ $((t1 - t0)) -lt 5 ]; assert_ok $? "…and returns promptly"
assert_eq "$("$ROOT/scripts/anoti-dir" --root)" "$(pwd -P)" "anoti-dir --root prints the marker dir"
mkdir -p sub/deeper; assert_eq "$(cd sub/deeper && "$ROOT/scripts/anoti-dir" --root)" "$(pwd -P)" "anoti-dir --root walks up from a subdir"
mkdir -p .claude .state/anoti; printf -- '---\nstate_dir: .state/anoti\n---\n' > .claude/anoti.local.md
assert_eq "$("$ROOT/scripts/anoti-dir" --root)" "$(pwd -P)" "anoti-dir --root with a configured state_dir is still the marker dir"
assert_eq "$("$ROOT/scripts/anoti-dir")" "$(pwd -P)/.state/anoti" "anoti-dir (no flag) unchanged: the configured state dir"
assert_eq "$(ANOTI_DIR=/elsewhere "$ROOT/scripts/anoti-dir" --root)" "$(pwd -P)" "anoti-dir --root ignores ANOTI_DIR and walks up"
und="$(mktemp -d)"; ( cd "$und" && "$ROOT/scripts/anoti-dir" --root --require >/dev/null 2>&1 ); assert_eq "$?" "1" "anoti-dir --root --require fails loudly when unanchored"; rm -rf "$und"
); rm -rf "$tmp"

# --- 2. observe: mechanical add on spec filing (§4.3) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
rd_mkfx "$tmp"
obs() { printf '{"session_id":"%s","hook_event_name":"PostToolUse","tool_name":"%s","tool_input":{"file_path":"%s","content":"x"},"tool_response":{}}' "$1" "$2" "$3" | "$RD" observe; }
obs s1 Write "$tmp/docs/specs/us-9-x.md"; assert_ok $? "observe exits 0"
grep -q $'^R1\t[0-9-]*\ts1\tdocs/specs/us-9-x.md\topen' .anoti/review-debt.tsv; assert_ok $? "Write under docs/specs opens a row with the spec path as subject"
obs s1 Write "$tmp/docs/specs/us-9-x.md"
c="$(grep -c . .anoti/review-debt.tsv)"; assert_eq "$c" "1" "re-Write of an open spec is a no-op"
obs s1 Edit "$tmp/docs/specs/us-8-y.md"; obs s1 Write "$tmp/docs/plans/p.md"; obs s1 Write "$tmp/docs/specs/notes.txt"; obs s1 Write "$tmp/docs/specs/sub/deep.md"
c="$(grep -c . .anoti/review-debt.tsv)"; assert_eq "$c" "1" "Edit on a spec, Write elsewhere, non-.md, and nested dirs do not open rows"
out="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s/docs/specs/q.md"}}' "$tmp" | "$RD" observe)"; assert_eq "$out" "" "observe is silent (no stdout)"
grep -q $'review-debt\tobserve\tR1 docs/specs/us-9-x.md$' .anoti/telemetry.log; assert_ok $? "observe's add is telemetered with the verb observe"
# custom spec_dir honoured; resolved from the project root, not the hook's cwd
mkdir -p .claude specs/design; printf -- '---\nspec_dir: specs/design\n---\n' > .claude/anoti.local.md
( cd docs && obs s1 Write "$tmp/specs/design/d1.md" )
grep -q $'\tspecs/design/d1.md\topen' .anoti/review-debt.tsv; assert_ok $? "custom spec_dir honoured, resolved from the project root while cwd is a subdir"
obs s1 Write "$tmp/docs/specs/now-not-spec.md"
c="$(grep -c 'now-not-spec' .anoti/review-debt.tsv)"; assert_eq "$c" "0" "with a custom spec_dir the default dir no longer counts"
( cd "$tmp/home" && printf '{"tool_name":"Write","tool_input":{"file_path":"%s/home/docs/specs/a.md"}}' "$tmp" | "$RD" observe ); assert_ok $? "observe outside a governed dir exits 0 silently"
printf -- '---\nspec_dir: ./docs/specs/\n---\n' > .claude/anoti.local.md
obs s1 Write "$tmp/docs/specs/dotslash.md"
grep -q $'\tdocs/specs/dotslash.md\topen' .anoti/review-debt.tsv; assert_ok $? "spec_dir with ./ prefix and trailing / normalises the subject"
); rm -rf "$tmp"

# --- 2b. observe in a state_dir-configured project (reviewer finding 1: dirname of the state dir is not the root) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME" docs/specs .claude .state/anoti
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
printf -- '---\nstate_dir: .state/anoti\n---\n' > .claude/anoti.local.md
printf '{"session_id":"s1","tool_name":"Write","tool_input":{"file_path":"%s/docs/specs/x.md"}}' "$tmp" | "$RD" observe
grep -q $'\tdocs/specs/x.md\topen' .state/anoti/review-debt.tsv; assert_ok $? "observe fires with a configured state_dir (root from anoti-dir --root)"
abs="$tmp/.abs-state"; printf -- '---\nstate_dir: %s\n---\n' "$abs" > .claude/anoti.local.md
printf '{"session_id":"s1","tool_name":"Write","tool_input":{"file_path":"%s/docs/specs/y.md"}}' "$tmp" | "$RD" observe
grep -q $'\tdocs/specs/y.md\topen' "$abs/review-debt.tsv"; assert_ok $? "observe fires with an ABSOLUTE state_dir"
rm .claude/anoti.local.md; mkdir -p .envdir
ANOTI_DIR="$tmp/.envdir" bash -c 'printf "{\"session_id\":\"s1\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"%s/docs/specs/z.md\"}}" "$1" | "$2" observe' _ "$tmp" "$RD"
grep -q $'\tdocs/specs/z.md\topen' .envdir/review-debt.tsv; assert_ok $? "observe fires under ANOTI_DIR"
); rm -rf "$tmp"

# --- 3. Stop gate: block once while this session's debt is open (§4.4) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
rd_mkfx "$tmp"
G="$ROOT/scripts/consolidation-gate"
out="$(printf '{"session_id":"s1"}' | "$G")"; assert_eq "$out" "" "no ledger: Stop gate silent"
"$RD" add s1 "batch: x" >/dev/null; "$RD" add s9 "other session's work" >/dev/null
out="$(printf '{"session_id":"s1"}' | "$G")"
assert_eq "$(printf '%s' "$out" | jq -r .decision)" "block" "open row from this session: Stop blocks"
printf '%s' "$out" | jq -r .reason | grep -q "R1 batch: x"; assert_ok $? "block reason names the owed id + subject"
printf '%s' "$out" | jq -r .reason | grep -q "other session"; assert_eq "$?" "1" "block reason does NOT name another session's row"
printf '%s' "$out" | jq -r .reason | grep -q "review-debt close" && printf '%s' "$out" | jq -r .reason | grep -q "review-debt defer"; assert_ok $? "block reason names both exits (close, defer)"
[ -f .anoti/sessions/s1.review-debt-blocked ]; assert_ok $? "block-once marker written"
out="$(printf '{"session_id":"s1"}' | "$G")"; assert_eq "$out" "" "second Stop in the same session: no second block"
grep -q $'\ts1\treview-debt\tblock\tR1$' .anoti/telemetry.log; assert_ok $? "telemetry: review-debt block <ids>"
out="$(printf '{"session_id":"s9"}' | "$G")"; assert_eq "$(printf '%s' "$out" | jq -r .decision)" "block" "the other session blocks on ITS row"
printf '%s' "$out" | jq -r .reason | grep -q "R2 other session's work"; assert_ok $? "…naming only its own row"
out="$(printf '{"session_id":"s2"}' | "$G")"; assert_eq "$out" "" "a session with no rows is never blocked by others' debt"
"$RD" defer R2 "deferred for the audit" >/dev/null; rm -f .anoti/sessions/s9.review-debt-blocked
out="$(printf '{"session_id":"s9"}' | "$G")"; assert_eq "$out" "" "a deferred row never blocks (decision recorded)"
out="$(printf '{"session_id":"s1","stop_hook_active":true}' | "$G")"; assert_eq "$out" "" "stop_hook_active: no block"
# consolidation block takes precedence; debt block then fires at a later stop
rm -f .anoti/sessions/s1.review-debt-blocked
"$ROOT/scripts/append-classification" s1 fast "t" >/dev/null; "$ROOT/scripts/set-episode" s1 candidate-detected >/dev/null
out="$(printf '{"session_id":"s1"}' | "$G")"
printf '%s' "$out" | jq -r .reason | grep -q "memory candidates await consolidation"; assert_ok $? "consolidation block takes precedence over the debt block"
[ -f .anoti/sessions/s1.review-debt-blocked ]; assert_eq "$?" "1" "…and the debt marker is NOT consumed by the consolidation block"
out="$(printf '{"session_id":"s1"}' | "$G")"
printf '%s' "$out" | jq -r .reason | grep -q "R1 batch: x"; assert_ok $? "next Stop: the debt block fires"
printf 'garbage\n' > .anoti/review-debt.tsv; rm -f .anoti/sessions/s1.review-debt-blocked
out="$(printf '{"session_id":"s1"}' | "$G")"; assert_eq "$out" "" "malformed ledger: Stop gate fails open"
printf 'R1\t2026-08-19\ts1\tvalid row\topen\t2026-08-19\t\nstray line\n' > .anoti/review-debt.tsv
out="$(printf '{"session_id":"s1"}' | "$G")"; assert_eq "$out" "" "PARTIALLY malformed ledger: whole file treated as empty (helpers refuse it too)"
); rm -rf "$tmp"

# --- 4. inhibit: ask at integration while debt is open (§4.5) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
rd_mkfx "$tmp"
I="$ROOT/scripts/inhibit"
inh() { printf '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" | "$I"; }
out="$(inh 'git merge feat')"; assert_eq "$out" "" "merge on main with no ledger: no decision (today's behaviour)"
"$RD" add s1 "batch: feedback helper" >/dev/null; "$RD" add s1 "docs/specs/us-9-x.md" >/dev/null
out="$(inh 'git merge feat')"
assert_eq "$(printf '%s' "$out" | jq -r .hookSpecificOutput.permissionDecision)" "ask" "merge on main with open debt: ask"
printf '%s' "$out" | jq -r .hookSpecificOutput.permissionDecisionReason | grep -q "2 adversarial review(s) owed: R1 batch: feedback helper; R2 docs/specs/us-9-x.md — review"; assert_ok $? "ask reason names count + every owed id/subject"
out="$(inh 'gh pr merge 12 --squash')"; assert_eq "$(printf '%s' "$out" | jq -r .hookSpecificOutput.permissionDecision)" "ask" "gh pr merge on main with open debt: ask"
out="$(inh 'git push origin feat')"
printf '%s' "$out" | jq -r .hookSpecificOutput.permissionDecisionReason | grep -q "adversarial review(s) owed"; assert_ok $? "git push with open debt: the debt reason (not the generic ask text)"
git checkout -q -b feat
out="$(inh 'git merge main')"; assert_eq "$out" "" "merge on a feature branch: no debt ask"
git checkout -q main
"$RD" defer R1 "audit first" >/dev/null; "$RD" close R2 "reviewed" >/dev/null
out="$(inh 'git merge feat')"; assert_eq "$out" "" "deferred/closed only: no debt ask on merge"
out="$(inh 'git push origin feat')"
printf '%s' "$out" | jq -r .hookSpecificOutput.permissionDecisionReason | grep -q "consequential action"; assert_ok $? "deferred/closed only: git push falls through to the generic ask row"
out="$(inh 'git log --oneline')"; assert_eq "$out" "" "non-integration git with open ledger file: no decision"
"$RD" add s1 "again" >/dev/null; git checkout -q feat
out="$(inh 'gh pr merge 12 --squash')"; assert_eq "$(printf '%s' "$out" | jq -r .hookSpecificOutput.permissionDecision)" "ask" "gh pr merge from a FEATURE branch asks (a PR merges into its base wherever you stand)"
git checkout -q main
printf 'R1\t2026-08-19\ts1\tvalid row\topen\t2026-08-19\t\nstray line\n' > .anoti/review-debt.tsv
out="$(inh 'git merge feat')"; assert_eq "$out" "" "partially malformed ledger: no debt ask (fail-open, whole file)"
); rm -rf "$tmp"

# --- 5. digest line (§4.7) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
rd_mkfx "$tmp"
out="$("$ROOT/scripts/digest")"; printf '%s' "$out" | grep -q "review debt"; assert_eq "$?" "1" "digest: silent with no ledger"
"$RD" add s1 "a" >/dev/null; "$RD" add s1 "b" >/dev/null; "$RD" add s1 "c" >/dev/null
"$RD" defer R2 "later" >/dev/null; "$RD" close R3 "done" >/dev/null
out="$("$ROOT/scripts/digest")"
printf '%s' "$out" | grep -qE -- "- review debt: 1 open, 1 deferred — oldest [0-9]{4}-[0-9]{2}-[0-9]{2} \(anoti review-debt list\)"; assert_ok $? "digest counts open + deferred (closed excluded) with the oldest date"
"$RD" close R1 "done" >/dev/null; "$RD" close R2 "done" >/dev/null
out="$("$ROOT/scripts/digest")"; printf '%s' "$out" | grep -q "review debt"; assert_eq "$?" "1" "digest: silent once every row is closed"
printf 'garbage\n' > .anoti/review-debt.tsv
out="$("$ROOT/scripts/digest")"; printf '%s' "$out" | grep -q "review debt"; assert_eq "$?" "1" "digest: malformed ledger is silent (fail-open)"
printf 'R1\t2026-08-19\ts1\tvalid row\topen\t2026-08-19\t\nstray line\n' > .anoti/review-debt.tsv
out="$("$ROOT/scripts/digest")"; printf '%s' "$out" | grep -q "review debt"; assert_eq "$?" "1" "digest: partially malformed ledger is silent (whole file)"
); rm -rf "$tmp"

# --- 6. wiring + orientation currency (§4.3, §4.6, D025) ---
h="$ROOT/hooks/hooks.json"
assert_eq "$(jq -r '.hooks.PostToolUse[1].matcher' "$h")" "Write" "review-debt observe wired on PostToolUse matcher Write"
assert_eq "$(jq -r '.hooks.PostToolUse[1].hooks[0].command' "$h")" "\${CLAUDE_PLUGIN_ROOT}/scripts/review-debt observe" "PostToolUse[1] runs review-debt observe"
assert_eq "$(jq -r '.hooks.PostToolUse[1].hooks[0].timeout' "$h")" "5" "review-debt observe timeout 5s"
assert_eq "$(jq -r '.hooks.PostToolUse[0].hooks[0].command' "$h")" "\${CLAUDE_PLUGIN_ROOT}/scripts/presence" "presence wiring unchanged at PostToolUse[0]"
"$ROOT/scripts/anoti" help | grep -q '^  review-debt '; assert_ok $? "anoti help lists review-debt"
grep -qF '`scripts/review-debt` (add/list/close/defer)' "$ROOT/docs/SKILL-MAP.md"; assert_ok $? "SKILL-MAP gains a scripts/review-debt entry-point row"
fb="$(grep -nF '`scripts/feedback` (list/clear)' "$ROOT/docs/SKILL-MAP.md" | head -1 | cut -d: -f1)"
rb="$(grep -nF '`scripts/review-debt` (add/list/close/defer)' "$ROOT/docs/SKILL-MAP.md" | head -1 | cut -d: -f1)"
[ -n "$fb" ] && [ -n "$rb" ] && [ "$rb" -eq $((fb + 1)) ]; assert_ok $? "review-debt row sits directly after the feedback row"
grep -q 'anoti review-debt list' "$ROOT/skills/demo/SKILL.md"; assert_ok $? "demo routing table teaches review-debt (D025)"
grep -q 'review-debt add <session-id>' "$ROOT/skills/policy-adversarial-handoff/SKILL.md" && grep -q 'review-debt close <id>' "$ROOT/skills/policy-adversarial-handoff/SKILL.md"; assert_ok $? "handoff policy opens and closes the row"
grep -q 'review-debt observe' "$ROOT/skills/spec/SKILL.md"; assert_ok $? "spec skill names the mechanical add"
grep -q 'review-debt row' "$ROOT/skills/deliberate/SKILL.md"; assert_ok $? "deliberate step 8 names the row"
grep -q 'anoti review-debt list' "$ROOT/skills/policy-retrospect/SKILL.md"; assert_ok $? "retrospect names open/deferred debt"
grep -q 'review-debt' "$ROOT/README.md"; assert_ok $? "README one-liner"
grep -q 'review-debt-design.md' "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"; assert_ok $? "longitudinal spec carries the dated telemetry-only amendment"
