#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
run() { bash "$here/latest-version.sh" "$1"; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# 1. max semver no lexicografico: 2.0.10 > 2.0.9
printf '{"tags":["2.0.9","2.0.10","1.2.10","latest","2.0.2"]}' > "$tmp/a.json"
[ "$(run "$tmp/a.json")" = "2.0.10" ] || { echo "FAIL caso 1: $(run "$tmp/a.json")"; exit 1; }

# 2. ignora major distinta y ruido
printf '{"tags":["3.0.0","1.0.94","latest","2.2.5","2.2.4"]}' > "$tmp/b.json"
[ "$(run "$tmp/b.json")" = "2.2.5" ] || { echo "FAIL caso 2: $(run "$tmp/b.json")"; exit 1; }

# 3. sin ningun 2.x -> exit 1
printf '{"tags":["1.2.10","latest"]}' > "$tmp/c.json"
if run "$tmp/c.json" >/dev/null 2>&1; then echo "FAIL caso 3: debio fallar"; exit 1; fi

echo "OK"
