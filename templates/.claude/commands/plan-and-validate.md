---
description: Create and validate implementation plan (Phase 3+3.5)
---

# PLAN & VALIDATE: Implementation Planning

You are creating a comprehensive implementation plan and automatically validating it before user approval. This combines planning (Phase 3) and validation (Phase 3.5) into a streamlined process.

## CRITICAL RULES

❌ **DO NOT start implementation before approval**
❌ **DO NOT skip validation - MANDATORY before presenting**
❌ **DO NOT present plan without auto-fixing issues**
✅ **ALWAYS include all 10 plan sections**
✅ **ALWAYS validate against codebase and standards**
✅ **ALWAYS auto-fix issues found**
✅ **ALWAYS add revision history entry**
✅ **ALWAYS save plan file to docs/plans/**

---

## Overview: Plan + Validation

This command combines two steps:

**Step A: Create Comprehensive Plan**
- 10-section implementation plan
- Database, API, component architecture
- Edge cases and testing strategy
- Implementation checklist

**Step B: Validate Plan (MANDATORY)**
- Validate against database schema
- Validate against type definitions
- Validate against standards
- Validate against user story
- Auto-fix all issues found

**Result:** Validated, ready-to-implement plan

---

## STEP A: CREATE IMPLEMENTATION PLAN

### Prerequisites

You should have completed `/discovery` first.

You need:
- Requirements summary
- Architecture summary
- Database exploration results
- Code exploration results
- Standards review

**If you don't have these, run `/discovery` first.**

### Plan File Structure

Create plan at: `docs/plans/us-XXX-plan.md` (or `us-NEW-plan.md` if no story ID yet)

The plan must include these 10 sections:

---

### Section 1: Plan Metadata & Requirements Summary

```markdown
# Implementation Plan: [Feature Name]

## Plan Metadata

- **User Story:** [US-XXX or link to story file]
- **Created:** 2025-MM-DD
- **Last Revised:** 2025-MM-DD
- **Status:** Draft (will become "Approved" after validation and user approval)
- **Estimated Effort:** [X days]

---

## 1. Requirements Summary

**Feature:** [Feature name]
**User Type:** [Customer/Staff/Admin]
**Goal:** [What user wants to achieve]
**Value:** [Why it matters to user]

**Must-Have Features:**
- [ ] Feature 1 - [description]
- [ ] Feature 2 - [description]

**Nice-to-Have Features:**
- [ ] Feature 3 - [description] (if time permits)

**Acceptance Criteria:**
- [ ] Criterion 1 from user story
- [ ] Criterion 2 from user story
- [ ] Criterion 3 from user story
```

---

### Section 2: Technical Approach

```markdown
## 2. Technical Approach

**Architecture Pattern:** [API layer + React components + Supabase RLS / etc.]
**Key Technologies:** [React 19, TypeScript, Supabase, React Hook Form, Zod, etc.]

**Reused Components:**
- `ComponentA` from `src/components/ComponentA.tsx` - [purpose]
- `ComponentB` from `src/components/ComponentB.tsx` - [purpose]

**Reused APIs:**
- `functionA()` from `src/api/module.ts` - [purpose]
- `functionB()` from `src/api/module.ts` - [purpose]

**New Components:**
- `FeaturePage.tsx` - [purpose and responsibility]
- `FeatureList.tsx` - [purpose and responsibility]
- `FeatureForm.tsx` - [purpose and responsibility]

**New APIs:**
- `getFeatureById(id: string): Promise<Feature | null>` - [purpose]
- `getAllFeatures(): Promise<Feature[]>` - [purpose]
- `createFeature(data: FormData): Promise<Feature>` - [purpose]

**Standards to Follow:**
- `docs/coding-standards.md` - [key conventions]
- `docs/database-patterns.md` - [key patterns]
- `docs/api-patterns.md` - [key patterns]
- `docs/component-patterns.md` - [key patterns]
```

---

### Section 3: Database Changes

```markdown
## 3. Database Changes

**New Tables:**

**Table: `table_name`**
```sql
CREATE TABLE table_name (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  column1 TEXT NOT NULL,
  column2 INTEGER,
  column3 TEXT CHECK (column3 IN ('value1', 'value2')),
  foreign_key_id UUID REFERENCES other_table(id)
);

-- Indexes
CREATE INDEX idx_table_name_foreign_key_id ON table_name(foreign_key_id);
CREATE INDEX idx_table_name_column1 ON table_name(column1);

-- RLS Policies
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

CREATE POLICY table_name_select_policy ON table_name
  FOR SELECT
  USING (client_id = (auth.jwt() ->> 'client_id')::uuid);

CREATE POLICY table_name_insert_policy ON table_name
  FOR INSERT
  WITH CHECK (client_id = (auth.jwt() ->> 'client_id')::uuid);
```

**Modified Tables:**
- Table: `existing_table`
  - New columns: `new_column TEXT`
  - New indexes: `idx_existing_table_new_column`

**Migration Files Needed:**
1. `YYYYMMDDHHMMSS_create_feature_tables.sql` - Create new tables
2. `YYYYMMDDHHMMSS_add_feature_rls.sql` - Add RLS policies
3. `YYYYMMDDHHMMSS_add_indexes.sql` - Add performance indexes (if needed)
```

---

### Section 4: API Layer Implementation

```markdown
## 4. API Layer Implementation

**New API Module:** `src/api/feature-name.ts`

**Type Definitions:**
```typescript
/**
 * Feature entity from database
 */
