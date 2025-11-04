---
description: Explore database schema, tables, RLS policies, and indexes
---

# Database Exploration Helper

This helper explores the current database state to understand tables, columns, indexes, RLS policies, and relationships.

## When to Use

Use this helper when you need to:
- Understand current database schema before planning changes
- Validate that tables/columns exist before referencing them
- Check RLS policies before designing security
- Find migration patterns to follow

## Execution

### Step 1: Find Migration Files

```bash
# Search for migration directories and files
find . -type d -name "migrations" 2>/dev/null | head -5
find . -name "*.sql" -path "*/migrations/*" 2>/dev/null | sort | tail -10
find . -name "schema.prisma" 2>/dev/null
```

### Step 2: Query Database (If MCP Tools Available)

**Check if MCP database tools are available first.**

If available, run these queries:

```sql
-- List all tables
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Get table columns (replace 'table_name' with actual tables found)
SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name IN ('users', 'clients', 'bookings', 'conversations')
ORDER BY table_name, ordinal_position;

-- Check indexes
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Check RLS policies
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Check foreign key relationships
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;
```

### Step 3: Read Migration Files (Fallback)

If no MCP database tools available:

1. Read the most recent 5-10 migration files to understand schema
2. Look for CREATE TABLE statements
3. Look for ALTER TABLE statements
4. Look for CREATE INDEX statements
5. Look for RLS policy statements (CREATE POLICY, ALTER TABLE ENABLE ROW LEVEL SECURITY)

### Step 4: Identify Patterns

From the migrations/schema found, identify:

- **Naming conventions:**
  - Table names: snake_case? plural?
  - Column names: snake_case? camelCase?
  - Index naming: `idx_table_column`? `table_column_idx`?

- **Standard columns:**
  - Primary keys: `id UUID`, `id SERIAL`?
  - Timestamps: `created_at`, `updated_at`?
  - Soft deletes: `deleted_at`?
  - User tracking: `created_by`, `updated_by`?

- **RLS patterns:**
  - Policy naming conventions
  - Common filters (user_id, client_id, tenant_id)
  - Permissive vs restrictive policies

### Step 5: Present Summary

Output a structured summary:

```markdown
## Database Exploration Summary

**Migration System:** [Supabase / Prisma / Raw SQL / Other]
**Total Tables Found:** X
**RLS Enabled:** [Yes/No/Partial]

### Tables

| Table | Columns | Primary Key | Has RLS | Purpose |
|-------|---------|-------------|---------|---------|
| users | 8 | id (UUID) | Yes | User accounts |
| clients | 12 | id (UUID) | Yes | Client management |
| bookings | 15 | id (UUID) | Yes | Booking records |

### Key Relationships

- `bookings.client_id` → `clients.id`
- `bookings.user_id` → `users.id`
- `conversations.client_id` → `clients.id`

### Naming Conventions

**Tables:** snake_case, plural (e.g., `user_profiles`, `booking_items`)
**Columns:** snake_case (e.g., `created_at`, `client_id`)
**Indexes:** `idx_<table>_<column>` (e.g., `idx_bookings_client_id`)

### Standard Columns Pattern

All tables include:
- `id UUID PRIMARY KEY DEFAULT uuid_generate_v4()`
- `created_at TIMESTAMPTZ DEFAULT NOW()`
- `updated_at TIMESTAMPTZ DEFAULT NOW()`

### RLS Patterns

**Policy naming:** `<table>_<action>_policy` (e.g., `bookings_select_policy`)
**Common filters:**
- User-specific: `user_id = auth.uid()`
- Client-specific: `client_id = (auth.jwt() ->> 'client_id')::uuid`
- Public read: `true` for SELECT policies

### Indexes Found

- Performance indexes on foreign keys
- Composite indexes on frequently queried columns
- BTREE indexes (default)

### Migration File Locations

- Directory: `supabase/migrations/` or `[path found]`
- Pattern: `YYYYMMDDHHMMSS_description.sql`
- Recent migrations: [list 3-5 most recent]
```

## Return to Calling Command

After presenting the summary, control returns to the command that called this helper.

**The calling command should use this information to:**
- Design new tables that follow existing patterns
- Reference existing tables correctly
- Plan RLS policies that match project security model
- Create migrations with proper naming conventions
