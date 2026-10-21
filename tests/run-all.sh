#!/usr/bin/env bash
# Run the hub's installer tests and every pack's tests.
# Usage: tests/run-all.sh
set -u

HUB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
status=0
for t in "$HUB/tests/installer.sh" "$HUB"/packs/*/tests/run.sh; do
  echo "== ${t#"$HUB"/}"
  bash "$t" || status=1
done
[ "$status" -eq 0 ] && echo "All tests passed." || echo "Some tests failed."
exit "$status"
