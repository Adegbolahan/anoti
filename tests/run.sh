#!/bin/bash
# anoti test harness: sources every tests/test_*.sh; those call assert_eq/assert_ok.
# Results are appended to the RESULTS file (exported) so assertions made inside
# ( cd ... ) subshells still count in the final tally.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS="$(mktemp)"
export ROOT RESULTS
assert_eq() { # got want label
  if [ "$1" = "$2" ]; then echo "P" >> "$RESULTS"; else echo "F" >> "$RESULTS"; echo "FAIL: $3 (want: '$2' got: '$1')"; fi
}
assert_ok() { # exitcode label
  if [ "$1" -eq 0 ]; then echo "P" >> "$RESULTS"; else echo "F" >> "$RESULTS"; echo "FAIL: $2 (exit $1)"; fi
}
command -v yq >/dev/null || { echo "missing dependency: yq"; exit 1; }
command -v jq >/dev/null || { echo "missing dependency: jq"; exit 1; }
# shellcheck disable=SC1090  # test files are sourced dynamically by design
for t in "$ROOT"/tests/test_*.sh; do . "$t"; done
PASS="$(grep -c '^P' "$RESULTS")"; FAIL="$(grep -c '^F' "$RESULTS")"
rm -f "$RESULTS"
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
