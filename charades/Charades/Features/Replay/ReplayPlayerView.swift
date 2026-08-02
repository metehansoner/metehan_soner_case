import AVFoundation
import SwiftUI

/// Ekran 18 / 23 — Replay Oynatıcı (§ `04` §4.4).
///
/// Tur sonunda açılan oynatıcı ile arşivden açılan **aynı ekran**; sadece giriş
/// noktası farklı. Altyazı ve ağır çekim, replay'i "kendimizi izliyoruz"
/// seviyesinden "bunu gruba atacağım" seviyesine taşıyan iki detay; ikisi de
/// kayıttaki damgalardan üretiliyor, yeni bir kayıt maliyeti yok.
struct ReplayPlayerView: View {
    let reel: ReplayReel
    /// §03 §5: aynı view iki kapıdan açılıyor; `replay_save` ve `replay_share`
    /// hangisinden geldiğini bilmezse arşivin paylaşıma katkısı ölçülemiyor.
    var source: Analytics.ReplaySource = .roundEnd
    var onDelete: () -> Void
    var onClose: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    @State private var playback = ReplayPlayback()
    @State private var isPinned: Bool
    @State private var isConfirmingDelete = false
    @State private var notice: String?

    init(
        reel: ReplayReel,
        source: Analytics.ReplaySource = .roundEnd,
        onDelete: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.reel = reel
        self.source = source
        self.onDelete = onDelete
        self.onClose = onClose
        _isPinned = State(initialValue: reel.isPinned)
    }

    var body: some View {
        ZStack {
            Color(hex: 0x070605).ignoresSafeArea()

            VStack(spacing: 0) {
                stage
                controls
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .task { playback.load(reel.videoURL) }
        .onDisappear { playback.teardown() }
        .overlay(alignment: .bottom) {
            LockedNotice(text: notice) { notice = nil }
        }
        .confirmationDialog(
            l10n.t("replay.delete.confirm"),
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
                Button(l10n.t("common.delete"), role: .destructive) {
                    Analytics.replayDelete()
                    playback.teardown()
                    onDelete()
                }
            Button(l10n.t("common.cancel"), role: .cancel) {}
        }
    }

    // MARK: Perde

    private var stage: some View {
        ZStack {
            ReplaySurface(player: playback.player)

            // §08: video sprocket delikli film şeridi çerçevesi içinde oynuyor.
            HStack {
                sprocket
                Spacer()
                sprocket
            }

            GrainOverlay()
                .allowsHitTesting(false)

            if playback.speed == .slow {
                slowBadge
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.top, 16)
                    .padding(.leading, 44)
            }

            meta
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 16)
                .padding(.trailing, 44)

            subtitle
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 18)

            closeButton
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 14)
                .padding(.leading, 8)

            if !playback.isPlaying {
                playBadge
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { playback.toggle() }
        .frame(maxHeight: .infinity)
    }

    private var sprocket: some View {
        SprocketStrip(
            axis: .vertical,
            holeSize: 11,
            spacing: 16,
            holeColor: AppColors.surfacePoster.opacity(0.88)
        )
        .frame(width: 26)
        .background(Color(hex: 0x0B0907))
        .allowsHitTesting(false)
    }

