import SwiftUI

/// Ekran 11 — Takım Kurulumu (§ `02` §4, § `04` §1, § `09` §5).
///
/// Yalnızca Takım Savaşı modunda, Mod Seçimi'nden sonra açılıyor. Üç şey
/// topluyor: takımlar, oyuncu adları ve tur sayısı.
///
/// Ad alanlarının hiçbiri zorunlu değil (§ `09` §5). Takım adı boşsa numarayla
/// anılıyor, oyuncu adı yoksa perde arası ve jenerik takım adıyla yetiniyor —
/// masadaki grup "hadi başlayalım" diyorsa tek dokunuşla geçiliyor. Adlar
/// girilirse perde arasında "telefonu Ayşe alsın", jenerikte "EN İYİ
/// CANLANDIRMA — AYŞE" mümkün oluyor.
struct TeamSetupView: View {
    var onContinue: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppRouter.self) private var router
    @Environment(GameSetup.self) private var setup

    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case name(UUID)
        case player(UUID, Int)
    }

    var body: some View {
        ZStack {
            VelvetBackground()

            VStack(spacing: 0) {
                navBar

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(setup.teams.enumerated()), id: \.element.id) { index, team in
                            teamCard(index: index, team: team)
                        }

                        if setup.teams.count < Team.countRange.upperBound {
                            addTeamButton
                        }

                        roundsRow
                            .padding(.top, 4)

                        Text(l10n.t("teams.players.optional"))
                            .font(AppFont.ui(11))
                            .foregroundStyle(AppColors.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)

                Button(l10n.t("teams.continue")) {
                    Haptics.primaryButton()
                    focus = nil
                    setup.tidyTeams()
                    onContinue()
                }
                .buttonStyle(MarqueeButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: Başlık

    private var navBar: some View {
        HStack(spacing: 0) {
            Button {
                Haptics.secondaryButton()
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.accentGold)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("common.back"))

            VStack(spacing: 2) {
                Text(l10n.t("teams.setup.title"))
                    .font(AppFont.display(19, weight: .bold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)

                Text(summary)
                    .font(AppFont.ui(10.5))
                    .foregroundStyle(AppColors.textMuted)
            }
            .frame(maxWidth: .infinity)

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }

    /// İki sayaç tek dizede birleşmiyor: tekil/çoğul ayrımı her dilde ayrı
    /// anahtar istiyor (`playbar.summary` deseni).
    private var summary: String {
        let teams = l10n.t("teams.setup.teamCount", count: setup.teams.count)
        let rounds = l10n.t("teams.setup.roundCount", count: setup.roundsPerTeam)
        return "\(teams) · \(rounds)"
    }

    // MARK: Takım kartı

    private func teamCard(index: Int, team: Team) -> some View {
        let binding = teamBinding(team.id)

        return VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 10) {
                Circle()
                    .fill(AppColors.team(index))
                    .frame(width: 12, height: 12)
                    .shadow(color: AppColors.team(index).opacity(0.7), radius: 6)

                TextField(
                    l10n.t("teams.defaultName", ["index": "\(index + 1)"]),
                    text: binding.name
                )
                .font(AppFont.display(17, weight: .semibold))
                .foregroundStyle(AppColors.textCream)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($focus, equals: .name(team.id))

                teamMenu(index: index, team: team)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 92), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(Array(team.players.enumerated()), id: \.offset) { slot, _ in
                    playerChip(team: team, binding: binding, slot: slot)
                }

                if team.players.count < Team.playerLimit {
                    addPlayerChip(team: team, binding: binding)
                }
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func teamMenu(index: Int, team: Team) -> some View {
        Menu {
            Button(l10n.t("teams.rename")) {
                focus = .name(team.id)
            }
            if setup.teams.count > Team.countRange.lowerBound {
                Button(l10n.t("teams.remove"), role: .destructive) {
                    Haptics.secondaryButton()
                    focus = nil
                    setup.removeTeam(team.id)
                }
            }
        } label: {
            Text(l10n.t("teams.edit"))
                .font(AppFont.ui(11, weight: .semibold))
                .foregroundStyle(AppColors.accentAmber)
                .padding(.horizontal, 4)
                .frame(height: 30)
        }
        .accessibilityLabel(l10n.t("teams.edit"))
    }

    // MARK: Oyuncu chip'i

    private func playerChip(team: Team, binding: Binding<Team>, slot: Int) -> some View {
        HStack(spacing: 4) {
            TextField(
                l10n.t("teams.player.placeholder"),
                text: Binding(
                    get: { slot < binding.wrappedValue.players.count ? binding.wrappedValue.players[slot] : "" },
                    set: { newValue in
                        guard slot < binding.wrappedValue.players.count else { return }
                        binding.wrappedValue.players[slot] = newValue
                    }
                )
            )
            .font(AppFont.ui(12.5))
            .foregroundStyle(AppColors.textCream)
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .focused($focus, equals: .player(team.id, slot))

            Button {
                focus = nil
                binding.wrappedValue.players.remove(at: slot)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(AppColors.textMuted)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("teams.player.remove"))
        }
        .padding(.leading, 11)
        .padding(.trailing, 5)
        .padding(.vertical, 7)
        .background {
            Capsule()
                .fill(AppColors.bgFilmBlack.opacity(0.45))
                .overlay { Capsule().strokeBorder(AppColors.accentGold.opacity(0.22), lineWidth: 1) }
        }
    }

    private func addPlayerChip(team: Team, binding: Binding<Team>) -> some View {
        Button {
            Haptics.secondaryButton()
            binding.wrappedValue.players.append("")
            focus = .player(team.id, binding.wrappedValue.players.count - 1)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .bold))
                Text(l10n.t("teams.addPlayer"))
                    .font(AppFont.ui(12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(AppColors.accentGold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                Capsule().strokeBorder(
                    AppColors.accentGold.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Takım ekle

    private var addTeamButton: some View {
        Button {
            Haptics.deckSelected()
            setup.addTeam()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                Text(l10n.t("teams.addTeam"))
                    .font(AppFont.display(14, weight: .semibold))
                    .tracking(1.6)
                    .textCase(.uppercase)
            }
            .foregroundStyle(AppColors.accentGold)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: 14).strokeBorder(
                    AppColors.accentGold.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Tur sayısı

    /// § `09` §5: bu ayarın hangi ekranda olduğu hiçbir yerde yazmıyordu —
    /// yeri burası, takım başına 1–5 tur.
    private var roundsRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.accentGold)

            VStack(alignment: .leading, spacing: 1) {
                Text(l10n.t("teams.rounds"))
                    .font(AppFont.ui(14, weight: .semibold))
                    .foregroundStyle(AppColors.textCream)
                Text(l10n.t("teams.rounds.hint"))
                    .font(AppFont.ui(10.5))
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer(minLength: 0)

            HStack(spacing: 2) {
                roundsStep(systemImage: "minus", delta: -1)
                Text("\(setup.roundsPerTeam)")
                    .font(AppFont.display(18, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(AppColors.textCream)
                    .frame(minWidth: 26)
                roundsStep(systemImage: "plus", delta: 1)
            }
            .padding(3)
            .background {
                Capsule().fill(AppColors.bgFilmBlack.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(cardBackground)
    }

    private func roundsStep(systemImage: String, delta: Int) -> some View {
        Button {
            let next = setup.roundsPerTeam + delta
            guard Team.roundsRange.contains(next) else {
                Haptics.stepperLimit()
                return
            }
            Haptics.selection()
            setup.roundsPerTeam = next
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.accentAmber)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l10n.t(delta > 0 ? "teams.rounds.increase" : "teams.rounds.decrease"))
    }

    // MARK: Ortak

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(AppColors.surfaceCard.opacity(0.85))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.accentGold.opacity(0.2), lineWidth: 1)
            }
    }

    /// Index yerine kimlik üzerinden: takım silindiğinde açıkta kalan bir
    /// index'e yazmak listeyi bozuyor.
    private func teamBinding(_ id: UUID) -> Binding<Team> {
        Binding(
            get: { setup.teams.first { $0.id == id } ?? Team(id: id) },
            set: { newValue in
                guard let index = setup.teams.firstIndex(where: { $0.id == id }) else { return }
                setup.teams[index] = newValue
            }
        )
    }
}
