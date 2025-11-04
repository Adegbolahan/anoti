---
description: Start feature implementation (Phase 4)
---

# PHASE 4: IMPLEMENTATION

You are now implementing the feature based on the approved plan from `/plan-and-validate`. Follow the implementation checklist systematically.

## CRITICAL RULES

❌ **DO NOT skip steps in the checklist**
❌ **DO NOT implement partial features - complete each phase fully**
❌ **DO NOT forget to handle loading/error/empty states**
✅ **ALWAYS use TodoWrite tool to track progress**
✅ **ALWAYS test after each phase before moving to next**
✅ **ALWAYS follow patterns from architecture review**
✅ **ALWAYS handle ALL edge cases identified in the plan**

---

## Step 4.1: Initialize TodoWrite Tracking

**IMMEDIATELY create todos from the Implementation Checklist in the plan.**

Extract the checklist items from the approved plan and create todos:

```markdown
Use TodoWrite to create todos for:
- [ ] Create migration: YYYYMMDD_create_feature_tables.sql
- [ ] Define table schema with constraints
- [ ] Add indexes for performance
- [ ] Create RLS policies
- [ ] Test migration locally
- [ ] Verify RLS policies work
- [ ] Create src/api/feature-name.ts
- [ ] Define TypeScript interfaces
- [ ] Implement getFeatureById()
- ... (continue with all checklist items)
```

**Mark todos as in_progress/completed as you work.**

---

## Step 4.2: Follow the 10-Step Development Process

Implement following `docs/feature-development-process.md`:

### Phase 1: Database & Migrations

**Create migration files:**

1. Create `supabase/migrations/YYYYMMDD_create_feature_tables.sql`
   - Copy table schema from plan
   - Add constraints and indexes
   - Test locally: `supabase db reset`

2. Create `supabase/migrations/YYYYMMDD_add_feature_rls.sql`
   - Copy RLS policies from plan
   - Test policies work correctly

**Mark todos complete after testing:**
- [x] Create migration
- [x] Add RLS policies
- [x] Test migration locally

**Test before proceeding:**
```sql
-- Verify tables exist
SELECT * FROM information_schema.tables WHERE table_name = 'your_table';

-- Verify RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'your_table';

-- Test policies work
INSERT INTO your_table (...) VALUES (...);
SELECT * FROM your_table;
```

---

### Phase 2: API Layer

**Create API module: `src/api/feature-name.ts`**

1. Define TypeScript interfaces (from plan)
2. Implement each function one by one:
   - `getFeatureById()`
   - `getAllFeatures()`
   - `createFeature()`
   - `updateFeature()`
   - `deleteFeature()`
3. Add comprehensive error handling
4. Add JSDoc comments

**Mark todos complete after each function:**
- [x] Create src/api/feature-name.ts
- [x] Implement getFeatureById()
- [x] Implement getAllFeatures()
- etc.

**Test in browser console before proceeding:**
```javascript
// Import the API module
import { getAllFeatures, createFeature } from './api/feature-name'

// Test fetching
const features = await getAllFeatures()
console.log('Features:', features)

// Test creating
const newFeature = await createFeature({ field1: 'test', field2: 42 })
console.log('Created:', newFeature)
```

---

### Phase 3: Core Components (Page & List)

**Create page component: `src/pages/FeaturePage.tsx`**

1. Set up component structure
2. Add state management (features, loading, error)
3. Implement data fetching in useEffect
4. Add loading state UI
5. Add error state UI
6. Add empty state UI
7. Render FeatureList when data exists

**Create list component: `src/components/FeatureList.tsx`**

1. Receive features array as prop
2. Map over features to render cards
3. Handle empty array (empty state)

**Create card component: `src/components/FeatureCard.tsx`**

1. Display feature data
2. Add edit button (handler passed as prop)
3. Add delete button with confirmation
4. Style with Tailwind

**Mark todos complete:**
- [x] Create FeaturePage
- [x] Implement data fetching
- [x] Add loading/error/empty states
- [x] Create FeatureList
- [x] Create FeatureCard

**Test in browser:**
- [ ] Page loads without errors
- [ ] Loading state shows briefly
- [ ] Data displays correctly
- [ ] Empty state shows if no data
- [ ] Styling looks correct

---

### Phase 4: Form & CRUD Operations

**Create form component: `src/components/FeatureForm.tsx`**

1. Set up React Hook Form
2. Define Zod validation schema
3. Create form fields
4. Add submit handler
5. Display validation errors
6. Add loading state during submission
7. Add success/error messages

**Wire up CRUD operations in FeaturePage:**

1. **Create flow:**
   - Add "Create" button
   - Show FeatureForm in modal/panel
   - On submit: call createFeature()
   - Update features array
   - Close form
   - Show success message

2. **Edit flow:**
   - Pass feature to form as initialData
   - On submit: call updateFeature()
   - Update features array
   - Close form
   - Show success message

3. **Delete flow:**
   - Show confirmation dialog
   - On confirm: call deleteFeature()
   - Remove from features array
   - Show success message

**Mark todos complete:**
- [x] Create FeatureForm
- [x] Add Zod validation
- [x] Implement create flow
- [x] Implement edit flow
- [x] Implement delete flow

