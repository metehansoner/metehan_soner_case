import AVFoundation
import Foundation


nonisolated struct ReplayCaptureEvents: Sendable {
    let didStart: @Sendable () -> Void


    let wasInterrupted: @Sendable () -> Void
    let didFinish: @Sendable (Bool) -> Void
}


nonisolated protocol ReplayCaptureEngine: AnyObject, Sendable {


    var pausesCleanly: Bool { get }

    func start(to url: URL, rotationAngle: CGFloat, events: ReplayCaptureEvents)
    func pause()
    func resume()
    func stop()
    func shutdown()
}


nonisolated final class AVReplayCaptureEngine: NSObject, ReplayCaptureEngine,
    AVCaptureFileOutputRecordingDelegate, @unchecked Sendable {


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


    func shutdown() {
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }


    private func configureIfNeeded() -> Bool {
        if isConfigured { return true }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device)
        else { return false }

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720


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


        let size = (try? outputFileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let isUsable = size > 0
        queue.async {
            let events = self.events
            self.events = nil
            events?.didFinish(isUsable)
        }
    }
}
