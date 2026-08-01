import Observation

/// İstem sırası — 09-kesinti-ve-sinir-durumlari.md §9.
///
/// Kural tek cümle: **aynı oturumda en fazla bir istem.** Üç aday var ve üçü de
/// aynı akşamın ilk yarım saatinde tetiklenebiliyor — tur sonu soft paywall'ı,
/// bildirim izni ve puanla bizi. Üçü peş peşe çıkarsa kullanıcı uygulamayı
/// kapatıyor; bu sınıf onları tek bir kotaya bağlıyor.
///
/// Öncelik sırası `Prompt`'un tanım sırası: soft paywall > bildirim izni >
/// puanla bizi. Sıra zamanla da uyumlu olduğu için karar noktalarında ayrıca
/// arbitraj gerekmiyor — soft paywall tur sonunda, diğer ikisi ana ekranda ve
/// orada öncelik sırasıyla değerlendiriliyor (§ `03` §1 8 saniyelik gecikme).
@MainActor
@Observable
final class PromptCoordinator {
    static let shared = PromptCoordinator()

    enum Prompt {
        case softPaywall
        case notifications
        case rateUs
    }

    /// Bu oturumda gösterilen istem; `nil` ise kota boş.
    private(set) var shown: Prompt?

    private init() {}

    /// Kotayı tüketmeyi dener. `false` dönerse çağıran hiçbir şey göstermemeli.
    func claim(_ prompt: Prompt) -> Bool {
        guard shown == nil else { return false }
        shown = prompt
        return true
    }

    #if DEBUG
    func debugReset() { shown = nil }
    #endif
}
