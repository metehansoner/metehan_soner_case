import AVFoundation
import Observation
import UIKit


@MainActor
@Observable
final class ReplayRecorder {
    static let shared = ReplayRecorder()


    enum Availability: Equatable {
        case ready
        case off
        case locked
        case denied
        case noCamera

        case limited(DeviceConditions.Limit)
    }


    struct Context {
        let matchID: String
        let sceneIndex: Int
        let deckIDs: [String]
        let modeID: String
        let playerName: String?
    }


    private(set) var isRecording = false


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


        var videoStartedAt: Date?

        var elapsed: TimeInterval = 0
        var marks: [ReplayReel.Mark] = []
        var isPartial = false
        var isUsable = false
    }

    private init() {}


    var availability: Availability {
        guard AppSettingsStore.shared.replayEnabled else { return .off }

        guard SubscriptionStore.shared.isPremium else { return .locked }

        guard hasCaptureDevice else { return .noCamera }


        guard isCameraAuthorized else { return .denied }
        if let limit = DeviceConditions.recordingLimit() { return .limited(limit) }
        return .ready
    }

    static var cameraAuthorization: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }


    static func requestCameraAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }


    func start(_ context: Context) {
        guard draft == nil else { return }

        switch availability {
        case .ready:
            break
        case .limited(let limit):

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


    func mark(word: String, key: String, isCorrect: Bool) {
        guard isRecording, draft?.videoStartedAt != nil else { return }


        let time = videoTime
        draft?.marks.append(
            ReplayReel.Mark(time: time, isCorrect: isCorrect, word: word, key: key)
        )
    }


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


    func interrupt() {
        guard isRecording else { return }
        draft?.isPartial = true
        engine?.stop()
    }

    private func interrupt(id: String) {
        guard draft?.id == id else { return }
        interrupt()
    }


    func finish() async -> ReplayReel? {
        guard draft != nil else { return nil }

        if isRecording {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                finishContinuation = continuation
                engine?.stop()

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


        ReplayStore.enforcePolicy(retention: AppSettingsStore.shared.replayRetention)
        return ReplayStore.reel(id: reel.id)
    }


    func discard() {
        guard let draft else { return }
        self.draft = nil
        isRecording = false
        stopThermalWatch()
        engine?.stop()
        engine?.shutdown()


        Task {
            try? await Task.sleep(for: .milliseconds(400))
            ReplayStore.delete(id: draft.id)
        }
    }

    func clearNotice() { noticeKey = nil }


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


    private var videoTime: TimeInterval {
        guard let draft else { return 0 }
        return draft.elapsed + (draft.videoStartedAt.map { Date().timeIntervalSince($0) } ?? 0)
    }


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

    static var usesSyntheticCapture: Bool {
        ProcessInfo.processInfo.arguments.contains("-FakeReplay")
            && AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) == nil
    }
    #endif


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


            return 0
        @unknown default:
            return 0
        }
    }
}
