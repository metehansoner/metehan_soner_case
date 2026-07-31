import SwiftUI
import Combine

struct ClueRoundView: View {
    @Bindable var live: LiveGame
    let player: AssignedPlayer
    let position: Int
    var onNext: () -> Void
    var onExit: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @State private var showExitConfirm = false
    @State private var appear = false
    @State private var timeLeft = RapidRoundLimits.secondsPerTurn
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isLast: Bool { position == live.players.count - 1 }
    private var isRapid: Bool { live.mode.isRapid }

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                progressDots
                    .padding(.top, 10)

                Spacer(minLength: 12)

                avatarStage

                Text(l10n.t("clue.turnOf"))
                    .font(AppFont.ui(15, weight: .bold))
                    .foregroundStyle(AppColors.accentCyan)
                    .textCase(.uppercase)
                    .padding(.top, 20)

                Text(player.name)
                    .font(AppFont.display(38, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)

                Text(l10n.t(live.mode.clueInstructionKey))
                    .font(AppFont.ui(16, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)

                if isRapid {
                    rapidCountdown
                        .padding(.top, 14)
                }

                Spacer(minLength: 12)

                Button {
                    Haptics.medium()
                    onNext()
                } label: {
                    Text(isLast ? l10n.t("clue.toDiscussion") : l10n.t("clue.given"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 14)

            if showExitConfirm {
                ExitGameConfirmOverlay(
                    onCancel: { showExitConfirm = false },
                    onConfirm: {
                        showExitConfirm = false
                        onExit()
                    }
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { appear = true }
        }
        .onReceive(ticker) { _ in
            guard isRapid, !showExitConfirm else { return }
            if timeLeft > 0 {
                timeLeft -= 1
                if timeLeft <= 3 { Haptics.light() }
            }
            if timeLeft == 0 {
                Haptics.heavy()
                onNext()
            }
        }
    }

    private var rapidCountdown: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 14, weight: .bold))
            Text("\(timeLeft)")
                .font(AppFont.display(22, weight: .black))
                .monospacedDigit()
        }
        .foregroundStyle(timeLeft <= 3 ? AppColors.stateDanger : AppColors.accentYellow)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppColors.surfaceCardElevated)
                .overlay(
                    Capsule().stroke(
                        (timeLeft <= 3 ? AppColors.stateDanger : AppColors.accentYellow).opacity(0.5),
                        lineWidth: 1.5
                    )
                )
        )
        .scaleEffect(timeLeft <= 3 ? 1.08 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: timeLeft)
    }

    private var header: some View {
        HStack {
            Button {
                Haptics.light()
                showExitConfirm = true
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(l10n.t("clue.title"))
                .font(AppFont.display(20, weight: .black))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<live.players.count, id: \.self) { i in
                Capsule()
                    .fill(dotColor(i))
                    .frame(width: i == position ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: position)
            }
        }
    }

    private func dotColor(_ i: Int) -> Color {
        if i < position { return AppColors.accentCyan.opacity(0.9) }
        if i == position { return AppColors.accentYellow }
        return AppColors.textSecondary.opacity(0.3)
    }

    private var avatarStage: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [player.accent.opacity(0.55), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 170
                    )
                )
                .frame(width: 320, height: 320)

            Image(player.avatarImageName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 210, height: 210)
                .shadow(color: .black.opacity(0.3), radius: 18, y: 12)
                .scaleEffect(appear ? 1 : 0.9)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appear)
        }
        .frame(height: 260)
    }
}
