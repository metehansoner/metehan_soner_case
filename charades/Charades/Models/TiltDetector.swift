import Foundation


struct TiltDetector {

    enum Trigger: Equatable {
        case correct
        case skip
    }


    struct Thresholds {

        var arm: Double = 40


        var release: Double = 20


        var cooldown: TimeInterval = 0.4


        var recalibrateAfter: TimeInterval = 8

        var recalibrateStability: Double = 6

        var smoothingWindow = 3
    }

    var thresholds: Thresholds

    private var samples: [Double] = []
    private var isArmed = true
    private var lastTriggerTime: TimeInterval?
    private var lastTriggerOrStart: TimeInterval?

    private var driftSamples: [(time: TimeInterval, angle: Double)] = []

    private var lockedUntil: TimeInterval?


    private(set) var pendingBaselineShift: Double?

    private(set) var smoothedAngle: Double = 0

    init(thresholds: Thresholds = Thresholds()) {
        self.thresholds = thresholds
    }


    mutating func lockTriggers(at time: TimeInterval, for duration: TimeInterval = 0.6) {
        lockedUntil = time + duration
    }

    mutating func reset(at time: TimeInterval, rearm: Bool = true) {
        samples.removeAll()
        driftSamples.removeAll()
        isArmed = rearm
        lastTriggerTime = nil
        lastTriggerOrStart = time
        lockedUntil = nil
        pendingBaselineShift = nil
        smoothedAngle = 0
    }

    mutating func consumeBaselineShift() -> Double? {
        defer { pendingBaselineShift = nil }
        return pendingBaselineShift
    }


    mutating func update(angle: Double, at time: TimeInterval) -> Trigger? {
        samples.append(angle)
        if samples.count > thresholds.smoothingWindow {
            samples.removeFirst(samples.count - thresholds.smoothingWindow)
        }
        let smoothed = samples.reduce(0, +) / Double(samples.count)
        smoothedAngle = smoothed

        if lastTriggerOrStart == nil { lastTriggerOrStart = time }


        if !isArmed, abs(smoothed) < thresholds.release {
            isArmed = true
        }

        updateDrift(smoothed: smoothed, at: time)

        if let lockedUntil, time < lockedUntil { return nil }

        guard isArmed else { return nil }
        if let last = lastTriggerTime, time - last < thresholds.cooldown { return nil }
        guard abs(smoothed) > thresholds.arm else { return nil }

        isArmed = false
        lastTriggerTime = time
        lastTriggerOrStart = time
        driftSamples.removeAll()
        return smoothed > 0 ? .correct : .skip
    }


    private mutating func updateDrift(smoothed: Double, at time: TimeInterval) {
        guard let since = lastTriggerOrStart else { return }

        driftSamples.append((time, smoothed))
        driftSamples.removeAll { time - $0.time > thresholds.recalibrateAfter }

        guard time - since >= thresholds.recalibrateAfter else { return }
        guard abs(smoothed) >= thresholds.release else { return }

        let angles = driftSamples.map(\.angle)
        guard let minimum = angles.min(), let maximum = angles.max() else { return }

        guard maximum - minimum <= thresholds.recalibrateStability else { return }

        pendingBaselineShift = smoothed
        lastTriggerOrStart = time
        driftSamples.removeAll()
        samples.removeAll()
        smoothedAngle = 0


    }
}


struct BaselineCalibrator {

    var window = 10

    var stabilityDegrees: Double = 2.5

    private var samples: [Double] = []

    init(window: Int = 10, stabilityDegrees: Double = 2.5) {
        self.window = window
        self.stabilityDegrees = stabilityDegrees
    }

    mutating func reset() { samples.removeAll() }

    mutating func add(_ angle: Double) {
        samples.append(angle)
        if samples.count > window { samples.removeFirst(samples.count - window) }
    }


    var stableBaseline: Double? {
        guard samples.count >= window,
              let minimum = samples.min(),
              let maximum = samples.max(),
              maximum - minimum <= stabilityDegrees
        else { return nil }
        return samples.reduce(0, +) / Double(samples.count)
    }


    var fallbackBaseline: Double? { samples.last }
}
