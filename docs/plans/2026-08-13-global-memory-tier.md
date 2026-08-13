# Global Memory Tier — Implementation Plan (r2, review verdict READY)

**Spec:** docs/specs/2026-08-13-global-memory-tier-design.md (RATIFIED 2026-08-13; Testing §helper-parity amended by dated changelog after plan review r1)

**Goal:** the global store works end to end — creatable by the opt-in
flow, trusted adjacently, digested with `[global]` labels, precedence
recorded by scoped-exception events, reviewable with user rights — every
spec rule executable and tested.

**Architecture:** three script changes (trust, retrieve,
validate-workspace), two content changes (consolidate skill incl.
precedence rule, review command verify-only), one dated protocol
amendment, one release. `append-record` is **unchanged** (its exit-0 is
already unconditional; auto-trust stays project-only per the spec's
amended helper-parity rule). Tech: bash + yq/jq, fake-`$HOME` fixtures.

## Global constraints (verbatim from the spec)

- Trust adjacency: **both sides realpath-normalized** — the store path
  AND `$HOME` (macOS `/var→/private/var` breaks one-sided
  normalization); under `$HOME/.claude/anoti/` → trust file
  `$HOME/.claude/anoti/trust`, else `<state-dir>/trust`. Never `dirname`.
- `trust` refuses global-path stores without `--global`; refuses missing
  store files (no false success); atomic temp+rename writes.
- Creation ordering: `mkdir -m 700` → `(umask 077; cp …)`; load-bearing.
- **Every** digest line sourced from the global store carries `[global]`.
- validate-workspace warns (stderr, exit unchanged) on
  `meta.scope`/location disagreement, using the same normalized compare.
- **Project beats global in-project; the conflict appends a
  scoped-exception event on the global record, once** (spec principle 4).
- Deferral is record-then-event: `append-event <store> <id>
scope-deferred session "global routing declined by human"`.
- Routing classes: `preference` (user), `policy`/`claim` (agent craft);
  human confirms every routing.
- Longitudinal amendment = dated changelog entry, **seventh** source.

## Files

Modify: `scripts/trust`, `scripts/retrieve`, `scripts/validate-workspace`,
`skills/consolidate/SKILL.md`, `docs/specs/2026-08-13-exp-longitudinal.md`,
`tests/test_helpers.sh`, `tests/test_retrieve.sh`, `tests/test_validate.sh`,
`tests/test_core_skills.sh`, `tests/test_docs.sh`, `CHANGELOG.md`,
`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`.
Read-verify only: `commands/review.md` (global rights already present:
its lines on correct/delete/export and independence — confirm, no edit
expected). Create: nothing. **Not touched:** `scripts/append-record`.

## Task 1: trust — normalized adjacency, --global gate, atomicity

- [ ] RED — append to `tests/test_helpers.sh`:

```bash
# --- global trust adjacency (spec: global-memory-tier) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME/.claude/anoti"
cp "$ROOT/tests/fixtures/store_valid.yaml" "$HOME/.claude/anoti/GROUNDING.yaml"
"$ROOT/scripts/trust" "$HOME/.claude/anoti/GROUNDING.yaml" 2>/dev/null
assert_eq "$?" "1" "global store without --global refused"
[ ! -f "$HOME/.claude/anoti/trust" ]; assert_ok $? "no trust written on refusal"
"$ROOT/scripts/trust" --global "$HOME/.claude/anoti/GROUNDING.yaml" >/dev/null
assert_ok $? "global trust with --global succeeds"
[ -f "$HOME/.claude/anoti/trust" ]; assert_ok $? "trust adjacent to global store"
[ ! -f .anoti/trust ]; assert_ok $? "project trust untouched by global op"
ln -s "$HOME/.claude/anoti" "$tmp/link"
"$ROOT/scripts/trust" "$tmp/link/GROUNDING.yaml" 2>/dev/null
assert_eq "$?" "1" "symlinked global path refused without --global (realpath)"
"$ROOT/scripts/trust" --global "$HOME/.claude/anoti/missing.yaml" 2>/dev/null
assert_eq "$?" "1" "missing store file is an error, never false success"
cp "$ROOT/tests/fixtures/store_valid.yaml" GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
[ -f .anoti/trust ]; assert_ok $? "project store trust unchanged"
ls "$HOME/.claude/anoti/"*.tmp 2>/dev/null | grep -q . && f8=1 || f8=0
assert_eq "$f8" "0" "no tmp residue (atomic write)"
# helper parity on the global store: append works; auto-trust stays project-only
printf '%s' '{"id":"G001","date":"2026-08-13","type":"preference","topic":"user.style","statement":"Terse commits","ratification":"approved","events":[{"date":"2026-08-13","action":"created","by":"session"}]}' \
  | "$ROOT/scripts/append-record" "$HOME/.claude/anoti/GROUNDING.yaml" 2>/dev/null
assert_ok $? "append-record works on the global store"
"$ROOT/scripts/append-event" "$HOME/.claude/anoti/GROUNDING.yaml" G001 scoped-exception session "project overrides in-project" >/dev/null
assert_ok $? "scoped-exception event appends on a global record (precedence mechanics)"
); rm -rf "$tmp"
```

