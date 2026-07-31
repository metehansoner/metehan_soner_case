import Foundation
import Observation

/// Bir Takım Savaşı maçının tamamı — 04-oyun-modlari.md §1, 09-kesinti-ve-sinir-durumlari.md §5.
///
/// `LiveGame` tek bir **turu** yönetiyor; takımların sırası, biriken puan ve
/// beraberliğin çözümü burada. İkisi ayrı çünkü tur, maçın içinde defalarca
/// baştan kuruluyor (`restartRound`) ama maç bir kez yaşıyor.
///
/// Takım adları buraya **çözülmüş** geliyor (`Team.resolvingName`): jenerik ve
/// perde arası boş ad görmüyor, model de lokalizasyona bağlanmıyor.
@MainActor
@Observable
final class TeamMatch {

    /// § `09` §5: ani ölüm 30 saniyelik tek tur.
    static let suddenDeathDuration = 30

    /// Oynanmış tek tur. Jenerikteki ödüller (§ `08` B1) bu kayıtlardan
    /// üretiliyor — "en iyi canlandırma" uydurma değil, kimin sırasında kaç
    /// doğru olduğu zaten burada duruyor.
    struct TurnResult: Identifiable, Equatable {
        let id = UUID()
        let teamIndex: Int
        /// Telefonu tutan kişi; ad girilmemişse `nil`.
        let player: String?
        /// 1-tabanlı tur numarası. Ani ölüm turunda 0.
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

    /// Jenerikteki rol sırası (§ `09` §5): `BAŞ ROL` · `YARDIMCI ROL` ·
    /// `KONUK OYUNCU` · `FİGÜRAN`.
    struct Standing: Identifiable {
        let id: Int
        let team: Team
        let points: Int
        /// Ani ölüm oynandıysa o turdaki doğru sayısı.
        let suddenDeathCorrect: Int?
        /// 0 = `BAŞ ROL`. Tam eşit takımlar **aynı** rolü paylaşıyor.
        let roleIndex: Int
    }

    struct Award: Equatable {
        /// Oyuncu adı; girilmemişse takım adı (§ `09` §5).
        let subject: String
        let value: Int
    }

    let teams: [Team]
    let roundsPerTeam: Int

    private(set) var results: [TurnResult] = []

    private(set) var currentTeamIndex = 0
    private(set) var currentPlayer: String?
    /// 1-tabanlı; ani ölümde 0.
    private(set) var currentRound = 1
    private(set) var isSuddenDeath = false

    /// Sıradaki turun, içinde bulunulan aşamadaki index'i.
    private var cursor = 0
    private var suddenDeathTeams: [Int] = []

    init(teams: [Team], roundsPerTeam: Int) {
        self.teams = teams
        self.roundsPerTeam = roundsPerTeam
        currentPlayer = teams.first?.player(forTurn: 0)
    }

    var totalTurns: Int { teams.count * roundsPerTeam }

    var currentTeam: Team { teams[currentTeamIndex] }

    /// Perde arası "3 / 6" göstergesi için oynanmış normal tur sayısı.
    var completedTurns: Int { results.filter { !$0.isSuddenDeath }.count }

    // MARK: Sıra

    /// Tur sonu ekranından çıkılırken çağrılıyor — skor orada düzeltmelerle
    /// hâlâ değişebildiği için maça **o an** yazılıyor.
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

        // § `09` §5: her takım eşit tur oynadığı için beraberlik istatistiksel
        // olarak sık. Tepede eşitlik varsa ani ölüm turu; bu kural olmadan
        // masadaki tartışmayı uygulama çözemiyor.
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

    // MARK: Skor

    /// Ani ölüm turu **toplama girmiyor**: § `09` §5'te kazananı belirleyen o
    /// turdaki doğru sayısı, puan değil. Jenerikte iki takım da berabere
    /// kaldıkları puanla görünüyor, sıralamayı ani ölüm satırı açıklıyor.
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

    /// § `09` §5: ani ölüm de bozamazsa paylaşımlı zafer — iki takım da `BAŞ ROL`.
    var isSharedVictory: Bool {
        standings.filter { $0.roleIndex == 0 }.count > 1
    }

    // MARK: Jenerik ödülleri — § `08` B1

    var bestPerformer: Award? { bestSubject { $0.correct } }

    var mostSkips: Award? { bestSubject { $0.skipped } }

    /// "Gişe rekoru": tek turda çıkarılan en yüksek doğru.
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
