#!/usr/bin/env bash
# Local test runner. CI runs the same suite via .github/workflows/ci.yml.
#
#   ./test/run.sh              # everything
#   ./test/run.sh regression   # one directory
set -euo pipefail

cd "$(dirname "$0")/.."

for tool in bats jq; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "missing: $tool"
    echo "  macOS: brew install bats-core jq"
    echo "  linux: apt-get install bats jq"
    exit 1
  }
done

target="test/${1:-}"
echo "running: $target"
exec bats --recursive --print-output-on-failure "$target"
