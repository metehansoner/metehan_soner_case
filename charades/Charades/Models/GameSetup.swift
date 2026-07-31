import Foundation
import Observation

/// §07 §3: kurulum akışının taşıdığı durum — seçili desteler, mod, süre, takımlar.
///
/// P3'te yalnızca deste seçimi var; mod (P6), süre (P6) ve takımlar (P8) aynı
/// nesneye ekleniyor. `RootView`'da `@State`, yani bir maçın kurulumu ekranlar
/// arasında taşınıyor ama uygulama ömrü boyunca yaşamıyor.
@MainActor
@Observable
final class GameSetup {

    /// Seçim sırası korunuyor: PlayBar özeti ve Mix önizlemesi kullanıcının
    /// seçtiği sırayı gösteriyor, alfabetik değil.
    private(set) var selectedDeckIDs: [String] = []

    var mode: GameMode = .classic {
        // Süre moda bağlı (§04 §1): Canlandır 90, Hız Turu 30. Mod değişince
        // önceki modun süresi taşınmamalı, kullanıcı yeni modun varsayılanından
        // başlamalı. Zorluk moddan bağımsız, o duruyor.
        didSet { if mode != oldValue { duration = nil } }
    }

    /// Tur Ön Ayar ekranındaki değerler — **yalnızca o tur için** (§09 §9).
    /// `nil` ise varsayılan geçerli: moda ait süre ya da ayarlardaki tercih.
    var duration: Int?
    var difficulty: CardDifficultyFilter?

    /// Takım Kurulumu (ekran 11). Yalnızca `teams` modunda kullanılıyor ama
    /// burada duruyor: maç sonundaki `TEKRAR OYNA` kurulum ekranına dönüyor
    /// (§02 §3) ve takımların o dönüşte hâlâ dolu olması gerekiyor.
    var teams: [Team] = Team.defaultRoster

    /// §09 §5: takım başına kaç tur — ayarın yeri Takım Kurulumu ekranı.
    var roundsPerTeam = Team.defaultRounds

    /// Maça girerken adlar bir kez çözülüyor; boş bırakılan takım numarasını,
    /// yarım kalan oyuncu alanı da hiçbir şeyi taşımıyor.
    func matchTeams(numbered: (Int) -> String) -> [Team] {
        teams.enumerated().map { $1.resolvingName(order: $0, numbered: numbered) }
    }

    /// Kurulum ekranından çıkarken yarım kalan oyuncu alanları düşüyor.
    /// Takım adı boş kalabilir — numarası maça girerken çözülüyor.
    func tidyTeams() {
        for index in teams.indices {
            teams[index].players = teams[index].namedPlayers
            teams[index].name = teams[index].name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func addTeam() {
        guard teams.count < Team.countRange.upperBound else { return }
        teams.append(Team())
    }

    func removeTeam(_ id: UUID) {
        guard teams.count > Team.countRange.lowerBound else { return }
        teams.removeAll { $0.id == id }
    }

    /// §04 §3: Hız Turu'nda süre sabit, tur ön ayarda kilitli.
    func effectiveDuration(userPreference: Int) -> Int {
        guard !mode.isDurationLocked else { return mode.defaultDuration }
        return duration ?? (mode.usesOwnDuration ? mode.defaultDuration : userPreference)
    }

    var hasSelection: Bool { !selectedDeckIDs.isEmpty }

    /// §09 §9: PlayBar'dan 2+ deste ile oynamak Mix demek ve Mix premium.
    var isMix: Bool { selectedDeckIDs.count >= 2 }

    var selectedDecks: [DeckDef] { selectedDeckIDs.compactMap(DeckCatalog.deck) }

    /// §01 §4: kart sayısı metadata'dan geliyor, kelime dosyası açılmıyor.
    /// İçeriği üretilmemiş deste toplamı büyütmüyor.
    var selectedCardCount: Int {
        selectedDeckIDs.reduce(0) { $0 + (DeckCardCounts.count(for: $1) ?? 0) }
    }

    func isSelected(_ deckID: String) -> Bool { selectedDeckIDs.contains(deckID) }

    func toggle(_ deckID: String) {
        if let index = selectedDeckIDs.firstIndex(of: deckID) {
            selectedDeckIDs.remove(at: index)
        } else {
            selectedDeckIDs.append(deckID)
        }
    }

    func select(only deckID: String) {
        selectedDeckIDs = [deckID]
    }

    func clearSelection() {
        selectedDeckIDs.removeAll()
    }
}