- [ ] Run `bash tests/run.sh` — expect exactly these new failures.
- [ ] GREEN — rewrite `scripts/trust`:

```bash
#!/bin/bash
# trust [--global] <store.yaml> — record the store's content hash as
# user-approved. Trust lives ADJACENT to its store: realpath-normalized
# store path under realpath-normalized $HOME/.claude/anoti/ ->
# $HOME/.claude/anoti/trust (requires --global: deliberate friction on
# the machine-wide path); otherwise <state-dir>/trust. Atomic writes.
set -u
GLOBAL=0
[ "${1:-}" = "--global" ] && { GLOBAL=1; shift; }
f="${1:?usage: trust [--global] <store.yaml>}"
[ -f "$f" ] || { echo "trust: no such store: $f" >&2; exit 1; }
SELF="$(cd "$(dirname "$0")" && pwd)"
real="$(cd "$(dirname "$f")" && pwd -P)/$(basename "$f")"
ghome="$(cd "$HOME" 2>/dev/null && pwd -P)"
gdir="$ghome/.claude/anoti"
case "$real" in
  "$gdir"/*)
    [ "$GLOBAL" = "1" ] || { echo "trust: store is under $gdir — machine-wide scope requires --global" >&2; exit 1; }
    tdir="$gdir" ;;
  *)
    AD="$("$SELF/anoti-dir")"; tdir="$AD"; mkdir -p "$tdir"
    [ -f "$tdir/.gitignore" ] || printf '*\n' > "$tdir/.gitignore" ;;
esac
tf="$tdir/trust"
{ [ -f "$tf" ] && cat "$tf"; shasum -a 256 "$f" | cut -d' ' -f1; } | sort -u > "$tf.tmp" \
  && mv "$tf.tmp" "$tf"
echo "trusted: $f"
```

(append-record's `trust "$f" >/dev/null` now fails harmlessly on
global stores — stderr shows the informative refusal, and its
pre-existing unconditional `exit 0` keeps append behavior identical,
exactly per the amended spec. No append-record edit.)

- [ ] `bash tests/run.sh` green.
- [ ] Commit: `feat: trust adjacency (dual realpath) with --global gate and atomic writes`

## Task 2: retrieve — per-store trust path, [global] on every line, drift report

- [ ] RED — append to `tests/test_retrieve.sh`:

