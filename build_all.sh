#!/bin/bash

set -uo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

passed=()
failed=()

for lang_dir in */; do
  for demo_dir in "$lang_dir"*/; do
    [ -x "${demo_dir}build.sh" ] || continue

    label="${demo_dir%/}"
    echo
    echo "=== $label ==="
    if (cd "$demo_dir" && ./build.sh); then
      passed+=("$label")
    else
      failed+=("$label")
    fi
  done
done

echo
echo "=== Summary ==="
echo "Passed (${#passed[@]}):"
for d in "${passed[@]}"; do echo "  $d"; done
if [ ${#failed[@]} -gt 0 ]; then
  echo "Failed (${#failed[@]}):"
  for d in "${failed[@]}"; do echo "  $d"; done
  exit 1
fi
