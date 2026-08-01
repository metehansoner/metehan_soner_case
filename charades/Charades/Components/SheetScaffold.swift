import SwiftUI

/// Sheet iskeleti — `ornek-ekranlar.html` `.sheet` / `.grabber` / `.sheet-head`.
///
/// Kurulum sheet'i (mod + tur ayarı) ve Nasıl Oynanır aynı sheet iskeletini
/// paylaşıyor: adım değişince yalnızca içerik geçiş yapıyor, sheet yeniden
/// açılmıyor.
struct SheetScaffold<Content: View>: View {
    let title: String
    /// Zincirin ilk adımında yok; sonraki adımlarda sola dönüş.
    var onBack: (() -> Void)?
    /// Yoksa çarpı gizlenir — saf sheet'lerde (Ayarlar) grabber yeter.
    var onClose: (() -> Void)?
    @ViewBuilder var content: Content

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppColors.accentGold.opacity(0.6))
                .frame(width: 38, height: 4)
                .padding(.top, 9)

            HStack(spacing: 10) {
                if let onBack {
                    circleButton(systemImage: "chevron.left", label: l10n.t("common.back"), action: onBack)
                }

                Text(title)
                    .font(AppFont.display(21, weight: .bold))
                    .appTracking(2.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                if let onClose {
                    circleButton(systemImage: "xmark", label: l10n.t("common.close"), action: onClose)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 16)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x4A1720), location: 0),
                    .init(color: AppColors.bgVelvetDeep, location: 0.26),
                    .init(color: AppColors.surfaceCard, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppColors.accentGold.opacity(0.5))
                    .frame(height: 1)
            }
            .overlay { GrainOverlay() }
            .ignoresSafeArea()
        }
        .presentationCornerRadius(28)
        .presentationBackground(.clear)
        .localizedLayout()
    }

    private func circleButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.secondaryButton()
            action()
        } label: {
            Image(systemName: systemImage)
                // §06 §2: geri oku RTL'de aynalanıyor, kapatma çarpısı simetrik.
                .flipsForRightToLeftLayoutDirection(true)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 30, height: 30)
                .background {
                    Circle()
                        .fill(AppColors.surfaceCardRaised.opacity(0.9))
                        .overlay {
                            Circle().strokeBorder(AppColors.accentGold.opacity(0.45), lineWidth: 1)
                        }
                }
                // Görünen daire 30pt; dokunma alanı 44pt.
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

extension View {
    /// §06 §2: sheet'ler ayrı bir presentation context'inde açılıyor ve
    /// `\.locale` ile `\.layoutDirection` mirası içeri taşınmıyor. Yeniden
    /// verilmezse Arapça'da sheet içeriği soldan sağa kalıyor ve ALL CAPS
    /// dönüşümü Türkçe'de "i" harfini bozuyor.
    func localizedLayout() -> some View {
        let l10n = LocalizationManager.shared
        return environment(\.locale, Locale(identifier: l10n.localeCode))
            .environment(\.layoutDirection, l10n.layoutDirection)
    }
}
