# Implementation Plan: [Feature Name]

## Plan Metadata

- **User Story:** [docs/features/us-XXX-story-name.md](../features/us-XXX-story-name.md)
- **Created:** YYYY-MM-DD
- **Author:** [Name or "Claude Code"]
- **Status:** Draft | Approved | In Progress | Complete | Revised
- **Estimated Effort:** X days
- **Actual Effort:** Y days (updated when complete)
- **Last Revised:** YYYY-MM-DD

## Revision History

| Date | Changes | Reason |
|------|---------|--------|
| YYYY-MM-DD | Initial plan created | - |

---

## 1. Requirements Summary

**Feature:** [Name]
**User Story:** [Link to US-XXX or description]
**User Type:** [Customer/Staff/Admin]
**Goal:** [What user wants to achieve]
**Value:** [Why it matters to user]

**Must-Have Features:**
- [ ] Feature 1
- [ ] Feature 2

**Nice-to-Have Features:**
- [ ] Feature 3 (if time permits)

---

## 2. Technical Approach

**Architecture Pattern:** [API layer + React components + Supabase RLS]
**Key Technologies:** [React 19, TypeScript, Supabase, React Hook Form, etc.]

**Reused Components:**
- [ComponentA] - [purpose]
- [ComponentB] - [purpose]

**Reused APIs:**
- [functionA()] from [module] - [purpose]
- [functionB()] from [module] - [purpose]

**New Components:**
- [ComponentX] - [purpose]
- [ComponentY] - [purpose]

**New APIs:**
- [functionX()] - [signature and purpose]
- [functionY()] - [signature and purpose]

**Standards to Follow:**
- [List relevant docs and key patterns]

---

## 3. Database Changes

**New Tables:**
- Table: `table_name`
  - Columns:
    - `id` UUID PRIMARY KEY DEFAULT uuid_generate_v4()
    - `created_at` TIMESTAMPTZ DEFAULT NOW()
    - `column1` TEXT NOT NULL
    - `column2` INTEGER
  - Indexes:
    - `idx_table_name_column1` ON column1
  - RLS Policies:
    - SELECT: Users can view their own records
    - INSERT: Authenticated users can create
    - UPDATE: Users can update their own records
    - DELETE: Users can delete their own records

**Modified Tables:**
- Table: `existing_table`
  - New Columns:
    - `new_column` TEXT
  - New Indexes:
    - `idx_existing_table_new_column` ON new_column

**Migration Files Needed:**
1. `YYYYMMDD_create_feature_tables.sql` - Create new tables
2. `YYYYMMDD_add_feature_rls.sql` - Add RLS policies
3. `YYYYMMDD_add_indexes.sql` - Add performance indexes

---

## 4. API Layer Implementation

**New API Module:** `src/api/feature-name.ts`

**Type Definitions:**
```typescript
interface Feature {
  id: string
  created_at: string
  field1: string
  field2: number
}

interface FeatureFormData {
  field1: string
  field2: number
}
```

**Functions to Implement:**

1. `getFeatureById(id: string): Promise<Feature | null>`
   - Query table with id
   - Handle not found case
   - Return typed result

2. `getAllFeatures(): Promise<Feature[]>`
   - Query all records
   - Apply filters if needed
   - Return array

3. `createFeature(data: FeatureFormData): Promise<Feature>`
   - Validate input
   - Insert into database
   - Return created record

4. `updateFeature(id: string, updates: Partial<FeatureFormData>): Promise<Feature>`
   - Check record exists
   - Update fields
   - Return updated record

5. `deleteFeature(id: string): Promise<void>`
   - Check record exists
   - Delete record
   - Handle cascade if needed

**Error Handling Pattern:**
- Use try/catch blocks
- Throw descriptive errors
- Log errors appropriately

---

## 5. Component Architecture

