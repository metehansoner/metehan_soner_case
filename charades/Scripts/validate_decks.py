#!/usr/bin/env python3
"""
Charades — deste kataloğu CI doğrulaması
Kaynak: 05-desteler-ve-kategoriler.md §5 (9 kontrol)

Kullanım:
  python3 Scripts/validate_decks.py
  python3 Scripts/validate_decks.py --strict-content   # v1'in tüm JSON'larını zorunlu kıl

İçerik üretimi ayrı bir yol (§10 §4). Varsayılan modda yalnızca
`DeckCatalog.contentReadyIDs` (şu an 3 örnek) JSON zorunluluğuna tabi;
diğer v1 desteleri için eksik dosya uyarıdır, hata değil. Yapısal
kontroller (katalog boyutu, bölüm↔chip, anahtar uzunluğu) her zaman katı.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHARADES = ROOT / "Charades"
DECKS_DIR = CHARADES / "Resources" / "Decks"
LOCS_DIR = CHARADES / "Resources" / "Localization"
CATALOG_SWIFT = CHARADES / "Models" / "DeckCatalog.swift"
SECTION_SWIFT = CHARADES / "Models" / "DeckSection.swift"
ASSETS = CHARADES / "Assets.xcassets"

LOCALES_25 = [
    "en", "tr", "de", "ar", "be", "ca", "cs", "da", "el", "es",
    "fi", "fil", "fr", "hr", "id", "it", "ms", "nb", "nl", "pl",
    "pt", "ro", "ru", "sv", "uk",
]
PRIORITY_ADAPT = ["en", "tr", "de", "es", "ru", "fr"]
CONTENT_READY = {"party", "movieClassics", "cities"}
EXPECTED_V1 = 92
EXPECTED_TOTAL = 124
MIN_CARDS = 60
MAX_DECK_TITLE = 22
MAX_MODE_TITLE = 18
ADAPT_RATIO = 0.60


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def err(self, msg: str) -> None:
        self.errors.append(msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)

    @property
    def ok(self) -> bool:
        return not self.errors


def parse_seed_ids(swift: str) -> list[dict]:
    """DeckCatalog.swift içindeki Seed(...) satırlarını okur."""
    # Seed("id", .section, .playability, .localization, .difficulty, v1: true/false, ...)
    pattern = re.compile(
        r'Seed\(\s*"([^"]+)"\s*,\s*\.(\w+)\s*,\s*\.(\w+)\s*,\s*\.(\w+)\s*,\s*\.(\w+)\s*,'
        r'\s*v1:\s*(true|false)'
        r'(?P<rest>[^)]*)\)',
        re.MULTILINE,
    )
    free_re = re.compile(r"free:\s*true")
    seeds = []
    for m in pattern.finditer(swift):
        seeds.append(
            {
                "id": m.group(1),
                "section": m.group(2),
                "playability": m.group(3),
                "localization": m.group(4),
                "difficulty": m.group(5),
                "v1": m.group(6) == "true",
                "free": bool(free_re.search(m.group("rest"))),
            }
        )
    return seeds


def parse_sections(swift: str) -> list[str]:
    # enum DeckSection cases before other members
    body = re.search(r"enum DeckSection[^{]*\{([^}]+)\}", swift, re.DOTALL)
    if not body:
        return []
    return re.findall(r"case\s+(\w+)", body.group(1))


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def check_catalog_shape(seeds: list[dict], sections: list[str], r: Report) -> None:
    if len(seeds) != EXPECTED_TOTAL:
        r.err(f"#katalog: {EXPECTED_TOTAL} deste bekleniyor, {len(seeds)} bulundu")
    v1 = [s for s in seeds if s["v1"]]
    if len(v1) != EXPECTED_V1:
        r.err(f"#katalog: {EXPECTED_V1} v1 deste bekleniyor, {len(v1)} bulundu")

    ids = [s["id"] for s in seeds]
    dupes = [i for i, c in Counter(ids).items() if c > 1]
    if dupes:
        r.err(f"#katalog: tekrarlayan id: {dupes}")

    free = [s for s in seeds if s["free"]]
    if len(free) != 1 or free[0]["id"] != "party":
        r.err(f"#katalog: kalıcı ücretsiz deste yalnızca 'party' olmalı, bulundu: {[s['id'] for s in free]}")

    # #8 — her bölümün bir chip'i var (DeckFilter.standardOrder yapısal)
    section_swift = SECTION_SWIFT.read_text(encoding="utf-8")
    if "DeckSection.allCases.map(DeckFilter.section)" not in section_swift:
        r.err("#8: DeckFilter.standardOrder bölümleri otomatik üretmiyor")
    if len(sections) != 13:
        r.err(f"#8: 13 bölüm bekleniyor, {len(sections)} bulundu")

    by_section = Counter(s["section"] for s in seeds)
    for sec in sections:
        if by_section[sec] == 0:
            r.err(f"#8: bölüm '{sec}' boş — chip'i olan ama destesi olmayan bölüm")


def check_json_files(seeds: list[dict], strict: bool, r: Report) -> None:
    v1_ids = {s["id"] for s in seeds if s["v1"]}
    seed_by_id = {s["id"]: s for s in seeds}
    existing = {p.stem: p for p in DECKS_DIR.glob("*.json")} if DECKS_DIR.exists() else {}

    for deck_id in sorted(v1_ids):
        path = existing.get(deck_id)
        required = strict or deck_id in CONTENT_READY
        if path is None:
            msg = f"#1: Resources/Decks/{deck_id}.json yok"
            (r.err if required else r.warn)(msg)
            continue

        try:
            data = load_json(path)
        except Exception as e:
            r.err(f"#1: {deck_id}.json okunamadı: {e}")
            continue

        if data.get("id") != deck_id:
            r.err(f"#1: {deck_id}.json içindeki id = {data.get('id')!r}")

        cards = data.get("cards") or []
        if len(cards) < MIN_CARDS:
            r.err(f"#2: {deck_id}: {len(cards)} kart (< {MIN_CARDS})")

        localize = data.get("localize")
        expected_loc = seed_by_id[deck_id]["localization"]
        if localize != expected_loc:
            r.err(f"#1: {deck_id}: JSON localize={localize!r}, katalog={expected_loc!r}")

        missing_locale_cards = 0
        for card in cards:
            t = card.get("t") or {}
            missing = [loc for loc in LOCALES_25 if loc not in t or not str(t[loc]).strip()]
            if missing:
                missing_locale_cards += 1
                if missing_locale_cards <= 3:
                    r.err(f"#3: {deck_id}/{card.get('k')}: eksik dil {missing}")
        if missing_locale_cards > 3:
            r.err(f"#3: {deck_id}: toplam {missing_locale_cards} kartta dil eksiği")

        # #7 — adapt: öncelikli 6 dilde yerel oran
        if localize == "adapt":
            for loc in PRIORITY_ADAPT:
                if loc == "en":
                    continue
                if not cards:
                    continue
                adapted = sum(1 for c in cards if (c.get("t") or {}).get(loc) != (c.get("t") or {}).get("en"))
                ratio = adapted / len(cards)
                if ratio < ADAPT_RATIO:
                    r.err(
                        f"#7: {deck_id}/{loc}: yerel içerik %{ratio*100:.0f} "
                        f"(eşik %{ADAPT_RATIO*100:.0f})"
                    )

    orphans = sorted(set(existing) - v1_ids - {s["id"] for s in seeds})
    for orphan in orphans:
        r.warn(f"#1: katalogda olmayan JSON: {orphan}.json")


def check_assets(seeds: list[dict], r: Report) -> None:
    """#4 — deck_{id} imageset. Kapaklar `DeckCovers/` altında (P3)."""
    covers_dir = ASSETS / "DeckCovers"
    teslim = ROOT.parent / "Charedes_document" / "teslim" / "deste-kapaklari"
    covers = {p.stem for p in teslim.glob("deck_*.png")} if teslim.exists() else set()
    for s in seeds:
        if not s["v1"]:
            continue
        name = f"deck_{s['id']}"
        imageset = covers_dir / f"{name}.imageset"
        if not imageset.exists():
            imageset = ASSETS / f"{name}.imageset"
        if imageset.exists():
            continue
        if name in covers:
            r.warn(f"#4: {name} teslimde var, asset catalog'da yok")
        else:
            r.err(f"#4: {name} ne asset catalog'da ne teslimde")


