# Hook test suite

```bash
./test/run.sh              # everything
./test/run.sh regression   # one directory
```

Requires `bats` and `jq`.
macOS: `brew install bats-core jq` · Linux: `apt-get install bats jq`

## Status: 72 tests, all passing

The suite was written **before** the fixes, against the broken hooks, so that
each defect became a failing test _before_ anyone touched the code. It opened at
12 pass / 12 fail. All 12 failures are now green, and each pins down a defect
that shipped in a previous release.

Two of these tests earned their keep immediately by catching bugs in the fixes
themselves: `snapshot` crashed whenever an override was armed (`@tsv` rejects
objects, and `.override` is one), and `has_prettier_config` never returned true
because `ls a* b*` exits nonzero when either glob misses.

**Do not delete a regression test to make a change pass.** Each one documents
something that was broken in production.

| Directory                           | Pins down                                                                                                                                                               |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `regression/d1-gate-unreachable`    | The gate never fired. Nothing advanced the phase to `implementation_in_progress`, so after approval it sat at `plan_approved`, the `case` fell through, commits passed. |
| `regression/sgap1-compound-command` | The gate was anchored to `^git commit` while every safety blocker beside it was unanchored, so `cd frontend && git commit` walked past it.                              |
| `regression/a2-missing-jq`          | Missing jq, a corrupt state file, an unreadable state file, and an unknown phase each silently _disabled_ the gate instead of blocking.                                 |
| `gate/f1-bystander`                 | The gate must stay out of repositories that were never scaffolded.                                                                                                      |
| `hooks/pre-edit`, `hooks/post-edit` | Secrets blocking, formatter detection, turn bookkeeping, phase advancement.                                                                                             |
| `state/workflow-state`              | Transitions, the exit-code contract, findings validation, override, schema migration, locking, audit log.                                                               |

## `test/gate/f1-bystander.bats` protects every other repo on the machine

Plugin hooks are installed user-wide and fire in **every** repository
([hook-development SKILL.md:383](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md)).
There is no project-scoping mechanism.

The gate fails _closed_: anything it cannot positively confirm blocks. On its
own that is catastrophic here, because "this repo has no `.claude/project/`" is
an unconfirmable state — a naive implementation would block `git commit` in
every unrelated repository you own.

So the ordering is load-bearing:

```
1. global safety blockers   run everywhere, deliberately
2. scope guard              not scaffolded? exit 0, silently
3. fail closed              only inside a scaffolded project
```

Reverse 2 and 3 and the product becomes hostile. These tests are the guard rail
for that ordering, and they run against a fixture that puts the hook scripts
_outside_ the project, simulating how they will ship from the plugin.

## How the harness works

Tests never assert against hook command strings. `helpers/setup.bash` reads
`.claude/settings.json` with jq, extracts every command registered for an
event and matcher, pipes a JSON payload into each, and treats the hook as
blocking if **any** command exits 2 — which is how Claude Code behaves.

```
payload (JSON on stdin)
     |
     v
[ jq: read every command for event+matcher ]
     |
     +--> bash -c cmd_1 --> exit code ---+
     +--> bash -c cmd_2 --> exit code ---+--> any 2? -> BLOCKED
     +--> bash -c cmd_N --> exit code ---+          else -> ALLOWED
```

That indirection is deliberate. Phase A moves hook bodies from inline strings
into scripts, and Phase B relocates them into the plugin. Both times
`settings.json` keeps registering the same events, so these tests survive
without a rewrite.

## Fixtures

`fixtures/bin/` holds fake `npx`, `prettier`, `black`, `rustfmt`, and `tsc`
that record their arguments to `$STUB_LOG` and exit 0. `stub_path` prepends
them so no test touches the network or a real toolchain.

- `stub_invoked npx` — assert a hook _tried_ to run something. This is the only
  way to prove `npx` is never invoked in a project with no formatter config.
- `STUB_FAIL_TSC=1` — make a stub exit non-zero.
- `hide_jq` — shim `jq` to exit 127, simulating a machine without it.
