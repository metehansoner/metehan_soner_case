#!/usr/bin/env python3
"""
Açılış (ekran 1) görsellerini üretir — 02-ekran-akisi.md §4, 08-sinematik-detaylar.md A3.

Neden görsel, neden çizim değil: A3'ün son maddesi statik launch screen ile
devamlılık istiyor. iOS'un gösterdiği launch screen bir storyboard, orada
SwiftUI çizimi çalıştırılamıyor. Aynı kareyi iki teknolojiyle iki kez çizmek
kaçınılmaz olarak ayrışıyor ve tam da kaçınılmak istenen zıplamayı üretiyor.
Bu yüzden iki kare de **aynı PNG**: storyboard `UIImageView` ile, `CurtainReveal`
`Image` ile aynı dosyayı aynı ölçekleme kuralıyla (aspect fill / sabit boyut)
gösteriyor.

Üretilenler:
  launch_curtain — tam ekran kapalı perde (dikey kıvrımlar)
  launch_plaque  — pirinç çerçeve + krem paspartu + app ikonu

Kullanım:
  /tmp/charades_venv/bin/python Scripts/build_launch_assets.py
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ICON = ROOT.parent / "Charedes_document" / "teslim" / "app-ikonu" / "ikon-1024.png"
ASSETS = ROOT / "Charades" / "Assets.xcassets" / "Launch"

# §01 §1 renk jetonları — `AppColors` ile birebir aynı olmak zorunda.
VELVET_DEEP = (0x2B, 0x0E, 0x15)
VELVET_MID = (0x47, 0x16, 0x1F)
VELVET_LIGHT = (0x5E, 0x1E, 0x27)
FILM_BLACK = (0x10, 0x0C, 0x0A)
POSTER = (0xF4, 0xE7, 0xCE)
BRASS = (0xA8, 0x79, 0x1F)
GOLD = (0xE3, 0xC3, 0x6A)

# En büyük iPhone çözünürlüğü; küçük ekranlar aspect fill ile kırpıyor.
# Desen dikey şeritlerden ibaret olduğu için kırpma fark edilmiyor.
CURTAIN_SIZE = (1290, 2796)
# Kıvrım genişliği @3x nokta cinsinden 26pt (`CurtainDrape.foldWidth`).
FOLD_WIDTH = 78

# Levha 168pt, ortasında 104pt ikon (§02 §4 ekran 1).
PLAQUE_PT = 168
SCALE = 3


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def fold_color(x_in_fold: float) -> tuple[int, int, int]:
    """Kıvrım içinde ışık ortada toplanıyor, iki yana koyulaşıyor (§01 §3)."""
    stops = [VELVET_DEEP, VELVET_MID, VELVET_LIGHT, VELVET_MID, VELVET_DEEP]
    position = x_in_fold * (len(stops) - 1)
    index = min(int(position), len(stops) - 2)
    return lerp(stops[index], stops[index + 1], position - index)


def build_curtain() -> Image.Image:
    width, height = CURTAIN_SIZE
    image = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(image)

    for x in range(width):
        draw.line([(x, 0), (x, height)], fill=fold_color((x % FOLD_WIDTH) / FOLD_WIDTH))

    # Üstteki ışık: perdenin toplandığı korniş hizası.
    top = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    top_draw = ImageDraw.Draw(top)
    band = round(height * 0.1)
    for y in range(band):
        alpha = round(120 * (1 - y / band))
        top_draw.line([(0, y), (width, y)], fill=(*VELVET_LIGHT, alpha))
    image = Image.alpha_composite(image.convert("RGBA"), top)

    # Ortadaki birleşme yerinde ince altın şerit (§02 §4 madde 4).
    seam = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    seam_draw = ImageDraw.Draw(seam)
    center = width // 2
    for offset in range(-9, 10):
        alpha = round(150 * math.cos(offset / 9 * math.pi / 2) ** 2)
        seam_draw.line([(center + offset, 0), (center + offset, height)], fill=(*GOLD, alpha))
    image = Image.alpha_composite(image, seam)

    # Kenarlarda vignette: perde kenarları duvara yaklaşırken kararıyor.
    vignette = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette)
    edge = round(width * 0.22)
    for x in range(edge):
        alpha = round(150 * (1 - x / edge) ** 2)
        vignette_draw.line([(x, 0), (x, height)], fill=(*FILM_BLACK, alpha))
        vignette_draw.line([(width - 1 - x, 0), (width - 1 - x, height)], fill=(*FILM_BLACK, alpha))
    image = Image.alpha_composite(image, vignette)

    return image.convert("RGB")


def build_plaque() -> Image.Image:
    side = PLAQUE_PT * SCALE
    image = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    radius = 10 * SCALE
    # Dışta pirinç profil: düz bir dolgu yerine üstten aydınlanan bir gradient,
    # metal ancak ışık aldığı yön belliyse metal gibi duruyor.
    for inset in range(6 * SCALE):
        tone = lerp(GOLD, BRASS, inset / (6 * SCALE))
        draw.rounded_rectangle(
            [inset, inset, side - 1 - inset, side - 1 - inset],
            radius=max(radius - inset, 2),
            outline=tone,
            width=1,
        )
    draw.rounded_rectangle(
        [6 * SCALE, 6 * SCALE, side - 1 - 6 * SCALE, side - 1 - 6 * SCALE],
        radius=radius - 4,
        fill=BRASS,
    )

    # Krem paspartu.
    mat = 14 * SCALE
    draw.rounded_rectangle(
        [mat, mat, side - 1 - mat, side - 1 - mat],
        radius=6 * SCALE,
        fill=POSTER,
    )

    # §02 §4: ortada 104 pt ikon. Kalanı çerçeve (14 pt) ve paspartu (18 pt);
    # paspartu görünmezse levha çerçeveli bir eser değil, kenarlıklı bir ikon
    # oluyor — çerçevenin tek amacı bu ayrım.
    icon_side = 104 * SCALE
    icon = Image.open(ICON).convert("RGBA").resize((icon_side, icon_side), Image.LANCZOS)
    mask = Image.new("L", (icon_side, icon_side), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, icon_side - 1, icon_side - 1], radius=round(icon_side * 0.22), fill=255
    )
    offset = (side - icon_side) // 2
    image.paste(icon, (offset, offset), mask)

    # İkonun kendi zemini de krem: paspartuyla aynı renk olduğu için sınır
    # kayboluyor ve ikon "çerçeveye basılmış" gibi duruyor. İnce pirinç hat
    # ikiyi ayırıyor.
    draw.rounded_rectangle(
        [offset - 1, offset - 1, offset + icon_side, offset + icon_side],
        radius=round(icon_side * 0.22),
        outline=BRASS,
        width=max(SCALE // 2, 1),
    )

    # Dört köşede vida başı: çerçeveyi "asılmış" gösteren tek detay.
    screw = 4 * SCALE
    pad = 9 * SCALE
    for cx, cy in [(pad, pad), (side - pad, pad), (pad, side - pad), (side - pad, side - pad)]:
        draw.ellipse(
            [cx - screw / 2, cy - screw / 2, cx + screw / 2, cy + screw / 2],
            fill=lerp(GOLD, POSTER, 0.35),
            outline=BRASS,
        )
        draw.line([cx - screw / 3, cy, cx + screw / 3, cy], fill=BRASS, width=max(SCALE // 2, 1))

    return image


def write(name: str, image: Image.Image, scale: str) -> None:
    folder = ASSETS / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    filename = f"{name}.png"
    image.save(folder / filename, optimize=True)
    (folder / "Contents.json").write_text(
        json.dumps(
            {
                "images": [{"filename": filename, "idiom": "universal", "scale": scale}],
                "info": {"author": "xcode", "version": 1},
            },
            indent=2,
        )
        + "\n"
    )
    size_kb = (folder / filename).stat().st_size / 1024
    print(f"{name}: {image.size[0]}×{image.size[1]} · {size_kb:.0f} KB")


def main() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    (ASSETS / "Contents.json").write_text(
        json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n"
    )
    # Perde tek ölçekte: zaten ekranı dolduruyor, @1x/@2x türevleri aynı
    # dosyanın küçültülmüşü olurdu.
    write("launch_curtain", build_curtain(), "1x")
    write("launch_plaque", build_plaque(), "3x")


if __name__ == "__main__":
    main()
