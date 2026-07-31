// Bu dosya üretiliyor — elle düzenlemeyin.
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
        "cities": 64,
        "movieClassics": 63,
        "party": 65,
    ]
}
