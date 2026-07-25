import Foundation
import UIKit
import GoogleMobileAds

@MainActor
@Observable
final class RewardedAdService: NSObject {
    static let shared = RewardedAdService()

    /// Your AdMob rewarded unit.
    private let productionAdUnitID = "ca-app-pub-6002701312080831/5740187461"
    /// Google sample rewarded unit — reliable while your new unit warms up.
    private let testAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    private(set) var isLoading = false
    private(set) var lastErrorMessage: String?
    private var rewardedAd: RewardedAd?
    private var isSDKReady = false

    private override init() {
        super.init()
    }

    func startSDK() {
        #if DEBUG
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["GADSimulatorID"]
        #endif

        MobileAds.shared.start { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isSDKReady = true
                self.preload()
            }
        }
    }

    func preload() {
        guard isSDKReady, rewardedAd == nil, !isLoading else { return }
        Task {
            _ = try? await loadAd(preferProduction: true)
        }
    }

    /// Loads if needed, then presents. Calls `onRewarded` only when reward is earned.
    func show(onRewarded: @escaping () -> Void, onFailed: ((String) -> Void)? = nil) {
        Task {
            do {
                let ad = try await ensureLoadedAd()
                guard let root = Self.topViewController() else {
                    onFailed?("Unable to present ad.")
                    return
                }
                rewardedAd = nil
                ad.present(from: root) {
                    onRewarded()
                }
            } catch {
                lastErrorMessage = error.localizedDescription
                onFailed?(friendlyMessage(for: error))
                preload()
            }
        }
    }

    private func ensureLoadedAd() async throws -> RewardedAd {
        if let rewardedAd { return rewardedAd }
        return try await loadAd(preferProduction: true)
    }

    @discardableResult
    private func loadAd(preferProduction: Bool) async throws -> RewardedAd {
        if isLoading {
            // Wait briefly for in-flight load.
            for _ in 0..<40 {
                try? await Task.sleep(for: .milliseconds(100))
                if let rewardedAd { return rewardedAd }
                if !isLoading { break }
            }
        }

        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        let primaryID = preferProduction ? productionAdUnitID : testAdUnitID
        do {
            let ad = try await RewardedAd.load(with: primaryID, request: Request())
            ad.fullScreenContentDelegate = self
            rewardedAd = ad
            return ad
        } catch {
            // New production units often fail for a while — fall back to Google test ads in DEBUG.
            #if DEBUG
            if preferProduction {
                let ad = try await RewardedAd.load(with: testAdUnitID, request: Request())
                ad.fullScreenContentDelegate = self
                rewardedAd = ad
                return ad
            }
            #endif
            lastErrorMessage = error.localizedDescription
            rewardedAd = nil
            throw error
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        let text = error.localizedDescription
        if text.localizedCaseInsensitiveContains("not ready")
            || text.localizedCaseInsensitiveContains("no ad")
            || text.localizedCaseInsensitiveContains("no fill") {
            return "Ad is loading. Please try again in a moment."
        }
        return text
    }

    private static func topViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
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
