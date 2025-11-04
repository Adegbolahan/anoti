# High-Level User Stories

TODO: Fill in project-specific user stories and track their progress.

This document is the **central progress tracker** for all user stories in the project.

---

## How to Use This Document

**Purpose:** Track the status of all user stories from requirements through implementation.

**Update Frequency:**
- When user story is created → Add to table with status "📝 Planned"
- When implementation plan is approved → Update "Plan Status" to "✅ Approved"
- When implementation starts → Update "Status" to "🚧 In Progress"
- When feature is complete → Update "Status" to "✅ Complete" and add commit hash

**Cross-References:**
- Each user story links to detailed specification in `/docs/features/`
- Each plan links to implementation plan in `/docs/plans/`
- Commit hash links to git commit that implemented the feature

**ID Convention:**
- Use **uppercase** (`US-003`) in the ID column and display text
- Use **lowercase** (`us-003-name.md`) in file paths and links
- See [User Story ID Conventions](user-story-standards.md#user-story-id-conventions) for full details

---

## User Stories Progress Tracker

### Legend

**Plan Status:**
- ➖ No plan - No implementation plan created yet
- 📝 Draft - Plan exists but not approved
- ✅ Approved - Plan reviewed and approved, ready for implementation
- 🚧 In Progress - Implementation in progress
- ✔️ Complete - Feature implemented and plan archived

**Story Status:**
- 📝 Planned - User story defined, not started
- 🚧 In Progress - Currently being implemented
- ✅ Complete - Implemented, tested, and deployed
- 🔄 Revised - Story revised, plan needs update
- ⏸️ On Hold - Blocked or paused

---

## Progress Table

| ID | Feature | Story File | Plan File | Plan Status | Status | Commit |
|----|---------|------------|-----------|-------------|--------|--------|
| US-001 | [Feature name] | [Link](features/us-001-feature.md) | [Link](plans/us-001-plan.md) | ✅ Approved | 🚧 In Progress | - |
| US-002 | [Feature name] | [Link](features/us-002-feature.md) | ➖ No plan | ➖ No plan | 📝 Planned | - |

**Example completed entry:**
```markdown
| US-003 | User Authentication | [Link](features/us-003-auth.md) | [Link](plans/us-003-plan.md) | ✔️ Complete | ✅ Complete | abc1234 |
```

---

## Summary Statistics

**Total User Stories:** [X]

**By Status:**
- ✅ Complete: [X] ([XX]%)
- 🚧 In Progress: [X] ([XX]%)
- 📝 Planned: [X] ([XX]%)
- ⏸️ On Hold: [X] ([XX]%)

**By Plan Status:**
- ✔️ Complete: [X]
- 🚧 In Progress: [X]
- ✅ Approved: [X]
- 📝 Draft: [X]
- ➖ No plan: [X]

---

## Phase Breakdown (Optional)

### Phase 1: Foundation ([X] stories)
- US-001: [Feature] - ✅ Complete
- US-002: [Feature] - 🚧 In Progress
- US-003: [Feature] - 📝 Planned

### Phase 2: Core Features ([X] stories)
- US-004: [Feature] - 📝 Planned
- US-005: [Feature] - 📝 Planned

### Phase 3: Polish & Optimization ([X] stories)
- US-006: [Feature] - 📝 Planned

---

## How to Update This Document

### When Creating a New User Story

1. Add row to progress table
2. Link to user story file in `/docs/features/`
3. Set Plan Status to "➖ No plan"
4. Set Status to "📝 Planned"

```markdown
| US-XXX | Feature Name | [Link](features/us-XXX-name.md) | ➖ No plan | ➖ No plan | 📝 Planned | - |
```

### When Implementation Plan is Created

1. Update "Plan File" column with link to `/docs/plans/us-XXX-plan.md`
2. Update "Plan Status" to "📝 Draft"

```markdown
| US-XXX | Feature Name | [Link](features/us-XXX-name.md) | [Link](plans/us-XXX-plan.md) | 📝 Draft | 📝 Planned | - |
```

### When Plan is Approved

1. Update "Plan Status" to "✅ Approved"

```markdown
| US-XXX | Feature Name | [Link](features/us-XXX-name.md) | [Link](plans/us-XXX-plan.md) | ✅ Approved | 📝 Planned | - |
```

### When Implementation Starts

1. Update "Plan Status" to "🚧 In Progress"
2. Update "Status" to "🚧 In Progress"

```markdown
| US-XXX | Feature Name | [Link](features/us-XXX-name.md) | [Link](plans/us-XXX-plan.md) | 🚧 In Progress | 🚧 In Progress | - |
```

### When Feature is Complete

1. Update "Plan Status" to "✔️ Complete"
2. Update "Status" to "✅ Complete"
3. Add commit hash from `git log`

```markdown
| US-XXX | Feature Name | [Link](features/us-XXX-name.md) | [Link](plans/us-XXX-plan.md) | ✔️ Complete | ✅ Complete | abc1234 |
```

---

## Integration with Feature Workflow

This document is referenced at key points in the feature development process:

1. **Phase 1+2 (/discovery):** Check if user story exists and current status
2. **Phase 3+3.5 (/plan-and-validate):** Update plan status to "📝 Draft" when plan is saved
3. **User approves plan:** Manually update plan status to "✅ Approved"
4. **Phase 4 (/start-implementation):** Update plan status to "🚧 In Progress" and story status to "🚧 In Progress"
5. **Step 10 (Commit):** Update story status to "✅ Complete", plan status to "✔️ Complete", and add commit hash

---

## Related Documents

- **User Story Standards:** See `docs/user-story-standards.md`
- **Feature Development Process:** See `docs/feature-development-process.md`
- **User Story Files:** See `/docs/features/` directory
- **Implementation Plans:** See `/docs/plans/` directory
- **Implementation Plan Template:** See `docs/implementation-plan-template.md`
