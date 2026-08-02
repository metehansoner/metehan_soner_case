import Foundation
import Observation
import SwiftUI

/// Oyun akışının fazları — 09-kesinti-ve-sinir-durumlari.md §1.
///
/// Landscape fazlar sistem yönüne bağlanmıyor: `ForcedLandscapeContainer`
/// içeriği 90° çeviriyor (cihaz yön kilidi açık/kapalı fark etmez). Eşleme
/// `prefersLandscape` içinde tek yerde; yeni faz oraya bir satır.
enum LivePhase: Equatable {
    /// §08 A2 + B5: klaket ve başlık kartı. Landscape — geri sayımın devamı
    /// gibi okunuyor.
    case slate
    /// Landscape: 3-2-1. Motion kalibrasyonu burada yapılıyor.
    case countdown
    case playing
    /// Oyunun üstünde overlay; yön değişmiyor.
    case paused
    /// §1 kritik düzeltme: süre 0'a inince otomatik geliniyor ve telefon o an
    /// birinin alnında yatay duruyor. Portrait tasarlanmış bir liste burada
    /// okunamaz — bu ekran landscape.
    case roundEnd
    /// §09 §5: takım index'i tek başına yetmiyordu — perde arası "telefonu
    /// Ayşe alsın" diyebilmek için sıradaki kişiyi de taşıyor. Landscape:
    /// telefon elden ele geçiyor ama hâlâ yatay.
    case teamHandoff(nextTeam: Int, nextPlayer: String?)
    /// Portrait: jenerik dikey okunuyor, oyun bitti (§09 §1).
    case matchEnd
}

/// Bir turun canlı durumu — 04-oyun-modlari.md §3.
///
/// `RootView`'da `LiveGame?` olarak duruyor: nil değilse `NavigationStack`in
/// **tamamının yerine** `GameFlowView` render ediliyor (§02 §5). Oyun path'e
/// push edilmiyor, böylece tur sırasında geri butonu ve swipe-back yok;
/// çıkışın tek yolu duraklat (§09 §3).
@MainActor
@Observable
final class LiveGame {

    /// Tur sonu ekranında kolonlar arası taşınabilen tek cevap (§02 ekran 17).
    struct Answer: Identifiable, Equatable {
        let card: Card
        var isCorrect: Bool
        /// Tur başından itibaren saniye. Replay zaman çizelgesi bu damgayı
        /// **kullanmıyor**: §09 §9 gereği oradaki referans video saati ve
        /// duraklatmada ikisi ayrışıyor. Damganın oyun tarafındaki karşılığı
        /// burada duruyor, kaydın karşılığı `ReplayRecorder` içinde.
        let offset: TimeInterval

        var id: String { card.k }
    }

    enum Flash: Equatable {
        case correct
        case skip
    }

    /// Duraklatmanın kimden geldiği, `DEVAM ET` davranışını değiştirmiyor ama
    /// overlay başlığını değiştiriyor: sistem kesintisinde kullanıcı neden
    /// duraklandığını bilmiyor.
    enum PauseReason: Equatable {
        case user
        /// §09 §2: arka plan, gelen çağrı, ekran kilidi.
        case system
    }

    /// Oyun akışından çıkış hedefi. Tek bir "kapat" yetmiyor: maç sonundaki
    /// `TEKRAR OYNA` ana ekrana değil Takım Kurulumu'na dönüyor (§02 §3).
    enum Exit: Equatable {
        case home
        case teamRematch
        /// §04 §4.3 giriş noktası 3: jenerikteki `ARŞİVE GİT`. Kaydın var
        /// olduğunu tam ilgili olduğu anda öğreniyor.
        case archive
    }

    // MARK: Kurulum (tur boyunca sabit)

    let mode: GameMode
    let deckIDs: [String]

    /// Kelime Sepeti ya da custom desteden gelen kartlar. Tur sonundaki
    /// `SEPETİ KAYDET` şeridi kaydedilecek kelimeleri buradan okuyor: oyun akışı
    /// `GameSetup`u görmüyor (§02 §5, `NavigationStack`in yerine geçiyor).
    let customCards: [Card]

    /// §09 §5: ani ölüm turu 30 saniye, o yüzden maç ortasında değişebiliyor.
    private(set) var duration: Int
    private let baseDuration: Int

    /// Takım Savaşı'nda maçın tamamı; diğer modlarda `nil`.
    let match: TeamMatch?

