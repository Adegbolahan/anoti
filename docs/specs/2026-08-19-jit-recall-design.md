# Just-in-Time Recall — the Presence Hook

**Spec:** this document. **Authority:** `docs/ROADMAP.md:96-105` (Phase 4
deliverable, ratified 2026-08-19 — "design spec is the next step, blocked
on this ratification", `docs/ROADMAP.md:97`); `docs/HIGH-LEVEL-STORIES.md:54-66`
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
story (`docs/HIGH-LEVEL-STORIES.md:54-66`).

## 3. Design principles / constraints

1. **Carrot, not stick.** PostToolUse cannot block — "exit code 2 is
   honored but only shows stderr to Claude; the tool already ran" (cascade
   plan §3a, docs-fetch citation, `docs/plans/2026-08-18-jit-recall-cascade.md:125-128`).
   This is a structural property of the mechanism, not merely a design
   choice: the presence hook can only inform, never gate.
2. **Fail open, ≤5s, no network, POSIX shell + `yq`/`jq`** — identical to
   every hook this plugin ships (`docs/specs/2026-08-12-anoti-plugin-design.md:507-510`).
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
#   Prints ranked "hits\tid\tlabel\tstatement" lines (§4.3.3 algorithm).
match_triggers() { ... }

# match_lessons <lessons-file> <keyword>
#   Prints matching "^- " lines (grep -i, cut -c1-220), mirroring the
#   grep pattern scripts/retrieve:87-92 already uses for lesson counting.
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
(`docs/plans/2026-08-18-jit-recall-cascade.md:118-124`).

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
`error` carries the failure text instead. `hook_event_name` is read first
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

**Per-record matching (`match_triggers`, in `scripts/store-resolve`):**

```sh
match_triggers() {  # $1=store $2=haystack $3=label ("" or "[global] ")
  f="$1"; hay="$2"; label="$3"
  n="$(yq -r '.records | length' "$f" 2>/dev/null || echo 0)"
  i=0
  while [ "$i" -lt "$n" ]; do
    tcount=0
    while IFS= read -r trig; do
      [ -n "$trig" ] || continue
      printf '%s' "$hay" | grep -qiF -- "$trig" && tcount=$((tcount+1))
    done <<< "$(yq -r ".records[$i].triggers // [] | .[]" "$f" 2>/dev/null)"
    if [ "$tcount" -gt 0 ]; then
      rid="$(yq -r ".records[$i].id" "$f" 2>/dev/null)"
      stmt="$(yq -r ".records[$i].statement" "$f" 2>/dev/null | cut -c1-220)"
      printf '%s\t%s\t%s\t%s\n' "$tcount" "$rid" "$label" "$stmt"
    fi
    i=$((i+1))
  done
}
```

Precise definitions, each a direct answer to a dispatcher requirement:

- **Case-insensitive fixed-string per trigger:** `grep -qiF -- "$trig"` —
  `-F` (fixed string, not regex) **and** `-i` (case-fold) in one call.
  `-F` is load-bearing, not incidental: a trigger is freeform authored
  text and may contain glob/regex metacharacters (`*`, `?`, `[`); using a
  shell `case` pattern or `grep -E` here would let those metacharacters
  be interpreted rather than matched literally — the exact class of bug
  `G002` already names for `yq`'s `==` ("Freeform identifiers must never
  meet a yq ==" — the same "pattern-matching operator meets freeform
  text" shape, `~/.claude/anoti/GROUNDING.yaml:43`) and the reasoning
  `G004`'s own predicate literally asks for ("what result would make it
  FAIL", `~/.claude/anoti/GROUNDING.yaml:45`). `grep -qiE` is already
  this codebase's precedent for case-insensitive pattern checks
  (`scripts/inhibit:78-79`); `-F` is the one-character difference that
  keeps triggers safe as _literal_ text.
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
- **Cross-source ranking + deterministic tie-break:** the caller collects
  `match_triggers` output from project store, global store (each
  correctly labeled), and `match_lessons` output from LESSONS-LEARNT
  (each lesson line counts as exactly one hit, since lessons carry no
  per-line trigger array to count against), then sorts:
  `sort -t"$(printf '\t')" -k1,1nr` (hit count, descending), tie-broken by
  **source priority project > global > lessons** (labeled judgment: a
  project-scoped trigger is authored against this codebase's own
  vocabulary and is inherently less likely to be a coincidental match
  than a broadly-scoped global one — the same caution `G004`'s
  namespace-collision case names), then by **id ascending** for full
  determinism (mirrors `scripts/record-index`'s exact-match discipline).
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
  `G004[global],D007[]`.
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
`.records[].statement`, same `grep -qiF` primitive) against both stores,
plus `match_lessons` against LESSONS-LEARNT — the broader net justified in
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
gains one line after `templates/GROUNDING.yaml:24` `statement:`):**

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
6. **Deliberate strengthening beyond `append-evidence`:**
   `scripts/append-trigger` also runs `regen-index` and `trust` on the
   result — cloning `scripts/append-record:18`'s stronger,
   self-contained contract instead. Reasoning (labeled judgment): every
   store mutation changes the file's hash, so `is_trusted` fails until
   the store is re-trusted (`scripts/retrieve:17`); `append-evidence`
   defers re-trusting to the caller's batch-end step
   (`skills/consolidate/SKILL.md:115-116`, step 9), which is safe inside
   a multi-step consolidation flow but not for `append-trigger`, which
   the encoding-time question (below) invokes as a **standalone** action
   that may be the last write in its episode — leaving the store
   untrusted after it would silently break the very next `retrieve`/
   `presence` read. `regen-index` is a content no-op here (`triggers:`
   is not part of the generated index shape, `scripts/regen-index:7`)
   but is run anyway for hygiene/idempotency consistency with
   `append-record`'s contract.

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

```sh
bad="$(yq -r ".records[$i].triggers // [] | if (. | type) == \"!!seq\" then (.[] | select((. | type) != \"!!str\" or . == \"\")) else \"NOTALIST\" end" "$f" 2>/dev/null | head -3 | tr '\n' ' ')"
[ -z "$bad" ] || fail "records[$i]: triggers must be a list of non-empty strings"
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
changelog rule binds _specs_; `docs/direction/SKILL.md`'s ratification
gate binds `docs/ROADMAP.md`/`docs/HIGH-LEVEL-STORIES.md` only,
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
= length of `.frames[]`, `retrospect_ran` = true iff a `presence` (wait —
`retrospect`, not `presence`) telemetry line for this `sid` exists in
`telemetry.log` from step above (`grep`-checked, not re-derived from
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
open-ended pattern library.

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
  `trust` both ran (store re-trusted immediately after, verified by a
  subsequent untrusted-store check returning false).
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
4. `scripts/anoti recall <keyword>` and the presence hook agree on which
   records a shared fixture keyword matches (same underlying
   `match_triggers`/`match_topic_statement` functions, different entry
   points) — checkable by running both against the same fixture store and
   diffing matched-id sets.
5. `scripts/append-trigger` round-trips: appended triggers are visible to
   both `scripts/recall` and `scripts/presence` immediately after the
   call returns (store re-trusted in the same call, §4.5 point 6).
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
