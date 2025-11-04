---
description: Read relevant project standards and patterns documentation
---

# Standards Reading Helper

This helper reads the relevant standards documentation based on the feature type and summarizes key patterns to follow.

## When to Use

Use this helper when you need to:
- Understand coding standards before writing code
- Learn project patterns before designing components
- Validate that your approach follows project conventions
- Get context on how similar features are built

## Required Input

Specify the feature type(s) that apply:
- **database** - Database schema, migrations, RLS
- **api** - Backend API functions
- **components** - React/Vue components, UI
- **forms** - Form handling and validation
- **auth** - Authentication and authorization
- **performance** - Performance optimization
- **testing** - Test strategy and implementation

## Execution

### Step 1: Always Read Core Standards

**These must be read for ALL features:**

1. **`docs/coding-standards.md`**
   - Language conventions (TypeScript, Python, etc.)
   - Naming conventions
   - Import organization
   - Error handling
   - Code formatting

2. **`docs/feature-development-process.md`**
   - 10-step development workflow
   - Quality gates
   - Testing requirements
   - Documentation requirements

3. **`docs/git-workflow.md`**
   - Branch naming conventions
   - Commit message format
   - User story references
   - Pull request process

### Step 2: Read Feature-Specific Standards

**Based on feature type, read these additional docs:**

| Feature Type | Standards Documents |
|--------------|---------------------|
| **database** | `docs/database-patterns.md`<br>`docs/api-patterns.md` |
| **api** | `docs/api-patterns.md`<br>`docs/async-patterns.md`<br>`docs/error-handling-patterns.md` |
| **components** | `docs/component-patterns.md`<br>`docs/styling-patterns.md` |
| **forms** | `docs/state-management-patterns.md`<br>`docs/component-patterns.md` |
| **auth** | `docs/database-patterns.md` (RLS section)<br>`docs/security-patterns.md` |
| **performance** | `docs/performance-patterns.md`<br>`docs/async-patterns.md` |
| **testing** | `docs/testing-patterns.md` |

### Step 3: Check for Feature-Specific Documentation

Look for existing documentation in:
- `docs/features/` - Feature-specific docs
- `docs/architecture.md` - System architecture
- `docs/api-design.md` - API design principles
- `README.md` - Project-specific conventions

### Step 4: Extract Key Patterns

For each document read, extract:

**From coding-standards.md:**
- Naming conventions (functions, variables, files)
- Type definition patterns
- Error handling standards
- Import/export patterns
- Code organization rules

**From database-patterns.md:**
- Table naming (snake_case, plural?)
- Column naming (snake_case, camelCase?)
- Standard columns (id, created_at, updated_at, etc.)
- Primary key pattern (UUID, SERIAL, etc.)
- Foreign key conventions
- Index naming pattern
- RLS policy patterns
- Migration file structure

**From api-patterns.md:**
- Function naming conventions
- Parameter patterns
- Return type patterns
- Error handling approach
- Async/await vs promises
- Database query patterns
- Type safety requirements

**From component-patterns.md:**
- Component file structure
- Props interface patterns
- State management approach
- Event handler naming
- Children prop patterns
- Export patterns (default vs named)
- Component composition patterns

**From state-management-patterns.md:**
- Global vs local state decisions
- Context usage patterns
- useState vs useReducer guidelines
- Custom hook patterns
- State update patterns

**From styling-patterns.md:**
- CSS approach (Tailwind, CSS Modules, etc.)
- Class naming conventions
- Responsive design patterns
- Color/spacing system
- Component variant patterns

**From testing-patterns.md:**
- Test file naming and location
- Test structure (Arrange, Act, Assert)
- Mock patterns
- Assertion patterns
- Coverage requirements

### Step 5: Present Summary

Output a structured summary:

