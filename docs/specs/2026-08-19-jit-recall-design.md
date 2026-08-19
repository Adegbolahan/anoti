# Just-in-Time Recall — the Presence Hook

**Status:** RATIFIED 2026-08-19 ("3" — commission the implementation
cascade) — adversarial review COMPLIANT-WITH-RESIDUE after three cycles
(1C+3M+7m fixed round 1; a round-1-introduced matcher no-op and a
self-caught yq-dialect bug fixed round 2). Named residue for the builder
under RED-first tests: `match_topic_statement` and retrieve's compaction
frame-filter are prose-only; awk portability verified on macOS only (CI
covers Linux at implementation).

**Spec:** this document. **Authority:** `docs/ROADMAP.md:96-105` (Phase 4
deliverable, "design spec is the next step, ratified 2026-08-19",
`docs/ROADMAP.md:97`, fix-round-2 residual correction to N1 — the earlier
fix-round-1 correction wrongly implied "blocked on this ratification" was
`docs/ROADMAP.md`'s own earlier draft state; git history shows that text
never appeared in `docs/ROADMAP.md` at any point. Its actual source is
`docs/plans/2026-08-18-roadmap-amendment-draft.md:57` — the
product-manager's proposed bullet text, written before the human's
2026-08-19 ratification substituted the wording that actually landed);
`docs/HIGH-LEVEL-STORIES.md:54-66`
(Audit — 2026-08-19, human-ratified Option A, "Human ruling 2026-08-19:
option A over a new story", `docs/HIGH-LEVEL-STORIES.md:65-66`);
`docs/plans/2026-08-18-jit-recall-cascade.md` (cascade plan, spawn #1);
skeptic verification, cascade spawn #3 (technical-foundation verdict,
relayed to this spawn in its dispatch brief — I did not re-run the live
capture myself; treated as input per the practitioner contract, flagged
again in Questions/doubts).

**roadmap_ref:** `docs/ROADMAP.md:96-105`. **story_ref:** `US-001`
(`docs/HIGH-LEVEL-STORIES.md:19,30-32`), extended by the 2026-08-19 audit
note (`docs/HIGH-LEVEL-STORIES.md:54-66`) rather than a new story, per the
human's ruling.

---

## 1. What this is

A single PostToolUse/PostToolUseFailure **presence hook**
(`scripts/presence`) that makes anoti's memory act at the moment of tool
use, not only at session start (`scripts/retrieve`, `hooks/hooks.json:3-13`)
or task start (`skills/attend/SKILL.md`). It carries four duties — JIT
recall, frame re-anchoring, an evidence-kind nudge, and telemetry — behind
one touchpoint, silent by default. Alongside it: a pull-side
`scripts/anoti recall <keywords...>` CLI sharing the same matcher; an
append-only `triggers:` record field with its own write helper
(`scripts/append-trigger`); a shared, sourced store-resolution+matcher
library (`scripts/store-resolve`, mirroring `scripts/store-lock`); session-
and telemetry-layer extensions that close two measurement gaps the cascade
plan found (§3d, `docs/plans/2026-08-18-jit-recall-cascade.md:201-235`);
evidence-kind discipline wired into policy and review text; and a
pre-registered metrics amendment to the longitudinal protocol. This spec
differs from every existing recall surface in this repo by firing
**during** tool use rather than before or after a session's work: the
SessionStart digest (`scripts/retrieve`) is a table of contents read once;
`/anoti:recall` (`commands/recall.md`) is an LLM-driven query the model
must think to run; this hook requires no invocation at all.

**Evidentiary status of the core mechanism (fix-round M3, precise
labeling):** that PostToolUse's `additionalContext` surfaces in the next
model turn is verified for this plugin's existing surfaces
(`scripts/retrieve:161`, `scripts/classify:24`). That it does so
**specifically for a non-MCP built-in tool on `PostToolUse`** — the exact
case this hook depends on — is skeptic spawn #3's SURVIVES verdict on U1,
assembled from three convergent sources: the documented mechanism, a
third-party plugin observed using the identical pattern (PostToolUse
combined with `additionalContext` on Edit and Write), and a transcript of
injected context acted on next turn. Convergent, but no single local
artifact combines "non-MCP built-in tool" and "`additionalContext`" within
one observed firing. Per G005, that composite claim is labeled
**probable, not established** everywhere this spec relies on it (§4.3.1,
§4.3.2) — not settled fact. Everything else skeptic spawn #3 verified
(the field names themselves, §4.3.2) stays at its verified weight.

## 2. Why

Three concrete field failures — cd-chain, stale Vite modules, popover
z-index — happened mid-task, at tool-use time, while the global records
that would have prevented them (`G004`, `G005`, `G008`,
`~/.claude/anoti/GROUNDING.yaml:45,46,49`) existed and never surfaced
(`docs/plans/2026-08-18-jit-recall-cascade.md:17-22`, cited by the human
directive that opened this cascade). D001's own staged pipeline names
"Retrieval & response — stored knowledge recalled to decide/act,
generating feedback that restarts the cycle" (`GROUNDING.yaml:146`) as a
distinct stage from "Attention & selection" (`GROUNDING.yaml:142`); today's
mechanisms cover session-start attention but not the retrieval-at-decision
moment D001 itself models. **Labeled inference** (shared with the cascade
plan, `docs/plans/2026-08-18-jit-recall-cascade.md:270-274`): D001 does not
use the term "encoding specificity", but its staged pipeline — an
encoding stage feeding a retrieval stage cued by the same features — is the
cited grounding for writing cues (`triggers:`) at write-time rather than
relying on retrieval-time reconstruction alone. US-001's ✅ status verifies
SessionStart delivery only (`docs/HIGH-LEVEL-STORIES.md:19,30-32`); the
2026-08-19 audit note names the gap this spec closes without reopening that
story (`docs/HIGH-LEVEL-STORIES.md:54-66`). This gap-closing motivation
depends on the mechanism §1 already labels **probable, not established**
(the non-MCP-tool + `additionalContext` combination, fix-round M3) — the
"why" holds regardless of that label (the field failures are real,
already-occurred events, §1's citation), but the "this spec closes it"
claim inherits the same evidentiary weight until the follow-on
implementation's first live test (§9) confirms the mechanism directly.

## 3. Design principles / constraints

1. **Carrot, not stick.** PostToolUse cannot block — "exit code 2 is
   honored but only shows stderr to Claude; the tool already ran" (cascade
   plan §3a, docs-fetch citation, `docs/plans/2026-08-18-jit-recall-cascade.md:125-128`).
   This is a structural property of the mechanism, not merely a design
   choice: the presence hook can only inform, never gate.
2. **Fail open, no network, POSIX shell + `yq`/`jq`** — identical to every
   hook this plugin ships (`docs/specs/2026-08-12-anoti-plugin-design.md:507-510`).
   `scripts/presence`'s own timeout is **5s**, not a plugin-wide constant
   (fix-round N4, corrected overclaim): `hooks/hooks.json` registers each
   hook's timeout individually — `retrieve` at 10s
   (`hooks/hooks.json:9`), `presence` at 5s (§4.3.1) — chosen tighter here
   because this hook fires far more often per session than `retrieve`
   does (principle 4 below), so a slow firing costs more in aggregate.
3. **Silent by default (US-002).** `docs/HIGH-LEVEL-STORIES.md:20,33-34`:
   "zero methodology overhead... no visible ritual on small asks." Nothing
   matched → nothing emitted, no telemetry line — the same contract
   `scripts/inhibit` already honors for its no-match row
   (`docs/specs/2026-08-12-anoti-plugin-design.md:527`) and that
   `tests/test_retrieve.sh:20-22` pins for the digest ("nothing to say ->
   no output").
4. **Budget scales with firing frequency, not just token cost.**
   `scripts/retrieve`'s digest budget (4000 chars, `scripts/retrieve:11`)
   is sized for one firing per session. This hook can fire on every
   matched tool call — potentially dozens of times per session — so its
   per-firing budget must be far smaller (§4.3.7 fixes exact numbers,
   labeled judgment, revisited by Tier-1 telemetry per §4.11).
5. **Untrusted-data envelope, always.** Every injected string is reference
   data, never instruction — the same framing `scripts/retrieve:158-160`
   already uses.
6. **Two-store + trust + lessons, exactly as `scripts/retrieve` already
   does it — never reinvented.** Global (`scripts/retrieve:74-75`),
   project (`scripts/retrieve:76-77`), trust check
   (`scripts/retrieve:16-17`), lessons resolution
   (`scripts/retrieve:86-93`), failure framing preserved not swallowed
   (`scripts/retrieve:26-30`).
7. **`entries_immutable` binds already-approved record bodies, not new
   optional fields** (`templates/GROUNDING.yaml:8`); the append-only shape
   of `triggers:` is this spec's own design choice, mirroring
   `evidence:`/`events:`/`relationships:`, not a schema-enforced rule —
   stated precisely, not overclaimed (§4.5).
8. **One component, one responsibility** (`roles/architect.md:29-31`):
   compaction-triggered frame re-anchoring belongs to the _existing_
   SessionStart/PreCompact hooks, not the new PostToolUse hook — see §4.7
   for why this is a different mechanism from periodic mid-session
   re-anchoring, which the new hook does own.

## 4. The design

### 4.1 Component map

| Component            | File                                           | New/changed                  | Responsibility                                                                                                       |
| -------------------- | ---------------------------------------------- | ---------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Presence hook        | `scripts/presence`                             | new                          | PostToolUse+PostToolUseFailure: JIT recall, periodic frame re-anchor, evidence-kind nudge, telemetry                 |
| Shared matcher lib   | `scripts/store-resolve`                        | new, sourced, non-executable | Store resolution (global/project/lessons) + trigger/keyword matching, used by `presence`, `recall`, and nothing else |
| Pull CLI             | `scripts/recall`                               | new                          | `anoti recall <keywords...>` — same matcher, human/agent-invoked                                                     |
| Trigger writer       | `scripts/append-trigger`                       | new                          | Append-only `triggers:` mutation, cloning `append-evidence`'s write contract                                         |
| Retrospect marker    | `scripts/mark-retrospect`                      | new                          | Durable telemetry line even on the "found nothing" retrospective path                                                |
| Store validator      | `scripts/validate-workspace`                   | extended                     | `triggers:` shape check                                                                                              |
| Session frame writer | `scripts/session-append`                       | extended                     | Telemetry line on every `frames` append                                                                              |
| Compaction stamp     | `scripts/persist-session`                      | extended                     | Stamps `.session.compacted_at`                                                                                       |
| SessionStart digest  | `scripts/retrieve`                             | extended                     | Reads `source`/`session_id` from stdin (currently discarded); re-anchors active frames after compaction              |
| Session cleanup      | `scripts/cleanup-session`                      | extended                     | Removes the new presence-state file; writes the durable summary line closing the "retrospect never ran" gap          |
| Dispatcher           | `scripts/anoti`                                | extended                     | Lists `presence` as a hook, like its five siblings                                                                   |
| Hook registration    | `hooks/hooks.json`                             | extended                     | Registers PostToolUse + PostToolUseFailure                                                                           |
| Policy text          | `skills/policy-epistemic/SKILL.md`             | extended                     | New numbered rule (evidence-kind ordering)                                                                           |
| Review text          | `commands/review-work.md`, `roles/reviewer.md` | extended                     | Evidence-kind checklist line                                                                                         |
| Consolidate skill    | `skills/consolidate/SKILL.md`                  | extended                     | Encoding-time trigger question                                                                                       |
| Recall command       | `commands/recall.md`                           | extended                     | Points at the mechanical CLI as a free pre-check                                                                     |
| Longitudinal spec    | `docs/specs/2026-08-13-exp-longitudinal.md`    | extended (dated changelog)   | Recall MISS + adherence metrics, Tier-1 gate                                                                         |

### 4.2 Shared library: `scripts/store-resolve`

Sourced, **not executable** — the precedent is `scripts/store-lock`, which
states its own convention explicitly: "This file is deliberately NOT
executable — it is a library, not an action" (`scripts/store-lock:8`).
`scripts/presence` and `scripts/recall` both `. "$SELF/store-resolve"`.

**Scoping decision (labeled judgment, handed to me as a choice by the
cascade plan, `docs/plans/2026-08-18-jit-recall-cascade.md:186-191`):**
`scripts/retrieve` is **not** refactored to source this library. Its
`hash_of`/`is_trusted`/`fx` primitives (`scripts/retrieve:16-21`) are
independently reproduced in `store-resolve` (six lines, cheap
duplication) rather than extracted out from under a file with its own
passing, exact-match-sensitive test suite (`tests/test_retrieve.sh`).
Reason: `store_digest` (`scripts/retrieve:24-66`) and the new matcher serve
different purposes at different call frequencies — refactor risk on a
tested, working, once-per-session file outweighs the savings from removing
~6 duplicated lines. `scripts/retrieve`'s own two required changes (§4.7)
are additive and orthogonal to store resolution.

**Exports:**

```sh
# scripts/store-resolve — sourced. Provides:
hash_of() { ... }        # identical to scripts/retrieve:16
is_trusted() { ... }     # identical to scripts/retrieve:17
fx() { ... }             # identical to scripts/retrieve:21 (case-exact existence)
cfgk() { ... }           # identical to scripts/retrieve:70-73 (.claude/anoti.local.md key read)

# resolve_global()  — prints "$HOME/.claude/anoti/GROUNDING.yaml" iff present,
#   validated, and trusted; else prints nothing and returns 1. Mirrors the
#   exact resolution scripts/retrieve:74-75 performs.
resolve_global() { ... }

# resolve_project() — prints the project GROUNDING.yaml path under the same
#   three gates, mirroring scripts/retrieve:76-77 (fx + validate + trust
#   against "$AD/trust").
resolve_project() { ... }

# resolve_lessons() — prints the lessons path via cfgk lessons_path,
#   defaulting to LESSONS-LEARNT.md, existence checked case-exactly (fx),
#   mirroring scripts/retrieve:86-93.
resolve_lessons() { ... }

# match_triggers <store> <haystack> <label>
#   O(1) yq subprocess spawns per store (fix-round M2 redesign, §4.3.3).
#   Prints "hits\tid\tlabel\tstatement" lines; caller sorts/ranks (§4.3.3).
match_triggers() { ... }

# match_topic_statement <store> <keyword> <label>
#   CLI-only broader net (§4.4, fix-round N6 — exported here, was used in
#   §4.4 without being listed): substring match against .records[].topic
#   and .records[].statement (not triggers). Same "hits\tid\tlabel\tstatement"
#   output shape as match_triggers (hits is always 1: a keyword either
#   matches across the two checked fields or it doesn't). Never called by
#   the presence hook — §4.3.3's "why triggers only" precision argument
#   applies to this function too, which is why it is CLI-only by design.
match_topic_statement() { ... }

# match_lessons <lessons-file> <keyword>
#   Same "hits\tid\tlabel\tstatement" output shape as match_triggers
#   (fix-round M1 — the original draft had no id/hit-count, so its output
#   could not merge/sort/dedupe/telemetry alongside match_triggers'
#   output). hits is always 1 per matching line (a lesson line either
#   contains the keyword or it doesn't — no per-line trigger array to
#   count multiple hits against). id is synthetic and stable:
#   "L:<first 8 hex chars of sha256(line text)>" — a line-number id would
#   silently shift whenever an earlier line is appended to
#   LESSONS-LEARNT.md's append-only growth, breaking recall_cache/dedupe
#   (§4.3.6) across sessions; a content hash of the line itself does not
#   shift. label is always "" (LESSONS-LEARNT resolves project-local only,
#   scripts/retrieve:86-93 — no global-tier lessons file exists in this
#   design). statement is the matched line, `sed 's/^- //'` then
#   `cut -c1-220`. Deliberately plain grep, no awk/ENVIRON at all — full
#   literal code + verification in §4.3.3 (fix-round 2, cycle-2 finding).
match_lessons() { ... }
```

Every caller must check the return of `resolve_*`; a failed resolution
(missing/invalid/untrusted) is reported once per session (§4.3.6 "warn
once"), never silently swallowed — required by constraint 6/principle
`scripts/retrieve:26-30`, adapted for firing frequency (§4.5).

### 4.3 The presence hook: `scripts/presence`

#### 4.3.1 Registration

```json
"PostToolUse": [
  {
    "matcher": "Bash|Write|Edit|NotebookEdit",
    "hooks": [
      { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/presence", "timeout": 5 }
    ]
  }
],
"PostToolUseFailure": [
  {
    "matcher": "Bash|Write|Edit|NotebookEdit",
    "hooks": [
      { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/presence", "timeout": 5 }
    ]
  }
]
```

Both event blocks point at the **same script** — this is the exact,
load-bearing correction skeptic spawn #3 relayed: "a hook registered only
on PostToolUse never sees a failed call or its error text; the presence
hook MUST register on both events." Matcher string mirrors the existing
PreToolUse matcher exactly (`hooks/hooks.json:27`, `scripts/inhibit`'s
own scope) — non-MCP tools only, the region the cascade plan already
confirmed sits outside the one documented PostToolUse+MCP gap
(`docs/plans/2026-08-18-jit-recall-cascade.md:118-124`). This entire
registration presupposes `additionalContext` actually surfaces for a
non-MCP built-in tool on `PostToolUse`/`PostToolUseFailure` — labeled
**probable, not established** (fix-round M3; full evidentiary accounting
in §1), not settled fact, even though the two-event requirement itself
(the correction quoted above) is established.

**Defense in depth (labeled judgment, closes an unverified assumption):**
whether the Claude Code harness honors a `matcher` field on
`PostToolUseFailure` identically to `PostToolUse` was not independently
confirmed by skeptic spawn #3 (its brief scoped to PostToolUse's field
names and the `additionalContext` mechanism, not PostToolUseFailure's
matcher semantics — flagged again in Questions/doubts). `scripts/presence`
therefore re-checks `tool_name` internally regardless of what fired it:

```sh
case "$tool" in Bash|Write|Edit|NotebookEdit) ;; *) exit 0 ;; esac
```

If the harness matcher already filters correctly, this is a no-op; if it
does not (fires for every tool), the script still degrades to silence for
anything outside scope — the assumption's truth stops mattering.

#### 4.3.2 Input contract

PostToolUse fields (skeptic-verified, live capture, cascade spawn #3):
`session_id, transcript_path, cwd, permission_mode, hook_event_name,
tool_name, tool_input, tool_response, tool_use_id, duration_ms`.
PostToolUseFailure fields (same verification, corrected from the earlier
draft's single-event assumption): `..., tool_name, tool_input,
tool_use_id, error, is_interrupt` — **no `tool_response`** on this event;
`error` carries the failure text instead. **Precise on what "verified"
covers (fix-round M3):** the field _names_ above are established by
skeptic spawn #3's live capture. That the resulting `additionalContext`
then surfaces in the next model turn **for this non-MCP-tool case
specifically** is the separate, convergent-but-not-directly-witnessed
claim §1 labels **probable, not established** — this whole input contract
is built on it, and the field-name verification does not itself settle
it. `hook_event_name` is read first
to branch:

```sh
input="$(cat 2>/dev/null || true)"
event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null)" || exit 0
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)" || exit 0
case "$tool" in Bash|Write|Edit|NotebookEdit) ;; *) exit 0 ;; esac
sid="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
[ -n "$sid" ] || exit 0
tin="$(printf '%s' "$input" | jq -c '.tool_input // {}' 2>/dev/null | cut -c1-8000)"
if [ "$event" = "PostToolUseFailure" ]; then
  outcome="$(printf '%s' "$input" | jq -r '.error // empty' 2>/dev/null | cut -c1-8000)"
