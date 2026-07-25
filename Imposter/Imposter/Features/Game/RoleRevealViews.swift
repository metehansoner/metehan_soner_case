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
                    .frame(maxHeight: 400)
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
        // Light accents need dark copy: mint, yellow, neon green, peach, turquoise
        [4, 5, 9, 12, 14].contains(player.avatarIndex)
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

/// Continuous elastic column: cover then black reveal. Release snaps back.
struct RoleRevealView: View {
    let player: AssignedPlayer
    let hint: String?
    var isLastPlayer: Bool = false
    var nextPlayerName: String? = nil
    var onDone: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @State private var scrollUp: CGFloat = 0
    @State private var hintBobbing = false
    /// Continue only after the user has peeked the secret at least once.
    @State private var hasPeeked = false

    private let revealFraction: CGFloat = 0.26

    var body: some View {
        GeometryReader { geo in
            let pageH = geo.size.height
            let revealH = pageH * revealFraction
            let maxScroll = revealH
            let peekThreshold = revealH * 0.35

            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    coverPage(height: pageH)
                        .frame(width: geo.size.width, height: pageH)

                    revealPage(height: revealH)
                        .frame(width: geo.size.width, height: revealH)
                }
                .offset(y: -scrollUp)
            }
            .frame(width: geo.size.width, height: pageH, alignment: .top)
            .clipped()
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        let up = max(0, -value.translation.height)
                        if up <= maxScroll {
                            scrollUp = up
                        } else {
                            let over = up - maxScroll
                            scrollUp = maxScroll + over * 0.18
                        }
                        if scrollUp >= peekThreshold, !hasPeeked {
                            hasPeeked = true
                            Haptics.selection()
                        }
                    }
                    .onEnded { _ in
                        Haptics.light()
                        withAnimation(.interpolatingSpring(stiffness: 240, damping: 24)) {
                            scrollUp = 0
                        }
                    }
            )
        }
        .ignoresSafeArea()
        .onAppear { hintBobbing = true }
    }

    private func coverPage(height: CGFloat) -> some View {
        ZStack {
            player.accent.ignoresSafeArea()

            VStack(spacing: 0) {
                Text(player.name)
                    .font(AppFont.display(32, weight: .black))
                    .foregroundStyle(needsDarkText ? AppColors.textOnLight : .white)
                    .padding(.top, 76)

                Spacer(minLength: 4)

                Image(player.avatarImageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: height * (hasPeeked ? 0.50 : 0.56))
                    .padding(.horizontal, 4)
                    .shadow(color: .black.opacity(0.22), radius: 14, y: 8)

                Spacer(minLength: 8)

                if hasPeeked {
                    // After peek: hand phone to next player (or start if last).
                    if !isLastPlayer {
                        Text(l10n.t("pass.givePhone", ["name": nextPlayerName ?? ""]))
                            .font(AppFont.display(28, weight: .black))
                            .foregroundStyle(needsDarkText ? AppColors.textOnLight : .white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.bottom, 14)
                            .transition(.opacity)
                    }

                    Button {
                        Haptics.light()
                        onDone()
                    } label: {
                        Text(isLastPlayer ? l10n.t("pass.startGame") : l10n.t("common.continue"))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Only swipe hint — no "give phone" yet.
                    VStack(spacing: 8) {
                        Text(l10n.t("pass.swipeHint"))
                            .font(AppFont.ui(17, weight: .bold))
                            .foregroundStyle(needsDarkText ? AppColors.textOnLight : .white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Image(systemName: "chevron.up")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(needsDarkText ? AppColors.textOnLight : .white)
                    }
                    .offset(y: hintBobbing ? -7 : 5)
                    .animation(
                        .easeInOut(duration: 0.85).repeatForever(autoreverses: true),
                        value: hintBobbing
                    )
                    .padding(.bottom, 40)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: hasPeeked)
        }
    }

    private func revealPage(height: CGFloat) -> some View {
        VStack(spacing: 10) {
            Spacer(minLength: 12)

            switch player.reveal {
            case .impostor:
                Image(systemName: "theatermasks.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.stateDanger)
                Text(l10n.t("pass.imposter"))
                    .font(AppFont.display(28, weight: .black))
                    .foregroundStyle(AppColors.stateDanger)
                if let hint {
                    Text(l10n.t("pass.hint", ["hint": hint]))
                        .font(AppFont.display(18, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            case .word(let word):
                Image(systemName: "person.3.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AppColors.stateSuccess)
                Text(word)
                    .font(AppFont.display(28, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Spacer(minLength: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var needsDarkText: Bool {
        // Light accents need dark copy: mint, yellow, neon green, peach, turquoise
        [4, 5, 9, 12, 14].contains(player.avatarIndex)
    }
}

struct ReadyToStartView: View {
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
