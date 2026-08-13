# anoti Cognition Content Implementation Plan (Plan 2 of 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The plugin's cognition layer — four core skills, ten policy skills, four agents, ten core-v1 roles (led by the conductor), three commands — plus migration of this repo's own GROUNDING.yaml to schema v3, so the plugin governs the project that builds it.

**Architecture:** All content files are markdown with YAML frontmatter, discovered by Claude Code's plugin conventions (`skills/*/SKILL.md`, `agents/*.md`, `commands/*.md`). Roles live in `roles/*.md` and are injected into practitioner spawns by the deliberate skill. Structural tests (frontmatter present, references resolve, required elements greppable) gate every task; prose is authored at execution with each file's requirement list below as the binding contract — the tests define done.

**Tech Stack:** markdown + YAML frontmatter; existing bash test harness (`tests/run.sh`, `assert_eq`/`assert_ok`/`ROOT`); `yq`/`jq`.

## Global Constraints

- Every SKILL.md frontmatter: `name:` (matches its directory name) and `description:` (non-empty, states when to use it).
- Every agent frontmatter: `name`, `description`, `tools` (exact allowlists below), `model`.
- Every role file frontmatter: `name`, `phase`, `class` (`advisory|builder|reviewer`), `model`, `policies` (list); every listed policy MUST resolve to `skills/policy-<name>/SKILL.md`.
- Universal report contract appears verbatim-in-substance in: practitioner agent, all three memory-facing agents, and `policy-epistemic` — every statement is a cited claim (`{file, lines}` | `{url, anchor}` | `{command, output}`) or a labeled judgment; reports end with a questions/doubts section.
- Memory writes remain main-session-only; no content file may instruct an agent to write GROUNDING stores, workspace docs, or session state.
- The cascade in the deliberate skill must match the spec's 8 steps and gate model A (human blocks only on ROADMAP and HIGH-LEVEL-STORIES).
- Spawn budget language: ≤ 3 concurrent, ≤ 8 per session, raised only by explicit human instruction.
- Commit after every task with the exact message given; keep the `Co-Authored-By: Claude <noreply@anthropic.com>` trailer.

## File Structure

```
skills/
├── attend/SKILL.md            deliberate/SKILL.md            # Task 2
├── consolidate/SKILL.md       skillify/SKILL.md              # Task 2
├── policy-epistemic/          policy-trace-to-frame/         # Task 1 (10 dirs,
├── policy-escalate-destructive/ policy-parallel-breadth/     #  one SKILL.md each)
├── policy-adversarial-handoff/  policy-test-driven/
├── policy-visual-verify/        policy-reversible-change/
├── policy-draft-for-ratification/ policy-reader-run/
agents/consolidator.md  explorer.md  skeptic.md  practitioner.md   # Task 3
roles/conductor.md  project-manager.md  architect.md  frontend.md  # Task 4 (10 files)
      backend.md  database.md  qa.md  reviewer.md  security.md  technical-writer.md
commands/review.md  recall.md  consolidate.md                      # Task 5
GROUNDING.yaml (migrated v2 → v3 in place)                         # Task 6
tests/test_policies.sh  test_core_skills.sh  test_agents.sh        # per-task tests
      test_roles.sh  test_commands.sh  test_migration.sh
```

---

### Task 1: Ten policy skills

**Files:** Create `skills/policy-<name>/SKILL.md` for: epistemic, trace-to-frame, escalate-destructive, parallel-breadth, adversarial-handoff, test-driven, visual-verify, reversible-change, draft-for-ratification, reader-run. Test: `tests/test_policies.sh`.

**Required content per policy** (each ≤ 40 lines; procedure body states: when it applies, the procedure steps, what it binds — which agent/skill/hook — and its violation handling):

