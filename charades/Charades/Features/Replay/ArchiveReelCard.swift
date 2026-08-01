import SwiftUI

/// Arşivdeki bir sahne kartı — §04 §4.3.
///
/// Görsel videonun ortasından alınan kare; üzerine bilet tipografisiyle sahne
/// numarası, süre ve o turdaki doğru sayısı biniyor. Kare üretilene kadar kart
/// boş kalmıyor, sprocket'lı film şeridi zemini duruyor.
struct ArchiveReelCard: View {
    let reel: ReplayReel
    var isSelecting: Bool
    var isSelected: Bool
    var onTap: () -> Void
    var onPin: () -> Void
    var onSave: () -> Void
    var onDelete: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                poster
                foot
            }
            .frame(width: 132)
            .background {
                RoundedRectangle(cornerRadius: 11)
                    .fill(AppColors.surfaceCard)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(
                        isSelected ? AppColors.accentAmber : AppColors.accentGold.opacity(0.24),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .shadow(color: .black.opacity(0.7), radius: 7, y: 5)
        }
        .buttonStyle(.plain)
        // Kart altı ayrı parça olarak okunuyordu (sahne no, süre, puan, alt yazı,
        // rozet). Tek cümlede toplanıyor; bağlam menüsündeki eylemler de
        // VoiceOver eylem listesine kopyalanıyor — uzun basma jesti sistem
        // menüsünü açsa da rotorda görünmüyordu.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: Text(l10n.t(reel.isPinned ? "archive.unpin" : "archive.pin")), onPin)
        .accessibilityAction(named: Text(l10n.t("archive.save")), onSave)
        .accessibilityAction(named: Text(l10n.t("common.delete")), onDelete)
        .contextMenu {
            Button {
                onPin()
            } label: {
                Label(
                    l10n.t(reel.isPinned ? "archive.unpin" : "archive.pin"),
                    systemImage: reel.isPinned ? "pin.slash" : "pin"
                )
            }

            Button {
                onSave()
            } label: {
                Label(l10n.t("archive.save"), systemImage: "square.and.arrow.down")
            }

            // Bağlam menüsündeki `ShareLink`e olay bağlanamıyor: menü öğeleri
            // sistem tarafından çiziliyor ve kendi eylemleri dışında jest
            // almıyorlar. Arşivden paylaşım ölçümü oynatıcıdaki butondan
            // geliyor (§03 §5 `replay_share.source = archive`).
            ShareLink(item: reel.videoURL) {
                Label(l10n.t("replay.share"), systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive, action: onDelete) {
                Label(l10n.t("common.delete"), systemImage: "trash")
            }
        }
        .task(id: reel.id) { thumbnail = await ReplayThumbnails.image(for: reel) }
    }

    private var poster: some View {
        ZStack {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [AppColors.surfaceCardRaised, AppColors.bgVelvetDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            HStack {
                sprocket
                Spacer()
                sprocket
            }

            playBadge

            Text(l10n.t("replay.scene", ["no": String(format: "%02d", reel.sceneIndex)]))
                .font(AppFont.display(9, weight: .semibold))
                .appTracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.surfacePoster)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.72)))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 6)
                .padding(.leading, 14)

            badges
        }
        .frame(width: 132, height: 78)
        .clipped()
    }

    private var badges: some View {
        ZStack {
            if reel.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.accentAmber)
                    .rotationEffect(.degrees(35))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 6)
                    .padding(.trailing, 14)
            }

            Text(ArchiveModel.durationText(reel.duration))
                .font(AppFont.display(9.5, weight: .semibold))
                .foregroundStyle(AppColors.surfacePoster)
                .monospacedDigit()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.72)))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.bottom, 6)
                .padding(.trailing, 14)
        }
    }

    /// Çoklu seçimde oynatma rozetinin yerini onay işareti alıyor: aynı dokunuş
    /// artık oynatmıyor, seçiyor.
    private var playBadge: some View {
        Image(systemName: isSelecting ? (isSelected ? "checkmark" : "circle") : "play.fill")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(isSelecting && !isSelected ? AppColors.surfacePoster : AppColors.textOnAmber)
            .frame(width: 29, height: 29)
            .background {
                Circle().fill(
                    isSelecting && !isSelected
                        ? Color.black.opacity(0.5)
                        : AppColors.accentAmber.opacity(0.93)
                )
            }
            .shadow(color: .black.opacity(0.5), radius: 4, y: 3)
    }

    private var sprocket: some View {
        SprocketStrip(
            axis: .vertical,
            holeSize: 5,
            spacing: 8,
            holeColor: AppColors.surfacePoster.opacity(0.85)
        )
        .frame(width: 9)
        .background(Color(hex: 0x0B0907))
    }

    private var foot: some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(reel.correctCount)")
                    .font(AppFont.display(15, weight: .bold))
                    .foregroundStyle(AppColors.stateCorrect)

                Text(l10n.t("round.points"))
                    .font(AppFont.ui(7.5, weight: .semibold))
                    .appTracking(1.3)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer(minLength: 0)

            Text(caption)
                .font(AppFont.ui(8.5, weight: .semibold))
                .appTracking(0.8)
                .textCase(.uppercase)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .foregroundStyle(reel.isPartial ? AppColors.stateWarning : AppColors.textSecondary)
                .frame(maxWidth: 58, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 9)
    }

    /// Sahne, süre, skor ve durum tek cümlede. Sabitlenmiş kayıtta iğne rozeti
    /// de sesli söyleniyor; görsel olarak tek işaret o.
    private var spokenSummary: String {
        var parts = [
            l10n.t("replay.scene", ["no": String(format: "%02d", reel.sceneIndex)]),
            ArchiveModel.durationText(reel.duration),
            "\(reel.correctCount) \(l10n.t("round.points"))",
            caption,
        ]
        if reel.isPinned { parts.append(l10n.t("archive.pinned")) }
        return parts.joined(separator: ", ")
    }

    /// Takım maçında sahnenin sahibi, tek kişilik turda kaydın durumu.
    private var caption: String {
        if reel.isPartial { return l10n.t("replay.partial") }
        return reel.playerName ?? ArchiveModel.dateText(reel.createdAt, localeCode: l10n.localeCode)
    }
}
