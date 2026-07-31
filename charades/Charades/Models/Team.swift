import Foundation

/// Takım Savaşı'nın tek takımı — 04-oyun-modlari.md §1, 09-kesinti-ve-sinir-durumlari.md §5.
///
/// Ad ve oyuncular **opsiyonel**: kurulum ekranından tek dokunuşla geçilebilsin
/// diye ikisi de boş bırakılabiliyor. Ad boşsa numarayla anılıyor
/// (`teams.defaultName`), oyuncu yoksa perde arası ve jenerik takım adıyla
/// yetiniyor (§ `09` §5).
struct Team: Identifiable, Hashable, Sendable {

    /// § `04` §1: 2–4 takım, takım başına 1–8 kişi.
    static let countRange = 2...4
    static let playerLimit = 8

    /// § `09` §5: takım başına 1–5 tur, varsayılan 3.
    static let roundsRange = 1...5
    static let defaultRounds = 3

    let id: UUID
    var name: String
    var players: [String]

    init(id: UUID = UUID(), name: String = "", players: [String] = []) {
        self.id = id
        self.name = name
        self.players = players
    }

    /// Kurulum ekranında yarım kalmış (boş) alanlar kayda geçmiyor.
    var namedPlayers: [String] {
        players
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Telefonu kimin alacağı: takım kendi içinde sırayla dönüyor.
    /// Ad girilmemişse `nil` — çağıran taraf takım adına düşüyor.
    func player(forTurn turn: Int) -> String? {
        let named = namedPlayers
        guard !named.isEmpty else { return nil }
        return named[turn % named.count]
    }

    /// Maç başlarken adlar bir kez çözülüyor; `TeamMatch` ve jenerik boş ad
    /// görmüyor. `numbered` lokalizasyondan geliyor, model dile bağlanmıyor.
    func resolvingName(order: Int, numbered: (Int) -> String) -> Team {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var copy = self
        copy.name = trimmed.isEmpty ? numbered(order + 1) : trimmed
        copy.players = namedPlayers
        return copy
    }

    static var defaultRoster: [Team] {
        (0..<countRange.lowerBound).map { _ in Team() }
    }
}
