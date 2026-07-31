import SwiftUI

struct GameSettingsView: View {
    @Bindable var session: GameSession
    var onBack: () -> Void
    var onPlay: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @State private var showSettings = false

    private var playerCount: Int { session.namedPlayers.count }
    private var recommended: Int { CategoryCatalog.recommendedImposters(for: playerCount) }
    private var maxImposters: Int { CategoryCatalog.maxImposters(for: playerCount) }

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                ScreenChromeHeader(
                    title: l10n.t("gameSettings.title"),
                    onBack: {
                        Haptics.light()
                        onBack()
                    },
                    onSettings: {
                        Haptics.light()
                        showSettings = true
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

                VStack(spacing: 14) {
                    modeBanner

                    controlCard(
                        title: l10n.t("gameSettings.imposters"),
                        subtitle: l10n.t(
                            "gameSettings.impostersDesc",
                            ["n": "\(playerCount)", "rec": "\(recommended)"]
                        )
                    ) {
                        StepperControl(
                            valueText: "\(session.imposterCount)",
                            canDecrement: session.imposterCount > 1,
                            canIncrement: session.imposterCount < maxImposters,
                            onDecrement: { session.imposterCount -= 1 },
                            onIncrement: { session.imposterCount += 1 }
                        )
                    }

                    if session.selectedMode.isRapid {
                        controlCard(
                            title: l10n.t("gameSettings.rapidTitle"),
                            subtitle: l10n.t(
                                "gameSettings.rapidBody",
                                ["n": "\(RapidRoundLimits.secondsPerTurn)"]
                            )
                        ) {
                            Text("\(RapidRoundLimits.secondsPerTurn)s")
                                .font(AppFont.display(32, weight: .black))
                                .foregroundStyle(AppColors.accentYellow)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        controlCard(
                            title: l10n.t("gameSettings.roundDuration"),
                            subtitle: l10n.t("gameSettings.roundDurationDesc")
                        ) {
                            StepperControl(
                                valueText: formatDuration(session.roundDurationSeconds),
                                canDecrement: session.roundDurationSeconds > RoundDurationLimits.minSeconds,
                                canIncrement: session.roundDurationSeconds < RoundDurationLimits.maxSeconds,
                                onDecrement: {
                                    session.roundDurationSeconds = max(
                                        RoundDurationLimits.minSeconds,
                                        session.roundDurationSeconds - RoundDurationLimits.stepSeconds
                                    )
                                },
                                onIncrement: {
                                    session.roundDurationSeconds = min(
                                        RoundDurationLimits.maxSeconds,
                                        session.roundDurationSeconds + RoundDurationLimits.stepSeconds
                                    )
                                }
                            )
                        }
                    }

                    if session.selectedMode.usesDecoyWord {
                        controlCard(
                            title: l10n.t("gameSettings.decoyTitle"),
                            subtitle: l10n.t("gameSettings.decoyBody")
                        ) {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(AppColors.accentCyan)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        controlCard(
                            title: l10n.t("gameSettings.imposterHints"),
                            subtitle: l10n.t("gameSettings.imposterHintsDesc")
                        ) {
                            OnOffToggle(isOn: $session.imposterHintsEnabled)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .scaleEffect(1.15)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 110)
            }

            VStack {
                Spacer(minLength: 0)
                PlayBar(
                    playTitle: l10n.t("gameSettings.launch"),
                    count: session.imposterCount,
                    countSystemImage: "theatermasks.fill",
                    countAccessibilityLabel: l10n.t(
                        "gameSettings.playSummary",
                        ["n": "\(session.imposterCount)"]
                    ),
                    enabled: true
                ) {
                    Haptics.medium()
                    clampImposterCount()
                    onPlay()
                }
            }
        }
        .navigationBarHidden(true)
        .onSwipeBack(perform: onBack)
        .onAppear {
            session.imposterCount = recommended
            clampImposterCount()
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }

    private var modeBanner: some View {
        HStack(spacing: 14) {
            Image(session.selectedMode.iconImageName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 58, height: 58)
                .shadow(color: AppColors.accentCyan.opacity(0.35), radius: 8, y: 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(l10n.t(session.selectedMode.titleKey))
                    .font(AppFont.display(22, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(l10n.t(session.selectedMode.subtitleKey))
                    .font(AppFont.ui(13, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppColors.accentCyan.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func controlCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(AppFont.display(18, weight: .black))
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(AppFont.ui(13, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            content()
                .padding(.top, 2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppColors.accentCyan.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private func clampImposterCount() {
        session.imposterCount = min(max(1, session.imposterCount), maxImposters)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
