# Mechanical Write Helpers (anoti 0.3.0)

**Goal:** eliminate model hand-serialized YAML — the root cause of every
data-integrity incident to date (state-file corruption → misleading
fail-open; unquoted flow scalars → split-key store corruption).

**Approach:** four scripts, each atomic (tmp+validate+mv, never leaving a
broken file), quoting via yq `strenv` (programmatic writes quote
correctly; hand-writes don't). Skills and commands reference the helpers
instead of instructing YAML edits. Classification writes also append a
durable line to `.anoti/telemetry.log` (gitignored), giving Plan 3 the
fast/slow calibration data the retrospective asked for.

| Helper                  | Signature                                                               | Writes                                           |
| ----------------------- | ----------------------------------------------------------------------- | ------------------------------------------------ |
| `append-classification` | `<session-id> <fast\|slow> <reason>`                                    | session state `classifications` + telemetry log  |
| `set-episode`           | `<session-id> <idle\|candidate-detected\|awaiting-approval\|committed>` | session state `episode`                          |
| `append-event`          | `<store> <record-id> <action> <by> <note>` (date auto)                  | record's `events` list; store re-validated       |
| `append-record`         | `<store>` + JSON record on stdin                                        | `records` append; validate + regen-index + trust |

**Tasks:** (1) RED tests in `tests/test_helpers.sh` incl. tricky
colon/comma scalars and failure paths; (2) implement helpers; (3) GREEN;
(4) update classify injection (embed real session id + helper path),
attend/consolidate skills, consolidate + review commands; (5) TODOS tick

- calibration item; (6) version 0.3.0; full suite green.
