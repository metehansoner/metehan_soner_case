import SwiftUI

/// §04 §4.5 — kamera izninden **önce** gelen bilgi ekranı.
///
/// Bu özellik masadaki başka insanların yüzünü kaydediyor; tek kullanıcıdan izin
/// almak yeterli değil. Onay kutusu yok, sadece bilgilendirme — ama bu satır
/// etik olarak gerekli ve App Review'da da olumlu karşılanıyor.
struct ReplayPrivacySheet: View {
    var onContinue: () -> Void
    var onCancel: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        SheetScaffold(title: l10n.t("replay.privacy.title"), onClose: onCancel) {
            VStack(spacing: 18) {
                lens

                Text(l10n.t("replay.privacy.body"))
                    .font(AppFont.ui(14))
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(AppColors.textCream)

                Text(l10n.t("replay.privacy.note"))
                    .font(AppFont.ui(11.5))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(AppColors.textMuted)

                Spacer(minLength: 0)

                Button(l10n.t("replay.privacy.continue")) {
                    Haptics.primaryButton()
                    onContinue()
                }
                .buttonStyle(MarqueeButtonStyle())

                Button(l10n.t("common.cancel")) {
                    Haptics.secondaryButton()
                    onCancel()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 22)
        }
        // Sabit yükseklik yerine oran: gövde metni uzun dillerde (de, ar) iki
        // satır daha büyüyor ve sabit detent metni tek satıra sıkıştırıyor.
        .presentationDetents([.fraction(0.58)])
    }

    /// Objektif: ortada mercek, çevresinde film şeridi halkası.
    private var lens: some View {
        ZStack {
            Circle()
                .strokeBorder(AppColors.accentGold.opacity(0.4), lineWidth: 1)
                .frame(width: 84, height: 84)

            Circle()
                .fill(AppColors.surfaceCardRaised)
                .frame(width: 62, height: 62)

            Image(systemName: "person.2.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(AppColors.accentAmber)
        }
        .padding(.top, 4)
    }
}
