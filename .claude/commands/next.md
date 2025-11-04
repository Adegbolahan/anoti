---
description: Proceed to next phase of feature implementation
---

# Proceed to Next Phase

This command continues the feature implementation workflow to the next phase.

## How It Works

Based on the most recent phase completion in the conversation, this command triggers the appropriate next step:

**Phase progression:**
- After `/discovery` → Trigger `/plan-and-validate`
- After `/plan-and-validate` → Trigger `/start-implementation`
- After `/start-implementation` → Implementation complete!

---

## Instructions for Claude

**Analyze the recent conversation to determine the last completed phase:**

1. **If the last message completed discovery (Phase 1+2):**
   - Use SlashCommand tool to run: `/plan-and-validate`

2. **If the last message completed plan-and-validate (Phase 3+3.5):**
   - Use SlashCommand tool to run: `/start-implementation`

3. **If implementation is already complete:**
   - Tell the user: "✅ Implementation is complete! No next phase."

4. **If unable to determine current phase:**
   - Ask the user: "Which phase would you like to proceed to?"
   - Options:
     - `/discovery` - Start Phase 1+2 (Requirements + Architecture)
     - `/plan-and-validate` - Start Phase 3+3.5 (Planning + Validation)
     - `/start-implementation` - Start Phase 4 (Implementation)

---

## Example Usage

```
User: [completes discovery]
Claude: "✅ Discovery Complete. Run `/next` to proceed to planning."
User: /next
Claude: [Triggers /plan-and-validate via SlashCommand tool]
```

```
User: [completes plan validation]
Claude: "✅ Plan Validated and Approved. Run `/next` to start implementation."
User: /next
Claude: [Triggers /start-implementation via SlashCommand tool]
```
