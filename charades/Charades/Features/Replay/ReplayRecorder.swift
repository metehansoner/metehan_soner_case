import AVFoundation
import Observation
import UIKit

/// Tur kaydının durum makinesi — 04-oyun-modlari.md §4.1, §09 §2–3.
///
/// Kayıt geri sayımda başlıyor, tur bitiminde duruyor ve tam olarak bir tur =
/// bir dosya. Duraklat, gelen çağrı, ısınma ve çıkış bu kuralı bozmadan
/// yönetiliyor: hiçbiri ikinci bir dosya açmıyor, hiçbiri yarım bir dosya
/// bırakmıyor.
@MainActor
@Observable
final class ReplayRecorder {
    static let shared = ReplayRecorder()

    /// Kaydın neden yapılmadığı. "Kapalı" ile "izin yok" aynı sonucu veriyor
    /// ama ayarlar ekranında bambaşka iki satır gösteriyor.
    enum Availability: Equatable {
        case ready
        case off
        case locked
        case denied
        case noCamera
        /// §09 §2: düşük güç, ısınma, disk.
        case limited(DeviceConditions.Limit)
    }

    /// Kaydın turdan gelen künyesi. Deste adı **çözülmüş hâliyle değil**
    /// kimlikleriyle taşınıyor: arşiv başka bir dilde açılabiliyor.
    struct Context {
        let matchID: String
        let sceneIndex: Int
        let deckIDs: [String]
        let modeID: String
        let playerName: String?
    }

    /// §04 §4.1: önizleme yok, yalnızca küçük bir kırmızı kayıt noktası.
    private(set) var isRecording = false

    /// §09 §2: "kullanıcıya bir kez bilgi verilir". Gösteren taraf okuduktan
    /// sonra `clearNotice()` ile siliyor.
    private(set) var noticeKey: String?

    private var engine: (any ReplayCaptureEngine)?
    private var draft: Draft?
    private var thermalWatch: Task<Void, Never>?
    private var finishContinuation: CheckedContinuation<Void, Never>?

    private struct Draft {
        let id: String
        let url: URL
        let context: Context
        let createdAt: Date
        /// Motor ilk kareyi yazdığı an. `startRecording` çağrısı ile gerçek
        /// başlangıç arasında ölçülemeyen bir gecikme var; damgalar bu ana göre.
        var videoStartedAt: Date?
        /// Duraklatılmış aralıkları dışarıda bırakan birikmiş video saati.
        var elapsed: TimeInterval = 0
        var marks: [ReplayReel.Mark] = []
        var isPartial = false
        var isUsable = false
    }

    private init() {}

    // MARK: Uygunluk

    var availability: Availability {
        guard AppSettingsStore.shared.replayEnabled else { return .off }
        // §09 §7: abonelik düşerse arşiv salt-okunur oluyor, yeni kayıt yok.
        guard SubscriptionStore.shared.isPremium else { return .locked }

        guard hasCaptureDevice else { return .noCamera }
        // İzin henüz sorulmadıysa da kayıt yok: izni tur başlarken istemek
        // telefonu alnına götürmüş kullanıcının önüne sistem diyaloğu koyar.
        // Soru ayarlarda, anahtar açılırken soruluyor (§06 §1).
        guard isCameraAuthorized else { return .denied }
        if let limit = DeviceConditions.recordingLimit() { return .limited(limit) }
        return .ready
    }

    static var cameraAuthorization: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    /// Ayarlardaki anahtar açılırken çağrılıyor. §04 §4.5: gizlilik bilgi
    /// ekranı bu çağrıdan **önce** gösteriliyor.
    static func requestCameraAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    // MARK: Kayıt

