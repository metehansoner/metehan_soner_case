import PhotosUI
import SwiftUI

/// Custom deste kapağı — 05-desteler-ve-kategoriler.md §7.
///
/// Şablonlar bilerek **soyut ve konusuz**: kadife, film şeridi, spot, yıldız…
/// Katalog kapakları gibi amblem taşımıyorlar, çünkü "Ofis Muhabbeti" destesine
/// yakışan bir amblem yok. Motifler PNG değil `Canvas` — 12 şablon × @3x asset
/// hem paket boyutu hem de tek renk değişikliğinde yeniden üretim demekti.
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
        .clipped()
        .allowsHitTesting(false)
    }

    private var template: some View {
        ZStack {
            LinearGradient(
                colors: cover.tones,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                cover.draw(in: &context, size: size)
            }

            HalftoneTexture(dotSize: 0.7, spacing: 4, color: .black.opacity(0.6))
                .opacity(0.18)
        }
    }

    /// §05 §7: seçilen görsele otomatik sepia + grain + altın çerçeve. Kullanıcı
    /// kapağı tema dışına çıkaramıyor — custom içeriğin ızgarayı bozmasını
    /// engelleyen kritik detay bu.
    private func photo(_ image: UIImage) -> some View {
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
}

// MARK: - Şablon çizimleri

extension CustomDeckCover {
    /// Her şablon ayrı bir renk çifti alıyor: 12 kapak yan yana dizildiğinde
    /// motif farkı küçük kalıyor, ayrımı asıl renk yapıyor.
    var tones: [Color] {
        switch self {
        case .velvet: [Color(hex: 0x7A1B28), Color(hex: 0x3A0D14)]
        case .filmStrip: [Color(hex: 0x2C2622), Color(hex: 0x14100E)]
        case .spotlight: [Color(hex: 0x2A2438), Color(hex: 0x120E1C)]
        case .star: [Color(hex: 0x8A5A12), Color(hex: 0x38220A)]
        case .ticket: [Color(hex: 0x9A6B2A), Color(hex: 0x40270E)]
        case .marquee: [Color(hex: 0x1C3A4A), Color(hex: 0x0C1A22)]
        case .reel: [Color(hex: 0x33301C), Color(hex: 0x16150C)]
        case .curtain: [Color(hex: 0x6B1430), Color(hex: 0x2C0814)]
        case .clapper: [Color(hex: 0x24262C), Color(hex: 0x0E0F12)]
        case .sunburst: [Color(hex: 0xA0651A), Color(hex: 0x40240A)]
        case .posterFrame: [Color(hex: 0x1E3428), Color(hex: 0x0C1610)]
        case .bulbBorder: [Color(hex: 0x3A2246), Color(hex: 0x180E1E)]
        }
    }

    private var ink: Color { AppColors.accentGold.opacity(0.66) }
    private var inkSoft: Color { AppColors.accentGold.opacity(0.24) }

