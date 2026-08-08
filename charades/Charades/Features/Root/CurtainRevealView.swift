import SwiftUI


struct CurtainRevealView: View {
    var onFinish: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isOpen = false
    @State private var showsStage = false

    @State private var lampLevel: Double = 0


    private let total: TimeInterval = 2.2
    private let plaqueSide: CGFloat = 168

    var body: some View {
        GeometryReader { geometry in
            ZStack {

                AppColors.screenBackground

                spotCone
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(lampLevel)

                plaque
                    .opacity(showsStage ? 1 : 0)

                wordmark
                    .frame(maxHeight: .infinity, alignment: .center)
                    .offset(y: plaqueSide / 2 + 54)
                    .opacity(showsStage ? 1 : 0)


                panel(.leading, size: geometry.size)
                panel(.trailing, size: geometry.size)


                loader
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 56)
                    .opacity(showsStage ? 1 : 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()

        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(l10n.t("app.name"))
        .task { await run() }
    }


    private var spotCone: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width * 0.64, 280)
            let height = geometry.size.height * 0.52
            LinearGradient(
                colors: [
                    AppColors.accentAmber.opacity(0.30),
                    AppColors.bgSpotlight.opacity(0.14),
                    .clear,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: width, height: height)
            .clipShape(SpotConeShape())
            .blur(radius: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: -geometry.size.height * 0.06)
        }
        .allowsHitTesting(false)
    }


    private func panel(_ edge: HorizontalEdge, size: CGSize) -> some View {
        let isLeading = edge == .leading
        return Image("launch_curtain")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
            .clipped()
            .mask(alignment: isLeading ? .leading : .trailing) {
                Rectangle().frame(width: size.width / 2)
            }
            .scaleEffect(x: isOpen ? 0.6 : 1, anchor: isLeading ? .leading : .trailing)
            .offset(x: isOpen ? (isLeading ? -size.width * 0.62 : size.width * 0.62) : 0)
    }


    private var plaque: some View {
        Image("launch_plaque")
            .frame(width: plaqueSide, height: plaqueSide)
            .overlay {
                BulbRing(
                    countPerSide: 8,
                    diameter: 4,
                    color: AppColors.accentAmber,
                    isLit: lampLevel > 0.12
                )
                .padding(-11)
            }
            .shadow(color: AppColors.accentAmber.opacity(0.55 * lampLevel), radius: 36, y: 0)
            .shadow(color: .black.opacity(0.55), radius: 26, y: 14)
    }

    private var wordmark: some View {
        VStack(spacing: 9) {
            Text(l10n.t("app.name"))
                .font(AppFont.display(34, weight: .bold))
                .appTracking(6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textCream)
                .shadow(color: AppColors.accentAmber.opacity(0.5 * lampLevel), radius: 11)

            HStack(spacing: 8) {
                rule
                Text(l10n.t("app.tagline"))
                    .textStyle(.sectionLabel)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize()
                rule
            }
            .frame(maxWidth: 240)
        }
    }

    private var rule: some View {
        Rectangle()
            .fill(AppColors.accentGold.opacity(0.45))
            .frame(height: 1)
    }


    private var loader: some View {
        VStack(spacing: 10) {
            ReelLoadTrack()
            Text(l10n.t("launch.loading"))
                .font(AppFont.ui(8, weight: .semibold))
                .appTracking(2.6)
                .textCase(.uppercase)
                .foregroundStyle(Color(hex: 0x6F6152))
        }
    }


    private func run() async {
        SoundService.curtainOpen()

        guard !reduceMotion else {


            await prepareCatalog()
            withAnimation(.easeOut(duration: 0.2)) {
                isOpen = true
                showsStage = true
                lampLevel = 1
            }
            try? await Task.sleep(for: .milliseconds(200))
            onFinish()
            return
        }

        withAnimation(.easeInOut(duration: total * 0.78).delay(0.12)) {
            isOpen = true
        }
        withAnimation(.easeOut(duration: 0.28).delay(0.22)) {
            showsStage = true
        }

        async let prepared: Void = prepareCatalog()
        async let shown: Void = playLampAndHold()
        _ = await (prepared, shown)
        onFinish()
    }


    private func playLampAndHold() async {
        let deadline = ContinuousClock.now + .seconds(total)

        try? await Task.sleep(for: .milliseconds(380))


        withAnimation(.easeIn(duration: 0.05)) { lampLevel = 0.85 }
        try? await Task.sleep(for: .milliseconds(70))
        withAnimation(.easeOut(duration: 0.06)) { lampLevel = 0 }
        try? await Task.sleep(for: .milliseconds(110))


        withAnimation(.easeIn(duration: 0.04)) { lampLevel = 0.55 }
        try? await Task.sleep(for: .milliseconds(55))
        withAnimation(.easeOut(duration: 0.07)) { lampLevel = 0 }
        try? await Task.sleep(for: .milliseconds(140))


        withAnimation(.easeOut(duration: 0.22)) { lampLevel = 1 }

        let remaining = deadline - ContinuousClock.now
        if remaining > .zero {
            try? await Task.sleep(for: remaining)
        }
    }


    private func prepareCatalog() async {
        await Task { @MainActor in _ = DeckCatalog.v1 }.value
    }
}


private struct ReelLoadTrack: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var travel: CGFloat = 0

    private let trackWidth: CGFloat = 104
    private let segmentRatio: CGFloat = 0.42

    var body: some View {
        let segment = trackWidth * segmentRatio
        Capsule()
            .fill(AppColors.accentGold.opacity(0.22))
            .frame(width: trackWidth, height: 2)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(AppColors.accentAmber)
                    .frame(width: segment, height: 2)
                    .shadow(color: AppColors.accentAmber.opacity(0.8), radius: 4)
                    .offset(x: reduceMotion ? (trackWidth - segment) / 2 : travel)
            }
            .clipped()
            .onAppear {
                guard !reduceMotion else { return }
                travel = -segment * 1.1
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    travel = trackWidth + segment * 0.4
                }
            }
    }
}


private struct SpotConeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topInset = rect.width * 0.38
        path.move(to: CGPoint(x: topInset, y: 0))
        path.addLine(to: CGPoint(x: rect.width - topInset, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
