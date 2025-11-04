---
description: Explore API modules, components, and code patterns
---

# Codebase Exploration Helper

This helper explores the existing codebase to understand API structure, component patterns, and reusable code.

## When to Use

Use this helper when you need to:
- Find existing API modules and functions to reuse
- Discover component patterns and UI components
- Understand code organization and file structure
- Identify similar features to use as templates

## Execution

### Step 1: Use Explore Agent for Comprehensive Discovery

**IMPORTANT:** Delegate thorough exploration to the Explore agent for best results.

Use Task tool with `subagent_type=Explore` and thoroughness level:
- **"quick"** - Basic file discovery (30 seconds)
- **"medium"** - Moderate exploration with pattern analysis (2-3 minutes)
- **"very thorough"** - Comprehensive analysis (5+ minutes)

**Recommended thoroughness:** "medium" for most cases

**Example prompts for Explore agent:**

**For API exploration:**
```
"Explore the src/api/ directory with medium thoroughness. Find all modules related to [feature area - e.g., customers, orders, bookings]. For each module, list:
1. File path and purpose
2. Exported functions with their signatures
3. Common patterns (error handling, return types, naming conventions)
4. Database queries and data access patterns
5. Type definitions used
6. Similar functions we could use as templates"
```

**For component exploration:**
```
"Explore src/components/ and src/pages/ with medium thoroughness to find components similar to [feature description]. Identify:
1. Similar page components and their structure
2. Reusable UI components (forms, lists, cards, modals, buttons)
3. State management patterns (useState, useReducer, Context, etc.)
4. Data fetching patterns (useEffect, custom hooks, RTK Query, etc.)
5. Error/loading/empty state handling patterns
6. Styling approach (Tailwind, CSS modules, styled-components, etc.)
7. Form handling (React Hook Form, native, Formik, etc.)"
```

### Step 2: Quick Manual Discovery (If Needed)

If Explore agent not available or for quick checks:

```bash
# Find API modules
find src/api -name "*.ts" -o -name "*.js" 2>/dev/null | head -20

# Find components
find src/components -name "*.tsx" -o -name "*.jsx" 2>/dev/null | head -20
find src/pages -name "*.tsx" -o -name "*.jsx" 2>/dev/null | head -20

# Find hooks
find src/hooks -name "*.ts" -o -name "*.tsx" 2>/dev/null | head -10

# Find utilities
find src/utils -name "*.ts" -o -name "*.js" 2>/dev/null | head -10
```

### Step 3: Read Similar Files (2-3 examples)

**For API patterns:**
- Read 2-3 similar API modules
- Look for function naming conventions
- Check error handling patterns
- Note return type patterns
- Check how database queries are structured

**For component patterns:**
- Read 2-3 similar components
- Check component structure and organization
- Note props and typing patterns
- Look at state management approach
- Check styling patterns
- See how forms are handled

### Step 4: Identify Reusable Code

**API Layer:**
- Existing functions that can be reused directly
- Utility functions for common operations
- Type definitions that can be imported
- Database query patterns to follow

**Component Layer:**
- UI components that can be reused (buttons, modals, cards, etc.)
- Layout components (headers, sidebars, navigation)
- Form components (inputs, selects, validation displays)
- State components (loading spinners, error messages, empty states)

### Step 5: Present Summary

Output a structured summary:

