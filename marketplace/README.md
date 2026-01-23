# Getting Started with Claude - Plugin Marketplace

A curated collection of Claude Code plugins for project scaffolding, documentation, and development workflows.

## Installation

### Add this marketplace to Claude Code:

```
/plugin marketplace add https://github.com/Adegbolahan/getting-started-claude/marketplace
```

### Browse available plugins:

```
/plugin marketplace browse getting-started-claude-marketplace
```

### Install a plugin:

```
/plugin install project-scaffolder@getting-started-claude-marketplace
```

## Available Plugins

| Plugin                                      | Description                                                   | Category    |
| ------------------------------------------- | ------------------------------------------------------------- | ----------- |
| [project-scaffolder](../project-scaffolder) | Scaffold projects with documentation, workflows, and tracking | Development |

## Plugin Details

### project-scaffolder

Scaffold new projects with Claude Code documentation, workflow commands, skills, and project tracking.

**Commands:**

- `/scaffold <path>` - Full project structure
- `/scaffold-minimal <path>` - Essential files only

**Features:**

- CLAUDE.md project hub template
- 6 workflow commands (implement, discovery, plan-and-validate, etc.)
- 3 interactive skills (development-workflow, project-standards, exploration-helpers)
- Hooks for enforcing story → plan → approve → build workflow
- Project tracking with user stories and roadmaps

**Install:**

```
/plugin install project-scaffolder@getting-started-claude-marketplace
```

## Contributing

Want to add a plugin to this marketplace?

1. Create your plugin following [Claude Code plugin structure](https://code.claude.com/docs/en/plugins)
2. Submit a PR adding your plugin to `.claude-plugin/marketplace.json`
3. Include documentation in the plugin's README

### Plugin Requirements

- Must have `.claude-plugin/plugin.json` manifest
- Must include README with usage instructions
- Should follow Claude Code conventions
- Must not include malicious code or dependencies

## Updating

To get the latest plugins:

```
/plugin marketplace update getting-started-claude-marketplace
```

## Support

- [GitHub Issues](https://github.com/Adegbolahan/getting-started-claude/issues)
- [Documentation](https://github.com/Adegbolahan/getting-started-claude)

## License

MIT
