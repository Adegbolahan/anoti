# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Getting Started with Claude** is a plugin marketplace and collection of Claude Code plugins for project scaffolding, documentation, and development workflows.

**Vision:** "Every new project starts with comprehensive, maintainable documentation that enables both humans and AI to understand and contribute effectively."

**Current State:** This repository contains a **plugin marketplace** and the **project-scaffolder plugin** for bootstrapping new projects with Claude Code workflows.

### Target Users

**Primary Market:** Software developers and engineering teams who want:

- AI-assisted development workflows with Claude Code
- Consistent documentation standards across projects
- Structured feature development processes
- Quick project setup without boilerplate

---

## Repository Structure

```
getting-started-claude/
├── CLAUDE.md                     # This file - project hub
├── README.md                     # User documentation
├── CHANGELOG.md                  # Version history
├── marketplace/                  # Plugin marketplace registry
│   ├── .claude-plugin/
│   │   └── marketplace.json      # Registry of available plugins
│   └── README.md                 # Marketplace documentation
└── project-scaffolder/           # Main scaffolding plugin
    ├── .claude-plugin/
    │   └── plugin.json           # Plugin manifest
    ├── commands/                 # /scaffold, /scaffold-minimal
    ├── agents/                   # template-customizer agent
    ├── hooks/                    # Workflow enforcement
    ├── skills/                   # scaffolding-guidance skill
    └── resources/templates/      # Template files
```

---

## Quick Start for Claude

### Key Components

| Component              | Purpose                                    | Location                                  |
| ---------------------- | ------------------------------------------ | ----------------------------------------- |
| **Marketplace**        | Plugin registry for discovery/installation | `marketplace/`                            |
| **Project Scaffolder** | Main plugin - scaffolds new projects       | `project-scaffolder/`                     |
| **Templates**          | Files copied to new projects               | `project-scaffolder/resources/templates/` |

### Plugin Commands

| Command                    | Description                                |
| -------------------------- | ------------------------------------------ |
| `/scaffold <path>`         | Full project structure with all components |
| `/scaffold-minimal <path>` | Essential files only                       |

### What Gets Scaffolded

New projects receive:

- `CLAUDE.md` - Project documentation hub
- `.claude-plugin/plugin.json` - Plugin manifest
- `.claude/commands/` - 6 workflow commands
- `.claude/hooks/hooks.json` - Workflow enforcement
- `.claude/skills/` - 3 interactive skills
- `.claude/project/` - Feature/plan tracking

---

## Development Workflow

### For EVERY Change:

1. **Understand the component** - Read existing code before modifying
2. **Make changes** - Follow established patterns
3. **Test locally** - Install plugin and test commands
4. **Verify output** - Run `/scaffold` on test project
5. **Document** - Update README.md if user-facing

### Testing Plugins Locally

```bash
# Run Claude Code with the plugin directory
claude --plugin-dir /path/to/project-scaffolder

# Or symlink to plugins directory
ln -s /path/to/project-scaffolder ~/.claude/plugins/project-scaffolder
```

### Modifying Templates

1. Edit files in `project-scaffolder/resources/templates/`
2. Test by running `/scaffold` on a test project
3. Verify generated files have correct structure
4. Check placeholder replacement works (`[PROJECT_NAME]`, etc.)

---

## Architecture & Design

### Plugin Structure

Each plugin follows Claude Code conventions:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Manifest (required)
├── commands/                # Slash commands (*.md)
├── agents/                  # Specialized agents (*.md)
├── hooks/                   # Event hooks (hooks.json)
├── skills/                  # Interactive skills (*/SKILL.md)
└── resources/               # Static assets
```

### Marketplace Architecture

The marketplace (`marketplace/.claude-plugin/marketplace.json`) registers plugins:

```json
{
  "plugins": [
    {
      "name": "plugin-name",
      "source": "../plugin-directory",
      "category": "development"
    }
  ]
}
```

### Scaffolded Project Workflow

Projects created by `/scaffold` enforce:

```
1. Story  → Create in .claude/project/features/
2. Plan   → Create in .claude/project/plans/
3. Approve → Get user approval before coding
4. Build  → Implement following the plan
```

This is enforced via hooks in `.claude/hooks/hooks.json`.

---

## Plugin Components

### Commands (`project-scaffolder/commands/`)

| File                  | Command             | Purpose                              |
| --------------------- | ------------------- | ------------------------------------ |
| `scaffold.md`         | `/scaffold`         | Full scaffolding with all components |
| `scaffold-minimal.md` | `/scaffold-minimal` | Essential files only                 |

### Agents (`project-scaffolder/agents/`)

| File                     | Purpose                                   |
| ------------------------ | ----------------------------------------- |
| `template-customizer.md` | Adapts templates for specific tech stacks |

### Hooks (`project-scaffolder/hooks/`)

| Event              | Purpose                                  |
| ------------------ | ---------------------------------------- |
| `UserPromptSubmit` | Enforces story → plan workflow           |
| `SessionStart`     | Offers to create tracking if missing     |
| `PreToolUse`       | Validates file naming conventions        |
| `PostToolUse`      | Updates tracking after file changes      |
| `Stop`             | Ensures status updates before completion |

### Skills (`project-scaffolder/skills/`)

| Skill                  | Triggers                                |
| ---------------------- | --------------------------------------- |
| `scaffolding-guidance` | "How to scaffold?", "Plugin structure?" |

---

## Git Workflow

**Branching:** Feature branches (`feature/<description>`)

**Commits:** Conventional Commits format

```bash
git commit -m "feat: add new template component

- Added X functionality
- Updated Y for consistency

"
```

**Types:** `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`

---

## Contributing

### Add a New Plugin

1. Create plugin directory with `.claude-plugin/plugin.json`
2. Add commands, agents, hooks, or skills as needed
3. Include README with usage instructions
4. Register in `marketplace/.claude-plugin/marketplace.json`
5. Submit pull request

### Modify Existing Plugin

1. Read existing code to understand patterns
2. Make changes following established conventions
3. Test locally with `claude --plugin-dir`
4. Update version in plugin.json if significant
5. Document changes in CHANGELOG.md

### Plugin Requirements

- Must have `.claude-plugin/plugin.json` manifest
- Must include README with usage instructions
- Should follow Claude Code conventions
- Must not include malicious code

---

## Documentation Index

| File                           | Purpose                              |
| ------------------------------ | ------------------------------------ |
| `README.md`                    | User guide - installation and usage  |
| `CLAUDE.md`                    | This file - developer reference      |
| `CHANGELOG.md`                 | Version history and breaking changes |
| `marketplace/README.md`        | Marketplace documentation            |
| `project-scaffolder/README.md` | Scaffolder plugin details            |

---

**This document evolves with the project. Update it when architecture changes or new patterns emerge.**
