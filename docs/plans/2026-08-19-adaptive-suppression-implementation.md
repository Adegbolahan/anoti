# Adaptive Suppression — Implementation Plan

**Spec:** docs/specs/2026-08-19-adaptive-suppression-design.md

## Goal

`presence-feedback.tsv` (project-level, `<state-dir>`-anchored) lets the
presence hook learn which `(record, trigger)` pairs the retrospective has
named irrelevant three times within 30 days and stop injecting exactly
those pairs, while every other trigger on the same record keeps firing.
`scripts/feedback mark/list/clear` is the single reader/writer;
`scripts/mark-retrospect` grows an additive, backward-compatible grammar
to name pairs; `scripts/presence` filters its recall duty through the new
suppression set, emits `suppressed` telemetry, warns once per session on
a corrupt feedback file (persisted across process invocations, not just
in-memory), and purges stale `recall_cache` entries on `clear` and on
natural 30-day TTL expiry so reversibility is real, not just a config
flag; `scripts/retrieve` gains a digest line gated exactly like the
existing recall-coverage line. The longitudinal spec's Q006 gate is
reworded to require adaptive suppression specifically (not just "the
mechanical measures") plus two audited weeks, and gains its own
pre-registered KEEP/telemetry-only/REVERT criterion. `bash tests/run.sh`
is green, `shellcheck -S warning` is clean on every changed script,
release 0.5.26 ships after a reviewer pass over the whole diff and a
human integration gate.

## Architecture

Two builder hats touch disjoint files and run **concurrently in isolated
git worktrees** (not the shared working copy jit-recall's own plan used —
see Spawn arithmetic): **backend** owns every script and the one new test
file plus test-file extensions (`scripts/store-resolve`,
`scripts/feedback`, `scripts/mark-retrospect`, `scripts/presence`,
`scripts/retrieve`, `tests/test_feedback.sh`, `tests/test_helpers.sh`);
**technical-writer** owns every exact-wording edit (policy, consolidate,
demo, skill-map, longitudinal spec) plus a drafted-not-applied CHANGELOG
paragraph. A single **reviewer** spawn reviews both diffs together,
mirroring the spec's own routing (spec:1283-1305). Both builder worktrees
are **kept alive — not merged, not removed — until the reviewer returns a
COMPLIANT verdict**, per the ratified lesson this exact scenario already
cost once (`LESSONS-LEARNT.md:71`: "a subagent whose worktree was removed
at integration cannot be resumed — the fix round had to go to a fresh
spawn that re-read everything at full cost"). Tech: POSIX-ish `sh`/`bash`
(existing scripts are `#!/bin/bash`), `yq` (mikefarah/yq v4,
`strenv`-dependent), `jq`, `awk` (multi-dim `in`, `ENVIRON`, `tolower`,
`substr`, `index` — the same primitive family `match_triggers` already
proved portable, spec:130-141), hermetic `mktemp -d` + `HOME`-override
tests. No new runtime dependency.

## Global constraints (verbatim from the spec, binding every task)

- Fail open, ≤5s, no new hook — extends the existing `scripts/presence`
  (`hooks/hooks.json:76,88`, timeout `5`, unchanged) and `scripts/retrieve`
  (SessionStart, unchanged registration). A missing/corrupt feedback file
  degrades to "no suppression," never a hook error (spec:109-114, §5).
- Silent by default (US-002) — the digest line emits only when `N > 0`;
  a firing with nothing suppressed emits nothing new (spec:115-116).
- Every write goes through a helper with the established contract: lock
  (`scripts/store-lock`), write-to-tmp/validate-shape/preserve-mode/
  atomic-mv (the exact sequence `scripts/append-trigger`/
  `scripts/remove-trigger` already establish), exact-string comparison for
  every id/trigger match — never a shell `case` pattern or `yq ==` against
  freeform text (G002, cited by id only per the spec's own line-drift
  finding, spec:117-141).
- bash 3.2 compatible; no `IFS=<tab> read`; shellcheck clean. Every TSV
  row this spec introduces is read with `cut -f` or `awk -F'\t'`, never
  `IFS=$'\t' read` (spec:142-146).
- One component, one responsibility. `match_triggers` itself
  (`scripts/store-resolve:32-57`) is **not modified** — all new
  per-trigger detail is a new sibling function (`match_trigger_pairs`).
  All suppression _policy_ (threshold, TTL, filtering, telemetry) lives in
  `scripts/presence` only — `scripts/recall` is unmodified and unaffected
  (spec:147-167).
- Exact values, no placeholders: threshold **3** (default, overridable via
  `feedback_threshold:` in `.claude/anoti.local.md`), TTL **30 days**,
  KEEP bar **≥15 percentage points**, REVERT bar **≥10 points lower**
  (spec:168-170, §4.9).

## File structure

| File                                                                            | New/Ext                        | Responsibility                                                                                                                 |
| ------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| `scripts/store-resolve`                                                         | extended                       | `+match_trigger_pairs` (per-pair, unaggregated matcher), `+feedback_shape_ok` (shared corrupt/valid predicate)                 |
| `scripts/feedback`                                                              | new, executable                | `mark`/`list`/`clear` — sole reader/writer of `presence-feedback.tsv`; `clear` purges stale `recall_cache` entries             |
| `scripts/mark-retrospect`                                                       | extended                       | additive `[pair ...]` grammar after the existing count; unchanged forms byte-identical                                         |
| `scripts/presence`                                                              | extended                       | suppression filtering, `suppressed` telemetry, warn-once persisted across process invocations, TTL-expiry `recall_cache` purge |
| `scripts/retrieve`                                                              | extended                       | digest line, gated like the existing recall-coverage line                                                                      |
| `tests/test_feedback.sh`                                                        | new                            | spec §6 items 1-9, 12-13 (feedback CLI + presence suppression behavior + digest + perf)                                        |
| `tests/test_helpers.sh`                                                         | extended                       | `match_trigger_pairs`/`feedback_shape_ok` unit tests; `mark-retrospect` pair-grammar tests (items 10, 11, 14, 15)              |
| `skills/policy-retrospect/SKILL.md`                                             | extended                       | rule 2 exact wording (§4.3.5): name ids/pairs, the `id[:trigger]` grammar, the lesson-id rejection note                        |
| `skills/consolidate/SKILL.md`                                                   | extended (plan-owner add.)     | step 2b addendum: a noisy cue either gets re-cued (`remove-trigger`) or mechanically quiets itself (adaptive suppression)      |
| `skills/demo/SKILL.md`                                                          | extended                       | new routing row: `anoti feedback list`/`clear`                                                                                 |
| `docs/SKILL-MAP.md`                                                             | extended                       | new entry-point row for `scripts/feedback`, alongside the presence-hook row                                                    |
| `docs/specs/2026-08-13-exp-longitudinal.md`                                     | extended (dated changelog)     | §4.8 Q006 gate reworded; §4.9 new KEEP/telemetry-only/REVERT criterion                                                         |
| `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | extended (applied post-review) | 0.5.26 — technical-writer drafts the text, the dispatching session applies it after the reviewer's COMPLIANT verdict           |

## Spawn arithmetic

- **1 backend spawn, isolated worktree** — Tasks 1-5 (every script + test
  file, in dependency order: store-resolve before feedback, before
  mark-retrospect and presence both depend on it; feedback before
  mark-retrospect, which shells out to it; presence's own tests depend on
  `scripts/feedback mark` existing to seed fixtures, so presence follows
  feedback). Justification: one dependency chain, one context holding it
  — the same reasoning `docs/specs/2026-08-19-jit-recall-design.md`'s own
  precedent plan already used (`docs/plans/2026-08-19-jit-recall-implementation.md:93-100`);
  splitting into multiple backend spawns would force a hand-off
  transcript to substitute for context a single spawn keeps for free.
  Dispatch: `Agent({subagent_type: "anoti:practitioner", isolation:
"worktree", run_in_background: true, description: "adaptive
suppression: backend", prompt: "<role: backend> Tasks 1-5 of this
plan, in order..."})`.
- **1 technical-writer spawn, isolated worktree, concurrent with
  backend** — Tasks 6-11 (every exact-wording edit + the drafted
  CHANGELOG text). Justification: disjoint file set from backend's (no
  file appears in both lists above), so no merge conflict risk;
  concurrency is free per policy-parallel-breadth's ≤3-concurrent budget
  (2 used at this point).
- **Worktree-branch verification (both spawns, first action before any
  edit):** `adaptive-suppression` currently equals `main`
  ({command: "git rev-parse adaptive-suppression main", output: two
  identical hashes, verified 2026-08-19}), so this is low-risk today, but
  the harness's worktree-isolation default is not independently confirmed
  to branch from the invoking session's current branch rather than
  `origin/<default-branch>` (EnterWorktree's own documented default is
  "fresh… branches from origin/<default-branch>" unless `head` is
  configured — the Agent tool's `isolation: "worktree"` may or may not
  share that default). Each builder's **first action** is therefore:
  confirm `git merge-base --is-ancestor adaptive-suppression HEAD` inside
  its own worktree; if false, `git rebase adaptive-suppression` (or
  `git reset --hard adaptive-suppression` if the worktree has no commits
  yet) before touching any file. Named explicitly rather than assumed —
  see Risks.
- **1 reviewer spawn, after both finish** — reviews both diffs together
  (spec:1283-1305 names one reviewer covering both builders). By reading
  each worktree's diff directly (`git -C <worktree-path> diff
adaptive-suppression`), not by merging first — merging is a _later_
  step, after the verdict. Justification: policy-adversarial-handoff
  requires builder work pass through a reviewer before it counts as done;
  one spawn suffices because the spec names one reviewer for both.
- **Fix-round resumes are not new spawns** — per D011
  (`skills/deliberate/SKILL.md:85-93`), reviewer findings resume the
  _original_ backend or technical-writer spawn (SendMessage to the same
  agent, same worktree — this is exactly why the worktree must still
  exist), capped at 3 cycles (mirrors spec:1307-1312).
- **Total distinct spawns this cascade adds: 3** (backend,
  technical-writer, reviewer) — 2 concurrent at peak, well under the
  ≤3-concurrent / ≤8-per-session ceiling.
- **Release + final integration (Task 13) is not a new spawn** — the
  dispatching session performs the CHANGELOG/version-bump edit directly
  (using technical-writer's drafted text from Task 11) and the git
  merge/push mechanics, because that step needs both worktrees'
  _combined_ diff and neither builder's own worktree contains the other's
  files; architect (this plan's own role) cannot perform it either
  (advisory-class, "never implementation," `roles/architect.md:22-24`).
  See Task 13.

---

## Tasks

Every task: RED (test shown, not described) → `bash tests/run.sh`
(confirm the _named_ new failures, nothing else regresses) → GREEN
(implementation shown) → `bash tests/run.sh` (confirm full green) →
`shellcheck -S warning <changed scripts/* files>` (CI's own lint scope,
`.github/workflows/ci.yml:47`, is `scripts/*` + `benchmark/*` +
`tests/run.sh` only) → commit.

### Task 1 — `scripts/store-resolve`: `match_trigger_pairs` + `feedback_shape_ok`

**Role: backend.** Loads: policy-test-driven, policy-adversarial-handoff,
`anoti:git`, plus backend's universal stack (`roles/backend.md:6-13`).

**Source:** spec:174-189 (component map rows "Detail matcher"/"Shape
checker"), spec:275-328 (`match_trigger_pairs`, illustrative code +
verification note), spec:566-580 (`feedback_shape_ok`, literal code),
constraint 5 (spec:147-167, "sibling function, not modification of
`match_triggers`").

**Current file:** `scripts/store-resolve` is 114 lines, ends after
`match_lessons` (lines 105-114, confirmed by direct read). Both new
functions are appended after it.

**RED** — append to `tests/test_helpers.sh` immediately after the
existing store-resolve block (which currently ends at line 729 with
`); rm -rf "$tmp"`, right before the `# --- append-trigger: project
path` comment at line 731 — confirmed by direct read):

```bash
# --- store-resolve: match_trigger_pairs + feedback_shape_ok (adaptive suppression §4.3.3/§4.4) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
SELF="$ROOT/scripts"; export SELF
. "$ROOT/scripts/store-resolve"
cp "$ROOT/tests/fixtures/store_triggers.yaml" GROUNDING.yaml
# T001 carries TWO triggers in the fixture as shipped: ["cd chain", "cd &&"]
out="$(match_trigger_pairs GROUNDING.yaml 'a cd chain happened here')"
n="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
assert_eq "$n" "1" "match_trigger_pairs emits one row for one matching pair"
assert_eq "$out" "$(printf 'T001\tcd chain\tcd chaining across shell invocations breaks relative paths.')" \
  "match_trigger_pairs emits id, ORIGINAL trigger text, statement (unaggregated)"
out="$(match_trigger_pairs GROUNDING.yaml 'cd chain and cd && both here')"
n="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
assert_eq "$n" "2" "match_trigger_pairs emits ONE ROW PER MATCHING TRIGGER, not aggregated per record (T001 x2)"
out="$(match_trigger_pairs GROUNDING.yaml 'nothing relevant here')"
assert_eq "$out" "" "match_trigger_pairs silent on no match"
# event-scoping (edit:/bash: prefixes) must be honored identically to match_triggers
cp "$ROOT/tests/fixtures/store_valid.yaml" s2.yaml
"$ROOT/scripts/append-trigger" s2.yaml D001 "edit:CHANGELOG.md" >/dev/null 2>&1
MT_EVENT=bash out="$(MT_EVENT=bash match_trigger_pairs s2.yaml 'editing CHANGELOG.md now')"
assert_eq "$out" "" "match_trigger_pairs respects edit:-scoping: silent on a Bash-typed firing"
out="$(MT_EVENT=edit match_trigger_pairs s2.yaml 'editing CHANGELOG.md now')"
printf '%s' "$out" | grep -qF -- $'D001\tedit:CHANGELOG.md'; assert_ok $? "match_trigger_pairs preserves the ORIGINAL prefixed trigger text (for feedback/remove-trigger to act on), not the stripped form used only for matching"
# feedback_shape_ok
printf 'D001\tcd chain\t3\t2026-08-17\t2026-08-19\n' > good.tsv
feedback_shape_ok good.tsv; assert_ok $? "feedback_shape_ok accepts a well-formed row"
[ -f nope.tsv ] || true
feedback_shape_ok nope.tsv; assert_ok $? "feedback_shape_ok: a MISSING file is not a shape failure"
printf 'D001\tcd chain\t3\n' > bad_cols.tsv
feedback_shape_ok bad_cols.tsv; assert_eq "$?" "1" "feedback_shape_ok rejects a row with the wrong column count"
printf 'D001\tcd chain\tthree\t2026-08-17\t2026-08-19\n' > bad_count.tsv
feedback_shape_ok bad_count.tsv; assert_eq "$?" "1" "feedback_shape_ok rejects a non-numeric count"
printf 'D001\tcd chain\t3\t08-17-2026\t2026-08-19\n' > bad_date.tsv
feedback_shape_ok bad_date.tsv; assert_eq "$?" "1" "feedback_shape_ok rejects a malformed last_marked date"
); rm -rf "$tmp"
```

Run `bash tests/run.sh` — expect these new failures (function not found),
nothing else.

**GREEN** — append to `scripts/store-resolve` (after `match_lessons`,
line 114):

```sh
match_trigger_pairs() {  # $1=store $2=haystack -- ALL matching (id,ORIGINAL-trigger,statement) triples, unaggregated, one row per matching pair. Sibling to match_triggers (constraint 5, spec:147-167) -- match_triggers itself is untouched.
  f="$1"
  export MT_HAY="$2"
  yq -r '.records[] | .id as $id | .statement as $s |
      (.triggers // [])[] | [$id, ., $s] | @tsv' "$f" 2>/dev/null |
  awk -F'\t' '
    BEGIN { h = tolower(ENVIRON["MT_HAY"]); ev = ENVIRON["MT_EVENT"] }
    {
      orig = $2
      trig = tolower($2)
      if (substr(trig, 1, 5) == "edit:") { if (ev != "" && ev != "edit") next; trig = substr(trig, 6) }
      else if (substr(trig, 1, 5) == "bash:") { if (ev != "" && ev != "bash") next; trig = substr(trig, 6) }
      if (trig != "" && index(h, trig) > 0) printf "%s\t%s\t%s\n", $1, orig, $3
    }
  '
  unset MT_HAY
}
feedback_shape_ok() {  # $1=file -- 0 if every non-empty line has exactly 5 tab fields, count numeric, both dates YYYY-MM-DD; a MISSING file is NOT a shape failure (caller distinguishes absent vs. present-and-bad)
  [ -f "$1" ] || return 0
  awk -F'\t' '
    NF == 0 { next }
    NF != 5 { bad = 1; exit }
    $3 !~ /^[0-9]+$/ { bad = 1; exit }
    $4 !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ { bad = 1; exit }
    $5 !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ { bad = 1; exit }
    END { exit bad ? 1 : 0 }
  ' "$1"
}
```

Run `bash tests/run.sh` — full green. `shellcheck -S warning
scripts/store-resolve`.

**Commit:** `feat: adaptive suppression — match_trigger_pairs +
feedback_shape_ok (store-resolve)`

Body: `New sibling exports per spec constraint 5
(docs/specs/2026-08-19-adaptive-suppression-design.md:147-167) —
match_triggers itself (scripts/store-resolve:32-57) is unmodified, same
regression-risk reasoning the jit-recall spec already established for
this exact function. Spec §4.3.3, §4.4.`

### Task 2 — `scripts/feedback` (new): `mark`/`list`/`clear`

**Role: backend.** Loads: same as Task 1.

**Source:** spec:482-581 (§4.4, full contract + illustrative code for
`mark`), spec:545-564 (`clear`, both forms + the deliberately-not-built
clear-everything form), spec:736-762 (§4.5.2 point 1, the `recall_cache`
purge-on-clear code block).

**RED** — new file `tests/test_feedback.sh` (auto-discovered by
`tests/run.sh:18`'s `for t in "$ROOT"/tests/test_*.sh` loop; sources
before `test_helpers.sh`/`test_presence.sh` alphabetically, so it
defines its own hermetic fixture helper rather than relying on
`test_presence.sh`'s `mkfx()`, which has not sourced yet at this point in
the run):

```bash
F="$ROOT/scripts/feedback"
fb_mkfx() { # $1=dir -- lay down a trusted project store from store_triggers.yaml (same fixture Task 1/4 use: T001 has triggers ["cd chain","cd &&"])
  mkdir -p "$1/.anoti"
  cp "$ROOT/tests/fixtures/store_triggers.yaml" "$1/GROUNDING.yaml"
  ( cd "$1" && "$ROOT/scripts/trust" GROUNDING.yaml >/dev/null )
}

# --- scripts/feedback mark/list (spec §4.4) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkdir -p .anoti
out="$("$F" list)"
assert_eq "$out" "feedback: no presence-feedback.tsv yet (nothing suppressed)" "list: missing file message, exit 0"
"$F" mark D001 "cd chain" >/dev/null; assert_ok $? "mark exits 0"
"$F" mark D001 "cd chain" >/dev/null
"$F" mark D001 "cd chain" >/dev/null
out="$("$F" list)"
printf '%s' "$out" | grep -qE $'^D001\tcd chain\t3\t.*\tyes$'; assert_ok $? "three marks: count=3, suppressed=yes"
"$F" mark D009 "curl" >/dev/null
"$F" mark D009 "curl" >/dev/null
out="$("$F" list)"
printf '%s' "$out" | grep -qE $'^D009\tcurl\t2\t.*\tno$'; assert_ok $? "two marks: count=2, suppressed=no"
c="$(grep -c $'^D001\tcd chain' .anoti/presence-feedback.tsv)"
assert_eq "$c" "1" "mark increments a row in place, never appends a duplicate"
); rm -rf "$tmp"

# --- scripts/feedback clear: with/without trigger, refusal on absent, recall_cache purge (spec §4.4, §4.5.2 point 1) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
"$F" mark T001 "cd &&" >/dev/null
# inject once BEFORE clear so recall_cache in the session's presence-state file holds a pre-suppression entry for T001 (MINOR 13 fix-round extension)
printf '{"session_id":"fbclr","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd &&"},"tool_response":{}}' | "$ROOT/scripts/presence" >/dev/null
yq -e '.recall_cache | has("T001")' .anoti/sessions/fbclr.presence.yaml >/dev/null 2>&1
assert_ok $? "setup: recall_cache holds a pre-clear entry for T001"
"$F" clear T001 "cd chain"; assert_ok $? "clear (with trigger) exits 0"
c="$(grep -c $'^T001\tcd chain' .anoti/presence-feedback.tsv 2>/dev/null || echo 0)"
assert_eq "$c" "0" "clear removed exactly the named (id,trigger) row"
c2="$(grep -c '^T001' .anoti/presence-feedback.tsv 2>/dev/null || echo 0)"
assert_eq "$c2" "1" "clear left the OTHER trigger's row for the same id untouched"
yq -e '.recall_cache | has("T001")' .anoti/sessions/fbclr.presence.yaml >/dev/null 2>&1
assert_eq "$?" "1" "clear purges the stale recall_cache entry for the cleared id (MINOR 13 fix)"
"$F" clear T001 "no-such-trigger" 2>/dev/null
assert_eq "$?" "1" "clear refuses an absent (id,trigger) pair"
"$F" clear T001 >/dev/null; assert_ok $? "clear without trigger removes ALL rows for the id"
c3="$(grep -c '^T001' .anoti/presence-feedback.tsv 2>/dev/null || echo 0)"
assert_eq "$c3" "0" "clear (no trigger) removed every row for T001, including 'cd &&'"
"$F" clear T001 2>/dev/null; assert_eq "$?" "1" "clear on an already-empty id refuses (G004: clear always distinguishes cleared vs nothing-there)"
); rm -rf "$tmp"
```

Run `bash tests/run.sh` — expect the named new failures (`scripts/feedback:
No such file or directory`), nothing else.

**GREEN** — new file `scripts/feedback`, `chmod 755`:

```sh
#!/bin/bash
# feedback mark|list|clear -- the single reader/writer of
# <state-dir>/presence-feedback.tsv (project-level adaptive suppression
# ledger). Spec: docs/specs/2026-08-19-adaptive-suppression-design.md §4.4
set -u
SELF="$(cd "$(dirname "$0")" && pwd)"
. "$SELF/store-resolve"
. "$SELF/store-lock"
usage() { echo "feedback: usage: feedback mark <id> <trigger> | feedback list | feedback clear <id> [trigger]" >&2; exit 1; }
sub="${1:-}"; [ "$#" -gt 0 ] && shift

case "$sub" in
  mark)
    id="${1:?record id required}"; trig="${2:?trigger required}"
    AD="$("$SELF/anoti-dir" --require)" || exit 1   # writers require anchoring (G003), scripts/anoti-dir:10
    ff="$AD/presence-feedback.tsv"
    lock_store "$ff" || exit 1
    trap 'unlock_store "$ff"' EXIT
    [ -f "$ff" ] || : > "$ff"
    today="$(date -u +%F)"
    awk -F'\t' -v id="$id" -v trig="$trig" -v today="$today" '
      BEGIN { found = 0 }
      { if ($1 == id && $2 == trig) { $3 = $3 + 1; $4 = today; found = 1 }; print }
      END { if (!found) print id "\t" trig "\t1\t" today "\t" today }
    ' OFS='\t' "$ff" > "$ff.tmp.$$"
    feedback_shape_ok "$ff.tmp.$$" || { rm -f "$ff.tmp.$$"; echo "feedback: result failed shape validation; store untouched" >&2; exit 1; }
    pm="$(stat -c %a "$ff" 2>/dev/null || stat -f %Lp "$ff" 2>/dev/null || echo "")"
    [ -n "$pm" ] && chmod "$pm" "$ff.tmp.$$" 2>/dev/null
    mv "$ff.tmp.$$" "$ff"
    exit 0 ;;
  list)
    AD="$("$SELF/anoti-dir" 2>/dev/null)" || AD=".anoti"   # readers degrade gracefully, no --require
    ff="$AD/presence-feedback.tsv"
    if ! fx "$ff"; then echo "feedback: no presence-feedback.tsv yet (nothing suppressed)"; exit 0; fi
    feedback_shape_ok "$ff" || { echo "feedback: presence-feedback.tsv is present but not parseable" >&2; exit 1; }
    th="$(cfgk feedback_threshold)"; [ -n "$th" ] || th=3
    cutoff="$(date -v-30d +%F 2>/dev/null || date -d '30 days ago' +%F 2>/dev/null || echo "")"
    printf 'record_id\ttrigger\tcount\tlast_marked\tfirst_marked\tsuppressed\n'
    awk -F'\t' -v th="$th" -v cutoff="$cutoff" '
      NF==5 { sup = ($3+0>=th && $4>=cutoff) ? "yes" : "no"
        printf "%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, sup }
    ' "$ff" | sort -t "$(printf '\t')" -k3,3nr -k1,1
    exit 0 ;;
  clear)
    id="${1:?record id required}"; trig="${2:-}"
    AD="$("$SELF/anoti-dir" --require)" || exit 1
    ff="$AD/presence-feedback.tsv"
    lock_store "$ff" || exit 1
    trap 'unlock_store "$ff"' EXIT
    [ -f "$ff" ] || { echo "feedback: no presence-feedback.tsv; nothing to clear" >&2; exit 1; }
    if [ -n "$trig" ]; then
      matched="$(awk -F'\t' -v id="$id" -v trig="$trig" 'NF==5 && $1==id && $2==trig' "$ff")"
      awk -F'\t' -v id="$id" -v trig="$trig" '!(NF==5 && $1==id && $2==trig)' "$ff" > "$ff.tmp.$$"
    else
      matched="$(awk -F'\t' -v id="$id" 'NF==5 && $1==id' "$ff")"
      awk -F'\t' -v id="$id" '!(NF==5 && $1==id)' "$ff" > "$ff.tmp.$$"
    fi
    [ -n "$matched" ] || { rm -f "$ff.tmp.$$"; echo "feedback: no row for '$id'${trig:+ / '$trig'}" >&2; exit 1; }
    feedback_shape_ok "$ff.tmp.$$" || { rm -f "$ff.tmp.$$"; echo "feedback: result failed shape validation; store untouched" >&2; exit 1; }
    pm="$(stat -c %a "$ff" 2>/dev/null || stat -f %Lp "$ff" 2>/dev/null || echo "")"
    [ -n "$pm" ] && chmod "$pm" "$ff.tmp.$$" 2>/dev/null
    mv "$ff.tmp.$$" "$ff"
    # purge the matching recall_cache entry from every live session's presence-state file (spec §4.5.2 point 1).
    # DEVIATION from the spec's own illustrative code (spec:744-754): a bare
    # `trap 'unlock_store "$sf"' EXIT` inside this loop would REPLACE the
    # outer `trap 'unlock_store "$ff"' EXIT` already set above, so an early
    # exit mid-loop would leak the feedback-file lock. Restore the outer
    # trap after each inner iteration instead of clearing it.
    for sf in "$AD"/sessions/*.presence.yaml; do
      [ -f "$sf" ] || continue
      lock_store "$sf" || continue
      trap 'unlock_store "$sf"' EXIT
      yq -e ".recall_cache | has(\"$id\")" "$sf" >/dev/null 2>&1 \
        && yq -i "del(.recall_cache[\"$id\"])" "$sf" 2>/dev/null
      unlock_store "$sf"
      trap 'unlock_store "$ff"' EXIT
    done
    exit 0 ;;
  *) usage ;;
esac
```

Run `bash tests/run.sh` — full green. `shellcheck -S warning
scripts/feedback`.

**Commit:** `feat: adaptive suppression — scripts/feedback mark/list/clear`

Body: `The single reader/writer of presence-feedback.tsv (spec §4.4).
clear purges the matching recall_cache entry from every live
*.presence.yaml so reversibility does not wait out the N=10 dedupe
window (spec §4.5.2 point 1, MINOR 13 fix-round finding). Fixes a trap-
clobber bug in the spec's own illustrative purge loop (see inline
comment). Spec §4.4.`

### Task 3 — `scripts/mark-retrospect`: extended pair grammar

**Role: backend.** Loads: same as Task 1.

**Source:** spec:330-443 (§4.3.4, full grammar + both fix-round guards,
IMPORTANT 3 lesson-id and IMPORTANT 4 empty-half), spec:1110-1122 (§6
items 10-11), spec:1134-1149 (§6 items 14-15, the exact worked-example
tokens named in the dispatch brief: `"D001:"`, `":cd-chain"`,
`"L:a1b2c3d4"`, `"L:a1b2c3d4:cd chain"`). Depends on Task 2
(`scripts/feedback mark`, which this task shells out to).

**RED** — append to `tests/test_helpers.sh` immediately after the
existing mark-retrospect block (currently lines 814-824, confirmed by
direct read — insert after line 824's `); rm -rf "$tmp"`):

```bash
# --- mark-retrospect: named pairs (adaptive suppression §4.3.4) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
# item 10: existing forms stay byte-identical (direct regression against the SAME assertions already at test_helpers.sh:817-823, re-run here on a fresh dir to confirm no cross-contamination from the new arg-parsing path)
"$ROOT/scripts/mark-retrospect" rY empty; assert_ok $? "backward-compat: empty exits 0"
grep -qE $'retrospect\tempty' .anoti/telemetry.log; assert_ok $? "backward-compat: empty branch telemetry shape unchanged"
"$ROOT/scripts/mark-retrospect" rY filed irrelevant-injections 3 >/dev/null
grep -qE $'irrelevant=3$' .anoti/telemetry.log; assert_ok $? "backward-compat: count-only form, NO pairs= suffix when no pairs given"
# item 11: named pairs -- id:trigger feeds scripts/feedback mark; id-only is audit-only
"$ROOT/scripts/mark-retrospect" rY filed irrelevant-injections 2 "D001:cd chain" "D009" >/dev/null
grep -qF -- 'pairs=D001:cd chain,D009' .anoti/telemetry.log; assert_ok $? "pairs= field is comma-joined, id-only un-suffixed"
c1="$(grep -c $'^D001\tcd chain' .anoti/presence-feedback.tsv 2>/dev/null || echo 0)"
assert_eq "$c1" "1" "id:trigger pair fed scripts/feedback mark"
c2="$(grep -c '^D009' .anoti/presence-feedback.tsv 2>/dev/null || echo 0)"
assert_eq "$c2" "0" "id-only token is audit-trail ONLY, no feedback-store write"
# a colon inside the trigger itself splits on the FIRST colon only
"$ROOT/scripts/mark-retrospect" rY filed irrelevant-injections 1 "D025:edit:CHANGELOG.md" >/dev/null
grep -qE $'^D025\tedit:CHANGELOG.md\t1\t' .anoti/presence-feedback.tsv; assert_ok $? "first-colon-only split: id=D025, trigger=edit:CHANGELOG.md (trigger's own colon preserved)"
); rm -rf "$tmp"

# --- mark-retrospect: guard cases (fix-round IMPORTANT 3/4, spec §6 items 14-15) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
mkdir -p .anoti
"$ROOT/scripts/mark-retrospect" rZ filed irrelevant-injections 1 "D001:" 2>err1.log >/dev/null
grep -qF "malformed pair token" err1.log; assert_ok $? "'D001:' (empty trigger half) rejected with stderr note"
[ -s .anoti/presence-feedback.tsv ] 2>/dev/null; assert_eq "$?" "1" "'D001:' wrote NO row"
grep -qE $'irrelevant=1$' .anoti/telemetry.log; assert_ok $? "'D001:' still writes the base irrelevant=1 line"
"$ROOT/scripts/mark-retrospect" rZ filed irrelevant-injections 1 ":cd-chain" 2>err2.log >/dev/null
grep -qF "malformed pair token" err2.log; assert_ok $? "':cd-chain' (empty id half) rejected with stderr note"
[ -s .anoti/presence-feedback.tsv ] 2>/dev/null; assert_eq "$?" "1" "':cd-chain' wrote NO row"
"$ROOT/scripts/mark-retrospect" rZ filed irrelevant-injections 1 "L:a1b2c3d4" 2>err3.log >/dev/null
grep -qF "lesson ids cannot be named" err3.log; assert_ok $? "'L:a1b2c3d4' (lesson id) rejected outright"
[ -s .anoti/presence-feedback.tsv ] 2>/dev/null; assert_eq "$?" "1" "'L:a1b2c3d4' wrote NO row (not accepted as id=L trigger=a1b2c3d4)"
! grep -qF "L:a1b2c3d4" .anoti/telemetry.log; assert_ok $? "'L:a1b2c3d4' does not even appear in the pairs= telemetry field"
"$ROOT/scripts/mark-retrospect" rZ filed irrelevant-injections 1 "L:a1b2c3d4:cd chain" 2>err4.log >/dev/null
grep -qF "lesson ids cannot be named" err4.log; assert_ok $? "'L:a1b2c3d4:cd chain' (spurious trigger appended) rejected the SAME way -- idhalf is L either way"
); rm -rf "$tmp"
```

Run `bash tests/run.sh` — expect the named new failures (grep finds
nothing yet), nothing else.

**GREEN** — replace `scripts/mark-retrospect` in full:

```sh
#!/bin/bash
# mark-retrospect <session-id> <empty|filed> [irrelevant-injections N [pair ...]] --
# mechanical, one durable telemetry line. Closes "did the retrospective
# run" (spec: jit-recall §4.8 gap 2). The optional count is the
# retrospective's answer to "how many presence injections this session
# were irrelevant?" -- the precision metric's source. Each optional pair
# is <record-id> (audit only) or <record-id>:<trigger> (feeds adaptive
# suppression via scripts/feedback mark). Spec: docs/specs/2026-08-19-
# adaptive-suppression-design.md §4.3.4
set -u
SELF="$(cd "$(dirname "$0")" && pwd)"
AD="$("$SELF/anoti-dir" --require)" || exit 1
sid="${1:?usage: mark-retrospect <session-id> <empty|filed>}"
state="${2:?state required (empty|filed)}"
case "$state" in empty|filed) ;; *) echo "mark-retrospect: state must be empty|filed" >&2; exit 1 ;; esac
irr=""
pairs_field=""
if [ "${3:-}" = "irrelevant-injections" ]; then
  irr="${4:?count required}"; case "$irr" in ''|*[!0-9]*) echo "mark-retrospect: count must be numeric" >&2; exit 1 ;; esac
  shift 4
  pairs_csv=""
  for tok in "$@"; do
    [ -n "$tok" ] || continue
    idhalf="${tok%%:*}"
    if [ "$idhalf" = "$tok" ]; then
      trighalf=""; haspair=0
    else
      trighalf="${tok#*:}"; haspair=1
    fi
    # GUARD 1: empty-half check (IMPORTANT 4) -- "D001:" -> trighalf="" rejected;
    # ":cd-chain" -> idhalf="" rejected.
    if [ -z "$idhalf" ] || { [ "$haspair" = "1" ] && [ -z "$trighalf" ]; }; then
      echo "mark-retrospect: skipping malformed pair token '$tok' (empty id or trigger half)" >&2
      continue
    fi
    # GUARD 2: lesson-id collision (IMPORTANT 3) -- lesson ids are always
    # "L:<hash>", so their mandatory colon forces idhalf="L" whether bare
    # or with a spurious trigger appended. Outright reject (§7: lessons
    # carry no authored triggers, so there is no pairing to suppress).
    if [ "$idhalf" = "L" ]; then
      echo "mark-retrospect: skipping '$tok' -- lesson ids cannot be named for suppression (adaptive-suppression §7)" >&2
      continue
    fi
    if [ "$haspair" = "1" ]; then
      "$SELF/feedback" mark "$idhalf" "$trighalf" >/dev/null 2>&1
      pairs_csv="${pairs_csv}${idhalf}:${trighalf},"
    else
      pairs_csv="${pairs_csv}${idhalf},"
    fi
  done
  pairs_csv="${pairs_csv%,}"
  [ -n "$pairs_csv" ] && pairs_field="$(printf '\tpairs=%s' "$pairs_csv")"
fi
if [ -n "$irr" ]; then
  printf '%s\t%s\t%s\t%s\tirrelevant=%s%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$sid" "retrospect" "$state" "$irr" "$pairs_field" >> "$AD/telemetry.log" 2>/dev/null || true
else
  printf '%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$sid" "retrospect" "$state" >> "$AD/telemetry.log" 2>/dev/null || true
fi
exit 0
```

Run `bash tests/run.sh` — full green (including the existing, unmodified
assertions at `tests/test_helpers.sh:817-823` — direct backward-compat
confirmation for §8 item 6). `shellcheck -S warning
scripts/mark-retrospect`.

**Commit:** `feat: adaptive suppression — mark-retrospect named
(id[:trigger]) pairs`

Body: `Additive, backward-compatible grammar (spec §4.3.4): a trailing
id:trigger token feeds scripts/feedback mark; id-only is audit-trail
only; malformed tokens and lesson ids are rejected with a stderr note,
never silently guessed into a pairing. Existing two/three-arg forms are
byte-identical (tests/test_helpers.sh:817-823, unmodified). Spec §4.3.4,
§6 items 10-11, 14-15.`

### Task 4 — `scripts/presence`: suppression filter, telemetry, warn-once persistence, `recall_cache` purge

**Role: backend.** Loads: same as Task 1. Depends on Task 1
(`match_trigger_pairs`/`feedback_shape_ok`) and Task 2 (its own tests use
`scripts/feedback mark` to seed fixtures).

**Source:** spec:583-655 (§4.5.1, load the suppression set + the
IMPORTANT-2 warn-once write-back fix), spec:657-789 (§4.5.2, filtering +
re-aggregation + the two `recall_cache` purge points), spec:791-807
(§4.5.3, `suppressed` telemetry), spec:1018-1109 (§6 items 1-9, the
literal test contracts).

**Current file:** `scripts/presence` is 245 lines (confirmed). Insertion
points, by exact current line:

- After line 61 (`warned_p="$(yq -r '.warned.project // false' ...)"`),
  before line 62 (`gstore=""; pstore=""; lstore=""`): the `warned_f` read
  - suppression-set load.
- Replacing lines 84-87 (the `p_matches`/`g_matches` assembly): the
  `suppression_filtered_matches` function + its two call sites.
- After line 167 (`[ -n "$recall_detail" ] && tel recall "$recall_detail"`):
  the `suppressed` telemetry duty.
- Before line 229 (`rc_json="$(...)"` construction): the expired-id
  `recall_cache_local` purge.
- Replacing lines 235-237 (the persist `yq` call): add `WF`/`.warned.feedback`.

**RED** — new file `tests/test_feedback.sh` (continuing from Task 2's
additions, same file — `fb_mkfx()` already defined there):

```bash
# --- item 1: three marks suppress; item 2: two marks don't ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
out="$(printf '{"session_id":"s1a","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_ok $? "item 2: two marks (below threshold 3) -- T001 still injects"
! grep -q "presence.suppressed" .anoti/telemetry.log; assert_ok $? "item 2: no suppressed telemetry below threshold"
"$F" mark T001 "cd chain" >/dev/null   # now count=3
out="$(printf '{"session_id":"s1b","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -q "T001"
assert_eq "$?" "1" "item 1: three marks (at threshold) -- T001 absent from additionalContext"
grep -qF -- $'presence\tsuppressed\tT001:cd chain' .anoti/telemetry.log; assert_ok $? "item 1: suppressed telemetry line names the pair"
! grep -qE "presence.recall.T001\[\]" .anoti/telemetry.log; assert_ok $? "item 1: no recall telemetry line for T001 this firing (fully suppressed)"
); rm -rf "$tmp"

# --- item 3: expired marks (last_marked > 30 days ago) don't count ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
old="$(date -v-40d +%F 2>/dev/null || date -d '40 days ago' +%F 2>/dev/null)"
printf 'T001\tcd chain\t3\t%s\t%s\n' "$old" "$old" > .anoti/presence-feedback.tsv
out="$("$F" list)"
printf '%s' "$out" | grep -qE $'^T001\tcd chain\t3\t.*\tno$'; assert_ok $? "item 3: list shows suppressed=no for an expired row"
out="$(printf '{"session_id":"s3","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"
assert_ok $? "item 3: an expired mark does not suppress -- T001 still injects"
); rm -rf "$tmp"

# --- item 4: other triggers still fire (T001 has TWO triggers: 'cd chain' suppressed, 'cd &&' not) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
out="$(printf '{"session_id":"s4","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain and cd && both here"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"
assert_ok $? "item 4: record still injects via its OTHER (unsuppressed) trigger"
grep -qE "presence.recall.T001\[\]" .anoti/telemetry.log; assert_ok $? "item 4: recall telemetry still names T001 (survived via 'cd &&')"
grep -qF -- $'presence\tsuppressed\tT001:cd chain' .anoti/telemetry.log; assert_ok $? "item 4: suppressed telemetry separately names ONLY the suppressed pair"
); rm -rf "$tmp"

# --- item 6: digest line, gated exactly like recall-coverage (PSTORE) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkdir -p .anoti
printf 'T001\tcd chain\t3\t2026-08-19\t2026-08-17\nD009\tcurl\t3\t2026-08-19\t2026-08-17\n' > .anoti/presence-feedback.tsv
out="$("$ROOT/scripts/anoti" digest)"
! printf '%s' "$out" | grep -q "pairs suppressed"; assert_ok $? "digest gate: NO project store (PSTORE unset) -- line never shows even though the TSV exists"
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
out="$("$ROOT/scripts/anoti" digest)"
printf '%s' "$out" | grep -q "presence: 2 (record,trigger) pairs suppressed — anoti feedback list"
assert_ok $? "digest: N=2, exact count and text, project store now present"
rm .anoti/presence-feedback.tsv
out="$("$ROOT/scripts/anoti" digest)"
! printf '%s' "$out" | grep -q "pairs suppressed"; assert_ok $? "digest: N=0 (no feedback file) -- line omitted entirely (US-002)"
); rm -rf "$tmp"

# --- item 7: telemetry shape -- ONE line, comma-joined, two pairs across two records ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkdir -p .anoti
cp "$ROOT/tests/fixtures/store_triggers.yaml" GROUNDING.yaml
yq -i '.records += [{"id":"T020","date":"2026-08-19","type":"claim","topic":"test.two","statement":"A second suppressible record.","triggers":["second-marker"],"epistemic_status":"probable","ratification":"approved","source":{"type":"conversation"},"evidence":[],"events":[{"date":"2026-08-19","action":"created","by":"session"}]}]' GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
"$F" mark T020 "second-marker" >/dev/null; "$F" mark T020 "second-marker" >/dev/null; "$F" mark T020 "second-marker" >/dev/null
out="$(printf '{"session_id":"s7","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain here, second-marker too"},"tool_response":{}}' | "$ROOT/scripts/presence")"
c="$(grep -c 'presence.suppressed' .anoti/telemetry.log)"
assert_eq "$c" "1" "item 7: EXACTLY one suppressed telemetry line, never two separate lines"
grep -qF -- $'presence\tsuppressed\tT001:cd chain,T020:second-marker' .anoti/telemetry.log
assert_ok $? "item 7: comma-joined, both pairs on the one line"
); rm -rf "$tmp"

# --- item 8: corrupt file, warn-once ACROSS TWO SEPARATE PROCESS INVOCATIONS ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
mkdir -p .anoti
printf 'T001\tcd chain\tNOT-A-NUMBER\t2026-08-19\t2026-08-17\n' > .anoti/presence-feedback.tsv
out1="$(printf '{"session_id":"s8","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"anything"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out1" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -qi "not parseable"
assert_ok $? "item 8: first (separate) process invocation warns about the corrupt file"
grep -q "presence.warn.feedback" .anoti/telemetry.log; assert_ok $? "item 8: first invocation logs presence warn feedback"
yq -e '.warned.feedback == true' .anoti/sessions/s8.presence.yaml >/dev/null 2>&1
assert_ok $? "item 8: warned.feedback is PERSISTED to disk (IMPORTANT 2 write-back fix), not just an in-memory flag"
# second invocation: a FRESH process (new printf | presence pipeline), same sid -- reads warned.feedback=true from disk
out2="$(printf '{"session_id":"s8","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"anything else"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out2" | jq -r '.hookSpecificOutput.additionalContext // ""' | grep -qi "not parseable"
assert_eq "$?" "1" "item 8: SECOND process invocation is silent on the same warning"
c="$(grep -c "presence.warn.feedback" .anoti/telemetry.log)"
assert_eq "$c" "1" "item 8: exactly one warn telemetry line across two separate invocations"
); rm -rf "$tmp"

# --- item 9: perf, extends the shipped 2.5s bound (tests/test_presence.sh:255-256) to cover match_trigger_pairs + the suppression filter pass ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME/.claude/anoti" .anoti
gen() {
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
i=1; while [ "$i" -le 200 ]; do
  printf 'P%03d\tbulk-kw-%d\t1\t2026-08-19\t2026-08-19\n' "$i" "$i" >> .anoti/presence-feedback.tsv
  i=$((i+1))
done
start="$(date +%s.%N)"
printf '{"session_id":"perf2","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"bulk-kw-1 bulk-kw-2"},"tool_response":{}}' | "$ROOT/scripts/presence" >/dev/null
end="$(date +%s.%N)"
elapsed="$(awk -v a="$start" -v b="$end" 'BEGIN{printf "%.3f", b-a}')"
awk -v e="$elapsed" 'BEGIN{exit !(e < 2.5)}'
assert_ok $? "item 9: perf pin UNCHANGED at 2.5s, now with match_trigger_pairs + suppression filter + a 200-row feedback file in the mix (got ${elapsed}s)"
); rm -rf "$tmp"

# --- item 12: feedback_threshold override ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
printf -- '---\nfeedback_threshold: 5\n---\n' > .claude/anoti.local.md.tmp 2>/dev/null || { mkdir -p .claude; printf -- '---\nfeedback_threshold: 5\n---\n' > .claude/anoti.local.md; }
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
out="$("$F" list)"; printf '%s' "$out" | grep -qE $'^T001\tcd chain\t3\t.*\tno$'
assert_ok $? "item 12: threshold override=5 -- 3 marks still shows suppressed=no"
out2="$(printf '{"session_id":"s12a","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out2" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"
assert_ok $? "item 12: 3 marks under a threshold of 5 still injects normally"
"$F" mark T001 "cd chain" >/dev/null; "$F" mark T001 "cd chain" >/dev/null
out3="$("$F" list)"; printf '%s' "$out3" | grep -qE $'^T001\tcd chain\t5\t.*\tyes$'
assert_ok $? "item 12: 5 marks under threshold=5 -- now suppressed=yes"
); rm -rf "$tmp"

# --- item 5 (extended, MINOR 13): recall_cache purge on natural TTL expiry, at read time ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
fb_mkfx "$tmp"
# inject once, unsuppressed, so recall_cache holds a pre-suppression entry
printf '{"session_id":"sttl","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain first time"},"tool_response":{}}' | "$ROOT/scripts/presence" >/dev/null
yq -e '.recall_cache | has("T001")' .anoti/sessions/sttl.presence.yaml >/dev/null 2>&1
assert_ok $? "TTL setup: recall_cache holds a pre-expiry entry for T001"
old="$(date -v-40d +%F 2>/dev/null || date -d '40 days ago' +%F 2>/dev/null)"
printf 'T001\tcd chain\t3\t%s\t%s\n' "$old" "$old" > .anoti/presence-feedback.tsv   # at/above threshold, but last_marked is EXPIRED
out="$(printf '{"session_id":"sttl","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"anything else"},"tool_response":{}}' | "$ROOT/scripts/presence")"
yq -e '.recall_cache | has("T001")' .anoti/sessions/sttl.presence.yaml >/dev/null 2>&1
assert_eq "$?" "1" "TTL expiry: the stale recall_cache entry is purged at the firing that finds it expired (§4.5.2 point 2)"
out2="$(printf '{"session_id":"sttl","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd chain again"},"tool_response":{}}' | "$ROOT/scripts/presence")"
printf '%s' "$out2" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "T001"
assert_ok $? "TTL expiry: the NEXT firing re-injects T001 (the purge actually restores reversibility)"
); rm -rf "$tmp"
```

Run `bash tests/run.sh` — expect the named new failures, nothing else.

**GREEN** — edit `scripts/presence` at the exact points named above.

Insert after line 61:

```sh
warned_f="$(yq -r '.warned.feedback // false' "$pf" 2>/dev/null || echo false)"
threshold="$(cfgk feedback_threshold)"; [ -n "$threshold" ] || threshold=3
cutoff="$(date -v-30d +%F 2>/dev/null || date -d '30 days ago' +%F 2>/dev/null || echo "")"
ff="$AD/presence-feedback.tsv"
suppressed=""; expired_ids=""
if fx "$ff"; then
  if feedback_shape_ok "$ff"; then
    suppressed="$(awk -F'\t' -v th="$threshold" -v cutoff="$cutoff" \
      'NF==5 && $3+0>=th && $4>=cutoff {print $1"\t"$2}' "$ff" 2>/dev/null)"
    expired_ids="$(awk -F'\t' -v th="$threshold" -v cutoff="$cutoff" \
      'NF==5 && $3+0>=th && $4<cutoff {print $1}' "$ff" 2>/dev/null | sort -u)"
  else
    if [ "$warned_f" != "true" ]; then
      try_emit "- presence-feedback.tsv: present but not parseable; suppression disabled this session (fix or remove it)" \
        && { tel warn feedback; warned_f=true; }
    fi
  fi
fi
```

Replace lines 84-87 (`p_matches=""; g_matches=""` through the `g_matches=`
line):

```sh
p_matches=""; g_matches=""; supp_this_firing=""
case "$tool" in Bash) export MT_EVENT=bash ;; Edit|Write|NotebookEdit) export MT_EVENT=edit ;; *) export MT_EVENT="" ;; esac
suppression_filtered_matches() {  # $1=store $2=label -- match_triggers' exact 4-col shape (hits\tid\tlabel\tstatement), suppressed pairs excluded; appends excluded pairs to supp_this_firing
  local store="$1" label="$2" pairs excl
  pairs="$(match_trigger_pairs "$store" "$haystack")"
  [ -n "$pairs" ] || return 0
  excl="$(mktemp)"
  printf '%s\n' "$pairs" | awk -F'\t' -v label="$label" -v supp="$suppressed" '
    BEGIN {
      n = split(supp, lines, "\n")
      for (i = 1; i <= n; i++) { split(lines[i], f, "\t"); if (f[1] != "") sup[f[1] SUBSEP f[2]] = 1 }
    }
    {
      if (($1, $2) in sup) { print $1 "\t" $2 > "/dev/stderr"; next }
      cnt[$1]++; stmt[$1] = $3
    }
    END { for (id in cnt) { s = stmt[id]; if (length(s) > 220) s = substr(s, 1, 220); printf "%s\t%s\t%s\t%s\n", cnt[id], id, label, s } }
  ' 2>"$excl"
  if [ -s "$excl" ]; then
    while IFS= read -r xline; do [ -n "$xline" ] && supp_this_firing="${supp_this_firing}${xline}
"; done < "$excl"
  fi
  rm -f "$excl"
}
[ -n "$pstore" ] && p_matches="$(suppression_filtered_matches "$pstore" "")"
[ -n "$gstore" ] && g_matches="$(suppression_filtered_matches "$gstore" "[global] ")"
```

Insert after line 167 (`[ -n "$recall_detail" ] && tel recall
"$recall_detail"`):

```sh
supp_this_firing="$(printf '%s\n' "$supp_this_firing" | sed '/^[[:space:]]*$/d' | sort -u)"
if [ -n "$supp_this_firing" ]; then
  supp_csv="$(printf '%s\n' "$supp_this_firing" | awk -F'\t' '{printf "%s%s:%s", (NR>1?",":""), $1, $2}')"
  tel suppressed "$supp_csv"
fi
```

Insert before line 229 (`rc_json="$(...)"`):

```sh
if [ -n "$expired_ids" ]; then
  while IFS= read -r eid; do
    [ -n "$eid" ] || continue
    recall_cache_local="$(printf '%s\n' "$recall_cache_local" | awk -F'\t' -v id="$eid" '$1!=id')"
  done <<EOF
$expired_ids
EOF
fi
```

Replace lines 235-237 (the persist `yq` call):

```sh
TC="$((tool_calls + 1))" LR="$last_reanchor" RC="$rc_json" WG="$warned_g" WP="$warned_p" WF="$warned_f" \
  yq ".tool_calls = strenv(TC) | .last_frame_reanchor = strenv(LR) | .recall_cache = (strenv(RC) | fromjson) | .warned.global = (strenv(WG) == \"true\") | .warned.project = (strenv(WP) == \"true\") | .warned.feedback = (strenv(WF) == \"true\")" "$pf" > "$pf.tmp.$$" \
  && mv "$pf.tmp.$$" "$pf"
```

Run `bash tests/run.sh` — full green, including every EXISTING
`tests/test_presence.sh` assertion (regression: unsuppressed firing
behavior is byte-identical, since `suppression_filtered_matches` produces
the exact same 4-column shape `match_triggers` always did whenever
nothing is suppressed). `shellcheck -S warning scripts/presence`.

**Commit:** `feat: adaptive suppression — presence hook filters recall by
learned (record,trigger) feedback`

Body: `Suppression filter (match_trigger_pairs-based, match_triggers
itself untouched), suppressed telemetry duty, warn-once on a corrupt
feedback file now persisted across process invocations (IMPORTANT 2
fix — the prior warned_g/warned_p pattern already had this right;
warned_f now follows the same write-back), recall_cache purged on
natural TTL expiry (MINOR 13). Perf pin held at 2.5s
(tests/test_presence.sh:255-256) with the new pass folded in. Spec
§4.5.1-4.5.3, §6 items 1-9, 12.`

### Task 5 — `scripts/retrieve`: digest line

**Role: backend.** Loads: same as Task 1.

**Source:** spec:820-855 (§4.6, exact code + gating rationale). Depends
on Task 1/2 only for fixture data, not for any code dependency —
`scripts/retrieve` deliberately does not source `store-resolve` (same
independent-reproduction choice the jit-recall spec already made for this
file, spec:829-834).

**RED** — already written and exercised by Task 4's item-6 block in
`tests/test_feedback.sh` (digest test, above) — that block IS this
task's RED evidence; re-run it in isolation to confirm it fails before
this task's GREEN lands:

```
bash tests/run.sh 2>&1 | grep -A2 "digest gate\|digest: N="
```

Expect failures (the line does not exist yet in `scripts/retrieve`'s
output).

**GREEN** — insert into `scripts/retrieve` directly after the existing
recall-coverage block (currently lines 106-115, confirmed by direct
read — the `#20` block, ending at `fi` on line 115):

```sh
FF="$AD/presence-feedback.tsv"
if [ -n "$PSTORE" ] && fx "$FF"; then
  fth="$(cfgk feedback_threshold)"; [ -n "$fth" ] || fth=3
  fco="$(date -v-30d +%F 2>/dev/null || date -d '30 days ago' +%F 2>/dev/null || echo "")"
  fn="$(awk -F'\t' -v th="$fth" -v cutoff="$fco" 'NF==5 && $3+0>=th && $4>=cutoff' "$FF" 2>/dev/null | wc -l | tr -d ' ')"
  fn="${fn:-0}"
  [ "$fn" -gt 0 ] 2>/dev/null && try_emit "- presence: $fn (record,trigger) pairs suppressed — anoti feedback list"
fi
```

Run `bash tests/run.sh` — full green. `shellcheck -S warning
scripts/retrieve`.

**Commit:** `feat: adaptive suppression — SessionStart digest line`

Body: `Gated identically to the existing recall-coverage line
(scripts/retrieve:96-97's PSTORE, scripts/retrieve:24's fx) — silent at
N=0, names the exact count, points at anoti feedback list. No new
sourced dependency (retrieve does not source store-resolve, matching the
jit-recall spec's own independent-reproduction choice). Spec §4.6.`

---

### Task 6 — `skills/policy-retrospect/SKILL.md`: rule 2 exact wording

**Role: technical-writer.** Loads: policy-reader-run,
policy-draft-for-ratification, plus the universal epistemic/
trace-to-frame/escalate-destructive stack (`roles/technical-writer.md:6-13`,
verbatim — **not** policy-adversarial-handoff, per spec's own fix-round
correction, spec:1265-1282).

**Source:** spec:445-480 (§4.3.5, exact replacement text).

**Edit:** replace `skills/policy-retrospect/SKILL.md` rule 2 (currently
lines 17-22, confirmed by direct read) in full:

```markdown
2. **What didn't** — friction, wrong turns, misleading signals — and,
   since 0.5.24, **which presence injections were irrelevant**: count
   them, and name each one you can identify — by record id, and by its
   trigger too when you can tell which trigger on that record actually
   fired (the `presence recall <id>[label]` telemetry line names the
   record; if only one of its triggers could plausibly match the tool
   call that just ran, name it — otherwise leave the trigger off rather
   than guess, since a wrong trigger name silently suppresses the wrong
   cue). Record via `scripts/mark-retrospect <sid> <empty|filed>
irrelevant-injections N [<id>[:<trigger>] ...]` — N is still the raw
   count the precision metric reads; the trailing tokens are what
   adaptive suppression (docs/specs/2026-08-19-adaptive-suppression-design.md)
   learns from: an `id:trigger` pair accumulates toward silencing that
   exact pairing after three marks within 30 days, an id alone is audit
   trail only. A lesson id (`L:<hash>`) can never be named this way —
   lessons carry no `triggers:` of their own, so there is no pairing to
   suppress; naming one is silently rejected with a warning, not written.
   Cite the moment. A retrospective that finds no friction in
   nontrivial work is suspect, not clean.
```

Verify verbatim against spec:461-480 (character-for-character; this is
the load-bearing D025 obligation and the exact text the reviewer checks
per spec:1291-1298). `bash tests/run.sh` — full green (no test currently
pins this file's exact wording; the reviewer's own pass is the
verification per spec's Execution routing).

**Commit:** `docs: adaptive suppression — retrospect policy names
id[:trigger] pairs`

Body: `Rule 2's wording (spec §4.3.5) applied verbatim: the retrospective
now names which trigger fired, not only a count, feeding
scripts/mark-retrospect's extended grammar (Task 3). Lesson-id rejection
noted explicitly.`

### Task 7 — `skills/consolidate/SKILL.md`: step 2b addendum (plan-owner addition)

**Role: technical-writer.** Loads: same as Task 6.

**Deviation flagged (labeled judgment, not in spec's own §9 file
list):** the spec's Execution routing (§9) names four technical-writer
targets — `skills/policy-retrospect/SKILL.md`,
`docs/specs/2026-08-13-exp-longitudinal.md`, `skills/demo/SKILL.md`,
`docs/SKILL-MAP.md` — and does **not** list `skills/consolidate/SKILL.md`.
The dispatch brief for this plan explicitly names "consolidate quick-ref"
as a technical-writer target, so this task exists to honor that
instruction; grounding it in the spec's own spirit rather than inventing
scope: step 2b (`skills/consolidate/SKILL.md:74-83`) already teaches "a
cue that proves noisy is removed with `scripts/remove-trigger` and
re-cued" — the one-sentence addendum below completes that same thought
with the mechanical alternative this spec adds, matching D025's own
"surfaces that teach it" standard (`GROUNDING.yaml:500`) even though this
specific file was not itemized. Flagged again in Questions/doubts for the
reviewer to weigh.

**Edit:** `skills/consolidate/SKILL.md`, insert after the existing
sentence at line 78 (`A cue that proves noisy is removed with
`scripts/remove-trigger` and re-cued.`), before `Skip silently for
candidates with no natural`:

```markdown
A cue that fires but keeps producing irrelevant injections quiets
itself mechanically after three retrospective marks within 30 days
(adaptive suppression, `docs/specs/2026-08-19-adaptive-suppression-design.md`)
without any edit here — `scripts/anoti feedback list`/`clear` shows and
reverses it; `remove-trigger` stays the permanent fix for a trigger
that is simply badly authored.
```

`bash tests/run.sh` — full green (prose-only change, no test currently
pins this file's exact wording).

**Commit:** `docs: adaptive suppression — consolidate step 2b notes the
mechanical un-cueing path`

Body: `Not in the spec's own §9 file list (docs/specs/2026-08-19-
adaptive-suppression-design.md §9 names four technical-writer targets,
not this one) — added per this plan's own dispatch brief and D025's
"surfaces that teach it" standard; flagged to the reviewer as a
plan-owner addition, not spec-mandated text.`

### Task 8 — `skills/demo/SKILL.md`: routing row

**Role: technical-writer.** Loads: same as Task 6.

**Source:** spec:186 (component map row), spec:1248-1250 (suggested
wording).

**Edit:** insert a new row into the "When to use what" table
(`skills/demo/SKILL.md:40-56`), immediately after the existing
`append-trigger (consolidate step 2b)` row (currently line 48, confirmed
by direct read):

```markdown
| Injections keep firing at the wrong moment | `anoti feedback list`, `clear <id> [trigger]` | see and undo what adaptive suppression has silenced — mechanical, reversible, learned from three retrospective marks within 30 days; `remove-trigger` is the permanent fix for a badly-authored cue |
```

`bash tests/run.sh` — full green.

**Commit:** `docs: adaptive suppression — demo routing row for anoti
feedback`

Body: `D025 obligation (GROUNDING.yaml:500): the demo skill's routing
table is updated in the same change that ships the feature, not in a
later reminder. Spec §9, component map row (spec:186).`

### Task 9 — `docs/SKILL-MAP.md`: entry-point row

**Role: technical-writer.** Loads: same as Task 6.

**Source:** spec:186 (component map), spec §9's "new entry-point row...
alongside the existing presence-hook row" (spec:1251-1253).

**Judgment call (flagged, mirrors Task 7's flagged deviation):** the spec
names the insertion point ("alongside the existing presence-hook row,
`docs/SKILL-MAP.md:16`") without supplying exact new-row text (unlike
Tasks 6/10, which quote the spec verbatim). This task adds one new row
for `scripts/feedback` as its own entry point (the CLI surface is a root
a human reaches directly, same class as the existing "Human commands"
row) and extends the presence-hook row's own "Leads to" column, since
presence's behavior genuinely changed. The technical-writer/reviewer may
reasonably word either differently; the reviewer should confirm accuracy,
not exact phrasing (mirrors the license the jit-recall plan's own Task 22
README wording already took, `docs/plans/2026-08-19-jit-recall-implementation.md:2069-2075`).

**Edit:** `docs/SKILL-MAP.md`, "Entry points (roots)" table. Extend the
existing presence-hook row (line 16) and insert one new row directly
after it:

```markdown
| PostToolUse/PostToolUseFailure hook (`presence`) | matched tool calls (Bash/Write/Edit/NotebookEdit) | JIT recall (filtered by adaptive suppression); periodic frame re-anchor; evidence-kind nudge; telemetry |
| `scripts/feedback` (list/clear) | on demand, or via `mark-retrospect`'s named pairs | inspect/undo adaptive suppression — presence-feedback.tsv (project-level, gitignored) |
```

`bash tests/run.sh` — full green, including
`tests/test_reachability.sh` if it enumerates this table's rows (spot-
check: `grep -c '^|' docs/SKILL-MAP.md` before/after to confirm exactly
one net new row, not an accidental duplicate).

**Commit:** `docs: adaptive suppression — SKILL-MAP entry-point row`

Body: `New root for scripts/feedback, alongside the presence-hook row it
extends (spec §9, component map spec:186). Exact wording is this plan's
own drafting, not spec-mandated — flagged in Questions/doubts.`

### Task 10 — `docs/specs/2026-08-13-exp-longitudinal.md`: dated amendment

**Role: technical-writer.** Loads: same as Task 6.

**Source:** spec:873-1002 (§4.8, §4.9 — exact replacement text, exact new
changelog entry, exact new KEEP/telemetry-only/REVERT subsection).

**Edit 1 — §4.8 replacement.** The current Presence-precision bullet
(`docs/specs/2026-08-13-exp-longitudinal.md:90-98`, confirmed by direct
read) is replaced verbatim with spec:897-908's text — the load-bearing
change: "AFTER the mechanical precision measures... have shipped" becomes
"AFTER adaptive suppression... has shipped and two audited weeks have
passed."

**Edit 2 — new changelog entry**, appended after the existing 2026-08-19
entries (currently ending at line 148, confirmed by direct read),
verbatim per spec:913-925.

**Edit 3 — new §4.9 subsection**, appended immediately after the
replaced Presence-precision bullet inside the Tier-1 gate section
(`docs/specs/2026-08-13-exp-longitudinal.md:76-108`), verbatim per
spec:927-1002 — the three-way KEEP/telemetry-only/REVERT rule, including
the **primary/fallback baseline-window logic** (this repo has zero
pre-ship audited weeks as of 2026-08-19, since the audit cadence's own
first date is 2026-08-20 — the fallback path is not a hypothetical, it is
the path this ship will actually take; see Risks).

`bash tests/run.sh` — full green (no test currently pins this file's
prose; `docs/specs/2026-08-13-exp-longitudinal.md`'s own Execution
routing, spec:150-157, has no mechanical gate on this text — the
reviewer's pass is the verification, per spec's own Execution routing
choice).

**Commit:** `docs: adaptive suppression — longitudinal spec Q006 gate
reorder + KEEP/telemetry-only/REVERT criterion`

Body: `Per skills/spec/SKILL.md's amendment rule (dated changelog, never
a silent edit) — this file's own established precedent
(docs/specs/2026-08-13-exp-longitudinal.md:120-148). Q006's gate now
names adaptive suppression specifically instead of "the mechanical
measures" generically; three outcomes (not two) close the loop MINOR 12
found underspecified. Spec §4.8, §4.9.`

### Task 11 — CHANGELOG draft text (deliverable, not a file edit)

**Role: technical-writer.** Loads: same as Task 6.

**Why this task does not touch `CHANGELOG.md`:** technical-writer's
worktree contains only its own diff — not backend's — so it cannot write
an honest release paragraph describing the _shipped_ feature (and cannot
know whether fix rounds changed anything) without either reading
backend's worktree on disk (fine, read-only) or waiting for the reviewer
verdict (safer — avoids drafting text for code that a fix round then
changes). This task's **output is text in this spawn's final report**,
handed to the dispatching session, which applies it in Task 13 once both
worktrees are COMPLIANT.

**Deliverable (drafted now, applied later verbatim unless the fix rounds
change what shipped):**

```markdown
- Adaptive suppression: a project-level feedback cache
  (`presence-feedback.tsv`) that lets the presence hook learn which
  `(record, trigger)` pairs the retrospective has named irrelevant three
  times within 30 days and stop injecting exactly those pairs — visibly
  (`anoti feedback list`, a new digest line) and reversibly (`anoti
feedback clear <id> [trigger]`) — while every other trigger on the
  same record keeps firing. `scripts/mark-retrospect` grows an additive
  grammar to name pairs (`irrelevant-injections N [<id>[:<trigger>]
...]`); a mistyped or lesson id is inert, never guessed into a
  suppression write. The longitudinal spec's Q006 re-ranker gate now
  requires adaptive suppression specifically (not just "the mechanical
  measures") plus two full audited weeks, and gains its own
  pre-registered KEEP (≥15pt precision gain)/telemetry-only/REVERT
  (≥10pt regression) criterion.
```

No RED/GREEN cycle (report-only deliverable, not a code or file
edit — technical-writer does not declare policy-test-driven,
`roles/technical-writer.md:6-13`).

### Task 12 — Reviewer pass over the whole diff

**Role: reviewer.** Loads: epistemic, trace-to-frame,
escalate-destructive (`roles/reviewer.md:6`) — no test-driven/
adversarial-handoff on the reviewer itself, per spec:1303-1305.

**Scope (spec:1283-1305):** one reviewer spawn, both builders' diffs,
read directly from their still-alive worktrees (`git -C
<backend-worktree-path> diff adaptive-suppression`, same for
technical-writer's) — **no merge before this review**, per Spawn
arithmetic. Verifies specifically:

- Every §6 test (Tasks 1-5's RED blocks) actually exercises what it
  claims — re-running RED before GREEN in a scratch copy where a
  transcript is ambiguous (`roles/reviewer.md:24-30`'s optional
  technique), same discipline jit-recall's own reviewer task already
  required (`docs/plans/2026-08-19-jit-recall-implementation.md:1957-1963`).
- The awk multi-dim `(id,trig) in sup` membership test and the
  `ENVIRON`-vs-`-v` discipline in Task 4's `suppression_filtered_matches`
  are correctly and _literally_ executed against a constructed fixture,
  not trusted from the spec's own "illustrative, not execution-verified"
  code (spec:309-316) or this plan's own restatement of it.
- The perf test (Task 4 item 9) actually re-measures at scale rather than
  assuming spec:318-328's cost estimate holds.
- `mark-retrospect`'s backward-compatibility claim (Task 3, §8 item 6) is
  checked by diff against `tests/test_helpers.sh:817-823`'s existing,
  unmodified assertions — not by re-reading the code and agreeing it
  looks right.
- Task 2's trap-restore fix (the deviation from spec:744-754's own
  illustrative purge loop) is sound — the outer `$ff` lock is genuinely
  released on every exit path, not just the happy path.
- The coupling the spec's own Questions/doubts names (`scripts/feedback
clear` mutating `scripts/presence`'s session-state shape directly under
  store-lock, spec:1316-1321) is confirmed scoped correctly: the purge
  touches only `.recall_cache[<id>]`, never any other key in
  `*.presence.yaml`.
- Every §4.3.5/§4.8/§4.9 wording block (Tasks 6, 10) landed **verbatim**,
  not paraphrased — diffed character-for-character against the spec.
- Task 7's and Task 9's flagged deviations (consolidate quick-ref not in
  spec's own file list; SKILL-MAP row wording not spec-mandated) are
  reasonable and accurately describe what shipped.

**Output:** findings report, `{file, lines}` evidence + severity
(Critical/Important/Minor), spec-compliance verdict. **No edits** — the
reviewer never fixes; findings return to the originating spawn (still
alive, in its own worktree) via SendMessage.

### Task 13 — Fix rounds (conditional) + release 0.5.26 + final integration

**Role:** whichever spawn (backend or technical-writer) owns the flagged
file — **resumed via SendMessage into its still-alive worktree, never a
fresh spawn** (D011, `skills/deliberate/SKILL.md:85-93`), capped at 3
cycles (mirrors spec:1307-1312). A blocker surviving three rounds
returns to the human as a design decision, not a fourth attempt. The
release edit and integration mechanics below are performed **by the
dispatching session directly, not a new spawn** — reasoning in Spawn
arithmetic (needs both worktrees' combined diff; architect cannot
implement).

**Once the reviewer's findings are fixed or explicitly adjudicated
(COMPLIANT verdict):**

1. Apply Task 11's drafted CHANGELOG paragraph — new section prepended
   above the current `## [0.5.25]` in `CHANGELOG.md`, headed `## [0.5.26]
— 2026-08-19` (or the actual ship date if it slips past today).
2. Bump `.claude-plugin/plugin.json` `.version` and
   `.claude-plugin/marketplace.json` `.version`/`.plugins[0].version` to
   `0.5.26` (mirrors jit-recall's own Task 24 mechanics,
   `docs/plans/2026-08-19-jit-recall-implementation.md:1912-1915`):

   ```bash
   jq '.version = "0.5.26"' .claude-plugin/plugin.json > t && mv t .claude-plugin/plugin.json
   jq '.version = "0.5.26" | .plugins[0].version = "0.5.26"' .claude-plugin/marketplace.json > t && mv t .claude-plugin/marketplace.json
   ```

   RED first: `jq -e --arg v "0.5.26" '.version == $v' .claude-plugin/plugin.json` fails before the edit, passes after; same for
   `marketplace.json` (both fields) and `grep -q "^## \[0.5.26\]" CHANGELOG.md`.

3. Merge both worktree branches into `adaptive-suppression` (disjoint
   files, so a plain merge is conflict-free by construction — verify
   with `git diff --name-only` on each branch against
   `adaptive-suppression` before merging, confirming zero file overlap,
   which Architecture already established but is re-verified here as
   fact, not assumed): `git merge --no-ff <backend-branch>` then `git
merge --no-ff <technical-writer-branch>` into `adaptive-suppression`,
   then this plan's own two edits (steps 1-2) as a final commit on
   `adaptive-suppression` itself.
4. `bash tests/run.sh` — full suite, on the exact merged tree (per
   `skills/git/SKILL.md`'s "the suite runs green on the exact tree being
   integrated — a green run only proves the tree it ran on").
5. `shellcheck -S warning` over every changed `scripts/*` file (CI's own
   lint scope, `.github/workflows/ci.yml:47`) — zero warnings.
6. `jq empty hooks/hooks.json` — confirm untouched (this spec adds no
   hook registration, constraint 1).
7. **NOW, only now: remove both builder worktrees** (per
   `LESSONS-LEARNT.md:71`: "remove worktrees at the end of the cascade,
   not at merge" — merge already happened in step 3; this is the
   cascade's actual end).
8. **Human integration gate** (per `skills/git/SKILL.md`'s "Finishing a
   branch" section, verbatim procedure): present the options — merge
   `adaptive-suppression` into `main` locally / push for PR / keep as-is
   — and wait. Never merge, push, or delete on inference. After a
   ratified local merge: delete the merged branch, run the suite once
   more on the merged result.
9. Do not force-push; do not add attribution trailers unless the human
   explicitly asks (per the user's own global CLAUDE.md rule on
   `Co-Authored-By:` trailers — preserve, never strip, never add
   unprompted).

---

## Risks and conditional branches

| Risk                                                                                                                                                                                                                                                         | Fallback                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Worktree base-ref uncertainty** (Spawn arithmetic) — the Agent tool's `isolation: "worktree"` base-branch behavior is not independently confirmed to match the invoking session's current branch rather than `origin/main`                                 | Each builder's first action verifies `git merge-base --is-ancestor adaptive-suppression HEAD`; if false, rebase/reset onto `adaptive-suppression` before any edit. Low-probability today (`adaptive-suppression` == `main` at plan-filing time, verified `{command: "git rev-parse adaptive-suppression main", output: identical hashes}`) but named rather than assumed.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| **bash 3.2** (macOS's shipped `/bin/bash`, shebang-pinned regardless of a homebrew bash on PATH — the same constraint jit-recall's own presence code already works around, `scripts/presence:116-125`)                                                       | No new pitfall class: this plan's GREEN code introduces zero `declare -A` usage anywhere (`scripts/feedback`, the presence additions, mark-retrospect's pair loop all use `cut -f`/`awk -F'\t'`/POSIX parameter expansion only). If a bash-3.2-specific failure surfaces anyway during Task 1-5's own `bash tests/run.sh` runs (which execute under `/bin/bash` on the dev machine), substitute the established TSV+awk idiom — the same fix already applied once for `recall_cache_local`.                                                                                                                                                                                                                                                                                                                                                                                             |
| **awk dialect divergence** (gawk vs. mawk vs. BSD awk — the multi-dim `(id,trig) in sup` test, `ENVIRON`, `substr`, `index`, `tolower` in Task 1's `match_trigger_pairs` and Task 4's `suppression_filtered_matches`)                                        | No new primitive class beyond what jit-recall's own Task 15 already verified across docker ubuntu (gawk) and macOS — spec:130-141 cites the exact verification transcripts for the primitives this spec reuses (§4.5.2's own `(a,b) in sup` transcript, spec:687-690). Reviewer (Task 12) re-executes the multi-dim test against a constructed fixture as part of its own scope, not trusted from prose. If CI's Linux job or a spot-check (`docker run --rm -v "$PWD":/w -w /w ubuntu:24.04 sh -c 'apt-get -qq update && apt-get -qq install -y gawk yq jq >/dev/null && bash tests/run.sh'`) diverges: (a) minimal portable rewrite avoiding the divergent construct first; (b) escalate to the human as a design decision (pin gawk vs. rewrite) rather than ship silently divergent behavior, mirroring jit-recall's own Risks table resolution for the identical class of problem. |
| **The acknowledged coupling** (spec's own Questions/doubts: `scripts/feedback clear` mutates `scripts/presence`'s session-state shape — `recall_cache` in `*.presence.yaml` — directly, under `store-lock`, rather than behind a shared helper)              | Accepted for this build as verified-working (spec's own framing) — Task 12's reviewer scope explicitly re-confirms the purge touches only `.recall_cache[<id>]`. **Named condition for revisiting:** if `*.presence.yaml`'s shape changes in a future spec, the purge logic in `scripts/feedback clear` must move behind a shared helper in `store-resolve` so the shape keeps one owner — filed as a TODOS entry at consolidation time (not built speculatively now), flagged for the plan owner per the spec's own instruction (spec:1316-1321), not silently absorbed.                                                                                                                                                                                                                                                                                                               |
| **The no-pre-ship-baseline case** (§4.9's fallback) — this repo's audit cadence starts 2026-08-20, one day after this spec was filed (2026-08-19); this feature will very likely ship with **zero** completed pre-ship audited weeks to draw a baseline from | Task 10 lands §4.9's fallback path verbatim (spec:940-963): baseline becomes the first two POST-ship audited weeks instead of the two weeks immediately before ship, post-ship window becomes weeks 3-4, and the whole comparison is explicitly relabeled a **within-post-ship** measurement carrying **weaker inference**, stated as such wherever cited — not silently treated as a clean before/after comparison. No code branch needed; this is a measurement-protocol fact for the eventual `/anoti:audit` runner to apply, already fully specified in the text this task lands.                                                                                                                                                                                                                                                                                                   |
| **Fix round exhausts context in a long-running builder spawn** (backend's task list is 5 sequential tasks in one spawn, largest single-spawn risk per Spawn arithmetic)                                                                                      | Resume the same spawn via SendMessage with the task list + completed-so-far state (never a fresh spawn losing the dependency-chain context or the worktree) — the same D011 resume discipline used for fix rounds applies here too.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| **`suppression_filtered_matches`'s stderr-as-data-channel** (Task 4's GREEN code follows the spec's own §4.5.2 illustrative shape, which the spec itself flags as one possible implementation, not mandated, spec:1347-1358)                                 | Free substitution if the backend builder or reviewer finds a cleaner shape (e.g., two separate awk passes over a captured variable) — the **contract** (excluded pairs are excluded from `cnt[id]`, and available for telemetry) is what Task 12 checks, not this literal mechanism.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |

## Out of scope (mirrors spec §7)

- The re-ranker (Q006) itself — this spec is the mechanical rung Q006's
  own gate requires be exhausted first.
- Lesson (`L:` id) suppression — no independent `(lesson, trigger)`
  pairing exists; `matched_trigs`/the lessons piggyback path
  (`scripts/presence:89-105`) are unmodified.
- Cross-store id disambiguation — the feedback keyspace is bare
  `record_id`, not `(scope, record_id)` (named, accepted risk, spec §4.2,
  §7, Questions/doubts).
- Garbage collection of expired rows — soft expiry only; no row is ever
  deleted for aging out, only for an explicit `clear`.
- A bare `anoti feedback clear` (clear-everything) form — `rm
<state-dir>/presence-feedback.tsv` is the equivalent, already available.
- Validating that a named record id exists in a store at mark-time — a
  mistyped id is inert, not dangerous (spec §4.3.4 point 4).
- Amending Q006's own `GROUNDING.yaml` record text (`GROUNDING.yaml:552`)
  — architect cannot write GROUNDING.yaml (advisory boundary); named as a
  follow-up for the eventual consolidation step (spec §7, Questions/doubts).

## Questions/doubts

- **Task 7 (`skills/consolidate/SKILL.md` step 2b addendum) is not in the
  spec's own §9 Execution-routing file list** — I added it because this
  plan's own dispatch brief named "consolidate quick-ref" explicitly as a
  technical-writer target. I grounded the actual edit in D025's spirit
  rather than inventing arbitrary text, but the reviewer should weigh
  whether this is scope the spec's author would have wanted, or scope
  creep this plan should have pushed back on and asked about instead of
  silently accommodating.
- **Task 9's SKILL-MAP row wording is this plan's own drafting**, not
  spec-mandated exact text (unlike Tasks 6/10, which quote the spec
  verbatim) — the spec names the insertion point but not the row's
  content. Reasonable-on-its-face, flagged for the reviewer to confirm
  accuracy rather than phrasing.
- **I did not myself execute `match_trigger_pairs` or
  `suppression_filtered_matches` before writing this plan** — both carry
  the spec's own "illustrative, not execution-verified" label
  (spec:309-316) and this plan restates that code with only the
  adjustments needed to fit the real, current file (exact line numbers,
  the trap-clobber fix in `scripts/feedback clear`, the persist-step
  ordering for `expired_ids`). The backend builder's RED/GREEN transcript
  (Task 1, Task 4) is the actual verification artifact; this plan's code
  is a design, not a claim of tested behavior.
- **The worktree-base-ref risk (Spawn arithmetic) is a genuine unknown at
  plan-filing time** — I could not find documentation confirming whether
  the Agent tool's `isolation: "worktree"` branches from the invoking
  session's current HEAD or from `origin/<default-branch>` by default
  (EnterWorktree's own docs state the latter as its default, but that is
  a different tool). I judged the mitigation (each builder verifies its
  own worktree's ancestry as its first action) sufficient rather than
  blocking the plan on this uncertainty, since `adaptive-suppression`
  currently equals `main` and the check is cheap. If the dispatching
  session finds the harness behaves differently, this is the first
  actual confirmation either way.
- **Task 13's release-and-integration mechanics assume a plain,
  conflict-free merge of two disjoint-file branches** — I did not
  execute this merge myself (no code exists yet to merge). If either
  builder's fix rounds touch a file outside its originally-assigned set
  (a plausible fix-round side effect, e.g. a shellcheck fix in a file
  neither builder was assigned), the disjointness assumption could break
  and a real merge conflict could occur — in which case the dispatching
  session resolves it directly (both diffs are visible, human-readable,
  and small) rather than escalating, unless the resolution itself is
  ambiguous, in which case it escalates per policy-escalate-destructive.
- **I did not independently re-verify that `T001`'s two triggers (`"cd
chain"`, `"cd &&"`) in `tests/fixtures/store_triggers.yaml` are
  sufficiently distinct substrings for the item-4/item-7 tests I wrote**
  — I confirmed by direct read that both strings are present in the
  fixture as shipped (`tests/fixtures/store_triggers.yaml:181`), but did
  not execute the actual `match_trigger_pairs` awk pass against them
  before writing this plan (see the prior doubt). If `"cd &&"` interacts
  oddly with awk's field-splitting or shell quoting inside a JSON
  `tool_input.command` string, Task 4's own RED step is where that
  surfaces, not assumed clean here.
