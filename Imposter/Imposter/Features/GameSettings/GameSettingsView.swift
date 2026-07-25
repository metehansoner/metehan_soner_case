import SwiftUI

struct GameSettingsView: View {
    @Bindable var session: GameSession
    var onBack: () -> Void
    var onPlay: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @State private var showSettings = false

    private var playerCount: Int {
        session.namedPlayers.count
    }

    private var recommended: Int {
        CategoryCatalog.recommendedImposters(for: playerCount)
    }

    private var maxImposters: Int {
        CategoryCatalog.maxImposters(for: playerCount)
    }

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

                ScrollView {
                    VStack(spacing: 14) {
                        SettingsCard(
                            title: l10n.t("gameSettings.mysteryTwist"),
                            subtitle: l10n.t("gameSettings.mysteryTwistDesc")
                        ) {
                            OnOffToggle(isOn: $session.mysteryTwistEnabled)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        SettingsCard(
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

                        SettingsCard(
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

                        SettingsCard(
                            title: l10n.t("gameSettings.imposterHints"),
                            subtitle: l10n.t("gameSettings.imposterHintsDesc")
                        ) {
                            OnOffToggle(isOn: $session.imposterHintsEnabled)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }

            VStack {
                Spacer(minLength: 0)
                PlayBar(
                    playTitle: l10n.t("common.play"),
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
        .onAppear {
            session.imposterCount = recommended
            clampImposterCount()
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
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
