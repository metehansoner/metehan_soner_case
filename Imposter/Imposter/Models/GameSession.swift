import SwiftUI

/// Session-only game setup. Cleared on every cold start (players never persist).
@Observable
final class GameSession {
    var players: [Player]
    var selectedMode: GameMode
    var selectedCategoryIDs: Set<String> = []
    /// Categories unlocked for this session via rewarded ad (stub until ads are wired).
    var adUnlockedCategoryIDs: Set<String> = []
    /// English secret-word keys already used this session (avoid repeats across rounds).
    var usedSecretWordKeys: Set<String> = []
    var imposterCount = 1
    var roundDurationSeconds = RoundDurationLimits.defaultSeconds
    var imposterHintsEnabled = true

    init(mode: GameMode = AppSettingsStore.shared.lastGameMode) {
        selectedMode = mode
        players = (0..<PlayerLimits.minCount).map { _ in Player() }
    }

    var canContinuePlayers: Bool {
        let named = players.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return named.count >= PlayerLimits.minCount && named.count == players.count
    }

    var namedPlayers: [Player] {
        players
            .map { Player(id: $0.id, name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.name.isEmpty }
    }

    var canContinueCategories: Bool {
        !selectedCategoryIDs.isEmpty
            && selectedCategoryIDs.allSatisfy { id in
                guard let cat = CategoryCatalog.all.first(where: { $0.id == id }) else { return false }
                return !cat.isLocked(adUnlockedIDs: adUnlockedCategoryIDs)
            }
    }

    func addPlayer() {
        guard players.count < PlayerLimits.maxCount else { return }
        players.append(Player())
        Haptics.light()
    }

    func removePlayer(at index: Int) {
        guard players.count > PlayerLimits.minCount, players.indices.contains(index) else { return }
        players.remove(at: index)
        Haptics.light()
    }

    func removePlayer(id: UUID) {
        guard players.count > PlayerLimits.minCount,
              let index = players.firstIndex(where: { $0.id == id }) else { return }
        players.remove(at: index)
        Haptics.light()
    }

    func resetPlayersForNewLaunch() {
        players = (0..<PlayerLimits.minCount).map { _ in Player() }
        selectedCategoryIDs = []
        adUnlockedCategoryIDs = []
        usedSecretWordKeys = []
        imposterCount = 1
        roundDurationSeconds = RoundDurationLimits.defaultSeconds
        imposterHintsEnabled = true
        selectedMode = AppSettingsStore.shared.lastGameMode
    }
}
