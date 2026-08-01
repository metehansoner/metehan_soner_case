#!/usr/bin/env python3
"""
App Store ekran görüntüsü seti — 01-tasarim-sistemi.md §6.3 kalem 4.

Simülatörden ham kare alıp üzerine sinema afişi kompozisyonu kuruyor: kadife
zemin, üstte Oswald başlık, ortada altın çerçeveli cihaz. Çerçeve ve zemin
kodun kendi token'larından (§ `01` §1) geliyor; ayrı bir tasarım dosyası yok.

Başlık metinleri **uydurulmuyor**, `Resources/Localization/<dil>.json`tan
okunuyor. Böylece aynı script 25 dilin herhangi biri için set üretebiliyor ve
mağaza metniyle uygulama metni birbirinden ayrışmıyor.

Kullanım:
  python3 Scripts/build_store_screenshots.py                 # 6.9" + 6.5", İngilizce
  python3 Scripts/build_store_screenshots.py --lang tr
  python3 Scripts/build_store_screenshots.py --size 6.9 --scene home
  python3 Scripts/build_store_screenshots.py --compose-only  # yeniden çekmeden diz

Bağımlılık: Pillow. Arapça başlık için `arabic-reshaper` + `python-bidi`
(sistem SF Arabic ile sunum biçimleri çiziliyor; Rubik OpenType birleştirmesi
PIL'de yok).

Çıktı: `Store/screenshots/<dil>/<boyut>/NN-<sahne>.png`
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys
import time

from PIL import Image, ImageDraw, ImageFilter, ImageFont

try:
    import arabic_reshaper
    from bidi.algorithm import get_display
except ImportError:  # pragma: no cover
    arabic_reshaper = None
    get_display = None

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONTS = ROOT / "Charades" / "Resources" / "Fonts"
L10N = ROOT / "Charades" / "Resources" / "Localization"
OUT = ROOT / "Store" / "screenshots"
RAW = pathlib.Path("/tmp/charades_store_raw")
APP = pathlib.Path("/tmp/charades_dd/Build/Products/Debug-iphonesimulator/Charades.app")
BUNDLE_ID = "com.metes.charades"

# § `01` §1 renk tablosu.
BG_VELVET_MID = (0x47, 0x16, 0x1F)
BG_VELVET_DEEP = (0x2B, 0x0E, 0x15)
BG_FILM_BLACK = (0x10, 0x0C, 0x0A)
BG_SPOTLIGHT = (0x8A, 0x4B, 0x1E)
ACCENT_GOLD = (0xE3, 0xC3, 0x6A)
ACCENT_AMBER = (0xF0, 0xA9, 0x3B)
TEXT_CREAM = (0xF6, 0xEB, 0xD6)

# App Store Connect'in iki zorunlu iPhone yuvası. Piksel ölçüleri sabit;
# simülatör bulunamazsa script kendi cihazını oluşturuyor.
SIZES = {
    "6.9": {
        "device": "iPhone 17 Pro Max",
        "device_type": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max",
        "canvas": (1320, 2868),
    },
    "6.5": {
        "device": "iPhone 11 Pro Max",
        "device_type": "com.apple.CoreSimulator.SimDeviceType.iPhone-11-Pro-Max",
        "canvas": (1242, 2688),
    },
}

# Her sahne: başlık anahtarı (ya da düz metin), açılış bayrakları ve kaç saniye
# beklendiği. Bekleme süreleri animasyonlu ekranlarda daha uzun — klaket ve
# perde arası kendi süreleri dolmadan kare vermiyor.
SCENES = [
    {
        "id": "home",
        "headline": ["paywall.summary.content"],
        "arguments": ["-Premium"],
        "settle": 4.0,
    },
    {
        "id": "game",
        "headline": ["onboarding.forehead.title"],
        "arguments": ["-Premium", "-StartGame", "movieClassics", "-SkipRotate"],
        # Klaket + geri sayım 5 sn sürüyor; kare ilk kelimede alınmalı.
        "settle": 8.0,
        # Simülatör cihazı portre kalıyor, uygulama içeriği kendi çeviriyor:
        # ham kare yan yatmış geliyor, afişte doğrultuluyor.
        "rotate": 90,
        # Yatay kare afişin yarısını boş bırakıyor; kuralın kendi cümlesi
        # (onboarding adım 2) o boşluğu dolduruyor.
        "sub": "onboarding.forehead.body",
    },
    {
        "id": "modes",
        "headline": ["mode.select.title"],
        "arguments": ["-Premium", "-ModeSelect"],
        "settle": 4.0,
    },
    {
        "id": "teams",
        "headline": ["mode.teams.title"],
        "arguments": ["-TeamRoster", "-TeamSetup"],
        "settle": 4.0,
    },
    {
        "id": "archive",
        "headline": ["archive.title"],
        "arguments": ["-FakeReplay", "-SeedArchive", "8", "-Archive"],
        "settle": 5.0,
    },
    {
        "id": "words",
        "headline": ["mode.ownWords.title"],
        "arguments": ["-Premium", "-NoKeyboard", "-Basket", "9", "-WordBasket"],
        "settle": 4.0,
    },
]

PLACEHOLDER = re.compile(r"\{(\w+)\}")
# `paywall.summary.content` sayıları çalışma zamanında dolduruyor; başlıkta da
# aynı üç sayı yazıyor (§ `03` §2 iki satır özeti).
SUMMARY_VALUES = {"decks": "92", "cards": "12.000", "languages": "25"}


def run(*command: str, check: bool = True) -> str:
    result = subprocess.run(command, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"✗ {' '.join(command)}\n{result.stderr.strip()}")
        sys.exit(1)
    return result.stdout


def strings(language: str) -> dict[str, str]:
    path = L10N / f"{language}.json"
    if not path.exists():
        print(f"✗ {language}.json yok")
        sys.exit(1)
    return json.loads(path.read_text(encoding="utf-8"))


def headline(scene: dict, table: dict[str, str]) -> str:
    parts = []
    for key in scene["headline"]:
        value = table.get(key, key)
        parts.append(PLACEHOLDER.sub(lambda m: SUMMARY_VALUES.get(m.group(1), m.group(0)), value))
    return " ".join(parts)


# MARK: Simülatör


def device_udid(size: dict) -> str:
    listing = json.loads(run("xcrun", "simctl", "list", "devices", "--json"))
    for devices in listing["devices"].values():
        for device in devices:
            if device["name"] == size["device"] and device.get("isAvailable"):
                return device["udid"]

    runtimes = json.loads(run("xcrun", "simctl", "list", "runtimes", "--json"))["runtimes"]
    available = [r for r in runtimes if r.get("isAvailable")]
    if not available:
        print("✗ kullanılabilir iOS runtime yok")
        sys.exit(1)
    newest = sorted(available, key=lambda r: r["version"])[-1]
    print(f"  · {size['device']} yok, {newest['name']} ile oluşturuluyor")
    return run(
        "xcrun", "simctl", "create", size["device"], size["device_type"], newest["identifier"]
    ).strip()


def boot(udid: str) -> None:
    run("xcrun", "simctl", "boot", udid, check=False)
    run("xcrun", "simctl", "bootstatus", udid, check=False)
    # Durum çubuğu her karede aynı olsun: saat 9:41, şebeke ve pil dolu.
    run(
        "xcrun", "simctl", "status_bar", udid, "override",
        "--time", "9:41",
        "--dataNetwork", "wifi",
        "--wifiMode", "active",
        "--wifiBars", "3",
        "--cellularMode", "active",
        "--cellularBars", "4",
        "--batteryState", "charged",
        "--batteryLevel", "100",
        check=False,
    )


def capture(udid: str, scene: dict, language: str, target: pathlib.Path) -> None:
    # `-NoFirstRun` olmadan onboarding sheet'i her karenin üstünü kapatıyor.
    arguments = ["-SkipSplash", "-NoFirstRun", "-Lang", language, *scene["arguments"]]
    run("xcrun", "simctl", "launch", "--terminate-running-process", udid, BUNDLE_ID, *arguments)
    time.sleep(scene["settle"])
    target.parent.mkdir(parents=True, exist_ok=True)
    run("xcrun", "simctl", "io", udid, "screenshot", str(target))


# MARK: Kompozisyon


def background(canvas: tuple[int, int]) -> Image.Image:
    width, height = canvas
    image = Image.new("RGB", canvas, BG_FILM_BLACK)
    draw = ImageDraw.Draw(image)

    # Dikey kadife geçişi: üstte orta ton, altta film siyahı (§ `01` §1).
    for y in range(height):
        t = y / (height - 1)
        eased = t ** 0.85
        color = tuple(
            round(BG_VELVET_MID[i] + (BG_FILM_BLACK[i] - BG_VELVET_MID[i]) * eased)
            for i in range(3)
        )
        draw.line([(0, y), (width, y)], fill=color)

    # Üst-orta sıcak spot: gradient'in kendisi düz, ışık onu kırıyor.
    glow = Image.new("L", canvas, 0)
    radius = int(width * 0.78)
    ImageDraw.Draw(glow).ellipse(
        [width // 2 - radius, -radius, width // 2 + radius, int(height * 0.42)],
        fill=86,
    )
    glow = glow.filter(ImageFilter.GaussianBlur(width * 0.09))
    image = Image.composite(Image.new("RGB", canvas, BG_SPOTLIGHT), image, glow)

    # Perde kıvrımları: dikey, çok düşük kontrastlı bantlar.
    folds = Image.new("RGBA", canvas, (0, 0, 0, 0))
    fold_draw = ImageDraw.Draw(folds)
    step = width // 14
    for x in range(0, width, step):
        fold_draw.rectangle([x, 0, x + step // 2, height], fill=(*BG_VELVET_DEEP, 46))
    folds = folds.filter(ImageFilter.GaussianBlur(step * 0.35))
    image = Image.alpha_composite(image.convert("RGBA"), folds).convert("RGB")
    return image


def tracked_text(
    draw: ImageDraw.ImageDraw,
    position: tuple[int, int],
    text: str,
    font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
    tracking: float,
) -> None:
    """PIL'de harf aralığı yok; §2'nin geniş aralığı harf harf çiziliyor."""
    if tracking == 0:
        # Arapça bitişik; harf harf çizmek bağlantıyı bozar.
        draw.text(position, text, font=font, fill=fill)
        return
    x, y = position
    for character in text:
        draw.text((x, y), character, font=font, fill=fill)
        x += draw.textlength(character, font=font) + tracking


def tracked_width(
    draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, tracking: float
) -> float:
    return sum(draw.textlength(c, font=font) for c in text) + tracking * max(len(text) - 1, 0)


def wrap(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont,
    tracking: float,
    limit: float,
) -> list[str]:
    lines: list[str] = []
    current = ""
    for word in text.split():
        candidate = f"{current} {word}".strip()
        if current and tracked_width(draw, candidate, font, tracking) > limit:
            lines.append(current)
            current = word
        else:
            current = candidate
    if current:
        lines.append(current)
    return lines


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius, fill=255)
    return mask


def title_font(size: int, rtl: bool) -> ImageFont.FreeTypeFont:
    # § `01` §2: Oswald'da Arap glifi yok. Rubik'te Arap var ama OpenType
    # birleştirmesiyle; PIL raqm olmadan FE70 sunum biçimlerini çizemiyor.
    # Mağaza başlığı için sistemin sunum biçimli SF Arabic'i kullanılıyor.
    if rtl:
        return ImageFont.truetype("/System/Library/Fonts/SFArabic.ttf", size)
    return ImageFont.truetype(str(FONTS / "Oswald-Bold.ttf"), size)


def body_font(size: int, rtl: bool) -> ImageFont.FreeTypeFont:
    if rtl:
        return ImageFont.truetype("/System/Library/Fonts/SFArabic.ttf", size)
    return ImageFont.truetype(str(FONTS / "FiraSans-Regular.ttf"), size)


def shape(text: str, rtl: bool) -> str:
    if not rtl:
        # Türkçe `i` → `İ`; Python'un `upper()`ı onu `I` yapıyor.
        return text.replace("i", "İ").replace("ı", "I").upper()
    if arabic_reshaper is None or get_display is None:
        return text
    return get_display(arabic_reshaper.reshape(text))


def compose(
    shot: Image.Image,
    text: str,
    canvas: tuple[int, int],
    rtl: bool,
    subtitle: str | None = None,
) -> Image.Image:
    width, height = canvas
    image = background(canvas)
    draw = ImageDraw.Draw(image)

    title_size = round(width * 0.062)
    font = title_font(title_size, rtl)
    # § `01` §2: ALL CAPS + geniş aralık. Arapça bitişik yazıldığı için aralık
    # yalnızca ayrık alfabelerde (uygulamadaki `appTracking` kuralının aynısı).
    tracking = 0 if rtl else title_size * 0.055
    caption = shape(text, rtl)

    top = round(height * 0.055)
    lines = wrap(draw, caption, font, tracking, width * 0.84)
    for line in lines:
        line_width = tracked_width(draw, line, font, tracking)
        tracked_text(draw, ((width - line_width) / 2, top), line, font, TEXT_CREAM, tracking)
        top += round(title_size * 1.22)

    # Başlığın altındaki ince altın çizgi — uygulamadaki `goldRule`ın aynısı.
    rule_y = top + round(title_size * 0.42)
    rule_half = round(width * 0.14)
    draw.line(
        [(width // 2 - rule_half, rule_y), (width // 2 + rule_half, rule_y)],
        fill=ACCENT_GOLD, width=max(2, width // 620),
    )

    # Cihaz çerçevesi: kalan alana sığan en büyük ölçek. Yatay kare dar kalıyor,
    # onu biraz daha genişletip boşluğun ortasına oturtuyoruz.
    landscape = shot.width > shot.height
    top_limit = rule_y + round(height * 0.035)
    bottom_margin = round(height * 0.045)
    available = (
        round(width * (0.94 if landscape else 0.84)),
        height - top_limit - bottom_margin,
    )
    scale = min(available[0] / shot.width, available[1] / shot.height)
    inner = (round(shot.width * scale), round(shot.height * scale))
    bezel = max(6, round(width * 0.009))
    frame = (inner[0] + bezel * 2, inner[1] + bezel * 2)
    frame_x = (width - frame[0]) // 2
    # Yatayda ortalanan şey yalnız cihaz değil, altındaki alt metinle birlikte
    # oluşan blok; o yüzden merkez bir tık yukarı çekiliyor.
    frame_top = top_limit
    if landscape:
        frame_top += max((available[1] - frame[1]) // 2 - round(height * 0.075), 0)
    frame_radius = round(min(frame) * 0.075)

    shadow = Image.new("RGBA", canvas, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [frame_x, frame_top + round(height * 0.006),
         frame_x + frame[0], frame_top + frame[1] + round(height * 0.006)],
        frame_radius, fill=(0, 0, 0, 190),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(width * 0.02))
    image = Image.alpha_composite(image.convert("RGBA"), shadow).convert("RGB")
    draw = ImageDraw.Draw(image)

    draw.rounded_rectangle(
        [frame_x, frame_top, frame_x + frame[0], frame_top + frame[1]],
        frame_radius, fill=BG_FILM_BLACK, outline=ACCENT_GOLD, width=max(2, width // 500),
    )

    resized = shot.convert("RGB").resize(inner, Image.LANCZOS)
    image.paste(
        resized,
        (frame_x + bezel, frame_top + bezel),
        rounded_mask(inner, max(frame_radius - bezel, 2)),
    )

    # Çerçevenin alt kenarına oturan üç ampul: afişin marquee'sinden alıntı.
    bulb_y = frame_top + frame[1] + round(height * 0.018)
    bulb_r = max(3, round(width * 0.006))
    for offset in (-1, 0, 1):
        cx = width // 2 + offset * round(width * 0.06)
        draw.ellipse(
            [cx - bulb_r, bulb_y - bulb_r, cx + bulb_r, bulb_y + bulb_r], fill=ACCENT_AMBER
        )

    if subtitle:
        sub_size = round(width * 0.032)
        sub_font = body_font(sub_size, rtl)
        caption = shape(subtitle, rtl) if rtl else subtitle
        sub_y = bulb_y + round(height * 0.028)
        for line in wrap(draw, caption, sub_font, 0, width * 0.74):
            line_width = draw.textlength(line, font=sub_font)
            draw.text(((width - line_width) / 2, sub_y), line, font=sub_font, fill=TEXT_CREAM)
            sub_y += round(sub_size * 1.42)

    return image


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lang", default="en")
    parser.add_argument("--size", choices=sorted(SIZES), action="append")
    parser.add_argument("--scene", action="append")
    parser.add_argument("--compose-only", action="store_true")
    parser.add_argument("--app", default=str(APP))
    arguments = parser.parse_args()

    sizes = arguments.size or sorted(SIZES)
    scenes = [s for s in SCENES if not arguments.scene or s["id"] in arguments.scene]
    table = strings(arguments.lang)
    rtl = table.get("meta.locale") == "ar"

    app = pathlib.Path(arguments.app)
    if not arguments.compose_only and not app.exists():
        print(f"✗ uygulama yok: {app}\n  önce `xcodebuild … -derivedDataPath /tmp/charades_dd build`")
        return 1

    for key in sizes:
        size = SIZES[key]
        print(f"— {key}\" ({size['device']}, {size['canvas'][0]}×{size['canvas'][1]})")
        raw_directory = RAW / arguments.lang / key

        if not arguments.compose_only:
            udid = device_udid(size)
            boot(udid)
            # Temiz kurulum: önceki setin tohumladığı arşiv/sepet bir sonraki
            # setin ana ekran karesine rozet olarak sızıyor.
            run("xcrun", "simctl", "uninstall", udid, BUNDLE_ID, check=False)
            run("xcrun", "simctl", "install", udid, str(app))

        for index, scene in enumerate(scenes, start=1):
            raw = raw_directory / f"{scene['id']}.png"
            if not arguments.compose_only:
                capture(udid, scene, arguments.lang, raw)
            if not raw.exists():
                print(f"  ✗ {scene['id']}: ham kare yok ({raw})")
                return 1

            shot = Image.open(raw)
            if scene.get("rotate"):
                shot = shot.rotate(scene["rotate"], expand=True)
            subtitle = table.get(scene["sub"]) if scene.get("sub") else None
            image = compose(shot, headline(scene, table), size["canvas"], rtl, subtitle)
            target = OUT / arguments.lang / key / f"{index:02d}-{scene['id']}.png"
            target.parent.mkdir(parents=True, exist_ok=True)
            image.save(target)
            print(f"  ✓ {target.relative_to(ROOT)}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
