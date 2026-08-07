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
    ├── settings.json            # Registers 7 hooks + version tracking
    ├── commands/                # implement, review
    ├── skills/                  # 3 interactive skills
    └── project/                 # Feature tracking
        ├── features/
        ├── plans/
        ├── hooks/               # One script per hook event
        ├── workflow-state.sh    # Phase state machine
        ├── high-level-user-stories.md
        └── roadmap.md
```

### Features

- **No arguments** — Claude asks what it needs
- **A commit gate that actually blocks** — `git commit` is refused until the work
  has been reviewed, including when the gate cannot evaluate its own state
- **Scoped to your project** — hooks stand down silently in any repository that
  was not scaffolded
- **Smart updates** — preserves your customizations
- **Version tracking** — knows when an update is available

### The commit gate

`git commit` is allowed only once `/review` has passed. It also blocks on states
it cannot confirm — missing `jq`, a corrupt state file, an unrecognised phase —
because a gate that fails open is not a gate.

Passing review requires **evidence**: a review report that exists on disk and is
newer than the last source edit. Its path and a content hash go into the audit
log, so a pass can be traced back to whatever produced it.

**What this is and is not.** This is a guardrail against drift and accident, not
an adversarial control, and it does not pretend otherwise. Anything that can
write a file can satisfy the evidence check — including the agent doing the
work. What the check buys you is that skipping review stops being a silent
two-command shortcut and becomes an explicit act that leaves a forged artifact
in the diff, where a human reviewing the PR can see it.

If you want a control an agent genuinely cannot reach, use branch protection on
the remote. This gate lives in your working copy and is bounded by that.

Blocked and need to know why:

```bash
.claude/project/workflow-state.sh why-blocked
```

Blocked and need to commit anyway (recorded in the audit log):

```bash
.claude/project/workflow-state.sh override "reason this is justified"
```

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

### Tests

The hook suite is the contract. Run it before and after any change to the hooks
or the state machine.

```bash
./test/run.sh
```

Requires `bats` and `jq` (`brew install bats-core jq`). CI runs the same suite
plus shellcheck, hook-schema validation, and a version-consistency check.

---

## Support

- [GitHub Issues](https://github.com/Adegbolahan/getting-started-claude/issues)
- [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code)

## License

MIT