else
  outcome="$(printf '%s' "$input" | jq -c '.tool_response // {}' 2>/dev/null | cut -c1-8000)"
fi
```

**`tool_response`'s per-tool shape is not independently known** (the
corrected foundation confirms the field's _name_, not its schema per tool
type — Bash likely carries stdout/stderr, Write/Edit something else
entirely). The design deliberately does not attempt per-tool field
extraction: `jq -c` serializes the whole value to compact JSON and the
matcher treats it as opaque text (§4.3.3). This trades a small amount of
matching noise (structural JSON tokens/keys entering the haystack) for
correctness across every tool type without per-tool schema knowledge —
labeled judgment.

**8000-char cap on `tool_input`/`outcome`:** bounds pathological payloads
(a multi-MB file write, a command with enormous stdout) so matching stays
O(haystack) and cheap regardless of payload size — not because normal
matching needs anywhere near that much text; it exists purely as a ceiling
inside the 5s timeout.

**`is_interrupt` (PostToolUseFailure only) does not gate the hook.** An
interrupted command's partial `tool_input` text is still valid recall
input; the hook does not special-case interruption.

#### 4.3.3 Duty (a): JIT recall — matching algorithm

**Haystack:** `$tin $outcome` (space-joined; case-folding happens inside
the match, not here — see below).

**Per-record matching (`match_triggers`, in `scripts/store-resolve`) —
redesigned for O(1) subprocess spawns TOTAL per store, not per record
(fix-round M2, empirically verified during this fix round):**

The original draft called `yq` three times per record (once for its
`triggers` list, once for `id`, once for `statement`) inside a
per-record loop — benchmarked by the reviewer at ~5.6ms per `yq` call on
this repo's own 24-record store, extrapolating to ~3.4s on two
~300-record stores for the trigger read alone, before `jq`/nudge/
reanchor/telemetry work even starts, against a 5s hook timeout (M2
finding). A first redesign attempt (one `yq` call per store piped into a
shell loop calling `grep -qiF` per trigger, mirroring the house pattern
`scripts/record-index:12-15`) was built and actually timed against a
synthetic 300-record fixture in this sandbox: **1.944s for one store**
(`{command: "yq ... | while read ... grep -qiF ...", output: "1.02s
user 0.77s system 92% cpu 1.944 total"}`) — still too slow across two
stores; the `grep`-subprocess-per-trigger cost (≈600 spawns for 300
records ×~2 triggers) dominated. Redesigned again to push the matching
itself **into a single `awk` pass** reading the same one-`yq`-call TSV
output.

**Fix-round-2 correction (NEW-C1, CRITICAL, reviewer cycle 2 — the
0.032s figure below was NOT measured against the literal code that ended
up in the fix-round-1 spec text):** that literal text used a shell
_prefix_ variable assignment, `MT_HAY="$2" \` immediately before the `yq`
invocation it shares a line-continuation with. Per POSIX §2.9.1, a
prefix assignment scopes only to the one simple command it prefixes — it
never crosses a pipe to reach `awk`, so `ENVIRON["MT_HAY"]` inside `awk`
was always empty. Verified by executing that exact function against a
fixture with the trigger literally present in the haystack: zero output
on every case (multi-word, plain, and a regex-metacharacter trigger),
exit 0 — silent, clean, wrong; the `G004` shape (a confident pass that
never actually checked anything). The interactive shell commands I ran
during fix round 1 to produce the 0.032s figure used `export
MT_HAY="$2"` as its own statement, a form that does propagate across the
pipe — **the benchmark measured the corrected form, not the broken form
that was actually written into the spec's code block.** Re-verified this
round two ways, both against the fixed form: first, a hand-typed copy in
a scratch harness (0.049s: `{command: "match_triggers store_300.yaml
...; match_triggers store_300b.yaml ..." (function sourced from a file,
called twice, timed as one block), output: "0.04s user 0.02s system 118%
cpu 0.049 total"}`); second — the decisive check — the exact bytes of the
code block below, `sed`-extracted straight from this file into a scratch
script and sourced, re-run against the same fixture: **0.032s for two
300-record stores combined** (`{command: "sed -n '<block-range>p'
docs/specs/2026-08-19-jit-recall-design.md > script.sh; . ./script.sh;
match_triggers store_300.yaml ...; match_triggers store_300b.yaml ...",
output: "0.04s user 0.01s system 158% cpu 0.032 total"}`) — this is what
now ships, verified as itself, not as a paraphrase of itself. Both runs
land in the same range as the reviewer's own reproduction (~0.033s), a
~40-60x improvement over the grep-loop attempt, comfortably inside the 5s
budget with room for the other three duties. Every correctness property
claimed below (multi-word substring, metacharacter-as-literal, hit
counting, silence on no match) was likewise re-verified this round
against the exact extracted bytes below, not merely assumed to carry
over from the earlier, differently-shaped test:

```sh
match_triggers() {  # $1=store $2=haystack $3=label ("" or "[global] ")
  f="$1"; label="$3"
  # ONE yq pass: one row per (record, trigger) pair; (.triggers // [])[]
  # emits zero rows for a triggerless record automatically. Piped into
  # ONE awk pass doing the matching itself (index()/tolower() are POSIX
  # awk, no extension needed) instead of a grep subprocess per trigger --
  # this is the change that took the design from 1.944s to ~0.03s (exact
  # figures + provenance in the prose above, fix-round 2 correction).
  #
  # export as its OWN statement, never a prefix assignment on the yq
  # command (fix-round-2 CRITICAL, NEW-C1): `MT_HAY="$2" yq ... | awk`
  # scopes the assignment to yq alone (POSIX 2.9.1, simple-command
  # scope) -- it never crosses the pipe, so ENVIRON["MT_HAY"] inside awk
  # is always empty and every match silently fails (verified: zero
  # output on every case, exit 0 -- the G004 shape, a confident pass
  # that checked nothing). `export` makes it a real environment
  # variable inherited by every subsequently exec'd child, awk included.
  export MT_HAY="$2"
  # Haystack passed via ENVIRON, NEVER awk -v: verified empirically that
  # -v processes backslash escapes in its value (a literal backslash-n /
  # backslash-backslash / backslash-t typed in the shell string becomes a
  # real newline/backslash/tab byte once inside awk) while ENVIRON
  # preserves the value byte-for-byte. tool_input/tool_response haystack
  # text is jq -c-serialized JSON (Sec 4.3.2) and routinely contains
  # literal backslash escapes (embedded quotes, literal backslashes,
  # newlines inside JSON string values); -v would silently corrupt it
  # before matching while triggers (read as awk fields, not via -v) would
  # not undergo the same corruption — an asymmetry that could cause real
  # misses. ENVIRON is the safe channel, used here.
  yq -r '.records[] | .id as $id | .statement as $s |
      (.triggers // [])[] | [$id, ., $s] | @tsv' "$f" 2>/dev/null |
  awk -F'\t' -v label="$label" '
    BEGIN { h = tolower(ENVIRON["MT_HAY"]) }
    {
      trig = tolower($2)
      if (trig != "" && index(h, trig) > 0) { cnt[$1]++; stmt[$1] = $3 }
    }
    END {
      for (id in cnt) {
        s = stmt[id]; if (length(s) > 220) s = substr(s, 1, 220)
        printf "%s\t%s\t%s\t%s\n", cnt[id], id, label, s
      }
    }
  '
  unset MT_HAY
}
```

`label` is passed via `awk -v` safely (unlike the haystack, `label` is
always one of two fixed literal strings — `""` or `"[global] "` — never
derived from arbitrary tool-call text, so it carries no backslash risk).
Precise definitions, each a direct answer to a dispatcher requirement:

- **Case-insensitive fixed-string per trigger:** `index(tolower(h),
tolower(trig)) > 0` — a literal substring test on case-folded text,
  with zero pattern-language ambiguity (awk's `index()` has no glob or
  regex semantics to accidentally invoke, unlike a shell `case` pattern
  or `grep -E`, either of which would let trigger metacharacters like
  `*`/`?`/`[` be interpreted rather than matched literally — the exact
  class of bug `G002` already names for `yq`'s `==` ("Freeform
  identifiers must never meet a yq ==" — the same "pattern-matching
  operator meets freeform text" shape,
  `~/.claude/anoti/GROUNDING.yaml:43`) and the reasoning `G004`'s own
  predicate literally asks for ("what result would make it FAIL",
  `~/.claude/anoti/GROUNDING.yaml:45`)). Case-insensitive matching itself
  is already this codebase's precedent (`grep -qiE`,
  `scripts/inhibit:78-79`) — `index()`/`tolower()` is the fixed-string
  equivalent, verified working (above) rather than assumed.
