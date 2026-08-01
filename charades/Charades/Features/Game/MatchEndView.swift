import SwiftUI

/// Ekran 19 — Maç Sonu · Jenerik Akışı (§ `02` §4, § `08` B1).
///
/// Skorlar tablo olarak değil **film jeneriği** olarak akıyor. Ödüller
/// dekorasyon değil: "en iyi canlandırma" ve "gişe rekoru" takım modunda zaten
/// tutulan gerçek veriden geliyor (§ `08` B1), o yüzden masada konuşulan bir
/// şey oluyor.
///
/// **Portrait** (§ `09` §1): yön yalnızca burada geri dönüyor ve dönüşün açık
/// bir mikro animasyonu var — ekran 13'ün tersi. Maç bittiği için kimse acele
/// etmiyor, bu geçiş rahatsız etmiyor.
struct MatchEndView: View {
    let match: TeamMatch
    /// §04 §4.3: jenerikteki `ARŞİVE GİT` yalnızca o maçtan kayıt kaldıysa.
    var hasReels: Bool
    var onRematch: () -> Void
    var onArchive: () -> Void
    var onExit: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isRolling = true
    @State private var hasStartedRoll = false
    @State private var rollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var rollEnd: Task<Void, Never>?
    @State private var showsRotateHint = true
    @State private var hintUpright = false

    /// § `08` B1: yukarı doğru yavaş akış.
    private let rollDuration: TimeInterval = 17

    var body: some View {
        ZStack {
            VelvetBackground(showsCurtain: true)

            credits
                .mask(fadeMask)

            exitButton
            actionBar

            if showsRotateHint {
                rotateHint
                    .transition(.opacity)
            }

            // §08 B4: jeneriğin açılış vurgusu. Bantlar kalıcı değil, girip
            // çekiliyor — jenerik akışının okunacağı alanı daraltmıyorlar.
            LetterboxBars()
        }
        .statusBarHidden()
        .task {
            // Yön geometrisi oturana kadar duran kısa bir yönlendirme.
            try? await Task.sleep(for: .milliseconds(1800))
            withAnimation(.easeOut(duration: 0.4)) { showsRotateHint = false }
        }
    }

    // MARK: Jenerik

    @ViewBuilder
    private var credits: some View {
        // § `08` notlar: Reduce Motion'da jenerik statik listeye dönüyor,
        // hiçbir bilgi kaybolmuyor — akış bilgi taşımayan bir katman.
        if isRolling, !reduceMotion {
            GeometryReader { geometry in
                column
                    .measuringHeight($contentHeight)
                    .offset(y: rollOffset == 0 ? geometry.size.height : rollOffset)
                    .onAppear { startRoll(from: geometry.size.height) }
                    .onChange(of: contentHeight) { _, _ in startRoll(from: geometry.size.height) }
            }
            // § `08` B1: jeneriği beklemek zorunlu değil, dokunuşla sonuna atlanır.
            .contentShape(Rectangle())
            .onTapGesture { skipRoll() }
        } else {
            ScrollView {
                column
                    .padding(.top, 30)
                    .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var column: some View {
        VStack(spacing: 0) {
            Text(l10n.t("teams.credits.presents"))
                .font(AppFont.ui(11, weight: .bold))
                .appTracking(8)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.accentBrass)
                .padding(.bottom, 52)

            ForEach(match.standings) { standing in
                block(
                    role: l10n.t(roleKey(standing.roleIndex)),
                    name: standing.team.name,
                    detail: counted("teams.credits.points", standing.points)
                )
            }

            // § `09` §5: beraberliği bozan tur. Puanlar eşit kaldığı için
            // sıralamanın sebebi ancak bu satırda görünüyor.
            if let winner = suddenDeathWinner {
                block(
                    role: l10n.t("teams.suddenDeath.title"),
                    name: winner.team.name,
                    detail: counted("teams.credits.correct", winner.suddenDeathCorrect ?? 0)
                )
            }

            if let award = match.bestPerformer {
                block(
                    role: l10n.t("teams.credits.bestActor"),
                    name: award.subject,
                    detail: counted("teams.credits.correct", award.value)
                )
            }

            if let award = match.mostSkips {
                block(
                    role: l10n.t("teams.credits.mostSkips"),
                    name: award.subject,
                    detail: counted("teams.credits.skips", award.value)
                )
            }

            if let record = match.boxOffice {
                block(
                    role: l10n.t("teams.credits.boxOffice"),
                    name: l10n.t("teams.credits.boxOffice.value", ["count": "\(record.correct)"]),
                    detail: record.round > 0
                        ? "\(record.team) · \(l10n.t("teams.credits.round", ["index": "\(record.round)"]))"
                        : "\(record.team) · \(l10n.t("teams.suddenDeath.title"))"
                )
            }

            Text(l10n.t("teams.credits.fin"))
                .font(AppFont.accent(34, weight: .bold, italic: true))
                .foregroundStyle(AppColors.accentAmber)
                .padding(.top, 20)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 34)
    }

    private func block(role: String, name: String, detail: String) -> some View {
        VStack(spacing: 4) {
            Text(role)
                .textStyle(.creditsRole)
                .foregroundStyle(AppColors.accentGold)

            Text(name)
                .textStyle(.creditsName)
                .foregroundStyle(AppColors.textCream)

            Text(detail)
                .font(AppFont.display(14, weight: .medium))
                .appTracking(2.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.bottom, 36)
    }

    private var suddenDeathWinner: TeamMatch.Standing? {
        guard !match.isSharedVictory else { return nil }
        return match.standings.first { $0.suddenDeathCorrect != nil && $0.roleIndex == 0 }
    }

    private func counted(_ key: String, _ count: Int) -> String {
        l10n.t(key, count: count)
    }

    private func roleKey(_ index: Int) -> String {
        // § `09` §5: 3–4. takımın rolü de tanımlı.
        switch index {
        case 0: "teams.role.lead"
        case 1: "teams.role.support"
        case 2: "teams.role.guest"
        default: "teams.role.extra"
        }
    }

    // MARK: Akış

    private func startRoll(from containerHeight: CGFloat) {
        guard isRolling, !hasStartedRoll, contentHeight > 0 else { return }
        hasStartedRoll = true
        rollOffset = containerHeight
        withAnimation(.linear(duration: rollDuration)) {
            rollOffset = -contentHeight
        }
        // Akış bitince liste okunabilir hâlde duruyor; jenerik ekranda hiçbir
        // şey kalmayan bir boşlukla bitmiyor.
        rollEnd = Task {
            try? await Task.sleep(for: .seconds(rollDuration))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.45)) { isRolling = false }
        }
    }

    private func skipRoll() {
        guard isRolling else { return }
        Haptics.secondaryButton()
        rollEnd?.cancel()
        withAnimation(.easeOut(duration: 0.25)) { isRolling = false }
    }

    /// § `08` B1: üstte ve altta karartma — yazı ekrana girip çıkarken eriyor.
    private var fadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.16),
                .init(color: .black, location: 0.8),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: Butonlar

