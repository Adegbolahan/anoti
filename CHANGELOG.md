# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-01-22

### Breaking Changes

This release represents a complete architectural shift from a Python CLI tool to a native Claude Code plugin system.

### Removed

- `scaffold-project.py` - Python CLI scaffolding tool
- `install.sh` - Bash installer for shell aliases
- `docs/` directory - Standalone documentation files
  - `docs/development.md`
  - `docs/coding-standards.md`
  - `docs/contributing.md`
- `templates/` directory - Old template structure
  - `templates/CLAUDE.md.EXAMPLE`
  - `templates/CLAUDE.md.TEMPLATE`
  - `templates/docs/*.md`
  - `templates/.claude/commands/*.md`
- `INSTALL.md` - Old installation guide
- `QUICK-REFERENCE.md` - Quick reference card
- `WORKFLOW-OPTIMIZATION.md` - Workflow documentation

### Added

- **Plugin Marketplace** (`marketplace/`)
  - `marketplace.json` - Registry for discovering and installing plugins
  - Extensible architecture for community plugins

- **Project Scaffolder Plugin** (`project-scaffolder/`)
  - `/scaffold` command - Full project scaffolding
  - `/scaffold-minimal` command - Essential files only
  - `template-customizer` agent - Adapts templates for tech stacks
  - Workflow enforcement hooks
  - `scaffolding-guidance` skill

- **New Template Structure**
  - Templates now live in `project-scaffolder/resources/templates/`
  - Includes workflow commands, hooks, skills, and project tracking
  - Enforces story → plan → approve → build workflow

### Changed

- **Architecture**: Migrated from Python CLI to Claude Code plugin system
- **Installation**: Now uses `/plugin install` instead of shell aliases
- **Documentation**: CLAUDE.md rewritten for plugin architecture
- **Scaffolded Output**: New projects get `.claude/` directory structure instead of `docs/`

### Migration Guide

If you previously used `scaffold-project.py`:

1. Install the plugin: `/plugin install project-scaffolder@getting-started-claude-marketplace`
2. Use `/scaffold <path>` instead of `python3 scaffold-project.py <path>`
3. Use `/scaffold-minimal <path>` instead of `--minimal` flag

The scaffolded output structure has changed significantly. New projects now receive:

- `.claude/commands/` - Workflow commands
- `.claude/hooks/` - Workflow enforcement
- `.claude/skills/` - Interactive documentation
- `.claude/project/` - Feature and plan tracking

---

## [1.0.0] - 2026-01-22

### Added

- Initial release of Python scaffolding framework
- `scaffold-project.py` - Main CLI tool
- `install.sh` - Shell integration installer
- Template library with CLAUDE.md examples
- Documentation templates for git workflow, feature development, user stories
- 8 workflow slash commands
