r---
description: Complete discovery - requirements gathering + architecture review (Phase 1+2)
---

# DISCOVERY: Requirements & Architecture

You are conducting comprehensive discovery for a feature implementation. This combines requirements gathering (Phase 1) and architecture review (Phase 2) into a streamlined process.

## CRITICAL RULES

❌ **DO NOT skip exploration - use helper commands**
❌ **DO NOT assume patterns - verify against codebase**
❌ **DO NOT skip reading standards**
✅ **ALWAYS explore current app state first**
✅ **ALWAYS read user story documentation**
✅ **ALWAYS ask informed clarifying questions**
✅ **ALWAYS use helper commands for deep dives**
✅ **ALWAYS verify against actual code**

---

## Overview: Two-Phase Discovery

This command combines two phases:

**Phase 1: Requirements Gathering**
- Understand user needs and acceptance criteria
- Explore current application state
- Ask informed clarifying questions
- Document requirements summary

**Phase 2: Architecture Review**
- Read project standards
- Deep dive into database, API, and component patterns
- Identify reusable code
- Document architecture approach

**Result:** Comprehensive understanding ready for planning

---

## PHASE 1: REQUIREMENTS GATHERING

### Step 1.1: Quick Project Overview

Get high-level understanding:

```bash
# Project structure
ls -la

# Tech stack indicators
cat package.json 2>/dev/null | grep -E '"(react|vue|next|typescript|supabase)"' | head -10
```

### Step 1.2: Read User Story (If Provided)

**If user provided US-XXX format:**
1. Read `docs/high-level-user-stories.md` to find the story
2. Read detailed spec at `docs/features/phase-X/US-XXX-*.md`
3. Extract:
   - User type and persona
   - User goal and benefit
   - ALL acceptance criteria
   - Priority level and current status

**If user provided feature description:**
- Ask if this matches an existing user story
- If not, we'll help create one during planning

**Document findings:**
```markdown
## User Story Context

**Story ID:** US-XXX or "New feature"
**User Type:** [Customer/Staff/Admin]
**Goal:** [What user wants to achieve]
**Benefit:** [Why it matters]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

### Step 1.3: Explore Current App State

**Use helper commands for thorough exploration:**

**For database-heavy features:**
```
Run SlashCommand: /helpers/explore-database

This will:
- Find migration files
- Query/read database schema
- Check RLS policies
- Identify patterns
```

**For component/API features:**
```
Run SlashCommand: /helpers/explore-codebase

Specify feature area (e.g., "bookings", "clients", "conversations")