    /// Geri sayımın başında. İkinci kez çağrılması sessizce yok sayılıyor:
    /// `beginCountdown` duraklat sonrası da çalışıyor (§09 §2).
    func start(_ context: Context) {
        guard draft == nil else { return }

        switch availability {
        case .ready:
            break
        case .limited(let limit):
            // §09 §2: engel sessizce geçilmiyor, sebebi bir kez söyleniyor.
            noticeKey = limit.noticeKey
            return
        case .off, .locked, .denied, .noCamera:
            return
        }

        guard ReplayStore.prepareDirectory() != nil, let engine = captureEngine() else { return }

        let id = UUID().uuidString
        let url = ReplayStore.videoURL(for: id)
        draft = Draft(id: id, url: url, context: context, createdAt: .now)
        isRecording = true

        engine.start(
            to: url,
            rotationAngle: Self.rotationAngle(),
            // Turu yeniden başlatmak eski kaydı kapatıp yenisini hemen açıyor;
            // kapanan kaydın geri çağrısı yeni taslağın üstüne düşmesin diye
            // her haber kendi kaydının kimliğiyle geliyor.
            events: ReplayCaptureEvents(
                didStart: { [weak self] in
                    Task { @MainActor in self?.handleDidStart(id: id) }
                },
                wasInterrupted: { [weak self] in
                    Task { @MainActor in self?.interrupt(id: id) }
                },
                didFinish: { [weak self] isUsable in
                    Task { @MainActor in self?.handleDidFinish(id: id, isUsable: isUsable) }
                }
            )
        )

        startThermalWatch()
    }

    /// §04 §4.1: doğru/pas anları zaman damgası olarak kaydediliyor; oynatıcıdaki
    /// zaman çizelgesi işaretleri ve altyazı buradan üretiliyor.
    func mark(word: String, key: String, isCorrect: Bool) {
        guard isRecording, draft?.videoStartedAt != nil else { return }
        // Damganın zamanı `draft`a yazmadan **önce** okunuyor: aynı ifadede hem
        // okuyup hem yazmak Swift'in özel erişim kuralını çiğniyor.
        let time = videoTime
        draft?.marks.append(
            ReplayReel.Mark(time: time, isCorrect: isCorrect, word: word, key: key)
        )
    }

    /// Kullanıcı duraklattı. iOS 18'de video saati de duruyor; öncesinde kayıt
    /// dönmeye devam ediyor (dosyada ölü saniyeler kalıyor ama damgalar yine
    /// video saatiyle tutarlı).
    func pauseForUser() {
        guard isRecording, let engine, engine.pausesCleanly, draft?.videoStartedAt != nil else { return }
        engine.pause()
        let elapsed = videoTime
        draft?.elapsed = elapsed
        draft?.videoStartedAt = nil
    }

    func resumeAfterPause() {
        guard isRecording, let engine, engine.pausesCleanly, draft != nil,
              draft?.videoStartedAt == nil else { return }
        engine.resume()
        draft?.videoStartedAt = .now
    }

    /// §09 §2: arka plan, gelen çağrı, ekran kilidi ve ısınma. Dosya o ana kadar
    /// yazılanla kapanıyor, tur devam ediyor, kayıt "kısmi" işaretleniyor.
    func interrupt() {
        guard isRecording else { return }
        draft?.isPartial = true
        engine?.stop()
    }

    private func interrupt(id: String) {
        guard draft?.id == id else { return }
        interrupt()
    }

