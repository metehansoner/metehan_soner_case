import Foundation
import Observation


@MainActor
@Observable
final class TeamMatch {


    static let suddenDeathDuration = 30


    struct TurnResult: Identifiable, Equatable {
        let id = UUID()
        let teamIndex: Int

        let player: String?

        let round: Int
        let correct: Int
        let skipped: Int
        let points: Int
        let isSuddenDeath: Bool
    }

    enum Next: Equatable {
        case turn(teamIndex: Int, player: String?)
        case matchEnd
    }


    struct Standing: Identifiable {
        let id: Int
        let team: Team
        let points: Int

        let suddenDeathCorrect: Int?

        let roleIndex: Int
    }

    struct Award: Equatable {

        let subject: String
        let value: Int
    }

    let teams: [Team]
    let roundsPerTeam: Int

    private(set) var results: [TurnResult] = []

    private(set) var currentTeamIndex = 0
    private(set) var currentPlayer: String?

    private(set) var currentRound = 1
    private(set) var isSuddenDeath = false


    private var cursor = 0
    private var suddenDeathTeams: [Int] = []

    init(teams: [Team], roundsPerTeam: Int) {
        self.teams = teams
        self.roundsPerTeam = roundsPerTeam
        currentPlayer = teams.first?.player(forTurn: 0)
    }

    var totalTurns: Int { teams.count * roundsPerTeam }

    var currentTeam: Team { teams[currentTeamIndex] }


    var completedTurns: Int { results.filter { !$0.isSuddenDeath }.count }


    var matchTurnNumber: Int {
        if isSuddenDeath { return min(cursor + 1, max(suddenDeathTeams.count, 1)) }
        return min(completedTurns + 1, max(totalTurns, 1))
    }

    var matchTurnTotal: Int {
        isSuddenDeath ? max(suddenDeathTeams.count, 1) : max(totalTurns, 1)
    }


    func finishTurn(correct: Int, skipped: Int, points: Int) -> Next {
        results.append(
            TurnResult(
                teamIndex: currentTeamIndex,
                player: currentPlayer,
                round: isSuddenDeath ? 0 : currentRound,
                correct: correct,
                skipped: skipped,
                points: points,
                isSuddenDeath: isSuddenDeath
            )
        )
        cursor += 1
        return advance()
    }

    private func advance() -> Next {
        if isSuddenDeath {
            guard cursor < suddenDeathTeams.count else { return .matchEnd }
            return begin(teamIndex: suddenDeathTeams[cursor])
        }
        if cursor < totalTurns {
            return begin(teamIndex: cursor % teams.count)
        }


        let tied = leaders()
        guard tied.count > 1 else { return .matchEnd }
        isSuddenDeath = true
        suddenDeathTeams = tied
        cursor = 0
        return begin(teamIndex: tied[0])
    }

    private func begin(teamIndex: Int) -> Next {
        currentTeamIndex = teamIndex
        currentRound = isSuddenDeath ? 0 : (cursor / teams.count) + 1
        let played = results.filter { $0.teamIndex == teamIndex }.count
        currentPlayer = teams[teamIndex].player(forTurn: played)
        return .turn(teamIndex: teamIndex, player: currentPlayer)
    }


    func points(for teamIndex: Int) -> Int {
        results
            .filter { $0.teamIndex == teamIndex && !$0.isSuddenDeath }
            .reduce(0) { $0 + $1.points }
    }

    func suddenDeathCorrect(for teamIndex: Int) -> Int? {
        results.first { $0.teamIndex == teamIndex && $0.isSuddenDeath }?.correct
    }

    private func leaders() -> [Int] {
        let totals = teams.indices.map { points(for: $0) }
        guard let best = totals.max() else { return [] }
        return totals.indices.filter { totals[$0] == best }
    }

    var standings: [Standing] {
        let entries = teams.indices.map {
            (index: $0, points: points(for: $0), tiebreak: suddenDeathCorrect(for: $0) ?? -1)
        }
        func isBetter(_ a: (index: Int, points: Int, tiebreak: Int),
                      _ b: (index: Int, points: Int, tiebreak: Int)) -> Bool {
            a.points != b.points ? a.points > b.points : a.tiebreak > b.tiebreak
        }
        return entries
            .sorted(by: isBetter)
            .map { entry in
                Standing(
                    id: entry.index,
                    team: teams[entry.index],
                    points: entry.points,
                    suddenDeathCorrect: suddenDeathCorrect(for: entry.index),
                    roleIndex: entries.filter { isBetter($0, entry) }.count
                )
            }
    }


    var isSharedVictory: Bool {
        standings.filter { $0.roleIndex == 0 }.count > 1
    }


    var bestPerformer: Award? { bestSubject { $0.correct } }

    var mostSkips: Award? { bestSubject { $0.skipped } }


    var boxOffice: (correct: Int, team: String, round: Int)? {
        guard let best = results.filter({ $0.correct > 0 }).max(by: { $0.correct < $1.correct }),
              let first = results.first(where: { $0.correct == best.correct })
        else { return nil }
        return (first.correct, teams[first.teamIndex].name, first.round)
    }

    private func subject(for result: TurnResult) -> String {
        result.player ?? teams[result.teamIndex].name
    }

    private func bestSubject(_ value: (TurnResult) -> Int) -> Award? {
        var order: [String] = []
        var totals: [String: Int] = [:]
        for result in results {
            let key = subject(for: result)
            if totals[key] == nil { order.append(key) }
            totals[key, default: 0] += value(result)
        }
        var best: Award?
        for key in order {
            guard let total = totals[key], total > 0 else { continue }
            if best == nil || total > best!.value {
                best = Award(subject: key, value: total)
            }
        }
        return best
    }
}