```markdown
## Codebase Exploration Summary

**Project Structure:** [React + TypeScript / Next.js / Vue / Other]
**State Management:** [useState / Redux / Zustand / Context / Other]
**Styling:** [Tailwind / CSS Modules / styled-components / Other]
**Data Fetching:** [useEffect / RTK Query / React Query / SWR / Other]

### API Layer

**Directory:** `src/api/` or `[path found]`
**Total Modules:** X

**Existing Modules:**
| Module | Functions | Pattern | Purpose |
|--------|-----------|---------|---------|
| clients.ts | 8 functions | CRUD + queries | Client management |
| bookings.ts | 12 functions | CRUD + business logic | Booking operations |
| users.ts | 6 functions | Read + auth | User data access |

**Common API Patterns:**

**Function naming:**
- Get single: `get[Entity]ById(id: string): Promise<Entity | null>`
- Get many: `getAll[Entity]s(filters?: Filters): Promise<Entity[]>`
- Create: `create[Entity](data: CreateData): Promise<Entity>`
- Update: `update[Entity](id: string, data: UpdateData): Promise<Entity>`
- Delete: `delete[Entity](id: string): Promise<void>`

**Return types:**
- Single item: `Promise<Entity | null>` (null if not found)
- Multiple items: `Promise<Entity[]>` (empty array if none)
- Operations: `Promise<Entity>` (throw on error)

**Error handling:**
```typescript
try {
  // operation
} catch (error) {
  console.error('Context:', error)
  throw new Error('User-friendly message')
}
```

**Database access:**
- Direct Supabase client: `supabase.from('table').select()`
- Query builder pattern
- RLS enforced automatically

**Reusable Functions:**
- `getClientById()` from `src/api/clients.ts` - Get client details
- `getCurrentUser()` from `src/api/users.ts` - Get authenticated user
- `handleApiError()` from `src/utils/errors.ts` - Error formatting

### Component Layer

**Directory:** `src/components/` and `src/pages/`
**Total Components:** X pages, Y components

**Similar Components Found:**

**Pages:**
- `src/pages/BookingsPage.tsx` - List page with CRUD
- `src/pages/ClientsPage.tsx` - List page with search/filter

**Reusable UI Components:**
- `<Button />` - `src/components/Button.tsx` - Styled button with variants
- `<Modal />` - `src/components/Modal.tsx` - Dialog/modal wrapper
- `<Card />` - `src/components/Card.tsx` - Content card container
- `<LoadingSpinner />` - `src/components/LoadingSpinner.tsx` - Loading indicator
- `<EmptyState />` - `src/components/EmptyState.tsx` - No data display
- `<ErrorMessage />` - `src/components/ErrorMessage.tsx` - Error display

**Form Components:**
- `<FormInput />` - Text input with label and error display
- `<FormSelect />` - Dropdown with validation
- `<FormDatePicker />` - Date picker component

**Component Patterns:**

**State management:**
```typescript
const [items, setItems] = useState<Item[]>([])
const [loading, setLoading] = useState(true)
const [error, setError] = useState<string | null>(null)
```

**Data fetching:**
```typescript
useEffect(() => {
  const fetchData = async () => {
    setLoading(true)
    try {
      const data = await getAllItems()
      setItems(data)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }
  fetchData()
}, [])
```

**Form handling:**
- React Hook Form with Zod validation
- Inline error messages
- Disabled submit during loading

**Styling:**
- Tailwind utility classes
- Consistent spacing (p-4, mb-4, etc.)
- Color system (bg-blue-500, text-gray-700, etc.)

### File Organization

**Pattern observed:**
```
src/
├── api/          - Backend API functions
├── components/   - Reusable UI components
├── pages/        - Route/page components
├── hooks/        - Custom React hooks
├── types/        - TypeScript type definitions
├── utils/        - Helper functions
└── lib/          - Third-party integrations
```

### Similar Features

**Found features similar to planned feature:**
1. **[SimilarFeature1]** - `src/pages/SimilarPage.tsx`
   - Uses same list + form pattern
   - Good template for component structure

2. **[SimilarFeature2]** - `src/components/SimilarComponent.tsx`
   - Similar data operations
   - Reusable error handling pattern

### Code to Reuse

**Can reuse directly:**
- API functions: [list specific functions]
- UI components: [list specific components]
- Hooks: [list custom hooks]
- Types: [list type definitions]

**Use as templates:**
- Component structure: [reference file]
- Form handling: [reference file]
- State management: [reference file]
```

## Return to Calling Command

After presenting the summary, control returns to the command that called this helper.

**The calling command should use this information to:**
- Identify components and APIs to reuse
- Follow established patterns in new code
- Avoid reinventing existing solutions
- Maintain consistency with existing codebase
