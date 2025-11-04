# Feature Development Process

This document defines the Standard Operating Procedure (SOP) for **EVERY** feature implementation in the TaadaB Logistics platform.

## Overview

Follow these steps sequentially for all feature development. This process ensures consistency, quality, and maintainability across the codebase.

---

## Step 0: Standards Review (MANDATORY)

**BEFORE writing any code:**

1. ✅ Read all relevant standards documents in `/docs/`:
   - `docs/coding-standards.md` (ALWAYS)
   - `docs/component-patterns.md` (for React components)
   - `docs/state-management-patterns.md` (for Redux/state)
   - `docs/styling-patterns.md` (for Tailwind CSS)
   - `docs/api-patterns.md` (for API endpoints)
   - `docs/database-patterns.md` (for database/RLS)
   - `docs/testing-patterns.md` (for tests)
2. ✅ If standards don't exist for a pattern, CREATE them first
3. ✅ Review existing similar features for established patterns
4. ✅ Ensure you understand and will follow all conventions

---

## Step 1: Requirements

**Write clear, testable requirements:**

- ✅ Write user story using standard format (see `docs/user-story-standards.md`)
- ✅ Save user story file to `/docs/features/us-XXX-<name>.md`
  - **Note:** Use lowercase `us-xxx` for filenames, uppercase `US-XXX` for display/tables
  - See [User Story ID Conventions](user-story-standards.md#user-story-id-conventions) for details
- ✅ Add entry to `docs/high-level-user-stories.md` tracking table
- ✅ Define acceptance criteria (checklist format preferred)
- ✅ Identify edge cases (validation, errors, empty states)
- ✅ Define success metrics (if applicable)
- ✅ Create implementation plan (see Step 2a below)

**Example User Story:**
```
As a client admin,
I want to view a list of all AI conversations,
So that I can review customer interactions and identify issues.

Acceptance Criteria:
- [ ] Conversations load from API with client_id filter
- [ ] List shows customer name, phone, type (voice/sms), date
- [ ] Loading spinner shown while fetching
- [ ] Error message shown if API fails with retry button
- [ ] Empty state shown if no conversations
- [ ] Filter by type (voice/sms)
- [ ] Search by customer name or phone
- [ ] Pagination for large lists (50 per page)
```

---

## Step 2a: Discovery & Planning (STREAMLINED WORKFLOW)

**Use the streamlined 3-phase workflow for feature implementation:**

### Phase 1: Discovery (`/discovery`)

Run `/discovery` to conduct requirements gathering and architecture review:
- Explores current app state (database, API, components)
- Reads user story documentation
- Asks informed clarifying questions
- Reviews project standards
- Identifies reusable code
- Presents discovery summary

### Phase 2: Plan & Validate (`/plan-and-validate`)

Run `/plan-and-validate` to create and validate implementation plan:
- Creates comprehensive 10-section plan
- **Automatically validates** against codebase and standards
- Auto-fixes issues found (types, database schema, file paths, etc.)
- Saves plan to `/docs/plans/us-XXX-plan.md`
- Presents validated plan for approval

**Plan includes:**
- Requirements summary
- Technical approach
- Database changes
- API layer design
- Component architecture
- State management strategy
- Edge cases and error handling
- Testing strategy
- Implementation checklist (becomes TodoWrite items)
- Effort estimates and risks

**Why This Workflow?**
- **Eliminates duplication:** Reusable helper commands
- **Mandatory validation:** Can't skip plan review
- **Faster:** 3 phases instead of 4
- **Consistent:** Same exploration logic everywhere
- **Quality assurance:** Auto-validation catches issues before coding

### Phase 3: Implementation (`/start-implementation`)

Run `/start-implementation` to begin coding (see Step 4 below)

### Quick Start

```bash
# Option 1: Use orchestrator (runs all phases)
/implement

# Option 2: Run phases manually
/discovery
# [review discovery summary]
/next  # or /plan-and-validate

# [review validated plan, approve it]
/next  # or /start-implementation

# Option 3: Legacy workflow (still supported)
# Individual commands still exist for granular control
```

**After Approval:**
- ✅ Update plan status to "✅ Approved" in:
  - `docs/plans/us-XXX-plan.md` metadata
  - `docs/features/us-XXX-*.md` plan metadata section
  - `docs/high-level-user-stories.md` tracking table

---

## Step 2b: Design

**Create design artifacts BEFORE implementation:**

- ✅ **Wireframes:** Sketch UI layout (Figma, pen & paper, or detailed description)
- ✅ **Sequence Diagrams:** Map out API calls, state changes, user flow
- ✅ **Data Models:** Define types/interfaces for all data structures
- ✅ Document design decisions in `/docs/decisions.md` (ADRs) if architectural

**Example Data Model:**
```typescript
interface Conversation {
  id: string;
  client_id: string;
  agent_id: string;
  type: 'voice' | 'sms';
  customer_name: string;
  customer_phone: string;
  transcript: string;
  audio_url?: string;
  duration?: number;
  sentiment?: string;
  created_at: string;
}
```

---

## Step 3: Backend/Database/Schema Changes

**If feature requires backend or database changes:**

1. ✅ Create database migration if schema changes needed
   ```bash
   cd supabase
   supabase migration new add_conversations_table
   ```
2. ✅ Define RLS policies for multi-tenant isolation
3. ✅ Implement API endpoints following `docs/api-patterns.md`
4. ✅ Test RLS policies with non-admin users
5. ✅ Write API tests (unit + integration)

**Example Migration:**
```sql
-- Migration: 20240101_create_conversations_table
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES clients(id),
  agent_id UUID REFERENCES agents(id),
  type TEXT NOT NULL CHECK (type IN ('voice', 'sms')),
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  transcript TEXT,
  audio_url TEXT,
  duration INTEGER,
  sentiment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their client's conversations"
ON conversations FOR ALL
USING (client_id = auth.jwt() ->> 'client_id');
```

---

## Step 4: Implementation

**Build the feature following standards:**

- ✅ Follow `docs/coding-standards.md` for naming and structure
- ✅ Follow `docs/component-patterns.md` for React components
- ✅ Follow `docs/state-management-patterns.md` for Redux/state
- ✅ Follow `docs/styling-patterns.md` for Tailwind CSS
- ✅ Implement component structure (state, hooks, effects, handlers, render)
- ✅ Use TypeScript strict mode (no `any`, no `ts-ignore`)

**Example Component:**
```typescript
// ConversationList.tsx
export function ConversationList({ clientId }: Props) {
  // State
  const [filters, setFilters] = useState<Filters>({});

  // RTK Query
  const { data, isLoading, error, refetch } = useGetConversationsQuery({ clientId, filters });

  // Early returns
  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} onRetry={refetch} />;
  if (!data || data.length === 0) return <EmptyState />;

  // Main render
  return <div>{/* List */}</div>;
}
```

---

## Step 5: Complete Implementation

**Handle all edge cases and states:**

- ✅ Loading states (spinners, skeletons)
- ✅ Error states (friendly messages, retry buttons)
- ✅ Empty states (helpful messaging, CTAs)
- ✅ Success states (confirmation messages)
- ✅ Form validation (client-side + server-side)
- ✅ Optimistic updates (for mutations)
- ✅ Accessibility (ARIA labels, keyboard navigation, focus states)

---

## Step 6: Tests

**Write comprehensive tests following `docs/testing-patterns.md`:**

### Unit Tests
- ✅ Test Redux slices (reducers, actions, selectors)
- ✅ Test utility functions
- ✅ Test custom hooks
- **Target: 80%+ coverage for critical business logic**

### Integration Tests
- ✅ Test API endpoints with database
- ✅ Test RLS policies with different user contexts
- ✅ Test full user flows (login → action → result)
- **Target: 75%+ coverage for API routes**

### Component Tests
- ✅ Test component rendering (loading, error, success states)
- ✅ Test user interactions (clicks, form submissions)
- ✅ Test accessibility (screen reader, keyboard navigation)
- **Target: 70%+ coverage for critical UI components**

**Example Test:**
```typescript
describe('ConversationList', () => {
  it('renders loading state initially', () => {
    render(<ConversationList clientId="client-123" />);
    expect(screen.getByRole('status')).toBeInTheDocument();
  });

  it('displays conversations after loading', async () => {
    render(<ConversationList clientId="client-123" />);
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });
  });

  it('shows error message on API failure', async () => {
    mockApiFailure();
    render(<ConversationList clientId="client-123" />);
    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });
});
```

---

## Step 7: Documentation

**Update documentation:**

- ✅ Add JSDoc comments to functions/components
- ✅ Update API documentation (OpenAPI/Swagger) if API changed
- ✅ Create/update Architecture Decision Records (ADRs) in `/docs/decisions.md` if architectural change
- ✅ Update standards documents if new patterns established
- ✅ Add inline comments for complex logic

---

## Step 8: Review

**Run quality checklist:**

- ✅ TypeScript strict mode passes (no `any`, no `ts-ignore`)
- ✅ ESLint/Pylint passes (no errors)
- ✅ Prettier/Black formatting applied
- ✅ All tests pass (unit, integration, component)
- ✅ Coverage targets met (see Step 6)
- ✅ Build succeeds (`npm run build` or `make build`)
- ✅ Manual testing completed in browser/Postman
- ✅ Accessibility check (keyboard navigation, screen reader)
- ✅ Responsive design check (mobile, tablet, desktop)
- ✅ RLS policies tested with non-admin users (if database changes)

---

## Step 9: Mark Feature as Completed

**ONLY mark complete after ALL quality gates pass:**

1. ✅ Create or update feature file in `/docs/features/<feature-name>.md`
2. ✅ Mark all completed user stories/tasks with ✅ checkbox
3. ✅ Add completion status and date:
   ```markdown
   ## Status
   ✅ **Completed** (2025-10-23)

   ## Implementation Notes
   - Used RTK Query for conversation fetching with 30s polling
   - Implemented optimistic updates for delete action
   - Added pagination with 50 items per page
   ```
4. ✅ **Update implementation plan status:**
   - Update `docs/plans/us-XXX-plan.md` metadata:
     - Status: "Complete"
     - Actual Effort: X days
   - Update `docs/features/us-XXX-*.md` plan metadata:
     - Plan Status: "✔️ Complete"
     - Actual Effort: X days
   - Update `docs/high-level-user-stories.md` tracking table:
     - Plan Status: "✔️ Complete"
     - Status: "✅ Complete"
     - Commit: (will be added in Step 10)
5. ✅ Update feature status in project tracker (if applicable)

**Only mark as completed if:**
- ✅ All acceptance criteria met
- ✅ All quality gates passed (tests, typecheck, lint, build)
- ✅ Feature manually tested and working as expected
- ✅ No known bugs or blockers
- ✅ Documentation updated

---

## Step 10: Commit

**Create Git commit following conventions (see `docs/git-workflow.md`):**

1. ✅ Stage changes: `git add <files>`
2. ✅ Write commit message following Conventional Commits **with user story reference**:
   ```bash
   git commit -m "feat: add conversation list with filtering

   - Implement ConversationList component with RTK Query
   - Add filters for type (voice/sms) and search
   - Handle loading, error, and empty states
   - Add pagination (50 per page)
   - Tests: 85% coverage

   Implements: docs/features/us-013-conversation-log-list.md

    

   
   ```
3. ✅ Pre-commit hooks run automatically (lint, format, tests)
4. ✅ Push to feature branch: `git push origin feature/conversation-list`
5. ✅ Create Pull Request with description linking to user story
6. ✅ **Update** `docs/high-level-user-stories.md` with commit hash:
   ```markdown
   | US-013 | Conversation List | [Link](features/us-013-conversation-log-list.md) | [Link](plans/us-013-plan.md) | ✔️ Complete | ✅ Complete | abc1234 |
   ```

**Commit Format Requirements:**
- Use Conventional Commits type (feat, fix, refactor, etc.)
- **REQUIRED:** Include `Implements: docs/features/us-XXX-<story-name>.md` for user story commits
- Use exact filename from `/docs/features/`
- Place before Claude Code footer
- For multiple stories, list all files

**Commit Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring (no functional change)
- `test:` - Add or update tests
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks (dependencies, config)
- `style:` - Code style changes (formatting)
- `perf:` - Performance improvements

**Why This Matters:**
- Provides traceability between code changes and requirements
- Makes code review easier (reviewers can check against acceptance criteria)
- Required for updating `docs/high-level-user-stories.md`

**Merge Strategy:** Squash and merge (keeps main branch clean)

---

## Quality Gates Checklist

Before marking any feature as complete, verify:

- ✅ All acceptance criteria met (from user story)
- ✅ Unit tests written (>80% coverage for critical paths)
- ✅ Integration tests pass (API + database)
- ✅ RLS policies tested with non-admin users
- ✅ No secrets or credentials in code
- ✅ API documented (OpenAPI/Swagger)
- ✅ Error handling implemented (graceful degradation)
- ✅ Logging added (structured logs with context)
- ✅ Manual testing completed
- ✅ Code reviewed (or self-reviewed thoroughly)

---

## Related Documents

- **User Story Standards:** See `docs/user-story-standards.md`
- **Git Workflow:** See `docs/git-workflow.md`
- **Coding Standards:** See `docs/coding-standards.md`
- **Testing Patterns:** See `docs/testing-patterns.md`
