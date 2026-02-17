# Project Scaffolder

Claude Code plugin that scaffolds projects with documentation, skills, commands, and project tracking.

## Commands

| Command   | Description                               |
| --------- | ----------------------------------------- |
| `/new`    | Create a new project with Claude Code     |
| `/update` | Update existing project to latest version |

## What Gets Created

```
project/
├── CLAUDE.md                    # Project hub
└── .claude/
    ├── settings.json            # Hooks for formatting, safety, workflow
    ├── commands/                # 2 workflow commands
    │   ├── implement.md         # Full 5-phase feature workflow
    │   └── review.md            # Pre-commit review
    ├── skills/
    │   ├── development-workflow/
    │   ├── project-standards/
    │   └── exploration-helpers/
    └── project/
        ├── features/
        ├── plans/
        ├── workflow-state.sh    # Phase state machine
        ├── high-level-user-stories.md
        └── roadmap.md
```

## Usage

Just run the command - Claude will ask what it needs:

```
/new
```

Claude will ask:

- Where to create the project
- How to handle existing files (if any)

```
/update
```

Claude will:

- Detect the project in current directory
- Show what's changed
- Update files (preserving your customizations)

## Features

- **No arguments needed** - Claude asks what it needs
- **Smart detection** - Finds existing Claude Code files
- **Safe updates** - Preserves CLAUDE.md and project tracking
- **Version tracking** - Knows when updates are available

## Hooks

Scaffolded projects include a full hook suite:

- **Safety guardrails** - Blocks force-push, --no-verify, git reset --hard, env file edits
- **Workflow phase tracking** - Auto-advances through discovery → plan → approval → implementation → complete
- **Auto-formatting** - Prettier/Black/Rustfmt after edits
- **Type checking** - Runs tsc after TypeScript file edits
- **Workflow gates** - Warns when editing source code before plan is approved

## Skills

| Skill                  | Purpose                        |
| ---------------------- | ------------------------------ |
| `development-workflow` | Feature process, git, planning |
| `project-standards`    | User stories, documentation    |
| `exploration-helpers`  | Database, codebase, types      |

## Installation

```bash
claude --plugin-dir /path/to/project-scaffolder
```

Or via marketplace:

```
/plugin install project-scaffolder@getting-started-claude
```

## Customization

After creating a project:

> "Help me customize for [your-tech-stack]"

## License

MIT
