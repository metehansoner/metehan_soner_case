import SwiftUI

/// Ekran 21 — Dil Seçimi (§06 §2 "Dil seçim ekranı").
///
/// 25 satır, her biri **kendi dilinde**; altında o dilin adı kullanıcının o
/// anki dilinde (`Locale.localizedString`, ayrı çeviri anahtarı gerekmiyor).
/// Arama alanı yok: 25 satır kaydırılabilir uzunlukta.
///
/// Seçim anında uygulanıyor, restart yok — `LocalizationManager` `@Observable`
/// ve font ailesi de aynı değerden türüyor (§01 §2), yani Yunanca'ya geçişte
/// tipografi de aynı karede değişiyor.
struct LanguageSheet: View {
    var onClose: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        SheetScaffold(title: l10n.t("settings.language"), onClose: onClose) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(l10n.t("language.group"))
                        .textStyle(.sectionLabel)
                        .foregroundStyle(AppColors.accentGold)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(LocalizationManager.supportedLocales.enumerated()), id: \.element) { index, code in
                            if index > 0 {
                                Rectangle()
                                    .fill(AppColors.accentGold.opacity(0.12))
                                    .frame(height: 1)
                                    .padding(.leading, 60)
                            }
                            row(code)
                        }
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppColors.surfaceCard.opacity(0.75))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(AppColors.accentGold.opacity(0.22), lineWidth: 1)
                            }
                    }

                    Text(l10n.t("language.note"))
                        .textStyle(.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }

    private func row(_ code: String) -> some View {
        let isSelected = code == l10n.localeCode

        return Button {
            guard !isSelected else { return }
            Haptics.selection()
            l10n.setLanguage(code)
        } label: {
            HStack(spacing: 12) {
                Text(Self.flag(code))
                    .font(.system(size: 22))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizationManager.languageDisplayName(code))
                        .textStyle(.bodyStrong)
                        .foregroundStyle(AppColors.textCream)
                    Text(subtitle(for: code, isSelected: isSelected))
                        .textStyle(.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(AppColors.bgVelvetDeep)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(AppColors.accentGold))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// Seçili satırda "Sistem dili" yerine dilin kullanıcı dilindeki adı zaten
    /// başlıkla aynı olurdu; onun yerine bu satırın neden seçili olduğu yazıyor.
    private func subtitle(for code: String, isSelected: Bool) -> String {
        if isSelected {
            return AppSettingsStore.shared.languageOverride == nil
                ? l10n.t("language.system")
                : l10n.t("language.selected")
        }
        let locale = Locale(identifier: l10n.localeCode)
        return locale.localizedString(forLanguageCode: code)?.capitalized(with: locale)
            ?? code.uppercased()
    }

    /// Mockup'taki (ekran 21) bayrak sütunu. `ca` için Andorra: Katalanca'nın
    /// tek resmî dil olduğu ülke — bölgesel bayrakların emoji karşılığı yok.
    private static func flag(_ code: String) -> String {
        let regions = [
            "en": "GB", "tr": "TR", "ar": "SA", "be": "BY", "ca": "AD",
            "cs": "CZ", "da": "DK", "de": "DE", "el": "GR", "es": "ES",
            "fi": "FI", "fil": "PH", "fr": "FR", "hr": "HR", "id": "ID",
            "it": "IT", "ms": "MY", "nb": "NO", "nl": "NL", "pl": "PL",
            "pt": "PT", "ro": "RO", "ru": "RU", "sv": "SE", "uk": "UA",
        ]
        guard let region = regions[code] else { return "🏳️" }
        return region.unicodeScalars
            .compactMap { UnicodeScalar(127_397 + $0.value).map(String.init) }
            .joined()
    }
}
