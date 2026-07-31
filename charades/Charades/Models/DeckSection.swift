import SwiftUI

/// 13 katalog bölümü — 05-desteler-ve-kategoriler.md §2.
/// Sıra ızgaradaki bölüm sırası ve reel numaralarının sırası (§2 tablo düzeni).
enum DeckSection: String, CaseIterable, Identifiable, Sendable {
    case party
    case actOut
    case movieTV
    case music
    case kids
    case sports
    case knowledge
    case brands
    case nostalgia
    case world
    case animals
    case home
    case seasonal

    var id: String { rawValue }

    var titleKey: String { "section.\(rawValue).title" }

    /// §8: her bölüme paletin içinden baskın bir ton atanıyor — ızgarada göz
    /// bölümleri ayırt ediyor ama palet dışına çıkılmıyor.
    var dominantHex: UInt32 {
        switch self {
        case .party: 0xF0A93B      // accentAmber
        case .actOut: 0x2F7F7C     // accentTeal
        case .movieTV: 0x2B0E15    // bgVelvetDeep
        case .music: 0xA8791F      // accentBrass
        case .kids: 0xF4E7CE       // surfacePoster
        case .sports: 0x4F8F5B     // stateCorrect
        case .knowledge: 0x2F7F7C  // accentTeal
        case .brands: 0xE3C36A     // accentGold
        case .nostalgia: 0xD2861F  // accentAmberDeep
        case .world: 0x2F7F7C      // accentTeal
        case .animals: 0x4F8F5B    // stateCorrect
        case .home: 0xE8D3A9       // surfaceTicket
        case .seasonal: 0xC0392B   // stateSkip
        }
    }

    var dominantTone: Color { Color(hex: dominantHex) }

    /// Koyu zeminde tek başına duran ince öğeler için (Mix karışım göstergesi).
    /// `movieTV` gibi neredeyse siyah tonlar 5px'lik bir çubukta kaybolduğu için
    /// afiş gradient'iyle aynı açma uygulanıyor.
    var meterTone: Color { Color.scaling(hex: dominantHex, minimumChannel: 0.62).color }

    /// Deste kartının afiş zemini — `ornek-ekranlar.html` `.art.*` kuralları.
    ///
    /// Mockup dört bölüm için elle yazılmış gradient veriyor; kalan dokuzu
    /// elle uydurmak yerine hepsi baskın tondan türetiliyor. Ton önce en
    /// parlak kanalı 0.45'e çıkacak kadar açılıyor (koyu bordo bu yüzden
    /// mockup'taki `#6d2530`e denk düşüyor), sonra %62 ve dış halka onun
    /// karartılmış hâli oluyor.
    var artGradient: EllipticalGradient {
        let inner = Color.scaling(hex: dominantHex, minimumChannel: 0.45)
        return EllipticalGradient(
            gradient: Gradient(stops: [
                .init(color: inner.color, location: 0),
                .init(color: inner.scaled(by: 0.42), location: 0.62),
                .init(color: inner.scaled(by: 0.16), location: 1),
            ]),
            center: UnitPoint(x: 0.5, y: 0.34),
            startRadiusFraction: 0,
            endRadiusFraction: 0.78
        )
    }

    /// §2: sezon bölümü yalnızca bir destesinin penceresi açıkken görünür.
    var isDateGated: Bool { self == .seasonal }
}

/// Filtre chip'leri — §2: 3 dinamik/genel + 13 bölüm = 16, artı §09 §9'daki
/// koşullu `FAVORİLER`.
///
/// Bölüm chip'i `case section(DeckSection)` olarak modellendiği için
/// "her bölümün bir chip'i var mı" (CI #8) derleme zamanında garanti — o hata
/// bir kez `MARKA & TEKNOLOJİ` bölümünde olmuş ve 8 desteyi filtre dışında
/// bırakmıştı. Script yine kontrol ediyor ama artık ikinci savunma hattı.
enum DeckFilter: Hashable, Identifiable, Sendable {
    case all
    case popular
    case new
    case favorites
    case section(DeckSection)

    var id: String {
        switch self {
        case .all: "all"
        case .popular: "popular"
        case .new: "new"
        case .favorites: "favorites"
        case .section(let s): "section.\(s.rawValue)"
        }
    }

    var titleKey: String {
        switch self {
        case .all: "filter.all"
        case .popular: "filter.popular"
        case .new: "filter.new"
        case .favorites: "filter.favorites"
        case .section(let s): "filter.section.\(s.rawValue)"
        }
    }

    /// §2'deki 16 chip'lik sabit sıra. `FAVORİLER` burada yok; koşullu olduğu
    /// için ızgara ekranı (P3) onu başa ekliyor.
    static let standardOrder: [DeckFilter] =
        [.all, .popular, .new] + DeckSection.allCases.map(DeckFilter.section)
}
