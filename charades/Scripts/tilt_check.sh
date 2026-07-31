#!/bin/bash
# Tilt karar mantığını cihazsız doğrular (04-oyun-modlari.md §2).
#
# `swift a.swift b.swift` çoklu dosyada üst düzey kodu çalıştırmıyor —
# üst düzey kod yalnızca `main.swift`te izinli. O yüzden geçici bir dizine
# kopyalanıp swiftc ile derleniyor.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp "$ROOT/Charades/Models/TiltDetector.swift" "$WORK/"
cp "$ROOT/Scripts/tilt_check.swift" "$WORK/main.swift"

swiftc -O "$WORK/TiltDetector.swift" "$WORK/main.swift" -o "$WORK/run"
"$WORK/run"