    /// Cevap yöntemi tur başında sabitleniyor (ayar / sensör).
    private(set) var answerInput: AnswerInput
    /// Portrait yedek düzeni (küçük punto). Sistem yönüne bağlı değil —
    /// `ForcedLandscapeContainer` kullanılmadığı nadir yollar için.
    private(set) var playsInPortrait: Bool

    // MARK: Durum

    private(set) var phase: LivePhase
    private(set) var currentCard: Card?
    private(set) var answers: [Answer] = []
    private(set) var flash: Flash?
    private(set) var pauseReason: PauseReason = .user

    /// §02 ekran 17: `REPLAY'İ İZLE` yalnızca o turda kayıt alındıysa görünüyor.
    /// Tur sonunda dosya kapandıktan sonra doluyor, yeni tur başlarken boşalıyor.
    private(set) var reel: ReplayReel?

    /// §04 §4.3: jenerikteki `ARŞİVE GİT` yalnızca bu maçtan en az bir makara
    /// kaldıysa görünüyor — boş bir arşive gönderen bağlantı kırık bir bağlantı.
    private(set) var matchHasReels = false

    /// §04 §4.1: landscape oyun ekranında önizleme yok, sadece kırmızı nokta.
    var isRecording: Bool { ReplayRecorder.shared.isRecording }

    /// Geri sayımda gösterilen rakam.
    private(set) var countdownValue = 3

    /// §08 A2 künye satırı 1. Arşivdeki `replay.scene` ile **aynı sayı**:
    /// klakette `SAHNE 02` görüp arşivde `SAHNE 02` bulmak, kaydın hangi tura
    /// ait olduğunu aramadan söylüyor.
    var sceneNumber: Int { (match?.results.count ?? soloRoundIndex) + 1 }

    /// §08 A2 künye satırı 2: "Takım modunda `ÇEKİM 03` tur numarasını veriyor."
    /// Diğer modlarda aynı sahnenin kaçıncı denemesi — Duraklat → `YENİDEN`.
    /// Ani ölümde `currentRound` 0'a düşüyor; klakette 0'lı bir çekim yok, o
    /// turun kendi açıklaması zaten perde arasında yapıldı.
    var takeNumber: Int { max(match?.currentRound ?? takeIndex, 1) }

    /// §08 A2: tam klaket yalnızca maçın ilk turunda; sonrakiler kısa sürüm.
    var isSlateFull: Bool { !slateWasShown }

    private var soloRoundIndex = 0
    private var takeIndex = 1
    private var slateWasShown = false

    /// Kalan süre, saniye (yukarı yuvarlanmış).
    private(set) var remaining: Int

    /// §09 §4: havuz bitip başa döndü — ekranda bir kez `DESTE BAŞA DÖNDÜ`.
    private(set) var didWrapPool = false

    /// §08 B2: perde arasının 5 saniyelik otomatik geri sayımı. `HAZIRIM`
    /// beklemeyi zorunlu olmaktan çıkarıyor, sayaç yine de akıyor.
    private(set) var handoffCountdown = 0

    /// §09 §2: 8 saniyedir tetik yok, "Telefonu yatay tut" hatırlatması.
    var showsOrientationReminder: Bool {
        phase == .playing && answerInput == .tilt && MotionService.shared.isSilentTooLong
    }

    /// §04 §3: ceza puanı yok. Hız Turu'nda doğru 2 puan.
    var score: Int { correctAnswers.count * mode.scoreMultiplier }

    /// §04 §1: Hız Turu'nda kelimenin altında eriyen ince sayaç çubuğu — kalan
    /// oran. Diğer modlarda `nil`, çubuk hiç çizilmiyor.
    var wordTimeFraction: Double? {
        guard let limit = mode.perWordLimit, let deadline = wordDeadline else { return nil }
        return min(1, max(0, (remainingExact - deadline) / limit))
    }

    /// §09 §9: Hız Turu'nun tekrar oynama gerekçesi rekor kırmak; tur sonunda
    /// `YENİ REKOR` şeridi bunu okuyor. Kıyas değeri tur **biterken** alınıyor:
    /// skor, tur sonu ekranındaki düzeltmelerle hâlâ değişebiliyor.
    private(set) var rapidRecordToBeat = 0

    var isNewRapidRecord: Bool { mode == .rapid && score > rapidRecordToBeat }