```bash
# --- global store digestion (spec: global-memory-tier) ---
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME/.claude/anoti"
cp "$ROOT/tests/fixtures/store_valid.yaml" "$HOME/.claude/anoti/GROUNDING.yaml"
out="$(printf '{"session_id":"g"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$out" | grep -q "not yet trusted"; assert_ok $? "untrusted global refused"
"$ROOT/scripts/trust" --global "$HOME/.claude/anoti/GROUNDING.yaml" >/dev/null
out="$(printf '{"session_id":"g"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
# NOTE (explicit coupling): the second [global] line comes deterministically
# from the scope-drift emit — the fixture carries scope: project while
# placed at the global path. If the fixture's scope field ever changes,
# give this test its own fixture rather than weakening the assertion.
n=$(printf '%s\n' "$out" | grep -c "\[global\]")
[ "$n" -ge 2 ]; assert_ok $? "every global-sourced line labeled [global] (got $n)"
printf '%s' "$out" | grep -q "2 records"; assert_ok $? "trusted global digested"
); rm -rf "$tmp"
# scope/location mismatch surfaces in the digest
tmp="$(mktemp -d)"; ( cd "$tmp"
HOME="$tmp/home"; export HOME; mkdir -p "$HOME"
sed 's/scope: project/scope: global/' "$ROOT/tests/fixtures/store_valid.yaml" > GROUNDING.yaml
"$ROOT/scripts/trust" GROUNDING.yaml >/dev/null
out="$(printf '{"session_id":"g"}' | "$ROOT/scripts/retrieve" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$out" | grep -qi "scope mismatch"; assert_ok $? "scope/location drift reported"
); rm -rf "$tmp"
```

- [ ] GREEN — `scripts/retrieve` changes, shown:

```bash
# store_digest signature grows two args: $3=trust-file $4=line-label
store_digest() { # $1=file $2=name $3=trustfile $4=label ("" or "[global] ")
  ...
  is_trusted() becomes: [ -f "$3" ] && grep -qs "$(hash_of "$1")" "$3"
  every emit inside store_digest prefixes "$4":
    emit "- $4$2: $n records, $p awaiting ratification. ..."
    emit "  - $4review recommended: ..." ; index rows and question lines likewise
  # scope drift (uses the same dual-realpath compare as trust):
  sc="$(yq -r '.meta.scope // ""' "$1" 2>/dev/null)"
  loc=project; case "$(cd "$(dirname "$1")" && pwd -P)/" in "$(cd "$HOME" && pwd -P)/.claude/anoti/"*) loc=global;; esac
  [ -n "$sc" ] && [ "$sc" != "$loc" ] && emit "  - $4scope mismatch: meta.scope=$sc but store is $loc — location drives behavior"
}
# call sites:
[ -f "$g" ] && store_digest "$g" "global memory" "$ghome/.claude/anoti/trust" "[global] "
[ -f GROUNDING.yaml ] && store_digest GROUNDING.yaml "project memory" "$AD/trust" ""
```

- [ ] Commit: `feat: retrieve digests the global tier — per-store trust, [global] labels, drift report`

## Task 3: validate-workspace scope warning

- [ ] RED — append to `tests/test_validate.sh`:

```bash
# meta.scope location mismatch warns without failing (spec: global tier)
tmpg="$(mktemp -d)"; ( cd "$tmpg"
HOME="$tmpg/home"; export HOME; mkdir -p "$HOME"
sed 's/scope: project/scope: global/' "$ROOT/tests/fixtures/store_valid.yaml" > s.yaml
err="$("$v" s.yaml 2>&1 >/dev/null)"; rc=$?
assert_eq "$rc" "0" "scope mismatch alone does not fail validation"
printf '%s' "$err" | grep -qi "warning: meta.scope"; assert_ok $? "scope mismatch warned on stderr"
); rm -rf "$tmpg"
```

- [ ] GREEN — before `exit "$err"` in `scripts/validate-workspace`:

```bash
sc="$(yq -r '.meta.scope // ""' "$f" 2>/dev/null)"
if [ -n "$sc" ]; then
  loc=project
  case "$(cd "$(dirname "$f")" && pwd -P)/" in
    "$(cd "$HOME" 2>/dev/null && pwd -P)/.claude/anoti/"*) loc=global ;;
  esac
  [ "$sc" != "$loc" ] && echo "warning: meta.scope=$sc disagrees with location ($loc)" >&2
fi
```

- [ ] Commit: `feat: validator warns on meta.scope/location drift`

## Task 4: consolidate skill — opt-in flow, routing classes, precedence rule

