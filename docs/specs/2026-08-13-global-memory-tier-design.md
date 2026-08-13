# Global Memory Tier — Design Spec

**Date:** 2026-08-13
**Status:** REVIEWED — round 1 (1 Critical, 7 Important, 3 Minor)
fixed; scoped re-review verdict READY with 2 residual minors applied;
pending human ratification
**Parent:** docs/specs/2026-08-12-anoti-plugin-design.md (§Memory
hierarchy, §Trust boundary); roadmap Phase 4; stories US-006, US-003.

## What this is

The cross-project memory store — `~/.claude/anoti/GROUNDING.yaml` — that
carries what transcends any one repository: who the user is, how they
like to work, and lessons about how agents work that every project should
inherit. It is the link that turns "anoti works here" into "anoti learns
anywhere," and it is deliberately the last organ built: it only has
content worth holding once a second project exists.

## Why

- The parent spec designed this tier on day one and every session since
  has run without it — retrieval already probes the path and stays
  silent when the store is absent (scripts/retrieve; verified by
  execution). Cited: parent spec §Memory hierarchy.
- Labeled judgment (synthesis over D014/D018, not their text): the
  evidence base is self-referential — anoti observing itself. A second
  governed project needs somewhere to send cross-project lessons on
  arrival, or they die in the project that learned them. D018 records
  the observational protocol's no-counterfactual limitation.
- Labeled judgment: preferences ("terse commits") and agent-craft lessons
  ("relay findings verbatim") are the two classes users repeat into every
  new project by hand today; automating their transfer is the tier's
  concrete payoff.

## Design principles / constraints

