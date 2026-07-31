import SwiftUI

enum AddPlayersPresentation {
    case launch
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

    private var namedCount: Int { session.namedPlayers.count }

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(session.players.enumerated()), id: \.element.id) { index, player in
                            playerRow(player: player, displayIndex: index)
                        }

                        if session.players.count < PlayerLimits.maxCount {
                            addPlayerButton
                        }

                        if namedCount < PlayerLimits.minCount {
                            Text(l10n.t("players.minHint"))
                                .font(AppFont.ui(13, weight: .bold))
                                .foregroundStyle(AppColors.textSecondary)
                                .padding(.top, 2)
                        } else if session.players.count >= PlayerLimits.maxCount {
                            Text(l10n.t("players.maxHint"))
                                .font(AppFont.ui(13, weight: .bold))
                                .foregroundStyle(AppColors.accentYellow)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)

                Button {
                    guard session.canContinuePlayers else { return }
                    Haptics.medium()
                    onContinue()
                } label: {
                    Text(
                        presentation == .profile
                            ? l10n.t("common.done")
                            : l10n.t("players.enterLobby")
                    )
                }
                .buttonStyle(PrimaryButtonStyle(enabled: session.canContinuePlayers))
                .disabled(!session.canContinuePlayers)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        colors: [AppColors.bgPrimary.opacity(0), AppColors.bgPrimary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
                )
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            if presentation == .profile {
                HeaderCircleIconButton(systemName: "xmark") {
                    onClose?()
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer(minLength: 4)
            ScreenTitle(text: l10n.t("players.screenTitle"))
            Spacer(minLength: 4)

            HeaderCircleIconButton(systemName: "gearshape.fill") {
                Haptics.light()
                showSettings = true
            }
        }
    }

    private func playerRow(player: Player, displayIndex: Int) -> some View {
        let isFocused = focusedPlayerID == player.id
        let accent = AssignedPlayer.accents[displayIndex % AssignedPlayer.accents.count]
        let avatar = String(format: "player_%02d", (displayIndex % 15) + 1)
        let canRemove = session.players.count > PlayerLimits.minCount

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent)
                    .frame(width: 42, height: 42)
                Image(avatar)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(3)
                    .frame(width: 42, height: 42)
            }
            .overlay(
                Circle()
                    .stroke(
                        isFocused ? AppColors.accentCyan : Color.white.opacity(0.2),
                        lineWidth: isFocused ? 2 : 1
                    )
            )

            ZStack(alignment: .leading) {
                if player.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(l10n.t("players.placeholder", ["n": "\(displayIndex + 1)"]))
                        .font(AppFont.display(18, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.5))
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

            if canRemove {
                Button {
                    Haptics.light()
                    if focusedPlayerID == player.id { focusedPlayerID = nil }
                    session.removePlayer(id: player.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.surfaceCard.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            isFocused ? AppColors.accentCyan.opacity(0.65) : accent.opacity(0.28),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    private var addPlayerButton: some View {
        Button {
            Haptics.selection()
            session.addPlayer()
            focusedPlayerID = session.players.last?.id
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .black))
                Text(l10n.t("players.add"))
                    .font(AppFont.display(16, weight: .black))
            }
            .foregroundStyle(AppColors.accentCyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.surfaceCard.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppColors.accentCyan.opacity(0.35), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
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
