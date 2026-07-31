#!/bin/bash
# Mix karıştırma algoritmasını cihazsız doğrular
# (05-desteler-ve-kategoriler.md §6).
#
# Üst düzey kod yalnızca `main.swift`te izinli olduğu için kaynaklar geçici
# dizine kopyalanıp swiftc ile derleniyor (bkz. match_check.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp "$ROOT/Charades/Models/Card.swift" "$WORK/"
cp "$ROOT/Charades/Models/WordPool.swift" "$WORK/"
cp "$ROOT/Scripts/mix_check.swift" "$WORK/main.swift"

swiftc -O "$WORK/Card.swift" "$WORK/WordPool.swift" "$WORK/main.swift" -o "$WORK/run"
"$WORK/run"