**Component Hierarchy:**
```
FeaturePage (src/pages/FeaturePage.tsx)
├── FeatureList (src/components/FeatureList.tsx)
│   ├── FeatureCard (src/components/FeatureCard.tsx)
│   └── EmptyState (reuse from src/components/EmptyState.tsx)
├── FeatureForm (src/components/FeatureForm.tsx)
└── LoadingSpinner (reuse from src/components/LoadingSpinner.tsx)
```

**Component Responsibilities:**

1. **FeaturePage** (`src/pages/FeaturePage.tsx`)
   - Fetch data on mount
   - Manage page-level state (features, loading, error)
   - Handle routing/navigation
   - Provide data to child components

2. **FeatureList** (`src/components/FeatureList.tsx`)
   - Display array of features
   - Handle empty state (no features)
   - Handle loading state
   - Handle error state

3. **FeatureCard** (`src/components/FeatureCard.tsx`)
   - Display single feature
   - Action buttons (edit, delete)
   - Confirm before delete

4. **FeatureForm** (`src/components/FeatureForm.tsx`)
   - Form fields with React Hook Form
   - Validation with Zod
   - Submit handler
   - Loading state during submission
   - Error display

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

---

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

1. **On Mount:**
   - Set loading = true
   - Call getAllFeatures()
   - Set features or error
   - Set loading = false

2. **On Create:**
   - Call createFeature(formData)
   - Add to features array
   - Close form
   - Show success message

3. **On Update:**
   - Call updateFeature(id, formData)
   - Update in features array
   - Close form
   - Show success message

4. **On Delete:**
   - Confirm with user
   - Call deleteFeature(id)
   - Remove from features array
   - Show success message

**Form Validation (Zod):**
```typescript
const featureSchema = z.object({
  field1: z.string().min(1, 'Field1 is required').max(100),
  field2: z.number().min(0).max(1000)
})
```

---

## 7. Edge Cases & Error Handling

**Loading States:**
- [ ] Initial page load - Show full-page spinner
- [ ] Form submission - Disable button, show inline spinner
- [ ] Delete operation - Show spinner on button
- [ ] Background refresh - Show subtle indicator (optional)

**Error States:**
- [ ] Network error - Show retry button with error message
- [ ] Validation error - Show field-specific errors inline
- [ ] API error (400/500) - Show user-friendly message
- [ ] 404 Not Found - Show "Record not found" message
- [ ] Unauthorized - Redirect to login or show permission error

**Empty States:**
- [ ] No features exist - Show empty state with "Create first feature" CTA
- [ ] Search no results - Show "No results found" message
- [ ] Deleted last item - Show empty state again

**Boundary Conditions:**
- [ ] Max length inputs - Validate and show character count
- [ ] Max items in list - Implement pagination or virtual scrolling
- [ ] Concurrent updates - Handle optimistic updates or refresh
- [ ] Duplicate prevention - Check before creating
- [ ] Required relationships - Validate foreign keys exist

**Network Resilience:**
- [ ] Slow network - Show loading indicators
- [ ] Offline mode - Show offline banner, queue actions
- [ ] Timeout handling - Set reasonable timeouts, show retry

---

## 8. Testing Strategy

**Manual Testing Checklist:**

**Happy Path:**
- [ ] User can view list of features
- [ ] User can create new feature
- [ ] Form validation works correctly
- [ ] User can edit existing feature
- [ ] User can delete feature
- [ ] Success messages display
- [ ] Data persists after page refresh

**Error Cases:**
- [ ] Network failure shows error message
- [ ] Invalid form data shows validation errors
- [ ] API errors show user-friendly messages
- [ ] Delete confirmation prevents accidental deletion

**Edge Cases:**
- [ ] Empty state displays when no data
- [ ] Loading state displays during fetch
- [ ] Large dataset handles gracefully (100+ items)
- [ ] Concurrent create/update doesn't break state
- [ ] Browser back/forward navigation works

**Accessibility:**
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Focus states are visible
- [ ] Form labels are associated with inputs
- [ ] Error messages announced to screen readers
- [ ] Color contrast meets WCAG standards