- `policy-epistemic`: hypothesis before test; every claim cited (`{file, lines}`|`{url, anchor}`|`{command, output}`) or labeled judgment; significant claims to the skeptic before asserting; one cite-or-retract bounce.
- `policy-trace-to-frame`: all work traces to the attention frame; untraceable work stops and escalates to the main session.
- `policy-escalate-destructive`: destructive/outward actions escalate; binds the inhibition decision table; "nobody answered" is never authorization.
- `policy-parallel-breadth`: delegate exploration to explorer spawns; return synthesized conclusions with references, never raw dumps; respect spawn budget.
- `policy-adversarial-handoff`: finished work goes to a reviewer spawn before it counts as done; the judging hat never edits.
- `policy-test-driven`: failing test before implementation; RED evidence before GREEN.
- `policy-visual-verify`: run it and look; loading/error/empty states seen, not assumed.
- `policy-reversible-change`: every change ships with its undo; rollback proven before rollout; reversible migrations only.
- `policy-draft-for-ratification`: output is a proposal; human ratifies before it takes effect; never edit human-owned organs directly.
- `policy-reader-run`: execute what you document; docs that weren't run aren't done.

- [ ] **Step 1: Write failing test** — `tests/test_policies.sh`: loops the 10 names; asserts each `skills/policy-<n>/SKILL.md` exists non-empty, frontmatter `name:` equals `policy-<n>`, `description:` non-empty; greps: epistemic contains "cite" and "judgment"; draft-for-ratification contains "ratif"; adversarial-handoff contains "never edits".
- [ ] **Step 2: Run `bash tests/run.sh`** — expect new FAILs only.
- [ ] **Step 3: Author the 10 files** per requirement list.
- [ ] **Step 4: Run `bash tests/run.sh`** — expect all green.
- [ ] **Step 5: Commit** — `feat: ten policy skills (policies are invocable skills)`

---

### Task 2: Four core skills

**Files:** Create `skills/{attend,deliberate,consolidate,skillify}/SKILL.md`. Test: `tests/test_core_skills.sh`.

**attend** (slow-path attention): produce the attention frame and write it to session state via the main session; frame fields exactly: `goal, success_criteria, scope{in,out}, constraints, risks, open_questions, evidence_plan, roadmap_ref`; escalate genuine goal ambiguity to the human as one concrete question; check whether the task touches an existing open question (opportunistic experimentation); topical retrieval: query stores with `yq` for records relevant to the task.

**deliberate** (working-memory discipline + the cascade): hypothesis-before-test; synthesis over accumulation; hat assignment (role file injected into practitioner spawn); spawn budget ≤3 concurrent/≤8 per session with one-line justification each; **the cascade**, all 8 spec steps: frame → conductor produces cited cascade plan → main session ratifies (escalate to human only for human-owned organs or budget bust) → roadmap gate (visionary/product-manager draft, **blocks for human**) → stories (requirements-analyst, **blocks for human**) → tasks (project-manager or architect, auto + trail) → research per unknown (explorer/skeptic) → execution & synthesis. Dual-process entry: cascade only for slow-path multi-step work.

**consolidate** (memory-write protocol): candidate typing (`claim|preference|decision|goal|policy`); citations required on claims; dedupe against both stores; scope routing (project vs global) with human confirmation; never-store categories (credentials/secrets always; health/legal/financial by default); append records + events, run `scripts/regen-index`, re-run `scripts/trust` after writes; episode transitions (`candidate-detected → awaiting-approval → committed`); questions promoted to `open_questions` with `raised_by/date/context/refs`.

**skillify** (workspace bootstrap + maintenance): idempotent bootstrap from `templates/` (create only missing; never overwrite; `--dry-run` plan; dated backups before migration); brownfield mapping; git: workspace files committed, `.anoti/` gitignored via fragment; migration on version mismatch → propose diff, human ratifies; which document updates on which event; uninstall = files remain.