- **Multi-word triggers:** a trigger is matched as one literal substring
  — `"cd chain"` matches only if that exact (case-folded) run of
  characters appears in the haystack, not as a set of independently
  matched words. This is a deliberate precision-over-recall choice:
  authored triggers are short and specific by construction (§4.5's
  encoding-time question asks "what would you have needed to _see_"),
  so substring matching keeps false positives low without needing
  tokenization.
- **Ranking by hit count:** `tcount` per record = number of **distinct**
  triggers on that record that matched (not occurrences of any one
  trigger) — a record with two different matching triggers outranks one
  with a single matching trigger repeated many times in the haystack.
- **How the hook invokes `match_lessons` (fix-round M1 — closes an
  invocation-shape gap the original draft left implicit):**
  `match_lessons`'s signature (§4.2) takes one explicit `<keyword>`, which
  is straightforward for the CLI (a human/agent-supplied keyword, §4.4)
  but undefined for the hook, which has a haystack, not a keyword.
  **Resolution (labeled judgment):** the hook calls `match_lessons` once
  per **distinct trigger string that already matched at least one record**
  in this firing's `match_triggers` output (project or global) — lessons
  never fire "cold" on their own free text, only riding along on a cue
  already established as relevant to this specific tool call by an
  authored record trigger. If zero record triggers matched, `match_lessons`
  is not invoked at all this firing. This is the same precision-first
  scoping already argued below ("why triggers only, not statement/topic")
  extended honestly to lessons, which carry no authored `triggers:` field
  of their own to test independently.
- **Cross-source ranking + deterministic tie-break:** the caller collects
  `match_triggers` output from project store, global store (each
  correctly labeled), and `match_lessons` output from LESSONS-LEARNT —
  now schema-compatible by construction (fix-round M1, §4.2): every
  source emits the same `hits\tid\tlabel\tstatement` shape, lessons'
  `hits` always `1` per matching line and `id` the stable synthetic
  `L:<hash>` form (§4.2) — then sorts: `sort -t"$(printf '\t')" -k1,1nr`
  (hit count, descending), tie-broken by **source priority project >
  global > lessons** (labeled judgment: a project-scoped trigger is
  authored against this codebase's own vocabulary and is inherently less
  likely to be a coincidental match than a broadly-scoped global one — the
  same caution `G004`'s namespace-collision case names; lessons rank last
  as the least curated source), then by **id ascending** for full
  determinism (mirrors `scripts/record-index`'s exact-match discipline —
  `L:` sorts after bare record ids lexically, which is an acceptable,
  arbitrary-but-deterministic tie-break, not a claimed ordering of
  importance).
- **Dedupe per session:** a record/lesson-line id already injected is not
  re-injected until `N` tool calls have passed since its last injection
  in this session (`N = 10`, shared with periodic frame re-anchoring —
  §4.3.7 justifies the single shared constant). State lives in the new
  presence-state file (§4.3.6).
