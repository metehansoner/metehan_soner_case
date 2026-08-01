import Observation
import SwiftUI

/// Film Arşivi'nin durumu — §04 §4.3.
///
/// Kayıtlar SwiftData'da değil dosya sisteminde yaşıyor (§ `07` §3: video
/// metadata'sı için ayrı bir veritabanı ikinci bir doğruluk kaynağı olurdu),
/// bu yüzden liste `@Query` ile değil elle yükleniyor.
@MainActor
@Observable
final class ArchiveModel {

    /// Bir maç = bir film. Tek turluk modlarda film tek sahnelik oluyor ama
    /// gruplama kuralı değişmiyor.
    struct Film: Identifiable {
        let id: String
        let title: String
        let date: Date
        var scenes: [ReplayReel]
    }

    private(set) var films: [Film] = []
    private(set) var totalBytes: Int64 = 0
    private(set) var reelCount = 0

    /// `DÜZENLE` ile açılan çoklu seçim; kapalıyken dokunuş oynatıcıyı açıyor.
    var isSelecting = false {
        didSet { if !isSelecting { selection.removeAll() } }
    }
    var selection: Set<String> = []

    func load(l10n: LocalizationManager) {
        let reels = ReplayStore.allReels()
        reelCount = reels.count
        totalBytes = reels.reduce(0) { $0 + ReplayStore.bytes(of: $1) }

        var order: [String] = []
        var grouped: [String: [ReplayReel]] = [:]
        for reel in reels {
            if grouped[reel.matchID] == nil { order.append(reel.matchID) }
            grouped[reel.matchID, default: []].append(reel)
        }

        films = order.compactMap { matchID in
            guard let scenes = grouped[matchID], let newest = scenes.first else { return nil }
            return Film(
                id: matchID,
                title: Self.title(for: newest, l10n: l10n),
                date: newest.createdAt,
                scenes: scenes.sorted { $0.sceneIndex < $1.sceneIndex }
            )
        }

        // Silinen kayıt seçili kalmasın.
        let ids = Set(reels.map(\.id))
        selection.formIntersection(ids)
    }

    /// Başlık kayıt anında değil **okuma anında** çözülüyor: kayıt Türkçe alınıp
    /// arşive İngilizce bakılabiliyor (§06 §2).
    private static func title(for reel: ReplayReel, l10n: LocalizationManager) -> String {
        if reel.deckIDs.count == 1, let deck = DeckCatalog.deck(reel.deckIDs[0]) {
            return l10n.t(deck.titleKey)
        }
        if reel.deckIDs.count > 1 { return l10n.t("mode.mix.title") }
        return l10n.t("mode.\(reel.modeID).title")
    }

    // MARK: Eylemler

    func toggleSelection(_ id: String) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }

    func deleteSelected(l10n: LocalizationManager) {
        for id in selection {
            Analytics.replayDelete()
            ReplayStore.delete(id: id)
        }
        isSelecting = false
        load(l10n: l10n)
    }

    func delete(id: String, l10n: LocalizationManager) {
        Analytics.replayDelete()
        ReplayStore.delete(id: id)
        load(l10n: l10n)
    }

    /// §04 §4.2: sabitlenen kayıt FIFO'dan ve otomatik silmeden muaf.
    func togglePin(id: String, l10n: LocalizationManager) {
        guard var reel = ReplayStore.reel(id: id) else { return }
        reel.isPinned.toggle()
        if reel.isPinned { Analytics.replayPin() }
        ReplayStore.save(reel)
        load(l10n: l10n)
    }

    func clearAll(l10n: LocalizationManager) {
        // Toplu temizlik kullanıcının kararı ama tek tek silmekle aynı sinyal
        // değil; her kayıt için event basmak "silme" oranını şişiriyor.
        Analytics.replayDelete()
        ReplayStore.deleteAll()
        isSelecting = false
        load(l10n: l10n)
    }

    func selectedReels() -> [ReplayReel] {
        films.flatMap(\.scenes).filter { selection.contains($0.id) }
    }

    // MARK: Biçimlendirme

    static func sizeText(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = bytes < 1_000_000 ? [.useKB] : [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    static func dateText(_ date: Date, localeCode: String) -> String {
        date.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: localeCode)))
    }

    static func durationText(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
