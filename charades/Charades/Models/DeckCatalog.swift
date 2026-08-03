import Foundation

// MARK: - Alanlar

/// §05 §1: destenin vücut diliyle oynanıp oynanamayacağı. Bu tek alan "kötü tur"
/// şikâyetlerinin büyük kısmını engelliyor — `Canlandır` modunda `describe`
/// desteler soluklaşıp `ANLATMA DESTESİ` etiketi alıyor, ama seçilebilir kalıyor.
enum Playability: String, Codable, Sendable {
    case mime
    case describe
    case both

    /// Canlandırma zorunlu olan modlarda önerilir mi.
    var supportsActOut: Bool { self != .describe }
}

/// §05 §5 / §06 §3.2: kartlar birebir mi çevrilir, kültüre göre mi uyarlanır.
enum LocalizationStyle: String, Codable, Sendable {
    case literal
    case adapt
}

/// Deste seviyesinde ortalama tahmin güçlüğü. Tur içi zorluk filtresi kartın
/// `d` alanına göre çalışıyor (§06 §4); bu alan ızgarada ve deste detayında
/// beklenti kurmak için.
enum Difficulty: String, Codable, Sendable, CaseIterable {
    case easy
    case medium
    case hard

    var titleKey: String { "difficulty.\(rawValue)" }
}

/// Gregoryen ya da hicri ay/gün.
struct MonthDay: Hashable, Sendable {
    let month: Int
    let day: Int

    init(_ month: Int, _ day: Int) {
        self.month = month
        self.day = day
    }
}

/// §05 §4: sezon destelerinin görünürlük penceresi. Tarih aralıkları koda
/// gömülmüyor sayılır — burada duran değer **varsayılan**, Remote Config
/// `DeckCatalog.seasonWindowOverrides` üzerinden üzerine yazıyor (§09 §8).
enum DateWindow: Hashable, Sendable {
    /// Yıl atlayan aralıklar destekli: 15 Aralık – 5 Ocak.
    case gregorian(MonthDay, MonthDay)
    /// Hicri takvim (Umm al-Qura) — `ramadan`, `eid`.
    case hijri(MonthDay, MonthDay)
    /// Paskalya gibi hesaplanan bayramlar: Paskalya gününe göre pencere.
    case easter(daysBefore: Int, daysAfter: Int)
    /// Birden fazla pencere — `eid` hem Ramazan hem Kurban bayramını kapsıyor.
    case any([DateWindow])

    func contains(_ date: Date) -> Bool {
        switch self {
        case .gregorian(let from, let to):
            Self.isInRange(date, from: from, to: to, calendar: Calendar(identifier: .gregorian))
        case .hijri(let from, let to):
            Self.isInRange(date, from: from, to: to, calendar: Calendar(identifier: .islamicUmmAlQura))
        case .easter(let before, let after):
            Self.isNearEaster(date, daysBefore: before, daysAfter: after)
        case .any(let windows):
            windows.contains { $0.contains(date) }
        }
    }

    private static func isInRange(_ date: Date, from: MonthDay, to: MonthDay, calendar: Calendar) -> Bool {
        let parts = calendar.dateComponents([.month, .day], from: date)
        guard let month = parts.month, let day = parts.day else { return false }
        let now = month * 100 + day
        let start = from.month * 100 + from.day
        let end = to.month * 100 + to.day
        // Yıl atlayan pencere (15 Ara – 5 Oca) için aralık ikiye ayrılıyor.
        return start <= end ? (now >= start && now <= end) : (now >= start || now <= end)
    }

    private static func isNearEaster(_ date: Date, daysBefore: Int, daysAfter: Int) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let year = calendar.component(.year, from: date)
        guard let easter = easterSunday(year: year, calendar: calendar),
              let start = calendar.date(byAdding: .day, value: -daysBefore, to: easter),
              let end = calendar.date(byAdding: .day, value: daysAfter, to: easter)
        else { return false }
        let today = calendar.startOfDay(for: date)
        return today >= calendar.startOfDay(for: start) && today <= calendar.startOfDay(for: end)
    }

    /// Anonim Gregoryen algoritması.
    private static func easterSunday(year: Int, calendar: Calendar) -> Date? {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = (h + l - 7 * m + 114) % 31 + 1
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}