    var correctAnswers: [Answer] { answers.filter(\.isCorrect) }
    var skippedAnswers: [Answer] { answers.filter { !$0.isCorrect } }

    /// §04 §3: son 10 saniyede sayaç `stateWarning`e dönüyor.
    var isInFinalTen: Bool { phase == .playing && remaining <= 10 }

    /// Forced-landscape faz eşlemesi (§09 §1). Pencere hep portrait kalır;
    /// `true` iken içerik `ForcedLandscapeContainer` ile 90° çizilir.
    var prefersLandscape: Bool {
        guard !playsInPortrait else { return false }
        switch phase {
        case .matchEnd: return false
        case .slate, .countdown, .playing, .paused, .roundEnd, .teamHandoff: return true
        }
    }

    /// §02 ekran 15: hatırlatıcı ilk 3 turda görünüyor.
    let showsInputHint: Bool

    private var pool: WordPool
    private var remainingExact: TimeInterval
    private var wordDeadline: TimeInterval?
    private var lastTickAt: Date?
    private var ticker: Task<Void, Never>?
    private var flashTask: Task<Void, Never>?
    private var roundStartedAt: Date?
    private var lastWarningSecond: Int?

    /// §04 §4.3: her maç bir film, her tur bir sahne. Tekil turlarda film tek
    /// sahnelik oluyor; kimlik yine de veriliyor ki arşiv tek kural işletsin.
    private let matchID = UUID().uuidString

    private let onExit: (Exit) -> Void

    // MARK: Kurulum

    init(
        mode: GameMode,
        deckIDs: [String],
        duration: Int,
        difficulty: CardDifficultyFilter,
        answerInput: AnswerInput,
        playsInPortrait: Bool,
        roundsPlayed: Int,
        match: TeamMatch? = nil,
        customCards: [Card] = [],
        onExit: @escaping (Exit) -> Void
    ) {
        self.mode = mode
        self.deckIDs = deckIDs
        self.customCards = customCards
        self.duration = duration
        self.baseDuration = duration
        self.match = match
        self.answerInput = playsInPortrait ? .touch : answerInput
        self.playsInPortrait = playsInPortrait
        self.showsInputHint = roundsPlayed < 3
        self.onExit = onExit

        // §04 §3: tur başında seçili destelerin kelimeleri karıştırılıyor,
        // `Set<String>` yerine kuyruk — de-duplication dilden bağımsız `k`
        // anahtarı üzerinden, kullanıcı ortada dil değiştirse bile bozulmuyor.
        // §05 §6: desteler ayrı kuyruklarda kalıyor, tek havuzda birleşmiyor.
        // §05 §7 + §09 §4: custom kaynak (Kelime Sepeti ya da custom deste) tek
        // kuyruk ve zorluk filtresine girmiyor — custom kartların `d` alanı yok.
        pool = customCards.isEmpty
            ? WordPool(byDeck: CardBank.shared.cardsByDeck(in: deckIDs, difficulty: difficulty))
            : WordPool(cards: customCards)

        remaining = duration
        remainingExact = TimeInterval(duration)
        // Eski "telefonu yatay çevir" kapısı yok: UI forced-landscape ile
        // çiziliyor, cihaz yön kilidine bağlı değil.
        phase = .slate
    }

    // MARK: Faz geçişleri

    /// §08 A2: turun onay ekranı. Klaketin kendi süresi `SlateView` içinde;
    /// model yalnızca hangi sürümün oynayacağını ve künyeyi veriyor.
    func beginSlate() {
        phase = .slate
        flash = nil
    }

    /// Klaket (ve varsa başlık kartı) bitti ya da dokunuşla atlandı.
    func finishSlate() {
        guard phase == .slate else { return }
        slateWasShown = true
        beginCountdown()
    }

