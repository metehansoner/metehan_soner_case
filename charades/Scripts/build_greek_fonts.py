#!/usr/bin/env python3
"""
Yunanca font ikamesi — 01-tasarim-sistemi.md §2.

Oswald, Playfair Display ve Rubik'in hiçbirinde Yunan glifi yok; `el` locale'i
üç rolü de başka ailelere devrediyor:

    display → Fira Sans Condensed (Bold, ExtraBold)
    accent  → EB Garamond (Bold, Bold Italic)
    ui      → Fira Sans (Regular, Medium, SemiBold, Bold)

§2 "Sadece Yunan subset'i gömülür, Latin kopyaları bundle'a girmez" diyor. Tam
Latin'i atmak yine de doğru değil: Yunanca ekranda da rakam, saat ayırıcısı ve
`CHARADES` marka adı var; onlar için gömülü fonttan düşmek satır ortasında aile
değiştirir. O yüzden subset = Yunan + Yunan Ext + ASCII + tipografik noktalama.

EB Garamond upstream'de değişken font; sabit ağırlık örnekleri (wght=700)
çıkarılıyor, çünkü `UIFont(name:)` değişken eksene erişmiyor.

Kullanım:
  /tmp/charades_venv/bin/pip install fonttools brotli
  /tmp/charades_venv/bin/python Scripts/build_greek_fonts.py
"""

from __future__ import annotations

import io
import pathlib
import sys
import time
import urllib.parse
import urllib.request

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

RAW = "https://raw.githubusercontent.com/google/fonts/main/"
DEST = pathlib.Path(__file__).resolve().parent.parent / "Charades" / "Resources" / "Fonts"

# Yunan + Yunan Ext (politonik) + Latin ASCII + noktalama + para/oklar.
UNICODES = [
    "U+0020-007E",
    "U+00A0-00FF",
    "U+0374-03FF",
    "U+1F00-1FFF",
    "U+2000-206F",
    "U+20AC",
    "U+2122",
    "U+2190-2193",
]

# (kaynak yol, hedef dosya, değişken fonttan çıkarılacak ağırlık)
JOBS = [
    ("ofl/firasanscondensed/FiraSansCondensed-Bold.ttf", "FiraSansCondensed-Bold.ttf", None),
    ("ofl/firasanscondensed/FiraSansCondensed-ExtraBold.ttf", "FiraSansCondensed-ExtraBold.ttf", None),
    ("ofl/firasans/FiraSans-Regular.ttf", "FiraSans-Regular.ttf", None),
    ("ofl/firasans/FiraSans-Medium.ttf", "FiraSans-Medium.ttf", None),
    ("ofl/firasans/FiraSans-SemiBold.ttf", "FiraSans-SemiBold.ttf", None),
    ("ofl/firasans/FiraSans-Bold.ttf", "FiraSans-Bold.ttf", None),
    ("ofl/ebgaramond/EBGaramond[wght].ttf", "EBGaramond-Bold.ttf", 700),
    ("ofl/ebgaramond/EBGaramond-Italic[wght].ttf", "EBGaramond-BoldItalic.ttf", 700),
]


def download(path: str, attempts: int = 5) -> bytes:
    url = RAW + urllib.parse.quote(path, safe="/")
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(url, timeout=60) as response:
                return response.read()
        except Exception as error:  # ağ tarafı ardışık indirmelerde bağlantı kapatabiliyor
            if attempt == attempts - 1:
                raise
            print(f"  yeniden deneniyor ({error})")
            time.sleep(2 * (attempt + 1))
    raise RuntimeError("ulaşılamaz")


def build(source: str, target: str, weight: int | None) -> None:
    raw = download(source)
    font = TTFont(io.BytesIO(raw))

    if weight is not None:
        font = instancer.instantiateVariableFont(font, {"wght": weight}, updateFontNames=True)

    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    options.recalc_bounds = True
    options.drop_tables += ["DSIG"]

    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=subset.parse_unicodes(",".join(UNICODES)))
    subsetter.subset(font)

    out = DEST / target
    font.save(out)
    print(f"{target:34} {len(raw) // 1024:5} KB → {out.stat().st_size // 1024:4} KB   "
          f"PostScript: {postscript_name(out)}")


def postscript_name(path: pathlib.Path) -> str:
    font = TTFont(path)
    record = font["name"].getDebugName(6)
    font.close()
    return record or "?"


def main() -> int:
    DEST.mkdir(parents=True, exist_ok=True)
    for source, target, weight in JOBS:
        build(source, target, weight)
    return 0


if __name__ == "__main__":
    sys.exit(main())