- [ ] RED — append to `tests/test_core_skills.sh` (sequence-aware, not
      keyword-presence):

```bash
grep -q "mkdir -m 700" "$ROOT/skills/consolidate/SKILL.md" && \
  grep -q "umask 077" "$ROOT/skills/consolidate/SKILL.md" && \
  awk '/mkdir -m 700/{a=NR} /umask 077/{b=NR} /trust --global/{c=NR} END{exit !(a && b && c && a<b && b<c)}' "$ROOT/skills/consolidate/SKILL.md"
assert_ok $? "consolidate creation flow in load-bearing order (mkdir -> umask cp -> trust --global)"
awk '/appended to the.*project store as a normal record/{a=NR} /scope-deferred/{b=NR} END{exit !(a && b && a<b)}' "$ROOT/skills/consolidate/SKILL.md"
assert_ok $? "deferral is record-then-event, in that order"
grep -qi "routing classes" "$ROOT/skills/consolidate/SKILL.md" && grep -qi "scoped-exception" "$ROOT/skills/consolidate/SKILL.md"
assert_ok $? "consolidate carries routing classes + cross-tier precedence"
```

- [ ] GREEN — add "## Global tier (opt-in, routing, precedence)" to the
      consolidate skill containing, verbatim-in-substance from the spec:
      the one-question creation flow in exact order (`mkdir -m 700` →
      `(umask 077; cp …)` → set scope → validate → regen-index →
      `trust --global`); deferral (candidate appended to the project
      store as a normal record, then the `scope-deferred` event, exact
      line); routing classes with per-candidate human confirmation; and
      **cross-tier precedence**: when a project record conflicts with a
      global record, the project record governs in-project and the flow
      appends `append-event <global-store> <id> scoped-exception session
    "project <name> overrides in-project: <project-record-id>"` —
      once, checked against the global record's existing events first.
- [ ] Commit: `feat: consolidate carries global opt-in, routing, and precedence`

## Task 5: review command — verify only

- [ ] Confirm `commands/review.md` names correct/delete/export for
      global records and the independence rule (its current text does).
      No edit expected; if a gap is found, patch with a RED grep in
      `tests/test_commands.sh` first.

## Task 6: longitudinal protocol — dated seventh source

- [ ] RED — append to `tests/test_docs.sh`:

```bash
grep -q "Cross-project citations" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md" && \
  grep -qE "2026-08-13 — amended" "$ROOT/docs/specs/2026-08-13-exp-longitudinal.md"
assert_ok $? "longitudinal spec carries the dated seventh-source amendment"
```

- [ ] GREEN — metrics table row:
      `| Cross-project citations | global records cited by work in a different project than their origin | trail refs + store events |`
      plus a `## Changelog` entry:
      `- 2026-08-13 — amended per the ratified global-tier spec: seventh source added (cross-project global-record citations); counts zero until a second governed project exists.`
- [ ] Commit: `feat: longitudinal protocol gains the cross-project source (dated amendment)`

## Task 7: release 0.5.0

- [ ] Version bumps, shown:

```bash
jq '.version = "0.5.0"' .claude-plugin/plugin.json > t && mv t .claude-plugin/plugin.json
jq '.version = "0.5.0" | .plugins[0].version = "0.5.0"' .claude-plugin/marketplace.json > t && mv t .claude-plugin/marketplace.json
```

- [ ] CHANGELOG `## [0.5.0] — 2026-08-13` section: global memory tier
      (opt-in store, dual-realpath trust adjacency with --global gate,
      [global] digest labels, scope-drift warnings, cross-tier
      precedence events, longitudinal seventh source).
- [ ] `bash tests/run.sh` fully green — acceptance gate.
- [ ] Commit: `feat: anoti 0.5.0 — global memory tier` ; push; CI tags.

## Out of scope (per spec)

Opt-in dialog exercised live (needs a real global candidate — arrives
with the second project); full precedence conflict-DETECTION exercised
live (fixture-tested here; first real occurrence per the spec's Testing
section, mirroring the opt-in framing); team sync; encryption beyond
file modes; global TODOS/LESSONS.
