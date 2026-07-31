#!/usr/bin/env python3
"""
`Charades/Models/DeckCardCounts.swift` dosyasını üretir.

Neden üretilen bir tablo: §01 §4 deste kartının sağ alt köşesinde `130 KART`
yazmasını istiyor, ama §05 §5 ana ekranda hiçbir kelime dosyasının
okunmamasını şart koşuyor (`CardBank` lazy). İkisi ancak sayı metadata'ya
taşınırsa uyuşuyor. Sayıyı elle yazmak 92 satırı içerik üretimiyle senkron
tutmak demek; bu yüzden JSON'lardan türetiliyor.

İçerik dosyası olmayan destede kayıt yok — kart sayı rozetini hiç çizmiyor.

Kullanım:
  python3 Scripts/generate_card_counts.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DECKS = ROOT / "Charades" / "Resources" / "Decks"
OUTPUT = ROOT / "Charades" / "Models" / "DeckCardCounts.swift"

HEADER = """// Bu dosya üretiliyor — elle düzenlemeyin.
// Kaynak: Charades/Resources/Decks/*.json
// Yeniden üretmek için: python3 Scripts/generate_card_counts.py

import Foundation

/// Deste başına kart sayısı, içerik dosyalarından türetilmiş.
///
/// §01 §4 ızgaradaki kartın sağ alt köşesinde kart sayısını istiyor, §05 §5 ise
/// ana ekranda kelime dosyası okunmamasını. Sayı bu yüzden derleme zamanında
/// gömülüyor. Tabloda olmayan deste = içeriği henüz üretilmemiş deste.
enum DeckCardCounts {
    static func count(for deckID: String) -> Int? { table[deckID] }

    static let table: [String: Int] = [
"""

FOOTER = """    ]
}
"""


def main() -> int:
    if not DECKS.exists():
        print(f"HATA: {DECKS} yok", file=sys.stderr)
        return 2

    counts: dict[str, int] = {}
    for path in sorted(DECKS.glob("*.json")):
        data = json.loads(path.read_text())
        deck_id = data.get("id", path.stem)
        if deck_id != path.stem:
            print(f"HATA: {path.name} içindeki id = {deck_id}", file=sys.stderr)
            return 1
        counts[deck_id] = len(data.get("cards", []))

    lines = [f'        "{deck_id}": {count},' for deck_id, count in sorted(counts.items())]
    OUTPUT.write_text(HEADER + "\n".join(lines) + "\n" + FOOTER)
    print(f"{len(counts)} deste → {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
