# Review Debt — Design Spec

**Date:** 2026-08-19
**Status:** DESIGN, filed 2026-08-19 — not yet reviewed. Per
`skills/spec/SKILL.md` ("specs of consequence get adversarial review
before done"), this is built on a branch and merges only after a skeptic
pass; the spec's own status line is a claim, not evidence (G005).

## 1. What this is

A small ledger that turns the adversarial-review obligation from prose
into tracked, aged, visible debt. Today `policy-adversarial-handoff`
says finished builder work "goes to a reviewer spawn before it counts as
done" and that work merged without its handoff "is reopened" — and
nothing records that a review is owed, nothing surfaces it, nothing
fires at the moment of integration. The consolidation obligation, by
contrast, has a Stop-gate (`scripts/consolidation-gate`). This spec gives
the review obligation the same three things memory already has for
everything else: a mechanical ledger (`scripts/review-debt`), a digest
line at session start, and two moment-of-use gates — the Stop hook
blocks once while debt created this session is still open, and the
inhibition hook `ask`s on integration while any debt is open. The only
way to make debt go quiet without a review is to **defer it with a
written reason** — a recorded decision, not a silent skip.

## 2. Why

- **D026** (claim, speculative, field retrospective 2026-08-19): a
  policy that exists only as prose is self-graded in practice — three
  reviews owed, flagged four times, done zero times, in one consumer
  session; the same session's gated/triggered mechanisms (C042 via the
  presence hook, G004) changed behaviour repeatedly.
- **D023** (claim, probable): when reviews _do_ run they catch real,
  execution-verified defects before integration. D026 refines D023: the
  value is real and the policy doesn't get run without a mechanism.
- **D025** (policy): "a gate beats a nudge (house ordering)" — the
  enumerable part gets a gate, the judgment-shaped rest gets a cue.
- **D024** (decision): pending.md is the single _human-decision_ surface.
  Review debt is an obligation of the agent, not a decision awaiting the
  human, so it does **not** queue in pending.md; the digest is where the
  human sees it. (Judgment: a second human-decision queue would violate
  D024; a state-dir ledger surfaced by the digest does not.)
- **US-002** (hooks stay silent unless they have something to say):
  every new surface is silent when the ledger is empty.

Labeled hypothesis (not a claim): making the skip cost a written
reason will reduce silent skips. The longitudinal audit measures it
(§4.7); nothing here asserts the outcome.

## 3. Design principles / constraints

- Fail-open everywhere: a missing, unreadable, or malformed ledger
  means no block, no ask, no digest line (and a one-line stderr warning
  from the helper only).
- ≤ 5 s per hook firing; the hook paths read one small TSV with awk.
- Helpers are the only writers (`scripts/review-debt`); the ledger is
  never hand-edited; every write is under `store-lock`.
- Portability rules of the house: bash 3.2, BSD/GNU awk/grep/date, no
  `declare -A`, `cut -f`/awk over `IFS=tab read`.
- Silent when empty (US-002); block **once** per session (the
  consolidation-gate pattern); deferral requires a non-empty reason.
- Closed rows are kept (audit trail for the deferral metric); only
  `open`/`deferred` rows count as debt.

## 4. The design

### 4.1 The ledger: `<state-dir>/review-debt.tsv`

Project-level, gitignored (same class as `presence-feedback.tsv`). One
row per obligation, seven tab-separated columns, no header:

```
id    created    session    subject    status    status_date    note
R1    2026-08-19 60267002…  docs/specs/us-172-x.md    open      2026-08-19
R2    2026-08-19 60267002…  batch: feedback helper    deferred  2026-08-19  reason text
```

- `id`: `R<n>`, n = max existing + 1 (never reused).
- `status` ∈ `open | deferred | closed`; `status_date` is the date of the
  last status change; `note` is the defer reason or the close note
  (tabs/newlines in subject/note are flattened to single spaces on
  write, the existing prose-appender rule).
- Shape check on every write (`review_debt_shape_ok`: every line has
  exactly 7 fields, `$1 ~ /^R[0-9]+$/`, `$5` in the status set); a
  failed check leaves the file untouched and exits 1.

### 4.2 `scripts/review-debt` — the single reader/writer

```
review-debt add <session-id> <subject...>     # open a row; same open/deferred subject → prints the existing id, no duplicate
review-debt list                              # table: id created session subject status status_date note
review-debt close <id> <note...>              # → closed (the reviewer's verdict or its ref); refuses unknown ids and already-closed rows
review-debt defer <id> <reason...>            # → deferred + reason; refuses unknown/closed rows and an empty reason
review-debt observe                           # hook mode: PostToolUse JSON on stdin (see 4.3); silent, fail-open
```

