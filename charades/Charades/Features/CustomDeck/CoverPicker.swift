import PhotosUI
import SwiftUI

/// Custom deste kapağı — 05-desteler-ve-kategoriler.md §7.
///
/// 12 tema afişi (hayvan, insan, araç…) SF Symbol + gradient ile çiziliyor.
/// PNG asset yok: paket boyutu ve renk güncellemesi ucuz kalıyor. Photos'tan
/// seçilen görsel varsa şablonun yerine geçiyor.
struct CustomCoverArt: View {
    let cover: CustomDeckCover
    /// Premium'un Photos'tan seçtiği görsel; varsa şablonun yerine geçiyor.
    var imageData: Data?

    var body: some View {
        ZStack {
            if let image = imageData.flatMap(UIImage.init(data:)) {
                photo(image)
            } else {
                template
            }
        }
        // Canvas/symbol ilk çizimi önbelleğe alabiliyor; kapak/foto değişince
        // kimlik değişmezse önizleme eski şablonda kalıyordu.
        .id(artIdentity)
        .clipped()
        .allowsHitTesting(false)
    }

    private var artIdentity: String {
        if let imageData {
            "photo-\(imageData.count)"
        } else {
            "template-\(cover.rawValue)"
        }
    }

    private var template: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let pad = side * 0.14

            ZStack {
                LinearGradient(
                    colors: cover.tones,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Derinlik: köşelerde soft vignette.
                RadialGradient(
                    colors: [.clear, .black.opacity(0.42)],
                    center: .center,
                    startRadius: side * 0.18,
                    endRadius: side * 0.9
                )

                // Arka plan gölge sembolü — afişe hacim verir.
                Image(systemName: cover.symbol)
                    .font(.system(size: side * 0.78, weight: .bold))
                    .foregroundStyle(cover.glow.opacity(0.14))
                    .offset(x: side * 0.1, y: side * 0.14)
                    .blur(radius: side * 0.02)

                // Ana amblem.
                Image(systemName: cover.symbol)
                    .font(.system(size: side * 0.44, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppColors.accentGold,
                                cover.glow,
                                AppColors.accentGold.opacity(0.85),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: cover.glow.opacity(0.55), radius: side * 0.07, y: side * 0.025)
                    .shadow(color: .black.opacity(0.35), radius: side * 0.03, y: side * 0.02)

                // Küçük köşe süsleri — katalog afişlerindeki köşe yıldızlarına paralel.
                ForEach(Array(cornerOffsets.enumerated()), id: \.offset) { _, point in
                    Image(systemName: cover.ornament)
                        .font(.system(size: side * 0.08, weight: .bold))
                        .foregroundStyle(AppColors.accentGold.opacity(0.55))
                        .position(
                            x: geo.size.width * point.x,
                            y: geo.size.height * point.y
                        )
                }

                HalftoneTexture(dotSize: 0.7, spacing: 4, color: .black.opacity(0.6))
                    .opacity(0.16)

                RoundedRectangle(cornerRadius: max(4, side * 0.06))
                    .strokeBorder(AppColors.accentGold.opacity(0.4), lineWidth: max(1, side * 0.018))
                    .padding(pad * 0.45)
            }
        }
    }

    private var cornerOffsets: [CGPoint] {
        [
            CGPoint(x: 0.16, y: 0.14),
            CGPoint(x: 0.84, y: 0.14),
            CGPoint(x: 0.16, y: 0.86),
            CGPoint(x: 0.84, y: 0.86),
        ]
    }

    /// §05 §7: seçilen görsele otomatik sepia + grain + altın çerçeve. Kullanıcı
    /// kapağı tema dışına çıkaramıyor — custom içeriğin ızgarayı bozmasını
    /// engelleyen kritik detay bu.
    ///
    /// `Image.scaledToFill` ideal boyutu piksel boyutundan öneriyor; `Color`
    /// üzerine overlay ile çizmek kartın 3:4 oranını fotoğrafın en-boy
    /// oranına göre şişirmesini engelliyor.
    private func photo(_ image: UIImage) -> some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .grayscale(0.72)
                    .colorMultiply(Color(hex: 0xD9AE72))
                    .brightness(-0.04)
                    .contrast(1.06)
                    .overlay { GrainOverlay() }
                    .overlay {
                        Rectangle()
                            .strokeBorder(AppColors.accentGold.opacity(0.75), lineWidth: 2)
                            .padding(3)
                    }
            }
            .clipped()
    }
}

// MARK: - Tema paleti

extension CustomDeckCover {
    /// Ana SF Symbol — afişin konusu.
    var symbol: String {
        switch self {
        case .animals: "pawprint.fill"
        case .people: "person.2.fill"
        case .vehicles: "car.fill"
        case .food: "fork.knife"
        case .sports: "soccerball"
        case .music: "music.note"
        case .travel: "airplane"
        case .home: "house.fill"
        case .nature: "leaf.fill"
        case .party: "party.popper.fill"
        case .jobs: "briefcase.fill"
        case .fantasy: "sparkles"
        }
    }

    /// Köşe süsü — ana sembolden küçük, afişi dolduruyor.
    var ornament: String {
        switch self {
        case .animals: "hare.fill"
        case .people: "heart.fill"
        case .vehicles: "bus.fill"
        case .food: "carrot.fill"
        case .sports: "figure.run"
        case .music: "headphones"
        case .travel: "globe.europe.africa.fill"
        case .home: "sofa.fill"
        case .nature: "mountain.2.fill"
        case .party: "gift.fill"
        case .jobs: "hammer.fill"
        case .fantasy: "wand.and.stars"
        }
    }

