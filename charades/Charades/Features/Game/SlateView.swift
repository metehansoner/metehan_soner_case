import SwiftUI

/// Klaket ve başlık kartı — 08-sinematik-detaylar.md A2 + B5.
///
/// İkisi tek view: B5'in kendi tanımı "klaketle birlikte tek akış gibi görünür".
/// Ayrı iki faz yapmak aralarına bir kare boşluk koyuyor ve akış iki ayrı ekran
/// gibi okunuyordu.
///
/// §08 §0 bütçesi:
///
/// | Tur | Klaket | Başlık | Geri sayım | Toplam |
/// |---|---|---|---|---|
/// | Maçın ilki | 0,9 sn | 0,5 sn | 3 sn | 4,4 sn |
/// | Sonrakiler | 0,35 sn | — | 3 sn | 3,35 sn |
///
/// Ekranın tamamı dokunuşla atlanıyor (§0: geri sayım hariç hepsi atlanabilir).
struct SlateView: View {
    /// Maçtaki sahne sırası — arşivdeki `replay.scene` ile **aynı sayı**.
    let scene: Int
    /// §08 A2: "Takım modunda ÇEKİM 03 tur numarasını veriyor." Diğer modlarda
    /// aynı sahnenin kaçıncı denemesi (Duraklat → `YENİDEN`); ikisi de "bu kaçıncı
    /// deneme" sorusunun o moddaki karşılığı.
    let take: Int
    let deckTitle: String
    let modeTitle: String
    /// Yalnızca maçın ilk turunda tam sürüm; sonrakiler kısa (§08 A2).
    let isFull: Bool
    var onFinish: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Çubuğun açık (kalkık) hâli. Kapanış "klak" anı.
    @State private var isBarOpen = true
    @State private var flash = false
    @State private var hasExited = false
    @State private var showsTitleCard = false

    // Süreler tek yerde: bütçe denetimi tabloya bakarak yapılabilsin.
    private var barFall: TimeInterval { isFull ? 0.42 : 0.18 }
    private var holdAfterClack: TimeInterval { isFull ? 0.28 : 0.07 }
    private var exitDuration: TimeInterval { isFull ? 0.2 : 0.1 }
    private let titleCardDuration: TimeInterval = 0.5

    var body: some View {
        ZStack {
            AppColors.bgFilmBlack.ignoresSafeArea()

            if showsTitleCard {
                titleCard
                    .transition(.opacity)
            } else {
                slate
                    // Kapanınca sola kayarak çıkıyor — kameranın önünden
                    // çekilen gerçek klaketin yönü.
                    .offset(x: hasExited ? -exitOffset : 0)
                    .opacity(hasExited ? 0 : 1)
            }

            // Klak anında tek karelik beyaz patlama. Reduce Motion'da yok:
            // ani parlaklık değişimi §5'in kapattığı ilk şey.
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

    // MARK: Klaket

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

    /// Üstteki çubuk: yukarıdan iniyor ve gövdeye çarpıyor.
    private var clapstick: some View {
        DiagonalStripes()
            .frame(height: 34)
            .frame(maxWidth: .infinity)
            .background(AppColors.bgFilmBlack)
            .overlay {
                Rectangle().strokeBorder(AppColors.textOnPoster.opacity(0.35), lineWidth: 1)
            }
            // Menteşe solda: çubuk düz inmiyor, dönerek kapanıyor.
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
                // Sütun sabit: dört satırın değerleri aynı hizada başlamazsa
                // klaket künye değil liste gibi duruyor. Uzun diller (`el`
                // "Λειτουργία") sütunu taşırmasın diye küçülüyor.
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

    // MARK: Başlık kartı — B5

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

    // MARK: Akış

    private func run() async {
        guard !reduceMotion else {
            // §5: klaket "anlık kesmeye" dönüyor. Bilgi kaybolmuyor —
            // deste ve mod adı zaten bir önceki ekranda seçildi.
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
            withAnimation(.easeOut(duration: 0.18)) { showsTitleCard = true }
            try? await Task.sleep(for: .seconds(titleCardDuration))
            guard !Task.isCancelled else { return }
        }
        onFinish()
    }

    private func clack() {
        Haptics.clapper()
        SoundService.clapper()
        // Bir kare (~16 ms) fazla kalırsa patlama değil geçiş oluyor.
        flash = true
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            withAnimation(.easeOut(duration: 0.12)) { flash = false }
        }
    }

    /// Dokunuş: kalan bezemeyi atlıyor, bilgiyi zaten okunmuş sayıyor.
    private func finishNow() {
        guard !hasExited || showsTitleCard else { return }
        onFinish()
    }

    private var exitOffset: CGFloat { 700 }

    private func number(_ value: Int) -> String {
        String(format: "%02d", value)
    }

    /// VoiceOver klaketi kare kare okumuyor: tek cümlede sahne, deste ve mod.
    private var spokenSummary: String {
        isFull
            ? "\(l10n.t("slate.scene")) \(scene), \(deckTitle), \(modeTitle)"
            : "\(l10n.t("slate.scene")) \(scene)"
    }
}

/// Klaket çubuğunun siyah-beyaz eğik şeritleri.
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