`add`/`close`/`defer` require an anchored workspace (`anoti-dir
--require`, G003) and print the affected id on success. `list` degrades
gracefully (prints a one-line "no review-debt.tsv yet" and exits 0).
Telemetry: `review-debt  add|close|defer|observe  <id> <subject>` rows
in `<state-dir>/telemetry.log` (the verb is the subcommand that ran —
`observe` for the mechanical add), same five-column shape as every
other writer; the Stop gate adds `review-debt  block  <ids>`. Reachable as `anoti review-debt …` through the dispatcher.

### 4.3 Mechanical add on spec filing (`observe`)

A second PostToolUse hook entry, matcher `Write`, command
`scripts/review-debt observe`. When the written path is a `.md` file
directly under the project's spec dir (`cfgk spec_dir`, default
`docs/specs`) it opens a row with subject = `<spec_dir as configured, minus any
leading ./ and trailing />/<basename>` (so `docs/specs/us-172-x.md` by
default; absolute when `spec_dir` is absolute); a re-Write of a spec
whose row is open/deferred is a no-op. The project root is the
anchoring marker directory (`anoti-dir --root`), never the parent of a
configurable `state_dir` (D016). Why Write
only: Write is how a spec is filed or rewritten wholesale; Edit is how
it is touched — the field report's failure mode is "spec filed, never
reviewed", and an Edit-triggered add would re-open debt on every
wording fix. Why not builder batches: nothing mechanical marks "this
batch is ready for review"; that add stays procedural (4.6) and is the
part D026 warns about — the gates below still bite once the row exists,
and the retrospective counts reviews skipped without a row.

### 4.4 The Stop gate: block once while this session's debt is open

In `scripts/consolidation-gate`, after the existing consolidation logic
and only when it did not itself block: if `review-debt.tsv` has rows
with `session == this session` and `status == open`, and the marker
`<state-dir>/sessions/<sid>.review-debt-blocked` does not exist → create
the marker, log `review-debt block <ids>`, and return
`{decision: block, reason: …}` naming the ids and subjects with the two
ways out: run the reviewer and `anoti review-debt close <id> "<verdict>"`,
or `anoti review-debt defer <id> "<reason>"`. The existing
`stop_hook_active` short-circuit stays first, so a session already
continuing from a block is never blocked again in the same stop
sequence; the marker bounds it to once per session regardless.
Deferred rows never block (the decision is recorded). Other sessions'
open rows never block this session (they surface in the digest).

### 4.5 The inhibition hook: `ask` at integration while debt is open

