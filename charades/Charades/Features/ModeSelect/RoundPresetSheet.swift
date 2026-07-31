import SwiftUI

/// Ekran 12 — Tur Ön Ayar (§ `02` §4, § `04` §3).
///
/// İki ayar var: süre ve zorluk. § `09` §5'te "kart sayısı" ayarı **kaldırıldı** —
/// ekranda duruyordu ama hiçbir mekaniğe bağlı değildi.
///
/// § `09` §9: buradaki değerler **yalnızca o tur için** geçerli, ayarlardaki
/// kalıcı tercihi yazmıyor. `GameSetup` bir maçın kurulumu, `AppSettingsStore`
/// kullanıcının varsayılanı.
struct RoundPresetSheet: View {
    var onBack: (() -> Void)?
    var onClose: () -> Void
    var onPlay: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(GameSetup.self) private var setup

    private var mode: GameMode { setup.mode }

    private var duration: Int {
        setup.effectiveDuration(userPreference: settings.roundDuration)
    }

    private var difficulty: CardDifficultyFilter {
        setup.difficulty ?? settings.difficulty
    }

    /// § `09` §4: zorluk filtresi havuzu beklenmedik ölçüde küçültebiliyor —
    /// `ZOR` seçiliyken ağırlıklı kolay bir deste 14 karta düşüyor. Sayı burada
    /// hesaplanıyor çünkü tur başladıktan sonra söylemenin faydası yok.
    private var filteredCardCount: Int {
        setup.selectedDeckIDs.reduce(0) {
            $0 + CardBank.shared.cards(in: $1, difficulty: difficulty).count
        }
    }

    /// Uyarı yalnızca **filtre** havuzu küçülttüğünde çıkıyor: çözümü zorluğu
    /// `HEPSİ` yapmak olan durum bu. Destenin kendisi küçükse (custom deste,
    /// Kelime Sepeti) § `09` §4 tavsiyeyi editörde veriyor, burada değil —
    /// orada `HEPSİ` önermenin bir karşılığı yok.
    private var isPoolTooSmall: Bool {
        difficulty != .all && !setup.selectedDeckIDs.isEmpty && filteredCardCount < 20
    }

    var body: some View {
        SheetScaffold(title: l10n.t("preset.title"), onBack: onBack, onClose: onClose) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        groupLabel("preset.duration")
                        durationRow

                        groupLabel("preset.difficulty")
                        difficultyRow

                        if isPoolTooSmall {
                            poolWarning
                                .padding(.top, 14)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)

                Button(l10n.t("common.play")) {
                    Haptics.primaryButton()
                    onPlay()
                }
                .buttonStyle(MarqueeButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
    }

    // MARK: Süre

    private var durationRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                stepButton(systemImage: "minus", delta: -GameMode.durationStep)

                VStack(spacing: 1) {
                    Text(l10n.t("preset.seconds", ["count": "\(duration)"]))
                        .font(AppFont.display(30, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(AppColors.textCream)
                    Text(l10n.t(mode.titleKey))
                        .font(AppFont.ui(9, weight: .semibold))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.accentBrass)
                }
                .frame(maxWidth: .infinity)

                stepButton(systemImage: "plus", delta: GameMode.durationStep)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(groupBackground)

            // § `04` §3: "Hız Turu'nda süre sabittir" notu. Kilidin sebebini
            // yazmayan bir disabled stepper, bozuk bir stepper'dan ayırt edilmiyor.
            if mode.isDurationLocked {
                Text(l10n.t("preset.duration.locked"))
                    .font(AppFont.ui(10.5))
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.leading, 3)
            }
        }
    }

    private func stepButton(systemImage: String, delta: Int) -> some View {
        Button {
            adjustDuration(by: delta)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(mode.isDurationLocked ? AppColors.stateLocked : AppColors.accentAmber)
                .frame(width: 42, height: 42)
                .background {
                    Circle()
                        .fill(AppColors.bgFilmBlack.opacity(0.55))
                        .overlay {
                            Circle().strokeBorder(
                                (mode.isDurationLocked ? AppColors.stateLocked : AppColors.accentGold)
                                    .opacity(0.5),
                                lineWidth: 1
                            )
                        }
                }
        }
        .buttonStyle(.plain)
        .disabled(mode.isDurationLocked)
        .accessibilityLabel(l10n.t(delta > 0 ? "preset.duration.increase" : "preset.duration.decrease"))
    }

    private func adjustDuration(by delta: Int) {
        let next = duration + delta
        guard GameMode.durationRange.contains(next) else {
            Haptics.stepperLimit()
            return
        }
        Haptics.selection()
        setup.duration = next
    }

    // MARK: Zorluk

    private var difficultyRow: some View {
        HStack(spacing: 6) {
            ForEach(CardDifficultyFilter.allCases, id: \.rawValue) { option in
                let isSelected = difficulty == option
                Button {
                    Haptics.selection()
                    setup.difficulty = option
                } label: {
                    Text(l10n.t(option.titleKey))
                        .font(AppFont.ui(11, weight: .semibold))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(isSelected ? AppColors.textOnAmber : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            Capsule().fill(isSelected ? AppColors.accentAmber : .clear)
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(4)
        .background(groupBackground)
    }

    /// § `09` §4: engel değil öneri — kullanıcı yine bu zorlukla oynayabiliyor.
    private var poolWarning: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(l10n.t("preset.smallPool", count: filteredCardCount))
                .font(AppFont.ui(12))
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(l10n.t("preset.smallPool.action")) {
                Haptics.selection()
                setup.difficulty = .all
            }
            .buttonStyle(.plain)
            .font(AppFont.ui(11, weight: .bold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.accentAmber)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background {
            RoundedRectangle(cornerRadius: 13)
                .fill(AppColors.stateWarning.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(AppColors.stateWarning.opacity(0.45), lineWidth: 1)
                }
        }
    }

    // MARK: Ortak

    private func groupLabel(_ key: String) -> some View {
        Text(l10n.t(key))
            .font(AppFont.ui(9.5, weight: .bold))
            .tracking(2.4)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.accentGold)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .padding(.leading, 3)
    }

    private var groupBackground: some View {
        RoundedRectangle(cornerRadius: 13)
            .fill(AppColors.surfaceCard.opacity(0.85))
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(AppColors.accentGold.opacity(0.2), lineWidth: 1)
            }
    }
}
