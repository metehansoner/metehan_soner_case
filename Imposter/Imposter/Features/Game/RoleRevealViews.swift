import SwiftUI

struct PassPhoneView: View {
    let player: AssignedPlayer
    var onContinue: () -> Void
    @Bindable private var l10n = LocalizationManager.shared

    var body: some View {
        ZStack {
            player.accent.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(player.avatarImageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxHeight: 340)
                    .shadow(color: .black.opacity(0.25), radius: 18, y: 10)

                Text(l10n.t("pass.givePhone", ["name": player.name]))
                    .font(AppFont.display(28, weight: .bold))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer()

                Button(action: onContinue) {
                    Text(l10n.t("common.continue"))
                }
                .buttonStyle(DarkCapsuleStyle(textOnLight: needsDarkText))
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    private var needsDarkText: Bool {
        // Light accents need dark text
        [5, 11, 14].contains(player.avatarIndex) // yellow, cyan, light aqua approx indices 5,11,14
            || player.avatarIndex == 5 || player.avatarIndex == 11 || player.avatarIndex == 14
    }

    private var textColor: Color {
        needsDarkText ? AppColors.textOnLight : .white
    }
}

struct DarkCapsuleStyle: ButtonStyle {
    var textOnLight: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.ui(17, weight: .bold))
            .foregroundStyle(textOnLight ? AppColors.textOnLight : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule().fill(textOnLight ? Color.white.opacity(0.92) : Color.black.opacity(0.85))
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct RoleRevealView: View {
    let player: AssignedPlayer
    let hint: String?
    var onDone: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @State private var revealed = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            player.accent.ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    Text(player.name)
                        .font(AppFont.display(30, weight: .bold))
                        .foregroundStyle(needsDarkText ? AppColors.textOnLight : .white)
                    Spacer()
                }
                .padding(.top, 16)

                Image(player.avatarImageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxHeight: revealed ? 200 : 300)
                    .padding(.horizontal, 24)

                if !revealed {
                    VStack(spacing: 8) {
                        Text(l10n.t("pass.swipeHint"))
                            .font(AppFont.ui(16, weight: .bold))
                            .foregroundStyle(needsDarkText ? AppColors.textOnLight : .white)
                            .multilineTextAlignment(.center)
                        Image(systemName: "chevron.up")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(needsDarkText ? AppColors.textOnLight : .white)
                    }
                    .padding(.bottom, 40)
                    .offset(y: dragOffset)
                }

                Spacer(minLength: 0)
            }

            if revealed {
                revealPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard !revealed else { return }
                    dragOffset = min(0, value.translation.height)
                }
                .onEnded { value in
                    guard !revealed else { return }
                    if value.translation.height < -80 {
                        Haptics.medium()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            revealed = true
                        }
                    }
                    dragOffset = 0
                }
        )
        .onTapGesture(count: 2) {
            guard !revealed else { return }
            Haptics.medium()
            withAnimation { revealed = true }
        }
    }

    private var revealPanel: some View {
        VStack(spacing: 14) {
            switch player.reveal {
            case .impostor:
                Image(systemName: "theatermasks.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.stateDanger)
                Text(l10n.t("pass.imposter"))
                    .font(AppFont.display(34, weight: .bold))
                    .foregroundStyle(AppColors.stateDanger)
                if let hint {
                    Text(l10n.t("pass.hint", ["hint": hint]))
                        .font(AppFont.ui(16, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
            case .blank:
                Image(systemName: "questionmark.square.dashed")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.accentYellow)
                Text(l10n.t("pass.blank"))
                    .font(AppFont.display(34, weight: .bold))
                    .foregroundStyle(AppColors.accentYellow)
                Text(l10n.t("pass.blankBody"))
                    .font(AppFont.ui(15))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            case .word(let word):
                Image(systemName: "person.3.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.accentCyan)
                Text(word)
                    .font(AppFont.display(32, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }

            Button {
                Haptics.light()
                onDone()
            } label: {
                Text(l10n.t("common.continue"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28
            )
            .fill(Color.black)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var needsDarkText: Bool {
        [5, 11, 14].contains(player.avatarIndex)
    }
}

struct ReadyToStartView: View {
    var mysteryTwistEnabled: Bool = false
    var onStart: () -> Void
    @Bindable private var l10n = LocalizationManager.shared

    var body: some View {
        ZStack {
            OceanBackground()
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColors.accentCyan)
                Text(l10n.t("pass.readyTitle"))
                    .font(AppFont.display(30, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                if mysteryTwistEnabled {
                    Text(l10n.t("twist.activeBadge"))
                        .font(AppFont.ui(14, weight: .bold))
                        .foregroundStyle(AppColors.textOnLight)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(AppColors.accentYellow))
                }

                Spacer()
                Button(action: onStart) {
                    Text(l10n.t("pass.startGame"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }
}
