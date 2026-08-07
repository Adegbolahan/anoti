# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

**Getting Started with Claude** is a plugin marketplace and a Claude Code plugin
that scaffolds projects with an enforced development workflow.

The plugin's central claim is that `git commit` is **blocked** until the work has
been reviewed. Everything else is in service of that. Treat any change that
weakens or bypasses the gate as a change to the product's core promise.

## Repository Structure

```
getting-started-claude/
├── CLAUDE.md                     # This file
├── README.md                     # User documentation
├── CHANGELOG.md
├── TODOS.md                      # Deferred work, with context
├── .claude-plugin/
│   └── marketplace.json          # Marketplace registry
├── .github/workflows/ci.yml      # Hook tests, shellcheck, schema, versions
├── docs/designs/                 # Design docs for larger changes
├── test/                         # bats suite for the hooks  <-- START HERE
└── project-scaffolder/
    ├── .claude-plugin/plugin.json
    ├── commands/                 # /new, /update
    ├── skills/                   # scaffolding-guidance
    └── resources/templates/      # What gets copied into a project
```

## Plugin Commands

| Command   | Description             |
| --------- | ----------------------- |
| `/new`    | Create new project      |
| `/update` | Update existing project |

No arguments. Claude asks what it needs.

## What Gets Scaffolded

New projects receive (standalone, no plugin manifest):

- `CLAUDE.md` — project hub
- `.claude/settings.json` — registers 7 hooks, one per event, plus version tracking
- `.claude/commands/` — 2 workflow commands (`implement`, `review`)
- `.claude/skills/` — 3 skills
- `.claude/project/` — feature tracking, `workflow-state.sh`, and `hooks/`

## Testing

**The suite is the contract.** Run it before and after any change to hooks or
the state machine.

```bash
./test/run.sh                 # everything
./test/run.sh regression      # one directory
```

Requires `bats` and `jq` (`brew install bats-core jq`).

Read `test/README.md` before adding tests. Two things matter:

1. **Tests never assert against hook command strings.** They read
   `settings.json`, extract every command registered for an event, and block if
   any exits 2. That indirection is what let the suite survive moving hook
   bodies from inline strings into scripts.
2. **`test/gate/f1-bystander.bats` protects other repositories.** Plugin hooks
   are installed user-wide and fire everywhere. Those tests assert the gate
   stays silent in a repo that was never scaffolded. Do not weaken them.

## Hook Architecture

Hook bodies live in `resources/templates/.claude/project/hooks/`, one script per
event. `settings.json` holds one-line invocations.

Every hook follows the same ordering, and the order is load-bearing:

```
1. global safety blockers   force-push, --no-verify, reset --hard, secrets
                            (these run in EVERY repo, by design)
2. scope guard              no .claude/project/ ? exit 0 silently
3. fail closed              inside a scaffolded project, anything the hook
                            cannot positively confirm BLOCKS and explains
```

Reversing 2 and 3 makes "this repo was never scaffolded" an unconfirmable state,
and the gate would block commits in every unrelated repository on the machine.

Hooks in the same event run in parallel and cannot see each other, so there is
exactly **one hook per event**. State writes are serialised with a `mkdir` lock.

## Development

```bash
claude --plugin-dir /path/to/project-scaffolder
```

### Modifying Templates

1. Edit files in `project-scaffolder/resources/templates/`
2. Run `./test/run.sh`
3. Run `shellcheck -x` on any shell you touched
4. Test with `/new` on a scratch directory

### Versioning

Four places must agree, and CI fails the build when they do not:
`plugin.json`, `marketplace.json`, the `settings.json` template's
`scaffoldVersion`, and a matching `CHANGELOG.md` entry.

## Git Workflow

**Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)

## Contributing

1. Create a plugin with `.claude-plugin/plugin.json`
2. Add commands/skills/agents
3. Include a README
4. Register it in `.claude-plugin/marketplace.json`
