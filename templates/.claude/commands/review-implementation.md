---
description: Review completed implementation (Phase 4.5 - MANDATORY before commit)
---

# IMPLEMENTATION REVIEW

You are performing a comprehensive review of a completed implementation to ensure it matches the user story, implementation plan, and all project standards.

**⚠️ THIS STEP IS MANDATORY - Use specialized agent for thorough code review**

## USE SPECIALIZED AGENT

**IMPORTANT:** This code review task should be delegated to a specialized agent for comprehensive validation:

```markdown
Use the Task tool with:
- subagent_type: "qa-automation-engineer" (for test validation and code review)
- OR subagent_type: "backend-api-engineer" (for API layer review)
- OR subagent_type: "frontend-spa-engineer" (for component review)
- OR subagent_type: "security-privacy-engineer" (for security/RLS review)

The agent will:
1. Read the user story and implementation plan
2. Review all implemented code
3. Validate against acceptance criteria
4. Check standards compliance
5. Run tests and build
6. Return comprehensive review report with issues
```

**If no specialized agent available, proceed with direct review but note limitations.**

## CRITICAL RULES

❌ **DO NOT approve implementation with failing tests**
❌ **DO NOT skip any validation step**
❌ **DO NOT commit code without implementation review**
❌ **DO NOT assume - READ and VERIFY actual code**
✅ **ALWAYS use specialized agent when available**
✅ **ALWAYS check against user story acceptance criteria**
✅ **ALWAYS validate against the implementation plan**
✅ **ALWAYS verify all standards were followed**
✅ **ALWAYS run tests and build**

---

## When to Use This Command

**⚠️ MANDATORY STEP:** This command MUST be run after implementation and BEFORE creating the commit.

**Required usage:**
1. **After Phase 4 implementation** - MANDATORY validation before commit (this is the primary use case)

**This is a quality gate - no code should be committed without passing this review.**

**Additional usage:**
2. **Before marking feature complete** - Ensure everything is done correctly
3. **After fixing issues** - Re-validate after addressing review feedback
4. **Final quality check** - Verify all requirements met

**The `/start-implementation` command will remind you to run this review before commit.**

---

## Step 1: Locate User Story and Plan

**Find the user story and implementation plan:**

1. Ask user for user story ID (e.g., "US-003")
2. Read user story from `docs/features/us-XXX-*.md`
3. Read implementation plan from `docs/plans/us-XXX-plan.md`
4. Extract:
   - All acceptance criteria from user story
   - Implementation checklist from plan
   - Database changes from plan
   - API functions from plan
   - Component list from plan
   - Type definitions from plan

**Create validation checklist:**
```markdown
## Acceptance Criteria to Verify
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Edge case 1
- [ ] Edge case 2

## Implementation Checklist Items
- [ ] Migration created
- [ ] API functions implemented
- [ ] Components created
- [ ] Tests written
```

---

## Step 2: Validate Database Implementation

**Check that database changes were implemented correctly:**

1. **Find migration files:**
   ```bash
   # Look for migrations matching the plan
   Glob: "supabase/migrations/*.sql"
   Glob: "migrations/*.sql"
   Glob: "db/migrations/*.sql"

   # Read the most recent migrations
   ```

2. **Verify migrations match plan:**
   - ✅ **Tables created:** Check tables from plan Section 3 exist in migrations
   - ✅ **Column definitions:** Match plan exactly (names, types, constraints)
   - ✅ **Indexes created:** All indexes from plan are in migrations
   - ✅ **RLS policies:** All policies from plan are implemented
   - ✅ **Foreign keys:** Relationships match plan
   - ✅ **Migration naming:** Follows project convention
   - ✅ **Migration tested:** Ask if migration was run successfully

**Example validation:**
```markdown
## Database Validation

Plan specified (Section 3):
- Table: `conversations` with 8 columns
- Index: `idx_conversations_client_id`
- RLS: "Users can only access their client's conversations"

Implementation found:
✅ Migration: `20250327_create_conversations_table.sql`
✅ Table `conversations` created with all 8 columns
✅ Column types match plan exactly
✅ Index `idx_conversations_client_id` created
✅ RLS policy matches plan specification
❌ Missing `updated_at` column mentioned in plan
❌ RLS policy doesn't use tenant_id from auth context

**Issues to fix before commit:**
1. Add `updated_at` column to migration
2. Update RLS policy to use correct auth context
```

---

## Step 3: Validate API Layer Implementation

**Check that API functions were implemented:**

1. **Find API module:**
   ```bash
   # Plan specified: src/api/conversations.ts
   Read: "src/api/conversations.ts"
   ```