    private var exitButton: some View {
        Button {
            Haptics.secondaryButton()
            onExit()
        } label: {
            Image(systemName: "chevron.left")
                    .flipsForRightToLeftLayoutDirection(true)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.accentGold)
                .frame(width: 42, height: 42)
                .background {
                    Circle().fill(AppColors.bgFilmBlack.opacity(0.55))
                }
                .tapTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l10n.t("round.backToStage"))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 14)
    }

    /// § `08` B1: `TEKRAR OYNA` ve `PAYLAŞ` sabit duruyor, jeneriği beklemiyor.
    private var actionBar: some View {
        VStack(spacing: 10) {
            if hasReels {
                Button {
                    Haptics.secondaryButton()
                    onArchive()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 12, weight: .semibold))
                        Text(l10n.t("teams.goToArchive"))
                            .font(AppFont.display(12, weight: .semibold))
                            .appTracking(1.6)
                            .textCase(.uppercase)
                    }
                    .foregroundStyle(AppColors.accentGold)
                }
                .buttonStyle(.plain)
            }

            buttonRow
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 30)
        .background {
            LinearGradient(
                colors: [.clear, AppColors.bgFilmBlack.opacity(0.97)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var buttonRow: some View {
        HStack(spacing: 10) {
            ShareLink(item: shareText) {
                Text(l10n.t("teams.share"))
                    .font(AppFont.display(13, weight: .semibold))
                    .appTracking(1.7)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background {
                        Capsule().strokeBorder(AppColors.accentGold.opacity(0.5), lineWidth: 1)
                    }
            }

            Button {
                Haptics.primaryButton()
                onRematch()
            } label: {
                Text(l10n.t("round.playAgain"))
                    .font(AppFont.display(13, weight: .semibold))
                    .appTracking(1.7)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textOnAmber)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background {
                        Capsule()
                            .fill(AppColors.accentAmber)
                            .overlay(alignment: .bottom) {
                                Capsule()
                                    .fill(AppColors.accentAmberDeep)
                                    .frame(height: 3)
                                    .padding(.horizontal, 12)
                            }
                    }
            }
            .buttonStyle(.plain)
        }
    }

    private var shareText: String {
        let lines = match.standings.map { standing in
            "\(l10n.t(roleKey(standing.roleIndex))): \(standing.team.name) · "
                + counted("teams.credits.points", standing.points)
        }
        return ([l10n.t("teams.share.header")] + lines).joined(separator: "\n")
    }

    // MARK: Yön geçişi — § `09` §1

    /// Ekran 13'ün tersi: yatayken duran telefon dikeye dönüyor.
    private var rotateHint: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.surfaceCard.opacity(0.9))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppColors.accentGold, lineWidth: 2.5)
                }
                .frame(width: 64, height: 118)
                .rotationEffect(.degrees(hintUpright ? 0 : -90))
                .animation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: hintUpright
                )
                .onAppear { hintUpright = true }

            Text(l10n.t("teams.rotatePortrait"))
                .font(AppFont.ui(12, weight: .semibold))
                .appTracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.bgFilmBlack.opacity(0.9).ignoresSafeArea())
        .allowsHitTesting(false)
    }
}

private extension View {
    /// Jeneriğin ne kadar yol alacağı içerik yüksekliğine bağlı; içerik dile
    /// göre uzayıp kısaldığı için ölçülüyor, sabit bir değer tutmuyor.
    func measuringHeight(_ height: Binding<CGFloat>) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { height.wrappedValue = proxy.size.height }
                    .onChange(of: proxy.size.height) { _, new in height.wrappedValue = new }
            }
        }
    }
}