    /// §04 §3: geri sayım teknik hazırlığı gizleyen ekran — motion baseline'ı,
    /// kelime havuzu ve replay kaydı burada hazırlanıyor.
    ///
    /// Duraklat sonrası `DEVAM ET` de buraya düşüyor (§09 §2) ama o yol yeni bir
    /// kayıt açmıyor: bir tur bir dosya. `resuming` ayrımı olmadan her duraklat
    /// arşive ikinci bir sahne bırakıyordu.
    func beginCountdown(resuming: Bool = false) {
        phase = .countdown
        countdownValue = 3
        flash = nil

        if resuming {
            ReplayRecorder.shared.resumeAfterPause()
        } else {
            ReplayRecorder.shared.start(replayContext)
        }

        if answerInput == .tilt {
            MotionService.shared.beginCalibration()
        }
        Haptics.prepareImpact()
        Haptics.prepareNotification()

        startTicker(interval: 1) { [weak self] in
            guard let self else { return }
            countdownValue -= 1
            if countdownValue <= 0 {
                startPlaying()
            } else {
                Haptics.countdownTick()
                SoundService.countdownTick()
            }
        }
        Haptics.countdownTick()
        SoundService.countdownTick()
    }

    /// §08 §0: geri sayım atlanamayan tek animasyon. Dokunmak kalan süreyi
    /// **1 saniyeye indiriyor**, sıfırlamıyor — o 1 saniye hazırlığın
    /// tamamlanması için ayrılıyor. Sabırsız kullanıcı tam olarak bu ekrana
    /// dokunacak kişi, o yüzden ayrım önemli.
    func shortenCountdown() {
        guard phase == .countdown, countdownValue > 1 else { return }
        countdownValue = 1
        startTicker(interval: 1) { [weak self] in
            self?.startPlaying()
        }
    }