**Responsive Design:**
- [ ] Desktop layout (1920x1080)
- [ ] Tablet layout (768x1024)
- [ ] Mobile layout (375x667)
- [ ] Touch targets minimum 44x44px

**Browser Testing:**
- [ ] Chrome (latest)
- [ ] Safari (latest)
- [ ] Mobile Safari
- [ ] Mobile Chrome

---

## 9. Implementation Checklist

**Phase 1: Database & Migrations (Day 1)**
- [ ] Create migration: `YYYYMMDD_create_feature_tables.sql`
- [ ] Define table schema with constraints
- [ ] Add indexes for performance
- [ ] Create RLS policies
- [ ] Test migration locally
- [ ] Verify RLS policies work

**Phase 2: API Layer (Day 1-2)**
- [ ] Create `src/api/feature-name.ts`
- [ ] Define TypeScript interfaces
- [ ] Implement `getFeatureById()`
- [ ] Implement `getAllFeatures()`
- [ ] Implement `createFeature()`
- [ ] Implement `updateFeature()`
- [ ] Implement `deleteFeature()`
- [ ] Add error handling to all functions
- [ ] Test functions in browser console

**Phase 3: Core Components (Day 2-3)**
- [ ] Create `src/pages/FeaturePage.tsx`
- [ ] Implement data fetching logic
- [ ] Add loading/error/empty states
- [ ] Create `src/components/FeatureList.tsx`
- [ ] Create `src/components/FeatureCard.tsx`
- [ ] Wire up delete functionality
- [ ] Test in browser

**Phase 4: Form & CRUD (Day 3-4)**
- [ ] Create `src/components/FeatureForm.tsx`
- [ ] Add Zod validation schema
- [ ] Integrate React Hook Form
- [ ] Implement create flow
- [ ] Implement edit flow
- [ ] Add form error display
- [ ] Add success messages
- [ ] Test all CRUD operations

**Phase 5: Polish & UX (Day 4)**
- [ ] Add Tailwind styling
- [ ] Ensure mobile responsive
- [ ] Add loading indicators
- [ ] Add confirmation dialogs
- [ ] Add keyboard shortcuts (if applicable)
- [ ] Add focus management
- [ ] Test accessibility

**Phase 6: Testing & QA (Day 5)**
- [ ] Run through manual testing checklist
- [ ] Test all edge cases
- [ ] Test error scenarios
- [ ] Test on mobile devices
- [ ] Fix any bugs found
- [ ] Run `npm run build` - verify no errors
- [ ] Run `npm run lint` - fix any issues
- [ ] Run `npm run type-check` - fix any type errors

**Phase 7: Documentation & Deploy (Day 5)**
- [ ] Add JSDoc comments to all functions
- [ ] Update `docs/implementation-notes.md`
- [ ] Update user story status to "Completed"
- [ ] Update plan status to "Complete"
- [ ] Update actual effort in plan metadata
- [ ] Create descriptive commit message
- [ ] Push to repository
- [ ] Create pull request (if applicable)

---

## 10. Estimated Effort & Risks

**Total Effort:** [X] days

**Breakdown:**
- Database & Migrations: 0.5 days
- API Layer: 1 day
- Core Components: 1.5 days
- Form & CRUD: 1 day
- Polish & UX: 0.5 days
- Testing & QA: 0.5 days
- Documentation: 0.5 days

**Dependencies:**
- [Dependency 1: e.g., awaiting design mockups]
- [Dependency 2: e.g., requires Feature X to be completed]
- OR: None

**Risks & Mitigation:**
- **Risk 1:** [Complex data relationships might slow down queries]
  - *Mitigation:* Add database indexes early, test with realistic data volume
- **Risk 2:** [User might need real-time updates]
  - *Mitigation:* Plan for Supabase realtime subscriptions if needed
- **Risk 3:** [Form validation could be complex]
  - *Mitigation:* Start with basic validation, iterate based on user feedback

---

**This plan was generated using the `/plan-and-validate` slash command and follows the structure defined in `.claude/commands/plan-and-validate.md`.**
