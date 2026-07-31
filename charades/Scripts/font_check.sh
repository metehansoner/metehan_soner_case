#!/bin/bash
# Locale başına font kapsamını cihazsız doğrular (01-tasarim-sistemi.md §2).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp "$ROOT/Scripts/font_check.swift" "$WORK/main.swift"

swiftc -O "$WORK/main.swift" -o "$WORK/run"
"$WORK/run" "$ROOT/Charades/Resources/Fonts"
