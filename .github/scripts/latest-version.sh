#!/usr/bin/env bash
# Prints the highest 2.x.y tag (numeric semver) found in a GHCR tags JSON file.
# Usage: latest-version.sh <json-tags-file>
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  echo "usage: latest-version.sh <json-tags-file>" >&2
  exit 2
fi

latest="$(grep -oE '"[0-9]+\.[0-9]+\.[0-9]+"' "$1" \
  | tr -d '"' \
  | grep -E '^2\.[0-9]+\.[0-9]+$' \
  | sort -t. -k1,1n -k2,2n -k3,3n \
  | tail -n1 || true)"

if [ -z "$latest" ]; then
  echo "no 2.x.y tag found in $1" >&2
  exit 1
fi

echo "$latest"