    /// Tur sonu. Dosya kapanana kadar bekleyip metadata'yı yazıyor.
    func finish() async -> ReplayReel? {
        guard draft != nil else { return nil }

        if isRecording {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                finishContinuation = continuation
                engine?.stop()
                // Motor haber vermezse tur sonu ekranı kilitlenmesin.
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(3))
                    self?.resumeFinishContinuation()
                }
            }
        }

        stopThermalWatch()
        engine?.shutdown()

        guard let draft else { return nil }
        self.draft = nil

        guard draft.isUsable else {
            ReplayStore.delete(id: draft.id)
            return nil
        }

        let reel = ReplayReel(
            id: draft.id,
            createdAt: draft.createdAt,
            matchID: draft.context.matchID,
            sceneIndex: draft.context.sceneIndex,
            duration: draft.elapsed,
            deckIDs: draft.context.deckIDs,
            modeID: draft.context.modeID,
            playerName: draft.context.playerName,
            marks: draft.marks,
            isPartial: draft.isPartial,
            isPinned: false
        )
        ReplayStore.save(reel)
        // §04 §4.2: kota yeni kayıt eklendiği anda işliyor. Açılışa bırakılsaydı
        // uzun bir maç arşivi kotanın iki katına çıkarabilirdi. Kota bu kaydı
        // yediyse tur sonu ekranına `REPLAY'İ İZLE` koymanın anlamı yok.
        ReplayStore.enforcePolicy(retention: AppSettingsStore.shared.replayRetention)
        return ReplayStore.reel(id: reel.id)
    }

    /// §09 §3: turu yeniden başlatmak ya da çıkmak kaydı siliyor — yarım tur
    /// videosu arşivi kirletiyor.
    func discard() {
        guard let draft else { return }
        self.draft = nil
        isRecording = false
        stopThermalWatch()
        engine?.stop()
        engine?.shutdown()
        // Dosya motor tarafından hâlâ kapatılıyor olabilir; silme çağrısı
        // kapandıktan sonra da geçerli.
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            ReplayStore.delete(id: draft.id)
        }
    }

    func clearNotice() { noticeKey = nil }

    // MARK: Motor geri çağrıları

    private func handleDidStart(id: String) {
        guard draft?.id == id else { return }
        draft?.videoStartedAt = .now
    }

    private func handleDidFinish(id: String, isUsable: Bool) {
        guard draft?.id == id else { return }
        isRecording = false
        let elapsed = videoTime
        draft?.elapsed = elapsed
        draft?.videoStartedAt = nil
        draft?.isUsable = isUsable
        resumeFinishContinuation()
    }

    private func resumeFinishContinuation() {
        guard let continuation = finishContinuation else { return }
        finishContinuation = nil
        continuation.resume()
    }

    // MARK: Yardımcılar

    private var videoTime: TimeInterval {
        guard let draft else { return 0 }
        return draft.elapsed + (draft.videoStartedAt.map { Date().timeIntervalSince($0) } ?? 0)
    }

    /// §04 §4.1: 10 tur arka arkaya oynanan takım maçında ısınma olabiliyor.
    /// `.serious` seviyesinde kayıt duruyor ve kullanıcı bilgilendiriliyor.
    private func startThermalWatch() {
        thermalWatch?.cancel()
        thermalWatch = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard let self, isRecording else { return }
                guard DeviceConditions.isThermallyThrottled else { continue }
                noticeKey = DeviceConditions.Limit.thermal.noticeKey
                interrupt()
                return
            }
        }
    }

    private func stopThermalWatch() {
        thermalWatch?.cancel()
        thermalWatch = nil
    }

    private var isCameraAuthorized: Bool {
        #if DEBUG
        if Self.usesSyntheticCapture { return true }
        #endif
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    private var hasCaptureDevice: Bool {
        #if DEBUG
        if Self.usesSyntheticCapture { return true }
        #endif
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
    }

    /// Motor turdan tura yaşıyor. Her turda yeni bir `AVCaptureSession` kurmak
    /// hem kamerayı baştan ısıtıyor hem de turu yeniden başlatırken kapanmakta
    /// olan oturumla yenisi aynı cihaza aynı anda uzanıyor.
    private func captureEngine() -> (any ReplayCaptureEngine)? {
        if let engine { return engine }
        engine = makeEngine()
        return engine
    }

    private func makeEngine() -> (any ReplayCaptureEngine)? {
        #if DEBUG
        if Self.usesSyntheticCapture { return SyntheticReplayCaptureEngine() }
        #endif
        return AVReplayCaptureEngine()
    }

    #if DEBUG
    /// Yalnızca kamera bulunmayan simülatörde ve yalnızca açıkça istendiğinde.
    static var usesSyntheticCapture: Bool {
        ProcessInfo.processInfo.arguments.contains("-FakeReplay")
            && AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) == nil
    }
    #endif

    /// Oyun `ForcedLandscapeContainer` (landscapeRight) ile çiziliyor; pencere
    /// ise OrientationLock yüzünden **hep portrait**. `interfaceOrientation`
    /// bu yüzden her zaman `.portrait` dönüyordu ve video 90° (dikey)
    /// damgalanıyordu — yatay kayda rağmen oynatıcıda dikey/yan görünüyordu.
    private static func rotationAngle() -> CGFloat {
        let device = UIDevice.current
        if !device.isGeneratingDeviceOrientationNotifications {
            device.beginGeneratingDeviceOrientationNotifications()
        }

        switch device.orientation {
        case .landscapeLeft:
            return 180
        case .landscapeRight:
            return 0
        case .portraitUpsideDown:
            return 270
        case .portrait:
            return 90
        case .faceUp, .faceDown, .unknown:
            // Alnında çoğu zaman faceUp/unknown — ForcedLandscape varsayılanı
            // (home sağda / landscapeRight).
            return 0
        @unknown default:
            return 0
        }
    }
}
