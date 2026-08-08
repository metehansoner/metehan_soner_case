import SwiftUI


struct SlateView: View {

    let scene: Int


    let take: Int
    let deckTitle: String
    let modeTitle: String

    let isFull: Bool
    var onFinish: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion


    @State private var isBarOpen = true
    @State private var flash = false
    @State private var hasExited = false
    @State private var showsTitleCard = false


    private var barFall: TimeInterval { isFull ? 0.55 : 0.18 }
    private var holdAfterClack: TimeInterval { isFull ? 0.4 : 0.07 }
    private var exitDuration: TimeInterval { isFull ? 0.3 : 0.1 }

    private let titleCardDuration: TimeInterval = 1.4
    private let titleCardFade: TimeInterval = 0.35

    var body: some View {
        ZStack {
            AppColors.bgFilmBlack.ignoresSafeArea()

            if showsTitleCard {
                titleCard
                    .transition(.opacity)
            } else {
                slate


                    .offset(x: hasExited ? -exitOffset : 0)
                    .opacity(hasExited ? 0 : 1)
            }


            if flash {
                Color.white.ignoresSafeArea()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: finishNow)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
        .accessibilityAddTraits(.isButton)
        .task { await run() }
    }


    private var slate: some View {
        VStack(spacing: 0) {
            clapstick
            body(of: rows)
        }
        .frame(maxWidth: 460)
        .padding(.horizontal, 34)
        .rotationEffect(.degrees(-2))
        .shadow(color: .black.opacity(0.6), radius: 24, y: 12)
    }


    private var clapstick: some View {
        DiagonalStripes()
            .frame(height: 34)
            .frame(maxWidth: .infinity)
            .background(AppColors.bgFilmBlack)
            .overlay {
                Rectangle().strokeBorder(AppColors.textOnPoster.opacity(0.35), lineWidth: 1)
            }

            .rotationEffect(.degrees(isBarOpen ? -22 : 0), anchor: .bottomLeading)
    }

    private func body(of content: some View) -> some View {
        content
            .padding(.horizontal, 22)
            .padding(.vertical, isFull ? 18 : 12)
            .frame(maxWidth: .infinity)
            .background {
                LinearGradient(
                    colors: [Color(hex: 0x1C1815), Color(hex: 0x0E0C0A)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay {
                Rectangle().strokeBorder(AppColors.textOnPoster.opacity(0.3), lineWidth: 1)
            }
    }

    @ViewBuilder
    private var rows: some View {
        VStack(alignment: .leading, spacing: isFull ? 9 : 0) {
            row(label: l10n.t("slate.scene"), value: number(scene))
            if isFull {
                row(label: l10n.t("slate.take"), value: number(take))
                row(label: l10n.t("slate.deck"), value: deckTitle)
                row(label: l10n.t("slate.mode"), value: modeTitle)
            }
        }
    }

    private func row(label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Text(label)
                .font(AppFont.ui(10, weight: .semibold, scales: nil))
                .appTracking(2.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textCream.opacity(0.6))


                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(width: 82, alignment: .leading)

            Text(value)
                .font(AppFont.display(22, weight: .bold))
                .appTracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textCream)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 0)
        }
    }


    private var titleCard: some View {
        VStack(spacing: 12) {
            Text(l10n.t("slate.presents"))
                .font(AppFont.ui(11, weight: .semibold, scales: nil))
                .appTracking(6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.accentGold)

            Text(deckTitle)
                .font(AppFont.display(46, weight: .bold))
                .appTracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textCream)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 40)
    }


    private func run() async {
        guard !reduceMotion else {


            onFinish()
            return
        }

        withAnimation(.easeIn(duration: barFall)) { isBarOpen = false }
        try? await Task.sleep(for: .seconds(barFall))
        guard !Task.isCancelled else { return }

        clack()
        try? await Task.sleep(for: .seconds(holdAfterClack))
        guard !Task.isCancelled else { return }

        withAnimation(.easeIn(duration: exitDuration)) { hasExited = true }
        try? await Task.sleep(for: .seconds(exitDuration))
        guard !Task.isCancelled else { return }

        if isFull {
            withAnimation(.easeOut(duration: titleCardFade)) { showsTitleCard = true }
            try? await Task.sleep(for: .seconds(titleCardDuration))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: titleCardFade)) { showsTitleCard = false }
            try? await Task.sleep(for: .seconds(titleCardFade))
            guard !Task.isCancelled else { return }
        }
        onFinish()
    }

    private func clack() {
        Haptics.clapper()
        SoundService.clapper()

        flash = true
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            withAnimation(.easeOut(duration: 0.12)) { flash = false }
        }
    }


    private func finishNow() {
        guard !hasExited || showsTitleCard else { return }
        onFinish()
    }

    private var exitOffset: CGFloat { 700 }

    private func number(_ value: Int) -> String {
        String(format: "%02d", value)
    }


    private var spokenSummary: String {
        isFull
            ? "\(l10n.t("slate.scene")) \(scene), \(deckTitle), \(modeTitle)"
            : "\(l10n.t("slate.scene")) \(scene)"
    }
}


private struct DiagonalStripes: View {
    private let stripeWidth: CGFloat = 22

    var body: some View {
        Canvas { context, size in
            let slant = size.height
            var x = -slant
            var isLight = true
            while x < size.width + slant {
                if isLight {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: size.height))
                    path.addLine(to: CGPoint(x: x + slant, y: 0))
                    path.addLine(to: CGPoint(x: x + slant + stripeWidth, y: 0))
                    path.addLine(to: CGPoint(x: x + stripeWidth, y: size.height))
                    path.closeSubpath()
                    context.fill(path, with: .color(AppColors.surfacePoster))
                }
                x += stripeWidth
                isLight.toggle()
            }
        }
        .allowsHitTesting(false)
    }
}