    /// §04 §4.4: o anda ekranda olan kelime, altında `DOĞRU`/`PAS` damgası.
    /// Videoyu izleyen kişi neyin anlatıldığını görmezse kaydın yarısı anlamsız.
    @ViewBuilder
    private var subtitle: some View {
        if let cue = ReplayPlayback.cue(at: playback.time, marks: reel.marks) {
            VStack(spacing: 7) {
                if cue.showsStamp {
                    Text(l10n.t(cue.isCorrect ? "game.hint.correct" : "game.hint.skip"))
                        .font(AppFont.display(11, weight: .bold))
                        .appTracking(2.6)
                        .textCase(.uppercase)
                        .foregroundStyle(cue.isCorrect ? AppColors.stateCorrect : AppColors.stateSkip)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 3)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(
                                    cue.isCorrect ? AppColors.stateCorrect : AppColors.stateSkip,
                                    lineWidth: 2
                                )
                        }
                        .rotationEffect(.degrees(-3))
                        .transition(.opacity)
                }

                Text(cue.word)
                    .font(AppFont.display(34, weight: .bold))
                    .appTracking(2.4)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.surfacePoster)
                    .shadow(color: .black.opacity(0.95), radius: 12)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 60)
            .opacity(cue.showsStamp ? 1 : 0.75)
            .animation(.easeOut(duration: 0.2), value: cue.showsStamp)
            .allowsHitTesting(false)
        }
    }

    private var slowBadge: some View {
        Text(l10n.t("replay.slowMotion"))
            .font(AppFont.display(10, weight: .bold))
            .appTracking(2.4)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.accentAmber)
            .padding(.horizontal, 11)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(AppColors.accentAmber.opacity(0.6), lineWidth: 1)
                    }
            }
            .allowsHitTesting(false)
    }

    private var meta: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(headline)
                .font(AppFont.display(13, weight: .semibold))
                .appTracking(1.8)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.surfacePoster)

            Text(caption)
                .font(AppFont.ui(9, weight: .medium))
                .appTracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.surfacePoster.opacity(0.6))

            if reel.isPartial {
                // §09 §2: kesintiye uğrayan kayıt sessizce kısa görünmesin.
                Text(l10n.t("replay.partial"))
                    .font(AppFont.ui(8.5, weight: .bold))
                    .appTracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.stateWarning)
                    .padding(.top, 3)
            }
        }
        .shadow(color: .black.opacity(0.8), radius: 6)
        .allowsHitTesting(false)
    }

    private var playBadge: some View {
        Image(systemName: "play.fill")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(AppColors.surfacePoster)
            .frame(width: 62, height: 62)
            .background {
                Circle().fill(Color.black.opacity(0.45))
            }
            .allowsHitTesting(false)
    }

    private var closeButton: some View {
        Button {
            Haptics.secondaryButton()
            playback.teardown()
            onClose()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.surfacePoster)
                .frame(width: 30, height: 30)
                .background {
                    Circle().fill(Color.black.opacity(0.45))
                }
                .tapTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l10n.t("common.close"))
    }

    // MARK: Kontrol paneli

    private var controls: some View {
        VStack(spacing: 8) {
            timeline

            HStack(spacing: 10) {
                Text(Self.clock(playback.time))
                    .monospacedDigit()
                Spacer()
                Text(Self.clock(playback.duration))
                    .monospacedDigit()
            }
            .font(AppFont.ui(9, weight: .medium))
            .foregroundStyle(AppColors.textMuted)

            HStack(spacing: 9) {
                speedSegment

                if reel.marks.contains(where: \.isCorrect) {
                    actionButton(title: l10n.t("replay.bestMoments"), systemImage: "sparkles") {
                        playback.jumpToBestMoments(marks: reel.marks)
                    }
                }

                Spacer(minLength: 0)

                actionButton(
                    title: l10n.t(isPinned ? "archive.unpin" : "archive.pin"),
                    systemImage: isPinned ? "pin.fill" : "pin",
                    isHighlighted: isPinned,
                    action: togglePin
                )

                actionButton(
                    title: l10n.t("common.delete"),
                    systemImage: "trash",
                    isDestructive: true
                ) {
                    isConfirmingDelete = true
                }

                actionButton(title: l10n.t("archive.save"), systemImage: "square.and.arrow.down") {
                    saveToPhotos()
                }

                    ShareLink(item: reel.videoURL) {
                        actionLabel(
                            title: l10n.t("replay.share"),
                            systemImage: "square.and.arrow.up",
                            isPrimary: true,
                            isDestructive: false,
                            isHighlighted: false
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        Haptics.primaryButton()
                        // Paylaşım sayfasının sonucu geri gelmiyor; ölçülen şey
                        // niyet, gönderim değil.
                        Analytics.replayShare(
                            source: source,
                            slowMotionUsed: playback.usedSlowMotion
                        )
                    })
            }
        }
        .padding(.horizontal, 44)
        .padding(.top, 11)
        .padding(.bottom, 15)
        .background {
            Color(hex: 0x100C0A).opacity(0.97)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppColors.accentGold.opacity(0.2))
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    /// §04 §4.4: `1×` / `0.5×`. Komik anların yarısı ağır çekimde ortaya çıkıyor.
    private var speedSegment: some View {
        HStack(spacing: 3) {
            ForEach(ReplayPlayback.Speed.allCases, id: \.self) { speed in
                let isSelected = playback.speed == speed
                Button {
                    guard !isSelected else { return }
                    Haptics.selection()
                    playback.setSpeed(speed)
                } label: {
                    Text(speed.label)
                        .font(AppFont.display(11, weight: .semibold))
                        .appTracking(1.3)
                        .foregroundStyle(isSelected ? AppColors.textOnAmber : AppColors.textMuted)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(isSelected ? AppColors.accentAmber : .clear)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(2.5)
        .background {
            RoundedRectangle(cornerRadius: 9)
                .fill(AppColors.surfaceCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(AppColors.accentGold.opacity(0.28), lineWidth: 1)
                }
        }
    }

    /// §04 §4.4: doğru anları yeşil, pas anları kırmızı çentik. Dokununca o ana
    /// atlıyor — veri zaten kayıtta, burada yalnızca görselleşiyor.
    private var timeline: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.surfaceCardRaised)
                    .frame(height: 4)

                Capsule()
                    .fill(AppColors.accentAmber)
                    .frame(width: width * playback.fraction, height: 4)

                ForEach(marks(width: width), id: \.id) { mark in
                    Capsule()
                        .fill(mark.isCorrect ? AppColors.stateCorrect : AppColors.stateSkip)
                        .frame(width: 3, height: 20)
                        .offset(x: mark.x - 1.5)
                }

                Circle()
                    .fill(AppColors.accentAmber)
                    .frame(width: 13, height: 13)
                    .shadow(color: AppColors.accentAmber.opacity(0.9), radius: 5)
                    .offset(x: width * playback.fraction - 6.5)
            }
            .frame(height: 22)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { value in
                    playback.seek(fraction: min(1, max(0, value.location.x / width)))
                }
            )
        }
        .frame(height: 22)
    }

    private struct TimelineMark: Identifiable {
        let id: Int
        let x: CGFloat
        let isCorrect: Bool
    }

    private func marks(width: CGFloat) -> [TimelineMark] {
        let duration = playback.duration > 0 ? playback.duration : reel.duration
        guard duration > 0 else { return [] }
        return reel.marks.enumerated().map { index, mark in
            TimelineMark(
                id: index,
                x: width * min(1, max(0, mark.time / duration)),
                isCorrect: mark.isCorrect
            )
        }
    }

    private func actionButton(
        title: String,
        systemImage: String,
        isDestructive: Bool = false,
        isHighlighted: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.secondaryButton()
            action()
        } label: {
            actionLabel(
                title: title,
                systemImage: systemImage,
                isPrimary: false,
                isDestructive: isDestructive,
                isHighlighted: isHighlighted
            )
        }
        .buttonStyle(.plain)
    }

    private func actionLabel(
        title: String,
        systemImage: String,
        isPrimary: Bool,
        isDestructive: Bool,
        isHighlighted: Bool
    ) -> some View {
        let tint: Color = if isPrimary {
            AppColors.textOnAmber
        } else if isDestructive {
            AppColors.stateSkip
        } else if isHighlighted {
            AppColors.accentAmber
        } else {
            AppColors.textCream
        }

        return HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(AppFont.display(11, weight: .semibold))
                .appTracking(1.8)
                .textCase(.uppercase)
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 14)
        .frame(height: 32)
        .background {
            Capsule()
                .fill(isPrimary ? AppColors.accentAmber : .clear)
                .overlay {
                    Capsule().strokeBorder(
                        isPrimary ? .clear : tint.opacity(0.4),
                        lineWidth: 1
                    )
                }
        }
    }

    // MARK: Eylemler

    private func togglePin() {
        guard var stored = ReplayStore.reel(id: reel.id) else { return }
        stored.isPinned.toggle()
        // Sabitleme kotadan muafiyet talebi; kaldırma sıradan bir geri alma.
        // İkisini aynı event'te toplamak "kaç kayıt saklanıyor" sorusunu bozuyor.
        if stored.isPinned { Analytics.replayPin() }
        ReplayStore.save(stored)
        isPinned = stored.isPinned
        notice = l10n.t(stored.isPinned ? "archive.pinned.note" : "archive.unpinned.note")
    }

    private func saveToPhotos() {
        Task {
            switch await PhotoLibrary.save([reel.videoURL]) {
            case .saved:
                Analytics.replaySave(source: source, slowMotionUsed: playback.usedSlowMotion)
                Haptics.exportSucceeded()
                notice = l10n.t("archive.saved", count: 1)
            case .denied:
                notice = l10n.t("archive.save.denied")
            case .failed:
                notice = l10n.t("archive.save.failed")
            }
        }
    }

    // MARK: Künye

    /// Kayıt kimliklerle saklanıyor, başlık **okuma anında** çözülüyor: kayıt
    /// Türkçe alınıp arşive İngilizce bakılabiliyor (§06 §2).
    private var headline: String {
        let scene = l10n.t("replay.scene", ["no": String(format: "%02d", reel.sceneIndex)])
        return "\(sourceTitle) · \(scene)"
    }

    private var sourceTitle: String {
        if reel.deckIDs.count == 1, let deck = DeckCatalog.deck(reel.deckIDs[0]) {
            return l10n.t(deck.titleKey)
        }
        if reel.deckIDs.count > 1 { return l10n.t("mode.mix.title") }
        return l10n.t("mode.\(reel.modeID).title")
    }

    private var caption: String {
        let date = ArchiveModel.dateText(reel.createdAt, localeCode: l10n.localeCode)
        let correct = l10n.t("round.correct", ["count": "\(reel.correctCount)"])
        return [date, reel.playerName, correct].compactMap { $0 }.joined(separator: " · ")
    }

    private static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// Arşivden açılan oynatıcı (ekran 23). Aynı view, farklı giriş: kayıt id ile