    private func startPlaying() {
        phase = .playing
        roundStartedAt = Date()
        lastWarningSecond = nil

        if answerInput == .tilt {
            MotionService.shared.startDetecting { [weak self] trigger in
                self?.answer(isCorrect: trigger == .correct)
            }
        }

        advanceCard()
        startRoundClock()
        // §04 §5: oyun ekranı boyunca çok kısık döngü.
        SoundService.startProjector()
        logRoundStart()

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-AutoScore") {
            startDebugAutoScore()
        }
        #endif
    }

    private func logRoundStart() {
        Analytics.roundStart(mode: mode.id, deckIDs: deckIDs, duration: duration)

        // §03 §2: günlük bedava destenin ölçümü `daily_free_deck_play` ile o
        // günden gelen `paywall_view` oranı. Premium kullanıcıda deste zaten
        // açık, oynaması rotasyonun işe yaradığını göstermiyor.
        if !SubscriptionStore.shared.isPremium,
           let daily = DeckCatalog.dailyFreeDeckID(),
           deckIDs.contains(daily) {
            Analytics.dailyFreeDeckPlay(deckID: daily)
        }
    }

    #if DEBUG
    /// Simülatörde tilt ve dokunuş yok; tur sonu ekranını gerçek cevaplarla
    /// doğrulamak için aralıklı otomatik skor üretiyor.
    ///
    /// Cevap sayısı sabit: süre dolana kadar üretmek her turda farklı bir skor
    /// bırakıyordu ve takım maçı hiç berabere kalmadığı için ani ölüm turu
    /// simülatörde hiç görülemiyordu.
    private func startDebugAutoScore() {
        Task { [weak self] in
            var flip = false
            var produced = 0
            while !Task.isCancelled, produced < 8 {
                try? await Task.sleep(for: .milliseconds(700))
                guard let self, phase == .playing, flash == nil else { continue }
                flip.toggle()
                answer(isCorrect: flip)
                produced += 1
            }
        }
    }
    #endif

    // MARK: Cevap

    func answer(isCorrect: Bool) {
        guard phase == .playing, flash == nil, let card = currentCard else { return }

        let offset = roundStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        answers.append(Answer(card: card, isCorrect: isCorrect, offset: offset))
        // §04 §4.1: zaman çizelgesi işaretleri ve altyazı bu damgadan üretiliyor.
        ReplayRecorder.shared.mark(
            word: card.text(for: LocalizationManager.shared.localeCode),
            key: card.k,
            isCorrect: isCorrect
        )

        if isCorrect {
            Haptics.answerCorrect()
            SoundService.correct()
        } else {
            Haptics.answerSkip()
            SoundService.skip()
        }

        flash = isCorrect ? .correct : .skip
        // §04 §2: cevap anında motion güncellemesi durur, animasyon bitince
        // yeniden başlar. Aksi hâlde animasyon sırasında ikinci tetik geliyor.
        MotionService.shared.suspend()

        flashTask?.cancel()
        flashTask = Task { [weak self] in
            // §04 §2: geri bildirim 0.45s, sonra sonraki kelime.
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled, let self, phase == .playing else { return }
            flash = nil
            advanceCard()
            MotionService.shared.resume()
        }
    }

    private func advanceCard() {
        currentCard = pool.next()
        didWrapPool = pool.didWrap

        if let limit = mode.perWordLimit {
            wordDeadline = remainingExact - limit
        }

        // §09 §4'ün kapsamadığı tek durum: havuz baştan boş. İçeriği üretilmemiş
        // deste seçildiyse tur başlamadan biter; PlayBar bunu zaten engelliyor
        // (§10 §4) ama tek savunma hattı bırakmıyoruz.
        if currentCard == nil {
            endRound()
            return
        }
        // §01 §4.1: kelime geçişi haptik almıyor; ses alıyor (§04 §5).
        SoundService.cardSlide()
    }

    // MARK: Süre

    private func startRoundClock() {
        lastTickAt = Date()
        startTicker(interval: 0.1) { [weak self] in
            self?.tick()
        }
    }

    private func tick() {
        guard phase == .playing else { return }

        let now = Date()
        let elapsed = now.timeIntervalSince(lastTickAt ?? now)
        lastTickAt = now
        remainingExact = max(0, remainingExact - elapsed)

        let seconds = Int(remainingExact.rounded(.up))
        if seconds != remaining {
            remaining = seconds
            // §04 §3: son 10 saniye, her saniye hafif haptic + tik sesi.
            if seconds <= 10, seconds > 0, lastWarningSecond != seconds {
                lastWarningSecond = seconds
                Haptics.warningTick()
                SoundService.warningTick()
            }
        }

        // §04 §1: Hız Turu'nda kelime başına 5 saniye, dolarsa otomatik PAS.
        if let deadline = wordDeadline, remainingExact <= deadline, flash == nil {
            answer(isCorrect: false)
            return
        }

        if remainingExact <= 0 {
            Haptics.timeUp()
            SoundService.timeUp()
            endRound()
        }
    }

    // MARK: Duraklat — §04 §3, §09 §2–3

    /// §09 §3: üstten aşağı sürükleme jesti **başladığı anda** motion tetikleri
    /// kilitleniyor. Telefonu alından indirmek kaçınılmaz olarak 40°'yi geçiyor;
    /// bu kilit olmadan duraklatmadan önce istemsiz bir DOĞRU/PAS kaydediliyor.
    func lockTriggersForPauseGesture() {
        MotionService.shared.lockForPauseGesture()
    }

    func pause(reason: PauseReason) {
        // Klaket de duraklatılabilir olmak zorunda: sürelerini `SlateView`
        // `Task.sleep` ile sayıyor ve o uyku arka planda da işliyor. Faz burada
        // durmazsa uygulama arka plandayken tur kendiliğinden başlıyor.
        guard phase == .playing || phase == .countdown || phase == .slate else { return }
        pauseReason = reason
        phase = .paused
        flash = nil
        flashTask?.cancel()
        stopTicker()
        MotionService.shared.suspend()
        SoundService.stopProjector()

        // §09 §2: sistem kesintisinde dosya o ana kadarki içerikle kapanıyor ve
        // kayıt "kısmi" işaretleniyor. Kullanıcı duraklatmasında ise kayıt
        // duruyor ama dosya açık kalıyor — tur bir bütün.
        if reason == .system {
            ReplayRecorder.shared.interrupt()
        } else {
            ReplayRecorder.shared.pauseForUser()
        }
    }

    /// §09 §2: otomatik devam **yok** — kullanıcının telefonu alnına geri koyacak
    /// zamanı olmalı. `DEVAM ET` yeni bir 3 saniyelik geri sayım ve **yeniden
    /// kalibrasyon** başlatıyor.
    func resume() {
        guard phase == .paused else { return }
        beginCountdown(resuming: true)
    }

    /// §09 §3: o turun skoru sıfırlanır, kelime havuzu tazelenir.
    /// §09 §3 Duraklat → `YENİDEN`: aynı sahnenin yeni çekimi.
    func restartRound() {
        takeIndex += 1
        resetRound()
        beginSlate()
    }

    private func resetRound() {
        stopTicker()
        flashTask?.cancel()
        flash = nil
        // §09 §3: yarım tur videosu arşivi kirletiyor.
        ReplayRecorder.shared.discard()
        reel = nil
        answers.removeAll()
        pool.reset()
        didWrapPool = false
        currentCard = nil
        remaining = duration
        remainingExact = TimeInterval(duration)
        wordDeadline = nil
    }

    /// §09 §3: Klasik/Hız/Canlandır/Mix'te tur iptal, ana ekrana dönüş.
    /// Takım Savaşı'nda maçın tamamı iptal oluyor — onay metni bu yüzden
    /// `PauseOverlay`de moda göre ayrışıyor.
    func exit() {
        leave(.home)
    }

    /// §02 §3: maç sonundaki `TEKRAR OYNA` Takım Kurulumu'na dönüyor —
    /// takımlar kurulu, tek dokunuşla yeni maç.
    func rematch() {
        leave(.teamRematch)
    }

    func openArchive() {
        leave(.archive)
    }

    private func leave(_ route: Exit) {
        commitRapidScore()
        teardown()
        onExit(route)
    }

    // MARK: Tur sonu

    private func endRound() {
        stopTicker()
        flashTask?.cancel()
        flash = nil
        phase = .roundEnd
        rapidRecordToBeat = AppSettingsStore.shared.rapidHighScore
        // Tur bitti: sensör kapanıyor, skor ekranı dokunmatik.
        MotionService.shared.stop()
        SoundService.stopProjector()
        // §04 §4.1: kayıt tur bitiminde duruyor. Dosyanın kapanması bir anlık
        // iş; `REPLAY'İ İZLE` butonu kapandıktan sonra beliriyor.
        Task { [weak self] in
            let reel = await ReplayRecorder.shared.finish()
            self?.reel = reel
            if reel != nil { self?.matchHasReels = true }
        }
        // §02 ekran 15 / §08 §0: tilt hatırlatıcısı ve öğretici bezemeler
        // 3. turdan sonra kısalıyor — sayaç burada ilerliyor.
        AppSettingsStore.shared.recordRoundPlayed()

        // §03 §5: skor tur sonu ekranındaki düzeltmelerle hâlâ değişebiliyor
        // ama event burada kalıyor — düzeltmeyi beklemek `round_complete`i
        // ekrandan çıkışa bağlar ve uygulama kapatılan turlar hiç sayılmaz.
        Analytics.roundComplete(
            mode: mode.id,
            deckIDs: deckIDs,
            duration: duration,
            correct: correctAnswers.count,
            skipped: skippedAnswers.count
        )

        #if DEBUG
        // Simülatörde dokunuş yok; maçın tamamını (perde arası, ani ölüm,
        // jenerik) uçtan uca görebilmek için sıra kendiliğinden ilerliyor.
        if match != nil, ProcessInfo.processInfo.arguments.contains("-AutoScore") {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                self?.finishTeamTurn()
            }
        }
        #endif
    }

    /// §02 ekran 17: yanlış işaretlenen kelimeye dokunarak düzeltme.
    /// Parti oyunlarında kritik — "o aslında doğruydu!".
    func toggleAnswer(_ id: String) {
        guard let index = answers.firstIndex(where: { $0.id == id }) else { return }
        answers[index].isCorrect.toggle()
        Haptics.selection()

        // §09 §9: düzeltme replay damgasını da çevirmek zorunda; yoksa kullanıcı
        // "doğru" diye düzelttiği kelimeyi replay'de kırmızı `PAS` damgasıyla
        // görüyor.
        guard var reel else { return }
        if let markIndex = reel.marks.firstIndex(where: { $0.key == id }) {
            reel.marks[markIndex].isCorrect = answers[index].isCorrect
            self.reel = reel
            ReplayStore.save(reel)
        }
    }

    /// §04 §4.4: oynatıcıdaki `Sil`. Dosya da metadata da gidiyor, tur sonu
    /// ekranındaki buton kayboluyor.
    func deleteReel() {
        guard let reel else { return }
        Analytics.replayDelete()
        ReplayStore.delete(id: reel.id)
        self.reel = nil
    }

    /// §02 §3: uygulamanın en yüksek frekanslı aksiyonu.
    func playAgain() {
        commitRapidScore()
        // Yeni tur yeni sahne: klaketin çekim sayacı başa dönüyor, sahne
        // numarası ilerliyor. `YENİDEN` ile ayrımı olan tek yer burası.
        soloRoundIndex += 1
        takeIndex = 1
        resetRound()
        beginSlate()
    }

    /// Skor tur sonu ekranında düzeltmelerle değişebildiği için rekor, ekrandan
    /// **çıkılırken** yazılıyor.
    private func commitRapidScore() {
        guard phase == .roundEnd, mode == .rapid else { return }
        AppSettingsStore.shared.recordRapidScore(score)
    }

    // MARK: Takım Savaşı — §04 §1, §09 §5

    /// Son turda buton `MAÇI BİTİR` oluyor. Beraberlik çıkarsa arkasından ani
    /// ölüm perde arası geliyor; o ekran kendini zaten açıklıyor.
    var isFinalTeamTurn: Bool {
        guard let match else { return false }
        return !match.isSuddenDeath && match.completedTurns + 1 >= match.totalTurns
    }

    /// Tur sonu ekranındaki `SIRADAKİ TAKIM`. Puan maça **burada** yazılıyor:
    /// o ana kadar ekrandaki düzeltmeler skoru hâlâ değiştirebiliyor.
    func finishTeamTurn() {
        guard phase == .roundEnd, let match else { return }

        switch match.finishTurn(
            correct: correctAnswers.count,
            skipped: skippedAnswers.count,
            points: score
        ) {
        case .turn(let team, let player):
            duration = match.isSuddenDeath ? TeamMatch.suddenDeathDuration : baseDuration
            phase = .teamHandoff(nextTeam: team, nextPlayer: player)
            startHandoffCountdown()

        case .matchEnd:
            teardown()
            phase = .matchEnd
            Haptics.matchWon()
            SoundService.winFanfare()
        }
    }

    /// §08 B2: `HAZIRIM` ya da 5 saniyenin dolması.
    func beginTeamTurn() {
        guard case .teamHandoff = phase else { return }
        takeIndex = 1
        resetRound()
        beginSlate()
    }

    private func startHandoffCountdown(seconds: Int = 5) {
        handoffCountdown = seconds
        startTicker(interval: 1) { [weak self] in
            guard let self, case .teamHandoff = phase else { return }
            handoffCountdown -= 1
            if handoffCountdown <= 0 { beginTeamTurn() }
        }
    }

    // MARK: Kesinti — §09 §2

    /// `scenePhase != .active`: arka plan, gelen çağrı, ekran kilidi.
    ///
    /// Genel ilke §09 §2: **hiçbir kesinti tur sonuçlarını yok etmiyor.**
    /// Duraklat yeterli — timer ve motion duruyor, cevaplar duruyor.
    func handleSceneInactive() {
        // Perde arası sayacı arka planda akmıyor: telefon elden ele geçerken
        // uygulamadan çıkılırsa tur kendiliğinden başlamamalı.
        if case .teamHandoff = phase {
            stopTicker()
            return
        }
        pause(reason: .system)
    }

    func handleSceneActive() {
        guard case .teamHandoff = phase, handoffCountdown > 0 else { return }
        startHandoffCountdown(seconds: handoffCountdown)
    }

    private func teardown() {
        stopTicker()
        flashTask?.cancel()
        MotionService.shared.stop()
        SoundService.stopProjector()
        // §09 §3: tur ortasında çıkıldıysa kayıt siliniyor. Tur sonundan
        // çıkışta ortada kayıt kalmıyor, çağrı boşa gidiyor.
        ReplayRecorder.shared.discard()
    }

    /// Kaydın künyesi. Deste adı çözülmemiş kimliklerle gidiyor: arşiv başka bir
    /// dilde açılabiliyor (§06 §2).
    private var replayContext: ReplayRecorder.Context {
        ReplayRecorder.Context(
            matchID: matchID,
            sceneIndex: (match?.results.count ?? 0) + 1,
            deckIDs: customCards.isEmpty ? deckIDs : [],
            modeID: mode.id,
            // Sırayı `TeamMatch` tutuyor ve ilk tur da dahil hep dolu; perde
            // arasından okunduğunda ilk sahne adsız kalıyordu.
            playerName: match?.currentPlayer
        )
    }

    // MARK: Ticker

    /// Tek bir tekrarlayan görev; her faz kendi aralığıyla yeniden kuruyor.
    /// `Timer` yerine `Task` çünkü `LiveGame` `@MainActor` ve iptal semantiği
    /// faz geçişlerinde daha okunaklı.
    private func startTicker(interval: TimeInterval, _ body: @escaping () -> Void) {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled, self != nil else { return }
                body()
            }
        }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }
}
