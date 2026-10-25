#!/usr/bin/env bash
# Sanity-check packages/*.txt (valid npm names, no duplicates). Used by CI.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rc=0
for f in "$ROOT"/packages/*.txt; do
  names="$(tr -d '\r' < "$f" | sed 's/[[:space:]]*#.*$//; s/^[[:space:]]*//; s/[[:space:]]*$//' | awk 'NF')"
  bad="$(printf '%s\n' "$names" | grep -Ev '^(@[a-z0-9._~-]+/)?[a-z0-9._~-]+(@[^[:space:]]+)?$' || true)"
  dup="$(printf '%s\n' "$names" | sort | uniq -d)"
  [ -n "$bad" ] && { echo "Invalid names in $f:"; echo "$bad"; rc=1; }
  [ -n "$dup" ] && { echo "Duplicates in $f:"; echo "$dup"; rc=1; }
done
[ "$rc" -eq 0 ] && echo "All package lists OK"
exit "$rc"
