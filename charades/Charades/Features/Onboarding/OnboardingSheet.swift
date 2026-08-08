import SwiftUI

/// Ekran 2 — Onboarding, 03-onboarding-paywall.md §1.
///
/// Ana ekranın üzerinde **bottom sheet**: arkadaki deste ızgarası bulanık değil,
/// net görünüyor. Kullanıcı anlatımı okurken 92 desteyi görüyor — "buradan çıkıp
/// bunlara bakayım" hissi ekranın kendi işi değil, arkasının işi.
///
/// Üç adım, beş değil (§ `03` §1): eski 2–5 Nasıl Oynanır slider'ının kopyasıydı.
/// Onboarding ikna ediyor, o slider talimat veriyor. Eğme sayfası birleştirilmedi
/// çünkü oyunun tek mekaniği o.
struct OnboardingSheet: View {
    var onFinish: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var index = 0

    /// §03 §1 sheet'i ekranın %55'i. Erişilebilirlik / iPad'de yükseliyor.
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
        // §03 §1: kapatılamaz. Tek çıkış `ATLA` ya da son adımın CTA'sı.
        .interactiveDismissDisabled()
        .presentationDetents([detent])
        .presentationCornerRadius(28)
        .presentationBackground(.clear)
        .onAppear { index = min(settings.onboardingStep, steps.count - 1) }
        // §03 §5: adım görünümü hem ileri gidişte hem şeritten geri dönüşte
        // sayılıyor; funnel'ın sorduğu şey "kaç kişi bu adımı gördü".
        .onChange(of: index, initial: true) { _, new in
            settings.storeOnboardingStep(new)
            Analytics.onboardingStepView(step: new + 1)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            // Geri dönüş yalnızca şeritten: okunmuş bir adıma dönmek isteyen
            // kullanıcı için ayrı bir buton eklemek üstteki satırı kalabalıklaştırıyor.
            FilmStripProgress(total: steps.count, current: index) { index = $0 }
                .frame(width: 89)

            Spacer(minLength: 0)

            // §03 §1: `ATLA` son sayfa hariç. Son sayfada kaldırmak yerine
            // soluklaşıyor — satırın hizası bozulmuyor, kaçış yolu da bitmiş oluyor.
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
        // `ATLA` da son adımın CTA'sı da onboarding'i bitiriyor ama funnel'da
        // ikisi aynı şey değil: biri okundu, diğeri atlandı.
        Analytics.onboardingComplete()
        finish()
    }

    private func finish() {
        settings.markOnboardingDone()
        onFinish()
    }

    /// §03 §1'deki üç adım. Adım 3, cihazda hareket sensörü yoksa dokunmatik
    /// anlatımına düşüyor — o kullanıcıda eğme diye bir şey hiç olmayacak
    /// (§ `04` §2 dokunmatik yedek).
    private var steps: [OnboardingStep] {
        var tilts = MotionService.shared.isAvailable && !settings.prefersTouchAnswers
        #if DEBUG
        // Simülatörde hareket sensörü yok; eğme hâli başka türlü görülemiyor.
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

// MARK: - Adım

private struct OnboardingStep {
    enum Artwork {
        case posterFan
        case illustration(String)
        /// Ortada telefon, iki yanında PAS / DOĞRU bölgesi.
        case tiltZones
        /// Aynı diyagram, telefonun iki yarısı olarak (§ `04` §2).
        case tapZones
    }

    let titleKey: String
    let bodyKey: String
    let ctaKey: String
    let artwork: Artwork
    /// Deste ve kart sayısı katalogdan geliyor; içerik büyüdükçe metin kendi
    /// kendine güncelleniyor (§ `05` §8'deki 92 deste hedefi henüz dolmadı).
    var bodyArguments: [String: String] = [:]
}

private struct OnboardingStepView: View {
    let step: OnboardingStep

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 0) {
            // Erişilebilirlik puntolarında görsel tamamen çekiliyor: yükselen
            // sheet'te bile afiş yelpazesi metnin yerini alıyor ve cümle yarıda
            // kalıyordu. Görsel bezeme (`accessibilityHidden`), cümle bilgi.
            if !typeSize.isAccessibilitySize {
                artwork
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 6)
            }

            // Sheet yüksekliği §03 §1'de sabit (%55). Büyük puntolarda metin
            // önce görseli sıkıştırıyor, yine sığmazsa kayıyor — kırpılmış
            // yarım cümle yerine tam metin.
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
            // Yer paylaşımında metin önce gelir: görsel bezeme, cümle bilgi.
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
        case .tiltZones:
            AnswerZonesArt(showsPhone: true)
        case .tapZones:
            AnswerZonesArt(showsPhone: false)
        }
    }
}

// MARK: - Eğme / dokunma diyagramı

/// Adım 3: solda PAS, sağda DOĞRU, ortada telefon. Yön ve renk eşlemesi
/// § `04` §2'den: öne eğ = DOĞRU (yeşil), arkaya eğ = PAS (kırmızı);
/// dokunmatikte ekranın sağ yarısı DOĞRU, sol yarısı PAS.
///
/// Bölgeler dilden ve RTL'den bağımsız: sol/sağ fiziksel bir eşleme, çevrilmiyor.
private struct AnswerZonesArt: View {
    var showsPhone: Bool

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        HStack(spacing: 14) {
            zone(
                color: AppColors.stateSkip,
                // Ok, cevabın nasıl verildiğini gösteriyor: eğmede telefonun
                // gittiği yön, dokunmada ekranın hangi yarısı.
                systemImage: showsPhone ? "arrow.up" : "arrow.left",
                label: l10n.t("game.stamp.skip"),
                hint: l10n.t(showsPhone ? "onboarding.zone.tiltBack" : "onboarding.zone.tapLeft")
            )

            if showsPhone {
                phone
            }

            zone(
                color: AppColors.stateCorrect,
                systemImage: showsPhone ? "arrow.down" : "arrow.right",
                label: l10n.t("game.stamp.correct"),
                hint: l10n.t(showsPhone ? "onboarding.zone.tiltForward" : "onboarding.zone.tapRight")
            )
        }
        .frame(maxWidth: .infinity)
        .environment(\.layoutDirection, .leftToRight)
    }

    private var phone: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(AppColors.bgVelvetDeep.opacity(0.9))
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(AppColors.accentGold, lineWidth: 2)
            }
            .overlay {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 19, weight: .light))
                    .foregroundStyle(AppColors.accentGold)
            }
            .frame(width: 44, height: 82)
            .shadow(color: AppColors.accentAmber.opacity(0.3), radius: 9)
    }

    private func zone(color: Color, systemImage: String, label: String, hint: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)

            Text(label)
                .font(AppFont.display(12, weight: .bold))
                .appTracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(color)

            Text(hint)
                .font(AppFont.ui(8.5))
                .appTracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textMuted)
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 11)
        .padding(.horizontal, 8)
        .frame(maxWidth: 104)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
                .overlay {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(color, lineWidth: 1.5)
                }
        }
    }
}

// MARK: - Zemin

/// `SheetScaffold` başlık ve kapatma çarpısı dayatıyor; onboarding'in ikisi de
/// yok. Ortak olan yalnızca kadife gradient, o da burada tekrarlanıyor.
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
