# Documentation Standards

This document defines documentation conventions and best practices for maintaining high-quality, consistent documentation across the project.

## Table of Contents

- [Documentation Philosophy](#documentation-philosophy)
- [Documentation Types](#documentation-types)
- [Markdown Conventions](#markdown-conventions)
- [File Organization](#file-organization)
- [Writing Guidelines](#writing-guidelines)
- [Code Documentation](#code-documentation)
- [API Documentation](#api-documentation)
- [Maintenance](#maintenance)

---

## Documentation Philosophy

### Core Principles

**Documentation is for both humans and AI:**
- Write clearly for human developers joining the project
- Structure content so AI assistants (like Claude Code) can quickly understand context
- Keep critical information in dedicated files (like CLAUDE.md) for AI context

**Documentation should be:**
- **Accurate** - Always reflects current state of code
- **Concise** - Clear without unnecessary verbosity
- **Discoverable** - Easy to find when needed
- **Maintainable** - Easy to update as code changes
- **Actionable** - Provides clear next steps

### Hub-and-Spoke Pattern

Use a **hub-and-spoke** architecture for documentation:

- **Hub:** Main index file (CLAUDE.md or README.md) with overview and links
- **Spokes:** Detailed topic-specific documents in `/docs/` directory

**Benefits:**
- Main file stays scannable (under 600 lines)
- Deep detail available via links
- Easy to navigate and maintain
- Reduces duplication

---

## Documentation Types

### 1. CLAUDE.md (AI Context File)

**Purpose:** Provide AI assistants with essential project context

**Required sections:**
- Project overview and vision
- Tech stack
- Key files and their purposes
- Required reading (priority ordered)
- Common tasks
- Links to detailed documentation

**File size:** 300-500 lines (max 600)

**Example structure:**
```markdown
# CLAUDE.md

## Project Overview
[Brief description, vision, current state]

## ⚠️ CRITICAL: Read Standards BEFORE Coding
[Links to required reading, priority ordered]

## Quick Start for Claude
[Key files, tech stack, common tasks]

## Documentation Index
[Links to all spoke documents]
```

### 2. README.md (User-Facing Guide)

**Purpose:** Primary documentation for human users

**Required sections:**
- Project description
- Installation instructions
- Quick start / getting started
- Basic usage examples
- Links to detailed documentation
- Contributing guidelines
- License

**File size:** No strict limit (comprehensive guide)

**✅ GOOD README structure:**
```markdown
# Project Name

Brief description and value proposition.

## Features
- Feature 1
- Feature 2

## Installation
Step-by-step setup

## Quick Start
Minimal example to get running

## Documentation
Links to detailed docs

## Contributing
How to contribute

## License
```

### 3. Technical Documentation (/docs/)

**Purpose:** Detailed topic-specific documentation

**Common files:**
- `architecture.md` - System design, tech stack, data flow
- `development.md` - Setup, dev commands, environment
- `coding-standards.md` - Language conventions, naming patterns
- `api-patterns.md` - API design patterns
- `testing-patterns.md` - Test strategies
- `deployment.md` - Deployment procedures
- `troubleshooting.md` - Common issues and solutions

**File size:** 200-500 lines per file (max 600)

### 4. Architecture Decision Records (ADRs)

**Purpose:** Document significant architectural decisions

**Format:**
```markdown
# ADR-XXX: [Title]

**Date:** YYYY-MM-DD
**Status:** [Proposed | Accepted | Deprecated | Superseded]
**Decision Maker:** [Name/Team]

## Context
[What is the issue we're facing?]

## Decision
[What decision did we make?]

## Consequences
**Positive:**
- Benefit 1
- Benefit 2

**Negative:**
- Trade-off 1
- Trade-off 2

## Alternatives Considered
- Alternative 1: [Why rejected]
- Alternative 2: [Why rejected]
```

**Location:** `/docs/decisions/` or `/docs/adr/`

### 5. User Stories & Feature Specs

**Purpose:** Define requirements for features

**Format:** See `user-story-standards.md`

**Location:** `/docs/features/us-XXX-feature-name.md`

**Required elements:**
- User story (As a... I want... So that...)
- Acceptance criteria (checklist format)
- Implementation notes
- API specifications
- Edge cases

### 6. API Documentation

**Purpose:** Document API endpoints and usage

**Formats:**
- OpenAPI/Swagger (preferred for REST APIs)
- GraphQL schema with comments
- Markdown documentation

**Required for each endpoint:**
- HTTP method and path
- Authentication requirements
- Request parameters
- Request body schema
- Response schema
- Error responses
- Example requests/responses

**Location:** `/docs/api.md` or auto-generated from code

### 7. Inline Code Documentation

**Purpose:** Explain complex logic directly in code

**When to use:**
- Complex algorithms or business logic
- Non-obvious implementation decisions
- Workarounds for bugs/limitations
- Security-critical sections

**See:** [Code Documentation](#code-documentation) section below

---

## Markdown Conventions

### Emoji Markers

Use consistent emoji for visual scanning:

| Emoji | Meaning | Usage |
|-------|---------|-------|
| 📋 | Lists, documentation | Table of contents, documentation references |
| ✅ | Correct, success | Good examples, completed tasks, checkboxes |
| ❌ | Incorrect, error | Bad examples, anti-patterns, errors |
| ⭐ | Important, priority | Critical items, must-read sections |
| 🚨 | Critical warning | Security issues, breaking changes |
| 🔧 | Configuration, tools | Setup, installation, tooling |
| 📝 | Writing, editing | Documentation tasks, notes |
| 💡 | Tip, idea | Helpful suggestions, best practices |
| ⚠️ | Warning, caution | Warnings, gotchas, deprecated features |

**✅ GOOD emoji usage:**
```markdown
### Required Reading
- ⭐ `docs/coding-standards.md` - MANDATORY
- 📋 `docs/development.md` - Setup guide

🚨 **CRITICAL:** Never commit secrets to the repository
```

**❌ WRONG emoji usage:**
```markdown
### Required Reading
- 🎨 `docs/coding-standards.md`
- 🚀 `docs/development.md`

🎉 **CRITICAL:** Never commit secrets
```

### Code Blocks

**Always specify language identifier:**

````markdown
✅ GOOD - language specified:
```python
def create_user(name: str) -> User:
    return User(name=name)
```

```bash
npm install
npm run dev
```

❌ WRONG - no language:
```
def create_user(name):
    return User(name=name)
```
````

**Show right vs wrong examples:**

````markdown
✅ GOOD - explicit comparison:
```python
# ✅ CORRECT - type hints
def create_user(name: str, email: str) -> User:
    return User(name=name, email=email)

# ❌ WRONG - no type hints
def create_user(name, email):
    return User(name=name, email=email)
```

❌ WRONG - no context:
```python
def create_user(name: str, email: str) -> User:
    return User(name=name, email=email)
```
````

### Headings

**Use hierarchical structure (never skip levels):**

```markdown
✅ GOOD hierarchy:
# Main Title (H1) - Only one per file

## Major Section (H2)

### Subsection (H3)

#### Detail Level (H4)

❌ WRONG - skipping levels:
# Main Title

### Subsection (skipped H2)
```

**Heading guidelines:**
- Only ONE H1 per file (document title)
- Use sentence case: "Getting started" not "Getting Started"
- Be descriptive: "API authentication" not "Auth"
- Keep concise: 3-8 words ideal

### Links

**Use descriptive link text:**

```markdown
✅ GOOD links:
See [coding standards](docs/coding-standards.md) for Python conventions.

For authentication details, refer to the [API patterns guide](docs/api-patterns.md).

❌ WRONG links:
Click [here](docs/coding-standards.md) for standards.

See [this](docs/api-patterns.md) for more info.
```

**Link formats:**
- Internal docs: Relative paths `docs/file.md`
- Specific sections: `docs/file.md#section-name`
- External links: Full URLs with https://

### Tables

**Use tables for structured comparison:**

```markdown
✅ GOOD - table for structured data:
| Endpoint | Method | Auth Required | Rate Limit |
|----------|--------|---------------|------------|
| /users | GET | Yes | 100/min |
| /auth/login | POST | No | 5/min |

❌ WRONG - list for tabular data:
- /users: GET, requires auth, 100/min rate limit
- /auth/login: POST, no auth, 5/min rate limit
```

### Lists

**Use appropriate list types:**

```markdown
✅ GOOD list usage:

**Ordered lists** (sequence matters):
1. Install dependencies
2. Configure environment
3. Run migrations
4. Start server

**Unordered lists** (no sequence):
- Feature A
- Feature B
- Feature C

**Checklists** (tasks to complete):
- [ ] Write tests
- [ ] Update documentation
- [ ] Create PR

❌ WRONG - ordered list when sequence doesn't matter:
1. Feature A
2. Feature B
3. Feature C
```

### Formatting

**Bold for emphasis on key terms:**

```markdown
✅ GOOD bold usage:
**CRITICAL:** Read all standards before coding.

The **hub-and-spoke** pattern keeps docs maintainable.

❌ WRONG - overuse:
**This** is **very** **important** **information**.
```

**Code formatting for:**
- File paths: `src/components/Button.tsx`
- Variable names: `userName`
- Commands: `npm install`
- Short code snippets: `const x = 10;`

---

## File Organization

### Directory Structure

```
project-root/
├── CLAUDE.md              ← Hub for AI context
├── README.md              ← Hub for humans
├── CHANGELOG.md           ← Version history
├── CONTRIBUTING.md        ← Contribution guide
│
├── docs/                  ← Spoke documentation
│   ├── architecture.md
│   ├── development.md
│   ├── coding-standards.md
│   ├── api-patterns.md
│   ├── testing-patterns.md
│   │
│   ├── features/          ← User story specs
│   │   ├── us-001-feature.md
│   │   └── us-002-feature.md
│   │
│   └── decisions/         ← ADRs
│       ├── adr-001-database-choice.md
│       └── adr-002-auth-strategy.md
│
└── src/                   ← Source code
```

### File Naming

**Use kebab-case for markdown files:**

```bash
✅ GOOD naming:
docs/coding-standards.md
docs/api-patterns.md
docs/feature-development-process.md

❌ WRONG naming:
docs/CodingStandards.md
docs/API_Patterns.md
docs/feature_development_process.md
```

### File Size Guidelines

Keep files focused and scannable:

- **CLAUDE.md:** 300-500 lines (max 600)
- **README.md:** No strict limit (comprehensive)
- **Pattern docs:** 200-500 lines (max 600)
- **Feature specs:** 100-300 lines (max 400)
- **ADRs:** 50-200 lines

**When a file exceeds limits:**
- Split into multiple topic-specific files
- Create hub file with links to spokes
- Keep related content together

---

## Writing Guidelines

### Clarity and Conciseness

**Write clear, concise sentences:**

```markdown
✅ GOOD - clear and concise:
Use pathlib for all file operations.

Run tests before committing changes.

❌ WRONG - verbose:
When you are working with files and file paths in this project,
you should make use of the pathlib module rather than using
the older os.path module or string concatenation.
```

### Active Voice

**Use active voice for instructions:**

```markdown
✅ GOOD - active voice:
Install dependencies with `npm install`.

Run the test suite using `pytest`.

❌ WRONG - passive voice:
Dependencies should be installed using `npm install`.

The test suite can be run with `pytest`.
```

### Present Tense

**Use present tense for current state:**

```markdown
✅ GOOD - present tense:
The system validates all user inputs.

The API returns JSON responses.

❌ WRONG - future tense:
The system will validate all user inputs.
```

### Audience Awareness

**Know your audience:**

- **CLAUDE.md:** AI assistants (technical, context-focused)
- **README.md:** New users (clear, welcoming, examples)
- **Pattern docs:** Developers (technical, detailed, examples)
- **API docs:** API consumers (precise, complete schemas)

### Examples

**Always include examples:**

```markdown
✅ GOOD - with examples:
### Authentication Header

Include the JWT token in the Authorization header:

```bash
curl -H "Authorization: Bearer eyJhbGc..." https://api.example.com/users
```

❌ WRONG - no examples:
### Authentication Header

Include the JWT token in the Authorization header.
```

---

## Code Documentation

### When to Document Code

**DO document:**
- ✅ Complex algorithms or business logic
- ✅ Non-obvious implementation decisions
- ✅ Workarounds for bugs or limitations
- ✅ Security-critical sections
- ✅ Performance optimizations
- ✅ Public APIs and interfaces

**DON'T document:**
- ❌ Obvious code that explains itself
- ❌ Getters/setters with no logic
- ❌ Standard patterns already defined in coding standards

### Inline Comments

**Explain WHY, not WHAT:**

```python
✅ GOOD - explains reasoning:
# Use batch insert instead of individual inserts for 10x performance
# when importing large datasets (>1000 records)
users = User.objects.bulk_create(user_list, batch_size=1000)

❌ WRONG - states the obvious:
# Create users in batch
users = User.objects.bulk_create(user_list, batch_size=1000)
```

### Function/Method Documentation

**Python (docstrings):**
```python
✅ GOOD docstring:
def create_user(name: str, email: str, role: str = "user") -> User:
    """
    Create a new user with the given details.

    Args:
        name: Full name of the user
        email: User's email address (must be unique)
        role: User role - one of: "user", "admin", "moderator"
              Defaults to "user"

    Returns:
        User object with generated ID and timestamps

    Raises:
        ValidationError: If email is invalid or already exists
        PermissionError: If role is "admin" and caller is not superuser
    """
    pass
```

**TypeScript (JSDoc):**
```typescript
✅ GOOD JSDoc:
/**
 * Fetch user data from the API with error handling and retries.
 *
 * @param userId - The unique identifier of the user
 * @param options - Optional configuration
 * @param options.includeDeleted - Include soft-deleted users
 * @param options.maxRetries - Maximum retry attempts (default: 3)
 * @returns Promise resolving to User object
 * @throws {NotFoundError} If user doesn't exist
 * @throws {NetworkError} If all retry attempts fail
 *
 * @example
 * ```typescript
 * const user = await fetchUser('user-123', { includeDeleted: true });
 * ```
 */
async function fetchUser(
  userId: string,
  options?: { includeDeleted?: boolean; maxRetries?: number }
): Promise<User> {
  // implementation
}
```

### TODO Comments

**Use structured TODO comments:**

```python
✅ GOOD TODO:
# TODO(username, 2024-03-15): Optimize this query using select_related()
# Current implementation causes N+1 queries for large datasets
# See: https://github.com/org/repo/issues/123

❌ WRONG TODO:
# TODO: fix this
```

---

## API Documentation

### REST API Endpoints

**Document each endpoint completely:**

```markdown
### POST /api/users

Create a new user account.

**Authentication:** Required (JWT)

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "role": "user"
}
```

**Response (201 Created):**
```json
{
  "id": "user-123",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "user",
  "created_at": "2024-03-15T10:30:00Z"
}
```

**Error Responses:**

400 Bad Request - Invalid input
```json
{
  "error": "validation_error",
  "message": "Invalid email format",
  "field": "email"
}
```

409 Conflict - Email already exists
```json
{
  "error": "duplicate_email",
  "message": "User with this email already exists"
}
```

**Rate Limit:** 10 requests/minute
```

### GraphQL APIs

**Document with schema comments:**

```graphql
type User {
  """Unique identifier for the user"""
  id: ID!

  """User's full name"""
  name: String!

  """
  User's email address
  Must be unique across all users
  """
  email: String!

  """
  User role determining permissions
  Possible values: USER, ADMIN, MODERATOR
  """
  role: Role!
}

"""
Create a new user account

Requires authentication with ADMIN role
"""
createUser(input: CreateUserInput!): User!
```

---

## Maintenance

### Keeping Documentation Updated

**When to update docs:**

| Code Change | Documentation to Update |
|-------------|------------------------|
| Add new feature | README.md, CLAUDE.md, feature spec, API docs |
| Change API | API docs, relevant pattern docs |
| Refactor architecture | architecture.md, CLAUDE.md |
| Update dependencies | development.md, README.md |
| Fix bug | CHANGELOG.md, troubleshooting.md (if common) |
| Change conventions | Relevant pattern docs, coding-standards.md |

### Documentation in Pull Requests

**PR checklist:**
- [ ] Updated CHANGELOG.md with changes
- [ ] Updated relevant technical docs
- [ ] Updated CLAUDE.md if architecture changed
- [ ] Updated README.md if user-facing behavior changed
- [ ] Added/updated code comments for complex logic
- [ ] Updated API docs if endpoints changed

### Deprecation Notices

**When deprecating features:**

```markdown
⚠️ **DEPRECATED:** This endpoint is deprecated as of v2.0.0 and will be
removed in v3.0.0. Use `/api/v2/users` instead.

**Migration guide:** [Link to migration documentation]

**Removal date:** Planned for 2024-12-31
```

### Changelog

**Use Keep a Changelog format:**

```markdown
# Changelog

## [Unreleased]

### Added
- User avatar upload feature

### Changed
- Updated authentication to use JWT instead of sessions

### Deprecated
- `/api/v1/auth/login` endpoint (use `/api/v2/auth/login`)

### Removed
- Legacy XML API endpoints

### Fixed
- Fixed race condition in user registration

### Security
- Patched SQL injection vulnerability in search

## [1.2.0] - 2024-03-15

...
```

---

## Quality Checklist

Before merging documentation changes, verify:

**Content:**
- [ ] Accurate (reflects current code state)
- [ ] Complete (covers all important aspects)
- [ ] Clear (no ambiguity)
- [ ] Concise (no unnecessary verbosity)
- [ ] Examples included for complex topics

**Structure:**
- [ ] Follows hub-and-spoke pattern
- [ ] File sizes within guidelines
- [ ] Proper heading hierarchy
- [ ] Table of contents for long files (>200 lines)

**Formatting:**
- [ ] Language specified for all code blocks
- [ ] Consistent emoji usage
- [ ] Descriptive link text
- [ ] Tables used for tabular data
- [ ] Proper list types (ordered/unordered/checklist)

**Maintenance:**
- [ ] Links work (no 404s)
- [ ] Code examples are tested and working
- [ ] No outdated information
- [ ] CHANGELOG.md updated

---

## Further Reading

- **Markdown Guide:** https://www.markdownguide.org/
- **CommonMark Spec:** https://spec.commonmark.org/
- **Keep a Changelog:** https://keepachangelog.com/
- **Architecture Decision Records:** https://adr.github.io/

---

**This document should evolve as the project grows. Update it when new patterns emerge or standards change.**
