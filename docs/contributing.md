# Contributing Guide

Thank you for your interest in contributing to Getting Started with Claude! This document explains how to contribute effectively.

## Table of Contents

- [Ways to Contribute](#ways-to-contribute)
- [Before You Start](#before-you-start)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Code Review](#code-review)

---

## Ways to Contribute

### 📝 Documentation Improvements
- Fix typos or unclear explanations
- Add examples or use cases
- Improve template content
- Translate documentation

### 🔧 Template Enhancements
- Add new generic template files
- Improve existing templates
- Add code examples to pattern docs
- Create tech-stack-specific variants

### 🚀 Scaffolder Features
- Add CLI options or modes
- Improve error handling
- Add validation logic
- Enhance user output

### 🐛 Bug Fixes
- Fix template errors
- Correct scaffolder logic
- Fix installer issues
- Address edge cases

### 💡 Feature Requests
- Propose new features
- Suggest improvements
- Share use cases

---

## Before You Start

### Read the Documentation

**Required reading:**
1. **`CLAUDE.md`** - Project overview and standards
2. **`docs/development.md`** - Architecture and setup
3. **`docs/coding-standards.md`** - Code conventions

### Check Existing Work

Before starting:
- Search existing issues and PRs
- Check if someone is already working on it
- Discuss major changes in an issue first

### Understand the Standards

This project follows its own documentation standards. Your contribution should:
- Follow Python/Bash/Markdown conventions (see `docs/coding-standards.md`)
- Match existing patterns and style
- Include appropriate tests
- Update documentation as needed

---

## Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR-USERNAME/getting-started-claude.git
cd getting-started-claude
```

### 2. Create Feature Branch

```bash
# Create branch from main
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/issue-description
```

### 3. Test Current State

```bash
# Test scaffolder before making changes
python3 scaffold-project.py /tmp/test-before

# Verify current behavior
ls -la /tmp/test-before
cat /tmp/test-before/CLAUDE.md

# Keep this for comparison later
```

---

## Making Changes

### Development Workflow

1. **Make your changes**
   - Edit relevant files
   - Follow coding standards
   - Add comments explaining complex logic

2. **Test your changes**
   ```bash
   # Test after modifications
   python3 scaffold-project.py /tmp/test-after

   # Compare with before
   diff -r /tmp/test-before /tmp/test-after

   # Test minimal mode
   python3 scaffold-project.py /tmp/test-minimal --minimal
   ```

3. **Validate templates**
   - Check line counts
   - Preview markdown in VSCode
   - Verify no broken links
   - Check placeholder consistency

4. **Update documentation**
   - Update README.md for user-facing changes
   - Update QUICK-REFERENCE.md for new tasks
   - Update relevant docs/ files

### Commit Guidelines

**Use Conventional Commits format:**

```bash
git commit -m "feat: add database-patterns template

- Created PostgreSQL patterns template
- Includes RLS examples and query patterns
- Added to GENERIC_DOCS list

 

```

**Commit types:**
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation only
- `refactor:` - Code improvements
- `chore:` - Maintenance tasks
- `test:` - Testing improvements

---

## Testing Requirements

### Pre-Commit Testing Checklist

**For scaffolder changes:**
```bash
# 1. Test full mode
python3 scaffold-project.py /tmp/test-full
[ -f /tmp/test-full/CLAUDE.md ] && echo "✅ CLAUDE.md created"
[ -f /tmp/test-full/docs/git-workflow.md ] && echo "✅ Generic docs copied"

# 2. Test minimal mode
python3 scaffold-project.py /tmp/test-minimal --minimal
[ -f /tmp/test-minimal/CLAUDE.md ] && echo "✅ CLAUDE.md created"
[ ! -f /tmp/test-minimal/docs/architecture.md ] && echo "✅ No placeholders"

# 3. Verify no breaking changes
diff -r /tmp/test-before /tmp/test-full

# 4. Clean up
rm -rf /tmp/test-full /tmp/test-minimal
```

**For template changes:**
```bash
# Check line counts
wc -l templates/CLAUDE.md.EXAMPLE  # Should be ~400-500
wc -l templates/docs/*.md          # Should be 200-500 each

# Validate markdown
# - Use VSCode preview
# - Check for broken links
# - Verify code block language identifiers
# - Check emoji consistency
```

**For installer changes:**
```bash
# Test installer (review output first)
bash install.sh

# Verify aliases added
grep "Claude Code Scaffolder" ~/.zshrc

# Test aliases work
claude-scaffold --help
```

### What to Test

- [ ] Scaffolder creates expected files
- [ ] Templates have correct content
- [ ] No broken links in markdown
- [ ] Line counts within limits
- [ ] No Python/Bash syntax errors
- [ ] Error messages are clear
- [ ] Documentation is updated

---

## Pull Request Process

### 1. Push Your Branch

```bash
git push origin feature/your-feature-name
```

### 2. Create Pull Request

On GitHub:
1. Click "New Pull Request"
2. Select your branch
3. Fill out the PR template

### 3. PR Description Template

```markdown
## Description
Brief description of what this PR does.

## Changes Made
- Added X feature
- Fixed Y bug
- Updated Z documentation

## Testing Done
- [ ] Tested full scaffolding mode
- [ ] Tested minimal scaffolding mode
- [ ] Verified template line counts
- [ ] Checked markdown formatting
- [ ] Updated relevant documentation

## Related Issues
Fixes #123
Relates to #456

## Screenshots (if applicable)
[Before/after screenshots for template changes]
```

### 4. Review Process

- Maintainers will review your PR
- Address any feedback
- Make requested changes
- Push updates to your branch

### 5. Merge

Once approved:
- PR will be merged by maintainers
- Your branch can be deleted
- Changes will be in main branch

---

## Code Review

### Review Checklist

**Code Quality:**
- [ ] Follows coding standards (see `docs/coding-standards.md`)
- [ ] Uses pathlib for paths
- [ ] Includes type hints (Python)
- [ ] POSIX-compliant (Bash)
- [ ] Clear variable names
- [ ] Appropriate comments

**Templates:**
- [ ] Line counts within limits
- [ ] Consistent emoji markers
- [ ] Code blocks have language identifiers
- [ ] No broken links
- [ ] Placeholder syntax consistent: `[placeholder]`

**Testing:**
- [ ] Manual testing completed
- [ ] No breaking changes
- [ ] Error handling tested
- [ ] Edge cases considered

**Documentation:**
- [ ] README.md updated (if user-facing)
- [ ] QUICK-REFERENCE.md updated (if new task)
- [ ] Relevant docs/ files updated
- [ ] Changelog updated (if significant)

**Git:**
- [ ] Conventional Commits format
- [ ] Clear commit messages
- [ ] Logical commit organization
- [ ] No merge commits (rebase if needed)

---

## Common Contribution Scenarios

### Adding a New Generic Template

**Example: Add deployment-guide.md**

1. **Create template:**
   ```bash
   touch templates/docs/deployment-guide.md
   # Write content following coding standards
   ```

2. **Update scaffolder:**
   ```python
   # Edit scaffold-project.py
   GENERIC_DOCS = [
       'git-workflow.md',
       'feature-development-process.md',
       'user-story-standards.md',
       'deployment-guide.md',  # NEW
   ]
   ```

3. **Test:**
   ```bash
   python3 scaffold-project.py /tmp/test
   cat /tmp/test/docs/deployment-guide.md
   ```

4. **Document:**
   - Update README.md "What Gets Created" section
   - Add to CLAUDE.md.EXAMPLE documentation index

### Improving Existing Template

**Example: Enhance CLAUDE.md.EXAMPLE**

1. **Edit template:**
   ```bash
   code templates/CLAUDE.md.EXAMPLE
   ```

2. **Check line count:**
   ```bash
   wc -l templates/CLAUDE.md.EXAMPLE  # Keep under 500
   ```

3. **Test scaffolding:**
   ```bash
   python3 scaffold-project.py /tmp/test
   cat /tmp/test/CLAUDE.md  # Verify changes
   ```

4. **Update teaching template:**
   - Also update `CLAUDE.md.TEMPLATE` if relevant
   - Add explanations for new sections

### Fixing a Bug

**Example: Fix installer issue**

1. **Reproduce bug:**
   ```bash
   bash install.sh  # See the error
   ```

2. **Fix issue:**
   ```bash
   code install.sh  # Make changes
   ```

3. **Test fix:**
   ```bash
   bash install.sh  # Verify fixed
   grep "aliases" ~/.zshrc  # Verify correct
   ```

4. **Document:**
   - Add to README.md troubleshooting if common
   - Update INSTALL.md if installation-related

---

## Getting Help

**Questions about contributing?**
- Open an issue with your question
- Tag with `question` label
- Describe what you want to contribute

**Stuck on something?**
- Check `docs/development.md` for architecture
- Review `docs/coding-standards.md` for conventions
- Look at existing code for patterns
- Ask in an issue or PR comment

**Want to discuss a major change?**
- Open an issue first
- Describe the change and rationale
- Get feedback before implementing
- Avoid wasted effort on rejected changes

---

## Code of Conduct

**Be respectful:**
- Constructive feedback only
- Assume good intentions
- Help each other learn
- Celebrate contributions

**Be patient:**
- Maintainers may take time to review
- Provide context for your changes
- Address feedback promptly
- Iterate based on suggestions

---

## Recognition

All contributors will be:
- Listed in project credits
- Mentioned in release notes
- Appreciated for their work

Thank you for contributing! 🎉

---

## Further Reading

- **`docs/development.md`** - Architecture and development workflow
- **`docs/coding-standards.md`** - Code conventions and patterns
- **`README.md`** - User documentation
- **`QUICK-REFERENCE.md`** - Common tasks

---

**Ready to contribute?** Fork the repo and start coding!
