---
description: Review implementation before commit
---

You are an autonomous code review agent. Review the current implementation thoroughly. Never rubber-stamp.

## Step 0: Set Workflow State

```bash
.claude/project/workflow-state.sh advance under_review
```

This signals to hooks that review is active. Source file edits are warned against during review.

## Step 1: Fresh-Context Review via Sub-Agents (MANDATORY)

**Launch ALL 4 review tracks in parallel using the Task tool.** Each agent starts fresh, re-reads the spec and code independently, free from implementation bias.

Read the active story ID from `.claude/project/workflow-state.sh get-field activeStory` first, then pass it to each agent.

### Track 1: Backend API Review (backend-api-engineer agent)

Prompt the agent to:

- Read the feature spec from `.claude/project/features/us-XXX-*.md` and plan from `.claude/project/plans/us-XXX-plan.md`
- Read every changed backend file (routes, services, schemas, types)
- Map each acceptance criterion to specific `file:line` — flag any AC not met as a BLOCKER
- Verify error handling, input validation, audit logging on all mutations
- Check for logic bugs: pagination with filters, state transitions, side effects of operations
- Verify edge cases from the plan are handled

### Track 2: Frontend Review (frontend-spa-engineer agent)

Prompt the agent to:

- Read the feature spec and plan
- Read every changed frontend file (components, hooks, API client, types)
- Verify UI acceptance criteria: filters, badges, buttons, dialogs, toasts
- Check accessibility: aria attributes, keyboard navigation, screen reader support
- Check for confirmation dialogs on destructive actions (especially bulk)

### Track 3: Test Coverage (qa-automation-engineer agent)

Prompt the agent to:

- Read test files for the feature
- Check coverage against these mandatory categories:
  - **Authorization**: Unauthorized access is rejected (MANDATORY)
  - **Input validation**: Invalid inputs return proper errors (MANDATORY)
  - **State transitions**: After action X, verify downstream state Y (MANDATORY)
  - **Error handling**: Expected failure modes return correct responses (MANDATORY)
  - **Edge cases**: Empty inputs, boundary values, concurrent access (if applicable)
- Flag any mandatory category with zero assertions as a BLOCKER
- Also check any project-specific test categories defined in CLAUDE.md or testing skills

### Track 4: Security Review (security-privacy-engineer agent)

Prompt the agent to:

- Read all new routes, services, and processors
- Verify authorization checks on all protected routes
- Verify no sensitive data exposed in error messages or logs
- Check input validation and sanitization on all endpoints
- Verify no hardcoded secrets, API keys, or credentials
- Check for common vulnerabilities (injection, XSS, CSRF where applicable)

## Step 2: Compile Results

After all 4 tracks complete:

1. Merge findings from all tracks into a single prioritized list
2. De-duplicate overlapping findings
3. Classify each as BLOCKER or WARNING

## Step 3: Build Gate

Run in order — these must pass regardless of review findings:

1. Type checking (zero errors)
2. Linting (zero warnings)
3. Tests (all pass)

Add any build failures to the blockers list.

## Step 4: Set Workflow State Based on Results

### If blockers exist (NOT READY):

```bash
# Store findings for the fix loop
.claude/project/workflow-state.sh set-findings '["Blocker 1 description", "Blocker 2 description"]'
.claude/project/workflow-state.sh advance changes_requested
```

Then output the report and **immediately start fixing blockers**:

1. Fix each blocker in priority order
2. After ALL blockers are fixed, re-run this review (`/review`) — this creates the continuous loop
3. Do NOT ask the user whether to fix — just fix and re-review

### If no blockers (READY):

```bash
.claude/project/workflow-state.sh set-findings '[]'
.claude/project/workflow-state.sh advance review_passed
```

## Output

Report results in this format:

```
REVIEW: US-XXX — [Story Title] (cycle N)

ACs:         X/Y met (0 deferred)
Integration: Pass/FAIL — [details if fail]
Security:    Pass/FAIL — [details if fail]
Quality:     Pass/FAIL — [details if fail]
Tests:       Pass/FAIL — [mandatory categories: N/5 covered]
Build:       Pass/FAIL — [test count]

Blockers: [numbered list or "none"]
Warnings: [numbered list or "none"]

Status: READY / NOT READY (cycle N)
```

If NOT READY: fix all blockers, then re-run `/review`. Repeat until READY.
If READY: proceed to commit.
