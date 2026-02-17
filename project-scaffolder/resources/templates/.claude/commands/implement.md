---
description: Implement a feature end-to-end
---

You are an autonomous feature implementation agent. Follow this phased workflow exactly. Never skip phases.

## Phase 0: Discovery (EVERY time — do not rush this)

### 0a. Context

- Read `.claude/project/high-level-user-stories.md` — find the story, understand what's complete and what's in progress
- Read `.claude/project/roadmap.md` — understand which phase this story belongs to, what's already delivered in that phase, and what the phase goals are
- If a feature spec already exists in `.claude/project/features/us-XXX-*.md`, read it
- If a plan exists in `.claude/project/plans/us-XXX-plan.md`, read it
- Read the database schema to understand the current data model

### 0b. Pattern Research

- Read 2-3 existing feature modules — match their structure, naming, error handling, and test patterns exactly
- Read `package.json` (root + relevant packages) — note exact versions of key deps
- If the feature needs a new dependency, check version compatibility with existing packages before adding

### 0c. Integration Analysis

- Identify every story this one depends on — read their feature specs AND verify their implementation actually exists in code
- For each integration point, verify:
  - API endpoints exist and return the expected shape
  - Types/interfaces are exported and importable
  - DB tables, columns, and relationships are present in the schema
  - Frontend shared state is accessible
- If anything is missing or mismatched, flag it as a **pre-requisite fix** before proceeding

### 0d. Gap & Risk Analysis

- List what the ACs do NOT cover: error states, empty states, permission edge cases, concurrent access, bulk operations
- Identify assumptions: does this assume a service is running? An env var exists? A specific data shape?
- Check for migration risks: will schema changes break existing data? Need backfill?
- Ask the user about anything ambiguous — do not guess at requirements

### 0e. Create Story (MANDATORY GATE — do not skip)

**A feature spec file MUST exist before moving to Phase 1.**

- If the feature spec does not yet exist:
  1. Ask ALL clarifying questions first — requirements, scope, edge cases, user expectations
  2. Wait for the user to answer every question. Do not proceed with unanswered ambiguities
  3. Only after all concerns are resolved, create the spec at `.claude/project/features/us-XXX-name.md`
  4. Include: persona, goal, benefit, and testable acceptance criteria checklists
  5. Update `high-level-user-stories.md` with the new entry
- If the feature spec already exists, verify it covers everything from 0c and 0d. Update it if gaps were found

**Do NOT proceed to Phase 1 without a written feature spec file.**

### 0f. Checklist

- Write a TodoWrite checklist of all acceptance criteria + integration pre-reqs + identified gaps

## Phase 1: Plan

### 1a. File Inventory

- List every file to create/modify with a 1-line description of the change
- Order by dependency: schema → migration → types → service → routes → frontend components → tests
- For each modified file, note what specifically changes (not just "update service")

### 1b. Dependency & Compatibility

- List any new packages needed with exact versions — verify peer dep compatibility with existing stack
- If adding a migration, describe the exact changes and whether they're backwards-compatible
- If touching shared types or APIs consumed by other features, identify what else could break

### 1c. Integration Contract

- For each integration point from Phase 0c, state the exact contract: endpoint path, request/response shape, types consumed
- If this story introduces APIs that future stories will consume, document the contract explicitly

### 1d. Risks & Mitigations

- What could go wrong? (migration failure, breaking existing tests, type conflicts, race conditions)
- For each risk, state the mitigation

### 1e. Save & Approve

- Save plan to `.claude/project/plans/us-XXX-plan.md`
- **Present the plan summary and wait for user approval before Phase 2**

### 1f. Context Handoff (MANDATORY — after approval, before coding)

**After the user approves, produce a clear context summary before writing any code:**

1. **Story**: US-XXX — one-line description
2. **ACs**: Numbered list of every acceptance criterion from the feature spec
3. **Integration points**: Each dependency with its verified contract (endpoint, types, DB refs)
4. **Pre-requisite fixes**: Any issues found in 0c that must be resolved first
5. **Risk mitigations**: Key risks and their planned mitigations
6. **File order**: The implementation sequence from 1a

This context summary ensures nothing from discovery/planning is lost when implementation begins — even if context is compacted or the session is resumed.

## Phase 2: Implement

- Follow the dependency order from the context handoff strictly
- After every 3 file changes, run type checking to catch errors early
- Write tests alongside implementation, not after
- Search for shared/reusable components before creating new ones

## Phase 3: Validate (Review Cycle — automated fix loop)

### 3a. Pre-Review Test Categories

Before running the review, verify tests cover ALL applicable categories. If any applicable category has zero assertions, add tests now:

- **Authorization**: At least 1 test verifying unauthorized access is rejected
- **Input validation**: Invalid/malformed inputs return proper error responses
- **State transitions**: After each action, verify the entity is in the expected downstream state (not a stale or invalid state)
- **Error handling**: Expected failure modes (not found, conflict, timeout) return correct status codes and messages
- **Edge cases**: Empty inputs, boundary values, concurrent access where applicable

> **Customize this list** for your project's specific concerns (e.g., tenant isolation for multi-tenant apps, audit logging for compliance, rate limiting for APIs).

### 3b. Run `/review` (triggers automated review cycle)

Run the `/review` command. This:

1. Sets workflow state to `under_review`
2. Launches 4 parallel sub-agent review tracks (backend, frontend, tests, security)
3. Compiles findings into a single report
4. If NOT READY → sets `changes_requested`, stores blockers, **automatically fixes all blockers**, then re-runs `/review`
5. If READY → sets `review_passed`, unblocks commit

**The commit is BLOCKED by hooks until the review passes.** The fix → re-review loop continues autonomously until all blockers are resolved. Do not ask the user to intervene unless a blocker requires a design decision.

### 3c. Verify Review Passed

After the review cycle completes, confirm the state:

```bash
.claude/project/workflow-state.sh get-field phase  # Should be: review_passed
```

## Phase 4: Commit & Update

1. Update plan status to Complete
2. Update story status in `.claude/project/high-level-user-stories.md`
3. Conventional commit: `feat: description (US-XXX)`
4. Report: test count, files changed, any follow-ups noted

## Error Recovery (CRITICAL — do not retry blindly)

| Error                 | Do This                                                    |
| --------------------- | ---------------------------------------------------------- |
| Migration fails       | Read migration scripts and docs before retrying            |
| Unknown CLI flag      | Read `--help` output for the actual tool                   |
| Type error            | Read the actual type definition file — never cast to `any` |
| Pre-commit hook fails | Read hook config, fix root cause — never use `--no-verify` |
| Test fails            | Read the test and the code it tests — don't guess at fixes |
| Import not found      | Use Glob to find the actual export path                    |