2. **Verify API functions match plan:**
   - ✅ **All functions exist:** Check each function from plan Section 4
   - ✅ **Function signatures:** Parameters and return types match plan
   - ✅ **Type definitions:** Interfaces match plan exactly
   - ✅ **Error handling:** try/catch blocks present
   - ✅ **Database queries:** Use correct table and columns
   - ✅ **RLS compliance:** Queries respect row-level security
   - ✅ **JSDoc comments:** Functions documented as per standards

**Example validation:**
```markdown
## API Layer Validation

Plan specified (Section 4):
- `getConversationById(id: string): Promise<Conversation | null>`
- `getAllConversations(): Promise<Conversation[]>`
- `createConversation(data: ConversationFormData): Promise<Conversation>`
- `updateConversation(id: string, updates: Partial<ConversationFormData>): Promise<Conversation>`
- `deleteConversation(id: string): Promise<void>`

Implementation review:
✅ All 5 functions implemented in `src/api/conversations.ts`
✅ Function signatures match plan exactly
✅ Type definitions match plan
✅ Error handling with try/catch blocks
❌ Missing JSDoc comments on functions
❌ `getAllConversations()` doesn't accept filter parameters mentioned in plan
✅ Database queries use correct table name

**Issues to fix:**
1. Add JSDoc comments to all functions
2. Add filter parameters to `getAllConversations(filters?: ConversationFilters)`
```

---

## Step 4: Validate Type Definitions

**Check that types match plan and database:**

1. **Find type definitions:**
   ```bash
   # Check if types are in API file or separate type file
   Read: API file for interfaces
   Read: Type files if separate
   ```

2. **Verify types match:**
   - ✅ **Database types:** Interface properties match database columns
   - ✅ **Plan types:** Match type definitions from plan Section 4
   - ✅ **Naming:** camelCase properties, PascalCase interfaces
   - ✅ **Optional fields:** Nullable columns = optional properties
   - ✅ **Enum types:** Match database CHECK constraints
   - ✅ **Consistent types:** Same types used throughout codebase

**Example validation:**
```markdown
## Type Definition Validation

Plan specified:
```typescript
interface Conversation {
  id: string
  clientId: string
  type: 'voice' | 'sms'
  customerName: string
  createdAt: string
}
```

Database schema:
- `client_id` UUID NOT NULL
- `type` TEXT CHECK (type IN ('voice', 'sms'))
- `customer_name` TEXT NOT NULL
- `created_at` TIMESTAMPTZ

Implementation:
✅ Interface `Conversation` exists
✅ Property names use camelCase (`clientId`, `customerName`)
✅ `type` is enum: `'voice' | 'sms'`
✅ `clientId` is required (NOT NULL in DB)
❌ Missing `updatedAt` field (database has `updated_at`)
✅ Types are consistent with database

**Issues to fix:**
1. Add `updatedAt?: string` to interface (optional because may be null)
```

---

## Step 5: Validate Component Implementation

**Check that components were built correctly:**

1. **Find components:**
   ```bash
   # From plan Section 5
   Read: "src/pages/ConversationsPage.tsx"
   Read: "src/components/ConversationList.tsx"
   Read: "src/components/ConversationCard.tsx"
   Read: "src/components/ConversationForm.tsx"
   ```

2. **Verify components match plan:**
   - ✅ **All components exist:** Check each from plan Section 5
   - ✅ **Component structure:** Follows project patterns
   - ✅ **Props interfaces:** Match plan specifications
   - ✅ **State management:** Uses approach from plan (Redux/Context/etc)
   - ✅ **Data fetching:** Uses API functions correctly
   - ✅ **Loading states:** Shows loading indicator
   - ✅ **Error states:** Shows error messages with retry
   - ✅ **Empty states:** Shows helpful empty state
   - ✅ **Form validation:** Uses validation library from plan
   - ✅ **Accessibility:** ARIA labels, keyboard navigation

**Example validation:**
```markdown
## Component Implementation

Plan specified (Section 5):
- ConversationsPage (main page component)
- ConversationList (displays array)
- ConversationCard (individual item)
- ConversationForm (create/edit form)

Implementation review:
✅ All 4 components created in correct locations
✅ Component structure follows project patterns
✅ Props interfaces match plan
✅ Uses RTK Query for data fetching
✅ Loading state implemented with spinner
✅ Error state with retry button
✅ Empty state with helpful message
❌ Form validation missing (plan specified Zod)
❌ Missing ARIA labels on form inputs
❌ Keyboard navigation incomplete (no Escape key handler)

**Issues to fix:**
1. Add Zod validation schema to ConversationForm
2. Add ARIA labels: aria-label, aria-required, aria-invalid
3. Add Escape key handler to close modal/form
```

