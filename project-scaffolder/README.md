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
        ├── hooks/               # One script per hook event
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

Scaffolded projects get one hook script per event, under `.claude/project/hooks/`.
`settings.json` holds one-line invocations.

| Event                     | Does                                                               |
| ------------------------- | ------------------------------------------------------------------ |
| SessionStart              | Branch, change count, current phase and next step                  |
| UserPromptSubmit          | Suggests `/implement`; detects plan approval                       |
| PreToolUse (Bash)         | Safety blockers, then the commit gate                              |
| PreToolUse (Edit\|Write)  | Secrets blocker, then the workflow gate                            |
| PostToolUse (Edit\|Write) | Formats if configured, records touched types, advances the phase   |
| PostToolUse (Bash)        | A commit from `review_passed` completes the story                  |
| Stop                      | Typecheck (only if TS was touched), uncommitted warning, next step |

Every script runs in the same order, and the order matters:

```
1. global safety blockers   force-push, --no-verify, reset --hard, clean -f,
                            branch -D, checkout ., secrets files
                            (these fire in EVERY repo, deliberately)
2. scope guard              no .claude/project/ ? exit 0, silently
3. fail closed              inside a scaffolded project, anything the hook
                            cannot positively confirm BLOCKS and explains why
```

Reversing 2 and 3 would make "this repo was never scaffolded" an unconfirmable
state, and the gate would block commits in every unrelated repository on your
machine.

**Formatting** only runs when the project actually configures a formatter, so a
project without prettier never triggers an `npx` fetch. **Typechecking** happens
at `Stop`, only when a TypeScript file was touched that turn, and incrementally.

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
