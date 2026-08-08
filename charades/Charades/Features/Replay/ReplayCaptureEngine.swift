import AVFoundation
import Foundation

/// Kayıt sırasında dışarıdan gelen üç haber. `ReplayRecorder` bunları ana
/// aktöre taşıyor; motor hangi kuyrukta çalıştığını bilmek zorunda değil.
/// Proje varsayılan olarak `MainActor` izolasyonunda (`SWIFT_DEFAULT_ACTOR_ISOLATION`);
/// kayıt kuyruğundan okunan her tip açıkça `nonisolated` olmak zorunda.
nonisolated struct ReplayCaptureEvents: Sendable {
    let didStart: @Sendable () -> Void
    /// §09 §2: gelen çağrı / kamera başka bir istemciye geçti. Tur devam ediyor,
    /// o turun replay'i "kısmi" işaretleniyor.
    let wasInterrupted: @Sendable () -> Void
    let didFinish: @Sendable (Bool) -> Void
}

/// Kayıt donanımını durum makinesinden ayıran ince katman.
///
/// İki sebeple protokol: `AVCaptureSession` ana aktörde çalıştırılamıyor
/// (`startRunning` blokluyor, oturum kurulumu saniyeler alabiliyor) ve
/// simülatörde ön kamera yok. Akışın kalanı — damgalar, tur sonu, dosya
/// yaşam döngüsü — tek kod yolunda kalsın diye ikisi aynı arayüzü uyguluyor.
nonisolated protocol ReplayCaptureEngine: AnyObject, Sendable {
    /// Video saatini gerçekten duraklatabiliyor mu. iOS 17'de
    /// `pauseRecording()` yok; o durumda kayıt duraklat overlay'i boyunca
    /// dönmeye devam ediyor ve damgalar yine video saatiyle tutarlı kalıyor.
    var pausesCleanly: Bool { get }

    func start(to url: URL, rotationAngle: CGFloat, events: ReplayCaptureEvents)
    func pause()
    func resume()
    func stop()
    func shutdown()
}

/// §04 §4.1: ön kamera, 720p, 30 fps, **ses yok**.
///
/// Ses girdisi bilinçli olarak eklenmiyor: mikrofon izni istemek zorunda
/// kalmadan aynı viral değeri veriyor ve `SoundService`in ambient oturumuna
/// dokunmuyor (`automaticallyConfiguresApplicationAudioSession = false`).
nonisolated final class AVReplayCaptureEngine: NSObject, ReplayCaptureEngine,
    AVCaptureFileOutputRecordingDelegate, @unchecked Sendable {

    /// Bütün oturum işleri bu kuyrukta; `queue` dışında hiçbir alan okunmuyor.
    private let queue = DispatchQueue(label: "com.charady.replay.capture")
    private let session = AVCaptureSession()
    private let output = AVCaptureMovieFileOutput()

    private var isConfigured = false
    private var events: ReplayCaptureEvents?
    private var observers: [NSObjectProtocol] = []

    var pausesCleanly: Bool {
        if #available(iOS 18.0, *) { return true }
        return false
    }

    func start(to url: URL, rotationAngle: CGFloat, events: ReplayCaptureEvents) {
        queue.async {
            guard self.configureIfNeeded() else {
                events.didFinish(false)
                return
            }
            self.events = events

            if !self.session.isRunning {
                self.session.startRunning()
            }

            if let connection = self.output.connection(with: .video),
               connection.isVideoRotationAngleSupported(rotationAngle) {
                connection.videoRotationAngle = rotationAngle
            }

            self.output.startRecording(to: url, recordingDelegate: self)
        }
    }

    func pause() {
        guard #available(iOS 18.0, *) else { return }
        queue.async {
            guard self.output.isRecording, !self.output.isRecordingPaused else { return }
            self.output.pauseRecording()
        }
    }

    func resume() {
        guard #available(iOS 18.0, *) else { return }
        queue.async {
            guard self.output.isRecordingPaused else { return }
            self.output.resumeRecording()
        }
    }

    func stop() {
        queue.async {
            guard self.output.isRecording else { return }
            self.output.stopRecording()
        }
    }

    /// Tur bittikten sonra oturum kapanıyor: açık kamera hem pil hem de
    /// durum çubuğundaki gizlilik göstergesi demek.
    func shutdown() {
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    // MARK: Oturum kurulumu

    private func configureIfNeeded() -> Bool {
        if isConfigured { return true }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device)
        else { return false }

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720
        // Ambient ses oturumunu kimse değiştirmesin: projektör döngüsü kayıt
        // başlarken susuyordu (§04 §5).
        session.automaticallyConfiguresApplicationAudioSession = false

        guard session.canAddInput(input), session.canAddOutput(output) else {
            session.commitConfiguration()
            return false
        }
        session.addInput(input)
        session.addOutput(output)
        session.commitConfiguration()

        if (try? device.lockForConfiguration()) != nil {
            let thirty = CMTime(value: 1, timescale: 30)
            device.activeVideoMinFrameDuration = thirty
            device.activeVideoMaxFrameDuration = thirty
            device.unlockForConfiguration()
        }

        observeInterruptions()
        isConfigured = true
        return true
    }

    /// §09 §2: kesinti haberi kaydın kendi hatasından önce geliyor; "kısmi"
    /// işareti buradan konuyor.
    private func observeInterruptions() {
        let center = NotificationCenter.default
        for name in [AVCaptureSession.wasInterruptedNotification, AVCaptureSession.runtimeErrorNotification] {
            let token = center.addObserver(forName: name, object: session, queue: nil) { [weak self] _ in
                guard let self else { return }
                queue.async { self.events?.wasInterrupted() }
            }
            observers.append(token)
        }
    }
}

extension AVReplayCaptureEngine {

    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        queue.async { self.events?.didStart() }
    }

    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        // Hata varken bile dosya oynatılabilir olabiliyor (kesintide o ana kadarki
        // örnekler yazılmış oluyor). Karar dosyanın kendisine bakılarak veriliyor:
        // §09 §2'nin "bozuk dosya bırakılmaz" ilkesi boş dosyayı da kapsıyor.
        let size = (try? outputFileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let isUsable = size > 0
        queue.async {
            let events = self.events
            self.events = nil
            events?.didFinish(isUsable)
        }
    }
}
