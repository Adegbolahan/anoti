# User Story Standards

User stories define **WHAT** to build and **WHY** it matters from the user's perspective.

## Table of Contents
- [User Story Format](#user-story-format)
- [User Story ID Conventions](#user-story-id-conventions)
- [Acceptance Criteria](#acceptance-criteria-checklist-format)
- [User Story Examples](#user-story-examples)
- [User Story Size Guidelines](#user-story-size-guidelines)
- [Quality Checklist](#user-story-quality-checklist)
- [Integration with Development Process](#integration-with-feature-development-process)
- [Common Mistakes](#common-mistakes-to-avoid)

---

## User Story Format

Use this standard format:

```
As a [user type/persona],
I want [goal/desire],
So that [benefit/value].
```

### Required Elements

- **User Type**: Who is this for? (client admin, platform admin, end customer, etc.)
- **Goal**: What does the user want to do? (concrete action)
- **Benefit**: Why does this matter? (value to user)

---

## User Story ID Conventions

User stories are identified by IDs that follow a specific case convention depending on context.

### Case Usage Rules

**Use UPPERCASE (`US-XXX`) for:**
- ✅ **Display contexts** - Tables, titles, headers, documentation text
- ✅ **Human communication** - Discussions, comments, commit messages
- ✅ **References in prose** - "As described in US-003..."

**Use lowercase (`us-xxx`) for:**
- ✅ **File paths** - Filenames, directory names, code references
- ✅ **URL slugs** - Web routes, API endpoints
- ✅ **Template patterns** - Pattern documentation (e.g., `us-XXX-<name>.md`)

### Why This Convention?

**Uppercase for readability**: Makes IDs stand out in text and tables, easier to scan visually
**Lowercase for filesystem**: Follows Unix/Linux conventions and avoids case-sensitivity issues across operating systems

### Examples

#### ✅ CORRECT Usage

**In tracking table (uppercase):**
```markdown
| US-003 | View Conversations | [Link](features/us-003-view-conversations.md) | ✅ Complete |
```

**In file path (lowercase):**
```markdown
docs/features/us-003-view-conversations.md
docs/plans/us-003-plan.md
```

**In commit message (uppercase for display):**
```bash
feat: add conversation filtering

Implements: docs/features/us-003-view-conversations.md
```

**In documentation text (uppercase):**
```markdown
User story US-003 defines the requirements for viewing conversation history.
```

**In template pattern (lowercase):**
```markdown
Save user story to: docs/features/us-XXX-<feature-name>.md
```

#### ❌ INCORRECT Usage

**Wrong: Uppercase in file path**
```markdown
docs/features/US-003-view-conversations.md  ❌
```

**Wrong: Lowercase in display text**
```markdown
| us-003 | View Conversations | ... |  ❌
```

**Wrong: Mixed case**
```markdown
| US-003 | View Conversations | [Link](features/US-003-view-conversations.md) | ❌
```

### Quick Reference

| Context | Case | Example |
|---------|------|---------|
| Table row | UPPER | `US-003` |
| Filename | lower | `us-003-view-conversations.md` |
| Directory | lower | `docs/features/`, `docs/plans/` |
| Text reference | UPPER | "See US-003 for details" |
| Commit message | UPPER | "Implements US-003" |
| File path in link | lower | `[Link](features/us-003-name.md)` |
| Template pattern | lower | `us-XXX-<name>.md` |

### Consistency Check

When creating or referencing user stories, verify:
- [ ] Table entries use uppercase (`US-003`)
- [ ] File paths use lowercase (`us-003-name.md`)
- [ ] Links in markdown use lowercase paths
- [ ] Display text uses uppercase for readability
- [ ] Both ID and filename match (except for case)

---

## Acceptance Criteria (Checklist Format)

Every user story **MUST** have acceptance criteria using checklist format:

```
Acceptance Criteria:
- [ ] User can [perform action]
- [ ] System displays [expected result]
- [ ] Error shown if [failure condition]
- [ ] [Edge case] handled correctly
- [ ] Loading state shown during [async operation]
- [ ] Success message shown after [action completes]
```

### Required Coverage

- ✅ **Happy path** (normal flow works correctly)
- ✅ **Error cases** (validation failures, network errors, API errors)
- ✅ **Edge cases** (empty states, maximum limits, boundary conditions)
- ✅ **UI feedback** (loading spinners, success messages, error alerts)
- ✅ **Accessibility** (keyboard navigation, screen reader support if applicable)

---

## User Story Examples

### ✅ GOOD User Story

```markdown
**User Story 3.1: View Conversation List**

As a client admin,
I want to view a paginated list of all AI conversations with my customers,
So that I can review past interactions and identify training opportunities for my AI agent.

**Acceptance Criteria:**

Given I am logged in as a client admin,
When I navigate to the Conversations page,
Then I see a list of conversations with the following information:
- [ ] Customer name
- [ ] Customer phone number
- [ ] Conversation type (voice or SMS badge)
- [ ] Date and time
- [ ] Duration (for voice calls)
- [ ] Sentiment indicator (positive, neutral, negative)

Given I am viewing the conversation list,
When the data is loading,
Then I see a loading spinner.

Given I am viewing the conversation list,
When the API call fails,
Then I see an error message with a "Retry" button.

Given I am viewing the conversation list,
When there are no conversations,
Then I see an empty state with message "No conversations yet. Your AI agent will start logging calls and messages soon."

**Filters & Search:**
- [ ] Filter by type (All, Voice, SMS)
- [ ] Search by customer name or phone number
- [ ] Search results update as I type (debounced 300ms)

**Pagination:**
- [ ] Show 50 conversations per page
- [ ] Display page numbers and navigation buttons
- [ ] Show total count (e.g., "Showing 1-50 of 247")

**Accessibility:**
- [ ] Keyboard navigation works (Tab, Enter, Arrow keys)
- [ ] Screen reader announces page changes
- [ ] Focus states visible on all interactive elements

**Edge Cases:**
- [ ] Handle conversations with missing data gracefully (no customer name → "Unknown")
- [ ] Handle very long customer names (truncate with ellipsis)
- [ ] Handle network timeouts (show error after 30s)
```

**Why This Is Good:**
- ✅ Clear user persona and value proposition
- ✅ Specific, testable acceptance criteria (can verify each checkbox)
- ✅ Covers happy path, loading, error, and empty states
- ✅ Includes UI/UX requirements (filters, pagination, accessibility)
- ✅ Identifies edge cases upfront
- ✅ Right-sized (2-3 days of work)

---

### ❌ BAD User Story (Too Vague)

```markdown
As a user,
I want to see conversations,
So I can use the app.

Acceptance Criteria:
- User can view conversations
- It should work
```

**Why This Is Bad:**
- ❌ Generic user persona ("a user" vs specific persona)
- ❌ No specific flows or actions defined
- ❌ Acceptance criteria not testable ("it should work")
- ❌ Missing edge cases, error handling, UI requirements
- ❌ No clear definition of "done"
- ❌ Cannot estimate effort or write tests

---

### ❌ BAD User Story (Too Technical)

```markdown
As a developer,
I want to implement a React component using RTK Query with TypeScript,
So that the API calls are cached and the component re-renders efficiently.

Acceptance Criteria:
- Use @reduxjs/toolkit/query for data fetching
- Implement useGetConversationsQuery hook
- Add loading and error states with isLoading and error from RTK Query
- Use TypeScript strict mode
```

**Why This Is Bad:**
- ❌ User is "developer" (should be end user)
- ❌ Focuses on **HOW** (implementation details) not **WHAT** (user value)
- ❌ No user-facing value described
- ❌ This should be in architecture decisions or coding standards, not a user story

---

## User Story Size Guidelines

### Good Size (1-3 days of work)
- ✅ Single user-facing feature or screen
- ✅ Can be demoed to stakeholder
- ✅ Delivers user value independently
- ✅ Has clear beginning and end

### Too Large (Epic - Break Down)
- ❌ "Build conversation management system" (this is an Epic)
- ❌ Multiple screens or complex workflows
- ❌ Takes more than 1 week
- ❌ Has many "and" statements ("view AND edit AND delete AND filter")

**Break large epics into smaller stories:**
```
Epic: Conversation Management
  ↓
Stories:
- View conversation list (2 days)
- View conversation detail (2 days)
- Filter and search conversations (1 day)
- Delete conversation (1 day)
- Export conversations to CSV (1 day)
```

### Too Small (Combine or Make a Task)
- ❌ "Change button color to blue"
- ❌ "Fix typo in error message"
- ❌ No user-facing value

---

## User Story Quality Checklist

Before starting implementation, verify:

- [ ] Clear user persona (not "user" or "developer")
- [ ] Specific goal (concrete action, not vague)
- [ ] Clear benefit/value (why it matters to user)
- [ ] Testable acceptance criteria (can verify each criterion)
- [ ] Happy path defined (normal flow)
- [ ] Error cases covered (validation, network errors)
- [ ] Edge cases identified (empty states, limits)
- [ ] UI/UX requirements specified (loading, error, success states)
- [ ] Accessibility requirements included (if interactive)
- [ ] Right-sized (1-3 days of work)
- [ ] Delivers value independently
- [ ] Written from user perspective (not technical implementation)

---

## Plan Metadata in User Story Files

Each user story file should include a **Plan Metadata** section that links to its implementation plan:

```markdown
## Implementation Plan

- **Plan File:** [docs/plans/us-XXX-plan.md](../plans/us-XXX-plan.md)
- **Plan Status:** ✅ Approved | 🚧 In Progress | 📝 Draft | ➖ No plan
- **Plan Created:** YYYY-MM-DD
- **Approved By:** [Name] (optional)
- **Estimated Effort:** X days
- **Actual Effort:** Y days (updated when complete)
```

### When to Update Plan Metadata

**When plan is created (Phase 3):**
```markdown
- **Plan File:** [docs/plans/us-001-plan.md](../plans/us-001-plan.md)
- **Plan Status:** 📝 Draft
- **Plan Created:** 2025-10-27
```

**When plan is approved:**
```markdown
- **Plan Status:** ✅ Approved
- **Approved By:** Product Manager
```

**When implementation starts (Phase 4):**
```markdown
- **Plan Status:** 🚧 In Progress
```

**When implementation completes:**
```markdown
- **Plan Status:** ✔️ Complete
- **Actual Effort:** 4.5 days
```

### Example User Story with Plan Metadata

```markdown
# US-003: View Conversation List

## Implementation Plan

- **Plan File:** [docs/plans/us-003-plan.md](../plans/us-003-plan.md)
- **Plan Status:** ✅ Approved
- **Plan Created:** 2025-10-27
- **Approved By:** Product Team
- **Estimated Effort:** 5 days
- **Actual Effort:** 4.5 days

---

As a client admin,
I want to view a paginated list of all AI conversations with my customers,
So that I can review past interactions and identify training opportunities.

**Acceptance Criteria:**
[... rest of user story ...]
```

---

## Integration with Feature Development Process

**Step 0: Standards Review** → Read this User Story Standards doc

**Step 1: Requirements** ← **YOU START HERE**
1. Write user story using format above
2. Define acceptance criteria (checklist format)
3. Identify edge cases and error scenarios
4. Run through quality checklist
5. Get stakeholder/team approval if needed

**Step 2-8: Design, Implementation, Testing**
- Use acceptance criteria to guide design (wireframe each criterion)
- Each criterion becomes at least one test case
- Manual testing verifies each checkbox

**Step 9: Mark Complete**
- ✅ Verify **ALL** acceptance criteria met
- ✅ Every checkbox checked and working
- ✅ No open bugs or blockers
- ✅ Update plan status to "✔️ Complete"
- ✅ Update actual effort in plan metadata

See `docs/feature-development-process.md` for full workflow.

---

## Common Mistakes to Avoid

### 1. Technical Implementation as User Story
- ❌ "Implement Redux store for conversations"
- ✅ "View list of past conversations"
- **Fix:** Focus on user outcome, not how it's built

### 2. Missing Edge Cases
- ❌ Only testing happy path
- ✅ Test validation errors, network failures, empty states
- **Fix:** Always ask "What could go wrong?"

### 3. No Definition of Done
- ❌ "System should be fast"
- ✅ "Search results display within 500ms"
- **Fix:** Make criteria specific and measurable

### 4. Too Many Features in One Story
- ❌ "View, edit, delete, filter, export, and analyze conversations"
- ✅ Split into 6 separate stories
- **Fix:** If you use "and" multiple times, split it

### 5. Developer-Centric Language
- ❌ "As a system, I want to cache API responses"
- ✅ "As a client admin, I want fast page loads when revisiting the conversations page"
- **Fix:** Always write from user perspective, describe value not implementation

---

## Related Documents

- **Feature Development Process:** See `docs/feature-development-process.md`
- **Testing Patterns:** See `docs/testing-patterns.md`
- **Coding Standards:** See `docs/coding-standards.md`
