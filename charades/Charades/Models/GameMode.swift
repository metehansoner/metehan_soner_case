import Foundation

/// 6 mod — 04-oyun-modlari.md §1.
///
/// Yeni mod eklemek = bir `case` + aşağıdaki matriste bir satır. Ekran kodu
/// değişmiyor, lokalizasyon anahtarları `id`den türüyor.
///
/// > §1'in sonundaki açık soru — `mix` ve `ownWords` aslında kural modu değil
/// > **kaynak modu**, temiz model `GameMode` × `WordSource` ayrımı olurdu —
/// > burada **çözülmedi**. Doküman kararı v1'i 6 modla çıkarmak; ayrıştırma
/// > 25 dildeki mod adı tablolarına, `mode_locked_tap` analytics'ine ve
/// > `howToSeen` mantığına dokunuyor.
enum GameMode: String, CaseIterable, Identifiable, Sendable {
    case classic
    case teams
    case actOut
    case rapid
    case mix
    case ownWords

    var id: String { rawValue }

    // §1: `id` asla değişmez, lokalizasyon yalnızca görünen metinde.
    var titleKey: String { "mode.\(rawValue).title" }
    var subtitleKey: String { "mode.\(rawValue).subtitle" }

    /// Mod Seçimi kartındaki amblem (§02 ekran 10). Kapaklardan farklı olarak
    /// üretilmiş görsel değil SF Symbol: altı ikon 25 dilde de aynı kalıyor ve
    /// Dynamic Type ile birlikte ölçekleniyor.
    var systemImage: String {
        switch self {
        case .classic: "movieclapper"
        case .teams: "chart.bar.fill"
        case .actOut: "figure.arms.open"
        case .rapid: "bolt.fill"
        case .mix: "shuffle"
        case .ownWords: "text.bubble.fill"
        }
    }

    /// §1: ücretsiz kullanıcının gördüğü tek mod Klasik.
    var isFree: Bool { self == .classic }

    /// §09 §9: Mix, Klasik'in `howToSeen` değerini paylaşıyor — oynanışı birebir
    /// aynı (§04 §1), aynı dört sayfayı ikinci kez göstermek gereksiz.
    var howToSeenKey: String { self == .mix ? GameMode.classic.rawValue : rawValue }

    // MARK: Özellik matrisi — §1

    var usesTilt: Bool { true }

    var usesTeams: Bool { self == .teams }

    /// Hız Turu'nda kelime başına 5 saniye; dolarsa otomatik PAS.
    var perWordLimit: TimeInterval? { self == .rapid ? 5 : nil }

    /// `actOut`ta ekranı **canlandıran** tutuyor, tahmin edenler görmemeli.
    var screenVisibleToGuesser: Bool { self != .actOut }

    var scoreMultiplier: Int { self == .rapid ? 2 : 1 }

    /// §1: `ownWords` tek modda kelime kaynağı katalog değil kullanıcı.
    var needsDeckSelection: Bool { self != .ownWords }

    // MARK: Süre — §3

    var defaultDuration: Int {
        switch self {
        case .actOut: 90
        case .rapid: 30
        default: 60
        }
    }

    /// §3: Hız Turu'nda süre sabit, tur ön ayarda kilitli.
    var isDurationLocked: Bool { self == .rapid }

    /// Canlandır 90 sn, Hız Turu 30 sn — bu iki modun süresi kendi tanımından
    /// geliyor. Diğerlerinde başlangıç değeri ayarlardaki kullanıcı tercihi
    /// (§09 §9: ayar **varsayılan**, tur ön ayar **o tur için**).
    var usesOwnDuration: Bool { self == .actOut || self == .rapid }

    /// §3: 30–180 sn, 15 sn adımlarla.
    static let durationRange = 30...180
    static let durationStep = 15
}

/// §04 §2 + §09 §1: cevap nasıl veriliyor.
///
/// `tilt` varsayılan; `touch` hem erişilebilirlik yolu (§01 §7) hem motion
/// sensörü sorunlu cihazların yedeği hem de ayarlardan kalıcı seçilebilen bir
/// tercih. Portrait oynanan tur her zaman `touch`, çünkü telefon alna konmuyor.
enum AnswerInput: String, Sendable {
    case tilt
    case touch
}
