# Adaptive Suppression — Design Spec

**Status:** RATIFIED 2026-08-19 ("proceed") — adversarial review
COMPLIANT-WITH-RESIDUE after two cycles (13 findings fixed round 1; two
polish items + an acknowledged coupling closed round 2). Implementation
cascade commissioned; Q006's ranker gate opens only after this ships and
two audited weeks pass.

**Date:** 2026-08-19
**Status:** DESIGN, filed 2026-08-19 — not yet reviewed. Per
`skills/spec/SKILL.md:84-86` ("specs of consequence get adversarial
review before done"), this design is not built until it clears the
reviewer pass named in §9.

**Authority:** human directive 2026-08-19, "proceed with all" (relayed to
this spawn's dispatch brief — I did not myself witness the directive text
in any durable artifact I can cite by `{file, lines}`; flagged in
Questions/doubts, same evidentiary posture
`docs/specs/2026-08-19-jit-recall-design.md:1567-1576` already
established for a relayed-not-witnessed instruction). Grounded in two
citable artifacts: the **field review** — commit `5b9bf98` (0.5.24)
message, "Field review on 0.5.22-23: ... presence injections were mostly
irrelevant"; and `docs/specs/2026-08-13-exp-longitudinal.md:131-135`'s own
changelog entry recording the same finding and adding the Presence-precision
metric + Q006 gate it produced. The **"codag.ai research (local cache with
TTL)"** the human directive cites as a second input is not present in this
repository under any name I could find (`grep -rn "codag" GROUNDING.yaml`
and a repo-wide search for "codag" both return nothing but the branch name
itself, `codag-ideas`) — I treat it as directive content handed to me, not
as an independently citable source, and say so again in Questions/doubts
rather than inventing a citation for it.

**Spec:** this document. **Parent:**
`docs/specs/2026-08-19-jit-recall-design.md` (the presence hook this spec
extends) and `docs/specs/2026-08-13-exp-longitudinal.md` (the metric and
gate this spec amends). **story_ref:** none new — this is a precision
refinement of the already-shipped JIT-recall mechanism (US-001, extended
per the 2026-08-19 audit note, `docs/HIGH-LEVEL-STORIES.md:54-66`), not a
new story.

---

## 1. What this is

A **project-level, not per-session**, feedback cache —
`<state-dir>/presence-feedback.tsv` — that lets the presence hook
(`scripts/presence`) learn which `(record, trigger)` pairs it has already
been told, by name, produce irrelevant injections, and stop injecting
exactly those pairs — visibly (a digest line, a `list` command) and
reversibly (a `clear` command) — while every other trigger on the same
record keeps firing normally. It closes the loop the field review opened:
`docs/specs/2026-08-13-exp-longitudinal.md:90-98` already added a
Presence-precision metric and a Q006 re-ranker gate keyed on that metric,
but the retrospective step that feeds the metric
(`skills/policy-retrospect/SKILL.md:17-22`) only ever recorded a **count**
(`scripts/mark-retrospect ... irrelevant-injections N`) — nothing today
converts "2 of 3 injections were noise" into a mechanism that stops
recurrence. This spec extends `mark-retrospect`'s contract so the
retrospective can additionally **name** the offending `(record, trigger)`
pairs, adds one new store-resolve primitive that gives the hook
per-trigger match detail it does not have today, and adds the suppression
check itself to `scripts/presence` — all before any ranker (Q006) is
considered, per the longitudinal spec's own stated ordering
(`docs/specs/2026-08-13-exp-longitudinal.md:94-98`, amended by this spec's
§4.8).

This differs from the two precision measures already shipped
(`docs/specs/2026-08-13-exp-longitudinal.md:131-135`, event-scoped
triggers and `remove-trigger`) in one load-bearing way: those are
**human-driven, permanent** edits to a record's authored `triggers:` list.
Adaptive suppression is **mechanical and reversible** — it learns from
repeated retrospective marks without a human editing GROUNDING.yaml, and
it un-learns the moment the marks are cleared or age out. `remove-trigger`
remains the permanent fix for a trigger that is simply badly authored;
this spec is for the case where a trigger is fine in general but keeps
firing at the wrong moment for one specific record.

## 2. Why

