import SwiftUI


struct OnboardingSheet: View {
    var onFinish: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var index = 0


    private var detent: PresentationDetent {
        if AppLayout.isRegularWidth(horizontalSizeClass) { return .large }
        return typeSize.isAccessibilitySize ? .fraction(0.9) : .fraction(0.55)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $index) {
                ForEach(Array(steps.enumerated()), id: \.offset) { offset, step in
                    OnboardingStepView(step: step)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            Button(l10n.t(steps[index].ctaKey)) {
                Haptics.primaryButton()
                advance()
            }
            .buttonStyle(MarqueeButtonStyle())
            .padding(.top, 15)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 22)
        .background {
            OnboardingBackdrop()
        }
        .animation(.easeOut(duration: 0.2), value: index)

        .interactiveDismissDisabled()
        .presentationDetents([detent])
        .presentationCornerRadius(28)
        .presentationBackground(.clear)
        .onAppear { index = min(settings.onboardingStep, steps.count - 1) }


        .onChange(of: index, initial: true) { _, new in
            settings.storeOnboardingStep(new)
            Analytics.onboardingStepView(step: new + 1)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {


            FilmStripProgress(total: steps.count, current: index) { index = $0 }
                .frame(width: 89)

            Spacer(minLength: 0)


            Button(l10n.t("onboarding.skip")) {
                Analytics.onboardingSkip(step: index + 1)
                finish()
            }
            .font(AppFont.display(11.5, weight: .semibold))
            .appTracking(2)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textMuted)
            .buttonStyle(.plain)
            .opacity(isLastStep ? 0.25 : 1)
            .disabled(isLastStep)
        }
        .padding(.top, 15)
    }

    private var isLastStep: Bool { index >= steps.count - 1 }

    private func advance() {
        guard isLastStep else {
            index += 1
            return
        }


        Analytics.onboardingComplete()
        finish()
    }

    private func finish() {
        settings.markOnboardingDone()
        onFinish()
    }


    private var steps: [OnboardingStep] {
        var tilts = MotionService.shared.isAvailable && !settings.prefersTouchAnswers
        #if DEBUG

        if ProcessInfo.processInfo.arguments.contains("-TiltOnboarding") { tilts = true }
        #endif
        return [
            OnboardingStep(
                titleKey: "onboarding.welcome.title",
                bodyKey: "onboarding.welcome.body",
                ctaKey: "onboarding.cta.continue",
                artwork: .posterFan,
                bodyArguments: [
                    "decks": DeckCatalog.v1.count.formatted(.number),
                    "cards": DeckCatalog.advertisedCardCount.formatted(.number),
                    "languages": LocalizationManager.supportedLocales.count.formatted(.number),
                ]
            ),
            OnboardingStep(
                titleKey: "onboarding.forehead.title",
                bodyKey: "onboarding.forehead.body",
                ctaKey: "onboarding.cta.next",
                artwork: .illustration("ob_forehead")
            ),
            OnboardingStep(
                titleKey: tilts ? "onboarding.tilt.title" : "onboarding.tap.title",
                bodyKey: tilts ? "onboarding.tilt.body" : "onboarding.tap.body",
                ctaKey: "onboarding.cta.ready",
                artwork: tilts ? .tiltZones : .tapZones
            )
        ]
    }
}


private struct OnboardingStep {
    enum Artwork {
        case posterFan
        case illustration(String)

        case tiltZones

        case tapZones
    }

    let titleKey: String
    let bodyKey: String
    let ctaKey: String
    let artwork: Artwork


    var bodyArguments: [String: String] = [:]
}

private struct OnboardingStepView: View {
    let step: OnboardingStep

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 0) {


            if !typeSize.isAccessibilitySize {
                artwork
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 6)
            }


            ScrollView {
                VStack(spacing: 9) {
                    Text(l10n.t(step.titleKey))
                        .font(AppFont.display(21, weight: .bold, scales: .title3))
                        .appTracking(2.4)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.textCream)

                    Text(l10n.t(step.bodyKey, step.bodyArguments))
                        .font(AppFont.ui(13))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)

            .layoutPriority(1)
            .padding(.top, 12)
        }
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.8)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var artwork: some View {
        switch step.artwork {
        case .posterFan:
            PosterFan()
        case .illustration(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        case .tiltZones, .tapZones:
            TiltAnswerDiagram(showsHints: true)
        }
    }
}


private struct OnboardingBackdrop: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0x4A1720), location: 0),
                .init(color: AppColors.bgVelvetDeep, location: 0.34),
                .init(color: AppColors.surfaceCard, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.accentGold.opacity(0.5))
                .frame(height: 1)
        }
        .overlay { GrainOverlay() }
        .ignoresSafeArea()
    }
}
