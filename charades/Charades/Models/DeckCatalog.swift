import Foundation


enum Playability: String, Codable, Sendable {
    case mime
    case describe
    case both


    var supportsActOut: Bool { self != .describe }
}


enum LocalizationStyle: String, Codable, Sendable {
    case literal
    case adapt
}


enum Difficulty: String, Codable, Sendable, CaseIterable {
    case easy
    case medium
    case hard

    var titleKey: String { "difficulty.\(rawValue)" }
}


struct MonthDay: Hashable, Sendable {
    let month: Int
    let day: Int

    init(_ month: Int, _ day: Int) {
        self.month = month
        self.day = day
    }
}


enum DateWindow: Hashable, Sendable {

    case gregorian(MonthDay, MonthDay)

    case hijri(MonthDay, MonthDay)

    case easter(daysBefore: Int, daysAfter: Int)

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


struct DeckDef: Identifiable, Hashable, Sendable {
    let id: String
    let section: DeckSection


    let reelNumber: Int
    let playability: Playability
    let localization: LocalizationStyle
    let difficulty: Difficulty
    let minPlayers: Int
    let isFree: Bool
    let seasonWindow: DateWindow?
    let addedAt: Date

    let isInV1: Bool


    var titleKey: String { "deck.\(id).title" }
    var descKey: String { "deck.\(id).desc" }
    var imageName: String { "deck_\(id)" }
    var reelLabel: String { String(format: "%02d", reelNumber) }


    func isLocked(isPremium: Bool, dailyFreeDeckID: String?) -> Bool {
        !isFree && !isPremium && dailyFreeDeckID != id
    }


    func isRecommended(inActOutMode: Bool) -> Bool {
        inActOutMode ? playability.supportsActOut : true
    }


    func isNew(on date: Date = .now, windowDays: Int = 60) -> Bool {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -windowDays, to: date)
        else { return false }
        return addedAt > cutoff && addedAt <= date
    }


    func isInSeason(on date: Date = .now) -> Bool {
        guard let window = DeckCatalog.effectiveSeasonWindow(for: id) else { return true }
        return window.contains(date)
    }
}


enum DeckCatalog {


    static let freeDeckID = "cities"


    static let contentReadyIDs: Set<String> = ["accents", "actors", "animalSounds", "animals", "animalsAct", "anime", "bachelor", "badHabits", "bands", "basketball", "birds", "body", "books", "brands", "capitals", "cars", "cartoonMovies", "celebImpressions", "childhoodGames", "chores", "christmas", "christmasMovies", "cities", "clothes", "colorsShapes", "combat", "countries", "dance", "dares", "dinosaurs", "dogBreeds", "drinks", "eid", "eighties", "emotions", "everyday", "extreme", "fairyTales", "famousWomen", "fitness", "flags", "food", "football", "footballers", "fruits", "genres", "halloween", "historyFigures", "horror", "household", "icebreaker", "instruments", "inventions", "jobs", "karaoke", "kidsFirst", "kitchen", "kpop", "landmarks", "lyrics", "mobileGames", "movieClassics", "movieQuotes", "mythology", "newYear", "nineties", "olympics", "party", "partyFlirty", "ramadan", "retroTech", "school", "science", "scifi", "seaLife", "singers", "socialMedia", "space", "sportsAct", "streaming", "summer", "superheroes", "superpowers", "techCompanies", "toys", "tvCartoons", "tvSeries", "twoThousands", "valentine", "vehicles", "videoGames", "villains"]


    nonisolated(unsafe) static var seasonWindowOverrides: [String: DateWindow] = [:]


    nonisolated(unsafe) static var popularDeckIDs: [String] = [
        "party", "jobs", "movieClassics", "emotions", "animalsAct", "superheroes",
        "kidsFirst", "chores", "food", "nineties", "animals", "household",
    ]

    static let all: [DeckDef] = buildCatalog()

    static let byID: [String: DeckDef] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func deck(_ id: String) -> DeckDef? { byID[id] }


    static let v1: [DeckDef] = all.filter(\.isInV1).sorted { $0.reelNumber < $1.reelNumber }


    static let advertisedCardsPerDeck = 130


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


    static func visibleDecks(on date: Date = .now) -> [DeckDef] {
        v1.filter { $0.isInSeason(on: date) }
    }


    nonisolated(unsafe) private(set) static var sessionOrderIDs: [String] = []


    static func refreshSessionOrder(on date: Date = .now) {
        sessionOrderIDs = visibleDecks(on: date).map(\.id).shuffled()
    }


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