    /// Gradient zemin — her tema yan yana ayırt edilebilsin.
    var tones: [Color] {
        switch self {
        case .animals: [Color(hex: 0x5C3A1E), Color(hex: 0x1E120A)]
        case .people: [Color(hex: 0x6B2A3A), Color(hex: 0x2A1018)]
        case .vehicles: [Color(hex: 0x1E3A4A), Color(hex: 0x0C1A22)]
        case .food: [Color(hex: 0x7A3A18), Color(hex: 0x2E1608)]
        case .sports: [Color(hex: 0x1E4A2E), Color(hex: 0x0C1E14)]
        case .music: [Color(hex: 0x3A2246), Color(hex: 0x160E1E)]
        case .travel: [Color(hex: 0x1C3A5A), Color(hex: 0x0A1828)]
        case .home: [Color(hex: 0x5A3A22), Color(hex: 0x24160C)]
        case .nature: [Color(hex: 0x2A4A28), Color(hex: 0x101E10)]
        case .party: [Color(hex: 0x7A1B3A), Color(hex: 0x2C0818)]
        case .jobs: [Color(hex: 0x3A3428), Color(hex: 0x16140E)]
        case .fantasy: [Color(hex: 0x3A2A5A), Color(hex: 0x140E24)]
        }
    }

    /// Sembol ışıması — gradient'in sıcak ucu.
    var glow: Color {
        switch self {
        case .animals: Color(hex: 0xD4A06A)
        case .people: Color(hex: 0xE08A9A)
        case .vehicles: Color(hex: 0x7EB8D4)
        case .food: Color(hex: 0xE0A05A)
        case .sports: Color(hex: 0x7EC89A)
        case .music: Color(hex: 0xC49AE0)
        case .travel: Color(hex: 0x7AA8E0)
        case .home: Color(hex: 0xD4B07A)
        case .nature: Color(hex: 0x8EC87A)
        case .party: Color(hex: 0xE08AB0)
        case .jobs: Color(hex: 0xC8B48A)
        case .fantasy: Color(hex: 0xB89AE0)
        }
    }
}

// MARK: - Seçici

/// Editördeki `◆ KAPAK SEÇ` satırı. 12 şablon yatay kayan şeritte; Premium'da
/// başta bir de Photos düğmesi var.
struct CoverPicker: View {
    @Binding var selection: CustomDeckCover
    @Binding var imageData: Data?

    @Environment(LocalizationManager.self) private var l10n
    @Environment(SubscriptionStore.self) private var subscription

    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                photoButton

                ForEach(CustomDeckCover.allCases) { cover in
                    Button {
                        Haptics.deckSelected()
                        // Foto varsa binding set zaten temizliyor; seçim
                        // değişimi gözlemi tetiklesin diye tek yerden yazılıyor.
                        selection = cover
                    } label: {
                        CoverSwatch(isSelected: imageData == nil && selection == cover) {
                            CustomCoverArt(cover: cover)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(l10n.t(cover.titleKey))
                    .accessibilityAddTraits(imageData == nil && selection == cover ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 3)
        }
        .scrollClipDisabled()
        // Fotoğrafın tamamı `coverImageData`ya gidiyor; 12 MP bir kare SwiftData
        // deposunu şişirirdi, kart boyutuna indiriliyor.
        .task(id: photoItem) {
            guard let photoItem,
                  let raw = try? await photoItem.loadTransferable(type: Data.self)
            else { return }
            imageData = UIImage(data: raw)?.downscaled(maxDimension: 600)
        }
    }

    @ViewBuilder
    private var photoButton: some View {
        if subscription.isPremium {
            // `PhotosPicker`ın etiket closure'ı izolasyon dışında çalışıyor;
            // içeride `self`e dokunmamak için değerler önceden alınıyor.
            let data = imageData
            let cover = selection
            PhotosPicker(selection: $photoItem, matching: .images) {
                PhotoCoverLabel(imageData: data, cover: cover)
            }
            .accessibilityLabel(l10n.t("customDeck.cover.photo"))
        }
    }
}

/// Photos düğmesinin yüzü: seçilmiş fotoğraf ya da boş kare.
private struct PhotoCoverLabel: View {
    let imageData: Data?
    let cover: CustomDeckCover

    var body: some View {
        CoverSwatch(isSelected: imageData != nil) {
            if let imageData {
                CustomCoverArt(cover: cover, imageData: imageData)
            } else {
                ZStack {
                    AppColors.surfaceCardRaised
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 17))
                        .foregroundStyle(AppColors.accentGold)
                }
            }
        }
    }
}

private struct CoverSwatch<Content: View>: View {
    let isSelected: Bool
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(width: 52, height: 66)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8).strokeBorder(
                    isSelected ? AppColors.accentAmber : AppColors.accentGold.opacity(0.3),
                    lineWidth: isSelected ? 2 : 1
                )
            }
            .shadow(color: AppColors.accentAmber.opacity(isSelected ? 0.4 : 0), radius: 7)
    }
}

extension UIImage {
    /// Kapak en fazla ~180pt genişliğinde çiziliyor; @3x için 600px yeterli.
    func downscaled(maxDimension: CGFloat) -> Data? {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return jpegData(compressionQuality: 0.82) }

        let scale = maxDimension / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
        .jpegData(compressionQuality: 0.82)
    }
}
