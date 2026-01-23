# Project Scaffolder

Claude Code plugin that scaffolds projects with documentation, skills, commands, and project tracking.

## Features

- **`/scaffold <path>`** - Full project structure
- **`/scaffold-minimal <path>`** - Essential files only
- **Hooks** - Auto-manage features, plans, and tracking files
- **Template Customizer Agent** - Adapt templates to your stack

## What Gets Scaffolded

```
project/
├── CLAUDE.md                    # Project hub
├── .claude-plugin/
│   └── plugin.json              # Points to .claude/ for components
└── .claude/                     # All Claude Code files (hidden)
    ├── commands/                # 6 workflow commands
    │   ├── implement.md
    │   ├── discovery.md
    │   ├── plan-and-validate.md
    │   ├── start-implementation.md
    │   ├── review-implementation.md
    │   └── next.md
    ├── hooks/
    │   └── hooks.json           # Workflow enforcement
    ├── skills/
    │   ├── development-workflow/  # Feature process + Git + Planning
    │   ├── project-standards/     # User stories + Documentation (full only)
    │   └── exploration-helpers/   # Database + Codebase + Types (full only)
    └── project/                 # Project tracking
        ├── features/            # User story specs (us-XXX-name.md)
        ├── plans/               # Implementation plans (us-XXX-plan.md)
        ├── high-level-user-stories.md
        └── roadmap.md
```

## Installation

```bash
# Use with Claude Code CLI
claude --plugin-dir /path/to/project-scaffolder

# Or copy to plugins directory
cp -r project-scaffolder ~/.claude/plugins/
```

## Usage

```
/scaffold ../my-project
/scaffold ../api --name "API Service" --tech-stack "fastapi"
/scaffold-minimal ../quick-project
```

## Arguments

| Argument        | Description                 |
| --------------- | --------------------------- |
| `<path>`        | Target directory (required) |
| `--name`        | Project name                |
| `--author`      | Author name                 |
| `--description` | Project description         |
| `--tech-stack`  | Tech stack hint             |

## Existing Directories

When scaffolding into an existing directory, you'll be prompted:

- **Merge** - Skip existing files, add only missing
- **Overwrite** - Replace all Claude Code files
- **Abort** - Cancel scaffolding

## Hooks

The plugin includes hooks that:

- **Detect feature intent** - When user asks to build/implement a feature, enforces: story → plan → approve → build
- **Guide file locations** - Stories → `.claude/project/features/`, Plans → `.claude/project/plans/`
- **Maintain tracking** - Updates high-level-user-stories.md and roadmap.md
- **Verify consistency** - Counts, links, phase progress

## Project Tracking

Files in `.claude/project/`:

| File                         | Purpose                       |
| ---------------------------- | ----------------------------- |
| `high-level-user-stories.md` | Progress tracker (START HERE) |
| `roadmap.md`                 | Phased implementation plan    |
| `features/`                  | User story specs              |
| `plans/`                     | Implementation plans          |

## Skills

| Skill                  | Location                               | Purpose                        |
| ---------------------- | -------------------------------------- | ------------------------------ |
| `development-workflow` | `.claude/skills/development-workflow/` | Feature process, git, planning |
| `project-standards`    | `.claude/skills/project-standards/`    | User stories, documentation    |
| `exploration-helpers`  | `.claude/skills/exploration-helpers/`  | Database, codebase, types      |

## Customization

After scaffolding:

> "Help me customize these templates for [your-tech-stack]"

## License

MIT