- [ ] **Step 1: Write failing test** — asserts 4 files exist with valid frontmatter; greps: attend contains `evidence_plan` and `roadmap_ref`; deliberate contains "cascade", "conductor", and "8"-step ordering markers ("Roadmap gate", "blocks for the human"); consolidate contains all five record types and "regen-index"; skillify contains "idempotent" and "dry-run".
- [ ] **Step 2: RED run.** — [ ] **Step 3: Author.** — [ ] **Step 4: GREEN run.**
- [ ] **Step 5: Commit** — `feat: core cognition skills (attend, deliberate+cascade, consolidate, skillify)`

---

### Task 3: Four agents

**Files:** Create `agents/{consolidator,explorer,skeptic,practitioner}.md`. Test: `tests/test_agents.sh`.

Exact frontmatter (binding):

| Agent        | model   | tools                                                                 |
| ------------ | ------- | --------------------------------------------------------------------- |
| consolidator | sonnet  | Read, Grep, Glob                                                      |
| explorer     | haiku   | Read, Grep, Glob                                                      |
| skeptic      | inherit | Read, Grep, Glob, Bash                                                |
| practitioner | inherit | (omit tools — role profile governs; body forbids memory-organ writes) |

Bodies (binding content): each carries the universal report contract (cited claim | labeled judgment; questions/doubts section; done-claims with evidence artifacts). consolidator: proposes typed candidates + evidence + scope, deduped, contradictions flagged never resolved; read-only. explorer: synthesized findings with file references, token-capped, never raw dumps. skeptic: attempts refutation; verdict + evidence; defaults to "not established" when uncertain; Bash for running refutation tests only. practitioner: reads injected role profile + attention frame; wears exactly one hat; satisfies the role's definition-of-done with evidence before returning; reviewer-class roles never edit.

- [ ] **Step 1: Failing test** — frontmatter fields + exact `tools:` strings + `model:` values; grep each body for "judgment" (contract) and "questions".
- [ ] **Steps 2–4: RED → author → GREEN.**
- [ ] **Step 5: Commit** — `feat: memory-facing agents and the practitioner`

---

### Task 4: Ten core-v1 roles

**Files:** Create `roles/{conductor,project-manager,architect,frontend,backend,database,qa,reviewer,security,technical-writer}.md`. Test: `tests/test_roles.sh`.

Frontmatter per role: `name`, `phase`, `class`, `model`, `policies` (list). Body: Lens / Approach / Definition of done (with required evidence artifacts).

| Role             | class    | model   | policies (all also get the 3 universal: epistemic, trace-to-frame, escalate-destructive) |
| ---------------- | -------- | ------- | ---------------------------------------------------------------------------------------- |
| conductor        | advisory | sonnet  | draft-for-ratification                                                                   |
| project-manager  | advisory | haiku   | draft-for-ratification                                                                   |
| architect        | advisory | inherit | parallel-breadth                                                                         |
| frontend         | builder  | sonnet  | test-driven, visual-verify, adversarial-handoff                                          |
| backend          | builder  | sonnet  | test-driven, adversarial-handoff                                                         |
| database         | builder  | sonnet  | reversible-change, test-driven, adversarial-handoff                                      |
| qa               | builder  | sonnet  | test-driven                                                                              |
| reviewer         | reviewer | inherit | (universals only; body: never edits, findings with evidence)                             |
| security         | reviewer | inherit | (universals only; threat-model-first)                                                    |
| technical-writer | builder  | haiku   | reader-run, draft-for-ratification                                                       |

conductor body additionally (binding): lens "who must think about what, in what order"; cognitive analog: executive function; produces a **cascade plan** — roadmap needed/exists (cited), agent sequence with produces/consumes/gates, unknowns each assigned a research role, spawn count vs budget; never dispatches, never executes.

- [ ] **Step 1: Failing test** — 10 files exist; frontmatter fields present; every `policies:` entry resolves to `skills/policy-<p>/SKILL.md`; conductor greps: "cascade plan", "executive function", "never dispatches"; reviewer greps "never edits".
- [ ] **Steps 2–4: RED → author → GREEN.**
- [ ] **Step 5: Commit** — `feat: core-v1 role library led by the conductor`

