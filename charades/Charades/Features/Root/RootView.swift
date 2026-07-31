import SwiftUI

/// Paket 1 komponent galerisi: tema katmanının tamamı tek ekranda görünsün diye.
/// Gerçek navigasyon kabuğu ve deste ızgarası P3'te bunun yerine geçecek.
struct RootView: View {
    @Bindable private var settings = AppSettingsStore.shared
    @Bindable private var l10n = LocalizationManager.shared

    @State private var switchOn = true
    @State private var page = 1
    @State private var showsCurtain = false

    var body: some View {
        ZStack {
            VelvetBackground(showsCurtain: showsCurtain, showsLightLeak: true)

            ScrollView {
                VStack(spacing: 28) {
                    logoPlaque
                    buttonsSection
                    switchSection
                    filmStripSection
                    bulbsSection
                    typeScaleSection
                    paletteSection
                    effectsSection
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 32)
            }
        }
    }

    // MARK: Logo

    private var logoPlaque: some View {
        VStack(spacing: 8) {
            Text(l10n.t("app.name"))
                .textStyle(.marquee)
                .foregroundStyle(AppColors.surfacePoster)
                .shadow(color: AppColors.accentAmber.opacity(0.5), radius: 20)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .overlay { BulbFrame(countPerEdge: 9, diameter: 5, color: AppColors.accentAmber) }

            Text("Grand Marquee")
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.accentGold)
        }
        .padding(.bottom, 4)
    }

    // MARK: Bölümler

    private var buttonsSection: some View {
        Card("Buttons") {
            Button(l10n.t("common.play")) {}
                .buttonStyle(MarqueeButtonStyle())

            Button(l10n.t("common.play")) {}
                .buttonStyle(MarqueeButtonStyle())
                .disabled(true)

            Button("Secondary") {}
                .buttonStyle(SecondaryButtonStyle())

            Button("Secondary") {}
                .buttonStyle(SecondaryButtonStyle())
                .disabled(true)
        }
    }

    private var switchSection: some View {
        Card("MarqueeSwitch") {
            HStack {
                Text("Titreşim")
                    .textStyle(.bodyStrong)
                    .foregroundStyle(AppColors.textCream)
                Spacer()
                MarqueeSwitch(isOn: $switchOn)
            }
        }
    }

    private var filmStripSection: some View {
        Card("FilmStripProgress · SprocketStrip") {
            FilmStripProgress(total: 4, current: page)
                .onTapGesture { page = (page + 1) % 4 }
            SprocketStrip(holeColor: AppColors.bgFilmBlack)
                .background(AppColors.surfacePoster)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }

    private var bulbsSection: some View {
        Card("BulbRow") {
            BulbRow(count: 12, diameter: 5, color: AppColors.accentAmber)
            BulbRow(count: 12, diameter: 5, color: AppColors.accentAmber, isLit: false)
        }
    }

    private var typeScaleSection: some View {
        Card("Tip ölçeği") {
            row("screenTitle", .screenTitle, AppColors.textCream)
            row("posterTitle", .posterTitle, AppColors.textCream)
            row("gameWord 34", .gameWord(34), AppColors.textCream)
            row("sectionLabel", .sectionLabel, AppColors.accentGold)
            row("body", .body, AppColors.textCream)
            row("caption", .caption, AppColors.textSecondary)
            row("creditsName", .creditsName, AppColors.textCream)
        }
    }

    private func row(_ label: String, _ style: AppTextStyle, _ color: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .textStyle(.caption)
                .foregroundStyle(AppColors.textMuted)
                .frame(width: 96, alignment: .leading)
            Text("Sessiz Sinema")
                .textStyle(style)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    private var paletteSection: some View {
        Card("Palet") {
            ForEach(Self.paletteGroups, id: \.0) { name, colors in
                VStack(alignment: .leading, spacing: 5) {
                    Text(name)
                        .textStyle(.caption)
                        .foregroundStyle(AppColors.textMuted)
                    HStack(spacing: 5) {
                        ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(height: 26)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(AppColors.textMuted.opacity(0.25), lineWidth: 0.5)
                                }
                        }
                    }
                }
            }
        }
    }

    private var effectsSection: some View {
        Card("Doku katmanları") {
            effectRow("Kadife perde", isOn: $showsCurtain)
            effectRow("Film efektleri (grain)", isOn: $settings.filmEffectsEnabled)
            effectRow("Scanline", isOn: $settings.scanlinesEnabled)

            RoundedRectangle(cornerRadius: 6)
                .fill(AppColors.surfacePoster)
                .frame(height: 44)
                .overlay { ScanlineOverlay() }
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func effectRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .textStyle(.body)
                .foregroundStyle(AppColors.textCream)
            Spacer()
            MarqueeSwitch(isOn: isOn)
        }
    }

    private static let paletteGroups: [(String, [Color])] = [
        ("Arka plan", [
            AppColors.bgFilmBlack, AppColors.bgVelvetDeep, AppColors.bgVelvetMid,
            AppColors.bgVelvetLight, AppColors.bgSpotlight,
        ]),
        ("Yüzey", [
            AppColors.surfaceCard, AppColors.surfaceCardRaised,
            AppColors.surfacePoster, AppColors.surfaceTicket,
        ]),
        ("Accent", [
            AppColors.accentAmber, AppColors.accentAmberDeep,
            AppColors.accentGold, AppColors.accentBrass, AppColors.accentTeal,
        ]),
        ("Durum", [
            AppColors.stateCorrect, AppColors.stateSkip,
            AppColors.stateWarning, AppColors.stateLocked,
        ]),
    ]
}

/// Galeri bölümü kabuğu — §4'teki sheet/kart anatomisinin sade hâli.
private struct Card<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.accentGold)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.surfaceCard.opacity(0.85))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppColors.accentGold.opacity(0.28), lineWidth: 1)
                }
        }
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