interface Feature {
  id: string
  created_at: string
  updated_at: string
  column1: string
  column2: number
  column3: 'value1' | 'value2'
  foreign_key_id: string
}

/**
 * Form data for creating/updating features
 */
interface FeatureFormData {
  column1: string
  column2: number
  column3: 'value1' | 'value2'
  foreign_key_id: string
}
```

**Functions to Implement:**

1. `getFeatureById(id: string): Promise<Feature | null>`
   - Query: `supabase.from('table_name').select('*').eq('id', id).single()`
   - Returns: Entity or null if not found
   - Error handling: Try/catch, log and throw descriptive error

2. `getAllFeatures(): Promise<Feature[]>`
   - Query: `supabase.from('table_name').select('*').order('created_at', { ascending: false })`
   - Returns: Array (empty if none)
   - Error handling: Try/catch, log and throw descriptive error

3. `createFeature(data: FeatureFormData): Promise<Feature>`
   - Validate input
   - Query: `supabase.from('table_name').insert(data).select().single()`
   - Returns: Created entity
   - Error handling: Try/catch, log and throw descriptive error

4. `updateFeature(id: string, updates: Partial<FeatureFormData>): Promise<Feature>`
   - Check entity exists
   - Query: `supabase.from('table_name').update(updates).eq('id', id).select().single()`
   - Returns: Updated entity
   - Error handling: Try/catch, log and throw descriptive error

5. `deleteFeature(id: string): Promise<void>`
   - Check entity exists
   - Query: `supabase.from('table_name').delete().eq('id', id)`
   - Returns: void
   - Error handling: Try/catch, log and throw descriptive error

**Error Handling Pattern:**
```typescript
try {
  // operation
} catch (error) {
  console.error('Context message:', error)
  throw new Error('User-friendly error message')
}
```
```

---

### Section 5: Component Architecture

```markdown
## 5. Component Architecture

**Component Hierarchy:**
```
FeaturePage (src/pages/FeaturePage.tsx)
├── FeatureList (src/components/FeatureList.tsx)
│   ├── FeatureCard (src/components/FeatureCard.tsx)
│   └── EmptyState (reuse: src/components/EmptyState.tsx)
├── FeatureForm (src/components/FeatureForm.tsx)
├── LoadingSpinner (reuse: src/components/LoadingSpinner.tsx)
└── ErrorMessage (reuse: src/components/ErrorMessage.tsx)
```

**Component Responsibilities:**

1. **FeaturePage** (`src/pages/FeaturePage.tsx`)
   - Fetch data on mount using `getAllFeatures()`
   - Manage page state (features, loading, error, editing)
   - Handle CRUD operations
   - Provide data to child components

2. **FeatureList** (`src/components/FeatureList.tsx`)
   - Receive features array as prop
   - Map to FeatureCard components
   - Show EmptyState when no data
   - Show loading/error states

3. **FeatureCard** (`src/components/FeatureCard.tsx`)
   - Display single feature
   - Edit button (calls onEdit prop)
   - Delete button with confirmation (calls onDelete prop)
   - Styling with Tailwind

4. **FeatureForm** (`src/components/FeatureForm.tsx`)
   - React Hook Form + Zod validation
   - Form fields for all editable properties
   - Submit handler (calls onSubmit prop)
   - Cancel button (calls onCancel prop)
   - Loading state during submission
   - Display validation errors

**Props Interfaces:**
```typescript
interface FeatureListProps {
  features: Feature[]
  onEdit: (feature: Feature) => void
  onDelete: (id: string) => void
  loading: boolean
  error: string | null
}