/// yükleniyor ve kapanınca arşive dönüyor, oyun akışına değil (§02 §5).
struct ArchivePlayerScreen: View {
    let reelID: String

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            Color(hex: 0x070605).ignoresSafeArea()

            if let reel = ReplayStore.reel(id: reelID) {
                ReplayPlayerView(
                    reel: reel,
                    source: .archive,
                    onDelete: {
                        ReplayStore.delete(id: reelID)
                        router.pop()
                    },
                    onClose: router.pop
                )
            }
        }
        // §09 §1: video 16:9 yatay; pencere portrait kalır, içerik forced-landscape.
        .forcedLandscape()
        .onAppear { OrientationLock.shared.lockPortrait() }
        .onDisappear { OrientationLock.shared.lockPortrait() }
    }
}

/// `AVPlayerLayer`ı SwiftUI'ye taşıyan ince katman. `VideoPlayer` sistem
/// kontrollerini zorunlu kılıyor; buradaki panel film şeridi çerçevesinin
/// parçası, sistem çubuğu o çerçeveyi bozuyor.
private struct ReplaySurface: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        view.playerLayer.player = player
    }

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

/// Oynatma durumu. Zaman gözlemcisi ve bitiş bildirimi tek yerde toplanıyor;
/// view yalnızca okuyor.
@MainActor
@Observable
final class ReplayPlayback {
    enum Speed: Double, CaseIterable {
        case normal = 1
        case slow = 0.5

