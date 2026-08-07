---
name: skillify
description: |
  Use this skill when the user wants to capture a pattern from completed work as a reusable project skill, or accepts a capture suggestion after finishing a story. Triggers on: "skillify this", "turn this into a skill", "capture this pattern", "make a skill for this", or agreeing to a suggestion from the workflow hooks.
metadata:
  version: "1.0.0"
---

# Skillify

Turn something you just learned building a feature into a skill the next person
(or the next session) gets for free.

## When NOT to do this

Start here, because the failure mode is volume. A project with thirty thin
skills is worse than one with three good ones: nobody reads thirty, and the
model's context is finite.

**Refuse if:**

- It is a restatement of what the code already says. Reading the code is not a
  skill.
- An existing skill covers it. Check `.claude/skills/` and the plugin's own
  skills before writing anything.
- It happened once and may never recur. One occurrence is an anecdote.
- It is general programming knowledge. The model already knows how promises,
  migrations and indexes work.

**The bar, at least one of:**

- The pattern has now come up in two or more stories.
- It encodes a project convention discovered while building, which is not
  obvious from reading the code.
- The sequence is non-obvious enough that redoing it later would cost real time.

If nothing clears the bar, say so plainly and stop. Declining is the common and
correct outcome.

## Process

### 1. Name what you actually learned

In one sentence, and concretely. Not "how to add API endpoints" — that is a
category. Something like "this codebase routes all tenant queries through
`withTenant()` and forgetting it silently returns other tenants' rows."

If you cannot make it concrete in one sentence, it is not ready to be a skill.

### 2. Check it does not already exist

```bash
ls -d .claude/skills/*/ 2>/dev/null
```

Read the `description:` of anything that looks close. Overlapping skills are
worse than a missing one: the model has to pick, and it will sometimes pick
wrong.

If it partially overlaps, **extend the existing skill** instead of creating a
sibling.

### 3. Write it

`.claude/skills/<kebab-name>/SKILL.md`:

```markdown
---
name: <kebab-name>
description: |
  Use this skill when <situation>. Triggers on: "<phrase>", "<phrase>".
metadata:
  version: "1.0.0"
---

# <Name>

<One paragraph: what this is and when it matters.>

## <The actual content>

<Concrete. Real file paths, real function names, real commands from this
codebase. A skill that could apply to any project is not a project skill.>

## Pitfalls

<What goes wrong if you do not know this. Ideally the specific thing that went
wrong while building the story that prompted it.>
```

Frontmatter rules the loader actually enforces:

- **`name` must be lowercase-hyphen and match the folder name exactly.** Not
  Title Case. A mismatch means the skill silently fails to load.
- **`version` is not a supported top-level attribute.** Put it under `metadata`.
- Supported keys: `argument-hint`, `compatibility`, `context`, `description`,
  `disable-model-invocation`, `license`, `metadata`, `name`, `user-invocable`.

Rules for the body:

- **Be specific to this codebase.** Name files, functions, commands.
- **Show the failure.** The reason a skill sticks is that it names the thing
  that bites.
- **Keep it short.** If it runs past a screen or two, it is documentation, not a
  skill. Link out instead.
- **Write the `description` for retrieval.** It is how the model decides whether
  to load this at all. Name the situation and realistic trigger phrases.

### 4. Cite the evidence

At the bottom, link the story that produced it:

```markdown
---

Captured from US-0XX (<title>). See `.claude/project/features/us-0XX-*.md`.
```

Then someone reading it in six months can find out why it exists, and whether
it still holds.

### 5. Confirm

Show the user the skill you wrote and ask whether to keep it. Skills load into
context on every matching request, so a bad one has an ongoing cost, not a
one-time one.