---

### Task 5: Three commands

**Files:** Create `commands/{review,recall,consolidate}.md`. Test: `tests/test_commands.sh`.

- `review`: list `ratification: pending` records (and probable claims) with evidence; human approves/rejects/promotes/demotes; every transition = appended event; supports global-store review (view/correct/delete/export).
- `recall`: `$ARGUMENTS` topic → `yq` queries over both stores' indexes then matching full records; results presented inside the untrusted-data framing.
- `consolidate`: manual consolidation fallback — run the consolidator flow (episode `awaiting-approval`), present proposals, apply approved appends, `regen-index`, `trust`, set episode `committed`.

- [ ] **Step 1: Failing test** — 3 files, frontmatter `description:` non-empty; recall contains `$ARGUMENTS`; consolidate contains "regen-index".
- [ ] **Steps 2–4: RED → author → GREEN.**
- [ ] **Step 5: Commit** — `feat: review, recall, and consolidate commands`

---

### Task 6: Migrate this repo's GROUNDING.yaml to v3

**Files:** Rewrite `GROUNDING.yaml` (v2 → v3 by hand — one file, four records; a generic migrator is skillify's later job). Backup first: `cp GROUNDING.yaml GROUNDING.yaml.v2.bak` (gitignored? No — commit the removal implicitly; keep .bak out of git via .gitignore addition NOT needed — delete after verification). Test: `tests/test_migration.sh`.

Mapping (binding):

- `meta`: `schema_version: 3`, `scope: project`, policy block from template; preserve old changelog under `meta.changelog` (extra keys are tolerated).
- D001–D004 → `records`, `type: claim`, `statement:` = the v2 summary condensed to one sentence; all v2 detail fields (`sequence`, `contrasts`, `details`, `caveats`, `relationships`, `note`, `implications`) preserved verbatim as extra keys on the record.
- **Grandfathering per spec:** D001–D003 `epistemic_status: probable` with event `{action: demoted, note: grandfathered; evidence pending}`; D004 stays `probable`. All four `ratification: approved` (the human ratified this content during design review).
- D004 `evidence:` gains its real entry: comparative agent observation, ref to the spec file + conversation.
- Q001 → `open_questions[0]`: `{id: Q001, date, question, raised_by: session, context: format-comprehension experiment (D004.verification), status: open, refs: [docs/specs/2026-08-12-anoti-plugin-design.md]}`.
- Then: `scripts/regen-index GROUNDING.yaml` && `scripts/trust GROUNDING.yaml`.
- CLAUDE.md: replace the manual read-GROUNDING instruction with: plugin hooks own retrieval when anoti is installed; the manual pointer remains only as fallback for sessions without the plugin.

- [ ] **Step 1: Failing test** — `validate-workspace GROUNDING.yaml` exits 0; `yq` asserts: schema_version 3; 4 records; D001 `epistemic_status` = probable; D001 events contain a `demoted` action; D004 evidence length ≥ 1; open_questions[0].id = Q001; index length = 4.
- [ ] **Steps 2–4: RED → migrate → GREEN** (plus live smoke: `printf '{"session_id":"m"}' | scripts/retrieve` digest now reports "4 records" instead of "fails validation"; delete the .bak).
- [ ] **Step 5: Commit** — `feat: migrate project grounding to schema v3 (grandfathering applied)`

---

### Task 7: Version bump + full acceptance

- [ ] Bump `.claude-plugin/plugin.json` version to `0.2.0`.
- [ ] `bash tests/run.sh` — full suite green is the Plan 2 acceptance gate.
- [ ] Commit — `feat: anoti 0.2.0 — cognition layer complete`

## Deferred to Plan 3

Live dogfood behavioral tests, H1–H3 comparative benchmark, v1.1 role set, global-store opt-in UX polish.
