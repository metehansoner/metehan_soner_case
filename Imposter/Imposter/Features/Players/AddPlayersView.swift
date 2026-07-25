import SwiftUI

enum AddPlayersPresentation {
    /// Cold start / app relaunch — continue goes to Home.
    case launch
    /// Opened from Home profile — edit names, then return.
    case profile
}

struct AddPlayersView: View {
    @Bindable var session: GameSession
    var presentation: AddPlayersPresentation = .launch
    var onContinue: () -> Void
    var onClose: (() -> Void)? = nil

    @Bindable private var l10n = LocalizationManager.shared
    @FocusState private var focusedPlayerID: UUID?
    @State private var showSettings = false

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(Array(session.players.enumerated()), id: \.element.id) { index, player in
                            playerRow(player: player, displayIndex: index)
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
                .scrollIndicators(.hidden)

                VStack(spacing: 0) {
                    Button {
                        guard session.canContinuePlayers else { return }
                        onContinue()
                    } label: {
                        Text(presentation == .profile ? l10n.t("common.done") : l10n.t("common.continue"))
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

    private var header: some View {
        HStack {
            if presentation == .profile {
                HeaderCircleIconButton(systemName: "xmark") {
                    onClose?()
                }
            } else {
                Color.clear.frame(width: 42, height: 42)
            }

            Spacer()

            ScreenTitle(
                text: presentation == .profile
                    ? l10n.t("players.profileTitle")
                    : l10n.t("players.title")
            )

            Spacer()

            HeaderCircleIconButton(systemName: "gearshape.fill") {
                Haptics.light()
                showSettings = true
            }
        }
    }

    private func playerRow(player: Player, displayIndex: Int) -> some View {
        let isFocused = focusedPlayerID == player.id

        return HStack(spacing: 14) {
            Text("\(displayIndex + 1)")
                .font(AppFont.display(17, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isFocused ? AppColors.accentYellow : AppColors.surfaceCard)
                        .overlay(
                            Circle()
                                .stroke(
                                    isFocused ? AppColors.accentYellow : AppColors.accentCyan.opacity(0.35),
                                    lineWidth: 1.5
                                )
                        )
                )

            ZStack(alignment: .leading) {
                if player.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(l10n.t("players.placeholder", ["n": "\(displayIndex + 1)"]))
                        .font(AppFont.display(18, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.55))
                        .lineLimit(1)
                        .allowsHitTesting(false)
                }

                TextField("", text: bindingName(for: player.id))
                    .font(AppFont.display(18, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .tint(AppColors.accentCyan)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedPlayerID, equals: player.id)
                    .submitLabel(displayIndex == session.players.count - 1 ? .done : .next)
                    .onSubmit {
                        if displayIndex < session.players.count - 1 {
                            focusedPlayerID = session.players[displayIndex + 1].id
                        } else {
                            focusedPlayerID = nil
                        }
                    }
            }

            if session.players.count > PlayerLimits.minCount {
                Button {
                    if focusedPlayerID == player.id {
                        focusedPlayerID = nil
                    }
                    session.removePlayer(id: player.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.55))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surfaceCardElevated.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isFocused ? AppColors.accentCyan.opacity(0.7) : AppColors.accentCyan.opacity(0.18),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isFocused)
    }

    private var addPlayerButton: some View {
        Button {
            session.addPlayer()
            focusedPlayerID = session.players.last?.id
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

    private func bindingName(for id: UUID) -> Binding<String> {
        Binding(
            get: { session.players.first(where: { $0.id == id })?.name ?? "" },
            set: { newValue in
                guard let index = session.players.firstIndex(where: { $0.id == id }) else { return }
                session.players[index].name = newValue
            }
        )
    }
}