def check_localization_keys(seeds: list[dict], r: Report) -> None:
    en_path = LOCS_DIR / "en.json"
    if not en_path.exists():
        r.err("#5: en.json yok")
        return
    en = load_json(en_path)

    for s in seeds:
        for suffix in ("title", "desc"):
            key = f"deck.{s['id']}.{suffix}"
            if key not in en or not str(en[key]).strip():
                r.err(f"#5: en.json'da {key} yok")

    # #6 — taşma
    for key, value in en.items():
        if key.startswith("deck.") and key.endswith(".title") and len(value) > MAX_DECK_TITLE:
            r.err(f"#6: {key} = {value!r} ({len(value)} > {MAX_DECK_TITLE})")
        if key.startswith("mode.") and key.endswith(".title") and len(value) > MAX_MODE_TITLE:
            r.err(f"#6: {key} = {value!r} ({len(value)} > {MAX_MODE_TITLE})")

    # Diğer mevcut dil dosyaları için de taşma
    for path in LOCS_DIR.glob("*.json"):
        if path.name == "en.json":
            continue
        data = load_json(path)
        for key, value in data.items():
            if key.startswith("deck.") and key.endswith(".title") and len(value) > MAX_DECK_TITLE:
                r.err(f"#6: {path.name} {key} = {value!r} ({len(value)} > {MAX_DECK_TITLE})")