// MARK: - DeckDef

/// §05 §5: deste metadata'sının tek kaynağı. Çeviri anahtarları ve asset adı
/// id'den türetiliyor — 124 deste × 3 anahtar = 372 string'i elle yazmak yerine.
struct DeckDef: Identifiable, Hashable, Sendable {
    let id: String
    let section: DeckSection
    /// Kartta gösterilen `REEL No. 07` (§01 §5.1). v1 desteleri 1–92, yol
    /// haritasındaki desteler 93–124; üretilmiş kapak dosyalarının sırasıyla
    /// birebir aynı.
    let reelNumber: Int
    let playability: Playability
    let localization: LocalizationStyle
    let difficulty: Difficulty
    let minPlayers: Int
    let isFree: Bool
    let seasonWindow: DateWindow?
    let addedAt: Date
    /// İlk sürümde var mı (§05 §2 `v1` kolonu). Kalan 32'si güncelleme yol haritası.
    let isInV1: Bool

    // Türetilen — elle yazılmaz
    var titleKey: String { "deck.\(id).title" }
    var descKey: String { "deck.\(id).desc" }
    var imageName: String { "deck_\(id)" }
    var reelLabel: String { String(format: "%02d", reelNumber) }

    /// §05 §5. Premium durumu ve günlük bedava deste dışarıdan veriliyor;
    /// `SubscriptionStore` P10'da geliyor, model o zamana kadar onu beklemiyor.
    func isLocked(isPremium: Bool, dailyFreeDeckID: String?) -> Bool {
        !isFree && !isPremium && dailyFreeDeckID != id
    }

    /// §05 §1: `Canlandır` modunda `describe` desteler önerilmez ama seçilebilir.
    func isRecommended(inActOutMode: Bool) -> Bool {
        inActOutMode ? playability.supportsActOut : true
    }

    /// §05 §2: `YENİ` chip'i son 60 günde eklenen desteleri gösteriyor.
    func isNew(on date: Date = .now, windowDays: Int = 60) -> Bool {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -windowDays, to: date)
        else { return false }
        return addedAt > cutoff && addedAt <= date
    }

    /// Sezon destesi değilse her zaman görünür.
    func isInSeason(on date: Date = .now) -> Bool {
        guard let window = DeckCatalog.effectiveSeasonWindow(for: id) else { return true }
        return window.contains(date)
    }
}

// MARK: - Katalog

/// §05 §2: 13 bölüm, 124 deste tanımlı, 92'si v1'de.
enum DeckCatalog {

    /// §05 §4: kalıcı ücretsiz deste.
    static let freeDeckID = "cities"

    /// §10 §4: kodlama 3 örnek deste ile başlıyor. Kelime dosyası olmayan bir
    /// deste ızgarada kilitli değil **içeriksiz** — P3 bunu ayırt etmek için
    /// bu listeyi okuyor, `CardBank` boş havuzla tur başlatmıyor.
    static let contentReadyIDs: Set<String> = ["party", "movieClassics", "cities", "icebreaker", "partyFlirty", "dares", "karaoke", "dance", "bachelor", "jobs", "emotions", "animalsAct", "chores", "sportsAct"]

    /// Remote Config'ten gelen sezon penceresi ezmeleri (§09 §8). Bundle
    /// varsayılanı aşağıdaki tabloda; RC yalnızca üzerine yazıyor.
    nonisolated(unsafe) static var seasonWindowOverrides: [String: DateWindow] = [:]

    /// §05 §2: `POPÜLER` kullanım verisinden geliyor, Remote Config güncelliyor.
    /// Aşağıdaki liste ağ yoksa geçerli olan varsayılan.
    nonisolated(unsafe) static var popularDeckIDs: [String] = [
        "party", "jobs", "movieClassics", "emotions", "animalsAct", "superheroes",
        "kidsFirst", "chores", "food", "nineties", "animals", "household",
    ]

