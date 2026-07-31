import SwiftUI

/// Paket 0 kabul ekranı: palet ve font yüklemesini gözle doğrulamak için.
/// Gerçek navigasyon kabuğu ve deste ızgarası P3'te bunun yerine geçecek.
struct RootView: View {
    var body: some View {
        ZStack {
            AppColors.screenBackground
            AppColors.spotlightOverlay
            AppColors.vignette

            VStack(spacing: 32) {
                VStack(spacing: 10) {
                    Text("Charades")
                        .textStyle(.marquee)
                        .foregroundStyle(AppColors.textCream)
                        .shadow(color: AppColors.accentAmber.opacity(0.55), radius: 18)

                    Text("Grand Marquee")
                        .textStyle(.sectionLabel)
                        .foregroundStyle(AppColors.accentGold)
                }

                Text("Sahne 1 · Çekim 1")
                    .textStyle(.posterTitle)
                    .foregroundStyle(AppColors.textSecondary)

                fontRoster
            }
            .padding(24)
        }
        .ignoresSafeArea()
    }

    private var fontRoster: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gömülü fontlar")
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.accentGold)

            ForEach(AppFont.bundledPostScriptNames, id: \.self) { name in
                let loaded = AppFont.isAvailable(name)
                HStack(spacing: 10) {
                    Image(systemName: loaded ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(loaded ? AppColors.stateCorrect : AppColors.stateSkip)
                    Text(name)
                        .font(.custom(name, size: 15))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.surfaceCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppColors.accentGold.opacity(0.35), lineWidth: 1)
                }
        }
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