        var label: String { self == .normal ? "1×" : "0.5×" }
    }

    /// Altyazının o anki hâli: kelime ekranda dururken damga yok, cevap
    /// verildiği anda damga biniyor.
    struct Cue {
        let word: String
        let isCorrect: Bool
        let showsStamp: Bool
    }

    /// Damga cevaptan sonra bu kadar saniye ekranda kalıyor.
    private static let stampHold: TimeInterval = 1.2

    /// §04 §4.4 en iyi anlar: doğru damgalarının yoğunlaştığı ~15 saniye.
    private static let highlightWindow: TimeInterval = 15

    let player = AVPlayer()

    private(set) var time: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isPlaying = false
    private(set) var speed: Speed = .normal
    /// §03 §5 `slow_motion_used`: paylaşılan kayıtların ağır çekimle izlenmiş
    /// olma oranı, özelliğin kalıp kalmayacağının verisi. O an ağır çekimde
    /// olması değil, oturumda **bir kez** açılmış olması sayılıyor.
    private(set) var usedSlowMotion = false

    var fraction: Double { duration > 0 ? min(1, time / duration) : 0 }

    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    static func cue(at time: TimeInterval, marks: [ReplayReel.Mark]) -> Cue? {
        guard let mark = marks.first(where: { time <= $0.time + stampHold }) else { return nil }
        return Cue(word: mark.word, isCorrect: mark.isCorrect, showsStamp: time >= mark.time)
    }

