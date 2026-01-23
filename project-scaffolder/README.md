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
└── .claude/                     # All Claude Code files
    ├── settings.json            # Hooks + version tracking
    ├── commands/                # 6 workflow commands
    │   ├── implement.md
    │   ├── discovery.md
    │   ├── plan-and-validate.md
    │   ├── start-implementation.md
    │   ├── review-implementation.md
    │   └── next.md
    ├── skills/
    │   ├── development-workflow/
    │   ├── project-standards/
    │   └── exploration-helpers/
    └── project/
        ├── features/
        ├── plans/
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

## Hooks (Non-blocking)

Scaffolded projects include hooks that:

- **Auto-increment US-XXX** - Assigns next user story number
- **Guide file naming** - Stories/plans go in correct locations
- **Maintain tracking** - Updates progress files

Hooks only trigger on `.claude/project/` file writes.

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