1. **Opt-in, once, explicitly.** The store never exists until the human
   approves its creation in a consolidation dialog. No silent global
   state. (This resolves the parent's ambiguous "opt-in at first use,
   per user" as once-per-machine — a resolution, not a restatement.)
2. **Same schema, same helpers.** Schema v3 with `meta.scope: global`;
   every mechanical helper takes a store path and MUST work on the
   global store — one (`trust`) requires the adjacency change specified
   below; the rest work unchanged today. No parallel machinery.
3. **Trust is adjacent to its store — exact rule:** if the store path,
   **realpath-normalized**, resolves under `$HOME/.claude/anoti/`
   (never a literal string test — relative paths and symlinks must not
   dodge or false-trigger the branch), the trust file is
   `$HOME/.claude/anoti/trust`; otherwise it is `<state-dir>/trust`. A
   hardcoded location check, not `dirname` (which would silently
   relocate project trust). `trust` adopts temp+rename atomic writes
   (its current in-place `sort -o` races when multiple sessions across
   projects touch the shared global file). **Write-path blast radius,
   argued not just labeled:** the read-side mitigations (envelope,
   never-instructions, context-not-content) do not constrain writers;
   a misbehaving session calling the helpers directly could poison the
   one trust file every project reads. Hardening: `trust` refuses any
   store under `$HOME/.claude/anoti/` unless invoked with an explicit
   `--global` flag — deliberate friction on the machine-wide path, so
   casual or injected invocations fail closed; the residual risk (a
   session that deliberately passes --global) is accepted and stated:
   helpers are convention-gated for project stores too, and the OS user
   account is the outer boundary.
4. **Project beats global** inside a project (parent spec's precedence
   rule); the conflict is recorded once as a scoped-exception event on
   the global record.
5. **Context, never content.** Global records inform sessions; they are
   never quoted into work products or committed artifacts. The digest
   labels them `[global]`.
6. **Never-store enforced hardest here:** credentials/secrets always
   rejected; health, legal, financial details rejected by default;
   project-identifying facts stay in project stores.
7. **File mode 0600** at creation; the directory `~/.claude/anoti/` is
   created 0700.

## The design

**Creation (opt-in flow, in the consolidate skill):** when scope routing
proposes the first global candidate and no global store exists, the flow
asks exactly one question: create `~/.claude/anoti/GROUNDING.yaml`? On
yes: `mkdir -m 700`, then `(umask 077; cp template store)` so the file
never exists at default permissions even briefly (file modes are this
design's entire confidentiality mechanism — the ordering is
load-bearing), set `meta.scope: global`, validate-workspace,
regen-index, `trust --global` (writes the adjacent
`~/.claude/anoti/trust`). On no: the candidate is appended to the
project store as a normal record first, then `append-event <store> <id>
scope-deferred session "global routing declined by human"` —
`by: session` because the event is automatic bookkeeping of a human
answer, not itself a ratification act (the answer is quoted in the
note); record-then-event,
since append-event refuses unknown ids; nothing is lost and the question
is not re-asked until the next global candidate.

**Routing classes (consolidate skill, human-confirmed per candidate):**
`preference` records about the user; `policy`/`claim` records about how
agents work (method lessons with cross-project reach); nothing else
routes global by default. The human confirms every routing — misfiled
memory is worse than no memory (parent spec).

**Retrieval:** scripts/retrieve already digests the global store first
when present; the change is trust-adjacency (check
`~/.claude/anoti/trust` for the global store instead of the project's
trust file) and a `[global]` label on its digest lines. Budget rules
unchanged; `/anoti:recall` already queries both stores.

**Review:** `/anoti:review` covers the global store with the extra user
rights the parent spec grants: correct (via events), delete (the one
immutability exception, user data rights), export (print the record's
YAML on request). Global promotions follow the same independence rule.

**Cross-project flow (the point of it all):** project A consolidates a
lesson → human routes it global → project B's next SessionStart digests
it → B's work cites it → the citation is appended as evidence _from a
different project_ — the first genuinely non-self-referential evidence
class available to the longitudinal protocol (D018). Wiring this into
the weekly audit means amending the frozen protocol
(docs/specs/2026-08-13-exp-longitudinal.md) with a **seventh** source —
cross-project global-record citations — which, per that spec's own
amendment rule, happens as a dated changelog entry at implementation
time, never silently here.

**Touched components (exhaustive):** `skills/consolidate/SKILL.md`
(opt-in flow + routing classes + helper quick reference),
`scripts/retrieve` (adjacent trust check + [global] label),
`scripts/trust` (exact adjacency rule, `--global` flag, atomic write),
`scripts/validate-workspace` (warn when `meta.scope` disagrees with the
store's location class), `commands/review.md` (verify global rights
wording), `docs/specs/2026-08-13-exp-longitudinal.md` (dated amendment
adding the seventh audit source, at implementation time),
`tests/test_helpers.sh` + `tests/test_retrieve.sh` (global fixtures
under fake `$HOME`). Nothing else changes.

## Failure behavior

- Global store missing → digest says nothing about it (today's behavior);
  unparseable → quarantine-and-report exactly like a project store; never
  crash a session.
- Global trust missing/mismatched → the store is reported, not injected
  — same refusal path as project stores.
- A project with no network/home access (sandboxed) degrades to
  project-only memory silently.
- A store whose `meta.scope` disagrees with its location class (a
  global-store copy pasted into a project, or vice versa) is flagged by
  validate-workspace as a warning and reported in the digest — location
  drives behavior; the field exists to catch exactly this drift.
- Deletion of the global store file is recoverable only via the user's
  own backups — the spec accepts this (user data, user custody) and the
  review command's export exists precisely so custody is exercisable.

## Testing

- Helper parity: append-record/append-event/append-evidence against a
  global-store fixture under fake `$HOME` — identical behavior, adjacent
  trust written. Observable: fixture assertions in tests/test_helpers.sh.
- Retrieval: trusted global + project stores → both digested, global
  lines labeled `[global]`, budget respected; untrusted global → refusal
  line. Observable: tests/test_retrieve.sh.
- Opt-in: consolidation with a global candidate and no store → exactly
  one creation question; "no" defers with event; "yes" creates 0600/0700
  and trusts. Observable: live dogfood transcript at first real use.
- Precedence: conflicting project record wins in-project; scoped
  exception appended once. Observable: fixture test + first live
  occurrence.
- Cross-project: the second-project rollout (below) produces ≥1 global
  record cited by the other project within two longitudinal audits.

## Out of scope

- Team-shared or synced global memory (multi-user) — per parent spec.
- Automatic routing without human confirmation — never.
- Encryption at rest beyond file modes — the OS user account is the
  boundary, stated plainly.
- Global TODOS/LESSONS files — only the GROUNDING store crosses
  projects; prospective memory stays project-local.

## Success criteria

1. All fixture tests green; suite stays green.
2. The opt-in flow observed live: store created with correct modes,
   trusted adjacently, first global record ratified by the human.
3. A second governed project cites a global record that originated
   elsewhere — evidence entry appended with cross-project provenance
   (the de-self-referencing milestone, feeding D018's audit).
4. Zero never-store violations found by `/anoti:review` inspections of
   the global store across the first four longitudinal audits (the
   review ritual's viewing rights are the inspection mechanism — no new
   scanner is assumed; if audits demand automation, that is its own
   future spec).