- **Hard caps:** at most **3** matched items injected per firing
  (`MAX_RECORDS=3`); each statement truncated to 220 chars (matching
  `scripts/retrieve:52`'s existing constant deliberately, for
  consistency of what "a truncated statement" looks like across this
  plugin's two digest surfaces). If more than 3 match after ranking, a
  terse `(+N more matched)` suffix is appended **only if it still fits**
  the overall firing budget (§4.3.7) — mirroring `scripts/retrieve`'s own
  `try_emit` budget-yielding pattern (`scripts/retrieve:15`).

**Why triggers only, not statement/topic (unlike the CLI, §4.4):** tool
call text is code/commands, not natural language. Matching against long
free-text `statement` fields against arbitrary command/output text would
false-positive heavily (a record whose statement happens to contain a
common word like "file" would fire on nearly every `Write`/`Edit` call).
Triggers are deliberately short, curated keywords authored _for_ this
purpose (§4.5); the CLI's broader statement/topic search is safe because
a human or agent explicitly invoked it and reads the ranked output
critically, rather than having it silently injected into working context.

**Literal code — `match_lessons` (fix-round 2, cycle-2 finding — the
original draft described this function only in prose/comments, §4.2; no
executable text existed to check for the same env-into-awk pitfall NEW-C1
found in `match_triggers`). Deliberately does NOT use `awk`/`ENVIRON` at
all** — a plain `grep`-based design, sidestepping that whole pitfall
class rather than repeating the export discipline it requires:

```sh
match_lessons() {  # $1=lessons-file $2=keyword; prints "hits\tid\tlabel\tstatement" lines
  lf="$1"; kw="$2"
  [ -n "$kw" ] || return 0
  [ -f "$lf" ] || return 0
  grep -iF -- "$kw" "$lf" 2>/dev/null | grep '^- ' | while IFS= read -r line; do
    stmt="$(printf '%s' "$line" | sed 's/^- //' | cut -c1-220)"
    hash="$(printf '%s' "$line" | shasum -a 256 | cut -c1-8)"
    printf '1\tL:%s\t\t%s\n' "$hash" "$stmt"
  done
}
```

`kw` reaches `grep -iF -- "$kw"` as a normal quoted shell argument, not
through an environment/`-v` channel at all — there is no prefix-assignment
or backslash-escaping hazard here because `grep`'s pattern argument is
taken literally, byte-for-byte, from argv (unlike `awk -v`, which
processes C-style escapes in its value, per NEW-C1's finding). Two `grep`
calls total regardless of file size (search, then re-filter to `^- `
lines only — mirroring `scripts/retrieve:87-92`'s own existing lessons
pattern of restricting to `^- ` lines); `shasum` runs only per actual
match, not per line scanned, so cost scales with hits, not file size.

Verified this round, literal text, sourced and run against a constructed
`LESSONS-LEARNT.md` fixture: a keyword present in one lesson line
matches and returns `1\tL:<8-hex>\t\t<line text, "- " stripped>`; an
absent keyword returns nothing, exit 0; and — the specific property the
design's own reasoning depends on — the **same line produces the same
`L:<hash>` id whether or not an unrelated earlier line is inserted before
it in the file** (`{command: "match_lessons lessons.md 'z-index'" run
against two fixtures differing only by an extra line prepended, output:
identical "L:20613d34" id both times}`), confirming the content-hash
choice actually delivers the position-independence the design argues for,
not merely asserting it. Multi-line lesson entries (a `^- ` line
continuing onto indented follow-on lines, the format
`LESSONS-LEARNT.md` itself already uses) are captured only by their
first line — the same limitation `scripts/retrieve:87-92`'s existing
lessons handling already has, not a new one introduced here.

#### 4.3.4 Duty (b): frame re-anchoring

Two mechanisms, **owned by different components** (constraint 8):

**Compaction recovery — owned by `scripts/retrieve`/`scripts/persist-session`, not by `scripts/presence`.** See §4.7; the new hook has no role here.

**Periodic mid-session re-anchoring — owned by `scripts/presence`, genuinely new.** On every matched firing:

1. Read/increment a tool-call counter in the presence-state file
   (§4.3.6).
2. Determine "slow-classified": read `.classifications[]` from
   `$AD/sessions/$sid.yaml` (written by `scripts/append-classification`,
   `scripts/append-classification:20`); `slow_classified = true` iff any
   entry has `verdict == "slow"`.
3. If `slow_classified` **and** `(tool_calls - last_frame_reanchor) >= N`
   (`N = 10`, §4.3.7) **and** a `frames:` entry with `status: active`
   exists (`skills/attend/SKILL.md:34-54`) → inject that frame's `goal`
   and `scope.in`, truncated to 200 chars combined; set
   `last_frame_reanchor = tool_calls`; emit telemetry
   (`frame-reanchor-periodic`, §4.3.6).

**N = 10, justified (labeled judgment, no empirical basis yet — exactly
the kind of default this spec's own Tier-1 gate exists to revisit,
§4.10):** roughly the tool-call count of a small multi-step task (a
handful of reads, an edit, a test run, a verification look) — high enough
to bias toward silence (US-002, `docs/HIGH-LEVEL-STORIES.md:33-34`) rather
than spamming every call, low enough that a session drifting for an
entire task's length without seeing its own goal again is not left
unanchored indefinitely. Same shape of "reasoned starting default,
revised by evidence" as `templates/GROUNDING.yaml:10`'s
`reverify_after_days: 180`.

#### 4.3.5 Duty (c): evidence-kind nudge

**Matcher-scope constraint, stated precisely rather than overclaimed:**
this hook's matcher is `Bash|Write|Edit|NotebookEdit` (§4.3.1) — it
**never** sees `Read` calls (a screenshot file being viewed) or MCP tool
calls (e.g. `chrome-devtools-mcp`'s screenshot/DOM-snapshot tools), because
neither is in scope. The plan's phrase "screenshot/read of rendered
output" is therefore realized here as: **Bash commands whose text matches
a small fixed pattern set associated with the brittle-instrument failure
modes `G004`/`G008` already evidence** (`~/.claude/anoti/GROUNDING.yaml:45`'s
own cited case: `"curl | grep -c on a Vite SPA returned 0 for a deleted
section... replaced with a rendered-DOM check"`) — not on the act of
taking a screenshot itself, which this hook structurally cannot observe.
Broader coverage (MCP-tool-aware nudging) is named as a Tier 3 candidate
(§4.11), not built here.

**Pattern set (fixed-string/regex, case-insensitive, checked against
`tool_input`'s command text only):**

- `curl` and `grep` both present in the same command (piped or chained) —
  the exact shape of the cited `G004` evidence instance.
- `grep -c` used against output that was itself produced by a `curl`/`wget`
  fetch earlier in the same command chain.

On a match, inject one line (≤150 chars):

```
evidence-kind: nearer-to-ground-truth instruments (DOM query, DB read) catch what curl|grep misses on rendered output — G004/G008
```

citing `G004` (`~/.claude/anoti/GROUNDING.yaml:45`) and `G008`
(`~/.claude/anoti/GROUNDING.yaml:49`) by id, per policy-epistemic's
artifact-citation rule (`skills/policy-epistemic/SKILL.md:24-28`).

#### 4.3.6 Duty (d): telemetry

One line **per duty that actually fired** in a given tool call — if both
recall and the evidence-nudge fire on the same call, two lines are
appended. Format, mirroring the three existing telemetry-line precedents
(`scripts/append-classification:23`: `ts\tsid\tverdict\treason`;
`scripts/set-episode:19`: `ts\tsid\tepisode\t<state>`; `scripts/inhibit:13`:
`ts\tsid\tinhibit\t<decision>\t<reason>`):

```
ts\tsid\tpresence\t<duty>\t<detail>
```

`<duty>` ∈ `{recall, frame-reanchor-periodic, evidence-nudge}` (compaction
recovery's telemetry is emitted by `scripts/retrieve`, not this script —
see §4.7). `<detail>`:

- `recall`: comma-separated `id[label]` pairs actually injected, e.g.
  `G004[global],D007[],L:a1b2c3d4[]` — the third form is a lesson hit
  (§4.2's synthetic `L:<hash>` id, fix-round M1).
- `frame-reanchor-periodic`: the frame id.
- `evidence-nudge`: the matched pattern name (`curl-grep`).

**Store-resolution failure reporting, deliberately different from
`scripts/retrieve`'s per-firing report (`scripts/retrieve:26-30`):**
because this hook can fire many times per session, repeating "store
present but not trusted" on every single matched tool call would violate
silence-by-default and swamp the transcript. `scripts/presence` reports
each resolution failure **once per session**: the presence-state file
carries a `warned: {global: bool, project: bool}` map; a failure is
emitted (as `additionalContext`, plus a `presence\twarn\t<store>` telemetry
line) only the first time it is seen this session, then suppressed. This
is a stated, labeled deviation from constraint 6/`scripts/retrieve:26-30`
— chosen because "report, don't silently skip" and "silent by default"
both bind here and firing-frequency forces a tie-break; once-per-session
still satisfies "never a silent skip" (the human/agent sees it at least
once) without spamming.

**Presence-state file:** `$AD/sessions/$sid.presence.yaml` — deliberately
**separate** from `$AD/sessions/$sid.yaml` (the frames/classifications
file `scripts/session-append` and `scripts/append-classification` write),
to avoid write-amplifying that file with per-tool-call churn and to avoid
lock contention with `attend`'s own frame writes (labeled judgment).
Shape:

```yaml
tool_calls: 0
last_frame_reanchor: 0
recall_cache: {} # record/lesson id -> tool_calls value at last injection
warned: { global: false, project: false }
```

Written under `scripts/store-lock`'s `lock_store`/`unlock_store`
(`scripts/store-lock:9-47`), the same primitive every other session-state
writer uses. **Contention is expected to be near-zero:** a single session
processes one tool call at a time in the common case; the one scenario
where concurrent presence firings could contend is subagent tool calls
sharing the parent's `session_id` — genuinely unknown whether they do
(flagged in Questions/doubts, not assumed either way; the lock's own 60s
ceiling is moot here since the hook's own 5s timeout kills the process
first if contention were ever that severe).

#### 4.3.7 Budget, in one place

| Constant                                         | Value                                                           | Rationale                                                                                                                                                                 |
| ------------------------------------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BUDGET_TOTAL`                                   | 1200 chars (~300 tokens) per firing, across all duties combined | Far below the SessionStart digest's 4000 chars (`scripts/retrieve:11`) because this hook can fire dozens of times per session where SessionStart fires once (principle 4) |
| `MAX_RECORDS`                                    | 3                                                               | Caps JIT recall's per-firing record count                                                                                                                                 |
| Statement truncation                             | 220 chars                                                       | Matches `scripts/retrieve:52`'s existing constant for consistency                                                                                                         |
| Frame re-anchor text                             | ≤200 chars                                                      | goal + scope.in, truncated                                                                                                                                                |
| Evidence-nudge text                              | ≤150 chars                                                      | One line                                                                                                                                                                  |
| `N` (periodic re-anchor interval, dedupe window) | 10 tool calls                                                   | §4.3.4 justification; shared constant, revisited by Tier-1 telemetry                                                                                                      |
| `tool_input`/`outcome` haystack cap              | 8000 chars each                                                 | Bounds pathological payloads (§4.3.2)                                                                                                                                     |

**Priority order when duties concurrently exceed `BUDGET_TOTAL`** (rare —
multiple duties firing on one call): `recall` > `evidence-nudge` >
`frame-reanchor-periodic`, applied via `try_emit`-style budget yielding
(`scripts/retrieve:15`'s pattern) — recall is the core JIT value; the
nudge is short and rarely the one cut; frame content also naturally
resurfaces at the next SessionStart/compaction moment, making it the
least costly duty to drop under pressure.

### 4.4 Pull-side CLI: `scripts/recall` / `anoti recall` / `/anoti:recall`

`scripts/recall <keywords...>` — dispatched via `scripts/anoti recall
<keywords...>` per the existing "the action IS the script name" contract
(`scripts/anoti:2-3,34-35`). Sources `store-resolve`; for each keyword,
runs `match_triggers` **and** a broader `match_topic_statement` pass
(new, `store-resolve`: substring match against `.records[].topic` and
`.records[].statement`, case-insensitive fixed-string — `grep -qiF` is
sufficient here, unlike `match_triggers`'s `awk` redesign (fix-round M2,
§4.3.3): this function is CLI-only, invoked once per human/agent query,
not once per tool call, so it carries none of the firing-frequency
perf pressure that motivated `match_triggers`'s redesign) against both
stores, plus `match_lessons` against LESSONS-LEARNT — the broader net
justified in
§4.3.3's "why triggers only" note: a human/agent explicitly invoked this,
so higher recall at the cost of some noise is the right trade, the inverse
of the hook's precision-first stance. Output: ranked list (same
tie-break as §4.3.3), `[global] ` labels preserved
(`scripts/retrieve:75`'s label convention), each result flagged with its
`epistemic_status`/`ratification` — mirroring `commands/recall.md:15-16`'s
existing framing exactly ("an unratified or speculative record is flagged
as such, never presented as settled fact") — and wrapped in the same
untrusted-data envelope (`scripts/retrieve:158-160`).

**Naming disambiguation (flagged by the cascade plan as a naming overlap,
not a technical collision, `docs/plans/2026-08-18-jit-recall-cascade.md:192-199`
— resolved here):** `anoti recall` is a mechanical shell CLI;
`/anoti:recall` (`commands/recall.md`) is an LLM-driven slash command that
has the model itself run `yq` queries. They do not collide at any
invocation layer (shell dispatch vs. slash-command prompt), only in the
word "recall". `commands/recall.md` gains a new step 0, prepended before
its existing step 1 (`commands/recall.md:8`):

```
0. Mechanical pre-check (free, no model reasoning needed): run
   `anoti recall <topic-keywords>` first — it runs the exact matcher the
   presence hook uses, over triggers/topic/statement in both stores plus
   LESSONS-LEARNT, and prints ranked hits instantly. Use the steps below
   when it comes up empty, or when you need deeper synthesis (evidence,
   events, open questions) than the mechanical matcher shows.
```

### 4.5 `triggers:` schema, `scripts/append-trigger`, validator check

**Schema (additive, `templates/GROUNDING.yaml` reference-comment block
gains one line after `templates/GROUNDING.yaml:20` `statement:`, fix-round
N2 correction — line 24 is `evidence: []`, not `statement:`):**

```yaml
triggers: [] # optional; short authored keywords/phrases matched at tool-use time (append-only via scripts/append-trigger)
```

**Precise, not overclaimed, on immutability (§ principle 7):**
`meta.policy.entries_immutable: true` (`templates/GROUNDING.yaml:8`) is
**prose, unenforced** by any code path — `scripts/validate-workspace`
enumerates no closed set of top-level record keys
(`scripts/validate-workspace:1-53`, confirmed by direct read: only nested
keys under `source`/`events`/`evidence`/`relationships` are checked,
`scripts/validate-workspace:27-36`) and `scripts/append-record` passes
JSON through untouched (`scripts/append-record:13`). Nothing mechanically
stops a future hand-edit from overwriting `triggers:` wholesale. The
append-only shape is this spec's own **recommended design** — an
accumulating, auditable cue set, mirroring `evidence:`/`events:`/
`relationships:`'s already-append-only convention — enforced only by
`scripts/append-trigger`'s own contract (it has no "replace" mode), not by
the schema. A hand-edit bypassing the helper would not be caught by
`validate-workspace` today; that gap is named, not silently assumed away.

**`scripts/append-trigger <store.yaml> <record-id> <keyword>...`** — clones
`scripts/append-evidence`'s write contract exactly, per the dispatcher's
explicit brief, with one deliberate strengthening:

1. `record-index` resolves `<record-id>` to its exact list index
   (`scripts/record-index`, exact shell comparison — never a `yq ==`,
   per `G002`, `~/.claude/anoti/GROUNDING.yaml:43`) — refuses unknown ids,
   mirroring `scripts/append-evidence:12-13`.
2. `store-lock`'s `lock_store`/`unlock_store`, trap on EXIT
   (`scripts/append-evidence:31-33`).
3. `yq ".records[$idx].triggers += [...]"` — append only, never
   overwrite (mirrors `scripts/append-evidence:35`'s `.evidence += [...]`
   shape exactly).
4. Validate the result before committing
   (`scripts/append-evidence:37`'s pattern: write to `.tmp.$$`, validate,
   refuse on failure, store untouched).
5. Preserve file mode (`scripts/append-evidence:38-39`'s `stat`/`chmod`
   dance), atomic `mv` (`scripts/append-evidence:40`).
6. **Deliberate strengthening beyond `append-evidence`, corrected for the
   global store (CRITICAL fix-round finding C1, dispatcher-ruled):**
   `scripts/append-trigger` also runs `regen-index`, then **attempts**
   `trust` on the result — the original draft claimed this cloned
   `scripts/append-record:18`'s "self-contained" `regen-index && trust`
   pattern, but that claim was refuted empirically: `scripts/trust:15-18`
   refuses any store path under `$HOME/.claude/anoti/` unless called with
   `--global` (`scripts/trust:4-6`'s "deliberate friction on the
   machine-wide path"), and neither `append-record`'s literal pattern nor
   a naive clone passes it — running `append-record`'s pattern against a
   global-path store exits 0 while the trailing `trust` call fails
   silently, leaving the store **untrusted**. This would have broken the
   spec's own flagship motivating example (§2) — retrofitting triggers
   onto the global `G004`/`G005`/`G008` records — exactly as the reviewer
   found: the very next `retrieve`/`presence` firing would report
   "not yet trusted; not loaded" against the store `append-trigger` just
   wrote to. **Fix, matching the pattern the `set-*` helpers already
   ship** (`scripts/set-ratification:35-36`, the same shape recurs in
   `set-status`/`resolve-question`) — never silently threading `--global`
   in, which would override a deliberate consent gate:

   ```sh
   "$SELF/regen-index" "$f"
   "$SELF/trust" "$f" >/dev/null 2>&1 \
     || echo "append-trigger: store written and indexed but NOT re-trusted — machine-wide scope requires explicit consent: scripts/trust --global $f" >&2
   exit 0
   ```

   On the project path, `trust` (no flag needed) succeeds and this is
   invisible — `append-trigger` stays fully self-contained, as originally
   intended. On the global path, the store is still written, indexed, and
   valid; only re-trust is deferred, exactly the state
   `skills/consolidate/SKILL.md:156`'s own global-tier opt-in flow already
   expects the human to close explicitly (`scripts/trust --global
<store>` as its own named step) — `append-trigger` degrades to
   `append-evidence`'s existing deferred-trust contract
   (`skills/consolidate/SKILL.md:115-116`, step 9) on this one path,
   loudly flagged rather than silently assumed. `regen-index` is a
   content no-op here (`triggers:` is not part of the generated index
   shape, `scripts/regen-index:7`) but is run anyway, unconditionally, for
   hygiene/idempotency consistency with `append-record`'s contract — its
   success does not depend on `--global` the way `trust`'s does.

**`scripts/validate-workspace` gains a triggers shape check** (new check,
inserted alongside the existing per-record checks at
`scripts/validate-workspace:21-24`): `.records[i].triggers`, if present,
must be a list whose every element is a non-empty string. Contract:
absent `triggers:` passes (optional field); `triggers: []` passes (empty
list is valid, not yet an error state — a record simply has no cues yet);
`triggers: ["", "x"]` fails (`"" ` is not a non-empty string);
`triggers: "x"` fails (bare scalar, not a list); `triggers: [1, "x"]`
fails (non-string element). Suggested check shape (implementation
guidance for the backend builder, not mandated literal code — the
_contract_ above is what's required):

**Self-discovered fix (fix-round 2's mandatory execution pass, not a
reviewer-relayed finding): the first draft's suggested shape used
`if (. | type) == "!!seq" then ... else ... end`, jq syntax that
`mikefarah/yq` — the actual binary this whole codebase runs (`yq
(https://github.com/mikefarah/yq/) version v4.53.2` in this
environment) — does not support at all.** Verified: even the minimal
`yq -r 'if .x == 5 then "yes" else "no" end'` fails with `Error: 1:1:
lexer: invalid input text "if .x == 5 then..."`, identical to the error
the full expression produced. Because the failure was piped through
`2>/dev/null` and captured into `$bad` via `$(...)`, a lexer error
produces empty stdout — indistinguishable from "no bad elements found"
without checking the exit code, so the broken check would have silently
never flagged anything, ever: the exact non-falsifiable-predicate shape
`G004` itself warns against. Rebuilt using this codebase's own idiom —
`case` on a `type` extraction for the enum check (already this file's
pattern at `scripts/validate-workspace:17`) and a `select()` **wrapped in
`[...] | length`**, never a bare `select()`, because a bare `select()`
matching an empty-string element also prints nothing in `-r` mode —
the identical non-falsifiability trap one level down, caught only by
checking that a `select()` on a deliberately-empty-string fixture in
this sandbox returned a count, not by trusting the pattern on sight.
Every branch (absent, empty list, good list, empty-string element, bare
scalar, non-string element) was executed against a constructed fixture
this round and produced the contractually-required pass/fail:

```sh
tt="$(yq -r ".records[$i].triggers | type" "$f" 2>/dev/null)"
case "$tt" in
  "!!null") ;;  # absent — optional field, valid
  "!!seq")
    bad="$(yq -r "[.records[$i].triggers[] | select((. | type) != \"!!str\" or . == \"\")] | length" "$f" 2>/dev/null)"
    [ "$bad" = "0" ] || fail "records[$i]: triggers must be a list of non-empty strings ($bad bad element(s))"
    ;;
  *) fail "records[$i]: triggers must be a list (got $tt)" ;;
esac
```

### 4.6 Consolidate skill: the encoding-time question

`skills/consolidate/SKILL.md` gains a new step **2b**, inserted between
the existing step 2 ("Type every candidate", `skills/consolidate/SKILL.md:61-64`)
and step 3 ("Citations", `skills/consolidate/SKILL.md:65-67`):

```
2b. **Encoding-time cue question (for `claim`/`policy`/`decision`
   candidates likely to matter mid-task, not only at review time):** ask
   "what would you have needed to *see* — a command, a file path, an
   error string — to be reminded of this at the moment it mattered?" If
   the answer names concrete text, capture it as `triggers:` on the
   record the moment it is appended: `scripts/append-trigger <store>
   <id> <keyword>...`. Skip silently for candidates with no natural
   tool-use-time cue (e.g. a `preference` about communication style) —
   not every record needs triggers, and forcing the question onto every
   candidate would just produce noise triggers that degrade the hook's
   precision (§4.3.3).
```

This is a skill-file edit, not a spec/direction-organ change — no dated
changelog or ratification gate applies (`skills/spec/SKILL.md`'s
changelog rule binds _specs_; `skills/direction/SKILL.md`'s ratification
gate — fix-round N3 correction, the path is `skills/direction/SKILL.md`,
not `docs/direction/SKILL.md`, which does not exist — binds
`docs/ROADMAP.md`/`docs/HIGH-LEVEL-STORIES.md` only,
`skills/direction/SKILL.md:8-11`).

### 4.7 Compaction recovery (owned by existing hooks, not the new one)

Per constraint 8 and the cascade plan's own lower-risk framing
(`docs/plans/2026-08-18-jit-recall-cascade.md:276-287`):

**Primary detection — `scripts/retrieve` branches on `source == "compact"`.**
`scripts/retrieve` currently **discards stdin entirely**
(`scripts/retrieve:10`: `cat >/dev/null 2>&1 || true # consume stdin;
digest does not depend on it`) — this is the single line that changes
first: retrieve now parses `session_id` and `source` from its own stdin
JSON instead of discarding it. On `source == "compact"`, after building
the normal digest, retrieve additionally reads `frames:` from
`$AD/sessions/$sid.yaml` (`skills/attend/SKILL.md:34-54`'s shape),
filters `status: active`, and emits one line per active frame:

```
- frame re-anchored (post-compaction): <goal, truncated> — scope: <scope.in, truncated>
```

then a telemetry line `ts\tsid\tpresence\tframe-reanchor-compaction\t<frame-id>`
— this is emitted by `retrieve`, not `presence`, since the whole
mechanism lives in the SessionStart hook (§4.3.6 already scoped
`presence`'s telemetry to its own three duties).

**`source`'s exact enum, unverified by this spec (flagged, not
assumed):** the cascade plan's own citation of `"startup"|"resume"|
"clear"|"compact"` traces to doc-based research, not a live capture the
way PostToolUse's fields were (skeptic spawn #3 verified PostToolUse
specifically, per the dispatch brief — SessionStart's `source` field was
not in its scope). This carries the same `probable, not established`
evidentiary weight G005 requires be stated precisely
(`~/.claude/anoti/GROUNDING.yaml:46`) — named in Questions/doubts, and
covered by the fallback below.

**Fallback/corroboration — `scripts/persist-session` stamps
`.session.compacted_at`.** `scripts/persist-session:17` already stamps
`.session.flushed` on every PreCompact firing; the same line gains a
sibling stamp: `.session.compacted_at = "$(date -u +%Y-%m-%dT%H:%M:%SZ)"`.
This is **not** the primary detection path (avoiding the complexity of a
second cross-invocation "have I already re-anchored since this
stamp" check) — it exists as a **durable, independently-queryable
corroboration signal for telemetry/audit**: "a compaction happened at T;
did the digest fired immediately after carry a re-anchor line" becomes
answerable from `telemetry.log` timestamps alone, without needing to diff
session-state snapshots — closing exactly the false-absence shape `G008`
warns about (`~/.claude/anoti/GROUNDING.yaml:49`) and mirroring the
cascade plan's own §3d gap-closing recommendation
(`docs/plans/2026-08-18-jit-recall-cascade.md:227-235`). If live testing
during implementation (first item of the follow-on plan's verification
step, per Branch B's "undetermined" case,
`docs/plans/2026-08-18-jit-recall-cascade.md:437-441`) shows `source`
does not reliably equal `"compact"` in this installation, `retrieve` can
be extended to treat a fresh, unconsumed `.session.compacted_at` as an
alternate trigger — named here as the documented fallback path, not built
speculatively ahead of evidence it's needed.

### 4.8 Session-state / telemetry additions closing the two measurement gaps

Both gaps and fixes are the cascade plan's own §3d finding
(`docs/plans/2026-08-18-jit-recall-cascade.md:212-235`), specified
precisely here:

**Gap 1 — frame writes leave no durable trace.** `scripts/session-append`
never writes to `telemetry.log`
(`docs/plans/2026-08-18-jit-recall-cascade.md:212-214`, confirmed by
direct read of `scripts/session-append:1-41`: no telemetry call
anywhere), and session YAML is deleted at clean SessionEnd
(`scripts/cleanup-session:13`). **Fix:** `scripts/session-append` emits
`ts\tsid\tframe\t<frame-id>` to `telemetry.log` whenever `key == "frames"`,
mirroring `scripts/set-episode:19`'s existing pattern exactly (same
tab-separated shape, same `$AD/telemetry.log` target, same best-effort
`|| true` suffix so a telemetry-write failure never blocks the actual
session-state write).

**Gap 2 — "retrospect ran, found nothing" is indistinguishable from
"retrospect never ran."** No existing helper marks this either way.
**Fix:** new helper `scripts/mark-retrospect <session-id> <empty|filed>` —
mechanical, one telemetry line: `ts\tsid\tretrospect\t<empty|filed>`.
`skills/consolidate/SKILL.md` step 11 (the retrospective step,
`skills/consolidate/SKILL.md:125-130`) gains an instruction to call this
helper on **both** branches — "trivial sessions route nothing" (existing
text, `skills/consolidate/SKILL.md:130`) now additionally calls
`scripts/mark-retrospect <sid> empty`; a session that files lessons/TODOS
calls `scripts/mark-retrospect <sid> filed`.

**Durable per-session summary, closing both gaps at the point session
state is about to disappear:** `scripts/cleanup-session` (SessionEnd,
`hooks/hooks.json:59-68`), before its existing `rm -f`/`mv` branch
(`scripts/cleanup-session:12-15`), emits one summary line:

```
ts\tsid\tsummary\tslow=<n>\tframes=<n>\tretrospect_ran=<bool>\tepisode=<final>
```

where `slow` = count of `slow` verdicts in `.classifications[]`, `frames`
= length of `.frames[]`, `retrospect_ran` = true iff a `retrospect`
telemetry line for this `sid` (written by `scripts/mark-retrospect`,
above) exists in `telemetry.log` (`grep`-checked, not re-derived from
session state, since session state is about to be deleted), `episode` =
final `.episode` value. This is the durable artifact "% slow-classified
sessions with a frame" and "% nontrivial sessions with a retrospect"
(§4.10) are computed from — mechanical, not memory-dependent, closing
exactly the "measure this from durable artifacts, not session recall"
requirement the cascade plan's §3d names
(`docs/plans/2026-08-18-jit-recall-cascade.md:216-217,221`).
`scripts/cleanup-session` also removes
`$AD/sessions/$sid.presence.yaml` alongside the existing
`$sf`/`.abandoned.yaml` handling (§4.3.6's state file).

### 4.9 Evidence-kind discipline — exact wording

**`skills/policy-epistemic/SKILL.md` — new numbered rule 6**, inserted
after the existing rule 5 (`skills/policy-epistemic/SKILL.md:29-30`),
before `**Binds:**` (`skills/policy-epistemic/SKILL.md:32`):

```
6. When a verification claim rests on one instrument, prefer the one
   nearer to ground truth: a DOM query or a database read settles what a
   screenshot or a raw-text grep can only suggest — screenshot < DOM
   query < DB query, ordered by distance from the system's actual state.
   Before trusting the farther instrument, ask what result would make it
   FAIL to find the thing (G004) or FAIL to have looked properly (G008)
   — if a nearer instrument was available and unused, that is a finding,
   not sufficient evidence.
```

**`commands/review-work.md` — new checklist bullet**, inserted after the
existing "Frontend" bullet (`commands/review-work.md:40-41`), inside Step
2's dimension list:

```
- **Evidence kind** (where a verification claim is made) — screenshot <
  DOM query < DB query, nearest-to-ground-truth instrument used for the
  claim; a claim resting on a farther instrument when a nearer one was
  available and unused is a finding, not evidence (G004/G008).
```

**`roles/reviewer.md` — checklist clause**, appended to the existing
"Verify the builder's evidence actually shows what it claims" sentence
(`roles/reviewer.md:15-16`):

```
**Approach — adversarial.** Try to break the work: hunt the input that
crashes it, the state that corrupts it, the requirement it silently
skipped. Verify the builder's evidence actually shows what it claims
(re-read the cited lines; distrust the report) — when a claim rests on a
screenshot where a DOM or DB query was available and unused, treat the
farther instrument as a finding, not sufficient evidence (G004/G008).
Calibrate severity —
```

(shown with one line of surrounding context on each side so the exact
insertion point is unambiguous — the technical-writer applies only the
new clause, `roles/reviewer.md:15-16` unchanged otherwise.)

### 4.10 Metrics amendment — `docs/specs/2026-08-13-exp-longitudinal.md`

Per the spec skill's amendment rule ("amendments after acceptance get
dated changelog entries, not silent edits", `skills/spec/SKILL.md:20-21`)
and this file's **own established precedent** for how it has already been
amended once (`docs/specs/2026-08-13-exp-longitudinal.md:69-70`: a new
table row — "Cross-project citations" — added directly, accompanied by a
dated changelog entry naming the authority): this spec adds three new
Metrics-table rows directly and appends a dated changelog entry, exactly
matching that precedent rather than inventing a different amendment
style.

**New rows, appended to the table at `docs/specs/2026-08-13-exp-longitudinal.md:27-35`:**

```
| Recall MISS | A retrospect names friction/failure a durable record's or lesson's `triggers:` covered, cross-checked against telemetry.log showing no matching `presence...recall` line for that id in the session's window — established positively (three-part check: named in retrospect + triggers existed + telemetry absence confirmed), never from telemetry silence alone (G008) | retrospect + telemetry.log + record `triggers:` |
| Frame adherence | % of slow-classified sessions (≥1 `slow` verdict in the session's durable `summary` telemetry line) whose `summary` line shows `frames` ≥ 1 | telemetry.log (`frame` lines via session-append; `summary` line via cleanup-session, §4.8) |
| Retrospect adherence | % of nontrivial sessions (same slow-classified definition) whose `summary` line shows `retrospect_ran=true` | telemetry.log (`retrospect` lines via mark-retrospect; `summary` line via cleanup-session, §4.8) |
```

**New Decision rules**, appended after the existing rules
(`docs/specs/2026-08-13-exp-longitudinal.md:37-49`):

```
- **Recall MISS rate > 0 in an audit week** → tuning TODO named per
  record/lesson id (its `triggers:` coverage needs improving) —
  mirroring the existing "False-positive guardrail rate > 1/week →
  tuning TODO" pattern (`docs/specs/2026-08-13-exp-longitudinal.md:48-49`)
  rather than treating it as an incident: a single miss is a coverage
  gap to close, not a governance failure.
- **Frame or Retrospect adherence < 100%** among slow-classified/nontrivial
  sessions in one audit week → filed as a lesson (a single week's shortfall
  may be explainable); **two consecutive weeks below 100% on the same
  metric** → corrective TODO, mirroring the existing "two incidents in one
  audit → a corrective TODO" pattern (`docs/specs/2026-08-13-exp-longitudinal.md:39-41`).
- **Nudges-emitted vs. adherence-after** is not an independent count but a
  derived comparison: of sessions with ≥1 `presence` telemetry line in a
  week, what fraction show the nudged content actually used afterward —
  a `recall` nudge citing record X followed by X being cited in the
  session's eventual work/report or trail; a `frame-reanchor-*` nudge
  followed by subsequent tool calls staying inside the frame's stated
  `scope.in`; an `evidence-nudge` followed by the nearer instrument
  actually being used. Source: telemetry.log cross-referenced against the
  session's own trail (report citations, diff, subsequent tool calls).
  This is the leading indicator the pre-registered Tier-1 gate below
  reads.
```

**Pre-registered Tier-1 gate** (new subsection, appended after Decision
rules, before Cadence & cost — `docs/specs/2026-08-13-exp-longitudinal.md:51`):

```
## Tier-1 gate (pre-registered, frozen 2026-08-19)

Tiers 2/3 (docs/specs/2026-08-19-jit-recall-design.md §4.11) are not
built until Tier 1's own telemetry earns them — this is a decision rule,
not a commitment to build either.

- **Tier 2 justified** when, across the first 5 audited weeks after this
  hook ships, adherence-after (nudges heeded / nudges emitted) is
  measurably below 100% AND at least 3 of those weeks show a Recall MISS
  or a frame-adherence shortfall attributable to accumulated drift across
  many individually-compliant tool calls rather than to missing
  `triggers:` coverage — a pattern per-call matching structurally cannot
  catch (no single call is the offender) but a periodic broader sweep
  over session state and trail could.
- **Tier 3 justified** when ≥2 audited weeks show recurring
  advisory-pattern telemetry lines (a drift pattern the hook can match
  but not judge, per §4.11) that the main session did not act on within
  the same session at least twice.
- Both thresholds are **labeled judgments extending this file's existing
  decision-rule style** (`docs/specs/2026-08-13-exp-longitudinal.md:37-49`'s
  "N consecutive weeks/incidents" shape) — no data exists yet to derive
  them empirically; revisit once the first audits accumulate evidence,
  the same discipline this file's changelog already practices
  (`docs/specs/2026-08-13-exp-longitudinal.md:61-70`).
```

**Changelog entry, appended after the existing two
(`docs/specs/2026-08-13-exp-longitudinal.md:63-70`):**

```
- 2026-08-19 — amended per `docs/specs/2026-08-19-jit-recall-design.md`
  (ratified Phase 4 deliverable, `docs/ROADMAP.md:96-105`): three new
  metrics (Recall MISS, Frame adherence, Retrospect adherence), two new
  decision rules, and a pre-registered Tier-1 gate governing whether
  Tiers 2/3 of the presence-hook wake architecture get built. Backfills
  the missing **Execution routing** section this file lacked
  (`skills/spec/SKILL.md:70-75` requires it for experiment specs) —
  runner: a fresh general-purpose agent dispatch, unnamed to any
  `roles/` hat (this file's own text already specifies "a fresh auditor
  agent", `docs/specs/2026-08-13-exp-longitudinal.md:16`, predating the
  role system; not invented here, only made explicit); grader: the human
  (`docs/specs/2026-08-13-exp-longitudinal.md:17`, "the human spot-audits
  its counts"); skills loaded: policy-reader-run, policy-epistemic.
```

### 4.11 Three-tier map — Tier 1 built here; Tiers 2/3 sketched, out of scope for this spec's build

**Tier 1 (default, zero LLM cost — this spec's entire build):** the
presence hook (§4.3) plus its supporting infrastructure (§4.2, §4.4–§4.8).
Extended pattern set beyond recall/nudge is named as a natural Tier-1
growth path, not built now: "slow session, no frame yet → suggest attend"
(traces to `US-004`, `docs/HIGH-LEVEL-STORIES.md:38-40`) and "N edits, no
test run → surface policy-test-driven" — both are additional entries in
the same matching/telemetry machinery §4.3 already builds, deferred as
follow-on work because this spec's scope is the four duties the cascade
plan named (`docs/plans/2026-08-18-jit-recall-cascade.md:260-312`), not an
open-ended pattern library. **Dispatcher ruling (fix-round, cited per
review):** this deferral stands as-is — the ratified `docs/ROADMAP.md:96-105`
line names four duties and controls scope; the two extra patterns stay
"Tier-1 growth path, not built now," not promoted into this spec's build.

**Tier 2 (opt-in, human-wired — NOT built by this spec):** an
`/anoti:presence` command examining session state + telemetry + recent
trail for skill/workflow suggestions, run on cadence via `/loop` — exact
existing precedent already in this repo: `commands/audit.md:56-59`, "the
human wires the cadence — `/loop 7d /anoti:audit`... The audit never
schedules itself; recurring token spend is the human's call, once." Tier 2
would be the identical pattern, new command, new cadence — sketched here
as a scope boundary only.

**Tier 3 (evidence-gated, later — NOT built by this spec):** Tier 1, on a
drift pattern it can match but not judge, emits one advisory
telemetry/context line naming the pattern; the **main session** (never
the hook) decides whether to dispatch the existing consolidator
(`agents/consolidator.md`) or skeptic (`agents/skeptic.md`) agent against
the trail. This boundary is structural, not a policy choice this spec
could relax even if it wanted to: no subagent frontmatter in this repo
carries a timer or self-wake field (`agents/explorer.md:1-6`,
`agents/skeptic.md:1-6`, `agents/consolidator.md:1-8`,
`agents/practitioner.md:1-8` — confirmed by direct read, none has such a
field), and every hook this plugin ships only ever emits
`additionalContext`/`permissionDecision` JSON or exits silently
(`docs/specs/2026-08-12-anoti-plugin-design.md:512-519`'s Output column;
no row invokes an agent dispatch) — recurring/scheduled execution and
agent dispatch are both main-session capabilities, never a hook's or a
subagent's own.

**Gate:** §4.10's pre-registered Tier-1 gate is the sole authority for
whether Tiers 2/3 are ever built.

## 5. Failure behavior

| Condition                                                                                                                              | Behavior                                                                                                                                                                                   | Never breaks                                                                                                                                                                      |
| -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hook script error (malformed JSON stdin, missing `yq`/`jq`, unexpected exception)                                                      | Fail-open: exit 0, no `additionalContext`, no telemetry — identical to every other hook's contract (`docs/specs/2026-08-12-anoti-plugin-design.md:507-510`)                                | The tool call itself: PostToolUse fires **after** the tool already ran (§3, constraint 1) — the hook's own failure can never affect it                                            |
| Neither store present                                                                                                                  | Silent (matches SessionStart's "no anoti workspace" silence path, `scripts/retrieve:149-156`) — no false digest manufactured for an ungoverned directory                                   | —                                                                                                                                                                                 |
| Store present but fails `validate-workspace` or is untrusted                                                                           | Reported once per session (§4.3.6's "warn once" deviation from `scripts/retrieve`'s per-firing report, justified by firing frequency), then suppressed for the rest of the session         | The store itself: never auto-repaired or auto-trusted by this hook — trust remains a human act (`scripts/trust`)                                                                  |
| Huge `tool_input`/`tool_response`/`error` payload                                                                                      | Capped at 8000 chars before matching (§4.3.2) — bounds runtime regardless of payload size                                                                                                  | Matching correctness on the retained prefix — a match inside the first 8000 chars is still found; a match only in truncated tail content is missed, a stated, accepted limitation |
| More than `MAX_RECORDS` (3) items match                                                                                                | Ranked, truncated to top 3; `(+N more matched)` suffix appended only if budget allows (§4.3.3)                                                                                             | —                                                                                                                                                                                 |
| `BUDGET_TOTAL` (1200 chars) exceeded across concurrently-firing duties                                                                 | `try_emit`-style yielding in priority order recall > evidence-nudge > frame-reanchor (§4.3.7) — lower-priority duties silently drop for that firing, not truncated mid-sentence            | —                                                                                                                                                                                 |
| Presence-state file lock contention (subagent concurrency, unconfirmed whether it occurs, §4.3.6)                                      | `store-lock`'s existing 60s wait-then-error contract (`scripts/store-lock:38-42`) — moot in practice since the hook's own 5s timeout kills the process first                               | The underlying tool call — again unaffected regardless                                                                                                                            |
| PostToolUseFailure fires for a tool outside the matcher scope (unverified whether the harness's matcher applies to this event, §4.3.1) | Internal `tool_name` guard exits 0 regardless (§4.3.1) — defense in depth                                                                                                                  | —                                                                                                                                                                                 |
| Compaction detection's primary signal (`source == "compact"`) turns out unreliable in a live installation                              | `.session.compacted_at` fallback signal already recorded (§4.7); `retrieve` can be extended to use it as an alternate trigger — named as the documented next step, not built speculatively | Frame re-anchoring degrades to periodic-only (the presence hook's own mechanism, unaffected) rather than disappearing entirely                                                    |

## 6. Testing

Every test is fixture-driven, hermetic (`mktemp -d`, `HOME` overridden to
avoid touching the real global store — the exact pattern `tests/test_retrieve.sh:2-3`
already establishes), and auto-discovered by `tests/run.sh`'s `for t in
"$ROOT"/tests/test_*.sh` loop (`tests/run.sh:18`). New fixture:
`tests/fixtures/store_triggers.yaml` — a valid store carrying ≥2 records
with `triggers:` arrays covering distinct keyword sets, so ranking/dedupe/
cap behavior is exercisable.

**New file: `tests/test_presence.sh`** — observable pass conditions per
requirement:

1. **Silence on no match (US-002):** `printf '{"session_id":"s1",
"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":
{"command":"ls"},"tool_response":{"output":"a b c"}}' |
scripts/presence` → `assert_eq "$out" "" "no match, no output"` — and
   confirm no line was appended to `telemetry.log`.
2. **PostToolUse recall fires:** a `tool_input.command` containing a
   fixture trigger → `additionalContext` contains the record's id and
   correct `[global] `/`` label; `telemetry.log` gains one
   `presence\trecall\t<id>[label]` line.
3. **PostToolUseFailure recall fires (the direct regression test for the
   corrected foundation):** same fixture trigger present only in
   `.error` (no `.tool_response` field at all, matching the corrected
   PostToolUseFailure schema) → `additionalContext` still fires. This is
   the test that would have caught the original single-event design the
   skeptic spawn refuted.
4. **Dedupe:** two firings within `N=10` calls both matching the same
   trigger → the second firing's `additionalContext` omits that record
   id; a firing after `N` calls have elapsed re-includes it.
5. **Cap:** a fixture with >3 matching records → exactly 3 appear,
   ranked by hit count then source-priority then id (§4.3.3's exact
   tie-break, asserted against a constructed tie case).
6. **Warn-once:** an untrusted store, two consecutive firings → only the
   first emits the warning line/telemetry; the second is silent on that
   point.
7. **Periodic frame re-anchor:** a slow-classified session
   (`.classifications` carries a `slow` verdict) with an active frame,
   `tool_calls` stepped to exactly `N-1` then `N` → silent at `N-1`,
   fires at `N`, contains truncated goal/scope.
8. **Evidence-kind nudge:** a `curl ... | grep -c ...` command →
   `additionalContext` contains the G004/G008 one-liner; a command not
   matching the pattern set → silent.
9. **Fail-open:** garbage (non-JSON) stdin, or `tool_name` outside the
   matcher scope → `exit 0`, empty output, verified via `$?`.
10. **Matcher-scope guard:** `tool_name: "Read"` (outside scope even if a
    hypothetical matcher misconfiguration let it through) → silent,
    proving the internal guard (§4.3.1) independent of the registered
    matcher string.
11. **Priority-order budget yielding (fix-round N7a — the original draft
    named the `recall > evidence-nudge > frame-reanchor-periodic`
    priority order in §4.3.7 but had no test for it):** construct a
    firing where all three duties would fire simultaneously (a slow
    session at exactly `N` tool calls, an active frame, a matching
    trigger, and a matching evidence-nudge pattern, all in one call) with
    `BUDGET_TOTAL` (§4.3.7) deliberately undersized via a test-only
    override — assert `additionalContext` contains the recall content,
    then the evidence-nudge, and omits or truncates the frame-reanchor
    content first when the budget forces a drop; a second case with
    budget large enough for all three asserts all three duties' content
    present together.
12. **Perf pass condition (fix-round M2 — the original draft's `match_triggers`
    design was benchmarked by the reviewer at ~3.4s for two ~300-record
    stores, exceeding the 5s timeout with no room left for the hook's
    other work; the redesign, **after fix-round 2's `export`-scoping
    correction (NEW-C1)**, was re-verified against the exact literal
    code block (§4.3.3) at **0.032s** for the same scale — `{command:
"sed-extracted match_triggers, sourced, called against two 300-record
fixtures", output: "0.04s user 0.01s system 158% cpu 0.032 total"}`,
    not the pre-fix number, which measured a differently-shaped test, per
    §4.3.3's own honesty note):** a generated 300-record fixture per
    store (not checked into the repo — generated by the test itself, to
    avoid bloating the tree with a large static fixture), both project
    and global paths populated, one firing → wall-clock time **< 1s**
    total for the recall duty (a wide margin above the 0.032s measured
    here, chosen to tolerate slower CI/developer machines while still
    being a meaningful regression guard against a reintroduced
    per-record `yq` spawn).

**Extended: `tests/test_retrieve.sh`** — compaction-recovery cases (owned
by `retrieve`, §4.7), appended to the existing suite: a `SessionStart`
input with `source: "compact"` plus a session file carrying a `status:
active` frame → digest contains the re-anchor line; the same input
without an active frame → digest omits it; `.session.compacted_at` is
correctly stamped by a `persist-session` PreCompact firing (extend
whatever hook-cycle test already exercises `persist-session`, or add a
direct one).

**Extended: `tests/test_validate.sh`** — triggers shape cases, mirroring
its existing style (`tests/test_validate.sh:1-15`): `triggers: []` passes;
`triggers: ["a", "b"]` passes; `triggers: [""]` fails; `triggers: "x"`
fails; `triggers: [1]` fails — each asserted via `assert_ok`/`assert_eq`
against a constructed fixture.

**Extended: `tests/test_helpers.sh`** (following its existing per-helper
section style, e.g. `tests/test_helpers.sh:43-51`'s `append-evidence`
block):

- `append-trigger`: exits 0 on a known id, refuses an unknown id
  (mirroring `tests/test_helpers.sh:51`'s `append-evidence ... NOPE ...`
  pattern), result validates, triggers accumulate across repeated calls
  (append-only, never overwrite), file mode preserved, `regen-index`+
  `trust` both ran on a **project-path** store (re-trusted immediately
  after, verified by a subsequent untrusted-store check returning false).
- `append-trigger` **global-path fixture (fix-round N7b — the missing
  case that would have caught C1):** a store constructed under a
  `HOME`-overridden `$HOME/.claude/anoti/GROUNDING.yaml` path (mirroring
  `tests/test_retrieve.sh:2`'s hermetic-`HOME` pattern, fix-round-2
  citation fix — the line is 2, not 3), trusted via
  `scripts/trust --global` first — `append-trigger` against it must (a)
  exit 0, (b) leave the triggers written and the store `validate-workspace`-clean,
  (c) print the "NOT re-trusted — machine-wide scope requires explicit
  consent" warning to stderr (§4.5 point 6), and (d) leave the store
  **untrusted** afterward (a subsequent `retrieve`/`presence` firing
  against it reports "not yet trusted") until a follow-up `scripts/trust
--global` call re-trusts it — this is the direct regression test for
  C1, distinct from the project-path case above which must show the
  opposite (self-contained, immediately re-trusted, no warning).
- `scripts/recall`: keyword match across both stores + lessons, `[global]`
  labeling correct, untrusted-store framing preserved (same assertions
  `tests/test_retrieve.sh:5-8` already makes for the digest, applied to
  the CLI's output).
- `session-append` frame telemetry: appending a `frames` item produces a
  `telemetry.log` line matching `frame\t<id>`; appending a
  `hypotheses`/`in_flight`/`candidates` item does not (scoped to `frames`
  only).
- `mark-retrospect`: `empty` and `filed` each produce their own
  telemetry line shape.
- `cleanup-session` summary line: constructed session state with known
  `.classifications`/`.frames` counts and a prior `retrospect` telemetry
  line → the emitted `summary` line's counts match exactly; absent
  `retrospect` telemetry → `retrospect_ran=false`.

**`hooks/hooks.json` registration** verified by whatever this repo's
existing `tests/test_hooks_wiring.sh` already checks structurally (new
`PostToolUse`/`PostToolUseFailure` keys present, correct matcher, correct
command path, correct timeout) — extended, not replaced.

## 7. Out of scope

- **Tiers 2 and 3** (§4.11) — sketched as a scope boundary, not built;
  gated on Tier-1 telemetry per the pre-registered gate (§4.10).
- **MCP-tool-aware evidence-kind nudging** (screenshots via
  `chrome-devtools-mcp`, `Read` of an image file) — structurally outside
  this hook's matcher (§4.3.5); a Tier 3 candidate if telemetry shows the
  gap matters.
- **Regex/fuzzy trigger matching** — fixed-string substring only (§4.3.3);
  no stemming, no Levenshtein distance, no tokenized word-set matching.
- **Refactoring `scripts/retrieve` to source `store-resolve`** — a
  deliberate labeled trade-off against regression risk (§4.2), not an
  oversight.
- **`docs/SKILL-MAP.md` currency** — this spec adds new entry points
  (`scripts/recall`, the presence hook) that the map does not yet name;
  updating it is cheap once file paths are final but was not named in
  this spec's brief, so it is explicitly deferred to the follow-on
  implementation pass rather than silently expanded into this spec's
  scope.
- **Cross-session or cross-project trigger analytics** (e.g. "which
  triggers fire most often across every governed project") — no
  aggregation mechanism beyond the per-project/per-machine telemetry.log
  files this spec already defines.
- **Auto-authoring `triggers:` on existing records** (e.g. NLP-deriving
  keywords from `G004`'s own statement text) — triggers are
  human-authored at encoding time (§4.5's consolidate-skill question)
  only; no automatic backfill onto `G001`–`G008` or any existing project
  record is performed by this spec.
- **Changing `US-001`'s status or filing a new story** — already settled
  by the human's 2026-08-19 ruling (Option A, audit note,
  `docs/HIGH-LEVEL-STORIES.md:65-66`); this spec implements against that
  ruling, does not revisit it.

## 8. Success criteria

1. `tests/test_presence.sh` and every extended test file (§6) pass, run
   via `bash tests/run.sh`.
2. A fixture-driven PostToolUseFailure firing (no `tool_response` field
   present) still produces a matching `additionalContext` — the direct,
   checkable resolution of the corrected foundation's central finding.
3. A trivial, unmatched tool call produces zero output and zero
   telemetry lines — US-002 silence, mechanically checkable.
4. `scripts/anoti recall <keyword>` and the presence hook agree on
   **trigger-based** matches for a shared fixture keyword (both call the
   same `match_triggers` function, different entry points) — checkable
   by running both against the same fixture store and diffing matched-id
   sets, restricted to hits `match_triggers` itself produced. They are
   **not** expected to agree in full: the CLI's additional
   `match_topic_statement` pass (§4.4) surfaces topic/statement matches
   the hook deliberately never does (§4.3.3's precision-first "why
   triggers only" argument) — a fixture keyword present only in a
   record's `statement`, not its `triggers:`, should appear in the CLI's
   output and correctly NOT appear in the hook's, and the test suite
   asserts that asymmetry directly rather than treating it as a bug.
5. `scripts/append-trigger` round-trips **on the project-path store**:
   appended triggers are visible to both `scripts/recall` and
   `scripts/presence` immediately after the call returns (self-contained
   trust, §4.5 point 6). **On the global-path store (fix-round C1
   correction — item 5 originally claimed this unconditionally, which
   the reviewer showed false):** triggers are appended and indexed, but
   the store is left untrusted with a loud stderr warning until a human
   runs `scripts/trust --global`; success here means the warning fires
   and the store reads as untrusted immediately after, not that it
   round-trips silently.
6. `docs/specs/2026-08-13-exp-longitudinal.md`'s next scheduled audit run
   (on/after 2026-08-20 per its own cadence, `docs/specs/2026-08-13-exp-longitudinal.md:53`)
   can score the three new metrics from durable `telemetry.log` artifacts
   alone, with no dependency on session memory — checkable by an auditor
   with git history and `telemetry.log` access only.
7. The evidence-kind wording (§4.9) appears verbatim in
   `skills/policy-epistemic/SKILL.md`, `commands/review-work.md`, and
   `roles/reviewer.md`, each citing `G004`/`G008` by id.

## 9. Execution routing

**Plan owner: architect.** `roles/architect.md:19-20` names this role's
cascade responsibility explicitly: "this role handles technical
decomposition of stories into implementation tasks when the cascade plan
assigns it"; `docs/SKILL-MAP.md:38` names architect as the spec skill's
entry point. Continuity reasoning (labeled judgment): this spec's
components are densely interdependent (schema/validator changes must land
before helpers that assume them; `hooks/hooks.json` registration must
land after `scripts/presence` exists and is tested) — the same context
that produced this spec is the cheapest place to sequence its build,
matching the cascade plan's own follow-on framing
(`docs/plans/2026-08-18-jit-recall-cascade.md:395-404`, "expected to be
architect or project-manager"). Project-manager may still own the
downstream TODOS/status-tracking layer once concrete tasks exist
(`roles/project-manager.md:14-19`), but the technical decomposition itself
is architect's.

**Builder hats, one per component class:**

- **backend** (`roles/backend.md`) — every script in §4.1's table marked
  "new" or "extended" except the plugin-governance/doc files:
  `scripts/presence`, `scripts/store-resolve`, `scripts/recall`,
  `scripts/append-trigger`, `scripts/mark-retrospect`,
  `scripts/validate-workspace`, `scripts/session-append`,
  `scripts/persist-session`, `scripts/retrieve`, `scripts/cleanup-session`,
  `scripts/anoti`, `hooks/hooks.json`, and every test file in §6. Reason:
  `roles/backend.md:18-24` — "the contract... routes, signatures,
  schemas... test-driven... idempotency... error paths" is exactly this
  work's shape (stdin/stdout JSON contracts over the plugin's own data
  model), the same reasoning the cascade plan already used to prefer
  backend over devops for this repo's hook scripts
  (`docs/plans/2026-08-18-jit-recall-cascade.md:96-102`). Loads:
  policy-test-driven (RED/GREEN transcripts per §6's observable pass
  conditions), policy-adversarial-handoff (reviewer spawn before done),
  the `anoti:git` skill (branch/commit discipline before any
  implementation work that will commit), plus the universal
  epistemic/trace-to-frame/escalate-destructive stack already in
  `roles/backend.md:6-13`.
- **technical-writer** (`roles/technical-writer.md`) — the exact-wording
  text edits: `skills/policy-epistemic/SKILL.md`,
  `commands/review-work.md`, `roles/reviewer.md`,
  `skills/consolidate/SKILL.md` (§4.6), `commands/recall.md` (§4.4's step
  0), and `docs/specs/2026-08-13-exp-longitudinal.md` (§4.10's dated
  amendment). **Scoping note (labeled judgment):** none of these targets
  is a human-owned direction organ in the `policy-draft-for-ratification`
  sense (`skills/policy-draft-for-ratification/SKILL.md:8-10` scopes that
  policy to `docs/ROADMAP.md`/`docs/HIGH-LEVEL-STORIES.md`-class organs
  specifically) — they are ordinary plugin/spec source, edited and
  reviewed like code (`policy-adversarial-handoff` applies instead, per
  `roles/technical-writer.md:26-28`'s own boundary: draft-for-ratification
  binds only "drafts that touch human-owned organs"). Loads:
  policy-reader-run (execute every edited doc's instructions as written,
  `roles/technical-writer.md:20-23`), policy-adversarial-handoff, the
  universal stack.
- **reviewer** (`roles/reviewer.md`) — adversarial pass over both
  builders' diffs before merge, per policy-adversarial-handoff
  (mandatory for builder-class work,
  `skills/policy-adversarial-handoff/SKILL.md:8-11`). Verifies: every
  §6 test actually exercises what it claims (re-running RED before GREEN
  where the backend spawn's transcript is ambiguous); every §4.9 wording
  block landed verbatim; the PostToolUseFailure regression test (§6 item 3) is not accidentally trivially-passing (e.g. matching on an absent
  field by coincidence). Loads: epistemic, trace-to-frame,
  escalate-destructive (`roles/reviewer.md:6`) — no test-driven/
  adversarial-handoff on the reviewer itself, per its own role stack.

**Fix rounds:** per D011 (`skills/deliberate/SKILL.md:85-93`), any
reviewer findings resume the **original** backend or technical-writer
spawn with findings relayed verbatim — never a fresh spawn, capped at 3
cycles by analogy to `commands/review-work.md:51-54`'s cap; a blocker
surviving three rounds returns to the human as a design decision, not a
fourth attempt.

## Questions/doubts

- **I did not independently re-run skeptic spawn #3's live capture.** Its
  verdict (PostToolUse's field names verified live; PostToolUseFailure as
  a required, separate registration; the `triggers:`/`entries_immutable`
  correction) was relayed to me in this spawn's dispatch brief, not
  re-verified by me against a durable artifact I can cite by
  `{file, lines}`. I have designed §4.3.1/4.3.2 to match it exactly and
  flagged the one sub-claim it did **not** cover (SessionStart's `source`
  field, §4.7) as separately unverified. If the reviewer spawn (§9) can
  locate a durable transcript of spawn #3's test, it should cite it
  directly in place of my relay.
- **Whether the `matcher` field is honored on `PostToolUseFailure`
  identically to `PostToolUse`** is genuinely unknown to me (§4.3.1) —
  I designed around it with an internal `tool_name` guard rather than
  assuming either way, but this is a gap the implementation's first live
  test (mirroring the cascade plan's own Branch B verification step,
  `docs/plans/2026-08-18-jit-recall-cascade.md:437-441`) should close.
- **Whether subagent tool calls share the parent session's `session_id`
  on PostToolUse/PostToolUseFailure** is unknown to me and affects only
  the granularity of the tool-call counter and dedupe window (§4.3.6), not
  correctness — flagged rather than assumed, since assuming wrong in
  either direction would silently mis-tune `N` rather than break anything.
- **`N = 10` (periodic re-anchor interval and dedupe window) is a
  labeled judgment with no empirical basis** — I chose a single shared
  constant for simplicity over two independently-tuned ones; the Tier-1
  gate (§4.10) is designed to produce the evidence that would justify
  splitting or re-tuning it, but that evidence does not exist yet.
- **The evidence-kind nudge's pattern set (§4.3.5) is narrow by
  construction** (`curl`+`grep` shapes only, cited from `G004`'s one
  concrete evidence instance) — I did not attempt to generalize it to
  every brittle-instrument shape `G008`'s evidence log names (stale-view,
  path-dependent state, transient UI state,
  `~/.claude/anoti/GROUNDING.yaml:49`'s evidence entries), because those
  shapes are UI/browser-interaction failures this hook's Bash-only
  matcher scope cannot observe at all (§4.3.5's own stated constraint) —
  a Tier 3/MCP-aware candidate, not a Tier 1 gap I could have closed
  within this spec's matcher scope.
- **I backfilled `docs/specs/2026-08-13-exp-longitudinal.md`'s missing
  Execution routing section (§4.10's changelog entry)** rather than
  leaving it as a separately-flagged gap, per the cascade plan's own
  suggestion that I "may reasonably choose to backfill... since [I'm]
  already amending the file" (`docs/plans/2026-08-18-jit-recall-cascade.md:489-496`)
  — the routing I named ("a fresh general-purpose agent dispatch, unnamed
  to any `roles/` hat") is honest about what that file already says
  rather than inventing a role-system mapping that doesn't exist; if the
  human intends `/anoti:audit` to route through a `roles/` hat going
  forward, that is a separate, larger decision this spec does not make.
- **This spec's own filename date (2026-08-19) is one day ahead of the
  session's stated current date (2026-08-18) at dispatch time** — I did
  not treat this as an error to resolve; it matches the already-ratified
  `docs/ROADMAP.md:97` line's own date and the filename this spawn was
  explicitly instructed to produce, and I have no basis to second-guess
  either.
- **New doubts from fix round 1 (superseded in places by fix round 2 below — kept for the trail, not deleted):**
  - **The `match_lessons` invocation-shape rule I added to close M1**
    ("piggyback on already-matched record triggers; never fire on the
    haystack cold," §4.3.3) is my own judgment call, made under this fix
    round's pressure to close the gap "without a clarifying question" —
    it changes lessons' actual recall behavior (a lesson can now only
    ever surface alongside a record trigger, never independently) in a
    way the original three-source design (§4 principle 6, "LESSONS-LEARNT
    exactly as `scripts/retrieve` already does it") did not obviously
    imply. If the human's intent was for lessons to have independent
    recall power, this narrows it; flagged for the reviewer/human to
    weigh rather than treated as self-evidently correct.
  - **The `awk`-based `match_triggers` redesign's `tolower()`/`index()`/
    `ENVIRON` behavior was verified in this fix round only against
    macOS's own `/usr/bin/awk`** (`{command: "awk -v x=... 'BEGIN{print
x}' | od -c", output: confirmed -v processes backslash escapes,
ENVIRON does not}`), not against whatever `awk` this plugin's CI
    actually runs (this codebase already handles GNU-vs-BSD divergence
    elsewhere, e.g. `stat -c` vs `stat -f` throughout the helper scripts —
    the same class of platform risk could apply to `awk` variants,
    though `tolower`/`index`/`ENVIRON` are POSIX-mandated awk features I
    am not aware of any common implementation (gawk, mawk, nawk) lacking
    — a knowledge-based claim, not one I independently verified on
    Linux in this pass).
- **New doubts from fix round 2 (this round — every literal block in §4
  that could be executed was executed, per the coordinator's explicit
  instruction; results below are what that pass actually found, not
  what it assumed):**
  - **A "suggested code" block that was never run is not evidence, only a
    claim about code — the lesson this whole round is an instance of.**
    Fix round 1's validate-workspace snippet (`if (. | type) == "!!seq"
then ... else ... end`) does not parse under `mikefarah/yq
v4.53.2` — the actual binary this repo's entire helper suite runs
    (confirmed: even `yq -r 'if .x == 5 then "yes" else "no" end'` fails
    identically) — and I filed it labeled "implementation guidance... not
    mandated literal code," which in practice meant it went unverified
    for a full review cycle. I have since executed every `sh` code fence
    in §4 against constructed fixtures (`match_triggers`,
    `match_lessons`, the §4.3.2 input-contract parsing block, this
    corrected shape check, and `append-trigger`'s trust step against the
    real `scripts/trust`/`scripts/regen-index` — six blocks, six pass) —
    but I did not go back and add equivalent literal, executed code for
    every OTHER prose-described mechanism in this spec (e.g. `retrieve`'s
    compaction-recovery frame filtering, §4.7, described only in prose).
    Those remain design-level, unverified-by-execution — labeled as such
    now, not implied to carry the same weight as the six blocks above.
  - **`match_topic_statement` (§4.2, §4.4) still has no literal code and
    was not executed this round.** It was not named in the reviewer's
    cycle-2 findings, and — being the third cycle under the 3-cycle cap —
    I chose not to speculatively add and self-verify new code for a
    function outside the named findings, on the reasoning that doing so
    late in the last cycle adds fresh, unreviewed surface rather than
    closing named ones. It uses the same `grep -qiF` primitive already
    verified safe elsewhere in this spec (no `awk`/`ENVIRON`, so NEW-C1's
    specific bug class cannot apply to it), which lowers but does not
    eliminate the risk. Flagged as named residue for the human, per this
    round's own instruction, rather than left silently implicit.
  - **This codebase's hard dependency on `mikefarah/yq`'s specific
    dialect (as opposed to `jq`, or the `kislyuk/yq` Python wrapper
    around `jq` that installs under the same command name on some
    systems) is pre-existing, not something this fix introduces.**
    `strenv()` — used throughout `scripts/append-record`,
    `scripts/set-ratification`, and others — is a `mikefarah/yq`-specific
    function with no `jq` equivalent, so the codebase already commits to
    this exact binary; my corrected shape check (`select()` + `length`,
    no `if/then/else`) is consistent with that existing, if undocumented,
    commitment rather than adding a new one. Whether that dependency
    should be documented explicitly somewhere (a `README`/`CLAUDE.md`
    prerequisites note) is outside this spec's scope to decide.
