# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

**Getting Started with Claude** is a plugin marketplace and collection of Claude Code plugins for project scaffolding.

## Repository Structure

```
getting-started-claude/
├── CLAUDE.md                     # This file
├── README.md                     # User documentation
├── .claude-plugin/
│   └── marketplace.json          # Marketplace registry
└── project-scaffolder/           # Main plugin
    ├── .claude-plugin/
    │   └── plugin.json
    ├── commands/                 # /new, /update
    ├── agents/                   # template-customizer
    ├── skills/                   # scaffolding-guidance
    └── resources/templates/      # Template files
```

## Plugin Commands

| Command   | Description                    |
| --------- | ------------------------------ |
| `/new`    | Create new project             |
| `/update` | Update existing project        |

No arguments - Claude asks what it needs.

## What Gets Scaffolded

New projects receive (standalone, no plugin manifest):

- `CLAUDE.md` - Project hub
- `.claude/settings.json` - Hooks + version tracking
- `.claude/commands/` - 6 workflow commands
- `.claude/skills/` - 3 skills
- `.claude/project/` - Feature tracking

## Development

### Testing

```bash
claude --plugin-dir /path/to/project-scaffolder
```

### Modifying Templates

1. Edit files in `project-scaffolder/resources/templates/`
2. Test with `/new` on a test project
3. Verify structure and placeholder replacement

## Git Workflow

**Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)

## Contributing

1. Create plugin with `.claude-plugin/plugin.json`
2. Add commands/skills/agents
3. Include README
4. Register in `.claude-plugin/marketplace.json`
