// Takım Savaşı maç mantığını cihazsız doğrular
// (04-oyun-modlari.md §1, 09-kesinti-ve-sinir-durumlari.md §5).
//
// Beraberlik, tur sırası, oyuncu rotasyonu ve jenerik ödülleri UI'dan
// bağımsız kurallar; ekranda doğrulamak için maçın bitmesini beklemek
// gerekiyor ve beraberlik rastgele çıkıyor.

import Foundation

var failures = 0

func check(_ label: String, _ condition: Bool, _ detail: String = "") {
    if condition {
        print("  ✓ \(label)")
    } else {
        failures += 1
        print("  ✗ \(label)\(detail.isEmpty ? "" : " — \(detail)")")
    }
}

func team(_ name: String, _ players: [String] = []) -> Team {
    Team(name: name, players: players)
}

/// Sırayla verilen (doğru, pas) çiftlerini oynatıp fazları döndürüyor.
@MainActor
func play(_ match: TeamMatch, _ turns: [(Int, Int)]) -> [TeamMatch.Next] {
    turns.map { match.finishTurn(correct: $0.0, skipped: $0.1, points: $0.0) }
}

@MainActor
func run() {
    print("Tur sırası ve oyuncu rotasyonu")
    do {
        let match = TeamMatch(
            teams: [team("A", ["Ali", "Ayşe"]), team("B", ["Burak"])],
            roundsPerTeam: 2
        )
        check("maç ilk takımla başlıyor", match.currentTeamIndex == 0)
        check("ilk oyuncu ilk sırada", match.currentPlayer == "Ali")
        check("toplam tur = takım × tur", match.totalTurns == 4)

        var next = match.finishTurn(correct: 3, skipped: 1, points: 3)
        check("sıra ikinci takıma geçti", next == .turn(teamIndex: 1, player: "Burak"))
        check("tur numarası hâlâ 1", match.currentRound == 1)

        next = match.finishTurn(correct: 2, skipped: 0, points: 2)
        check("tur 2 birinci takımla başlıyor", next == .turn(teamIndex: 0, player: "Ayşe"))
        check("tur numarası 2 oldu", match.currentRound == 2)
        check("takım içi oyuncu sırayla dönüyor", match.currentPlayer == "Ayşe")

        _ = match.finishTurn(correct: 1, skipped: 0, points: 1)
        next = match.finishTurn(correct: 0, skipped: 4, points: 0)
        check("son tur sonrası maç bitiyor", next == .matchEnd)
        check("A toplamı", match.points(for: 0) == 4, "\(match.points(for: 0))")
        check("B toplamı", match.points(for: 1) == 2, "\(match.points(for: 1))")
    }

    print("Oyuncu adı girilmemişse")
    do {
        let match = TeamMatch(teams: [team("A"), team("B")], roundsPerTeam: 1)
        check("sıradaki kişi yok", match.currentPlayer == nil)
        let next = match.finishTurn(correct: 2, skipped: 0, points: 2)
        check("perde arası kişisiz devam ediyor", next == .turn(teamIndex: 1, player: nil))
        _ = match.finishTurn(correct: 1, skipped: 3, points: 1)
        check("ödül takım adına yazılıyor", match.bestPerformer?.subject == "A")
        check("en çok pas takım adına yazılıyor", match.mostSkips?.subject == "B")
    }

    print("Kazanan ve roller")
    do {
        let match = TeamMatch(
            teams: [team("A"), team("B"), team("C"), team("D")],
            roundsPerTeam: 1
        )
        _ = play(match, [(1, 0), (4, 0), (2, 0), (3, 0)])
        let standings = match.standings
        check("sıralama puana göre", standings.map(\.team.name) == ["B", "D", "C", "A"])
        check("roller sırayla dağılıyor", standings.map(\.roleIndex) == [0, 1, 2, 3])
        check("paylaşımlı zafer yok", !match.isSharedVictory)
    }

    print("Beraberlik → ani ölüm turu")
    do {
        let match = TeamMatch(
            teams: [team("A", ["Ali"]), team("B", ["Burak"]), team("C")],
            roundsPerTeam: 1
        )
        _ = play(match, [(5, 1), (5, 0)])
        let next = match.finishTurn(correct: 2, skipped: 0, points: 2)

        check("berabere takımlar ani ölüme gidiyor", match.isSuddenDeath)
        check("ani ölüm ilk berabere takımla başlıyor", next == .turn(teamIndex: 0, player: "Ali"))
        check("geride kalan takım ani ölüme girmiyor", match.currentTeamIndex != 2)

        let second = match.finishTurn(correct: 3, skipped: 0, points: 3)
        check("ani ölüm ikinci takıma geçiyor", second == .turn(teamIndex: 1, player: "Burak"))

        let end = match.finishTurn(correct: 6, skipped: 0, points: 6)
        check("ani ölüm tek turla bitiyor", end == .matchEnd)

        check("ani ölüm puanı toplama girmiyor", match.points(for: 1) == 5, "\(match.points(for: 1))")
        check("beraberliği doğru sayısı bozuyor", match.standings.first?.team.name == "B")
        check("kaybeden yine de eşit puanda", match.standings[1].points == 5)
        check("paylaşımlı zafer yok", !match.isSharedVictory)
    }

    print("Ani ölüm de berabere → paylaşımlı zafer")
    do {
        let match = TeamMatch(teams: [team("A"), team("B")], roundsPerTeam: 1)
        _ = play(match, [(4, 0), (4, 0)])
        check("ani ölüm başladı", match.isSuddenDeath)
        _ = play(match, [(2, 0), (2, 0)])
        check("iki takım da BAŞ ROL", match.standings.allSatisfy { $0.roleIndex == 0 })
        check("paylaşımlı zafer", match.isSharedVictory)
    }

    print("Jenerik ödülleri gerçek veriden")
    do {
        let match = TeamMatch(
            teams: [team("A", ["Ali", "Ayşe"]), team("B", ["Burak", "Buse"])],
            roundsPerTeam: 2
        )
        _ = play(match, [(3, 1), (2, 5), (7, 0), (1, 2)])

        check("en iyi canlandırma tek turdaki rekoru değil toplamı", match.bestPerformer?.subject == "Ayşe")
        check("en iyi canlandırma değeri", match.bestPerformer?.value == 7)
        check("en çok pas geçen", match.mostSkips?.subject == "Burak", match.mostSkips?.subject ?? "-")
        check("en çok pas değeri", match.mostSkips?.value == 5)

        let record = match.boxOffice
        check("gişe rekoru en yüksek tek tur", record?.correct == 7)
        check("gişe rekoru takımı", record?.team == "A")
        check("gişe rekoru turu", record?.round == 2)
    }

    print("Puansız maçta ödül uydurulmuyor")
    do {
        let match = TeamMatch(teams: [team("A", ["Ali"]), team("B", ["Burak"])], roundsPerTeam: 1)
        _ = play(match, [(0, 0), (0, 0)])
        check("en iyi canlandırma yok", match.bestPerformer == nil)
        check("en çok pas yok", match.mostSkips == nil)
        check("gişe rekoru yok", match.boxOffice == nil)
    }

    print("Takım adı çözümü")
    do {
        let resolved = [Team(name: "  "), Team(name: " Perdeciler ")]
            .enumerated()
            .map { $1.resolvingName(order: $0) { "\($0). Takım" } }
        check("boş ad numaraya düşüyor", resolved[0].name == "1. Takım")
        check("girilen ad kırpılıyor", resolved[1].name == "Perdeciler")

        let team = Team(name: "A", players: ["Ali", "  ", "Ayşe"])
        check("boş oyuncu alanı sayılmıyor", team.namedPlayers == ["Ali", "Ayşe"])
        check("oyuncu sırası başa dönüyor", team.player(forTurn: 2) == "Ali")
    }
}

MainActor.assumeIsolated { run() }

print(failures == 0 ? "\nOK — tüm maç kuralları geçti" : "\n\(failures) kontrol başarısız")
exit(failures == 0 ? 0 : 1)