In `scripts/inhibit`'s Bash branch, before the generic ask row: if the
command contains `git merge` (any segment) while the current branch is
the default branch, or contains `git push` or `gh pr merge` on any
branch (a PR merges into its base wherever you stand), **and**
the ledger has ≥ 1 `open` row (any session — the project's debt) →
`ask` with reason `N adversarial review(s) owed: R1 <subject>; R2 … —
review (anoti review-debt close) or defer with a reason (anoti
review-debt defer) before integrating`. Telemetry `inhibit ask …` as
today. Deferred rows do not re-ask (the human already has the reason in
the digest); `deny` is deliberately not used — inhibit cannot reliably
know that a given push is _the_ integration of _that_ work, and a
guardrail whose predicate cannot discriminate is worse than none (G004).

### 4.6 Skills — wording changes (the semantics bind; the text may be extended)

- `policy-adversarial-handoff` step 1: "…report it as _ready-for-review_,
  not done, **and open the row: `anoti review-debt add <session-id>
"<subject>"`**"; step 4: "…explicitly adjudicated by the main session
  **— close the row: `anoti review-debt close <id> "<verdict>"`; a
  review that will not happen now is deferred with a written reason
  (`defer`), never left silent**"; violation handling: "…self-review
  never substitutes for the adversarial pass. **Open rows block the
  Stop hook once and make integration ask; the digest ages them.**"
- `spec` skill Rules: the last rule gains "— filing a spec under
  `spec_dir` opens a review-debt row mechanically (the PostToolUse hook);
  it closes when the review lands."
- `deliberate` step 8: "builder roles per task … ready-for-review opens
  a review-debt row (policy-adversarial-handoff)".
- `policy-retrospect` question 2: "…and **review debt left open or
  deferred this session** (`anoti review-debt list`) — name each row".
- `demo` routing table: one row, _Work is "done" but unreviewed_ →
  `anoti review-debt list|close|defer` → why.
- `docs/SKILL-MAP.md` entry-point row for `scripts/review-debt`, directly
  after the `scripts/feedback` row; README helper sentence.

### 4.7 Visibility and measurement

- Digest (core `emit`, not `try_emit`): `- review debt: N open, M
deferred — oldest YYYY-MM-DD (anoti review-debt list)` when N+M > 0;
  silent otherwise.
- Longitudinal spec: dated changelog entry adding three telemetry-only
  metrics per weekly audit — open-row age (max days), rows deferred /
  rows opened, rows closed / rows opened. No decision rule changes;
  D026 moves on the ladder only through /anoti:review with this data.

## 5. Failure behavior

Missing ledger → every surface silent. Malformed ledger → helper writes
refuse (shape check) and say so; hooks treat it as empty and stay
silent (fail-open) — `list` prints the parse warning. Lock contention →
the writer waits up to the store-lock timeout then exits 1 with a
message; the read-only hook paths (Stop gate, inhibit, digest) never
take the lock; the one hook-side writer, `observe`, waits at most ~2 s
(`STORE_LOCK_MAX_TRIES=40`) and then drops the add silently inside the
5 s budget. A malformed ledger means _any_ non-empty line failing the
shape rule: the hooks then treat the whole file as empty, and the
helpers refuse to write through it — both surfaces agree. A hook crash
or timeout
never blocks a tool call or a stop (exit 0 / no decision). What never
breaks: the Stop gate can block at most once per session for debt; the
consolidation block keeps precedence.

## 6. Testing

`tests/test_review_debt.sh`, all in scratch workspaces:

1. add/list/close/defer: ids allocate R1, R2; duplicate open subject
   returns the existing id; close refuses unknown and closed; defer
   refuses empty reason and closed rows; shape check refuses a corrupt
   file and leaves it untouched; telemetry rows written.
2. observe: Write under `docs/specs/*.md` adds a row; Edit does not;
   Write elsewhere does not; a custom `spec_dir` is honoured; re-Write
   of an open subject is a no-op; non-anchored dir is silent.
3. Stop gate: open row from this session → block once (marker created,
   reason names the id), second Stop → no block; deferred row → no
   block; another session's open row → no block; consolidation block
   takes precedence; `stop_hook_active` → no block; malformed ledger →
   no block.
4. inhibit: `git merge` on a default branch with open debt → ask naming
   the id; same with no debt → no decision (falls through to today's
   rows); `git merge` on a feature branch → no debt ask; `git push` with
   open debt → ask with the debt reason; deferred-only → no debt ask.
5. digest: open+deferred counts and oldest date; silent when empty.
6. hooks.json wires `review-debt observe` on PostToolUse matcher `Write`
   with timeout 5; existing presence wiring unchanged; `anoti help`
   lists review-debt; SKILL-MAP and demo rows present (currency gate).

## 7. Out of scope

- Mechanical detection of "builder batch ready for review" (no reliable
  signal; stays procedural).
- A `deny` at integration (G004 — see 4.5).
- Cross-project or global review debt; TTL/auto-expiry of open rows
  (debt is meant to age visibly, not disappear).
- Queuing review debt in pending.md (D024 — not a human decision).
- Time-triggered reminders (parked TODO; separate trigger family).

## 8. Success criteria

- A spec filed by Write in `spec_dir` shows up in `anoti review-debt
list` as open without the model doing anything.
- A session that opened debt and tries to stop is blocked exactly once
  with the id and both exits named; deferral requires a reason.
- `git merge`/`git push` with open debt produces an `ask` whose reason
  names the owed subjects; with deferred-only or no debt, today's
  behaviour is unchanged.
- Digest shows the counts and oldest date; hidden when empty.
- Suite green on macOS and Ubuntu; skeptic review COMPLIANT or residue
  adjudicated; CHANGELOG 0.5.27 + demo/SKILL-MAP/README updated (D025).

## 9. Execution routing

Builder: main session (single-file-class changes across helper, two
hooks, digest, skills, docs, tests). Reviewer: `anoti:skeptic` against
the branch diff with the spec as the contract; fix rounds resume the
builder (D011). Integration: human-gated merge of branch `review-debt`.

## Changelog

- 2026-08-19 (review round 1, skeptic REFUTED → fixed): §4.3 subject
  normalisation and project-root resolution via `anoti-dir --root`
  (state_dir-configured projects never fired); §4.2 telemetry verbs are
  the subcommand names; §4.5 `gh pr merge` integrates from any branch;
  §4.6 heading honesty (wording extended, not verbatim); §5 whole-file
  malformed-ledger rule stated for hooks AND helpers, and the one
  hook-side writer's bounded lock wait. Also fixed in code: state dir
  created before locking (fresh clone spun ~60 s), `awk -v` escape
  processing broke dedupe on backslash subjects (ENVIRON now).

