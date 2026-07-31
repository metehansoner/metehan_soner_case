#!/bin/bash
# Kelime listesi kurallarını cihazsız doğrular
# (05-desteler-ve-kategoriler.md §7, 02-ekran-akisi.md §24).
#
# Üst düzey kod yalnızca `main.swift`te izinli olduğu için kaynaklar geçici
# dizine kopyalanıp swiftc ile derleniyor (bkz. mix_check.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp "$ROOT/Charades/Models/WordList.swift" "$WORK/"
cp "$ROOT/Scripts/words_check.swift" "$WORK/main.swift"

swiftc -O "$WORK/WordList.swift" "$WORK/main.swift" -o "$WORK/run"
"$WORK/run"
