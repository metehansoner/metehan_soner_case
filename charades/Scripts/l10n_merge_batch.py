#!/usr/bin/env python3
"""
Bir çeviri partisini dil dosyalarına yerleştirir.

Girdi: `{ "de": { "settings.haptics": "Vibration", ... }, ... }` biçiminde tek
bir JSON. Anahtarlar `--anchor` ile verilen anahtarın hemen ardına giriyor;
dosyada zaten varsa üzerine yazılıyor ve sırası korunuyor.

Kullanım:
  python3 Scripts/l10n_merge_batch.py batch.json --anchor settings.language
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIRECTORY = ROOT / "Charades" / "Resources" / "Localization"


def merge(code: str, additions: dict[str, str], anchor: str) -> int:
    path = DIRECTORY / f"{code}.json"
    if not path.exists():
        print(f"✗ {code}: dosya yok")
        return 0

    strings = json.loads(path.read_text(encoding="utf-8"))
    fresh = {k: v for k, v in additions.items() if k not in strings}

    for key, value in additions.items():
        if key in strings:
            strings[key] = value

    if fresh:
        if anchor not in strings:
            print(f"✗ {code}: çıpa {anchor!r} yok")
            return 0
        merged: dict[str, str] = {}
        for key, value in strings.items():
            merged[key] = value
            if key == anchor:
                merged.update(fresh)
        strings = merged

    path.write_text(
        json.dumps(strings, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return len(additions)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("batch", type=pathlib.Path)
    parser.add_argument("--anchor", required=True)
    args = parser.parse_args()

    batch = json.loads(args.batch.read_text(encoding="utf-8"))
    for code, additions in batch.items():
        count = merge(code, additions, args.anchor)
        print(f"{code}: {count} anahtar")
    return 0


if __name__ == "__main__":
    sys.exit(main())
