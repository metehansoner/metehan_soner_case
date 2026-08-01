import SwiftUI

/// §09 §9: modal paywall oturum başına en fazla 3 kez açılıyor. Kota dolduktan
/// sonra kilitli içeriğe dokunuş bu kısa uyarıyı gösteriyor — dördüncü kez aynı
/// ekranı açmak ikna etmiyor, sinirlendiriyor.
///
/// §01 §4.1'in kuralı gereği haptik yok: uyarı kullanıcının başlattığı bir
/// eylemin sonucu değil, engellenmesinin bildirimi.
struct LockedNotice: View {
    let text: String?
    let onDismiss: () -> Void

    private static let visibleDuration = Duration.seconds(2.4)

    var body: some View {
        Group {
            if let text {
                HStack(spacing: 8) {
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(text)
                        .font(AppFont.ui(12.5, weight: .medium))
                        .lineLimit(2)
                }
                .foregroundStyle(AppColors.textCream)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background {
                    Capsule()
                        .fill(AppColors.surfaceCardRaised.opacity(0.96))
                        .overlay {
                            Capsule().strokeBorder(AppColors.accentGold.opacity(0.4), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: text) {
                    try? await Task.sleep(for: Self.visibleDuration)
                    guard !Task.isCancelled else { return }
                    onDismiss()
                }
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: text)
        .accessibilityAddTraits(.isStaticText)
    }
}
