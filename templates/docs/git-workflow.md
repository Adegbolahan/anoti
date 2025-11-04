# Git Workflow

This document defines the Git workflow and conventions for the TaadaB Logistics platform.

---

## Branching Strategy

**Model:** Feature branches with protected main

### Branch Naming Conventions

- **Feature branches:** `feature/<short-description>`
- **Bug fixes:** `fix/<issue-description>`
- **Hotfixes:** `hotfix/<issue-description>`
- **Chores:** `chore/<task-description>`

**Examples:**
```bash
feature/conversation-list
fix/rls-policy-appointments
hotfix/twilio-webhook-timeout
chore/update-dependencies
```

### Protected Branches

- **`main`** - Production-ready code (requires PR review)
- **`staging`** - Staging environment (optional)

---

## Commit Conventions

**Format:** Conventional Commits with User Story Reference

```
<type>: <subject>

<body>

Implements: docs/features/<user-story-file>.md

<footer>
```

### Commit Types

- **`feat:`** - New feature
- **`fix:`** - Bug fix
- **`refactor:`** - Code refactoring (no functional change)
- **`test:`** - Add or update tests
- **`docs:`** - Documentation changes
- **`chore:`** - Maintenance tasks (dependencies, config)
- **`style:`** - Code style changes (formatting)
- **`perf:`** - Performance improvements

### User Story Reference (REQUIRED)

**All commits implementing user stories MUST reference the user story file:**

- Add `Implements: docs/features/us-XXX-<story-name>.md` in the commit footer
- Use the exact filename from `/docs/features/`
- Place before the Claude Code footer (if applicable)
- For commits implementing multiple stories, list all files

**Why This Matters:**
- Provides traceability between code changes and requirements
- Makes it easy to find commits for a specific user story
- Helps with code review (reviewers can check against acceptance criteria)
- Updates `docs/high-level-user-stories.md` require commit hash + story reference

### Examples

**Simple commit:**
```bash
git commit -m "feat: add conversation list component

Implements: docs/features/us-013-conversation-log-list.md"
```

**Detailed commit:**
```bash
git commit -m "feat: add conversation list with filtering

- Implement ConversationList component with RTK Query
- Add filters for type (voice/sms) and search
- Handle loading, error, and empty states
- Add pagination (50 per page)
- Tests: 85% coverage

Implements: docs/features/us-013-conversation-log-list.md

 


```

**Multiple user stories:**
```bash
git commit -m "feat: implement appointments UI

- Working hours management page (US-010)
- Appointment booking component (US-011)
- Calendar sync panel (US-012)
- RTK Query hooks for all endpoints
- Tests: 75% coverage

Implements: docs/features/us-010-manage-working-hours.md
Implements: docs/features/us-011-appointment-booking-tool.md
Implements: docs/features/us-012-calendar-sync.md

 


```

**Non-user-story commits (chores, fixes):**
```bash
# For commits not tied to a user story, Implements line is optional
git commit -m "chore: update dependencies

- Bump React to 18.3.0
- Update Tailwind to 3.4.0
- Fix security vulnerabilities"
```

---

## Pre-Commit Hooks

Pre-commit hooks run automatically before each commit to ensure code quality.

### Frontend (React + TypeScript)

**Setup:**
```bash
cd frontend
npm install    # Installs husky + lint-staged
npm run prepare # Sets up Husky hooks
```

**Runs on commit:**
- ESLint with auto-fix
- Prettier formatting
- TypeScript type checking

### AI Runtime (Node.js + TypeScript)

**Setup:**
```bash
cd ai_runtime
npm install    # Installs husky + lint-staged
npm run prepare # Sets up Husky hooks
```

**Runs on commit:**
- ESLint with auto-fix
- Prettier formatting
- TypeScript type checking

### Backend (Python + FastAPI)

**Setup:**
```bash
cd backend
uv pip install -r requirements-dev.txt  # Installs pre-commit
pre-commit install                       # Sets up hooks
```

**Runs on commit:**
- Black (code formatting)
- isort (import sorting)
- Flake8 (linting)
- mypy (type checking)
- Security checks (detect private keys, large files)

### IMPORTANT

- **NEVER** use `--no-verify` to bypass hooks unless absolutely necessary
- Fix all issues before committing (hooks help catch bugs early)
- Only bypass hooks if explicitly requested by user or in emergency
- Hooks are configured per-repo (each service has its own)
- Write descriptive commit messages following Conventional Commits format

---

## Merge Strategy

**Strategy:** Squash and merge (keeps main branch clean)

### Why Squash and Merge?

- ✅ Clean commit history on main
- ✅ One commit per feature/fix
- ✅ Easier to revert entire features
- ✅ Better for release notes generation

---

## Pull Request Process

### 1. Create Feature Branch

```bash
git checkout main
git pull origin main
git checkout -b feature/conversation-list
```

