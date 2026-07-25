import Foundation
import UIKit
import GoogleMobileAds

enum AdMobConfig {
    /// `true` = Google sample rewarded ads (reliable for testing unlock flow).
    /// `false` = your production unit `category unlock`.
    static var useTestAds = true

    static let productionAppID = "ca-app-pub-6002701312080831~7057138562"
    static let productionRewardedUnitID = "ca-app-pub-6002701312080831/5740187461"

    /// Official Google sample rewarded unit.
    static let testRewardedUnitID = "ca-app-pub-3940256099942544/1712485313"

    static var activeRewardedUnitID: String {
        useTestAds ? testRewardedUnitID : productionRewardedUnitID
    }
}

@MainActor
@Observable
final class RewardedAdService: NSObject {
    static let shared = RewardedAdService()

    private(set) var isLoading = false
    private(set) var lastErrorMessage: String?
    private var rewardedAd: RewardedAd?
    private var isSDKReady = false
    private var loadTask: Task<RewardedAd, Error>?

    private override init() {
        super.init()
    }

    func startSDK() {
        MobileAds.shared.start { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isSDKReady = true
                self.preload()
            }
        }
    }

    func preload() {
        guard rewardedAd == nil, loadTask == nil else { return }
        loadTask = Task {
            defer { loadTask = nil }
            return try await performLoad()
        }
        Task {
            _ = try? await loadTask?.value
        }
    }

    /// Loads if needed, then presents. Calls `onRewarded` only when reward is earned.
    func show(onRewarded: @escaping () -> Void, onFailed: ((String) -> Void)? = nil) {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                await waitForSDK(timeoutMs: 8_000)
                let ad = try await ensureLoadedAd()
                guard let root = Self.topViewController() else {
                    onFailed?("Ekran hazır değil. Tekrar dene.")
                    return
                }

                rewardedAd = nil
                ad.present(from: root) {
                    onRewarded()
                }
            } catch {
                lastErrorMessage = error.localizedDescription
                onFailed?(Self.userFacingMessage(for: error))
                preload()
            }
        }
    }

    private func ensureLoadedAd() async throws -> RewardedAd {
        if let rewardedAd { return rewardedAd }

        if let loadTask {
            return try await loadTask.value
        }

        let task = Task {
            try await performLoad()
        }
        loadTask = task
        defer { loadTask = nil }
        return try await task.value
    }

    private func performLoad() async throws -> RewardedAd {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        let unitID = AdMobConfig.activeRewardedUnitID
        do {
            let ad = try await RewardedAd.load(with: unitID, request: Request())
            ad.fullScreenContentDelegate = self
            rewardedAd = ad
            return ad
        } catch {
            // If production unit has no fill yet, automatically try Google test ads.
            if !AdMobConfig.useTestAds {
                do {
                    let ad = try await RewardedAd.load(
                        with: AdMobConfig.testRewardedUnitID,
                        request: Request()
                    )
                    ad.fullScreenContentDelegate = self
                    rewardedAd = ad
                    return ad
                } catch {
                    lastErrorMessage = error.localizedDescription
                    rewardedAd = nil
                    throw error
                }
            }
            lastErrorMessage = error.localizedDescription
            rewardedAd = nil
            throw error
        }
    }

    private func waitForSDK(timeoutMs: Int) async {
        if isSDKReady { return }
        let steps = max(1, timeoutMs / 100)
        for _ in 0..<steps {
            if isSDKReady { return }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private static func userFacingMessage(for error: Error) -> String {
        let ns = error as NSError
        // Common Mobile Ads error codes
        switch ns.code {
        case 1: return "Reklam isteği geçersiz. Birim ID'sini kontrol et."
        case 2: return "Ağ hatası. İnterneti kontrol edip tekrar dene."
        case 3: return "Şu an reklam yok (no fill). Biraz sonra tekrar dene."
        default:
            let text = error.localizedDescription
            if text.isEmpty { return "Reklam yüklenemedi. Tekrar dene." }
            return text
        }
    }

    private static func topViewController(
        base: UIViewController? = {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let windows = scenes.flatMap(\.windows)
            return (windows.first { $0.isKeyWindow } ?? windows.first)?.rootViewController
        }()
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

extension RewardedAdService: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.rewardedAd = nil
            self.preload()
        }
    }

    nonisolated func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            self.lastErrorMessage = error.localizedDescription
            self.rewardedAd = nil
            self.preload()
        }
    }
}
