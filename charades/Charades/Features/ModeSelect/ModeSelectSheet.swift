import SwiftUI


struct ModeSelectSheet: View {
    var onClose: () -> Void
    var onPlay: () -> Void

    var onNeedsSideSetup: (GameMode) -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(AppRouter.self) private var router
    @Environment(AppSettingsStore.self) private var settings
    @Environment(GameSetup.self) private var setup

    private var mode: GameMode { setup.mode }

    private var duration: Int {
        setup.effectiveDuration(userPreference: settings.roundDuration)
    }

    private var difficulty: CardDifficultyFilter {
        setup.difficulty ?? settings.difficulty
    }

    private var filteredCardCount: Int {
        setup.selectedDeckIDs.reduce(0) {
            $0 + CardBank.shared.cards(in: $1, difficulty: difficulty).count
        }
    }

    private var isPoolTooSmall: Bool {
        difficulty != .all && !setup.selectedDeckIDs.isEmpty && filteredCardCount < 20
    }

    var body: some View {
        SheetScaffold(title: l10n.t("mode.select.title"), onClose: onClose) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        modes
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
                    .padding(.top, 4)
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


    private var modes: some View {
        VStack(spacing: 9) {
            ForEach(GameMode.allCases) { mode in
                ModeCard(
                    mode: mode,
                    isSelected: setup.mode == mode,
                    isLocked: isLocked(mode),
                    action: { tap(mode) }
                )
            }
        }
    }

    private func isLocked(_ mode: GameMode) -> Bool {
        !mode.isFree && !subscriptions.isPremium
    }

    private func tap(_ mode: GameMode) {
        guard !isLocked(mode) else {
            Haptics.lockedWall()
            router.openPaywall(.lockedMode(mode.id))
            return
        }
        Haptics.modeSelected()
        Analytics.modeSelect(mode: mode.id)
        setup.mode = mode

        if needsSideSetup(mode) {
            onNeedsSideSetup(mode)
        }
    }


    private func needsSideSetup(_ mode: GameMode) -> Bool {
        if !mode.needsDeckSelection { return true }
        if mode.usesTeams { return true }
        if mode == .mix, !setup.isMix { return true }
        return false
    }


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
                        .appTracking(1.8)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.accentBrass)
                }
                .frame(maxWidth: .infinity)

                stepButton(systemImage: "plus", delta: GameMode.durationStep)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(groupBackground)

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
                        .appTracking(1.6)
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
            .appTracking(1.4)
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


    private func groupLabel(_ key: String) -> some View {
        Text(l10n.t(key))
            .font(AppFont.ui(9.5, weight: .bold))
            .appTracking(2.4)
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
