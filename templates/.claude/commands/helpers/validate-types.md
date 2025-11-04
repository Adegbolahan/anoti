---
description: Validate TypeScript type definitions against database schema
---

# Type Validation Helper

This helper validates TypeScript type definitions to ensure they align with database schema, follow naming conventions, and reuse existing types appropriately.

## When to Use

Use this helper when you need to:
- Validate type definitions in a plan or code
- Ensure types match database schema
- Check for type definition duplicates
- Verify naming conventions are followed

## Required Input

Provide ONE of the following:
- **Plan file path:** e.g., `docs/plans/us-XXX-plan.md`
- **Type definition code block:** TypeScript interfaces/types to validate
- **File path:** e.g., `src/types/conversations.ts`

## Execution

### Step 1: Find Existing Type Files

```bash
# Search for type definition files
find src -name "*.types.ts" -o -name "*.d.ts" 2>/dev/null | head -20
find src/types -name "*.ts" 2>/dev/null | head -20
find types -name "*.ts" 2>/dev/null | head -20
```

Read 3-5 existing type files to understand project conventions.

### Step 2: Extract Type Definitions to Validate

**From plan file:**
- Read Section 4 (API Layer Implementation) for type definitions
- Extract all `interface` and `type` definitions

**From code block:**
- Parse provided TypeScript code

**From file:**
- Read the TypeScript file

### Step 3: Get Database Schema Reference

Use `/explore-database` helper or reference database exploration done earlier in workflow.

Need to know:
- Table names and columns
- Column data types (TEXT, INTEGER, UUID, TIMESTAMPTZ, etc.)
- Nullable columns (NULL vs NOT NULL)
- Enum constraints (CHECK constraints)

### Step 4: Validate Type Definitions

Run these validation checks:

#### Check 1: Naming Conventions

✅ **Correct:**
- Interface names: PascalCase (e.g., `Conversation`, `UserProfile`)
- Property names: camelCase (e.g., `clientId`, `createdAt`)
- Type aliases: PascalCase (e.g., `ConversationType`, `Status`)

❌ **Incorrect:**
- snake_case interface names
- PascalCase property names
- snake_case matching database columns in interfaces

**Rule:** TypeScript uses camelCase for properties even if database uses snake_case. Mapping happens in API layer.

#### Check 2: Database Schema Alignment

For each interface representing a database table:

✅ **Correct:**
- All table columns represented as properties
- Property types match column types:
  - `UUID` → `string`
  - `TEXT` → `string`
  - `INTEGER` / `BIGINT` → `number`
  - `BOOLEAN` → `boolean`
  - `TIMESTAMPTZ` / `DATE` → `string` (ISO 8601 format)
  - `JSONB` → `unknown` or specific type
  - `ENUM` / `CHECK (column IN (...))` → union type: `'value1' | 'value2'`
- Nullable columns → optional properties (`property?: type`)
- NOT NULL columns → required properties (`property: type`)

❌ **Incorrect:**
- Missing columns from table
- Wrong TypeScript type for database column
- Required property for nullable column
- Optional property for NOT NULL column

#### Check 3: Enum Type Validation

For columns with CHECK constraints or ENUMs:

✅ **Correct:**
```typescript
// Database: CHECK (type IN ('voice', 'sms'))
type: 'voice' | 'sms'

// Database: status TEXT CHECK (status IN ('pending', 'active', 'completed'))
status: 'pending' | 'active' | 'completed'
```

❌ **Incorrect:**
```typescript
// Too permissive
type: string

// Typo or missing value
type: 'voice' | 'text'  // Should be 'sms', not 'text'
```

#### Check 4: Reuse Existing Types

✅ **Correct:**
- Import and reuse existing types instead of redefining
- Extend existing interfaces when adding properties
- Use utility types (Pick, Omit, Partial) when appropriate

❌ **Incorrect:**
- Redefining types that already exist elsewhere
- Duplicating common types like `User`, `Client`, `Timestamp`

**Example:**
```typescript
// ✅ Good - Reuse existing type
import { User } from './users'
interface Conversation {
  customer: User  // Reuse existing User type
}

// ❌ Bad - Redefine type
interface Conversation {
  customer: {  // Redefining what User already provides
    id: string
    name: string
  }
}
```

#### Check 5: Form Data Types

For create/update operations:

✅ **Correct:**
- Separate type for form data (input)
- Omit auto-generated fields (id, created_at, updated_at)
- Include only user-provided fields