    func load(_ url: URL) {
        guard player.currentItem == nil else { return }

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        // Kayıtta ses yok ama oynatıcı yine de ambient oturumu bozmasın:
        // ana ekranda müzik dinleyen kullanıcının müziği kesilmiyor.
        player.isMuted = true

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] current in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.time = current.seconds
                if self.duration == 0,
                   let itemDuration = self.player.currentItem?.duration.seconds,
                   itemDuration.isFinite {
                    self.duration = itemDuration
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.rewind()
            }
        }

        play()
    }

    func toggle() {
        isPlaying ? pause() : play()
        Haptics.selection()
    }

    func setSpeed(_ newValue: Speed) {
        speed = newValue
        if newValue == .slow { usedSlowMotion = true }
        guard isPlaying else { return }
        player.rate = Float(newValue.rawValue)
    }

    func seek(fraction: Double) {
        guard duration > 0 else { return }
        let target = CMTime(seconds: duration * fraction, preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        time = duration * fraction
    }

    /// Doğru damgalarının en yoğun olduğu pencereye atlıyor. Ayrı bir dışa
    /// aktarım değil, sadece oynatma konumu: kayıt tek dosya olarak kalıyor.
    func jumpToBestMoments(marks: [ReplayReel.Mark]) {
        let correct = marks.filter(\.isCorrect).map(\.time)
        guard !correct.isEmpty, duration > Self.highlightWindow else {
            seek(fraction: 0)
            play()
            return
        }

        let best = correct.max { first, second in
            density(from: first, in: correct) < density(from: second, in: correct)
        }
        guard let start = best else { return }

        // Pencere damganın biraz öncesinden başlıyor: cevap anına gelene kadar
        // kullanıcı ne anlatıldığını görüyor.
        let from = max(0, min(start - 2, duration - Self.highlightWindow))
        seek(fraction: from / duration)
        play()
    }

    private func density(from start: TimeInterval, in times: [TimeInterval]) -> Int {
        times.filter { $0 >= start - 2 && $0 <= start - 2 + Self.highlightWindow }.count
    }

    private func play() {
        player.rate = Float(speed.rawValue)
        isPlaying = true
    }

    private func pause() {
        player.pause()
        isPlaying = false
    }

    private func rewind() {
        player.seek(to: .zero)
        pause()
        time = 0
    }

    func teardown() {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        timeObserver = nil
        endObserver = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaying = false
    }
}
