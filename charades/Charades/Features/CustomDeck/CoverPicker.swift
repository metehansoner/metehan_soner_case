import PhotosUI
import SwiftUI


struct CustomCoverArt: View {
    let cover: CustomDeckCover

    var imageData: Data?

    var body: some View {
        ZStack {
            if let image = imageData.flatMap(UIImage.init(data:)) {
                photo(image)
            } else {
                template
            }
        }


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


                RadialGradient(
                    colors: [.clear, .black.opacity(0.42)],
                    center: .center,
                    startRadius: side * 0.18,
                    endRadius: side * 0.9
                )


                Image(systemName: cover.symbol)
                    .font(.system(size: side * 0.78, weight: .bold))
                    .foregroundStyle(cover.glow.opacity(0.14))
                    .offset(x: side * 0.1, y: side * 0.14)
                    .blur(radius: side * 0.02)


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


extension CustomDeckCover {

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


struct CoverPickerSheet: View {
    @Binding var selection: CustomDeckCover
    @Binding var imageData: Data?
    var onClose: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(SubscriptionStore.self) private var subscription

    @State private var photoItem: PhotosPickerItem?

    private let columns = [
        GridItem(.adaptive(minimum: 92), spacing: 12),
    ]

    var body: some View {
        SheetScaffold(title: l10n.t("customDeck.field.cover"), onClose: onClose) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    photoButton

                    ForEach(CustomDeckCover.allCases) { cover in
                        Button {
                            Haptics.deckSelected()
                            selection = cover
                            imageData = nil
                            onClose()
                        } label: {
                            VStack(spacing: 7) {
                                CoverSwatch(
                                    isSelected: imageData == nil && selection == cover,
                                    width: 92,
                                    height: 118
                                ) {
                                    CustomCoverArt(cover: cover)
                                }

                                Text(l10n.t(cover.titleKey))
                                    .font(AppFont.ui(11, weight: .semibold))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(l10n.t(cover.titleKey))
                        .accessibilityAddTraits(imageData == nil && selection == cover ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .task(id: photoItem) {
            guard let photoItem,
                  let raw = try? await photoItem.loadTransferable(type: Data.self)
            else { return }
            imageData = UIImage(data: raw)?.downscaled(maxDimension: 600)
            if imageData != nil { onClose() }
        }
    }

    @ViewBuilder
    private var photoButton: some View {
        if subscription.isPremium {
            let data = imageData
            let cover = selection
            let title = l10n.t("customDeck.cover.photo")
            PhotosPicker(selection: $photoItem, matching: .images) {
                PhotoPickerCell(imageData: data, cover: cover, title: title)
            }
            .accessibilityLabel(title)
        }
    }
}


private struct PhotoPickerCell: View {
    let imageData: Data?
    let cover: CustomDeckCover
    let title: String

    var body: some View {
        VStack(spacing: 7) {
            PhotoCoverLabel(imageData: imageData, cover: cover, width: 92, height: 118)
            Text(title)
                .font(AppFont.ui(11, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .contentShape(Rectangle())
    }
}


private struct PhotoCoverLabel: View {
    let imageData: Data?
    let cover: CustomDeckCover
    var width: CGFloat = 52
    var height: CGFloat = 66

    var body: some View {
        CoverSwatch(isSelected: imageData != nil, width: width, height: height) {
            if let imageData {
                CustomCoverArt(cover: cover, imageData: imageData)
            } else {
                ZStack {
                    AppColors.surfaceCardRaised
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: height * 0.28))
                        .foregroundStyle(AppColors.accentGold)
                }
            }
        }
    }
}

private struct CoverSwatch<Content: View>: View {
    let isSelected: Bool
    var width: CGFloat = 52
    var height: CGFloat = 66
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10).strokeBorder(
                    isSelected ? AppColors.accentAmber : AppColors.accentGold.opacity(0.3),
                    lineWidth: isSelected ? 2.5 : 1
                )
            }
            .shadow(color: AppColors.accentAmber.opacity(isSelected ? 0.45 : 0), radius: 8)
            .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}

extension UIImage {

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
