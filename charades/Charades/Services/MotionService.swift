import CoreMotion
import Foundation
import Observation
import UIKit


@MainActor
@Observable
final class MotionService {
    static let shared = MotionService()

    enum State: Equatable {
        case idle

        case calibrating
        case running

        case suspended
    }

    private(set) var state: State = .idle


    private(set) var angle: Double = 0


    var isAvailable: Bool { manager.isDeviceMotionAvailable }


    private(set) var isSilentTooLong = false

    private let manager = CMMotionManager()
    private var detector = TiltDetector()
    private var calibrator = BaselineCalibrator()


    private var sign: Double = 1
    private var baseline: Double = 0
    private var hasBaseline = false

    private var lastTriggerTime: TimeInterval = 0
    private var onTrigger: ((TiltDetector.Trigger) -> Void)?
    private var didPrepareForApproach = false

    private init() {}


    func beginCalibration() {
        guard isAvailable else { return }

        detector.reset(at: now)
        calibrator.reset()
        hasBaseline = false
        baseline = 0
        angle = 0
        isSilentTooLong = false
        state = .calibrating

        guard !manager.isDeviceMotionActive else { return }


        manager.deviceMotionUpdateInterval = 1.0 / 30
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) {
            [weak self] motion, _ in
            guard let self, let motion else { return }
            self.consume(motion)
        }
    }


    func startDetecting(onTrigger: @escaping (TiltDetector.Trigger) -> Void) {
        guard isAvailable else { return }

        if !hasBaseline {
            baseline = calibrator.stableBaseline ?? calibrator.fallbackBaseline ?? 0
            hasBaseline = true
        }
        self.onTrigger = onTrigger
        lastTriggerTime = now
        didPrepareForApproach = false
        detector.reset(at: now)
        state = .running
    }


    func suspend() {
        guard state == .running else { return }
        state = .suspended
    }

    func resume() {
        guard state == .suspended else { return }


        detector.reset(at: now, rearm: false)
        state = .running
    }


    func lockForPauseGesture() {
        detector.lockTriggers(at: now)
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        onTrigger = nil
        state = .idle
        angle = 0
        isSilentTooLong = false
    }


    private func consume(_ motion: CMDeviceMotion) {
        let raw = Self.rollDegrees(motion)

        if state == .calibrating {


            if abs(motion.gravity.x) > 0.5 {


                sign = motion.gravity.x > 0 ? 1 : -1
            }
            calibrator.add(raw * sign)
            angle = 0

            if let stable = calibrator.stableBaseline {
                baseline = stable
                hasBaseline = true
            }
            return
        }

        let calibrated = raw * sign - baseline

        guard state == .running else {


            angle = calibrated
            return
        }

        if let trigger = detector.update(angle: calibrated, at: now) {
            angle = detector.smoothedAngle
            lastTriggerTime = now
            isSilentTooLong = false
            onTrigger?(trigger)
            return
        }

        angle = detector.smoothedAngle


        let magnitude = abs(angle)
        if magnitude > detector.thresholds.release * 0.7,
           magnitude < detector.thresholds.arm {
            if !didPrepareForApproach {
                Haptics.prepareNotification()
                didPrepareForApproach = true
            }
        } else if magnitude < detector.thresholds.release {
            didPrepareForApproach = false
        }


        if let shift = detector.consumeBaselineShift() {
            baseline += shift
            angle = 0
        }


        isSilentTooLong = now - lastTriggerTime > 8
    }


    private static func rollDegrees(_ motion: CMDeviceMotion) -> Double {
        motion.attitude.roll * 180 / .pi
    }

    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }
}
