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
    var dominantTone: Color {
        switch self {
        case .party: AppColors.accentAmber
        case .actOut: AppColors.accentTeal
        case .movieTV: AppColors.bgVelvetDeep
        case .music: AppColors.accentBrass
        case .kids: AppColors.surfacePoster
        case .sports: AppColors.stateCorrect
        case .knowledge: AppColors.accentTeal
        case .brands: AppColors.accentGold
        case .nostalgia: AppColors.accentAmberDeep
        case .world: AppColors.accentTeal
        case .animals: AppColors.stateCorrect
        case .home: AppColors.surfaceTicket
        case .seasonal: AppColors.stateSkip
        }
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