interface FeatureCardProps {
  feature: Feature
  onEdit: () => void
  onDelete: () => void
}

interface FeatureFormProps {
  initialData?: Feature
  onSubmit: (data: FeatureFormData) => Promise<void>
  onCancel: () => void
}
```
```

---

### Section 6: State Management

```markdown
## 6. State Management

**FeaturePage State:**
```typescript
const [features, setFeatures] = useState<Feature[]>([])
const [loading, setLoading] = useState(true)
const [error, setError] = useState<string | null>(null)
const [editingFeature, setEditingFeature] = useState<Feature | null>(null)
const [showForm, setShowForm] = useState(false)
```

**API Call Flow:**

**On Mount:**
- Set loading = true
- Call getAllFeatures()
- On success: setFeatures(data), setError(null)
- On error: setError(message)
- Finally: setLoading(false)

**On Create:**
- Call createFeature(formData)
- Add to features array: setFeatures([newFeature, ...features])
- Close form: setShowForm(false)
- Show success toast

**On Update:**
- Call updateFeature(id, formData)
- Update in array: setFeatures(features.map(f => f.id === id ? updated : f))
- Close form: setShowForm(false), setEditingFeature(null)
- Show success toast

**On Delete:**
- Show confirmation dialog
- Call deleteFeature(id)
- Remove from array: setFeatures(features.filter(f => f.id !== id))
- Show success toast

**Form Validation (Zod):**
```typescript
const featureSchema = z.object({
  column1: z.string().min(1, 'Required').max(100, 'Too long'),
  column2: z.number().min(0).max(1000),
  column3: z.enum(['value1', 'value2']),
  foreign_key_id: z.string().uuid()
})
```
```

---

### Section 7: Edge Cases & Error Handling

```markdown
## 7. Edge Cases & Error Handling

**Loading States:**
- [ ] Initial page load - Show full-page LoadingSpinner
- [ ] Form submission - Disable button, show inline spinner
- [ ] Delete operation - Show spinner on delete button
- [ ] Background refresh - Optional: subtle indicator

**Error States:**
- [ ] Network error - Show ErrorMessage with retry button
- [ ] Validation error - Show inline field errors from Zod
- [ ] API error (400/500) - Show user-friendly message
- [ ] 404 Not Found - Show "Record not found" message
- [ ] Unauthorized (403) - Show permission error or redirect

**Empty States:**
- [ ] No features exist - Show EmptyState with "Create first feature" CTA
- [ ] Search/filter no results - Show "No results found" message
- [ ] Deleted last item - Show empty state

**Boundary Conditions:**
- [ ] Max length inputs - Validate with Zod, show character count
- [ ] Max items in list - Implement pagination if > 100 items
- [ ] Concurrent updates - Use optimistic updates or refresh
- [ ] Duplicate prevention - Check before creating (if applicable)
- [ ] Required relationships - Validate foreign keys exist

**Network Resilience:**
- [ ] Slow network (3G) - Show loading indicators
- [ ] Offline mode - Show offline banner, queue actions (optional)
- [ ] Timeout handling - Set reasonable timeouts, show retry option
```

---

### Section 8: Testing Strategy

```markdown
## 8. Testing Strategy

**Manual Testing Checklist:**

**Happy Path:**
- [ ] View list of features
- [ ] Create new feature with valid data
- [ ] Form validation works correctly
- [ ] Edit existing feature
- [ ] Delete feature with confirmation
- [ ] Success messages display correctly
- [ ] Data persists after page refresh

**Error Cases:**
- [ ] Network failure shows error message with retry
- [ ] Invalid form data shows validation errors
- [ ] API errors show user-friendly messages
- [ ] Delete confirmation prevents accidental deletion

**Edge Cases:**
- [ ] Empty state displays when no data
- [ ] Loading state displays during fetch
- [ ] Large dataset (50+ items) handles gracefully
- [ ] Concurrent create/update doesn't break state
- [ ] Browser back/forward navigation works

**Accessibility:**
- [ ] Keyboard navigation (Tab, Enter, Escape)
- [ ] Focus states visible
- [ ] Form labels associated with inputs
- [ ] Error messages announced to screen readers
- [ ] Color contrast meets WCAG AA

**Responsive Design:**
- [ ] Desktop (1920x1080)
- [ ] Tablet (768x1024)
- [ ] Mobile (375x667)
- [ ] Touch targets minimum 44x44px

**Build & Lint:**
- [ ] `npm run build` completes without errors
- [ ] `npm run lint` passes
- [ ] `npm run type-check` passes (if available)
```