---

## Step 6: Validate Standards Compliance

**Check code follows all project standards:**

1. **Read standards documents:**
   ```bash
   Read: "docs/coding-standards.md"
   Read: "docs/component-patterns.md"
   Read: "docs/api-patterns.md"
   Read: "docs/database-patterns.md"
   Read: "docs/testing-patterns.md"
   ```

2. **Verify standards followed:**
   - ✅ **Naming conventions:** Functions, variables, files follow standards
   - ✅ **Import order:** Imports organized per coding-standards.md
   - ✅ **Error handling:** Consistent with error-handling-patterns.md
   - ✅ **Component structure:** Follows component-patterns.md
   - ✅ **API patterns:** Follows api-patterns.md
   - ✅ **Database patterns:** Follows database-patterns.md
   - ✅ **Async patterns:** Follows async-patterns.md
   - ✅ **Performance:** Follows performance-patterns.md (memo, useMemo)
   - ✅ **Logging:** Follows logging-patterns.md

**Example validation:**
```markdown
## Standards Compliance

From `docs/coding-standards.md`:
✅ Functions use async/await (not .then())
✅ Files use kebab-case naming
❌ Import order incorrect (React imports should be first)
✅ No `any` types used

From `docs/component-patterns.md`:
✅ Components structured: state → hooks → handlers → render
❌ Missing React.memo on ConversationCard (list item optimization)
✅ Custom hooks extracted properly

From `docs/api-patterns.md`:
✅ API functions return typed Promises
✅ Error messages are user-friendly
❌ Missing error logging with correlation IDs

**Issues to fix:**
1. Reorder imports: React first, then external, then internal
2. Wrap ConversationCard in React.memo
3. Add error logging: `logger.error('Failed to fetch', { correlationId, error })`
```

---

## Step 7: Validate User Story Acceptance Criteria

**Check that ALL acceptance criteria are met:**

1. **Map criteria to implementation:**
   ```markdown
   User Story Acceptance Criteria:

   ✅ "User can view list of conversations"
      → Verified: ConversationList component renders array

   ✅ "Loading spinner shown while fetching"
      → Verified: LoadingSpinner component rendered when isLoading=true

   ✅ "Error message shown if API fails"
      → Verified: ErrorMessage component with retry button

   ❌ "Filter by type (voice/sms)"
      → NOT IMPLEMENTED: No filter UI found in components

   ✅ "Search by customer name"
      → Verified: Search input in ConversationList filters results

   ✅ "Pagination (50 per page)"
      → Verified: Pagination component with 50 per page

   ❌ "Keyboard navigation works"
      → PARTIAL: Tab works but missing Escape and Enter handlers

   ✅ "Empty state shown if no conversations"
      → Verified: EmptyState component with helpful message
   ```

2. **Check edge cases from user story:**
   - All edge cases handled?
   - Loading states covered?
   - Error scenarios handled?
   - Boundary conditions tested?

**Example:**
```markdown
## Acceptance Criteria Review

**Met Criteria (6/8):**
✅ View list
✅ Loading spinner
✅ Error handling
✅ Search
✅ Pagination
✅ Empty state

**Missing Criteria (2/8):**
❌ Filter by type (voice/sms) - NO FILTER UI
❌ Keyboard navigation - INCOMPLETE

**Edge Cases:**
✅ Handles long customer names (truncates)
✅ Handles missing data (shows "Unknown")
❌ Network timeout not handled (plan specified 30s timeout)

**Issues to fix:**
1. Add type filter dropdown with "All", "Voice", "SMS" options
2. Complete keyboard navigation (Escape, Enter keys)
3. Add 30-second timeout to API calls
```

---

## Step 8: Validate Tests

**Check that comprehensive tests were written:**

1. **Find test files:**
   ```bash
   # Look for test files
   Glob: "**/*.test.ts"
   Glob: "**/*.test.tsx"
   Glob: "**/*.spec.ts"

   # Read test files related to feature
   ```

2. **Verify test coverage:**
   - ✅ **Unit tests:** API functions tested
   - ✅ **Component tests:** Components render correctly
   - ✅ **Integration tests:** API + database tested
   - ✅ **Edge cases:** Error scenarios tested
   - ✅ **User flows:** Happy path tested end-to-end
   - ✅ **Accessibility:** Keyboard nav, screen reader tested

