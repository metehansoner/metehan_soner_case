import SwiftUI

struct AddPlayersView: View {
    @Bindable var session: GameSession
    var onOpenHome: () -> Void
    var onContinue: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @FocusState private var focusedIndex: Int?
    @State private var showSettings = false

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 12) {
                        modeChip

                        ForEach(Array(session.players.enumerated()), id: \.element.id) { index, _ in
                            playerRow(index: index)
                        }

                        if session.players.count < PlayerLimits.maxCount {
                            addPlayerButton
                        }

                        Text(l10n.t("players.minHint"))
                            .font(AppFont.ui(13))
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.top, 4)

                        if session.players.count >= PlayerLimits.maxCount {
                            Text(l10n.t("players.maxHint"))
                                .font(AppFont.ui(13))
                                .foregroundStyle(AppColors.accentYellow)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }

                VStack(spacing: 0) {
                    Button {
                        guard session.canContinuePlayers else { return }
                        onContinue()
                    } label: {
                        Text(l10n.t("common.continue"))
                    }
                    .buttonStyle(PrimaryButtonStyle(enabled: session.canContinuePlayers))
                    .disabled(!session.canContinuePlayers)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .padding(.top, 12)
                    .background(
                        LinearGradient(
                            colors: [AppColors.bgPrimary.opacity(0), AppColors.bgPrimary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }

    private var modeChip: some View {
        let title = session.selectedMode == .classic
            ? l10n.t("home.classicTitle")
            : l10n.t("home.drawingTitle")

        return Button(action: onOpenHome) {
            HStack(spacing: 8) {
                Image(systemName: session.selectedMode == .classic ? "theatermasks.fill" : "pencil.tip")
                Text(title)
                    .font(AppFont.ui(14, weight: .bold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(AppColors.surfaceCardElevated)
                    .overlay(Capsule().stroke(AppColors.accentCyan.opacity(0.35), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        HStack {
            Button(action: onOpenHome) {
                Image(systemName: "house.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColors.surfaceCardElevated))
            }

            Spacer()

            ScreenTitle(text: l10n.t("players.title"))

            Spacer()

            Button {
                Haptics.light()
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColors.surfaceCardElevated))
            }
        }
    }

    private func playerRow(index: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(AppFont.ui(14, weight: .bold))
                .foregroundStyle(AppColors.textOnLight)
                .frame(width: 28, height: 28)
                .background(Circle().fill(AppColors.accentYellow))

            TextField(
                "",
                text: bindingName(at: index),
                prompt: Text(l10n.t("players.placeholder", ["n": "\(index + 1)"]))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.7))
            )
            .font(AppFont.ui(16, weight: .semibold))
            .foregroundStyle(AppColors.textPrimary)
            .focused($focusedIndex, equals: index)
            .submitLabel(index == session.players.count - 1 ? .done : .next)
            .onSubmit {
                if index < session.players.count - 1 {
                    focusedIndex = index + 1
                } else {
                    focusedIndex = nil
                }
            }

            if session.players.count > PlayerLimits.minCount {
                Button {
                    session.removePlayer(at: index)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(AppColors.stateDanger.opacity(0.9))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(AppColors.surfaceCard)
        )
    }

    private var addPlayerButton: some View {
        Button {
            session.addPlayer()
            focusedIndex = session.players.count - 1
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text(l10n.t("players.add"))
                    .font(AppFont.ui(16, weight: .bold))
            }
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.7))
            )
        }
    }

    private func bindingName(at index: Int) -> Binding<String> {
        Binding(
            get: { session.players[index].name },
            set: { session.players[index].name = $0 }
        )
    }
}