---

### Section 9: Implementation Checklist

```markdown
## 9. Implementation Checklist

**Phase 1: Database & Migrations**
- [ ] Create migration file: `YYYYMMDDHHMMSS_create_feature_tables.sql`
- [ ] Define table schema with all columns and constraints
- [ ] Add indexes for foreign keys and commonly queried columns
- [ ] Create RLS policies (enable RLS, add policies for SELECT/INSERT/UPDATE/DELETE)
- [ ] Test migration locally: `supabase db reset` or equivalent
- [ ] Verify RLS policies work: test queries as different users

**Phase 2: API Layer**
- [ ] Create file: `src/api/feature-name.ts`
- [ ] Define TypeScript interfaces (Feature, FeatureFormData)
- [ ] Implement `getFeatureById()` with error handling
- [ ] Implement `getAllFeatures()` with error handling
- [ ] Implement `createFeature()` with validation and error handling
- [ ] Implement `updateFeature()` with error handling
- [ ] Implement `deleteFeature()` with error handling
- [ ] Add JSDoc comments to all functions
- [ ] Test functions in browser console

**Phase 3: Core Components**
- [ ] Create file: `src/pages/FeaturePage.tsx`
- [ ] Implement data fetching in useEffect
- [ ] Add loading/error/empty states
- [ ] Create file: `src/components/FeatureList.tsx`
- [ ] Create file: `src/components/FeatureCard.tsx`
- [ ] Wire up delete functionality with confirmation
- [ ] Test components render correctly

**Phase 4: Form & CRUD**
- [ ] Create file: `src/components/FeatureForm.tsx`
- [ ] Set up React Hook Form
- [ ] Define Zod validation schema
- [ ] Create form fields
- [ ] Wire up create flow in FeaturePage
- [ ] Wire up edit flow in FeaturePage
- [ ] Add success/error toast notifications
- [ ] Test all CRUD operations

**Phase 5: Polish & Accessibility**
- [ ] Apply Tailwind styling consistently
- [ ] Ensure mobile responsive (test on small screens)
- [ ] Add proper loading indicators
- [ ] Add confirmation dialogs for destructive actions
- [ ] Test keyboard navigation
- [ ] Verify focus management
- [ ] Check color contrast

**Phase 6: Testing & QA**
- [ ] Run through manual testing checklist above
- [ ] Test all edge cases
- [ ] Test error scenarios (network failures, validation)
- [ ] Test on actual mobile devices
- [ ] Fix any bugs found
- [ ] Run `npm run build` - fix any errors
- [ ] Run `npm run lint` - fix any issues
- [ ] Run `npm run type-check` - fix type errors

**Phase 7: Documentation & Commit**
- [ ] Add JSDoc comments to all API functions
- [ ] Update `docs/implementation-notes.md` (if exists)
- [ ] Update user story status to "Completed"
- [ ] Create commit following `docs/git-workflow.md`
- [ ] Push to repository
- [ ] Create pull request (if applicable)
```

---

### Section 10: Effort Estimate & Risks

```markdown
## 10. Estimated Effort & Risks

**Total Effort:** [X] days

**Breakdown:**
- Database & Migrations: 0.5 days
- API Layer: 1 day
- Core Components: 1.5 days
- Form & CRUD: 1 day
- Polish & Accessibility: 0.5 days
- Testing & QA: 0.5 days
- Documentation & Commit: 0.5 days

**Dependencies:**
- [Dependency 1: e.g., "Requires Feature X to be completed first"]
- [Dependency 2: e.g., "Awaiting design mockups"]
- OR: None

**Risks & Mitigation:**

**Risk 1:** [Description of risk]
- **Impact:** [High/Medium/Low]
- **Probability:** [High/Medium/Low]
- **Mitigation:** [How to address]

**Risk 2:** [Description of risk]
- **Impact:** [High/Medium/Low]
- **Probability:** [High/Medium/Low]
- **Mitigation:** [How to address]

**Success Criteria:**
- [ ] All acceptance criteria met
- [ ] All tests passing
- [ ] No critical bugs
- [ ] Performance acceptable
- [ ] Accessible to keyboard and screen readers
```

---

### Section 11: Revision History

