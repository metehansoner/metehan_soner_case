import SwiftUI

/// Ayarlar satırı — 06-ayarlar-ve-lokalizasyon.md §1: `surfaceCard` kart,
/// solda ikon kolonu, ortada başlık + isteğe bağlı alt metin, sağda kontrol.
///
/// Kartlar tek tek değil grup hâlinde çiziliyor (`SettingsGroup`), aralarında
/// 1px altın çizgi var; her satırın kendi kenarlığı olsaydı 13 satır 13 ayrı
/// kutuya bölünüp liste okunmaz hâle gelirdi.
struct SettingsRow<Control: View>: View {
    /// Segment ve stepper üç seçenek + başlıkla aynı satıra sığmıyor; o
    /// kontroller başlığın altına, tam genişliğe geçiyor.
    enum ControlPlacement {
        case trailing
        case below
    }

    let icon: String
    let title: String
    var subtitle: String?
    /// Dokunulabilir satırlarda tüm kart bir buton gibi davranıyor; kontrolü
    /// kendi olan satırlarda (anahtar, segment) `nil`.
    var action: (() -> Void)?
    var isEnabled = true
    var placement: ControlPlacement = .trailing
    @ViewBuilder var control: Control

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if let action {
            Button {
                Haptics.secondaryButton()
                action()
            } label: {
                content
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        } else {
            // Kendi kontrolü olan satırlar üç ayrı öğe olarak okunuyordu:
            // başlık, alt metin ve etiketsiz anahtar. Birleşince anahtarın
            // durumu başlığın değeri hâline geliyor.
            content.accessibilityElement(children: .combine)
        }
    }

    /// Erişilebilirlik puntolarında başlık ile kontrol yan yana sığmıyor:
    /// başlığa kalan genişlik iki-üç karaktere iniyor ve kelimeler ortadan
    /// bölünüyor ("Roun d lengt h"). O boyutlarda kontrol alt satıra geçiyor.
    private var stacksControl: Bool {
        placement == .below || typeSize.isAccessibilitySize
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isEnabled ? AppColors.accentGold : AppColors.stateLocked)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .textStyle(.bodyStrong)
                        .foregroundStyle(isEnabled ? AppColors.textCream : AppColors.stateLocked)

                    if let subtitle {
                        Text(subtitle)
                            .textStyle(.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !stacksControl {
                    control
                }
            }

            if stacksControl {
                control
                    .frame(maxWidth: .infinity, alignment: typeSize.isAccessibilitySize ? .leading : .center)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

/// Satırın sağ ucundaki `›`. Yön bağımlı olduğu için RTL'de aynalanıyor (§ `06` §2).
struct SettingsDisclosure: View {
    var value: String?

    var body: some View {
        HStack(spacing: 8) {
            if let value {
                Text(value)
                    .textStyle(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textMuted)
                .flipsForRightToLeftLayoutDirection(true)
                // Satırın kendisi zaten "düğme" diye okunuyor; ok işareti
                // eklenince VoiceOver her satırın sonuna bir de "chevron" diyor.
                .accessibilityHidden(true)
        }
    }
}

/// Grup başlığı + kart. Satırlar arasına altın %15 ayraç koyuyor.
struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.accentGold)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.surfaceCard.opacity(0.75))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(AppColors.accentGold.opacity(0.22), lineWidth: 1)
                    }
            }
        }
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.accentGold.opacity(0.15))
            .frame(height: 1)
            .padding(.leading, 52)
    }
}

/// İki ya da üç seçenekli kapsül segment (§ `06` §1 satır 3 ve 4).
/// Kurulum sheet'indeki zorluk satırının aynısı; orada inline duruyordu.
struct SettingsSegment<Option: Hashable>: View {
    let options: [Option]
    let title: (Option) -> String
    @Binding var selection: Option

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                Button {
                    guard !isSelected else { return }
                    Haptics.selection()
                    selection = option
                } label: {
                    Text(title(option))
                        .font(AppFont.ui(10.5, weight: .semibold))
                        .appTracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(isSelected ? AppColors.textOnAmber : AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            Capsule().fill(isSelected ? AppColors.accentAmber : .clear)
                        }
                        // Kapsül 31pt yüksekliğinde kalıyor; dokunma alanı 44pt.
                        .frame(minHeight: 38)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(3)
        .background {
            Capsule()
                .fill(AppColors.bgFilmBlack.opacity(0.5))
                .overlay {
                    Capsule().strokeBorder(AppColors.accentGold.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

/// `−  01:00  +` (§ `06` §1 satır 2). Sınıra dayanınca değer değişmiyor ama
/// haptik geliyor — sessiz kalan bir stepper bozuk sanılıyor.
struct SettingsStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let format: (Int) -> String

    var body: some View {
        HStack(spacing: 6) {
            button(systemImage: "minus", delta: -step)

            Text(format(value))
                .font(AppFont.display(16, weight: .bold, scales: .body))
                .monospacedDigit()
                .foregroundStyle(AppColors.textCream)
                .frame(minWidth: 52)

            button(systemImage: "plus", delta: step)
        }
        // Üç ayrı öğe yerine tek ayarlanabilir değer: VoiceOver'da yukarı/aşağı
        // kaydırmayla değişiyor, satırın başlığı da etiket olarak kalıyor.
        .accessibilityElement(children: .ignore)
        .accessibilityValue(format(value))
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? step : -step
            guard range.contains(value + delta) else {
                Haptics.stepperLimit()
                return
            }
            Haptics.selection()
            value += delta
        }
    }

    private func button(systemImage: String, delta: Int) -> some View {
        let isAvailable = range.contains(value + delta)
        return Button {
            guard isAvailable else {
                Haptics.stepperLimit()
                return
            }
            Haptics.selection()
            value += delta
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isAvailable ? AppColors.accentAmber : AppColors.stateLocked)
                .frame(width: 32, height: 32)
                .background {
                    Circle()
                        .fill(AppColors.bgFilmBlack.opacity(0.55))
                        .overlay {
                            Circle().strokeBorder(
                                (isAvailable ? AppColors.accentGold : AppColors.stateLocked).opacity(0.5),
                                lineWidth: 1
                            )
                        }
                }
                // Daire 32pt kalıyor — satırın dikey ritmi onunla kuruldu — ama
                // dokunma alanı 44pt'ye açılıyor (§01: "dokunma hedefleri
                // tamamen modern").
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
