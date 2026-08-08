import SwiftUI


struct GameCardView: View {
    let game: LiveGame

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPortrait: Bool { game.playsInPortrait }

    var body: some View {
        ZStack {
            poster


            if game.answerInput == .touch {
                touchZoneChrome
                touchTargets
            }

            if let flash = game.flash {
                answerFlash(flash)
                    .transition(.opacity)
            }


            pauseButton
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 36)
                .padding(.leading, isPortrait ? 18 : 26)
        }
        .animation(.easeOut(duration: 0.12), value: game.flash)
    }


    private var poster: some View {
        VStack(spacing: 0) {
            sprocketBand


                .overlay(alignment: .trailing) {
                    CueMark(isActive: game.isInFinalTen, diameter: 18)
                        .padding(.trailing, 16)
                }
            stage
            sprocketBand
        }
        .background {
            LinearGradient(
                colors: [AppColors.surfacePoster, AppColors.surfaceTicket],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay {

                HalftoneTexture(dotSize: 0.6, spacing: 3.5, color: .black.opacity(0.45))
                    .opacity(0.16)
            }
            .ignoresSafeArea()
        }
    }

    private var sprocketBand: some View {
        AdvancingSprocketBand(advanceToken: game.currentCard?.k)
    }

    private var stage: some View {
        ZStack {
            VStack(spacing: 14) {
                word
                if game.mode.perWordLimit != nil {
                    wordTimerBar
                }
            }

            hud
                .frame(maxHeight: .infinity, alignment: .top)

            VStack(spacing: 6) {
                if game.didWrapPool {
                    wrapNotice
                }
                if game.showsOrientationReminder {
                    reminder
                }
                if game.answerInput == .tilt, game.showsInputHint {
                    inputHint
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, isPortrait ? 22 : 30)
    }


    private var wordSize: CGFloat {
        if !game.mode.screenVisibleToGuesser { return isPortrait ? 30 : 34 }
        return isPortrait ? 64 : 96
    }

    private var word: some View {
        Text(game.currentCard.map { $0.text(for: l10n.localeCode) } ?? "")
            .textStyle(.gameWord(wordSize))
            .foregroundStyle(AppColors.textOnPoster)
            .multilineTextAlignment(.center)
            .lineLimit(game.mode.screenVisibleToGuesser ? 3 : 1)
            .minimumScaleFactor(game.mode.screenVisibleToGuesser ? (isPortrait ? 48.0 / 64 : 44.0 / 96) : 0.5)
            .opacity(game.flash == nil ? 1 : 0.12)
            .id(game.currentCard?.k)


            .transition(
                reduceMotion
                    ? .opacity
                    : .asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top))
                        .combined(with: .opacity)
            )
            .animation(.easeOut(duration: 0.28), value: game.currentCard?.k)
            .accessibilityLabel(game.currentCard.map { $0.text(for: l10n.localeCode) } ?? "")
    }


    private var wordTimerBar: some View {
        GeometryReader { geometry in
            let fraction = game.wordTimeFraction ?? 1
            Capsule()
                .fill(fraction < 0.34 ? AppColors.stateSkip : AppColors.textOnPoster.opacity(0.55))
                .frame(width: geometry.size.width * fraction)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.linear(duration: 0.1), value: fraction)
        }
        .frame(height: 3)
        .frame(maxWidth: 260)
        .background {
            Capsule().fill(AppColors.textOnPoster.opacity(0.12))
        }
        .opacity(game.flash == nil ? 1 : 0)
        .accessibilityHidden(true)
    }


    private var hud: some View {
        HStack(alignment: .top) {

            Color.clear.frame(width: 36, height: 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(Self.clock(game.remaining))
                    .font(AppFont.display(38, weight: .bold))
                    .appTracking(1)
                    .monospacedDigit()

                    .foregroundStyle(
                        game.isInFinalTen ? AppColors.stateWarning : AppColors.textOnPoster
                    )
                Text(l10n.t("game.hud.remaining"))
                    .font(AppFont.ui(8.5, weight: .semibold, scales: nil))
                    .appTracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textOnPosterMuted)
            }

            Spacer()

            if game.isRecording {
                recordingDot
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text("\(game.score)")
                    .font(AppFont.display(30, weight: .bold))
                    .foregroundStyle(AppColors.stateCorrect)
                Text(l10n.t("game.hud.correct"))
                    .font(AppFont.ui(8.5, weight: .semibold, scales: nil))
                    .appTracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textOnPosterMuted)
            }
        }
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
    }


    private var recordingDot: some View {
        TimelineView(.periodic(from: .now, by: 0.9)) { context in
            let isOn = Int(context.date.timeIntervalSinceReferenceDate / 0.9) % 2 == 0
            HStack(spacing: 5) {
                Circle()
                    .fill(AppColors.stateSkip)
                    .frame(width: 7, height: 7)
                    .opacity(isOn ? 1 : 0.3)
                Text(l10n.t("replay.rec"))
                    .font(AppFont.ui(8.5, weight: .bold, scales: nil))
                    .appTracking(1.6)
                    .foregroundStyle(AppColors.textOnPosterMuted)
            }
            .animation(.easeInOut(duration: 0.35), value: isOn)
        }
        .padding(.top, 7)
        .accessibilityHidden(true)
    }


    private var inputHint: some View {
        HStack(spacing: 74) {
            Label {
                Text(l10n.t("game.hint.skip"))
            } icon: {
                Image(systemName: game.answerInput == .tilt ? "arrow.turn.left.up" : "hand.tap")
            }
            Label {
                Text(l10n.t("game.hint.correct"))
            } icon: {
                Image(systemName: game.answerInput == .tilt ? "arrow.turn.right.up" : "hand.tap")
            }
            .labelStyle(TrailingIconLabelStyle())
        }
        .font(AppFont.ui(9.5, weight: .semibold, scales: nil))
        .appTracking(2.2)
        .textCase(.uppercase)
        .foregroundStyle(AppColors.textOnPosterMuted)
        .accessibilityHidden(true)
    }


    private var wrapNotice: some View {
        Text(l10n.t("game.deckWrapped"))
            .font(AppFont.ui(8.5, weight: .bold, scales: nil))
            .appTracking(2)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textOnPosterMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background {
                Capsule().strokeBorder(AppColors.textOnPosterMuted.opacity(0.35), lineWidth: 1)
            }
    }


    private var reminder: some View {
        Text(l10n.t("game.holdLandscape"))
            .font(AppFont.ui(10, weight: .semibold, scales: nil))


            .foregroundStyle(AppColors.textOnPoster)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background {
                Capsule().fill(AppColors.surfacePoster.opacity(0.9))
            }
            .overlay {
                Capsule().strokeBorder(AppColors.stateSkip, lineWidth: 1.5)
            }
    }


    private var pauseButton: some View {
        Button {
            Haptics.secondaryButton()
            game.lockTriggersForPauseGesture()
            game.pause(reason: .user)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.textOnPoster)
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(AppColors.bgFilmBlack.opacity(0.14))
                        .overlay {
                            Circle().strokeBorder(AppColors.textOnPoster.opacity(0.4), lineWidth: 1)
                        }
                }
                .frame(width: 48, height: 48)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l10n.t("pause.title"))
    }


    private var touchTargets: some View {
        HStack(spacing: 0) {
            Button { game.answer(isCorrect: false) } label: {
                Color.clear.contentShape(Rectangle())
            }
            .accessibilityLabel(l10n.t("game.hint.skip"))

            Button { game.answer(isCorrect: true) } label: {
                Color.clear.contentShape(Rectangle())
            }
            .accessibilityLabel(l10n.t("game.hint.correct"))
        }
        .buttonStyle(.plain)
    }


    private var touchZoneChrome: some View {
        HStack(spacing: 0) {
            touchZoneSide(
                title: l10n.t("game.hint.skip"),
                color: AppColors.stateSkip,
                edge: .leading
            )
            Rectangle()
                .fill(AppColors.textOnPoster.opacity(0.12))
                .frame(width: 1)
                .padding(.vertical, 28)
            touchZoneSide(
                title: l10n.t("game.hint.correct"),
                color: AppColors.stateCorrect,
                edge: .trailing
            )
        }
        .allowsHitTesting(false)
        .opacity(game.flash == nil ? 1 : 0)
        .accessibilityHidden(true)
    }

    private func touchZoneSide(title: String, color: Color, edge: HorizontalEdge) -> some View {
        let isLeading = edge == .leading
        return ZStack(alignment: isLeading ? .bottomLeading : .bottomTrailing) {
            LinearGradient(
                colors: [
                    color.opacity(0.16),
                    color.opacity(0.05),
                    .clear,
                ],
                startPoint: isLeading ? .leading : .trailing,
                endPoint: isLeading ? .trailing : .leading
            )

            VStack(alignment: isLeading ? .leading : .trailing, spacing: 5) {
                Image(systemName: isLeading ? "chevron.left" : "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(AppFont.display(18, weight: .bold))
                    .appTracking(2)
                    .textCase(.uppercase)
            }
            .foregroundStyle(color.opacity(0.95))
            .padding(.horizontal, isPortrait ? 14 : 18)

            .padding(.bottom, isPortrait ? 56 : 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    private func answerFlash(_ flash: LiveGame.Flash) -> some View {
        ZStack {
            (flash == .correct ? AppColors.stateCorrect : AppColors.stateSkip)
                .overlay {
                    HalftoneTexture(dotSize: 0.6, spacing: 3.5, color: .black.opacity(0.5))
                        .opacity(0.2)
                }
                .ignoresSafeArea()

            HStack(spacing: 18) {
                Text(l10n.t(flash == .correct ? "game.stamp.correct" : "game.stamp.skip"))
                    .font(AppFont.display(60, weight: .bold))
                    .appTracking(5)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.surfacePoster)

                Image(systemName: flash == .correct ? "checkmark" : "xmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(AppColors.surfacePoster)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 14)
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(AppColors.surfacePoster, lineWidth: 5)
            }
            .rotationEffect(.degrees(-7))
        }
        .accessibilityHidden(true)
    }

    private static func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}


private struct AdvancingSprocketBand: View {

    var advanceToken: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shift: CGFloat = 0

    private let holeSize: CGFloat = 11
    private let spacing: CGFloat = 14
    private var period: CGFloat { holeSize + spacing }

    var body: some View {
        GeometryReader { geometry in
            SprocketStrip(
                axis: .horizontal,
                holeSize: holeSize,
                spacing: spacing,
                holeColor: AppColors.surfacePoster.opacity(0.9)
            )


            .frame(width: geometry.size.width + period * 2, height: geometry.size.height)
            .offset(x: -period + shift)
        }
        .frame(height: 26)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0x0B0907))
        .clipped()
        .accessibilityHidden(true)
        .onChange(of: advanceToken) { _, _ in advance() }
    }

    private func advance() {


        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.22)) { shift = -period }


        Task {
            try? await Task.sleep(for: .milliseconds(230))
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { shift = 0 }
        }
    }
}


private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}
