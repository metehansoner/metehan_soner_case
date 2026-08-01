#!/usr/bin/env python3
"""
Onboarding / Nasıl Oynanır illüstrasyonlarını uygulama türevine çevirir.

Deste kapaklarıyla aynı sıkıştırma mantığı (`build_deck_assets.py`, §01 §5.7):
master arşivde kalır, uygulamaya indirgenmiş palet türevi girer. İki fark var:

1. Tuval kare değil **4:3** (§01 §6.3 — sahnede iki taraf var, kareye sıkışınca
   figürler küçülüyor).
2. Görünen boyut kapaktan büyük: Nasıl Oynanır sayfasında illüstrasyon sheet'in
   tam genişliğini (~340 pt) kaplıyor, @3x'te 1020 px. Bu yüzden uzun kenar
   1024'te kalıyor, kapaklardaki 512'ye inmiyor.

Kullanım:
  /tmp/charades_venv/bin/python Scripts/build_illustration_assets.py
"""

from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Charedes_document" / "teslim" / "ekran-gorselleri"
ASSETS = ROOT / "Charades" / "Assets.xcassets" / "Illustrations"

LONG_EDGE = 1024
PALETTE_LEVELS = [64, 96, 128, 192, 256]
ERROR_BUDGET = 5.0

NAMES = ["ob_mime", "ob_forehead"]


def quantize(image: Image.Image, colors: int) -> Image.Image:
    # FASTOCTREE alfayı palet girdisinin parçası olarak taşıyor; MEDIANCUT
    # alfayı düşürüp şeffaf zemini siyaha çeviriyor.
    return image.quantize(colors=colors, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)


def visible_error(original: Image.Image, candidate: Image.Image) -> float:
    before = np.asarray(original, dtype=np.int16)
    after = np.asarray(candidate.convert("RGBA"), dtype=np.int16)
    visible = before[..., 3] > 8
    if not visible.any():
        return 0.0
    return float(np.abs(before[visible][..., :3] - after[visible][..., :3]).mean())


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

    total_in = total_out = 0

    for name in NAMES:
        master = SOURCE / f"{name}.png"
        if not master.exists():
            print(f"HATA: {master} yok", file=sys.stderr)
            return 2

        original = Image.open(master).convert("RGBA")
        scale = LONG_EDGE / max(original.size)
        size = (round(original.width * scale), round(original.height * scale))
        original = original.resize(size, Image.LANCZOS)

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
        (imageset / "Contents.json").write_text(
            json.dumps(
                {
                    "images": [{"filename": out.name, "idiom": "universal"}],
                    "info": {"author": "xcode", "version": 1},
                },
                indent=2,
            )
            + "\n"
        )

        total_in += master.stat().st_size
        total_out += out.stat().st_size
        print(f"{name:14s} {size[0]}×{size[1]}  palet {chosen:3d}  hata {best_error:.2f}")

    print(f"master : {total_in / 1024 / 1024:5.2f} MB")
    print(f"türev  : {total_out / 1024 / 1024:5.2f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