```markdown
## Revision History

| Date | Changes | Reason |
|------|---------|--------|
| 2025-MM-DD | Initial plan created | - |
```

---

## STEP B: VALIDATE PLAN (MANDATORY)

**⚠️ DO NOT SKIP VALIDATION - This step is REQUIRED before presenting plan to user**

### Validation Process

Run these validations IN ORDER:

### B.1: Validate Database Schema

**Use helper command:**
```
Run SlashCommand: /helpers/explore-database
```

**Check against plan Section 3:**
- ✅ Table names follow project conventions (snake_case, plural, etc.)
- ✅ Column types match PostgreSQL standards
- ✅ Standard columns included (id, created_at, updated_at, etc.)
- ✅ Foreign keys reference existing tables
- ✅ Index naming follows pattern
- ✅ RLS policies follow project patterns

**Auto-fix issues found**

### B.2: Validate Type Definitions

**Use helper command:**
```
Run SlashCommand: /helpers/validate-types

Provide plan file path
```

**Check plan Section 4 types:**
- ✅ Interface naming (PascalCase)
- ✅ Property naming (camelCase)
- ✅ Types match database columns
- ✅ Nullable columns → optional properties
- ✅ Enum types match CHECK constraints
- ✅ No duplicate type definitions

**Auto-fix issues found**

### B.3: Validate Standards Compliance

**Use helper command:**
```
Run SlashCommand: /helpers/read-standards

Specify feature types from plan
```

**Check against all relevant standards:**
- ✅ Naming conventions followed
- ✅ Error handling patterns included
- ✅ Testing strategy comprehensive
- ✅ Accessibility mentioned
- ✅ JSDoc comments in checklist

**Auto-fix issues found**

### B.4: Validate User Story Alignment

**Read user story** (from plan metadata)

**Check coverage:**
- ✅ All acceptance criteria addressed in plan
- ✅ All edge cases from story included
- ✅ Non-functional requirements covered

**Auto-fix gaps found**

### B.5: Validate File Paths

**Check reused components/APIs exist:**
```bash
# Verify each file path mentioned in Section 2
ls -la [file-path-from-plan]
```

**Check and fix:**
- ✅ All referenced files exist
- ✅ Paths are correct
- ✅ Functions mentioned actually exist

**Auto-fix incorrect paths**

### B.6: Update Plan with Fixes

**For ALL issues found:**
1. Make corrections directly in plan
2. Add to revision history table
3. Update "Last Revised" date
4. Save updated plan

**Revision history entry:**
```markdown
| 2025-MM-DD | Auto-validation fixes | Fixed DB types, corrected file paths, added missing acceptance criteria, aligned with standards |
```

---

## Present Validated Plan for Approval

```markdown
# ✅ Implementation Plan Ready: [Feature Name]

**Plan File:** `docs/plans/us-XXX-plan.md`
**Status:** Draft (pending your approval)
**Total Sections:** 11
**Estimated Effort:** X days

---

## Validation Results

### ✅ All Validations Passed

1. ✅ Database schema follows project conventions
2. ✅ Type definitions align with database
3. ✅ Standards compliance verified
4. ✅ All acceptance criteria addressed
5. ✅ File paths validated
6. ✅ Similar features reviewed

### 🔧 Auto-Fixes Applied: [X]

[List issues found and fixed, if any]

---

## Plan Summary

[Include brief summary of approach from plan]

---

## Ready to Proceed?

**Before implementation, please confirm:**

1. ✅ Requirements are accurate
2. ✅ Technical approach is sound
3. ✅ Database design is appropriate
4. ✅ Component structure makes sense
5. ✅ Edge cases are covered
6. ✅ Effort estimate is acceptable
7. ✅ No major concerns

## Next Steps

**If approved:**
- Say "approve" or "proceed" to update plan status to "Approved"
- Then run `/start-implementation` to begin coding

**If changes needed:**
- Specify what needs adjustment
- I'll update the plan and re-validate

**If questions:**
- Ask anything about the plan
```

---

## After Approval

When user approves:

1. Update plan file:
   - Change Status: "Draft" → "Approved"
   - Add approval to revision history
   - Save file

2. Update user story (if exists):
   - Change status to "In Progress"
   - Link to plan file

3. Inform user:
   ```
   ✅ Plan approved and saved

   Ready to implement!
   Run `/start-implementation` to begin coding.
   ```

---

## Next Phase

After plan is approved:
```
/start-implementation
```

This will begin the implementation following the validated plan.