```typescript
// Database entity
interface Conversation {
  id: string
  created_at: string
  updated_at: string
  client_id: string
  type: 'voice' | 'sms'
  notes: string
}

// Form data (what user provides)
interface ConversationFormData {
  client_id: string
  type: 'voice' | 'sms'
  notes: string
}

// Or using utility type
type ConversationFormData = Omit<Conversation, 'id' | 'created_at' | 'updated_at'>
```

❌ **Incorrect:**
- Using full entity type for create operations (includes id, timestamps)
- Missing fields that should be user-provided

### Step 5: Report Validation Results

Output findings in this format:

```markdown
## Type Validation Results

**Types Validated:** X interfaces/types
**Issues Found:** Y

---

### ✅ Passed Validations

1. ✅ Interface naming follows PascalCase convention
2. ✅ Property naming follows camelCase convention
3. ✅ Primary key `id` correctly typed as `string` (UUID)
4. ✅ Timestamps correctly typed as `string`
5. ✅ Foreign key `clientId` correctly typed as `string`
6. ✅ Reuses existing `User` type from `src/types/users.ts`

---

### ❌ Issues Found & Fixes

**Issue 1: Incorrect enum type**
- **Problem:** `type: string` - Too permissive
- **Database:** `CHECK (type IN ('voice', 'sms'))`
- **Fix:** Change to `type: 'voice' | 'sms'`

```diff
interface Conversation {
-  type: string
+  type: 'voice' | 'sms'
}
```

**Issue 2: Missing nullable indicator**
- **Problem:** `notes: string` - Marked as required
- **Database:** `notes TEXT NULL`
- **Fix:** Change to `notes?: string` (optional)

```diff
interface Conversation {
-  notes: string
+  notes?: string
}
```

**Issue 3: Wrong nullability**
- **Problem:** `clientId?: string` - Marked as optional
- **Database:** `client_id UUID NOT NULL`
- **Fix:** Change to `clientId: string` (required)

```diff
interface Conversation {
-  clientId?: string
+  clientId: string
}
```

**Issue 4: Missing standard column**
- **Problem:** Missing `updated_at` column
- **Database:** Table has `updated_at TIMESTAMPTZ DEFAULT NOW()`
- **Fix:** Add `updatedAt: string` property

```diff
interface Conversation {
   id: string
   createdAt: string
+  updatedAt: string
   clientId: string
}
```

**Issue 5: Duplicate type definition**
- **Problem:** `Client` interface redefined
- **Existing:** `src/types/clients.ts` already exports `Client`
- **Fix:** Import existing type instead

```diff
+import { Client } from './clients'
+
-interface Client {
-  id: string
-  name: string
-}
-
interface Conversation {
   client: Client
}
```

**Issue 6: Form data includes auto-generated fields**
- **Problem:** `ConversationFormData` includes `id` and timestamps
- **Fix:** Remove auto-generated fields

```diff
interface ConversationFormData {
-  id: string
-  createdAt: string
-  updatedAt: string
   clientId: string
   type: 'voice' | 'sms'
   notes?: string
}
```

---

### Corrected Type Definitions

```typescript
import { Client } from './clients'
import { User } from './users'

/**
 * Conversation entity matching database schema
 */
interface Conversation {
  id: string
  createdAt: string
  updatedAt: string
  clientId: string
  customerId: string
  type: 'voice' | 'sms'
  notes?: string
  client?: Client  // Populated via join
  customer?: User  // Populated via join
}

/**
 * Form data for creating/updating conversations
 */
interface ConversationFormData {
  clientId: string
  customerId: string
  type: 'voice' | 'sms'
  notes?: string
}

/**
 * Type alias for conversation type
 */
type ConversationType = 'voice' | 'sms'
```

---

### Type Definition Checklist

- [x] Interface names use PascalCase
- [x] Property names use camelCase
- [x] Types match database column types
- [x] Nullable columns marked optional (`?`)
- [x] NOT NULL columns marked required
- [x] Enum types use union types (`'a' | 'b'`)
- [x] Existing types reused (no duplicates)
- [x] Form data types separate from entity types
- [x] Auto-generated fields omitted from form data
- [x] JSDoc comments added for clarity
```

## Return to Calling Command

After presenting validation results, control returns to the command that called this helper.

**The calling command should:**
- Apply the corrections to the plan or code
- Update type definitions with fixes
- Re-run validation if changes were significant
- Proceed with confidence that types are correct