**Claim (cited):** the field review found presence injections "mostly
irrelevant" at one site (commit `5b9bf98` message,
`docs/specs/2026-08-13-exp-longitudinal.md:131-132`). **Claim (cited):**
the retrospective policy already asks the session to count irrelevant
injections (`skills/policy-retrospect/SKILL.md:17-22`) and the
longitudinal spec already scores a Presence-precision metric from that
count (`docs/specs/2026-08-13-exp-longitudinal.md:90-93`) — but a count
alone cannot drive a mechanism: nothing downstream of `mark-retrospect`
today reads _which_ injections were named, because `mark-retrospect`
never had anywhere to put that information (`scripts/mark-retrospect:1-21`,
current signature is `<sid> <empty|filed> [irrelevant-injections N]`, no
id/trigger slot). **Labeled inference:** the two mechanical measures
already shipped (event-scoping, `remove-trigger`) require a human to read
telemetry and decide; a cache that acts on the retrospective's own,
already-produced verdict — three strikes and a pair goes quiet — is a
strictly cheaper next rung on the same ladder the longitudinal spec
already built for the ranker (`docs/specs/2026-08-13-exp-longitudinal.md:82-98`
names Tier-2/ranker gates as later, evidence-gated rungs; this spec is a
rung the longitudinal spec's own Q006 gate text explicitly did not yet
name, because it did not exist when that gate was written — closed by
§4.8's amendment). This motivation depends on the retrospective actually
being run and actually naming ids — a discipline problem, not a
mechanism problem; `skills/policy-retrospect/SKILL.md:53-55`'s existing
violation-handling clause (an abandoned-state surfacing path) already
covers "retrospective skipped entirely," so this spec does not invent a
new enforcement path for that, only for what happens once names exist.

## 3. Design principles / constraints

1. **Fail open, ≤5s, no new hook.** This spec adds no PostToolUse/
   PostToolUseFailure registration; it extends the existing `scripts/presence`
   (`hooks/hooks.json:76,88`, timeout `5`, unchanged) and
   `scripts/retrieve` (SessionStart, unchanged registration). A missing or
   corrupt feedback file degrades to "no suppression," never to a hook
   error (§5).
2. **Silent by default (US-002).** The digest line emits only when
   `N > 0` (§4.6); a firing with nothing suppressed emits nothing new.
3. **Every write goes through a helper with the established contract:**
   lock (`scripts/store-lock`, the same primitive `scripts/presence`
   already uses for its own state file, `scripts/presence:38-39`),
   write-to-tmp/validate-shape/preserve-mode/atomic-mv (the exact sequence
   `scripts/append-trigger:17-22` and `scripts/remove-trigger:22-29`
   already establish), and exact-string matching for every id/trigger
   comparison — never a shell `case` pattern or a `yq ==` against
   freeform text (**G002** — cited by id, not line: the global store is
   unversioned in this repo and its record order drifts as new records
   are appended; a fix-round re-check found G002 had moved from line 43
   to line 47 between the first draft of this spec and this fix round,
   confirming the fragility — every citation into `~/.claude/anoti/GROUNDING.yaml`
   in this document now cites by id only). Verified,
   not assumed, that the two primitives this spec actually uses for exact
   comparison are safe: awk's `==` on two strings is byte-exact, not
   wildcard (`{command: "awk 'BEGIN{a=\"c*\"; b=\"c1\"; print
(a==b)?\"MATCH\":\"NOMATCH\"}'", output: "NOMATCH"}` and the same
   pattern with `b="c*"` prints `MATCH` — i.e. it is testing string
   identity, not glob-matching `a` against `b`), and `grep -qxF --`
   is fixed-string whole-line matching, unaffected by a literal `*` in
   the needle (`{command: "printf 'D001\\tcX\\n' | grep -qxF --
$'D001\\tc*' && echo WRONGLY-MATCHED || echo CORRECT-NO-MATCH",
output: "CORRECT-NO-MATCH"}`). Neither primitive carries G002's
   specific failure mode (that finding is about `yq`'s compiled `==`
   specifically); this spec's TSV never touches `yq` at all (§4.2).
4. **bash 3.2 compatible; no `IFS=<tab> read`; shellcheck clean.** Same
   constraints `scripts/presence` already documents and works around
   (`scripts/presence:116-125`'s TSV-substitute-for-`declare -A` note;
   `scripts/presence:135-142`'s `cut -f` note). Every TSV row this spec
   introduces is read with `cut -f` or `awk -F'\t'`, never `IFS=$'\t' read`.
5. **One component, one responsibility.** `scripts/store-resolve` gets
   exactly two additions (§4.3.3, §4.5.1) and is otherwise untouched — in
   particular, `match_triggers` itself (`scripts/store-resolve:32-57`) is
   **not modified**, for the same regression-risk reasoning
   `docs/specs/2026-08-19-jit-recall-design.md:188-199` already used to
   keep `scripts/retrieve` unrefactored: that function's exact bytes were
   hardened across two fix rounds (NEW-C1, `docs/specs/2026-08-19-jit-recall-design.md:396-430`)
   and both `scripts/presence` and `scripts/recall` depend on its exact 4-column
   output shape by position (`scripts/presence:144-146`'s `cut -f3/-f4/-f5`;
   `scripts/recall:31-33`'s `cut -f2/-f3/-f4`, confirmed by direct read).
   All new per-trigger detail is a **new sibling function**
   (`match_trigger_pairs`, §4.3.3), the same pattern this codebase already
   used once for exactly this reason (`matched_triggers`,
   `scripts/store-resolve:58-76`, its own comment: "NEW export beyond the
   spec's listed exports... Reuses match_triggers' exact export/ENVIRON
   discipline"). All suppression _policy_ (threshold, TTL, filtering,
   telemetry) lives in `scripts/presence` only — `scripts/recall` is
   unmodified and unaffected, because a human explicitly invoking pull-side
   recall wants full recall, the same asymmetry
   `docs/specs/2026-08-19-jit-recall-design.md:774-778` already argues for
   trigger-only vs. topic/statement matching.
6. **Exact values, no placeholders.** Threshold 3 (default, overridable),
   TTL 30 days, KEEP bar ≥15 percentage points, all stated here, not left
   for implementation to invent.

## 4. The design

### 4.1 Component map

| Component           | File                                            | New/changed                | Responsibility                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| ------------------- | ----------------------------------------------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Feedback store      | `<state-dir>/presence-feedback.tsv`             | new                        | durable `(record_id, trigger, irrelevant_count, last_marked, first_marked)` rows                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| Feedback helper     | `scripts/feedback`                              | new                        | `mark`/`list`/`clear` — the only reader/writer of the feedback store; `clear` also purges the matching stale `recall_cache` entry from any `$AD/sessions/*.presence.yaml` on disk (§4.5.2)                                                                                                                                                                                                                                                                                                                                                     |
| Detail matcher      | `scripts/store-resolve` (`match_trigger_pairs`) | new, sourced               | per-`(record, trigger)` match detail for one firing, sibling to `match_triggers`                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| Shape checker       | `scripts/store-resolve` (`feedback_shape_ok`)   | new, sourced               | one shared corrupt/valid predicate for the feedback TSV, used by both hook and helper                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| Presence hook       | `scripts/presence`                              | extended                   | applies suppression before ranking; new `suppressed` telemetry duty; warn-once on corruption; purges a record's recall_cache entry at read time when its suppression expires (TTL)                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| Retrospect marker   | `scripts/mark-retrospect`                       | extended                   | accepts named `id[:trigger]` tokens after the existing count; backward compatible                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| Retrospect policy   | `skills/policy-retrospect/SKILL.md`             | extended                   | wording: name ids (and triggers where known), not only a count                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| SessionStart digest | `scripts/retrieve`                              | extended                   | "presence: N pairs suppressed" line, gated like the existing recall-coverage line                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| Demo skill          | `skills/demo/SKILL.md`                          | extended                   | routing row for `anoti feedback` (D025 obligation, §9)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| Skill map           | `docs/SKILL-MAP.md`                             | extended                   | new entry-point row (D025 obligation, §9)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| Longitudinal spec   | `docs/specs/2026-08-13-exp-longitudinal.md`     | extended (dated changelog) | Q006 gate reworded; new pre-registered KEEP/telemetry-only/REVERT rule for adaptive suppression                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| Dispatcher          | `scripts/anoti`                                 | **no change**              | `scripts/anoti`'s `help` listing already iterates every executable file under `$SELF` (`scripts/anoti:12-29`) — `scripts/feedback`, once created and made executable, is picked up automatically. Verified by reading the loop, not assumed: it has no allow-list, only a deny-list for the seven hook scripts — `retrieve`, `classify`, `inhibit`, `persist-session`, `consolidation-gate`, `cleanup-session`, `presence` (`scripts/anoti:17-21`, counted directly from the `case` pattern, not assumed) — and `feedback` is not one of them. |

### 4.2 The feedback store: `<state-dir>/presence-feedback.tsv`

Rows: `record_id\ttrigger\tirrelevant_count\tlast_marked\tfirst_marked`
(5 tab-separated fields; `last_marked`/`first_marked` are `YYYY-MM-DD`,
matching every other date field in this codebase, e.g.
`templates/GROUNDING.yaml:17`'s record-shape comment). At most one row
per exact `(record_id, trigger)` pair — `scripts/feedback mark` (§4.4)
either increments an existing row or inserts a new one; it never appends
a duplicate. No header line, matching `telemetry.log`'s own headerless
TSV convention (`scripts/presence:57`'s `tel()`, same shape family).

**Location and persistence, verified, not assumed:**

- `<state-dir>` is `$AD` as resolved by `scripts/anoti-dir`
  (`scripts/anoti-dir:1-37`) — project-anchored by root-marker walk-up,
  the same resolver every other project-scoped state file in this plugin
  already uses (`scripts/presence:7`, `scripts/store-resolve:23`). This
  makes the feedback store **project-level by construction**: two
  different projects on the same machine each get their own file, and a
  record id that happens to collide between a project's own store and the
  global store shares one feedback keyspace within that one project (a
  named limitation, not solved here — see Questions/doubts).
- **Gitignored, verified by direct test, not inference:** the default
  state dir (`.anoti/`) is covered by two layers — the top-level
  `.gitignore:1` (`.anoti/`) and `.anoti/.gitignore` (content `*`,
  confirmed by direct read). Constructing the actual file and asking git
  confirms it: `{command: "touch .anoti/presence-feedback.tsv &&
git check-ignore -v .anoti/presence-feedback.tsv", output:
".gitignore:1:.anoti/\t.anoti/presence-feedback.tsv"}` — matched by the
  top-level rule, so a new file under the state dir needs no gitignore
  entry of its own. A project configured with a **custom** `state_dir:`
  (`.claude/anoti.local.md`, `scripts/anoti-dir:18-24`) inherits whatever
  gitignore protection that directory already has today for
  `telemetry.log`/`trust`/`sessions/` — this spec adds no new protection
  and needs none; it is not a new risk this feature introduces.
- **Survives `cleanup-session` (SessionEnd), verified by direct read, not
  assumed:** `scripts/cleanup-session:1-24` touches exactly three paths —
  it reads `$AD/sessions/$sid.yaml` (line 9), removes
  `$AD/sessions/$sid.presence.yaml` (line 18), and either removes or
  renames `$AD/sessions/$sid.yaml` (lines 19-22). It never globs or
  touches any other file under `$AD` — `presence-feedback.tsv`,
  `telemetry.log`, and `trust` are outside its blast radius entirely, by
  construction (no wildcard, no directory-wide operation in the file).
  This is the "project-level, NOT per-session" property the task
  requires, demonstrated rather than asserted.

### 4.3 Signal source: the retrospective names pairs, not just a count

#### 4.3.1 The status quo (cited)

`scripts/mark-retrospect:1-21`'s current signature is `<session-id>
<empty|filed> [irrelevant-injections N]`. When the optional form is used
it writes one telemetry line:
`ts\tsid\tretrospect\t<state>\tirrelevant=N` (`scripts/mark-retrospect:17`).
This is the **entire** durable trace of "which injections were
irrelevant" today — a count, no ids. The retrospective policy that
produces this count (`skills/policy-retrospect/SKILL.md:17-22`) already
tells the session to "count them," but names no mechanism for recording
which ones.

#### 4.3.2 What the hook already logs per firing (cited) — and the gap

`scripts/presence`'s `recall` telemetry duty already names the **records**
injected in a firing: `recall_detail="${recall_detail}${id}[${ltag}],"`
(`scripts/presence:157,166-167`), producing lines like
`presence recall G004[global],D007[]`. It does **not** name which
`trigger` caused each record to match — `match_triggers`
(`scripts/store-resolve:32-57`) aggregates every matching trigger on a
record into a single hit count and never surfaces the trigger text
itself past its own `awk` pass. A human reading `telemetry.log` after the
fact can identify _which record_ fired at _which tool call_ (the
`tool_input`/`tool_response` at that timestamp, if the transcript is
still available) but has no mechanical way to know _which trigger_
matched without re-deriving it by hand. This is the exact gap the task
names: "design how the hook logs which trigger matched so feedback can be
per (record, trigger)." This spec closes it two ways: a new matcher
primitive that makes trigger-level detail available **inside** a firing
(§4.3.3, consumed by suppression itself) and an extended retrospective
contract that lets a **human** name the trigger after the fact, from
memory or from re-reading the transcript, when they can tell which one
fired (§4.3.4) — the task's own "and, where known" qualifier, honored
literally: an id-only mark is accepted and logged for audit, but never
guessed into a pair.

#### 4.3.3 New store-resolve primitive: `match_trigger_pairs`

A sibling to `match_triggers`, not a modification of it (constraint 5).
Same yq extraction, same `tolower`/`index`/`ENVIRON` discipline
(`export MT_HAY=...` as its own statement, never a prefix assignment —
the exact NEW-C1 pitfall `docs/specs/2026-08-19-jit-recall-design.md:396-430`
already found and fixed once; repeating the same discipline here rather
than re-risking it), but instead of aggregating into one row per record
it **emits one row per matching pair**, unaggregated, carrying the
**original, unmodified trigger text** (prefix and all) rather than the
lower-cased, prefix-stripped copy used only for matching — this is
deliberate: the trigger text going into `presence-feedback.tsv` and into
`scripts/feedback clear`/`remove-trigger` must be the exact authored
string, so a human can act on it with `remove-trigger` unchanged.

```sh
match_trigger_pairs() {  # $1=store $2=haystack -- ALL matching (id,trigger,statement) triples, unaggregated
  f="$1"
  export MT_HAY="$2"
  yq -r '.records[] | .id as $id | .statement as $s |
      (.triggers // [])[] | [$id, ., $s] | @tsv' "$f" 2>/dev/null |
  awk -F'\t' '
    BEGIN { h = tolower(ENVIRON["MT_HAY"]); ev = ENVIRON["MT_EVENT"] }
    {
      trig = tolower($2)
      if (substr(trig,1,5) == "edit:") { if (ev != "" && ev != "edit") next; trig = substr(trig,6) }
      else if (substr(trig,1,5) == "bash:") { if (ev != "" && ev != "bash") next; trig = substr(trig,6) }
      if (trig != "" && index(h, trig) > 0) printf "%s\t%s\t%s\n", $1, $2, $3
    }
  '
  unset MT_HAY
}
```

This is **illustrative, not execution-verified by me** — the awk
primitives it depends on (`tolower`, `index`, `ENVIRON`, `substr`) are the
same ones `match_triggers` already verified working on this platform
(`docs/specs/2026-08-19-jit-recall-design.md:412-425`); I did not
separately re-run this exact byte sequence, and the backend builder's
RED/GREEN transcript (§6) is the verification artifact, not this prose,
per the same distinction `docs/specs/2026-08-19-jit-recall-design.md:1647-1650`
draws about "suggested code" vs. executed code.

**Cost, labeled judgment:** this is one additional `yq`+`awk` pass per
store per firing — the same subprocess-count class as `match_triggers`
itself (already verified at ~0.032s for two 300-record stores combined,
`docs/specs/2026-08-19-jit-recall-design.md:418-422`). §4.5.2 explains why
`scripts/presence` calls `match_trigger_pairs` **instead of**
`match_triggers` (not in addition to it) for its own recall duty, so this
spec does not double the yq-call count the earlier perf work fought to
bring down — it substitutes one O(1)-per-store call for another,
net-neutral on subprocess count. The backend builder's perf test (§6,
item 9) must confirm this figure at scale before it ships, honestly
flagged as unverified by this spec rather than claimed.

#### 4.3.4 `scripts/mark-retrospect`'s extended contract

New grammar, additive and backward compatible — the existing two-arg and
three-arg (`... irrelevant-injections N`) forms are byte-identical in
behavior; only a new, optional fourth-and-beyond position is added:

```
scripts/mark-retrospect <session-id> <empty|filed> \
    [irrelevant-injections N [pair ...]]
```

Each `pair` is either `<record-id>` (id only — audit trail, no
suppression write) or `<record-id>:<trigger>` (feeds suppression). Split
on the **first** `:` only — `${tok%%:*}` / `${tok#*:}`, POSIX parameter
expansion, bash-3.2-safe — because a trigger's own authored text can
legitimately contain a colon (`edit:CHANGELOG.md` is itself a valid
trigger, `skills/consolidate/SKILL.md:75-76`); splitting on the first
colon correctly yields `id="D025"` and `trigger="edit:CHANGELOG.md"` for
the token `D025:edit:CHANGELOG.md`, never a mis-split on the trigger's
own internal colon. No colon present (`"${tok%%:*}" = "$tok"`) means an
id-only token.

**Fully-specified token classification (fix-round corrections, IMPORTANT
3 and 4 — the first draft left two real gaps here, both closed below,
not just patched):**

```sh
for tok in "$@"; do   # illustrative shape; the pair-arguments loop
  [ -n "$tok" ] || continue
  idhalf="${tok%%:*}"
  if [ "$idhalf" = "$tok" ]; then
    # no colon present -- id-only form
    trighalf=""
    haspair=0
  else
    trighalf="${tok#*:}"
    haspair=1
  fi
  # GUARD 1 (IMPORTANT 4): empty-half check -- only meaningful for the
  # pair form; "D001:" -> idhalf=D001, trighalf="" is rejected here;
  # ":cd-chain" -> idhalf="", trighalf=cd-chain is rejected here too.
  # An id-only token with an empty idhalf can only arise from a stray
  # blank argument (bad quoting upstream) and is rejected by the same
  # check (idhalf empty is never valid, paired or not).
  if [ -z "$idhalf" ] || { [ "$haspair" = "1" ] && [ -z "$trighalf" ]; }; then
    echo "mark-retrospect: skipping malformed pair token '$tok' (empty id or trigger half)" >&2
    continue
  fi
  # GUARD 2 (IMPORTANT 3): lesson-id collision. Lesson ids are always
  # shaped "L:<hash>" (store-resolve's match_lessons, scripts/store-resolve:112;
  # presence's own telemetry already renders one as "L:a1b2c3d4[]",
  # scripts/presence:157) -- their OWN mandatory colon means ANY mention
  # of a lesson id in this pair grammar always splits with idhalf exactly
  # "L", whether written bare ("L:a1b2c3d4", which looks like an
  # attempted id-only mark but the mandatory colon forces the pair path)
  # or with a spurious trigger appended ("L:a1b2c3d4:sometrigger").
  # DISPATCHER RULING: lesson ids can never be named for suppression --
  # consistent with §7's lesson exclusion (lessons carry no authored
  # triggers: of their own, so there is no (lesson, trigger) pair this
  # mechanism could ever act on) -- so this is an outright reject, not a
  # degraded id-only accept.
  if [ "$idhalf" = "L" ]; then
    echo "mark-retrospect: skipping '$tok' -- lesson ids cannot be named for suppression (§7)" >&2
    continue
  fi
  if [ "$haspair" = "1" ]; then
    id="$idhalf"; trigger="$trighalf"   # feeds scripts/feedback mark, point 2 below
  else
    id="$idhalf"                          # audit-only, point 3 below
  fi
done
```

Rejected tokens (either guard) are **not** written to
`presence-feedback.tsv` and **not** included in the `pairs=` telemetry
field (§4.3.4 point 1) — the stderr warning is their only trace, visible
in the session transcript at the moment `mark-retrospect` runs, which is
sufficient audit trail for a caller error rather than a suppression
decision. A malformed or lesson-guarded token never blocks the other
tokens in the same call, nor the base `<empty|filed> irrelevant=N`
line, which is always written regardless (§5).

**Behavior:**

1. The existing summary telemetry line is unchanged in shape —
   `printf ...irrelevant=%s...` (`scripts/mark-retrospect:17`) — so the
   already-shipped Presence-precision metric
   (`docs/specs/2026-08-13-exp-longitudinal.md:90-93`) keeps working
   without modification. **Additive** when pairs are given: a `pairs=`
   field is appended to the same line, e.g.
   `...irrelevant=2\tpairs=D001:cd-chain,D009` — comma-joined,
   id-only tokens included un-suffixed, `id:trigger` tokens with the
   colon intact — giving the longitudinal audit's Recall-MISS metric
   (`docs/specs/2026-08-13-exp-longitudinal.md:36`) a mechanically
   parseable record of which ids were named, instead of relying on
   re-reading conversational retrospective text.
2. For every token that split into an `id:trigger` pair, `mark-retrospect`
   shells out to `scripts/feedback mark "$id" "$trigger"` (§4.4) — one
   call per pair, each independently locked (§4.4), so a failure on one
   pair does not block the others or the telemetry write.
3. For every id-only token, **no feedback-store write happens at all** —
   it is logged only in the `pairs=` telemetry field above. This is the
   literal reading of the task's "and, where known" — an unknown trigger
   is never guessed, and never silently promoted into a suppression write
   the human did not actually assert.
4. `mark-retrospect` never touches GROUNDING.yaml, never calls
   `record-index`, and does not verify a named id actually exists in any
   store — a mistyped id is harmless (§4.4 explains why: it can never
   match anything at hook-fire time, so it can never suppress anything;
   it simply sits in `presence-feedback.tsv` for a human to notice via
   `anoti feedback list`). This is a deliberate, lower validation bar than
   `append-trigger`/`remove-trigger`'s (which mutate the authoritative
   store and so must resolve a real index, `scripts/append-trigger:11-12`)
   — the feedback store is a side ledger, not memory content.

#### 4.3.5 `skills/policy-retrospect/SKILL.md` — exact wording

Rule 2 (`skills/policy-retrospect/SKILL.md:17-22`) currently reads:

```
2. **What didn't** — friction, wrong turns, misleading signals — and,
   since 0.5.24, **which presence injections were irrelevant** (count
   them; record via `scripts/mark-retrospect <sid> <empty|filed>
   irrelevant-injections N` so the audit can score precision); cite the
   moment. A retrospective that finds no friction in nontrivial work is
   suspect, not clean.
```

Replace with (technical-writer applies verbatim, per D025, §9):

```
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

### 4.4 `scripts/feedback` — the single reader/writer

Three subcommands, dispatched via the existing `anoti <action>` contract
(`scripts/anoti:31-35`; `scripts/feedback` needs no dispatcher change,
§4.1). Sources `store-resolve` (for `cfgk`, `fx`, `feedback_shape_ok`)
and `store-lock` (for `lock_store`/`unlock_store`).

**`scripts/feedback mark <record-id> <trigger>`** — internal; called by
`mark-retrospect` (§4.3.4), never a human-facing entry in the demo table
(§9's routing row lists only `list`/`clear`, matching the task's own
named CLI surface). Read-modify-write under lock:

```sh
scripts/feedback mark <record-id> <trigger>
  AD="$("$SELF/anoti-dir" --require)" || exit 1   # writers require anchoring, scripts/anoti-dir:10
  ff="$AD/presence-feedback.tsv"
  lock_store "$ff" || exit 1
  trap 'unlock_store "$ff"' EXIT
  [ -f "$ff" ] || : > "$ff"
  today="$(date -u +%F)"
  awk -F'\t' -v id="$1" -v trig="$2" -v today="$today" '
    BEGIN { found = 0 }
    { if ($1 == id && $2 == trig) { $3 = $3 + 1; $4 = today; found = 1 }; print }
    END { if (!found) print id "\t" trig "\t1\t" today "\t" today }
  ' OFS='\t' "$ff" > "$ff.tmp.$$"
  feedback_shape_ok "$ff.tmp.$$" || { rm -f "$ff.tmp.$$"; echo "feedback: result failed shape validation; store untouched" >&2; exit 1; }
  pm="$(stat -c %a "$ff" 2>/dev/null || stat -f %Lp "$ff" 2>/dev/null || echo "")"
  [ -n "$pm" ] && chmod "$pm" "$ff.tmp.$$" 2>/dev/null
  mv "$ff.tmp.$$" "$ff"
  exit 0
```

The `$1 == id` / `$2 == trig` comparisons are awk string equality —
verified byte-exact, not wildcard, in constraint 3 above. This mirrors
`scripts/append-trigger:17-22`'s write-to-tmp / validate / preserve-mode /
atomic-mv sequence exactly, substituting `feedback_shape_ok` (§4.5.1) for
`validate-workspace` since this file is a flat TSV, not a YAML
GROUNDING store, and needs no `regen-index`/`trust` step (it carries no
`ratification`/`epistemic_status` — it is bookkeeping, not memory
content, per §4.3.4 point 4's same reasoning).

**`scripts/feedback list`** — read-only, no lock needed (every writer
here uses atomic `mv`, so a concurrent reader always sees a complete old
or new file, never a torn one — the same guarantee every other
tmp-then-`mv` helper in this plugin already relies on,
`scripts/append-trigger:22`). Prints every row with a computed
`suppressed: yes|no` column, using the **same** threshold/cutoff logic
`scripts/presence` uses (§4.5.1, §4.7) so what a human sees here matches
what the hook is actually doing:

```
record_id  trigger        count  last_marked  first_marked  suppressed
D001       cd chain       3      2026-08-19   2026-08-17    yes
D009       curl           2      2026-08-18   2026-08-18    no
```

Sorted by `count` descending, then `record_id` ascending (deterministic,
matching the tie-break discipline `docs/specs/2026-08-19-jit-recall-design.md:540-544`
already established for the hook's own ranking). Missing feedback file:
prints `feedback: no presence-feedback.tsv yet (nothing suppressed)` and
exits 0 — not an error, matching the "missing → no suppression" contract
(§5).

**`scripts/feedback clear <record-id> [trigger]`** — reversibility. With
`trigger`: removes the one row matching that exact `(id, trigger)` pair
(awk `$1==id && $2==trig` filter, print everything else), mirroring
`remove-trigger`'s "removes exactly ONE occurrence" framing
(`scripts/remove-trigger:3`) at the row level. Without `trigger`: removes
**every** row for that `record_id` (any trigger) — the natural reading of
the task's `[trigger]` being optional. Refuses (exit 1, stderr) when no
row matched, mirroring `scripts/remove-trigger:21`'s refusal on an absent
trigger — clearing something that was never suppressed is a caller error
worth surfacing, not a silent no-op (G004: a `clear` that always exits 0
regardless of whether anything changed could not distinguish "cleared" from
"nothing there," the same non-falsifiable shape G004 already names —
cited by id only, per the fix-round note above). Same write-to-tmp/validate/atomic-mv
sequence as `mark`.

**Deliberately not built:** `scripts/feedback clear` with no id at all
(clear-everything) — not in the task's named signature; a human wanting
that can `rm <state-dir>/presence-feedback.tsv` directly, since it is a
plain file with no index/trust dance to keep consistent (unlike
GROUNDING.yaml).

`feedback_shape_ok` (new, `store-resolve`, shared by the hook's read path
and this helper's write path — DRY, one predicate, two callers):

```sh
feedback_shape_ok() {  # $1=file -- 0 if every non-empty line has exactly 5 tab fields, count numeric, both dates YYYY-MM-DD; missing file is NOT a shape failure (caller distinguishes absent vs. present-and-bad)
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

### 4.5 Suppression in the presence hook

#### 4.5.1 Loading the suppression set

Once per firing (not once per store — the feedback file is one
project-level file, §4.2):

```sh
# read upfront, same position/shape as the existing warned_g/warned_p
# reads (scripts/presence:60-61) -- NOT only inside the warn branch,
# so the value is always defined and ready for the persist step below
# regardless of which branch this firing takes
warned_f="$(yq -r '.warned.feedback // false' "$pf" 2>/dev/null || echo false)"
threshold="$(cfgk feedback_threshold)"; [ -n "$threshold" ] || threshold=3   # §4.7
cutoff="$(date -v-30d +%F 2>/dev/null || date -d '30 days ago' +%F 2>/dev/null || echo "")"   # exact idiom, scripts/retrieve:25
ff="$AD/presence-feedback.tsv"
suppressed=""
if fx "$ff"; then
  if feedback_shape_ok "$ff"; then
    suppressed="$(awk -F'\t' -v th="$threshold" -v cutoff="$cutoff" \
      'NF==5 && $3+0>=th && $4>=cutoff {print $1"\t"$2}' "$ff" 2>/dev/null)"
  else
    if [ "$warned_f" != "true" ]; then
      try_emit "- presence-feedback.tsv: present but not parseable; suppression disabled this session (fix or remove it)" \
        && { tel warn feedback; warned_f=true; }
    fi
  fi
fi
```

`$4 >= cutoff` is a lexical string comparison of two `YYYY-MM-DD` dates —
equivalent to chronological comparison for zero-padded ISO-8601 dates,
the exact technique `scripts/retrieve:42`'s own oldest-probable check
already relies on (`! [ "$cutoff" \< "$oldest" ]`). The `warned.feedback`
flag is a **third key** added to the presence-state file's existing
`warned: { global: false, project: false }` map (`scripts/presence:41`,
`docs/specs/2026-08-19-jit-recall-design.md:730`) — additive; a
presence-state file written by a session before this ships simply reads
`.warned.feedback // false` as `false` via `yq`'s default, the same
defensive pattern every other field in that file already uses (`tool_calls
// 0`, `scripts/presence:52`).

**Fix-round correction (IMPORTANT 2, reviewer finding): reading
`warned_f` is not enough — the value must be written back, or every
firing re-reads `false` and warns again.** The above code block, taken
alone, sets the local shell variable `warned_f=true` but nothing in it
persists that to `$pf` — and because `scripts/presence` is a fresh
process invocation per tool call (not a long-running daemon holding
state in memory), a local variable set in one firing does not exist in
the next one; only what is written to `$pf` survives. `scripts/presence`
already solves exactly this problem for `warned_g`/`warned_p` at its
existing persist step
(`scripts/presence:235-237`, current shipped file — reproduced here for
the exact insertion point):

```sh
TC="$((tool_calls + 1))" LR="$last_reanchor" RC="$rc_json" WG="$warned_g" WP="$warned_p" \
  yq ".tool_calls = strenv(TC) | .last_frame_reanchor = strenv(LR) | .recall_cache = (strenv(RC) | fromjson) | .warned.global = (strenv(WG) == \"true\") | .warned.project = (strenv(WP) == \"true\")" "$pf" > "$pf.tmp.$$" \
  && mv "$pf.tmp.$$" "$pf"
```

This spec's required change to that one line: add `WF="$warned_f"` to
the prefix-assignment list and `| .warned.feedback = (strenv(WF) ==
\"true\")` to the `yq` filter — the exact same shape as the existing
`WG`/`.warned.global` and `WP`/`.warned.project` pairs, nothing novel.
Without this, `warned_f` would silently reset to `false` every firing and
the corrupt-file warning would re-emit on every single matched tool call
for the rest of the session — the exact spam constraint 2/US-002 exists
to prevent, and the precise regression §6 item 8 is extended to catch
(two firings **in the same session, each its own process invocation**,
not two calls within one process — the direct test for this fix).
This is the "warn once per session" half of the corrupt-file failure
contract (§5).

#### 4.5.2 Filtering and re-aggregation — replacing, not adding to, the recall duty's matching step

`scripts/presence`'s current recall assembly (`scripts/presence:83-113`)
calls `match_triggers` per store to build `p_matches`/`g_matches`, and
separately calls `matched_triggers` to build `matched_trigs` for the
lessons piggyback (`scripts/presence:89-105`). This spec changes **only**
the `p_matches`/`g_matches` half — `matched_trigs` and the lessons
piggyback are unaffected (§7: lessons are out of scope for suppression).

New assembly, per store (`$1`=store, `$2`=label):

```sh
suppression_filtered_matches() {  # $1=store $2=haystack $3=label -- emits match_triggers' exact 4-col shape (hits\tid\tlabel\tstatement), suppressed pairs excluded; side effect: appends this store's suppressed pairs to $SUPP_THIS_FIRING
  pairs="$(match_trigger_pairs "$1" "$2")"   # §4.3.3
  [ -n "$pairs" ] || return 0
  printf '%s\n' "$pairs" | awk -F'\t' -v label="$3" -v supp="$suppressed" '
    BEGIN {
      n = split(supp, lines, "\n")
      for (i = 1; i <= n; i++) { split(lines[i], f, "\t"); if (f[1] != "") sup[f[1] SUBSEP f[2]] = 1 }
    }
    {
      if (($1, $2) in sup) { print $1 "\t" $2 > "/dev/stderr"; next }
      cnt[$1]++; stmt[$1] = $3
    }
    END { for (id in cnt) printf "%s\t%s\t%s\t%s\n", cnt[id], id, label, stmt[id] }
  ' 2>"$supp_tmp_this_store"
}
```

`(id, trigger) in sup` is POSIX awk's multi-dimensional membership test
(implicit `SUBSEP` join) — verified working on this platform:
`{command: "awk 'BEGIN{sup[\"D001\" SUBSEP \"cd chain\"]=1; a=\"D001\";
b=\"cd chain\"; if ((a,b) in sup) print \"OK\"; else print \"FAIL\"}'",
output: "OK"}`, and correctly absent for a non-member pair in the same
run. `suppressed` (the set loaded in §4.5.1) is passed via `-v`, safe
here because it is composed only of record ids and trigger text already
read from `yq -r` TSV output — **not** raw, unbounded tool-call text the
way the haystack is, so it does not carry the backslash-escape corruption
risk `docs/specs/2026-08-19-jit-recall-design.md:451-461` found for
`awk -v` specifically on haystack content; trigger text is already
proven safe to pass by value elsewhere in this file (`match_triggers`'s
own `label` parameter, `scripts/store-resolve:37`, same reasoning). The
suppressed-pair stderr redirect is captured per store into a small temp
file (`supp_tmp_this_store`, one per store, cleaned up with the rest of
the firing's scratch state) purely so the caller can build the
`suppressed` telemetry duty (§4.5.3) without re-deriving which pairs were
cut — this is illustrative shape, not a claim that stderr-as-a-data-channel
is how the backend builder must implement it; a temp file, a second
return value via a second awk output stream with a sentinel prefix, or
splitting into two awk passes are equally valid — the **contract** this
spec requires is: for every `(id, trigger)` pair that matched this firing
and was found in `suppressed`, the record's contribution to `cnt[id]`
is excluded, and the pair is available for telemetry (§4.5.3).

**Ranking consequence (labeled judgment):** a record matched by two
triggers where one is suppressed keeps its **other** trigger's
contribution to `cnt[id]` — it still ranks and still injects, just with a
lower hit count than an unfiltered firing would have given it. A record
whose **every** matching trigger this firing is suppressed has `cnt[id]
== 0` after filtering and is absent from `all`/`ranked` entirely — not
merely capped by `MAX_RECORDS`, genuinely not a candidate this firing.
This is the literal reading of the task's "the record still fires via
OTHER triggers": suppression removes a pairing's _contribution_, not the
record.

**`recall_cache` can go stale across a suppression lifecycle (MINOR 13,
reviewer finding) — two purge points close it, both mechanical:** a
fully-suppressed record never reaches `rc_set` (`scripts/presence:158`)
this firing — its contribution is excluded before the dedupe loop even
runs (above) — so `recall_cache[id]` is left exactly as it was from the
**last time the record was actually injected, before it became
suppressed**. If suppression then ends — by `scripts/feedback clear` or
by the marks aging past the 30-day TTL — that stale entry could
otherwise dedupe-block the record for up to `N=10` more calls even
though the real reason it stopped appearing (suppression) is already
gone, defeating the reversibility the task requires. Two purge points,
not one, because the two ways suppression ends are observed from two
different places:

1. **Explicit `clear` (`scripts/feedback clear`, §4.4):** after the
   `presence-feedback.tsv` write succeeds, `scripts/feedback` additionally
   globs every `$AD/sessions/*.presence.yaml` currently on disk and, for
   each one whose `recall_cache` object has a key equal to the cleared
   `<id>`, removes that key — under that **session file's own**
   `store-lock` (the same primitive `scripts/presence:38-39` already
   locks it with), one file at a time:

   ```sh
   for sf in "$AD"/sessions/*.presence.yaml; do
     [ -f "$sf" ] || continue
     lock_store "$sf" || continue
     trap 'unlock_store "$sf"' EXIT
     yq -e ".recall_cache | has(\"$id\")" "$sf" >/dev/null 2>&1 \
       && yq -i "del(.recall_cache[\"$id\"])" "$sf" 2>/dev/null
     unlock_store "$sf"
     trap - EXIT
   done
   ```

   Best-effort, not correctness-critical: there are realistically 0-1
   active session files at any moment plus perhaps a handful of
   not-yet-cleaned abandoned ones (`scripts/cleanup-session:19-22`); a
   file appearing or disappearing mid-scan is not raced beyond each
   file's own lock, because the worst case of a missed purge is the
   pre-existing dedupe window (`N=10` more calls), never a permanent
   block or a corruption.

2. **Natural TTL expiry, at read time (`scripts/presence` itself,
   §4.5.1):** on the firing where §4.5.1's threshold+cutoff computation
   first finds a pair's marks have aged past 30 days (i.e., that pair
   just fell out of the `suppressed` set it would have been in on the
   previous firing), `scripts/presence` drops that id's `recall_cache`
   entry as part of the same persist step that already writes
   `recall_cache` back (§4.5's closing `yq` call) — computed by comparing
   this firing's `suppressed` set against **the previous firing's**, which
   requires `presence-feedback.tsv`'s own `last_marked` values (already
   loaded, §4.5.1) rather than any new state: an id is "just expired"
   when it has a `presence-feedback.tsv` row at/above threshold whose
   `last_marked` is **not** in `suppressed` this firing (aged out) but a
   `recall_cache` entry still exists for it. This is illustrative logic,
   not literal verified code — the **contract** is: a `recall_cache`
   entry never outlives the suppression episode that made it stale.

**Everything else in the pipeline is unchanged:** `tag_prio`, the `sort` tie-break (project >
global > lessons, then id ascending,
`docs/specs/2026-08-19-jit-recall-design.md:528-544`), the `recall_cache`
dedupe window, `MAX_RECORDS`, the `(+N more matched)` suffix — is
**unchanged**, because `suppression_filtered_matches` produces the exact
same 4-column shape `match_triggers` always produced (`scripts/presence:143-146`'s
`cut -f3/-f4/-f5` reads it identically either way). A fully-suppressed
record is removed **before** that pipeline runs, so it correctly never
consumes a `MAX_RECORDS` slot and never inflates the `skipped_more` count
— it was never a candidate, not a candidate that lost a coin flip.

#### 4.5.3 Telemetry: `presence suppressed <id>:<trigger>`

One line per firing (mirroring the `recall` duty's own single-line,
comma-joined convention, `scripts/presence:157,166-167` — chosen for
consistency across all of `presence`'s duties rather than inventing a
per-pair-line convention this file does not otherwise use):

```
ts\tsid\tpresence\tsuppressed\tD001:cd chain,D009:curl
```

Emitted only when at least one pair was actually suppressed this firing
— silence otherwise (US-002). This is independent of whether the
record(s) involved still fired via another trigger; the audit needs to
see every suppression event even on a firing where the record was not
actually silenced, so precision-over-time is auditable (§4.6, §4.8).

#### 4.5.4 What is unaffected

Frame re-anchoring (`scripts/presence:204-224`) and the evidence-kind
nudge (`scripts/presence:170-202`) are untouched — suppression applies
only to the recall duty, per the task's own scope ("adaptive suppression"
is named against presence _injections_, and the task's bullet list names
only `(record, trigger)` pairs, which only the recall duty produces). The
existing dedupe window (`recall_cache`, `N=10`) and periodic re-anchor
interval share nothing with this spec's TTL (30 days) or threshold (3) —
two independently-tuned constants for two independent mechanisms, not
conflated.

### 4.6 Visibility: the digest line

`scripts/retrieve` gains one `try_emit` line, inserted directly after the
existing recall-coverage line (`scripts/retrieve:106-115`, the `#20`
block, re-verified against the current file — it shifted from its
earlier 95-101 position when 0.5.25 added the codepoint-aware cut
handling ahead of it) — same gating (`[ -n "$PSTORE" ]`, a governed project store must
exist; an unrelated global-only or bare-`TODOS.md` directory never shows
it, matching that block's own comment "warnings only for a GOVERNED
project"), same independent-reproduction choice §4.2 of
`docs/specs/2026-08-19-jit-recall-design.md:188-199` already made for
`retrieve` (it does not source `store-resolve`; this spec does not change
that — the count logic below is four lines, cheaper to duplicate than to
risk `retrieve`'s own exact-match-sensitive test suite,
`tests/test_retrieve.sh`, by adding a new dependency edge):

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

`$AD` is already resolved at the top of `scripts/retrieve`
(`scripts/retrieve:9`); `PSTORE` and `fx`/`cfgk` are the file's own
existing locals (`fx` at `scripts/retrieve:24`, `cfgk` at
`scripts/retrieve:90-93`, `PSTORE` set at `scripts/retrieve:96-97` —
re-verified against the current file, all three shifted from an earlier
draft's line numbers) — no new dependency, no
new sourced file, only new local lines, matching how the recall-coverage
line was added in 0.5.23 (commit `6036f45`, `scripts/retrieve` diff
"+10" per that commit's stat) with the same shape of change.

### 4.7 Human-overridable threshold

`.claude/anoti.local.md` gains one recognized key: `feedback_threshold:`
— read via the existing generic `cfgk` function (`scripts/store-resolve:9-12`,
duplicated locally in `scripts/retrieve:90-93`, same key-reading pattern
`lessons_path`/`todos_path`/`roadmap_path`/`story_path`/`state_dir`
already use). There is no central registry of valid `.claude/anoti.local.md`
keys in this repository (a repo-wide search for a keys-list document
found none) — each feature that needs a config knob documents its own key
inline at every `cfgk` call site, which is the existing, if informal,
convention this spec follows rather than invents. Default `3` (matching
the task's stated default) applies whenever the key is absent or the
frontmatter block itself is missing, exactly as every other `cfgk` caller
in this codebase already defaults (`scripts/store-resolve:28`'s
`lessons_path` default is the closest structural analogue).

### 4.8 Interaction with Q006 — dated amendment to the longitudinal spec

`docs/specs/2026-08-13-exp-longitudinal.md:90-98` currently reads:

```
- **Presence precision (added 2026-08-19, field review):** relevant
  injections / total injections per audited week, where "irrelevant" is
  the retrospective's own count (`mark-retrospect … irrelevant-injections
  N` telemetry) over the `presence recall` lines. **Re-ranker filter
  justified** (Q006: a small cross-encoder scoring keyword candidates,
  local, fail-open, only when candidates exist) when precision stays
  below 50% across two consecutive audited weeks AFTER the mechanical
  precision measures (event-scoped triggers, cue-quality guidance,
  remove-trigger) have shipped — never before them.
```

Per `skills/spec/SKILL.md:20-21`'s amendment rule ("amendments after
acceptance get dated changelog entries, not silent edits") and this
file's own established precedent for how it has already been amended
twice this way (`docs/specs/2026-08-13-exp-longitudinal.md:120-148`), the
technical-writer (§9) applies this exact replacement plus a new
changelog entry — not a silent edit:

```
- **Presence precision (added 2026-08-19, field review):** relevant
  injections / total injections per audited week, where "irrelevant" is
  the retrospective's own count (`mark-retrospect … irrelevant-injections
  N` telemetry) over the `presence recall` lines. **Re-ranker filter
  justified** (Q006: a small cross-encoder scoring keyword candidates,
  local, fail-open, only when candidates exist) when precision stays
  below 50% across two consecutive audited weeks AFTER adaptive
  suppression (docs/specs/2026-08-19-adaptive-suppression-design.md,
  itself built on the earlier mechanical measures — event-scoped
  triggers, cue-quality guidance, remove-trigger) has shipped and two
  audited weeks have passed — never before it.
```

New changelog entry, appended after the existing 2026-08-19 entries
(`docs/specs/2026-08-13-exp-longitudinal.md:136-148`):

```
- 2026-08-19 (later still) — amended per
  `docs/specs/2026-08-19-adaptive-suppression-design.md`: the Q006
  re-ranker gate's "AFTER the mechanical precision measures... have
  shipped" clause is reworded to name adaptive suppression specifically
  and require two full audited weeks to pass after it ships before the
  gate can fire — adaptive suppression is itself a mechanical precision
  measure and the pre-registered discipline (`docs/specs/2026-08-13-exp-longitudinal.md:103-108`)
  requires it be given the same fair chance the earlier measures were.
  Also adds §"Adaptive suppression KEEP/telemetry-only/REVERT" as a new,
  independent pre-registered gate for the suppression mechanism's own
  disposition (below).
```

### 4.9 Pre-registered KEEP/telemetry-only/REVERT criterion for adaptive suppression itself

New subsection, appended immediately after the existing "Presence
precision" bullet (§4.8's replacement text) inside the Tier-1 gate section
(`docs/specs/2026-08-13-exp-longitudinal.md:76-108`):

```
**Adaptive suppression KEEP/telemetry-only/REVERT (pre-registered, frozen
2026-08-19):** compare Presence precision across two windows, each drawn
from this file's own existing weekly-audit cadence
(`docs/specs/2026-08-13-exp-longitudinal.md:112-114`, first audit
2026-08-20, weekly thereafter) — never a bespoke measurement window.

**Baseline window, with an explicit fallback (MINOR 11, reviewer
finding — this repo's audit cadence starts 2026-08-20 and adaptive
suppression is expected to ship within days of that, so two full audited
PRE-ship weeks may simply not exist yet):**

- **Primary:** the two most recently completed audited weeks immediately
  BEFORE adaptive suppression ships, if both exist.
- **Fallback, stated plainly rather than left as a silent gap:** if fewer
  than two pre-ship audited weeks exist, the baseline is instead **the
  first two audited weeks AFTER shipping** — defensible only because
  suppression cannot act at all until a pair accumulates 3 marks within
  30 days (§4.2), so a freshly-shipped mechanism's first two weeks are a
  reasonable, if imperfect, proxy for "before it had any effect" (it
  barely acts early). Under this fallback, the **post-ship window**
  becomes the two audited weeks immediately **following** the fallback
  baseline (weeks 3-4 after ship, compared against weeks 1-2) — this
  makes the whole comparison a **within-post-ship** measurement, not a
  true before/after one, and any conclusion drawn from it carries
  correspondingly **weaker inference**, labeled as such wherever it is
  cited — the same "observational, no counterfactual arm" honesty this
  file's own Method section already states up front
  (`docs/specs/2026-08-13-exp-longitudinal.md:19-23`).
- Under the **primary** path, the post-ship window is simply the two
  audited weeks immediately after ship, as originally specified.

**Three outcomes, not two (MINOR 12, reviewer finding — folding "no
effect" and "regressed" into one bucket hid a real failure mode: a
mechanism that makes precision WORSE is a different, more urgent finding
than one that merely does nothing):**

- **KEEP** — adaptive suppression is credited as the cause of any
  precision gain and stays the load-bearing precision mechanism — when
  mean post-ship precision is **≥15 percentage points higher** than mean
  baseline precision.
- **Telemetry-only** — the mechanism's marks/suppressions keep recording
  (nothing is removed or disabled), but it is no longer treated as a
  source of further expected precision gain — when the change is **between
  -10 and +15 points** (a rise below the KEEP bar, or a fall that does not
  reach the REVERT bar). This is not a rollback: `presence-feedback.tsv`
  and `scripts/feedback` stay exactly as built; "telemetry-only" describes
  how future gates read the evidence, not a code change.
- **REVERT** — when mean post-ship precision is **≥10 percentage points
  LOWER** than mean baseline precision (the mechanism is actively making
  things worse, e.g. by suppressing pairs a later trigger context would
  have found relevant). Filed as a **corrective TODO** — matching this
  file's own existing decision-rule shape for a filed action rather than
  an autonomous code change ("two incidents in one audit → a corrective
  TODO," `docs/specs/2026-08-13-exp-longitudinal.md:43-44`) — to disable
  the suppression check pending human review (e.g., an effectively
  unreachable `feedback_threshold` override, §4.7, or a dedicated
  disable flag; the exact mechanism is an implementation decision for
  that TODO, not fixed here) while `presence-feedback.tsv` continues
  accumulating for audit. Not an automatic rollback: this is a metrics
  and gate document, not a deployment mechanism, and every other
  decision rule in this file resolves to a filed human action, not
  self-executing code.
- **Every outcome opens Q006's gate identically:** the "two audited
  weeks have passed" clause in §4.8's amended Presence-precision bullet
  is satisfied the moment this comparison runs (primary or fallback
  path), regardless of which of the three outcomes it resolves to — the
  wait exists to give the mechanical measure a fair chance to work, not
  to hide an unfavorable result from the ranker gate.
```

## 5. Failure behavior

| Condition                                                                                                                                                | Behavior                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Never breaks                                                                                          |
| -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `presence-feedback.tsv` missing                                                                                                                          | No suppression this firing; no warning, no telemetry (§4.5.1's `fx "$ff"` gate is false) — silent, matching US-002                                                                                                                                                                                                                                                                                                                                                                                           | The recall duty's existing unfiltered behavior — identical to a session with no feedback history ever |
| `presence-feedback.tsv` present but malformed (`feedback_shape_ok` fails)                                                                                | Suppression disabled this firing; warned **once per session** (`.warned.feedback`, mirrors the existing global/project warn-once pattern **as documented in the design spec**, `docs/specs/2026-08-19-jit-recall-design.md:704-717` — fix-round correction: the earlier draft of this table cited `scripts/presence:704-717`, but `scripts/presence` is 245 lines total; the quoted "once per session... `warned: {global: bool, project: bool}` map" text lives in the design doc, not the 245-line script) | Every other duty; the malformed file is never auto-repaired or deleted — a human fixes or removes it  |
| `scripts/feedback mark`/`clear` write races another writer                                                                                               | `store-lock`'s existing mkdir-based mutex (`scripts/store-lock:9-46`) — same primitive already serializing the presence-state file (`scripts/presence:38-39`); a stuck lock steals after 30s, a waiter times out loudly at ~60s                                                                                                                                                                                                                                                                              | The feedback file's own consistency — a torn write is never committed (write-to-tmp + atomic `mv`)    |
| A retrospective names a nonexistent record id                                                                                                            | Accepted, written, harmless — it can never match a haystack at hook-fire time (§4.3.4 point 4), and shows up in `anoti feedback list` for a human to notice                                                                                                                                                                                                                                                                                                                                                  | Every real pairing's own suppression accounting                                                       |
| A pair token is malformed — either half empty after the split (`"D001:"` gives id=`D001`, trigger=`""`; `":cd-chain"` gives id=`""`, trigger=`cd-chain`) | Skipped for that one token, with a stderr note naming the token; N and every other valid token in the same call are unaffected (§4.3.4's fully-specified empty-half guard)                                                                                                                                                                                                                                                                                                                                   | The base `irrelevant=N` telemetry line, which is written regardless                                   |
| A pair token names a lesson id (`L:<hash>`, or any token whose id-half is exactly `L`)                                                                   | Rejected outright with a stderr warning, never written to `presence-feedback.tsv` and never counted in the `pairs=` telemetry field — lessons carry no authored `triggers:` of their own, so `(lesson, trigger)` is not a pairing this mechanism can suppress (§4.3.4's lesson guard, consistent with §7's lesson exclusion)                                                                                                                                                                                 | Every non-lesson token in the same call                                                               |
| A `recall_cache` entry for an id predates a suppression that has since been cleared or expired                                                           | `scripts/feedback clear` purges the matching `recall_cache` entry from every `$AD/sessions/*.presence.yaml` on disk as part of the clear; `scripts/presence` itself purges a stale entry at read time on the firing where an id's suppression naturally expires past the 30-day cutoff (§4.5.2) — a record is never dedupe-blocked by a cache entry set before it became suppressed                                                                                                                          | The dedupe window's normal behavior for every id that was never suppressed                            |
| `scripts/feedback` invoked outside any anoti workspace                                                                                                   | `scripts/anoti-dir --require` fails loudly (`scripts/anoti-dir:33-36`) — the writer refuses rather than minting a stray file, the same G003 discipline every other writer here follows                                                                                                                                                                                                                                                                                                                       | —                                                                                                     |
| The hook script itself errors (bad JSON, missing `yq`/`jq`)                                                                                              | Fail-open: exit 0, no `additionalContext`, no telemetry — identical, unchanged contract to every other failure mode already in `docs/specs/2026-08-19-jit-recall-design.md:1268-1278`'s table                                                                                                                                                                                                                                                                                                                | The tool call itself — presence fires after the tool already ran                                      |

## 6. Testing

Fixture-driven, hermetic (`mktemp -d`, `HOME` overridden — the pattern
`tests/test_retrieve.sh:2-3` establishes), auto-discovered by
`tests/run.sh`'s `for t in "$ROOT"/tests/test_*.sh` loop
(`tests/run.sh:18`). New file `tests/test_feedback.sh`, extending
`tests/test_helpers.sh` and `tests/test_presence.sh` per requirement:

1. **Three marks suppress:** `scripts/feedback mark D001 "cd chain"`
   called three times → a fourth call to `scripts/feedback list` shows
   `count=3, suppressed=yes`; a `scripts/presence` firing whose haystack
   contains `cd chain` and whose only matching trigger on `D001` is that
   one → `D001` absent from `additionalContext`; `telemetry.log` gains a
   `presence\tsuppressed\tD001:cd chain` line and **no**
   `presence\trecall\tD001[]` line for that firing.
2. **Two marks do not suppress:** same setup, marked twice → `list` shows
   `suppressed=no`; the same firing still injects `D001` normally, no
   `suppressed` telemetry line.
3. **Expired marks don't count:** a fixture row with `count=3` but
   `last_marked` set to 40 days before "today" (test-injected clock, or a
   constructed cutoff) → `list` shows `suppressed=no` (soft expiry, §4.2);
   the hook does not suppress it.
4. **Other triggers still fire:** a record with two triggers, one
   suppressed (3 marks) and one not → the record still appears in
   `additionalContext` (via the surviving trigger); telemetry shows both
   a `recall` line naming the record and a `suppressed` line naming only
   the suppressed pair.
5. **`list`/`clear` round-trip:** mark a pair to `count=3`; `clear` it
   (with trigger) → the row is gone from `list`; a subsequent presence
   firing with that same haystack no longer suppresses it (back to
   normal injection) — the direct regression test for reversibility.
   `clear <id>` with no trigger removes every row for that id (fixture
   with two triggers on the same id, both marked, one `clear` call
   removes both).
   `clear` on an absent pair exits 1 with a stderr message (mirrors
   `scripts/remove-trigger:21`'s refusal test, `tests/test_helpers.sh:892-893`).
   **Extended (MINOR 13, reviewer finding):** before `clear`, inject the
   record once (uncorrupted, unsuppressed) so `recall_cache` in the
   session's `*.presence.yaml` holds an entry for it; mark it to
   `count=3` (now suppressed, so no further `rc_set` calls touch that
   entry — it stays exactly as it was pre-suppression); `clear` it →
   assert the `recall_cache` entry for that id is gone from the
   presence-state file, not merely that the feedback row is gone —
   then a firing on the very next tool call (not N calls later)
   re-injects the record, proving the fix (without it, a stale
   pre-suppression `recall_cache` entry could dedupe-block the record for
   up to `N=10` more calls after `clear`, silently defeating
   reversibility). A parallel case for natural TTL expiry: same setup,
   but instead of `clear`, advance the fixture's `last_marked` past the
   30-day cutoff and fire presence once — assert the same
   `recall_cache` purge happens at that firing, per §4.5.2's expiry rule.
6. **Digest line:** `N=0` (no feedback file, or file present but nothing
   at/above threshold) → digest omits the line entirely; `N=2` → digest
   contains `presence: 2 (record,trigger) pairs suppressed — anoti
feedback list`, gated on `PSTORE` being set (a directory with only a
   global store and no project GROUNDING.yaml never shows it, mirroring
   `tests/test_retrieve.sh`'s existing warning-gating assertions).
7. **Telemetry shape:** a firing suppressing two pairs across two
   different records → exactly one `presence\tsuppressed\t` line,
   comma-joined (`id1:trig1,id2:trig2`), never two separate lines — the
   direct test for §4.5.3's stated single-line convention.
8. **Corrupt file, warn-once:** a hand-corrupted `presence-feedback.tsv`
   (wrong column count on one line) → first presence firing this session
   emits the warning line + `presence\twarn\tfeedback` telemetry and
   disables suppression; a **second, separate invocation** of
   `scripts/presence` (piped fresh JSON into a new process — not a second
   call inside the same process, since each hook firing genuinely is its
   own process, §4.5.1's fix-round note) reusing the same `$sid` and `$pf`
   is silent on that point (mirrors the existing warn-once test pattern,
   `docs/specs/2026-08-19-jit-recall-design.md:1314-1316`, item 6). This
   is the direct regression test for IMPORTANT 2 (the write-back fix):
   asserting the second invocation reads `.warned.feedback == true` from
   `$pf` on disk, not merely that a single in-process run behaves —
   run against the **unfixed** design (no `WF`/`.warned.feedback` write-back)
   first, in a scratch copy, to confirm it goes RED (warns twice), per
   the reviewer's own optional-empirical-evidence pattern
   (`roles/reviewer.md:27-33`), before confirming GREEN against the fixed
   version.
9. **Perf:** a `presence-feedback.tsv` fixture with 200 rows, a firing
   matching several pairs against it → wall-clock time for the recall
   duty stays under **2.5s**, the actual shipped bar
   `tests/test_presence.sh:223,255-256` already enforces for
   `match_triggers` at two-300-record-store scale (`awk -v e="$elapsed"
'BEGIN{exit !(e < 2.5)}'`, widened from the parent design spec's own
   narrower **<1s** prose estimate — `docs/specs/2026-08-19-jit-recall-design.md:1342-1358`
   — to **2.5s** during 0.5.22 to tolerate slower CI/developer machines,
   per `tests/test_presence.sh:228`'s own comment: "operational hook
   timeout is 5s, so 2.5s leaves half the budget"). This spec's perf test
   extends the **shipped** 2.5s assertion (not the earlier, narrower
   prose figure) to also cover the new `match_trigger_pairs` call and the
   suppression filter pass — this is the required re-verification §4.3.3
   flags as unperformed by this spec.
10. **`mark-retrospect` backward compatibility:** the existing two- and
    three-arg forms (`<sid> filed`, `<sid> filed irrelevant-injections 3`)
    produce byte-identical telemetry lines to today's — a direct
    regression test against `tests/test_helpers.sh:814-822`'s existing
    assertions, unchanged.
11. **`mark-retrospect` with named pairs:** `mark-retrospect s1 filed
irrelevant-injections 2 D001:"cd chain" D009` → `telemetry.log` gains
    a line with `pairs=D001:cd chain,D009`; `presence-feedback.tsv` gains
    exactly one new/incremented row for `D001`/`cd chain` and **none**
    for `D009` (id-only, audit-only — the direct test for §4.3.4 point 3).
    A colon inside the trigger itself (`D025:edit:CHANGELOG.md`) splits
    correctly into `id=D025, trigger=edit:CHANGELOG.md` (the direct test
    for §4.3.4's first-colon-only split rule).
12. **Threshold override:** `.claude/anoti.local.md` with
    `feedback_threshold: 5` → a pair marked 3 times shows `suppressed=no`
    in `list` and still injects normally; marked 5 times shows
    `suppressed=yes` and is skipped.
13. **shellcheck clean, bash 3.2:** `scripts/feedback`, the extended
    `scripts/presence`, `scripts/mark-retrospect`, and the extended
    `scripts/store-resolve`/`scripts/retrieve` pass `shellcheck` and run
    correctly under `/bin/bash` on macOS (this repo's existing CI
    baseline, per `docs/specs/2026-08-19-jit-recall-design.md:1631-1642`'s
    own noted platform scope) — no `declare -A`, no `${var,,}`, no
    `IFS=<tab> read`, matching constraint 4.
14. **Malformed pair token (IMPORTANT 4, direct regression test):**
    `mark-retrospect s1 filed irrelevant-injections 1 "D001:"` →
    `presence-feedback.tsv` gains **no** row, stderr carries the
    "malformed pair token" note, and the base `irrelevant=1` telemetry
    line is still written. Same assertions for
    `mark-retrospect s1 filed irrelevant-injections 1 ":cd-chain"`. Both
    cases are the literal worked examples the reviewer named.
15. **Lesson-id guard (IMPORTANT 3, direct regression test):**
    `mark-retrospect s1 filed irrelevant-injections 1 "L:a1b2c3d4"` →
    `presence-feedback.tsv` gains no row, stderr carries the "lesson ids
    cannot be named for suppression" note, and `telemetry.log`'s `pairs=`
    field (if present at all) does **not** contain `L:a1b2c3d4` — proving
    the token is rejected outright, not silently accepted as a
    `(id=L, trigger=a1b2c3d4)` pair. A second case with a spurious
    trigger appended (`"L:a1b2c3d4:cd chain"`) asserts the same rejection
    (idhalf is `L` either way, per the split rule).

## 7. Out of scope

- **The re-ranker (Q006) itself** — this spec is explicitly the
  mechanical rung the longitudinal spec's own gate requires be exhausted
  first (§4.8, §4.9); building the ranker is not this spec's work.
- **Lesson (`L:` id) suppression** — lessons carry no authored `triggers:`
  of their own; they piggyback on an already-matched record trigger
  (`docs/specs/2026-08-19-jit-recall-design.md:518-527`), so there is no
  independent `(lesson, trigger)` pair to suppress. `matched_trigs` and
  the lessons piggyback path (`scripts/presence:89-105`) are unmodified.
- **Cross-store id disambiguation** — the feedback keyspace is bare
  `record_id`, not `(scope, record_id)`; a project id colliding with a
  global id is a named, accepted risk (§4.2, Questions/doubts), not
  solved here — the task's own row shape (`record_id, trigger, ...`) does
  not name a scope column, and inventing one unrequested is scope creep
  an advisory role should not add unilaterally.
- **Garbage collection of expired rows** — soft expiry only (§4.2); no
  row is ever deleted for aging out, only for an explicit `clear`. A
  human can prune the plain TSV by hand if it matters.
- **A bare `anoti feedback clear` (clear-everything) form** — not in the
  task's named CLI signature; `rm <state-dir>/presence-feedback.tsv` is
  the equivalent, already available without new code.
- **Suppression of the frame-reanchor or evidence-nudge duties** — the
  task's scope is `(record, trigger)` pairs, which only the recall duty
  produces (§4.5.4).
- **Validating that a named record id exists in a store at mark-time** —
  deliberately not checked (§4.3.4 point 4); a mistyped id is inert, not
  dangerous.
- **Amending Q006's own GROUNDING.yaml record text** — Q006's stored
  question (`GROUNDING.yaml:552`) duplicates language this spec's §4.8
  changes in the longitudinal spec; I cannot write GROUNDING.yaml as an
  advisory role (roles/architect.md's boundary), so this drift is named
  as a follow-up for the eventual consolidation step, not fixed here
  (Questions/doubts).

## 8. Success criteria

1. `tests/test_feedback.sh` and every extended test file (§6) pass, run
   via `bash tests/run.sh`.
2. A fixture pair marked exactly 3 times within 30 days is suppressed; the
   same pair marked exactly 2 times is not — the direct, checkable
   resolution of the task's own worked example.
3. A record matched by a suppressed trigger AND a non-suppressed trigger
   in the same firing still injects, and telemetry names the suppressed
   pair separately from the successful injection — checkable via
   `telemetry.log` diff against a constructed two-trigger fixture.
4. `scripts/feedback list`/`clear` round-trip: a suppressed pair, once
   cleared, resumes injecting on the next matching firing — checkable
   end-to-end without touching GROUNDING.yaml or any record's
   `triggers:` list.
5. The digest line appears only when `N > 0`, names the exact count, and
   points at `anoti feedback list` — mechanically checkable against a
   constructed feedback fixture and a directory with none.
6. `scripts/mark-retrospect`'s existing two- and three-argument forms are
   byte-identical in output to pre-this-spec behavior — checkable by
   diffing telemetry lines against `tests/test_helpers.sh:814-822`'s
   existing fixtures, unmodified.
7. `docs/specs/2026-08-13-exp-longitudinal.md`'s Q006 gate text and the
   new Adaptive-suppression KEEP/telemetry-only/REVERT subsection (§4.8, §4.9)
   appear verbatim, each with its own dated changelog entry — no silent
   edit.
8. `skills/policy-retrospect/SKILL.md` rule 2's new wording (§4.3.5)
   appears verbatim.

## 9. Execution routing

**Plan owner: architect.** Same reasoning
`docs/specs/2026-08-19-jit-recall-design.md:1494-1509` already gives for
this exact role/spec pairing: `roles/architect.md:19-20` names the
cascade-decomposition responsibility, `docs/SKILL-MAP.md:39` names
architect as the spec skill's entry point, and this spec's components are
interdependent in the same way (the shape checker must land before
`scripts/feedback` can validate against it; `mark-retrospect`'s extension
must land before its call to `scripts/feedback mark` can be tested
end-to-end) — the context that produced this spec is the cheapest place
to sequence its build.

**Builder hats:**

- **backend** (`roles/backend.md`) — `scripts/presence` (extended),
  `scripts/store-resolve` (extended: `match_trigger_pairs`,
  `feedback_shape_ok`), `scripts/mark-retrospect` (extended),
  `scripts/feedback` (new), `scripts/retrieve` (extended: digest line),
  and every test file in §6. Reason: `roles/backend.md:18-24` — "routes,
  signatures, schemas... test-driven... idempotency... error paths" is
  exactly this work's shape, the same reasoning
  `docs/specs/2026-08-19-jit-recall-design.md:1519-1524` already applied
  to the sibling scripts this spec extends. Loads: policy-test-driven
  (RED/GREEN transcripts per §6), policy-adversarial-handoff (reviewer
  spawn before done), `anoti:git` (branch/commit discipline), plus the
  universal epistemic/trace-to-frame/escalate-destructive stack already
  in `roles/backend.md:6-13`.
- **technical-writer** (`roles/technical-writer.md`) — the exact-wording
  edits: `skills/policy-retrospect/SKILL.md` (§4.3.5),
  `docs/specs/2026-08-13-exp-longitudinal.md` (§4.8, §4.9's dated
  amendment), `skills/demo/SKILL.md` (new routing row, inserted after the
  existing `append-trigger (consolidate step 2b)` row,
  `skills/demo/SKILL.md:44`, reading e.g. "Injections keep firing at the
  wrong moment / anoti feedback list, clear <id> [trigger] / see and undo
  what adaptive suppression has silenced; remove-trigger is the permanent
  fix"), `docs/SKILL-MAP.md` (new entry-point row under "Entry points
  (roots)", `docs/SKILL-MAP.md:16`, alongside the existing presence-hook
  row). **These edits are D025's own obligation, made concrete:**
  `GROUNDING.yaml:500`'s D025 record states plainly "the demo skill's
  routing table, docs/SKILL-MAP.md, and README one-liners are updated
  alongside the CHANGELOG entry and version bump — never in a later
  reminder from the human" — this spec's Execution routing names that
  work explicitly rather than leaving it implicit, the same choice
  `docs/specs/2026-08-19-jit-recall-design.md:1531-1546` already made for
  its own equivalent edits. None of these targets is a human-owned
  direction organ in the `policy-draft-for-ratification` sense
  (`skills/policy-draft-for-ratification/SKILL.md:8-10` scopes that
  policy to ROADMAP/HIGH-LEVEL-STORIES-class organs) — ordinary
  plugin/spec source, reviewed like code even though no organ here
  triggers `draft-for-ratification`'s procedure. **Loads (fix-round
  correction, IMPORTANT 5): policy-reader-run (execute every edited doc's
  instructions as written), policy-draft-for-ratification, plus the
  universal epistemic/trace-to-frame/escalate-destructive stack — this is
  `roles/technical-writer.md:6-13`'s own registered policy stack,
  verbatim.** The earlier draft of this routing additionally listed
  `policy-adversarial-handoff` here, which is wrong: that policy's own
  "Applies" line is conditional — "roles that declare it — builder work
  whose failure would be expensive to discover late"
  (`skills/policy-adversarial-handoff/SKILL.md:8-9`) — and
  `roles/technical-writer.md:6-13`'s policy list does not declare it (it
  carries `draft-for-ratification` instead, which backend's own stack
  does not). Technical-writer's diff is not left unreviewed by this
  correction: it is still adversarially checked, just via the **reviewer
  role's own batch pass** below (which does declare, and does apply
  `policy-adversarial-handoff` to itself as the mechanism, not because
  technical-writer independently carries the policy) — the same
  distinction the dispatcher's ruling draws.
- **reviewer** (`roles/reviewer.md`) — one adversarial pass over the
  **whole batch** — backend's diff, covered by `policy-adversarial-handoff`
  as backend's own declared policy (`roles/backend.md:6-13`,
  `skills/policy-adversarial-handoff/SKILL.md:8-9`'s "roles that declare
  it"), and technical-writer's diff alongside it in the same pass, as
  ordinary reviewed source (not because technical-writer declares
  `policy-adversarial-handoff` itself — it does not, per the correction
  above — but because the reviewer's own scope is the batch, not a
  policy-by-policy dispatch). Verifies
  specifically: every §6 test exercises what it claims (re-running RED
  before GREEN where a transcript is ambiguous); the awk multidim-`in`
  and `ENVIRON`-vs-`-v` discipline in §4.5.2's illustrative code is
  correctly and _literally_ executed against a constructed fixture before
  being trusted, per the exact lesson
  `docs/specs/2026-08-19-jit-recall-design.md:396-430,1643-1664` already
  paid for once on this same matcher family — a "suggested code" block
  that is never run is not evidence, only a claim about code; the perf
  test (§6 item 9) actually re-measures rather than assumes §4.3.3's
  cost estimate holds at scale; `mark-retrospect`'s backward-compatibility
  claim (§8 item 6) is checked by diff, not by re-reading the code and
  agreeing it looks right. Loads: epistemic, trace-to-frame,
  escalate-destructive (`roles/reviewer.md:6`) — no test-driven/
  adversarial-handoff on the reviewer itself, per its own role stack.

**Fix rounds:** per D011 (`skills/deliberate/SKILL.md:85-93`), reviewer
findings resume the **original** backend or technical-writer spawn with
findings relayed verbatim — never a fresh spawn — capped at 3 cycles by
analogy to `commands/review-work.md:55-56`'s "Cycle cap (MANDATORY): at
cycle 3, STOP" sentence; a blocker surviving three rounds returns to the
human as a design decision, not a fourth attempt.

## Questions/doubts

- **Coupling, acknowledged (reviewer cycle 2):** `scripts/feedback clear`
  mutates `scripts/presence`'s session-state shape (`recall_cache` in
  `*.presence.yaml`) directly, under store-lock. Accepted for the build as
  verified-working; if the state-file shape changes, the purge must move
  behind a shared helper in `store-resolve` so the shape keeps one owner.
  Flagged for the plan owner, not silently folded in.

- **"The codag.ai research" cited in this spec's authority is not
  independently verifiable by me.** I searched this repository (git
  history, GROUNDING.yaml, docs/) for any artifact under that name and
  found nothing but the branch name `codag-ideas` itself. I have treated
  it as directive content relayed to this spawn, not as a source I can
  cite by `{url, anchor}`. If a durable artifact for it exists outside
  this repo, the reviewer or human should supply the citation; I have not
  invented one.
- **I did not myself witness the "proceed with all" directive text** in
  any durable artifact — it is relayed dispatch content, the same
  evidentiary posture `docs/specs/2026-08-19-jit-recall-design.md:1567-1576`
  already flagged for an analogous relay. If the reviewer can locate a
  durable transcript, it should cite that directly in place of my relay.
- **Cross-store id collision in the feedback keyspace is a named,
  accepted risk, not a solved one** (§4.2, §7): a project-store record id
  and a global-store record id that happen to share the same text would
  share one row in `presence-feedback.tsv`. I judged this acceptable
  because record ids are conventionally namespaced (`G00N` for global,
  `D00N`/`Q00N` for project) even though nothing enforces that
  convention, and because inventing a scope column beyond the task's own
  literal row shape (`record_id, trigger, irrelevant_count, last_marked,
first_marked`) would be scope creep for an advisory role. If this
  matters in practice, the file is a plain TSV a human can inspect
  directly.
- **§4.5.2's illustrative code uses awk's stderr as a side channel for
  the suppressed-pairs list**, which I flagged as one possible shape
  among several equally valid ones, not a mandated implementation. I made
  this judgment call because I did not want to either (a) claim a single
  literal implementation as verified when I have not executed the full
  `scripts/presence` integration, or (b) leave the _contract_ (what must
  be true of the output) unstated. If the reviewer or backend builder
  finds a cleaner shape (e.g., two separate awk passes over a captured
  variable, avoiding stderr-as-data entirely, which is not this
  codebase's existing convention anywhere else I found), that is a free
  substitution as long as the contract in §4.5.2's closing paragraph
  holds.
- **The 15-point KEEP bar, the 10-point REVERT bar, and the 30-day TTL
  are labeled judgments, not derived from data** — no audited weeks exist
  yet at filing time (the longitudinal spec's own cadence starts
  2026-08-20, `docs/specs/2026-08-13-exp-longitudinal.md:112`). The KEEP
  and TTL values were specified directly by the human directive this
  spec implements; the REVERT bar was specified by the fix-round
  dispatcher ruling (MINOR 12) that split the original two-outcome KEEP/
  telemetry-only design into three. None of the three numbers is
  independently derived from this project's own precision data, which
  does not exist yet. 15 and 10 points are both large enough to be
  distinguishable from plausible week-to-week noise in a metric with no
  stated confidence interval — a reasonable-on-its-face pair (asymmetric
  by design: a smaller fall is treated as more urgent than an equal-sized
  rise, since a regressing mechanism actively hurts where a flat one
  merely fails to help) — but reasonable-on-its-face is not the same as
  validated. 30 days matches (in rhythm, not value — the two numbers are
  deliberately different, 30 vs. 180) the kind of policy-level day-count
  constant `templates/GROUNDING.yaml:10`'s `reverify_after_days` already
  establishes as a precedent shape for "a bare integer constant governing
  when accumulated state stops counting." All three are exactly the kind
  of default the pre-registered gates in this spec and the longitudinal
  spec exist to revisit with real evidence, not treated as permanent.
- **Whether "two audited weeks" cleanly aligns when adaptive suppression
  ships mid-week is not fully specified** — §4.9 names the mechanism
  (draw from the existing weekly-audit artifacts, wait for the boundary)
  but does not handle every calendar edge case (e.g., a week whose audit
  was skipped because "the repo saw no work,"
  `docs/specs/2026-08-13-exp-longitudinal.md:112`). I judged this an
  acceptable level of specification for a pre-registered gate whose
  parent gate (`docs/specs/2026-08-13-exp-longitudinal.md:76-89`'s
  original Tier-1 gate) already tolerates the same ambiguity ("first 5
  audited weeks," not "first 5 calendar weeks") without further
  definition — consistent with existing house practice, not a new gap
  this spec introduces.