### 2. Make Changes

```bash
# Make your changes
git add <files>
git commit -m "feat: add conversation list"

# Continue development
git add <files>
git commit -m "test: add conversation list tests"
```

### 3. Keep Branch Updated

```bash
# Fetch latest changes
git fetch origin main

# Rebase your branch (preferred)
git rebase origin/main

# Or merge (if you prefer)
git merge origin/main
```

### 4. Push to Remote

```bash
git push origin feature/conversation-list
```

### 5. Create Pull Request

**PR Title:** Same format as commit messages
```
feat: add conversation list with filtering
```

**PR Description Template:**
```markdown
## Description
Brief description of changes

## Related User Story
**Implements:** `docs/features/us-XXX-<story-name>.md`

- Closes #123 (if applicable)
- See detailed spec: [US-XXX](../docs/features/us-XXX-<story-name>.md)

## Changes Made
- [ ] Implemented ConversationList component
- [ ] Added RTK Query integration
- [ ] Added filters and search
- [ ] Added pagination
- [ ] Wrote tests (85% coverage)

## Acceptance Criteria Status
_From `docs/features/us-XXX-<story-name>.md`:_
- [ ] AC1: Users can view paginated list of conversations
- [ ] AC2: Users can filter by type (voice/sms)
- [ ] AC3: Users can search conversations
- [ ] AC4: Loading/error/empty states handled
- [ ] AC5: Performance: <500ms load time

## Testing
- [ ] Unit tests pass (XX% coverage)
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Acceptance criteria verified
- [ ] Accessibility tested

## Screenshots (if applicable)
[Add screenshots here]

## Checklist
- [ ] Code follows coding standards
- [ ] Tests written and passing (75%+ coverage)
- [ ] Documentation updated
- [ ] No secrets committed
- [ ] RLS policies tested (if database changes)
- [ ] Updated `docs/high-level-user-stories.md` with commit hash
```

### 6. Code Review

**Reviewer checklist:**
- [ ] Code follows standards
- [ ] Tests comprehensive
- [ ] No security issues
- [ ] Performance acceptable
- [ ] Documentation updated

### 7. Merge

Once approved:
1. Ensure CI passes
2. Squash and merge to main
3. Delete feature branch

---

## Working with Claude Code

When Claude Code creates commits:

### Automatic Co-Authoring

Claude Code automatically adds:
```
 

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Review Before Pushing

**ALWAYS review commits before pushing:**
```bash
# View last commit
git log -1

# View changes in last commit
git show

# Amend commit if needed
git commit --amend
```

---

## Common Git Operations

### Undo Last Commit (Keep Changes)

```bash
git reset --soft HEAD~1
```

### Undo Last Commit (Discard Changes)

```bash
git reset --hard HEAD~1
```

### View Branch History

```bash
git log --oneline --graph --all
```

### Stash Changes

```bash
# Stash current changes
git stash

# List stashes
git stash list

# Apply latest stash
git stash pop

# Apply specific stash
git stash apply stash@{0}
```

### Cherry-Pick Commit

```bash
git cherry-pick <commit-hash>
```

### Rebase Interactive

```bash
# Rebase last 3 commits
git rebase -i HEAD~3
```

---

## Merge Conflicts

### Resolving Conflicts

```bash
# Pull latest changes
git pull origin main

# Conflicts occur - resolve manually
# Edit conflicted files

# Mark as resolved
git add <resolved-files>

# Continue rebase/merge
git rebase --continue
# OR
git merge --continue
```

### Abort Merge/Rebase

```bash
git rebase --abort
# OR
git merge --abort
```

---

## Release Process

### Creating a Release

```bash
# Tag release
git tag -a v1.0.0 -m "Release v1.0.0"

# Push tag
git push origin v1.0.0
```

### Hotfix Process

```bash
# Create hotfix branch from main
git checkout main
git checkout -b hotfix/critical-bug

# Make fix
git commit -m "hotfix: fix critical bug"

# Merge to main (via PR)
# Tag release
git tag -a v1.0.1 -m "Hotfix v1.0.1"
git push origin v1.0.1
```

---

## Best Practices

### DO

- ✅ Write descriptive commit messages
- ✅ Commit frequently (small, logical commits)
- ✅ Pull before pushing
- ✅ Keep branches short-lived (< 1 week)
- ✅ Review your own PR before requesting review
- ✅ Run tests before pushing

### DON'T

- ❌ Commit secrets or API keys
- ❌ Force push to main/staging
- ❌ Commit large binary files
- ❌ Use `git add .` blindly (review changes first)
- ❌ Bypass pre-commit hooks without reason
- ❌ Leave branches unmerged for weeks

---

## Related Documents

- **Feature Development Process:** See `docs/feature-development-process.md`
- **Coding Standards:** See `docs/coding-standards.md`
- **Development Guide:** See `docs/development.md`
