import SwiftUI
import UIKit

/// Ekran 13 — 02-ekran-akisi.md §4.
///
/// Tek ilerleme koşulu cihazın **fiziksel olarak** yatay gelmesi; buton yok.
/// Arayüz bu fazda portrait kilitli olduğu için SwiftUI'ın boyut sınıfı
/// değişmiyor — cihaz yönü `UIDevice` bildiriminden okunuyor.
///
/// Alt kısımdaki `DOKUNMATİK OYNA` §09 §1'in düzeltmesi: eski hâlinde bu link
/// yalnızca **cevap yöntemini** değiştiriyordu, yön problemini çözmüyordu.
/// Yatakta oynayan, cihaz yön kilidi açık olan veya motor kısıtlı kullanıcı
/// için bu bir çıkmaz sokaktı. Artık tur portrait'te açılıyor.
struct OrientationPromptView: View {
    var onLandscape: () -> Void
    var onPlayInPortrait: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isTilted = false

    var body: some View {
        ZStack {
            VelvetBackground()

            VStack(spacing: 26) {
                phoneHint

                VStack(spacing: 12) {
                    Text(l10n.t("game.rotate.title"))
                        .textStyle(.screenTitle)
                        .foregroundStyle(AppColors.textCream)
                        .multilineTextAlignment(.center)

                    Text(l10n.t("game.rotate.body"))
                        .textStyle(.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                VStack(spacing: 7) {
                    Button(l10n.t("game.rotate.touchMode")) {
                        Haptics.secondaryButton()
                        onPlayInPortrait()
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Text(l10n.t("game.rotate.touchMode.hint"))
                        .textStyle(.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 280)
                .padding(.top, 6)
            }
            .padding(.horizontal, 40)
        }
        .task { await watchDeviceOrientation() }
    }

    /// Mockup'taki `rotHint`: dikeyden 90° sola dönüp geri gelen telefon.
    private var phoneHint: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppColors.surfaceCard.opacity(0.85))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.accentGold, lineWidth: 2.5)
            }
            .overlay(alignment: .top) {
                Capsule()
                    .fill(AppColors.accentGold.opacity(0.5))
                    .frame(width: 26, height: 4)
                    .padding(.top, 8)
            }
            .frame(width: 76, height: 142)
            .shadow(color: AppColors.accentAmber.opacity(0.3), radius: 17)
            .rotationEffect(.degrees(isTilted ? -90 : 0))
            .animation(
                reduceMotion
                    ? nil
                    : .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                value: isTilted
            )
            .onAppear { isTilted = true }
            .accessibilityHidden(true)
    }

    /// Arayüz portrait kilitliyken `horizontalSizeClass` değişmiyor, o yüzden
    /// ivmeölçer tabanlı cihaz yönü bildirimi dinleniyor.
    private func watchDeviceOrientation() async {
        let device = UIDevice.current
        device.beginGeneratingDeviceOrientationNotifications()
        defer { device.endGeneratingDeviceOrientationNotifications() }

        if device.orientation.isLandscape {
            onLandscape()
            return
        }

        let notifications = NotificationCenter.default.notifications(
            named: UIDevice.orientationDidChangeNotification
        )
        for await _ in notifications {
            if Task.isCancelled { return }
            if UIDevice.current.orientation.isLandscape {
                onLandscape()
                return
            }
        }
    }
}