This will:
- Find similar components
- Discover API modules
- Identify reusable code
- Document patterns
```

**Quick manual checks (if helpers not sufficient):**
```bash
# Check documentation
ls docs/*.md 2>/dev/null

# Check feature docs
ls docs/features/ 2>/dev/null
```

### Step 1.4: Ask Informed Clarifying Questions

**Now that you understand the current state, ask targeted questions using AskUserQuestion tool:**

**Requirements Questions:**
- What problem does this solve for the user?
- Who are the primary users? (Customer/Staff/Admin?)
- What are must-have vs nice-to-have features?
- Are there design mockups or wireframes?
- Does this integrate with existing features you found?

**Technical Questions:**
- Should this follow the same pattern as [existing similar feature]?
- Performance requirements? (response time, data volume)
- Security considerations? (PII, access control, RLS)
- Expected timeline? (impacts scope)
- Integration requirements? (external services, APIs)

**Edge Cases:**
- What happens when data is empty?
- What happens on API failure or slow network?
- What are boundary conditions? (max values, limits)

### Step 1.5: Present Requirements Summary

```markdown
## Phase 1 Complete: Requirements Summary

### Current App Context
**Tech Stack:** [React, TypeScript, Supabase, etc.]
**Similar Features:** [List features found]
**Database Tables:** [Relevant tables]
**API Modules:** [Relevant APIs]
**Components:** [Similar components]

### User Story
**User Type:** [Customer/Staff/Admin]
**Goal:** [What user wants]
**Benefit:** [Why it matters]
**Story Reference:** [US-XXX or "New"]

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### Must-Have Features
- Feature 1
- Feature 2

### Nice-to-Have Features
- Feature 3 (if time permits)

### Technical Considerations
- **Performance:** [Requirements or "None specified"]
- **Security:** [RLS, auth, data protection]
- **Integrations:** [List or "None"]
- **Timeline:** [Expected timeframe]

### Edge Cases Identified
- [ ] Empty data state
- [ ] API failure recovery
- [ ] Slow network handling
- [ ] Boundary conditions

### Open Questions
- [ ] Question 1?
- [ ] Question 2?
```

**Confirm requirements understanding with user before proceeding to Phase 2.**

---

## PHASE 2: ARCHITECTURE REVIEW

### Step 2.1: Read Project Standards

**Use the standards helper:**

```
Run SlashCommand: /helpers/read-standards

Specify feature type(s):
- database (if DB changes needed)
- api (if backend functions needed)
- components (if UI needed)
- forms (if form handling needed)
- auth (if authentication/authorization)
- performance (if performance critical)
- testing (always include)

This will:
- Read core standards (coding, process, git)
- Read feature-specific standards
- Extract key patterns to follow
- Present standards checklist
```

**Document key standards:**
```markdown
## Standards to Follow

**From coding-standards.md:**
- [Key convention 1]
- [Key convention 2]

**From database-patterns.md:**
- [Key pattern 1]
- [Key pattern 2]

**From api-patterns.md:**
- [Key pattern 1]
- [Key pattern 2]

**From component-patterns.md:**
- [Key pattern 1]
- [Key pattern 2]
```

### Step 2.2: Database Architecture Deep Dive

**If feature involves database changes:**

**Reference exploration from Phase 1 or run again:**
```
Run SlashCommand: /helpers/explore-database
```

**Document database approach:**
```markdown
## Database Architecture

**Existing Schema:**
- Tables: [list relevant tables]
- Key relationships: [describe]
- Naming patterns: [snake_case, plural, etc.]
- RLS approach: [user-based, client-based, etc.]

**Changes Needed:**
- [ ] Create table: `table_name` with columns [list]
- [ ] Add columns to `existing_table`: [list]
- [ ] Add indexes: [specify]
- [ ] Add RLS policies: [specify]

**Migration Strategy:**
1. Migration file: `YYYYMMDDHHMMSS_description.sql`
2. Tables created with standard columns (id, created_at, updated_at)
3. Foreign keys to existing tables
4. Indexes on foreign keys and commonly queried columns
5. RLS policies following project patterns
```

### Step 2.3: API Architecture Deep Dive

**If feature involves API functions:**

**Reference exploration from Phase 1 or run again:**
```
Run SlashCommand: /helpers/explore-codebase

Focus on API layer
```

**Document API approach:**
```markdown
## API Architecture

**Existing APIs to Reuse:**
- `getClientById()` from `src/api/clients.ts` - Get client details
- `getCurrentUser()` from `src/api/users.ts` - Get current user

**New API Module:** `src/api/feature-name.ts`

**New Functions Needed:**
- `getFeatureById(id: string): Promise<Feature | null>`
- `getAllFeatures(): Promise<Feature[]>`
- `createFeature(data: FeatureFormData): Promise<Feature>`
- `updateFeature(id: string, updates: Partial<FeatureFormData>): Promise<Feature>`
- `deleteFeature(id: string): Promise<void>`

**Patterns to Follow:**
- Function naming: [pattern from codebase]
- Return types: [pattern from codebase]
- Error handling: [pattern from codebase]
- Database queries: [pattern from codebase]
```

### Step 2.4: Component Architecture Deep Dive

**If feature involves UI components:**

**Reference exploration from Phase 1 or run again:**
```
Run SlashCommand: /helpers/explore-codebase

Focus on components and pages
```

**Document component approach:**
```markdown
## Component Architecture

**Similar Components Found:**
- `src/pages/SimilarPage.tsx` - Good template for page structure
- `src/components/SimilarList.tsx` - List display pattern

**Reusable Components:**
- `<LoadingSpinner />` from `src/components/LoadingSpinner.tsx`
- `<EmptyState />` from `src/components/EmptyState.tsx`
- `<ErrorMessage />` from `src/components/ErrorMessage.tsx`
- `<Modal />` from `src/components/Modal.tsx`
- `<Button />` from `src/components/Button.tsx`

**New Components Needed:**
- `FeaturePage.tsx` - Main page (follows pattern from SimilarPage)
- `FeatureList.tsx` - List display
- `FeatureCard.tsx` - Individual item
- `FeatureForm.tsx` - Create/edit form

**Patterns to Follow:**
- State management: [useState, Context, RTK Query, etc.]
- Data fetching: [useEffect, custom hooks, etc.]
- Form handling: [React Hook Form, native, etc.]
- Validation: [Zod, Yup, etc.]
- Styling: [Tailwind, CSS modules, etc.]

**Component Hierarchy:**
```
FeaturePage
├── FeatureList
│   ├── FeatureCard
│   └── EmptyState (reused)
├── FeatureForm
│   └── Form fields
└── LoadingSpinner (reused)
```
```

### Step 2.5: Synthesize Architecture Understanding

```markdown
## Phase 2 Complete: Architecture Summary

### Standards Compliance
**Core Standards:** [List key standards to follow]
**Feature Standards:** [List feature-specific patterns]
**Quality Gates:** [List quality checks before commit]

### Database Layer
**Existing Schema:** [Summary]
**Changes Needed:** [Summary]
**Migration Plan:** [Brief description]

### API Layer
**Reusable Functions:** [List]
**New Functions:** [List with signatures]
**Patterns:** [Key patterns to follow]

### Component Layer
**Reusable Components:** [List]
**New Components:** [List with purpose]
**Patterns:** [Key patterns to follow]

### Dependencies & Integration
**Existing Features:** [How this integrates]
**External Services:** [If any]
**Third-party Libraries:** [If needed]
```

---

## Discovery Complete!

Present complete discovery summary:

```markdown
# ✅ Discovery Complete: [Feature Name]

## Summary

**Feature:** [Name and brief description]
**User Story:** [US-XXX or "New feature"]
**Complexity:** [Low/Medium/High]
**Estimated Effort:** [Initial rough estimate]

---

## Requirements (Phase 1)

[Include Requirements Summary from Step 1.5]

---

## Architecture (Phase 2)

[Include Architecture Summary from Step 2.5]

---

## Ready for Planning

**Next Steps:**
1. Review the discovery findings above
2. Confirm approach is correct
3. Proceed to planning phase

**Would you like to:**
- **Option 1:** Proceed to planning (run `/plan-and-validate`)
- **Option 2:** Adjust discovery findings (specify changes)
- **Option 3:** Ask more questions

**Shortcuts:**
- Say "proceed" or "continue" to automatically trigger `/plan-and-validate`
- Say "/next" to continue to next phase
```

---

## Next Phase

After discovery is approved, run:
```
/plan-and-validate
```

This will create a comprehensive implementation plan and validate it against the discoveries made here.
