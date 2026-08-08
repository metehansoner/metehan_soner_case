import Foundation


enum DeviceConditions {

    enum Limit: String {

        case lowPower

        case thermal


        case storage

        var noticeKey: String { "replay.notice.\(rawValue)" }
    }


    static let minimumFreeBytes: Int64 = 200 * 1_000_000


    static func recordingLimit() -> Limit? {
        let info = ProcessInfo.processInfo
        if info.isLowPowerModeEnabled { return .lowPower }
        if isThermallyThrottled { return .thermal }
        if let free = freeBytes(), free < minimumFreeBytes { return .storage }
        return nil
    }


    static var isThermallyThrottled: Bool {
        ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
    }


    static func freeBytes() -> Int64? {
        let url = URL.applicationSupportDirectory
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage
    }
}