```markdown
## Standards Review Summary

**Feature Type:** [database / api / components / forms / etc.]
**Standards Read:** X documents

---

### Core Standards

**From `docs/coding-standards.md`:**
- **Naming:** Functions use camelCase, files use kebab-case
- **Types:** All functions must have explicit return types
- **Imports:** Organize imports (React, third-party, local)
- **Errors:** Use try/catch, log errors, throw user-friendly messages
- **Formatting:** Prettier with 2-space indentation, 100-char line limit

**From `docs/feature-development-process.md`:**
- Follow 10-step process: Requirements → Architecture → Plan → Implement → Test → Document
- Must pass all quality gates before commit
- Add JSDoc comments to all public functions
- Update user story status after completion

**From `docs/git-workflow.md`:**
- Branch naming: `feature/us-XXX-description`
- Commit format: `feat(scope): description`
- Reference user story: `Implements: docs/features/us-XXX-*.md`
- Include Claude Code attribution

---

### Feature-Specific Standards

**From `docs/database-patterns.md`:**
- **Tables:** snake_case, plural (e.g., `conversations`, `user_profiles`)
- **Columns:** snake_case (e.g., `client_id`, `created_at`)
- **Primary keys:** `id UUID PRIMARY KEY DEFAULT uuid_generate_v4()`
- **Standard columns:** All tables must have `id`, `created_at`, `updated_at`
- **Foreign keys:** `<entity>_id` pattern (e.g., `client_id`, `user_id`)
- **Indexes:** `idx_<table>_<column>` (e.g., `idx_bookings_client_id`)
- **RLS naming:** `<table>_<action>_policy` (e.g., `bookings_select_policy`)
- **RLS filters:** Use `auth.uid()` for user, `auth.jwt() ->> 'client_id'` for client
- **Migrations:** `YYYYMMDDHHMMSS_description.sql` format

**From `docs/api-patterns.md`:**
- **Function naming:**
  - Get single: `get[Entity]ById(id: string): Promise<Entity | null>`
  - Get many: `getAll[Entity]s(): Promise<Entity[]>`
  - Create: `create[Entity](data: CreateData): Promise<Entity>`
  - Update: `update[Entity](id: string, data: UpdateData): Promise<Entity>`
  - Delete: `delete[Entity](id: string): Promise<void>`
- **Return types:** Always return typed promises, null for not found
- **Error handling:** Try/catch all async operations, throw descriptive errors
- **Database queries:** Use Supabase client, leverage RLS
- **Type safety:** Define interfaces for all data structures

**From `docs/component-patterns.md`:**
- **File naming:** PascalCase for components (e.g., `UserProfile.tsx`)
- **Props interface:** Define above component, named `[Component]Props`
- **State:** Use useState for local, Context for shared across tree
- **Effects:** Use useEffect for side effects, add cleanup if needed
- **Event handlers:** Prefix with `handle` (e.g., `handleSubmit`, `handleClick`)
- **Exports:** Named exports for components (not default)
- **Composition:** Break large components into smaller focused components
- **Loading states:** Always handle loading, error, and empty states

**From `docs/state-management-patterns.md`:**
- **Form state:** Use React Hook Form for forms, useState for simple inputs
- **Server state:** Use RTK Query or SWR for API data
- **UI state:** Use useState for local UI state (modals, tabs, etc.)
- **Global state:** Use Context sparingly, only for truly global data

---

### Key Takeaways

**Must follow:**
1. [Pattern 1 from standards]
2. [Pattern 2 from standards]
3. [Pattern 3 from standards]

**Must avoid:**
1. [Anti-pattern 1 from standards]
2. [Anti-pattern 2 from standards]

**Quality gates before commit:**
- [ ] Code follows all naming conventions
- [ ] Types are explicit and correct
- [ ] Error handling is comprehensive
- [ ] Tests exist and pass
- [ ] JSDoc comments added
- [ ] Build passes without errors
- [ ] Lint passes without errors

---

### Standards Checklist

Use this checklist during implementation:

**Coding:**
- [ ] Function names follow convention
- [ ] Variable names follow convention
- [ ] File names follow convention
- [ ] Types are explicit
- [ ] Imports are organized
- [ ] Error handling is comprehensive

**Database (if applicable):**
- [ ] Table names follow convention
- [ ] Column names follow convention
- [ ] Standard columns included
- [ ] Indexes added for foreign keys
- [ ] RLS policies defined
- [ ] Migration follows naming pattern

**API (if applicable):**
- [ ] Function signatures match pattern
- [ ] Return types are correct
- [ ] Error handling in all async functions
- [ ] Type definitions created
- [ ] JSDoc comments added

**Components (if applicable):**
- [ ] Component file naming correct
- [ ] Props interface defined
- [ ] Loading state handled
- [ ] Error state handled
- [ ] Empty state handled
- [ ] Event handlers named correctly
- [ ] Proper component composition

**Testing:**
- [ ] Test file created
- [ ] Happy path tested
- [ ] Error cases tested
- [ ] Edge cases tested
- [ ] Coverage meets requirements

**Documentation:**
- [ ] JSDoc comments added
- [ ] User story updated
- [ ] Implementation notes documented
- [ ] Commit message follows format
```

## Return to Calling Command

After presenting the summary, control returns to the command that called this helper.

**The calling command should:**
- Use the standards checklist during implementation
- Refer to specific patterns when writing code
- Validate against standards before completing tasks
- Ensure all quality gates are met