**Test all CRUD operations:**
- [ ] Can create new feature
- [ ] Validation prevents invalid data
- [ ] Can edit existing feature
- [ ] Can delete feature (with confirmation)
- [ ] Success messages display
- [ ] Error messages display for failures

---

### Phase 5: Polish & Accessibility

**Add polish:**

1. **Styling:**
   - Apply Tailwind classes consistently
   - Ensure proper spacing and layout
   - Add hover/focus states
   - Make responsive (mobile/tablet/desktop)

2. **Loading indicators:**
   - Page load: full-page spinner
   - Form submit: button spinner
   - Delete: button loading state

3. **User feedback:**
   - Toast notifications for success/error
   - Confirmation dialogs for destructive actions
   - Disabled states during operations

4. **Accessibility:**
   - Proper ARIA labels
   - Keyboard navigation (Tab, Enter, Escape)
   - Focus management (trap focus in modals)
   - Visible focus indicators
   - Screen reader announcements

**Mark todos complete:**
- [x] Add Tailwind styling
- [x] Ensure mobile responsive
- [x] Add loading indicators
- [x] Add confirmation dialogs
- [x] Add accessibility features

**Test polish:**
- [ ] Looks good on desktop (1920x1080)
- [ ] Looks good on tablet (768x1024)
- [ ] Looks good on mobile (375x667)
- [ ] Can navigate with keyboard only
- [ ] Focus indicators visible
- [ ] Touch targets at least 44x44px

---

### Phase 6: Comprehensive Testing

**Run through the testing checklist from the plan:**

**Happy Path:**
- [ ] User can view list
- [ ] User can create new item
- [ ] Form validation works
- [ ] User can edit item
- [ ] User can delete item
- [ ] Success messages display

**Error Cases:**
- [ ] Network error handled
- [ ] Validation errors display
- [ ] API errors show user-friendly messages
- [ ] Delete confirmation works

**Edge Cases:**
- [ ] Empty state when no data
- [ ] Loading state during fetch
- [ ] Large dataset (add 50+ test items)
- [ ] Concurrent operations don't break state
- [ ] Browser back/forward works

**Accessibility:**
- [ ] Keyboard navigation complete
- [ ] Screen reader friendly
- [ ] Color contrast sufficient

**Build & Lint:**
- [ ] Run `npm run build` - no errors
- [ ] Run `npm run lint` - fix all issues
- [ ] Run `npm run type-check` - no type errors

**Mark todos complete:**
- [x] Run through testing checklist
- [x] Test edge cases
- [x] Test error scenarios
- [x] Fix all bugs found
- [x] Run build successfully
- [x] Run lint successfully

---

### Phase 7: Documentation & Commit

**Add documentation:**

1. **Code documentation:**
   - Add JSDoc comments to all API functions
   - Add comments for complex logic
   - Add prop types documentation

2. **Update project docs:**
   - Update `docs/implementation-notes.md` with feature details
   - Update user story status to "Completed" in `docs/high-level-user-stories.md`
   - Update feature status in `docs/features/phase-X/US-XXX-*.md`

3. **Create commit:**
   - Follow `docs/git-workflow.md` conventions
   - Use Conventional Commits format
   - Include user story reference: `Implements: docs/features/us-XXX-<story-name>.md`
   - Include Claude Code attribution

```bash
git add .
git commit -m "feat: implement [feature name]

- Created database tables and RLS policies
- Implemented API layer with CRUD operations
- Built React components with form handling
- Added comprehensive error handling
- Tested all user flows and edge cases

Implements: docs/features/us-XXX-<story-name>.md

 

```

**Important:** See `docs/git-workflow.md` for commit conventions and user story reference format.

**Mark todos complete:**
- [x] Add JSDoc comments
- [x] Update implementation notes
- [x] Update user story status
- [x] Create commit
- [x] Push to repository

---

## Step 4.3: Implementation Checklist Summary

**As you implement, continuously:**

1. ✅ Mark todos in_progress before starting each task
2. ✅ Mark todos completed after finishing and testing
3. ✅ Test thoroughly after each phase
4. ✅ Fix issues before moving to next phase
5. ✅ Keep user updated on progress

**Do NOT:**

- ❌ Skip loading states
- ❌ Skip error states
- ❌ Skip empty states
- ❌ Leave TODOs in code
- ❌ Commit broken code
- ❌ Skip testing

---

## Implementation Complete!

When all todos are marked complete:

```markdown
# ✅ Feature Implementation Complete: [Feature Name]

## Summary of Changes

**Database:**
- Created tables: [list]
- Added RLS policies: [list]

**API Layer:**
- New module: src/api/feature-name.ts
- Functions: [list]

**Components:**
- New page: src/pages/FeaturePage.tsx
- New components: [list]

**Testing:**
- All manual tests passed
- Build successful
- Lint passed
- No type errors

**Documentation:**
- User story updated to "Completed"
- Implementation notes added
- Code documented with JSDoc

## Commit Details
- Commit hash: [hash]
- Branch: [branch name]

## Next Steps
- [ ] Create pull request (if applicable)
- [ ] Deploy to staging for QA
- [ ] Demo to stakeholders
- [ ] Gather user feedback
```

**The feature is now complete and ready for review/deployment!**