    func draw(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let center = CGPoint(x: w / 2, y: h / 2)

        switch self {
        case .velvet:
            // Düşey kadife kıvrımları: her şerit hafif dalgalı, aralar koyu.
            for index in 0..<7 {
                let x = w * (CGFloat(index) + 0.5) / 7
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                for step in stride(from: 0.0, through: 1.0, by: 0.05) {
                    let y = h * step
                    let offset = sin(step * .pi * 2) * w * 0.018
                    path.addLine(to: CGPoint(x: x + offset, y: y))
                }
                context.stroke(path, with: .color(inkSoft), lineWidth: w * 0.05)
            }

        case .filmStrip:
            let bandHeight = h * 0.34
            for band in 0..<2 {
                let y = h * (band == 0 ? 0.22 : 0.62) - bandHeight / 2
                let rect = CGRect(x: -w * 0.1, y: y, width: w * 1.2, height: bandHeight)
                context.fill(Path(rect), with: .color(.black.opacity(0.42)))
                for hole in 0..<7 {
                    let hx = w * (CGFloat(hole) - 0.2) / 6
                    let holeSize = CGSize(width: w * 0.07, height: bandHeight * 0.16)
                    for edge in [y + bandHeight * 0.09, y + bandHeight * 0.75] {
                        let holeRect = CGRect(origin: CGPoint(x: hx, y: edge), size: holeSize)
                        context.fill(
                            Path(roundedRect: holeRect, cornerRadius: 1.5),
                            with: .color(ink.opacity(0.5))
                        )
                    }
                }
            }

        case .spotlight:
            var beam = Path()
            beam.move(to: CGPoint(x: w * 0.5, y: -h * 0.05))
            beam.addLine(to: CGPoint(x: w * 0.03, y: h))
            beam.addLine(to: CGPoint(x: w * 0.97, y: h))
            beam.closeSubpath()
            context.fill(
                beam,
                with: .linearGradient(
                    Gradient(colors: [AppColors.accentAmber.opacity(0.42), .clear]),
                    startPoint: CGPoint(x: w / 2, y: 0),
                    endPoint: CGPoint(x: w / 2, y: h)
                )
            )
            context.fill(
                Path(ellipseIn: CGRect(x: w * 0.36, y: -h * 0.1, width: w * 0.28, height: h * 0.16)),
                with: .color(AppColors.accentAmber.opacity(0.75))
            )

        case .star:
            context.fill(starPath(center: center, radius: min(w, h) * 0.3), with: .color(ink))
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: center.x - min(w, h) * 0.42,
                    y: center.y - min(w, h) * 0.42,
                    width: min(w, h) * 0.84,
                    height: min(w, h) * 0.84
                )),
                with: .color(inkSoft),
                lineWidth: w * 0.02
            )

        case .ticket:
            let rect = CGRect(x: w * 0.14, y: h * 0.2, width: w * 0.72, height: h * 0.6)
            context.stroke(
                Path(roundedRect: rect, cornerRadius: w * 0.05),
                with: .color(ink),
                lineWidth: w * 0.022
            )
            // Koparma çentikleri + perforasyon: bilet olduğunu anlatan iki detay.
            for side in [rect.minX, rect.maxX] {
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: side - w * 0.045, y: rect.midY - w * 0.045,
                        width: w * 0.09, height: w * 0.09
                    )),
                    with: .color(tones[1])
                )
            }
            var perforation = Path()
            perforation.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.06))
            perforation.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.06))
            context.stroke(
                perforation,
                with: .color(inkSoft),
                style: StrokeStyle(lineWidth: w * 0.015, dash: [w * 0.03, w * 0.03])
            )

        case .marquee:
            let rect = CGRect(x: w * 0.1, y: h * 0.16, width: w * 0.8, height: h * 0.68)
            context.stroke(
                Path(roundedRect: rect, cornerRadius: w * 0.04),
                with: .color(ink),
                lineWidth: w * 0.018
            )
            for line in 0..<3 {
                var path = Path()
                let y = rect.minY + rect.height * (0.3 + CGFloat(line) * 0.2)
                path.move(to: CGPoint(x: rect.minX + w * 0.1, y: y))
                path.addLine(to: CGPoint(x: rect.maxX - w * 0.1, y: y))
                context.stroke(path, with: .color(inkSoft), lineWidth: w * 0.03)
            }

        case .reel:
            for ring in [0.42, 0.3, 0.1] {
                let radius = min(w, h) * ring
                context.stroke(
                    Path(ellipseIn: CGRect(
                        x: center.x - radius, y: center.y - radius,
                        width: radius * 2, height: radius * 2
                    )),
                    with: .color(ring == 0.1 ? ink : inkSoft),
                    lineWidth: w * 0.02
                )
            }
            for hole in 0..<3 {
                let angle = Double(hole) / 3 * 2 * .pi - .pi / 2
                let radius = min(w, h) * 0.22
                let dot = min(w, h) * 0.07
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: center.x + cos(angle) * radius - dot,
                        y: center.y + sin(angle) * radius - dot,
                        width: dot * 2, height: dot * 2
                    )),
                    with: .color(ink)
                )
            }

        case .curtain:
            for fold in 0..<6 {
                let x = w * CGFloat(fold) / 5
                var path = Path()
                path.move(to: CGPoint(x: x, y: h * 0.12))
                path.addQuadCurve(
                    to: CGPoint(x: x, y: h),
                    control: CGPoint(x: x + w * 0.07, y: h * 0.55)
                )
                context.stroke(path, with: .color(inkSoft), lineWidth: w * 0.035)
            }
            var swag = Path()
            swag.move(to: CGPoint(x: 0, y: h * 0.06))
            swag.addQuadCurve(
                to: CGPoint(x: w, y: h * 0.06),
                control: CGPoint(x: w / 2, y: h * 0.28)
            )
            context.stroke(swag, with: .color(ink), lineWidth: w * 0.03)

        case .clapper:
            let band = CGRect(x: -w * 0.1, y: h * 0.16, width: w * 1.2, height: h * 0.22)
            context.fill(Path(band), with: .color(.black.opacity(0.5)))
            for stripe in 0..<6 {
                var path = Path()
                let x = band.minX + CGFloat(stripe) * (band.width / 6)
                path.move(to: CGPoint(x: x, y: band.maxY))
                path.addLine(to: CGPoint(x: x + band.height * 0.6, y: band.minY))
                path.addLine(to: CGPoint(x: x + band.height * 1.2, y: band.minY))
                path.addLine(to: CGPoint(x: x + band.height * 0.6, y: band.maxY))
                path.closeSubpath()
                context.fill(path, with: .color(ink.opacity(0.7)))
            }
            var slate = Path()
            slate.move(to: CGPoint(x: w * 0.18, y: h * 0.58))
            slate.addLine(to: CGPoint(x: w * 0.82, y: h * 0.58))
            context.stroke(slate, with: .color(inkSoft), lineWidth: w * 0.03)

        case .sunburst:
            for ray in 0..<16 {
                let angle = Double(ray) / 16 * 2 * .pi
                let spread = 0.16
                var path = Path()
                path.move(to: center)
                path.addLine(to: CGPoint(
                    x: center.x + cos(angle - spread) * w,
                    y: center.y + sin(angle - spread) * w
                ))
                path.addLine(to: CGPoint(
                    x: center.x + cos(angle + spread) * w,
                    y: center.y + sin(angle + spread) * w
                ))
                path.closeSubpath()
                context.fill(path, with: .color(ray.isMultiple(of: 2) ? inkSoft : .clear))
            }

        case .posterFrame:
            for inset in [0.08, 0.14] {
                let rect = CGRect(
                    x: w * inset, y: h * inset * 0.75,
                    width: w * (1 - inset * 2), height: h * (1 - inset * 1.5)
                )
                context.stroke(
                    Path(rect),
                    with: .color(inset == 0.08 ? ink : inkSoft),
                    lineWidth: w * 0.015
                )
            }
            for corner in [(0.14, 0.105), (0.86, 0.105), (0.14, 0.895), (0.86, 0.895)] {
                let point = CGPoint(x: w * corner.0, y: h * corner.1)
                context.fill(
                    starPath(center: point, radius: w * 0.05, points: 4),
                    with: .color(ink)
                )
            }

        case .bulbBorder:
            let rect = CGRect(x: w * 0.12, y: h * 0.12, width: w * 0.76, height: h * 0.76)
            let bulb = w * 0.03
            for step in 0..<28 {
                let progress = CGFloat(step) / 28 * 4
                let point = perimeterPoint(rect: rect, progress: progress)
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: point.x - bulb, y: point.y - bulb,
                        width: bulb * 2, height: bulb * 2
                    )),
                    with: .color(step.isMultiple(of: 2) ? ink : inkSoft)
                )
            }
        }
    }

    private func starPath(center: CGPoint, radius: CGFloat, points: Int = 5) -> Path {
        var path = Path()
        let inner = radius * 0.44
        for step in 0..<(points * 2) {
            let angle = Double(step) / Double(points * 2) * 2 * .pi - .pi / 2
            let distance = step.isMultiple(of: 2) ? radius : inner
            let point = CGPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance
            )
            step == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }

    /// `progress` 0…4 aralığında dikdörtgenin kenarlarında dolaşıyor.
    private func perimeterPoint(rect: CGRect, progress: CGFloat) -> CGPoint {
        let side = Int(progress) % 4
        let fraction = progress - CGFloat(Int(progress))
        switch side {
        case 0: return CGPoint(x: rect.minX + rect.width * fraction, y: rect.minY)
        case 1: return CGPoint(x: rect.maxX, y: rect.minY + rect.height * fraction)
        case 2: return CGPoint(x: rect.maxX - rect.width * fraction, y: rect.maxY)
        default: return CGPoint(x: rect.minX, y: rect.maxY - rect.height * fraction)
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
                        selection = cover
                        imageData = nil
                    } label: {
                        CoverSwatch(isSelected: imageData == nil && selection == cover) {
                            CustomCoverArt(cover: cover)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(l10n.t(cover.titleKey))
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
