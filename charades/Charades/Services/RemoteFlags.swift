import FirebaseRemoteConfig
import Foundation


enum RemoteFlags {
    enum Key {
        static let seasonWindows = "season_windows"
        static let popularDecks = "popular_decks"
        static let dailyFreeExclusions = "daily_free_pool_exclusions"
        static let socialProofEnabled = "social_proof_enabled"

        static let all = [seasonWindows, popularDecks, dailyFreeExclusions, socialProofEnabled]
    }


    private(set) nonisolated(unsafe) static var socialProofEnabled = false

    static func loadBundleDefaults() {
        guard
            let url = Bundle.main.url(forResource: "RemoteConfigDefaults", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let values = try? PropertyListSerialization.propertyList(from: data, format: nil)
                as? [String: Any]
        else { return }
        apply(values)
    }


    static func apply(_ values: [String: Any]) {
        if let windows = values[Key.seasonWindows] as? [String: String] {
            DeckCatalog.seasonWindowOverrides = windows.compactMapValues(parseWindow)
        }
        if let popular = values[Key.popularDecks] as? [String], !popular.isEmpty {
            DeckCatalog.popularDeckIDs = popular
        }
        if let excluded = values[Key.dailyFreeExclusions] as? [String] {
            DeckCatalog.dailyFreeExcludedIDs = Set(excluded)
        }
        if let flag = values[Key.socialProofEnabled] as? Bool {
            socialProofEnabled = flag
        }
    }


    static func fetchRemote() {
        let config = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 12 * 60 * 60
        #endif
        config.configSettings = settings


        config.fetchAndActivate { status, _ in
            guard status != .error else { return }
            Task { @MainActor in applyRemoteValues() }
        }
    }

    private static func applyRemoteValues() {
        let config = RemoteConfig.remoteConfig()
        let values = Key.all.reduce(into: [String: Any]()) { result, key in
            let value = config[key]


            guard value.source == .remote, let decoded = decode(key: key, value: value) else {
                return
            }
            result[key] = decoded
        }
        guard !values.isEmpty else { return }
        apply(values)
    }


    private static func decode(key: String, value: RemoteConfigValue) -> Any? {
        switch key {
        case Key.socialProofEnabled:
            return value.boolValue
        case Key.seasonWindows:
            return try? JSONDecoder().decode([String: String].self, from: value.dataValue)
        default:
            return try? JSONDecoder().decode([String].self, from: value.dataValue)
        }
    }


    static func parseWindow(_ raw: String) -> DateWindow? {
        let parts = raw.split(separator: "|").compactMap(parseSingleWindow)
        switch parts.count {
        case 0: return nil
        case 1: return parts[0]
        default: return .any(parts)
        }
    }

    private static func parseSingleWindow(_ raw: Substring) -> DateWindow? {
        let pieces = raw.split(separator: ":", maxSplits: 1)
        guard pieces.count == 2 else { return nil }
        let body = pieces[1].split(separator: "/")
        guard body.count == 2 else { return nil }

        switch pieces[0] {
        case "g":
            guard let from = monthDay(body[0]), let to = monthDay(body[1]) else { return nil }
            return .gregorian(from, to)
        case "h":
            guard let from = monthDay(body[0]), let to = monthDay(body[1]) else { return nil }
            return .hijri(from, to)
        case "e":
            guard let before = Int(body[0]), let after = Int(body[1]) else { return nil }
            return .easter(daysBefore: abs(before), daysAfter: abs(after))
        default:
            return nil
        }
    }

    private static func monthDay(_ raw: Substring) -> MonthDay? {
        let parts = raw.split(separator: "-")
        guard parts.count == 2, let month = Int(parts[0]), let day = Int(parts[1]),
              (1...12).contains(month), (1...31).contains(day)
        else { return nil }
        return MonthDay(month, day)
    }
}