def check_font_glyphs(r: Report) -> None:
    """#9 — örnek dize glif taraması. fontTools yoksa atlanır."""
    try:
        from fontTools.ttLib import TTFont  # type: ignore
    except ImportError:
        r.warn("#9: fontTools yok — glif taraması atlandı (pip install fonttools)")
        return

    fonts_dir = CHARADES / "Resources" / "Fonts"
    samples = {
        "en": "CHARADES",
        "tr": "SESSİZ SİNEMA",
        "de": "STILLE POST",
        "el": "ΧΑΡΑΔΕΣ",
        "ar": "تمثيلية",
        "ru": "ШАРАДЫ",
        "uk": "ШАРАДИ",
    }
    # Display font: Oswald; Arapça/Yunanca için Rubik (§01 §2)
    oswald = fonts_dir / "Oswald-Bold.ttf"
    rubik = fonts_dir / "Rubik-Bold.ttf"
    if not oswald.exists() or not rubik.exists():
        r.warn("#9: font dosyaları eksik")
        return

    def cmap(path: Path) -> set[str]:
        font = TTFont(path)
        chars: set[str] = set()
        for table in font["cmap"].tables:
            chars.update(chr(c) for c in table.cmap)
        return chars

    oswald_chars = cmap(oswald)
    rubik_chars = cmap(rubik)

    for loc, sample in samples.items():
        use_rubik = loc in {"ar", "el"}
        chars = rubik_chars if use_rubik else oswald_chars
        font_name = "Rubik" if use_rubik else "Oswald"
        missing = sorted({ch for ch in sample if not ch.isspace() and ch not in chars})
        if missing:
            r.err(f"#9: {loc} örneği {font_name}'da eksik glif: {missing} ({sample!r})")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--strict-content",
        action="store_true",
        help="v1'in 92 destesinin tamamında JSON zorunlu (içerik pipeline'ı bitince)",
    )
    args = parser.parse_args()

    r = Report()
    if not CATALOG_SWIFT.exists():
        print(f"HATA: {CATALOG_SWIFT} yok", file=sys.stderr)
        return 2

    catalog_src = CATALOG_SWIFT.read_text(encoding="utf-8")
    section_src = SECTION_SWIFT.read_text(encoding="utf-8")
    seeds = parse_seed_ids(catalog_src)
    sections = parse_sections(section_src)

    if not seeds:
        r.err("DeckCatalog.swift'ten hiç Seed okunamadı — parser kırılmış olabilir")
    else:
        check_catalog_shape(seeds, sections, r)
        check_json_files(seeds, strict=args.strict_content, r=r)
        check_assets(seeds, r)
        check_localization_keys(seeds, r)

    check_font_glyphs(r)

    print(f"Katalog: {len(seeds)} deste ({sum(1 for s in seeds if s['v1'])} v1)")
    print(f"JSON: {len(list(DECKS_DIR.glob('*.json'))) if DECKS_DIR.exists() else 0} dosya")
    for w in r.warnings:
        print(f"  UYARI  {w}")
    for e in r.errors:
        print(f"  HATA   {e}")

    if r.ok:
        print("OK — tüm zorunlu kontroller geçti")
        return 0
    print(f"FAIL — {len(r.errors)} hata")
    return 1


if __name__ == "__main__":
    sys.exit(main())
