# Q001 format-comprehension results (sequence 1, n=1/format, haiku readers)

| Format | Accuracy | Bytes | ~Tokens (chars/4) |
|---|---|---|---|
| agent-Markdown | 10/10 | 745 | ~186 |
| sigil (bespoke) | 10/10 | 986 | ~247 |
| v1-era YAML | 10/10 | 1,249 | ~312 |
| v3 YAML (records+events) | 10/10 | 2,388 | ~597 |

All four blinded readers answered all ten questions correctly, including
both revision questions — even the bespoke sigil notation parsed
perfectly at this scale.

**Frozen decision rule applied:** YES via agent-Markdown — accuracy ≥ all
(tied) and cost below sigil and below v1. v3 YAML fails the cost prong:
it is the LARGEST format; its overhead is the governance payload (events,
ratification, typing), not syntax ceremony.

**Honest caveats, recorded not buried:**
- Accuracy ceilinged (8 facts, ~1KB, strong reader): the accuracy prong
  discriminated nothing. Only cost separated the formats.
- Mild tension with D004: this pilot shows NO accuracy penalty for sigil
  at small scale, where D004's founding observation (Codex) reported
  comprehension-reliability risk. Not a contradiction — D004's mechanism
  (in-context grammar learning cost) plausibly bites at scale/complexity
  this pilot never reached — but the tension is now on the record.
- n=1 per format; pilot-grade.

**Proposed Q001 resolution (human's call):** answered-with-qualification —
familiar syntax + agent-oriented content design wins on cost and ties on
accuracy at small scale; the reliability question D004 raises remains
scale-dependent and untested above ~1KB.