    static let dailyFreePoolOrder: [String] = v1.filter { !$0.isFree }.map(\.id)


    nonisolated(unsafe) static var dailyFreeExcludedIDs: Set<String> = []


    nonisolated(unsafe) private(set) static var pinnedDailyFreeDeckID: String?

    static func pinDailyFreeDeck(on date: Date = .now) {
        pinnedDailyFreeDeckID = dailyFreeDeckID(on: date)
    }

    static func unpinDailyFreeDeck() {
        pinnedDailyFreeDeckID = nil
    }


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


        let start = dayOfYear % pool.count
        for step in 0..<pool.count {
            let candidate = pool[(start + step) % pool.count]
            guard !dailyFreeExcludedIDs.contains(candidate) else { continue }
            if byID[candidate]?.isInSeason(on: date) == true { return candidate }
        }
        return nil
    }


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


    private static let seeds: [Seed] = [


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


        Seed("singers", .music, .describe, .adapt, .medium, v1: true),
        Seed("bands", .music, .describe, .adapt, .hard, v1: true),
        Seed("instruments", .music, .mime, .literal, .easy, v1: true),
        Seed("genres", .music, .mime, .literal, .easy, v1: true),
        Seed("lyrics", .music, .describe, .adapt, .hard, v1: true),
        Seed("kpop", .music, .describe, .literal, .hard, v1: true),
        Seed("rap", .music, .describe, .adapt, .hard, v1: false),
        Seed("classical", .music, .describe, .literal, .hard, v1: false),


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


        Seed("brands", .brands, .describe, .adapt, .easy, v1: true),
        Seed("cars", .brands, .describe, .adapt, .medium, v1: true),
        Seed("socialMedia", .brands, .mime, .literal, .easy, v1: true),
        Seed("videoGames", .brands, .both, .literal, .medium, v1: true),
        Seed("mobileGames", .brands, .both, .literal, .medium, v1: true),
        Seed("techCompanies", .brands, .describe, .literal, .medium, v1: true),
        Seed("gadgets", .brands, .mime, .literal, .easy, v1: false),
        Seed("fashion", .brands, .describe, .adapt, .hard, v1: false),


        Seed("nineties", .nostalgia, .both, .adapt, .medium, v1: true),
        Seed("eighties", .nostalgia, .both, .adapt, .medium, v1: true),
        Seed("twoThousands", .nostalgia, .both, .adapt, .medium, v1: true),
        Seed("retroTech", .nostalgia, .mime, .literal, .medium, v1: true),
        Seed("childhoodGames", .nostalgia, .mime, .adapt, .easy, v1: true),
        Seed("decadeBest", .nostalgia, .describe, .adapt, .hard, v1: false),


        Seed("countries", .world, .describe, .literal, .easy, v1: true),
        Seed("cities", .world, .describe, .adapt, .medium, v1: true),
        Seed("capitals", .world, .describe, .literal, .hard, v1: true),
        Seed("flags", .world, .describe, .literal, .hard, v1: true),
        Seed("landmarks", .world, .both, .literal, .medium, v1: true),
        Seed("food", .world, .mime, .adapt, .easy, v1: true),
        Seed("drinks", .world, .mime, .adapt, .easy, v1: true),
        Seed("bucketList", .world, .mime, .literal, .medium, v1: false),


        Seed("animals", .animals, .mime, .literal, .easy, v1: true),
        Seed("seaLife", .animals, .mime, .literal, .easy, v1: true),
        Seed("birds", .animals, .mime, .literal, .medium, v1: true),
        Seed("dogBreeds", .animals, .describe, .literal, .hard, v1: true),
        Seed("catBreeds", .animals, .describe, .literal, .hard, v1: false),
        Seed("nature", .animals, .mime, .literal, .easy, v1: false),


        Seed("household", .home, .mime, .literal, .easy, v1: true),
        Seed("everyday", .home, .mime, .literal, .easy, v1: true),
        Seed("kitchen", .home, .mime, .literal, .easy, v1: true),
        Seed("clothes", .home, .mime, .literal, .easy, v1: true),
        Seed("tools", .home, .mime, .literal, .medium, v1: false),
        Seed("hobbies", .home, .mime, .literal, .easy, v1: false),


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

        Seed("ramadan", .seasonal, .mime, .adapt, .easy, v1: true,
             season: .hijri(MonthDay(9, 1), MonthDay(9, 30))),

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
