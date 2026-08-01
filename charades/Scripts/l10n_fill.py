#!/usr/bin/env python3
"""
Dil dosyasını tamamlar ve düzenler — 06-ayarlar-ve-lokalizasyon.md §2.

92 destenin `deck.*.desc` anahtarı İngilizce'de tek kalıp ("Play the X deck.")
ve elle çevrilecek bir metin taşımıyor; kalıp + o dildeki deste adı yeterli.
Kalıptan sapan açıklamalar (örnek desteler) dosyada zaten yazılıysa korunuyor.

Ayrıca anahtar sırasını `en.json` ile eşitliyor; Slav dillerinin fazladan
`.few` biçimi kendi `.one` biçiminin hemen ardına giriyor.

Kullanım:
  python3 Scripts/l10n_fill.py de 'Spiele das Deck „{title}“.'
"""

from __future__ import annotations

import collections
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIRECTORY = ROOT / "Charades" / "Resources" / "Localization"


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2

    code, template = sys.argv[1], sys.argv[2]
    path = DIRECTORY / f"{code}.json"
    english = json.loads((DIRECTORY / "en.json").read_text(encoding="utf-8"))
    strings = json.loads(path.read_text(encoding="utf-8"))

    filled = 0
    for key in english:
        if not (key.startswith("deck.") and key.endswith(".desc")):
            continue
        if strings.get(key):
            continue
        title = strings.get(key[: -len("desc")] + "title")
        if not title:
            print(f"✗ {key}: başlık yok, açıklama üretilemiyor")
            return 1
        strings[key] = template.format(title=title)
        filled += 1

    ordered = collections.OrderedDict()
    for key in english:
        if key in strings:
            ordered[key] = strings[key]
        if key.endswith(".one") and (few := key[: -len("one")] + "few") in strings:
            ordered[few] = strings[few]

    leftover = [key for key in strings if key not in ordered]
    if leftover:
        print(f"✗ {code}: en.json'da olmayan anahtar: {leftover}")
        return 1

    path.write_text(json.dumps(ordered, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"✓ {code}: {len(ordered)} anahtar ({filled} açıklama kalıptan üretildi)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
