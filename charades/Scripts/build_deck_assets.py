#!/usr/bin/env python3
"""
Deste kapaklarını uygulama türevine çevirir.
Kaynak: 01-tasarim-sistemi.md §5.7 — master 1024 RGBA arşivde kalır,
uygulamaya 512 px'lik indirgenmiş palet türevi girer.

§5.7 sabit "64 renk" öneriyor ve ortalama hatayı 1.7/255 ölçüyor. O ölçüm
kapağın ~%75'ini kaplayan **şeffaf** pikselleri de ortalamaya katıyor; yalnızca
görünür piksellere bakınca aynı ayarın hatası 7.2/255 çıkıyor ve gözle
görülüyor: `deck_dance`in disko topundaki teal karolar 64 renkte tamamen
kayboluyor, `deck_instruments`in halftone dokusu düzleşiyor.

Bu yüzden renk sayısı sabit değil, kapak başına **kalite hedefiyle** seçiliyor:
görünür piksel hatası eşiğin altına inen en küçük palet. Çoğu kapak 96–128'de
kalıyor, yalnızca çok tonlu birkaçı 256'ya çıkıyor.

Kullanım:
  /tmp/charades_venv/bin/python Scripts/build_deck_assets.py
"""

from __future__ import annotations

import io
import json
import shutil
import sys
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / "Charedes_document" / "teslim" / "deste-kapaklari"
ASSETS = ROOT / "Charades" / "Assets.xcassets" / "DeckCovers"

SIZE = 512
PALETTE_LEVELS = [64, 96, 128, 192, 256]
ERROR_BUDGET = 5.0


def quantize(image: Image.Image, colors: int) -> Image.Image:
    # FASTOCTREE alfayı palet girdisinin parçası olarak taşıyor. MEDIANCUT
    # alfayı düşürüyor ve şeffaf zemin siyaha dönüyor.
    return image.quantize(colors=colors, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)


def visible_error(original: Image.Image, candidate: Image.Image) -> float:
    before = np.asarray(original, dtype=np.int16)
    after = np.asarray(candidate.convert("RGBA"), dtype=np.int16)
    visible = before[..., 3] > 8
    if not visible.any():
        return 0.0
    return float(np.abs(before[visible][..., :3] - after[visible][..., :3]).mean())


def contents_for(filename: str) -> dict:
    # Tek ölçekli universal: kart ızgarada ~180pt, amblem kartın %80'i →
    # @3x'te 432 px görünüyor, 512 tek dosya yetiyor (§01 §5.7).
    return {
        "images": [{"filename": filename, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }


def main() -> int:
    if not SOURCE.exists():
        print(f"HATA: kaynak yok: {SOURCE}", file=sys.stderr)
        return 2

    if ASSETS.exists():
        shutil.rmtree(ASSETS)
    ASSETS.mkdir(parents=True)
    (ASSETS / "Contents.json").write_text(
        json.dumps(
            {"info": {"author": "xcode", "version": 1}, "properties": {"provides-namespace": False}},
            indent=2,
        )
        + "\n"
    )

    masters = sorted(SOURCE.glob("deck_*.png"))
    if not masters:
        print(f"HATA: {SOURCE} içinde deck_*.png yok", file=sys.stderr)
        return 2

    levels = Counter()
    errors: list[float] = []
    total_in = total_out = 0

    for master in masters:
        name = master.stem
        original = Image.open(master).convert("RGBA").resize((SIZE, SIZE), Image.LANCZOS)

        chosen = PALETTE_LEVELS[-1]
        best = quantize(original, chosen)
        best_error = visible_error(original, best)
        for colors in PALETTE_LEVELS:
            candidate = quantize(original, colors)
            error = visible_error(original, candidate)
            if error <= ERROR_BUDGET:
                chosen, best, best_error = colors, candidate, error
                break

        imageset = ASSETS / f"{name}.imageset"
        imageset.mkdir()
        out = imageset / f"{name}.png"
        best.save(out, optimize=True)
        (imageset / "Contents.json").write_text(json.dumps(contents_for(out.name), indent=2) + "\n")

        levels[chosen] += 1
        errors.append(best_error)
        total_in += master.stat().st_size
        total_out += out.stat().st_size

    print(f"{len(masters)} kapak · hedef ≤ {ERROR_BUDGET}/255 görünür piksel hatası")
    print(f"master : {total_in / 1024 / 1024:6.2f} MB")
    print(f"türev  : {total_out / 1024 / 1024:6.2f} MB")
    print(f"palet  : {dict(sorted(levels.items()))}")
    print(f"hata   : ort {np.mean(errors):.2f}  max {np.max(errors):.2f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
