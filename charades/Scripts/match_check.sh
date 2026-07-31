#!/bin/bash
# Takım Savaşı maç mantığını cihazsız doğrular
# (04-oyun-modlari.md §1, 09-kesinti-ve-sinir-durumlari.md §5).
#
# `swift a.swift b.swift` çoklu dosyada üst düzey kodu çalıştırmıyor —
# üst düzey kod yalnızca `main.swift`te izinli. O yüzden geçici bir dizine
# kopyalanıp swiftc ile derleniyor (bkz. tilt_check.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp "$ROOT/Charades/Models/Team.swift" "$WORK/"
cp "$ROOT/Charades/Models/TeamMatch.swift" "$WORK/"
cp "$ROOT/Scripts/match_check.swift" "$WORK/main.swift"

swiftc -O "$WORK/Team.swift" "$WORK/TeamMatch.swift" "$WORK/main.swift" -o "$WORK/run"
"$WORK/run"
