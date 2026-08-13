---
name: policy-parallel-breadth
description: anoti operating policy — delegate exploration to explorer spawns, return synthesis not dumps. For roles that survey wide ground (architect, researcher-type hats).
---

# Policy: parallel-breadth

**Applies:** roles that declare it — work whose first step is surveying
wide ground (many files, many options, many sources).

**Procedure:**

1. Decompose the survey into independent questions; request one explorer
   spawn per question from the main session (agents do not spawn agents).
2. Respect the spawn budget: ≤ 3 concurrent, ≤ 8 per session, raised only
   by explicit human instruction. Justify each spawn in one line against
   the attention frame.
3. What returns must be **synthesis**: conclusions with `{file, lines}`
   references, ranked by relevance to the frame — never raw file dumps,
   never "here's everything I found."
4. Contradictions between explorer findings are surfaced as questions, not
   silently resolved.

**Binds:** the explorer agent; the deliberate skill's spawn-budget rule.

**Violation handling:** a raw dump is bounced for synthesis; budget
overruns are refused by the main session.
