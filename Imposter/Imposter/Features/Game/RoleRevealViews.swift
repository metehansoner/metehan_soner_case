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

/// Signature reveal: a sealed card that only opens while you hold your finger down.
/// Release re-seals it instantly — nobody peeks over your shoulder.
struct RoleRevealView: View {
    let player: AssignedPlayer
    let hint: String?
    var isLastPlayer: Bool = false
    var nextPlayerName: String? = nil
    var onDone: () -> Void

    @Bindable private var l10n = LocalizationManager.shared

    @State private var isHolding = false
    @State private var fill: CGFloat = 0
    @State private var isOpen = false
    @State private var hasOpenedOnce = false
    @State private var revealWork: DispatchWorkItem?
    @State private var sealPulse = false

    private let holdDuration: Double = 0.5

    var body: some View {
        ZStack {
            backdrop

            GeometryReader { geo in
                let cardHeight = min(max(geo.size.height * 0.48, 280), 400)

                VStack(spacing: 0) {
                    Text(l10n.t("reveal.turnOf", ["name": player.name]))
                        .font(AppFont.display(34, weight: .black))
                        .foregroundStyle(accentText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .frame(maxWidth: .infinity)

                    Spacer(minLength: 8)

                    sealCard
                        .frame(height: cardHeight)
                        .padding(.horizontal, 22)

                    Spacer(minLength: 8)

                    footer
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 112, alignment: .bottom)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear { sealPulse = true }
        .onDisappear { revealWork?.cancel() }
    }

    // MARK: Backdrop

    private var backdrop: some View {
        player.accent.ignoresSafeArea()
    }

    // MARK: Seal card

    private var sealCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(isOpen ? 0.28 : 0.16), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.35), radius: 22, y: 14)

            sealedFace.opacity(isOpen ? 0 : 1)
            openFace.opacity(isOpen ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .scaleEffect(isHolding ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHolding)
        .gesture(holdGesture)
    }

    private var sealedFace: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 132, height: 132)
                Circle()
                    .stroke(Color.white.opacity(0.22), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: fill)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(sealPulse ? 1.06 : 0.94)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: sealPulse)
            }
            .frame(width: 132, height: 132)

            VStack(spacing: 6) {
                Text(l10n.t("reveal.holdTitle"))
                    .font(AppFont.display(21, weight: .black))
                    .foregroundStyle(.white)
                Text(l10n.t("reveal.holdHint"))
                    .font(AppFont.ui(14, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    private var openFace: some View {
        VStack(spacing: 14) {
            switch player.reveal {
            case .impostor:
                Image(systemName: "theatermasks.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppColors.stateDanger)
                Text(l10n.t("reveal.imposterTag"))
                    .font(AppFont.display(30, weight: .black))
                    .foregroundStyle(AppColors.stateDanger)
                    .multilineTextAlignment(.center)
                if let hint {
                    Text(l10n.t("reveal.hint", ["hint": hint]))
                        .font(AppFont.ui(15, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                } else {
                    Text(l10n.t("reveal.imposterBody"))
                        .font(AppFont.ui(15, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            case .word(let word):
                Text(l10n.t("reveal.crewLabel"))
                    .font(AppFont.ui(14, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .textCase(.uppercase)
                Text(word)
                    .font(AppFont.display(38, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 20)
                Text(l10n.t("reveal.crewBody"))
                    .font(AppFont.ui(14, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Footer

    @ViewBuilder
    private var footer: some View {
        if hasOpenedOnce {
            VStack(spacing: 10) {
                if !isLastPlayer, let nextPlayerName {
                    Text(l10n.t("reveal.passNext", ["name": nextPlayerName]))
                        .font(AppFont.display(18, weight: .black))
                        .foregroundStyle(accentText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                Button {
                    Haptics.light()
                    onDone()
                } label: {
                    Text(isLastPlayer ? l10n.t("reveal.startGame") : l10n.t("common.continue"))
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .transition(.opacity)
        } else {
            Label(l10n.t("reveal.releaseHint"), systemImage: "eye.slash.fill")
                .font(AppFont.ui(14, weight: .bold))
                .foregroundStyle(accentText.opacity(0.85))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Hold gesture

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isHolding else { return }
                startHold()
            }
            .onEnded { _ in
                endHold()
            }
    }

    private func startHold() {
        isHolding = true
        Haptics.selection()
        withAnimation(.easeInOut(duration: holdDuration)) { fill = 1 }
        let work = DispatchWorkItem {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isOpen = true
                hasOpenedOnce = true
            }
            Haptics.success()
        }
        revealWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration, execute: work)
    }

    private func endHold() {
        isHolding = false
        revealWork?.cancel()
        revealWork = nil
        withAnimation(.easeOut(duration: 0.2)) {
            fill = 0
            isOpen = false
        }
        Haptics.light()
    }

    private var accentText: Color {
        needsDarkText ? AppColors.textOnLight : .white
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
