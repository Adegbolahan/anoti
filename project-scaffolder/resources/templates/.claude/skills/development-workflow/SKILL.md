---
name: Development Workflow
description: |
  Use this skill when the user asks to implement/build/create a feature, or asks about development process, git workflow, or planning. Triggers on: "implement feature", "build feature", "add feature", "create feature", "how do I implement", "git workflow", "branching strategy", "commit conventions".
version: 2.2.0
---

# Development Workflow

## Feature Implementation Flow (REQUIRED)

**When user requests a feature, ALWAYS follow this 5-phase flow (see `/implement`):**

```
Phase 0: Discovery   → Research codebase, ask ALL questions, create story spec (MANDATORY GATE)
Phase 1: Plan        → File inventory, integration contracts, risks → save plan → approval → context handoff (MANDATORY)
Phase 2: Implement   → Build in dependency order, tests alongside code
Phase 3: Review      → Sub-agent review → auto-fix → re-review loop (COMMIT BLOCKED until passed)
Phase 4: Commit      → Update tracking, conventional commit, report
```

**Mandatory gates:**

- **No Phase 1 without a written story file** in `.claude/project/features/`. Resolve all questions first, then create the spec.
- **No Phase 2 without plan approval AND context handoff** — summarize ACs, integration points, risks, and file order before writing code.
- **No Phase 4 (commit) without review passing** — `/review` launches 4 parallel sub-agents, auto-fixes blockers, and re-reviews in a loop until clean. Hooks BLOCK `git commit` until `review_passed`.
- **Never start coding without approved plan**

### File Naming Conventions

| Type  | Path                                      | Example                |
| ----- | ----------------------------------------- | ---------------------- |
| Story | `.claude/project/features/us-XXX-name.md` | `us-001-user-login.md` |
| Plan  | `.claude/project/plans/us-XXX-plan.md`    | `us-001-plan.md`       |

- **Filenames:** lowercase (`us-001`)
- **Display:** UPPERCASE (`US-001`)

### Auto-Increment User Story IDs

When creating a new user story:

1. Read `high-level-user-stories.md` to find the highest US-XXX number
2. Use the next number (e.g., if US-003 exists, use US-004)
3. If user specifies a number, use that instead

### After Creating Files

**After creating a user story:**

1. Update `high-level-user-stories.md` table with new entry
2. Update Overview counts
3. Set initial status to 'Planned'

**After creating a plan:**

1. Link plan in `high-level-user-stories.md` Plan column
2. Update Overview counts if needed

**After completing a feature:**

1. Update story status in `high-level-user-stories.md`
2. Add commit hash to the story
3. Update `roadmap.md` phase progress

---

## Workflow Commands

| Command      | Purpose                                                                          |
| ------------ | -------------------------------------------------------------------------------- |
| `/implement` | Full feature workflow: discovery → plan → implement → review cycle → commit      |
| `/review`    | 4-track sub-agent review with automated fix loop until all blockers are resolved |

Phase tracking is automated via hooks (see `.claude/settings.json`). Commits are BLOCKED until review passes.

---

## Quick Process Checklist

For every feature, these must happen in order:

1. **Read skills** - Load domain patterns for the feature area
2. **Research** - Explore codebase, find existing patterns, check integration points
3. **Ask questions** - Resolve ALL ambiguities before writing the story
4. **Write story** - Create feature spec with ACs in `.claude/project/features/` (GATE)
5. **Plan** - File inventory, integration contracts, risks → save to `.claude/project/plans/`
6. **Get approval** - Present plan, wait for user approval (GATE)
7. **Context handoff** - Summarize ACs, integration points, file order before coding (GATE)
8. **Build** - Implement in dependency order, tests alongside code
9. **Review** - `/review` launches sub-agents, auto-fixes, re-reviews until clean (COMMIT GATE)
10. **Commit** - Conventional commit, update tracking files (only after review_passed)

---

## Git Conventions

**Branches:**

- `feature/<name>` - New features
- `fix/<name>` - Bug fixes
- `hotfix/<name>` - Urgent fixes
- `chore/<name>` - Maintenance

**Commits:** Conventional Commits format

```
<type>: <subject>

<body>
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`

**Example:**

```bash
git commit -m "feat: add user authentication

- Login and register endpoints
- JWT token generation
- Tests: 90% coverage"
```

---

## Plan Structure (10 Sections)

1. Requirements Summary
2. Technical Approach
3. Database Changes
4. API Layer
5. Component Architecture
6. State Management
7. Edge Cases & Error Handling
8. Testing Strategy
9. Implementation Checklist
10. Effort & Risks

---

## Pre-Commit Checklist

- [ ] Lint passes
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Edge cases handled
- [ ] Story status updated
- [ ] high-level-user-stories.md updated