3. **Run tests:**
   ```bash
   # Run test suite
   Bash: npm test
   Bash: npm run test:coverage
   ```

**Example validation:**
```markdown
## Test Coverage

Plan specified (Section 8):
- Unit tests for all API functions
- Component tests for all 4 components
- Integration test for API + database
- Accessibility tests

Implementation:
✅ Unit tests: 5 tests for API functions (100% coverage)
✅ Component tests: ConversationList.test.tsx (12 tests)
❌ Missing: ConversationCard.test.tsx
❌ Missing: ConversationForm.test.tsx
✅ Integration test: conversations-api.integration.test.ts
❌ Missing: Accessibility tests (keyboard nav, screen reader)

**Test Results:**
✅ All existing tests pass
❌ Coverage: 68% (target: 80%)

**Issues to fix:**
1. Add ConversationCard component tests
2. Add ConversationForm component tests (especially validation)
3. Add accessibility tests using @testing-library/jest-dom
4. Aim for 80%+ coverage
```

---

## Step 9: Run Build and Quality Checks

**Verify build succeeds and quality tools pass:**

1. **Run TypeScript type check:**
   ```bash
   Bash: npm run type-check
   # or
   Bash: tsc --noEmit
   ```

2. **Run linter:**
   ```bash
   Bash: npm run lint
   # or
   Bash: eslint src/
   ```

3. **Run build:**
   ```bash
   Bash: npm run build
   ```

4. **Check for console errors:**
   - Any TypeScript errors?
   - Any ESLint errors or warnings?
   - Build warnings or errors?

**Example validation:**
```markdown
## Build & Quality Checks

✅ TypeScript: No type errors
❌ ESLint: 3 warnings found
   - `src/api/conversations.ts:45` - Unused variable 'error'
   - `src/components/ConversationCard.tsx:23` - Missing key prop in list
   - `src/components/ConversationForm.tsx:67` - useEffect missing dependency
✅ Build: Successful (no errors)
❌ Build warnings: 1 warning
   - Large bundle size (1.2MB vs 800KB target)

**Issues to fix:**
1. Remove unused 'error' variable
2. Add key prop to list items
3. Add missing dependency to useEffect deps array
4. Investigate bundle size (check for large imports)
```

---

## Step 10: Manual Testing Checklist

**Verify feature works correctly in browser:**

**Ask user to confirm they've tested:**

```markdown
## Manual Testing Checklist

**Happy Path:**
- [ ] User can view list of conversations
- [ ] User can create new conversation
- [ ] Form validation works correctly
- [ ] User can edit existing conversation
- [ ] User can delete conversation (with confirmation)
- [ ] Success messages display
- [ ] Data persists after page refresh

**Error Cases:**
- [ ] Network failure shows error with retry
- [ ] Invalid form shows validation errors
- [ ] API errors show user-friendly messages
- [ ] Delete confirmation prevents accidents

**Edge Cases:**
- [ ] Empty state displays when no data
- [ ] Loading state shows during operations
- [ ] Large dataset (50+ items) handles well
- [ ] Concurrent operations don't break state
- [ ] Browser back/forward work correctly

**Accessibility:**
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Focus states visible
- [ ] Screen reader announces changes
- [ ] Color contrast meets WCAG

**Responsive:**
- [ ] Desktop (1920x1080)
- [ ] Tablet (768x1024)
- [ ] Mobile (375x667)

**Browsers:**
- [ ] Chrome
- [ ] Safari
- [ ] Mobile Safari
- [ ] Mobile Chrome
```

**If user hasn't tested, remind them to do so before approving.**

---

## Step 11: Present Review Results

**Show comprehensive review summary:**

