# anoti

A human-shaped cognitive work cycle for AI agents, over governed,
evidence-bearing, human-ratified memory.

anoti gives Claude Code sessions what agents structurally lack: memory
that survives sessions and cannot be quietly corrupted, an attention
bottleneck that spends effort only where work deserves it, gates on
destructive actions, and a consolidation ritual where a human — not the
model — decides what becomes established truth.

**Slogan:** outsource some of the thinking, but never outsource
understanding.

## Quick Start

```
/plugin marketplace add https://github.com/Adegbolahan/getting-started-claude
/plugin install anoti@anoti
```

Then in your project:

```
/anoti:new        # bootstrap the workspace (memory store + direction docs)
```

Restart Claude Code (hooks load at session start) and every session opens
with your project's memory digest, current roadmap phase, and value
standard.

## What you get

- **Six lifecycle hooks:** retrieval with a provenance trust boundary,
  an attention classifier (zero overhead on trivial prompts), an
  inhibition decision table with a versioned deny-list, session-state
  persistence across compaction, and a consolidation gate.
- **Governed memory** (`GROUNDING.yaml`, schema v3): typed records
  (claim/preference/decision/goal/policy), separated epistemic and
  ratification status, append-only event logs, a generated index, and
  mechanical write helpers — the model never hand-serializes YAML.
- **Commands:** `/anoti:new`, `/anoti:implement` (feature workflow with a
  mandatory spec gate), `/anoti:review-work` (pre-ship review with an
  evidence contract and cycle cap), `/anoti:update`, `/anoti:review`
  (memory ratification), `/anoti:recall`, `/anoti:consolidate`.
- **A 23-role practitioner system** led by the conductor, with
  composable policy skills (policies are invocable skills).
- **Honest evidence:** the plugin benchmarks itself pre-registered and
  records verdicts either direction — see `docs/trials/` for sequence 1,
  including the findings that went against it.

## Deprecation notice — project-scaffolder

This repository previously hosted the project-scaffolder plugin. It is
**deprecated**: anoti absorbs its workflow commands (`/new`,
`/implement`, `/review` → `/review-work`, `/update`) rebuilt on anoti's
memory and governance. Existing pinned installs keep working — the
`v3.x` tags remain in this repository's history. No further scaffolder
releases will be made.

## Development

```
bash tests/run.sh     # full suite
```

See `CHANGELOG.md` for release history, `docs/specs/` for the design
spec, and `GROUNDING.yaml` for the project's own governed memory —
including the claims about itself it has demoted.
