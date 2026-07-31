import SwiftUI

struct LanguageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var l10n = LocalizationManager.shared

    private var codes: [String] {
        LocalizationManager.supportedLocales.sorted {
            displayName(for: $0).localizedStandardCompare(displayName(for: $1)) == .orderedAscending
        }
    }

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                Capsule()
                    .fill(AppColors.textSecondary.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                ScreenTitle(text: l10n.t("settings.language"))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(codes, id: \.self) { code in
                            languageRow(code: code)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)

                Button {
                    Haptics.light()
                    dismiss()
                } label: {
                    Text(l10n.t("common.done"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
        }
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
            HStack(spacing: 12) {
                Text(name)
                    .font(AppFont.display(17, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(AppColors.textOnLight, AppColors.accentCyan)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? AppColors.surfaceCardElevated : AppColors.surfaceCard.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                selected ? AppColors.accentCyan : AppColors.accentCyan.opacity(0.12),
                                lineWidth: selected ? 2 : 1
                            )
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: selected)
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