```markdown
# 📋 Implementation Review: [Feature Name]

**User Story:** US-XXX - [Name]
**Implementation Plan:** docs/plans/us-XXX-plan.md
**Review Date:** 2025-MM-DD

---

## Review Summary

### ✅ Passed Checks (X/10)

1. ✅ **Database:** Migrations match plan, all tables/indexes created
2. ✅ **API Layer:** All 5 functions implemented with correct signatures
3. ✅ **Type Definitions:** Types match database and plan
4. ✅ **Components:** All 4 components created and functional
5. ⚠️ **Standards Compliance:** Mostly followed, minor issues
6. ⚠️ **Acceptance Criteria:** 6/8 met, 2 missing
7. ⚠️ **Tests:** Unit tests good, missing component tests
8. ✅ **Build:** TypeScript and build successful
9. ❌ **Quality Checks:** 3 ESLint warnings
10. ❓ **Manual Testing:** Pending user confirmation

---

## ❌ Issues Found (MUST FIX BEFORE COMMIT)

### Critical Issues (Block Commit)

**Missing Acceptance Criteria (2):**
1. ❌ **Filter by type:** No filter UI for voice/sms filtering
2. ❌ **Keyboard navigation:** Missing Escape/Enter key handlers

**Missing Tests (2):**
3. ❌ **ConversationCard tests:** No test file exists
4. ❌ **ConversationForm tests:** No test file exists

### High Priority Issues

**Standards Compliance (4):**
5. ⚠️ **Import order:** React imports not first (coding-standards.md)
6. ⚠️ **React.memo:** Missing on ConversationCard (performance)
7. ⚠️ **Error logging:** Missing correlation IDs (logging-patterns.md)
8. ⚠️ **Form validation:** Not using Zod as specified in plan

**Code Quality (3):**
9. ⚠️ **ESLint warning:** Unused variable 'error'
10. ⚠️ **ESLint warning:** Missing key prop in list
11. ⚠️ **ESLint warning:** useEffect missing dependency

### Medium Priority Issues

**Accessibility (2):**
12. ⚠️ **ARIA labels:** Missing on form inputs
13. ⚠️ **Accessibility tests:** None written

**Edge Cases (1):**
14. ⚠️ **Network timeout:** Not handling 30s timeout from plan

---

## 🔧 Recommended Fixes

### Before Commit (Critical)

```typescript
// 1. Add filter by type
<select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)}>
  <option value="all">All</option>
  <option value="voice">Voice</option>
  <option value="sms">SMS</option>
</select>

// 2. Add keyboard navigation
useEffect(() => {
  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Escape') closeForm();
    if (e.key === 'Enter' && e.metaKey) submitForm();
  };
  window.addEventListener('keydown', handleKeyDown);
  return () => window.removeEventListener('keydown', handleKeyDown);
}, []);

// 3. Create test files
// ConversationCard.test.tsx
// ConversationForm.test.tsx
```

### Before Next Feature (High Priority)

```typescript
// 4. Fix import order
import React from 'react'; // First
import { useQuery } from '@tanstack/react-query'; // External
import { Button } from '@/components'; // Internal

// 5. Add React.memo
export const ConversationCard = React.memo(({ conversation }) => {
  // ...
});

// 6. Add Zod validation
const conversationSchema = z.object({
  customerName: z.string().min(1),
  type: z.enum(['voice', 'sms'])
});
```

---

## 📊 Statistics

**Code Quality:**
- TypeScript: ✅ 0 errors
- ESLint: ⚠️ 3 warnings
- Build: ✅ Success
- Bundle size: ⚠️ 1.2MB (target: 800KB)

**Test Coverage:**
- Unit tests: ✅ 100% (5/5 API functions)
- Component tests: ❌ 50% (2/4 components)
- Integration tests: ✅ 100% (1/1)
- Overall: ⚠️ 68% (target: 80%)

**Acceptance Criteria:**
- Met: 6/8 (75%)
- Missing: 2/8 (25%)

**Implementation Completeness:**
- Database: ✅ 100%
- API Layer: ✅ 100%
- Components: ⚠️ 90% (minor issues)
- Tests: ⚠️ 70%
- Documentation: ✅ 100%

---

## 🚦 Recommendation

**Status: ⚠️ NOT READY FOR COMMIT**

**Critical blockers (MUST FIX):**
1. Add filter by type UI
2. Complete keyboard navigation
3. Add ConversationCard tests
4. Add ConversationForm tests

**Estimated fix time:** 2-3 hours

**After fixing, please:**
1. Run `/review-implementation` again to re-validate
2. Confirm all manual tests pass
3. Then proceed with commit

---

## Next Steps

**If all issues are fixed:**
1. ✅ Update plan status to "Complete"
2. ✅ Update user story status to "Complete"
3. ✅ Update actual effort in plan metadata
4. ✅ Create commit with user story reference
5. ✅ Update high-level-user-stories.md with commit hash

**If issues remain:**
1. Fix critical blockers listed above
2. Run `/review-implementation` again
3. Verify all checks pass
4. Then proceed with commit
```

---

## Important Notes

1. **Don't commit with failing tests** - All tests must pass
2. **Don't skip acceptance criteria** - Every criterion must be met
3. **Don't ignore standards** - Follow all project conventions
4. **Manual testing required** - Feature must work in browser
5. **Re-run after fixes** - Validate again after fixing issues

---

**This review ensures the implementation is complete, correct, and ready for commit.**
