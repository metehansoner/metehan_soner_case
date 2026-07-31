import SwiftUI

struct SplashView: View {
    @State private var showName = false

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 18) {
                Image("splash_icon")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(AppColors.accentCyan.opacity(0.85), lineWidth: 2.5)
                    )
                    .shadow(color: AppColors.accentCyan.opacity(0.45), radius: 22, y: 0)
                    .scaleEffect(showName ? 1 : 0.86)

                VStack(spacing: 6) {
                    Text(LocalizationManager.shared.t("app.name"))
                        .font(AppFont.display(28, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(LocalizationManager.shared.t("splash.tagline"))
                        .font(AppFont.ui(14, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .opacity(showName ? 1 : 0)
                .offset(y: showName ? 0 : 10)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) {
                showName = true
            }
        }
    }
}