    static let all: [DeckDef] = buildCatalog()

    static let byID: [String: DeckDef] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func deck(_ id: String) -> DeckDef? { byID[id] }

    /// İlk sürümde yer alan 92 deste, reel sırasında.
    static let v1: [DeckDef] = all.filter(\.isInV1).sorted { $0.reelNumber < $1.reelNumber }

    /// §05 §2: her deste ~130 kart.
    static let advertisedCardsPerDeck = 130

    /// Paywall ve onboarding'deki "12.000 kart" iddiası (§03 §2 madde 3).
    /// Katalogdan hesaplanıyor: katalog büyüdüğünde metin kendiliğinden
    /// güncelleniyor, sabit bir sayı geride kalmıyor.
    static var advertisedCardCount: Int {
        let total = v1.count * advertisedCardsPerDeck
        return (total + 500) / 1000 * 1000
    }

    static func decks(in section: DeckSection, v1Only: Bool = true) -> [DeckDef] {
        (v1Only ? v1 : all).filter { $0.section == section }
    }

    static func effectiveSeasonWindow(for id: String) -> DateWindow? {
        seasonWindowOverrides[id] ?? byID[id]?.seasonWindow
    }

    /// Izgarada gösterilecek desteler: sezon destesi penceresi dışındaysa listede yok.
    static func visibleDecks(on date: Date = .now) -> [DeckDef] {
        v1.filter { $0.isInSeason(on: date) }
    }

    // MARK: Ana ekran sırası (All)

    /// Açılışta bir kez karıştırılır; süreç boyunca sabit kalır.
    nonisolated(unsafe) private(set) static var sessionOrderIDs: [String] = []

    /// Her uygulama açılışında All ızgarasının sırasını yeniler.
    static func refreshSessionOrder(on date: Date = .now) {
        sessionOrderIDs = visibleDecks(on: date).map(\.id).shuffled()
    }

    /// All filtresi: oturum sırası. Premium değilse kalıcı ücretsiz deste en başta.
    static func homeOrderedDecks(isPremium: Bool, on date: Date = .now) -> [DeckDef] {
        let decks = visibleDecks(on: date)
        if sessionOrderIDs.isEmpty {
            refreshSessionOrder(on: date)
        }
        let rank = Dictionary(
            uniqueKeysWithValues: sessionOrderIDs.enumerated().map { ($1, $0) }
        )
        var ordered = decks.sorted { a, b in
            let ra = rank[a.id] ?? Int.max
            let rb = rank[b.id] ?? Int.max
            if ra != rb { return ra < rb }
            return a.reelNumber < b.reelNumber
        }
        if !isPremium, let index = ordered.firstIndex(where: \.isFree) {
            ordered.insert(ordered.remove(at: index), at: 0)
        }
        return ordered
    }

    // MARK: Günlük bedava deste

    /// §09 §8: bölen **sabit** ve sıra sürümler arası değişmiyor. `premiumDeckCount`
    /// kullanılsa katalog 92'den 124'e büyüdükçe ve sezon desteleri havuza girip
    /// çıktıkça herkeste farklı deste açılırdı. Yeni desteler bu listenin
    /// **sonuna** eklenir, araya girmez.
    static let dailyFreePoolOrder: [String] = v1.filter { !$0.isFree }.map(\.id)

    /// §09 §11 madde 3: editoryal incelemesi bitmemiş desteler rotasyondan muaf.
    /// "Bugün Bekarlığa Veda bedava" bildirimi çocuğuyla oynayan kullanıcıya
    /// gitmemeli. Havuzdan çıkıyorlar ama **bölen sabit kalıyor**.
    nonisolated(unsafe) static var dailyFreeExcludedIDs: Set<String> = []

    /// §09 §8: gün ortada dönerse açılan deste, o desteyle oynanan oturum
    /// bitene kadar açık kalıyor. `LiveGame` başlarken sabitliyor, tur bitince
    /// bırakıyor — masada 6 kişi varken destenin kilitlenmesi yapılabilecek en
    /// kötü şey.
    nonisolated(unsafe) private(set) static var pinnedDailyFreeDeckID: String?

