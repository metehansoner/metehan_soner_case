import SwiftUI

struct LanguageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var l10n = LocalizationManager.shared

    private let codes = LocalizationManager.supportedLocales

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppColors.textSecondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text(l10n.t("settings.language"))
                .font(AppFont.display(30, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(codes, id: \.self) { code in
                        languageRow(code: code)
                    }
                }
                .padding(.horizontal, 8)
            }
            .scrollIndicators(.hidden)

            Button {
                Haptics.light()
                dismiss()
            } label: {
                Text(l10n.t("common.back"))
            }
            .buttonStyle(SecondaryCapsuleButtonStyle())
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [AppColors.bgPrimaryMid, AppColors.bgPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .onAppear { Haptics.light() }
    }

    private func languageRow(code: String) -> some View {
        let selected = l10n.localeCode == code
        let name = displayName(for: code)

        return Button {
            Haptics.medium()
            l10n.setLanguage(code)
        } label: {
            HStack {
                Text(name)
                    .font(AppFont.display(18, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.accentCyan)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func displayName(for code: String) -> String {
        let fallback: [String: String] = [
            "tr": "Türkçe", "de": "Deutsch", "ar": "العربية", "be": "Беларуская", "da": "Dansk",
            "id": "Bahasa Indonesia", "fil": "Filipino", "fi": "Suomi", "fr": "Français",
            "nl": "Nederlands", "hr": "Hrvatski", "ca": "Català", "pl": "Polski", "ms": "Bahasa Melayu",
            "nb": "Norsk Bokmål", "pt": "Português", "ro": "Română", "ru": "Русский",
            "uk": "Українська", "el": "Ελληνικά", "cs": "Čeština", "en": "English",
            "es": "Español", "sv": "Svenska", "it": "Italiano"
        ]
        return LocalizationManager.languageDisplayName(code) ?? fallback[code] ?? code
    }
}
