# Getting Started with Claude Code

A plugin marketplace and collection of Claude Code plugins for project scaffolding, documentation, and development workflows.

## Quick Start

### Install the Marketplace

```
/plugin marketplace add https://github.com/Adegbolahan/getting-started-claude
```

### Install a Plugin

```
/plugin install project-scaffolder@getting-started-claude
```

### Create a New Project

```
/new
```

Claude will ask where to create it and set everything up.

---

## Available Plugins

| Plugin                                     | Description                                                   |
| ------------------------------------------ | ------------------------------------------------------------- |
| [project-scaffolder](./project-scaffolder) | Scaffold projects with documentation, workflows, and tracking |

---

## Project Scaffolder

### Commands

| Command   | Description                               |
| --------- | ----------------------------------------- |
| `/new`    | Create a new project with Claude Code     |
| `/update` | Update existing project to latest version |

No arguments needed - Claude asks what it needs.

### What Gets Created

```
your-project/
├── CLAUDE.md                    # Project hub
└── .claude/
    ├── settings.json            # Hooks + version tracking
    ├── commands/                # 6 workflow commands
    ├── skills/                  # 3 interactive skills
    └── project/                 # Feature tracking
        ├── features/
        ├── plans/
        ├── high-level-user-stories.md
        └── roadmap.md
```

### Features

- **No arguments** - Claude asks what it needs
- **Smart updates** - Preserves your customizations
- **Version tracking** - Knows when updates available
- **Non-blocking hooks** - Only trigger on project files

### Customization

After creating a project:

> "Help me customize for [your-tech-stack]"

---

## Contributing

### Add a Plugin

1. Create plugin with `.claude-plugin/plugin.json`
2. Add to this repository
3. Update `.claude-plugin/marketplace.json`
4. Submit PR

---

## Local Development

```bash
claude --plugin-dir /path/to/project-scaffolder
```

---

## Support

- [GitHub Issues](https://github.com/Adegbolahan/getting-started-claude/issues)
- [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code)

## License

MIT