    static func pinDailyFreeDeck(on date: Date = .now) {
        pinnedDailyFreeDeckID = dailyFreeDeckID(on: date)
    }

    static func unpinDailyFreeDeck() {
        pinnedDailyFreeDeckID = nil
    }

    /// §09 §8: gün dönümü cihazın yerel gece yarısı.
    ///
    /// `ignoringPin`, ileri tarihleri soranlar için: § `06` §3 bildirimleri
    /// önümüzdeki iki hafta için önceden planlıyor ve o hesap, bugünün turu
    /// için sabitlenmiş desteden etkilenmemeli.
    static func dailyFreeDeckID(
        on date: Date = .now,
        calendar: Calendar = .current,
        ignoringPin: Bool = false
    ) -> String? {
        if !ignoringPin, let pinnedDailyFreeDeckID { return pinnedDailyFreeDeckID }
        let pool = dailyFreePoolOrder
        guard !pool.isEmpty,
              let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date)
        else { return nil }

        // Penceresi kapalı sezon destesi havuzdan çıkar ama bölen sabit kalır;
        // aksi hâlde "herkeste aynı deste" garantisi bozulur.
        let start = dayOfYear % pool.count
        for step in 0..<pool.count {
            let candidate = pool[(start + step) % pool.count]
            guard !dailyFreeExcludedIDs.contains(candidate) else { continue }
            if byID[candidate]?.isInSeason(on: date) == true { return candidate }
        }
        return nil
    }

    // MARK: Kurulum

    /// Doküman tablosundaki satır. Reel numarası ve tarih burada yok; ikisi de
    /// katalog kurulurken sıradan türetiliyor.
    private struct Seed {
        let id: String
        let section: DeckSection
        let playability: Playability
        let localization: LocalizationStyle
        let difficulty: Difficulty
        let minPlayers: Int
        let isFree: Bool
        let isInV1: Bool
        let season: DateWindow?

        init(
            _ id: String,
            _ section: DeckSection,
            _ playability: Playability,
            _ localization: LocalizationStyle,
            _ difficulty: Difficulty,
            v1: Bool,
            players: Int = 2,
            free: Bool = false,
            season: DateWindow? = nil
        ) {
            self.id = id
            self.section = section
            self.playability = playability
            self.localization = localization
            self.difficulty = difficulty
            self.minPlayers = players
            self.isFree = free
            self.isInV1 = v1
            self.season = season
        }
    }

    private static func buildCatalog() -> [DeckDef] {
        var reelByID: [String: Int] = [:]
        var reel = 0
        for seed in seeds where seed.isInV1 {
            reel += 1
            reelByID[seed.id] = reel
        }
        for seed in seeds where !seed.isInV1 {
            reel += 1
            reelByID[seed.id] = reel
        }

        return seeds.map { seed in
            let reelNumber = reelByID[seed.id] ?? 0
            return DeckDef(
                id: seed.id,
                section: seed.section,
                reelNumber: reelNumber,
                playability: seed.playability,
                localization: seed.localization,
                difficulty: seed.difficulty,
                minPlayers: seed.minPlayers,
                isFree: seed.isFree,
                seasonWindow: seed.season,
                addedAt: placeholderAddedAt(id: seed.id, reelNumber: reelNumber, isInV1: seed.isInV1),
                isInV1: seed.isInV1
            )
        }
    }

    /// `addedAt` yalnızca `YENİ` chip'ini besliyor ve içerik üretimi ayrı bir yol
    /// (§10 §4) — bu yüzden tarihler yer tutucu. Kalıcı ücretsiz deste en yeni
    /// tarihi alıyor, böylece chip lansmanda boş kalmıyor; v1'in kalanı 60 günlük
    /// pencerenin dışında, yol haritasındaki 32 deste gelecek tarihli.
    private static func placeholderAddedAt(id: String, reelNumber: Int, isInV1: Bool) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
        }

        if id == freeDeckID { return date(2026, 7, 20) }
        if isInV1 {
            let base = date(2025, 11, 1)
            return calendar.date(byAdding: .day, value: (reelNumber - 1) * 2, to: base) ?? base
        }
        let base = date(2026, 9, 1)
        return calendar.date(byAdding: .day, value: (reelNumber - 93) * 11, to: base) ?? base
    }

    // MARK: 124 deste — §05 §2

    private static let seeds: [Seed] = [

        // MARK: PARTİ — 10
        Seed("party", .party, .mime, .literal, .easy, v1: true, free: true),
        Seed("icebreaker", .party, .both, .literal, .easy, v1: true, players: 3),
        Seed("partyFlirty", .party, .mime, .adapt, .medium, v1: true),
        Seed("dares", .party, .mime, .literal, .easy, v1: true, players: 3),
        Seed("karaoke", .party, .mime, .adapt, .medium, v1: true, players: 3),
        Seed("dance", .party, .mime, .literal, .easy, v1: true),
        Seed("bachelor", .party, .mime, .adapt, .medium, v1: true, players: 3),
        Seed("birthday", .party, .mime, .literal, .easy, v1: false),
        Seed("costume", .party, .mime, .literal, .medium, v1: false),
        Seed("gossip", .party, .both, .adapt, .medium, v1: false, players: 3),

        // MARK: CANLANDIR — 12 (hepsi mime)
        Seed("jobs", .actOut, .mime, .literal, .easy, v1: true),
        Seed("emotions", .actOut, .mime, .literal, .easy, v1: true),
        Seed("animalsAct", .actOut, .mime, .literal, .easy, v1: true),
        Seed("chores", .actOut, .mime, .literal, .easy, v1: true),
        Seed("sportsAct", .actOut, .mime, .literal, .easy, v1: true),
        Seed("superpowers", .actOut, .mime, .literal, .medium, v1: true),
        Seed("badHabits", .actOut, .mime, .literal, .medium, v1: true),
        Seed("accents", .actOut, .mime, .adapt, .hard, v1: true),
        Seed("celebImpressions", .actOut, .mime, .adapt, .hard, v1: true),
        Seed("winterAct", .actOut, .mime, .literal, .easy, v1: false),
        Seed("couplesAct", .actOut, .mime, .literal, .medium, v1: false),
        Seed("babyAct", .actOut, .mime, .literal, .easy, v1: false),

        // MARK: FİLM & TV — 16
        Seed("movieClassics", .movieTV, .both, .adapt, .medium, v1: true),
        Seed("cartoonMovies", .movieTV, .both, .literal, .easy, v1: true),
        Seed("superheroes", .movieTV, .both, .literal, .easy, v1: true),
        Seed("villains", .movieTV, .both, .literal, .medium, v1: true),
        Seed("tvSeries", .movieTV, .describe, .adapt, .medium, v1: true),
        Seed("streaming", .movieTV, .describe, .adapt, .hard, v1: true),
        Seed("anime", .movieTV, .both, .literal, .hard, v1: true),
        Seed("horror", .movieTV, .both, .literal, .medium, v1: true),
        Seed("scifi", .movieTV, .both, .literal, .medium, v1: true),
        Seed("actors", .movieTV, .describe, .adapt, .hard, v1: true),
        Seed("movieQuotes", .movieTV, .describe, .adapt, .hard, v1: true),
        Seed("tvCartoons", .movieTV, .both, .literal, .easy, v1: true),
        Seed("movieNight", .movieTV, .mime, .literal, .easy, v1: false),
        Seed("directors", .movieTV, .describe, .adapt, .hard, v1: false),
        Seed("awards", .movieTV, .describe, .literal, .hard, v1: false),
        Seed("fictionalChars", .movieTV, .both, .literal, .medium, v1: false),

        // MARK: MÜZİK — 8
        Seed("singers", .music, .describe, .adapt, .medium, v1: true),
        Seed("bands", .music, .describe, .adapt, .hard, v1: true),
        Seed("instruments", .music, .mime, .literal, .easy, v1: true),
        Seed("genres", .music, .mime, .literal, .easy, v1: true),
        Seed("lyrics", .music, .describe, .adapt, .hard, v1: true),
        Seed("kpop", .music, .describe, .literal, .hard, v1: true),
        Seed("rap", .music, .describe, .adapt, .hard, v1: false),
        Seed("classical", .music, .describe, .literal, .hard, v1: false),

        // MARK: ÇOCUK — 12
        Seed("kidsFirst", .kids, .mime, .literal, .easy, v1: true),
        Seed("animalSounds", .kids, .mime, .literal, .easy, v1: true),
        Seed("colorsShapes", .kids, .describe, .literal, .easy, v1: true),
        Seed("fairyTales", .kids, .both, .adapt, .easy, v1: true),
        Seed("toys", .kids, .mime, .literal, .easy, v1: true),
        Seed("school", .kids, .mime, .literal, .easy, v1: true),
        Seed("fruits", .kids, .mime, .literal, .easy, v1: true),
        Seed("vehicles", .kids, .mime, .literal, .easy, v1: true),
        Seed("dinosaurs", .kids, .mime, .literal, .medium, v1: true),
        Seed("numbersLetters", .kids, .describe, .literal, .easy, v1: false),
        Seed("bedtime", .kids, .mime, .literal, .easy, v1: false),
        Seed("kidsHeroes", .kids, .both, .adapt, .medium, v1: false),

        // MARK: SPOR — 10
        Seed("football", .sports, .both, .adapt, .easy, v1: true),
        Seed("basketball", .sports, .both, .literal, .easy, v1: true),
        Seed("footballers", .sports, .describe, .adapt, .hard, v1: true),
        Seed("olympics", .sports, .mime, .literal, .medium, v1: true),
        Seed("combat", .sports, .mime, .literal, .medium, v1: true),
        Seed("extreme", .sports, .mime, .literal, .medium, v1: true),
        Seed("fitness", .sports, .mime, .literal, .easy, v1: true),
        Seed("teams", .sports, .describe, .adapt, .hard, v1: false),
        Seed("motorsport", .sports, .describe, .literal, .hard, v1: false),
        Seed("baseball", .sports, .both, .adapt, .medium, v1: false),

        // MARK: BİLGİ & OKUL — 12
        Seed("space", .knowledge, .both, .literal, .medium, v1: true),
        Seed("body", .knowledge, .mime, .literal, .easy, v1: true),
        Seed("inventions", .knowledge, .both, .literal, .medium, v1: true),
        Seed("historyFigures", .knowledge, .describe, .adapt, .hard, v1: true),
        Seed("famousWomen", .knowledge, .describe, .adapt, .hard, v1: true),
        Seed("mythology", .knowledge, .both, .adapt, .hard, v1: true),
        Seed("science", .knowledge, .describe, .literal, .hard, v1: true),
        Seed("books", .knowledge, .describe, .adapt, .hard, v1: true),
        Seed("writers", .knowledge, .describe, .adapt, .hard, v1: false),
        Seed("periodicTable", .knowledge, .describe, .literal, .hard, v1: false),
        Seed("art", .knowledge, .describe, .literal, .hard, v1: false),
        Seed("professionsHistory", .knowledge, .mime, .adapt, .hard, v1: false),

        // MARK: MARKA & TEKNOLOJİ — 8
        Seed("brands", .brands, .describe, .adapt, .easy, v1: true),
        Seed("cars", .brands, .describe, .adapt, .medium, v1: true),
        Seed("socialMedia", .brands, .mime, .literal, .easy, v1: true),
        Seed("videoGames", .brands, .both, .literal, .medium, v1: true),
        Seed("mobileGames", .brands, .both, .literal, .medium, v1: true),
        Seed("techCompanies", .brands, .describe, .literal, .medium, v1: true),
        Seed("gadgets", .brands, .mime, .literal, .easy, v1: false),
        Seed("fashion", .brands, .describe, .adapt, .hard, v1: false),

        // MARK: NOSTALJİ — 6
        Seed("nineties", .nostalgia, .both, .adapt, .medium, v1: true),
        Seed("eighties", .nostalgia, .both, .adapt, .medium, v1: true),
        Seed("twoThousands", .nostalgia, .both, .adapt, .medium, v1: true),
        Seed("retroTech", .nostalgia, .mime, .literal, .medium, v1: true),
        Seed("childhoodGames", .nostalgia, .mime, .adapt, .easy, v1: true),
        Seed("decadeBest", .nostalgia, .describe, .adapt, .hard, v1: false),

        // MARK: DÜNYA & SEYAHAT — 8
        Seed("countries", .world, .describe, .literal, .easy, v1: true),
        Seed("cities", .world, .describe, .adapt, .medium, v1: true),
        Seed("capitals", .world, .describe, .literal, .hard, v1: true),
        Seed("flags", .world, .describe, .literal, .hard, v1: true),
        Seed("landmarks", .world, .both, .literal, .medium, v1: true),
        Seed("food", .world, .mime, .adapt, .easy, v1: true),
        Seed("drinks", .world, .mime, .adapt, .easy, v1: true),
        Seed("bucketList", .world, .mime, .literal, .medium, v1: false),

        // MARK: HAYVANLAR & DOĞA — 6
        Seed("animals", .animals, .mime, .literal, .easy, v1: true),
        Seed("seaLife", .animals, .mime, .literal, .easy, v1: true),
        Seed("birds", .animals, .mime, .literal, .medium, v1: true),
        Seed("dogBreeds", .animals, .describe, .literal, .hard, v1: true),
        Seed("catBreeds", .animals, .describe, .literal, .hard, v1: false),
        Seed("nature", .animals, .mime, .literal, .easy, v1: false),

        // MARK: EV & GÜNLÜK HAYAT — 6
        Seed("household", .home, .mime, .literal, .easy, v1: true),
        Seed("everyday", .home, .mime, .literal, .easy, v1: true),
        Seed("kitchen", .home, .mime, .literal, .easy, v1: true),
        Seed("clothes", .home, .mime, .literal, .easy, v1: true),
        Seed("tools", .home, .mime, .literal, .medium, v1: false),
        Seed("hobbies", .home, .mime, .literal, .easy, v1: false),

        // MARK: SEZON & TATİL — 10 (pencereye göre görünür)
        Seed("newYear", .seasonal, .mime, .literal, .easy, v1: true,
             season: .gregorian(MonthDay(12, 15), MonthDay(1, 5))),
        Seed("christmas", .seasonal, .both, .literal, .easy, v1: true,
             season: .gregorian(MonthDay(12, 1), MonthDay(12, 31))),
        Seed("christmasMovies", .seasonal, .describe, .literal, .medium, v1: true,
             season: .gregorian(MonthDay(12, 1), MonthDay(12, 31))),
        Seed("valentine", .seasonal, .mime, .literal, .easy, v1: true,
             season: .gregorian(MonthDay(2, 7), MonthDay(2, 20))),
        Seed("halloween", .seasonal, .both, .literal, .easy, v1: true,
             season: .gregorian(MonthDay(10, 20), MonthDay(10, 31))),
        // Ramazan ayının tamamı; hicri ay 29 ya da 30 gün olabiliyor.
        Seed("ramadan", .seasonal, .mime, .adapt, .easy, v1: true,
             season: .hijri(MonthDay(9, 1), MonthDay(9, 30))),
        // İki bayram: Şevval 1–4 (Ramazan) ve Zilhicce 10–14 (Kurban).
        Seed("eid", .seasonal, .mime, .adapt, .easy, v1: true,
             season: .any([
                .hijri(MonthDay(10, 1), MonthDay(10, 4)),
                .hijri(MonthDay(12, 10), MonthDay(12, 14)),
             ])),
        Seed("summer", .seasonal, .mime, .literal, .easy, v1: true,
             season: .gregorian(MonthDay(6, 1), MonthDay(8, 31))),
        Seed("backToSchool", .seasonal, .mime, .literal, .easy, v1: false,
             season: .gregorian(MonthDay(8, 25), MonthDay(9, 20))),
        Seed("easter", .seasonal, .mime, .literal, .easy, v1: false,
             season: .easter(daysBefore: 10, daysAfter: 2)),
    ]
}
