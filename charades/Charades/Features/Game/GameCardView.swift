import SwiftUI

/// Ekran 15 — 02-ekran-akisi.md §4, oyunun ana ekranı.
///
/// Zemin afiş kağıdı, üst ve altta film sprocket şeridi; kelime ortada, Oswald
/// Bold 96'dan başlayıp sığana kadar küçülüyor (min 44). Portrait yedeğinde
/// (§09 §1) telefon alna konmadığı ve kelimeyi kullanıcı da gördüğü için ölçek
/// 48–64'e düşüyor.
struct GameCardView: View {
    let game: LiveGame

    @Environment(LocalizationManager.self) private var l10n

    private var isPortrait: Bool { game.playsInPortrait }

    var body: some View {
        ZStack {
            poster

            if game.answerInput == .touch {
                touchTargets
            }

            if let flash = game.flash {
                answerFlash(flash)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.12), value: game.flash)
    }

    // MARK: Afiş

    private var poster: some View {
        VStack(spacing: 0) {
            sprocketBand
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
                // Mockup'taki `.game::after` kağıt dokusu.
                HalftoneTexture(dotSize: 0.6, spacing: 3.5, color: .black.opacity(0.45))
                    .opacity(0.16)
            }
            .ignoresSafeArea()
        }
    }

    private var sprocketBand: some View {
        SprocketStrip(
            axis: .horizontal,
            holeSize: 11,
            spacing: 14,
            holeColor: AppColors.surfacePoster.opacity(0.9)
        )
        .frame(height: 26)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0x0B0907))
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
                if game.showsInputHint {
                    inputHint
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, isPortrait ? 22 : 30)
    }

    /// §04 §1 `Canlandır`: kelimeyi yalnızca telefonu tutan görmeli, bu yüzden
    /// **küçük ve tek satır**. Diğer modlarda tam tersi geçerli — kelime iki
    /// metre öteden okunacak.
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
            // §08 A4: film karesi ilerlemesi — mevcut kelime yukarı kayıyor,
            // yeni kelime alttan geliyor. Sprocket hızlanması P17'de.
            .transition(
                .asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top))
                    .combined(with: .opacity)
            )
            .animation(.easeOut(duration: 0.28), value: game.currentCard?.k)
            .accessibilityLabel(game.currentCard.map { $0.text(for: l10n.localeCode) } ?? "")
    }

    /// §04 §1 `Hız Turu`: "ekranda kelimenin altında ince bir sayaç çubuğu
    /// erir". Ticker 0.1 sn'de bir işlediği için genişlik adım adım geliyor;
    /// lineer animasyon aradaki kareleri dolduruyor.
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

    // MARK: HUD

    private var hud: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.clock(game.remaining))
                    .font(AppFont.display(38, weight: .bold))
                    .tracking(1)
                    .monospacedDigit()
                    // §04 §3: son 10 saniyede sayaç `stateWarning`e dönüyor.
                    .foregroundStyle(
                        game.isInFinalTen ? AppColors.stateWarning : AppColors.textOnPoster
                    )
                Text(l10n.t("game.hud.remaining"))
                    .font(AppFont.ui(8.5, weight: .semibold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: 0x6B5C46))
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
                    .font(AppFont.ui(8.5, weight: .semibold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: 0x6B5C46))
            }
        }
        .padding(.top, 16)
        .accessibilityElement(children: .combine)
    }

    /// §04 §4.1: kamera önizlemesi **gösterilmiyor** — kullanıcı kendini
    /// görmesin, doğal davransın. Kaydın sürdüğünü söyleyen tek işaret bu nokta;
    /// nabzı yavaş, kelimeyle yarışmıyor.
    private var recordingDot: some View {
        TimelineView(.periodic(from: .now, by: 0.9)) { context in
            let isOn = Int(context.date.timeIntervalSinceReferenceDate / 0.9) % 2 == 0
            HStack(spacing: 5) {
                Circle()
                    .fill(AppColors.stateSkip)
                    .frame(width: 7, height: 7)
                    .opacity(isOn ? 1 : 0.3)
                Text(l10n.t("replay.rec"))
                    .font(AppFont.ui(8.5, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Color(hex: 0x8A7860))
            }
            .animation(.easeInOut(duration: 0.35), value: isOn)
        }
        .padding(.top, 7)
        .accessibilityHidden(true)
    }

    // MARK: Alt şerit

    /// §02 ekran 15: `PAS ↰ | ↱ DOĞRU`, ilk 3 turda görünüyor.
    ///
    /// Ok yönleri dilden ve RTL'den bağımsız (§04 §2, §06 §2): telefonu öne
    /// eğmek her dilde DOĞRU. Dokunmatik modda oklar yerini ekran yarılarına
    /// bırakıyor.
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
        .font(AppFont.ui(9.5, weight: .semibold))
        .tracking(2.2)
        .textCase(.uppercase)
        .foregroundStyle(Color(hex: 0x8A7860))
        .accessibilityHidden(true)
    }

    /// §09 §4: havuz bitip başa döndü.
    private var wrapNotice: some View {
        Text(l10n.t("game.deckWrapped"))
            .font(AppFont.ui(8.5, weight: .bold))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(Color(hex: 0x6B5C46))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background {
                Capsule().strokeBorder(Color(hex: 0x6B5C46).opacity(0.35), lineWidth: 1)
            }
    }

    /// §09 §2: kullanıcı telefonu fiziksel olarak dikey tutuyorsa açı nötr
    /// banda düşer ve hiç tetik gelmez — oyun bozuk değil, duruş yanlış.
    private var reminder: some View {
        Text(l10n.t("game.holdLandscape"))
            .font(AppFont.ui(10, weight: .semibold))
            .foregroundStyle(AppColors.stateSkip)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background {
                Capsule().fill(AppColors.surfacePoster.opacity(0.9))
            }
    }

    // MARK: Dokunmatik cevap

    /// §04 §2: ekranın sol yarısı PAS, sağ yarısı DOĞRU.
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

    // MARK: Geri bildirim

    /// §04 §2: tam ekran renk + eğik mühür, 0.45 saniye.
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
                    .tracking(5)
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

/// `PAS ↰` solda ikon, `↱ DOĞRU` sağda ikon — ok her zaman ekranın dışına bakıyor.
private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}
