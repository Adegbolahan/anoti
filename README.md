# Getting Started with Claude Code

A plugin marketplace and collection of Claude Code plugins for project scaffolding, documentation, and development workflows.

## Repository Structure

```
getting-started-claude/
├── marketplace/                  # Plugin marketplace
│   ├── .claude-plugin/
│   │   └── marketplace.json      # Marketplace registry
│   └── README.md                 # Marketplace documentation
├── project-scaffolder/           # Scaffolding plugin
│   ├── .claude-plugin/
│   │   └── plugin.json           # Plugin manifest
│   ├── commands/                 # /scaffold, /scaffold-minimal
│   ├── agents/                   # template-customizer agent
│   ├── skills/                   # scaffolding-guidance skill
│   └── resources/templates/      # Template files
└── CLAUDE.md                     # Project documentation
```

## Quick Start

### Install the Marketplace

```
/plugin marketplace add https://github.com/Adegbolahan/getting-started-claude/marketplace
```

### Browse Available Plugins

```
/plugin marketplace browse getting-started-claude-marketplace
```

### Install a Plugin

```
/plugin install project-scaffolder@getting-started-claude-marketplace
```

## Available Plugins

| Plugin                                     | Description                                                   | Category    |
| ------------------------------------------ | ------------------------------------------------------------- | ----------- |
| [project-scaffolder](./project-scaffolder) | Scaffold projects with documentation, workflows, and tracking | Development |

---

## Project Scaffolder

Scaffold new projects with Claude Code documentation, workflow commands, skills, hooks, and project tracking.

### Commands

| Command                    | Description                                       |
| -------------------------- | ------------------------------------------------- |
| `/scaffold <path>`         | Full project structure with all components        |
| `/scaffold-minimal <path>` | Essential files only (CLAUDE.md, commands, skill) |

### What Gets Created

```
your-project/
├── CLAUDE.md                    # Project hub
├── .claude-plugin/
│   └── plugin.json              # Points to .claude/
└── .claude/                     # All Claude Code files (hidden)
    ├── commands/                # 6 workflow commands
    │   ├── implement.md         # Full workflow orchestrator
    │   ├── discovery.md         # Requirements + Architecture
    │   ├── plan-and-validate.md # Create and validate plan
    │   ├── start-implementation.md
    │   ├── review-implementation.md
    │   └── next.md              # Proceed to next phase
    ├── hooks/
    │   └── hooks.json           # Workflow enforcement
    ├── skills/                  # Interactive skills
    │   ├── development-workflow/
    │   ├── project-standards/
    │   └── exploration-helpers/
    └── project/                 # Project tracking
        ├── features/            # User story specs
        ├── plans/               # Implementation plans
        ├── high-level-user-stories.md
        └── roadmap.md
```

### Options

| Argument        | Description                       |
| --------------- | --------------------------------- |
| `<path>`        | Target directory (required)       |
| `--name`        | Project name                      |
| `--author`      | Author name                       |
| `--description` | Project description               |
| `--tech-stack`  | Tech stack hint for customization |

### Examples

```
/scaffold ../my-app
/scaffold ../api --name "User API" --tech-stack "fastapi"
/scaffold-minimal ../quick-project
```

### Existing Directories

When scaffolding into an existing directory:

- **Merge** - Skip existing files, add only missing
- **Overwrite** - Replace all Claude Code files
- **Abort** - Cancel scaffolding

### Feature Workflow

The hooks enforce a structured workflow:

```
1. Story  → Create in .claude/project/features/
2. Plan   → Create in .claude/project/plans/
3. Approve → Get user approval before coding
4. Build  → Implement following the plan
```

**No coding starts without story + plan + approval.**

### Skills

| Skill                  | Purpose                        |
| ---------------------- | ------------------------------ |
| `development-workflow` | Feature process, git, planning |
| `project-standards`    | User stories, documentation    |
| `exploration-helpers`  | Database, codebase, types      |

### Customization

After scaffolding, ask the template-customizer agent:

> "Help me customize these templates for [your-tech-stack]"

---

## Contributing

### Add a Plugin to the Marketplace

1. Create your plugin following [Claude Code plugin structure](https://docs.anthropic.com/en/docs/claude-code/plugins)
2. Add your plugin directory to this repository
3. Update `marketplace/.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "your-plugin-name",
      "description": "What your plugin does",
      "version": "1.0.0",
      "author": { "name": "Your Name" },
      "source": "../your-plugin-directory",
      "category": "development",
      "keywords": ["relevant", "keywords"]
    }
  ]
}
```

4. Submit a pull request

### Plugin Requirements

- Must have `.claude-plugin/plugin.json` manifest
- Must include README with usage instructions
- Should follow Claude Code conventions
- Must not include malicious code or dependencies

---

## Local Development

### Test a Plugin Locally

```bash
# Run Claude Code with the plugin directory
claude --plugin-dir /path/to/project-scaffolder

# Or copy to your plugins directory
cp -r project-scaffolder ~/.claude/plugins/

# Or create a symlink
ln -s /path/to/project-scaffolder ~/.claude/plugins/project-scaffolder
```

### Modify Templates

1. Edit files in `project-scaffolder/resources/templates/`
2. Test by running `/scaffold` on a test project
3. Verify generated files match expectations

---

## Support

- [GitHub Issues](https://github.com/Adegbolahan/getting-started-claude/issues)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)

## License

MIT
