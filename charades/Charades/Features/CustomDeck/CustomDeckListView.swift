import SwiftData
import SwiftUI

/// Kendi Destelerim (ekran 7) — 02-ekran-akisi.md §7, limitler §05 §7.
///
/// Ana ekrandaki ızgara custom desteleri **oynamak** için gösteriyor; bu ekran
/// onları **düzenlemek** için. İki kapıyı ayırmak §05 §7'nin ilk tablosundaki
/// ayrımın devamı: burada dokunuş editörü açıyor, tur başlatmıyor.
struct CustomDeckListView: View {
    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppRouter.self) private var router
    @Environment(SubscriptionStore.self) private var subscription
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CustomDeck.sortIndex) private var decks: [CustomDeck]

    @State private var deckPendingDeletion: CustomDeck?

    /// Editörün boş taslağı listede flaş etmesin; slot hesabı tüm kayıtları
    /// saymaya devam ediyor (açık taslak yeri tutsun).
    private var listedDecks: [CustomDeck] {
        decks.filter(\.hasListableContent)
    }

    private var slotLimit: Int {
        CustomDeckLimits.maxDeckCount(isPremium: subscription.isPremium)
    }

    private var hasFreeSlot: Bool { decks.count < slotLimit }

    var body: some View {
        ZStack {
            VelvetBackground()

            VStack(spacing: 0) {
                navBar

                ScrollView {
                    VStack(spacing: 10) {
                        if listedDecks.isEmpty {
                            emptyState
                        } else {
                            ForEach(Array(listedDecks.enumerated()), id: \.element.uuid) { index, deck in
                                row(deck, isReadOnly: index >= slotLimit)
                            }

                            // Slot doluyken dashed "Yeni Deste" kartı ikinci bir
                            // boş deste gibi duruyordu — yalnızca yer varken.
                            if hasFreeSlot {
                                addRow
                            } else {
                                slotsFullNote
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .alert(
            l10n.t("customDeck.delete.title"),
            isPresented: Binding(
                get: { deckPendingDeletion != nil },
                set: { if !$0 { deckPendingDeletion = nil } }
            )
        ) {
            Button(l10n.t("common.cancel"), role: .cancel) {}
            Button(l10n.t("customDeck.delete.confirm"), role: .destructive, action: deletePending)
        } message: {
            Text(l10n.t("customDeck.delete.body", ["name": displayName(deckPendingDeletion)]))
        }
    }

    // MARK: Başlık

    private var navBar: some View {
        HStack(spacing: 0) {
            BackNavButton(accessibilityLabel: l10n.t("common.back")) {
                router.pop()
            }

            VStack(spacing: 2) {
                Text(l10n.t("customDeck.list.title"))
                    .font(AppFont.display(19, weight: .bold))
                    .appTracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)

                Text(l10n.t("customDeck.list.slots", [
                    "used": "\(decks.count)",
                    "total": "\(slotLimit)",
                ]))
                .font(AppFont.ui(10.5))
                .foregroundStyle(AppColors.textMuted)
            }
            .frame(maxWidth: .infinity)

            Color.clear.frame(width: BackNavButton.hitSide, height: BackNavButton.hitSide)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }

    // MARK: Boş durum — §02 §6

    private var emptyState: some View {
        VStack(spacing: 18) {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    AppColors.accentGold.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                )
                .frame(width: 96, height: 128)
                .overlay {
                    Image(systemName: "rectangle.portrait.badge.plus")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(AppColors.accentGold)
                }

            VStack(spacing: 8) {
                Text(l10n.t("customDeck.list.emptyTitle"))
                    .font(AppFont.display(18, weight: .bold))
                    .appTracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)
                    .multilineTextAlignment(.center)

                Text(l10n.t("customDeck.list.emptyBody"))
                    .font(AppFont.ui(12))
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            }

            Button(action: createDeck) {
                Text(l10n.t("customDeck.list.emptyAction"))
                    .lineLimit(1)
            }
            .buttonStyle(MarqueeButtonStyle())
            .padding(.horizontal, 28)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.top, 48)
    }

    // MARK: Deste satırı

    private func row(_ deck: CustomDeck, isReadOnly: Bool) -> some View {
        Button {
            Haptics.secondaryButton()
            router.push(.customEditor(deck.uuid.uuidString))
        } label: {
            HStack(spacing: 12) {
                CustomCoverArt(cover: deck.cover, imageData: deck.coverImageData)
                    .frame(width: 46, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(AppColors.accentGold.opacity(0.35), lineWidth: 1)
                    }
                    .saturation(isReadOnly ? 0.3 : 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName(deck))
                        .font(AppFont.display(16, weight: .semibold))
                        .foregroundStyle(AppColors.textCream)
                        .lineLimit(1)

                    Text(subtitle(for: deck))
                        .font(AppFont.ui(10.5))
                        .foregroundStyle(deck.canPlay ? AppColors.textMuted : AppColors.stateWarning)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                // §09 §9: Premium'dan düşen kullanıcının fazla desteleri
                // silinmiyor, salt-okunur kalıyor — kendi emeğini kaybetmiyor.
                Image(systemName: isReadOnly ? "lock.fill" : "chevron.right")
                    .flipsForRightToLeftLayoutDirection(true)
                    .font(.system(size: isReadOnly ? 12 : 14, weight: .semibold))
                    .foregroundStyle(isReadOnly ? AppColors.stateLocked : AppColors.accentGold)
            }
            .padding(11)
            .background {
                RoundedRectangle(cornerRadius: 13)
                    .fill(AppColors.surfaceCard.opacity(0.86))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13)
                            .strokeBorder(AppColors.accentGold.opacity(0.26), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .disabled(isReadOnly)
        .contextMenu {
            Button(role: .destructive) {
                deckPendingDeletion = deck
            } label: {
                Label(l10n.t("common.delete"), systemImage: "trash")
            }
        }
    }

    private func displayName(_ deck: CustomDeck?) -> String {
        let name = deck?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? l10n.t("customDeck.defaultName") : name
    }

    private func subtitle(for deck: CustomDeck) -> String {
        let words = l10n.t("customDeck.wordCount", count: deck.wordCount)
        guard deck.canPlay else {
            return "\(words) · \(l10n.t("customDeck.needsMore", count: CustomDeckLimits.minWordsToPlay))"
        }
        return "\(words) · \(l10n.t("customDeck.editedAt", ["when": relative(deck.updatedAt)]))"
    }

    private func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: l10n.localeCode)
        formatter.unitsStyle = .full
        // `.named` yakın zamanı "şimdi"/"dün" diye yazıyor; ham biçim az önce
        // düzenlenen destede "0 saniye içinde" gibi geleceğe bakan bir metin
        // üretiyordu. Tarih ayrıca şimdiye kırpılıyor.
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: min(date, .now), relativeTo: .now)
    }

    // MARK: Yeni deste

    private var addRow: some View {
        Button(action: createDeck) {
            VStack(spacing: 7) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.accentGold)

                Text(l10n.t("customDeck.new"))
                    .font(AppFont.display(14, weight: .semibold))
                    .appTracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.accentGold)

                Text(l10n.t("customDeck.list.emptySlot", ["index": "\(decks.count + 1)"]))
                    .font(AppFont.ui(10))
                    .foregroundStyle(AppColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background {
                RoundedRectangle(cornerRadius: 13)
                    .fill(AppColors.surfaceCard.opacity(0.4))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13).strokeBorder(
                            AppColors.accentGold.opacity(0.42),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                        )
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private var slotsFullNote: some View {
        Text(l10n.t("customDeck.slotsFull"))
            .font(AppFont.ui(11, weight: .semibold))
            .appTracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
    }

    // MARK: Eylemler

    private func createDeck() {
        guard hasFreeSlot else {
            Haptics.lockedWall()
            router.openPaywall(.customDeck)
            return
        }
        Haptics.secondaryButton()
        // İsimsiz deste hemen yazılıyor: editör otomatik kaydediyor. İsim
        // boş bırakılıyor — "Yeni Deste" hem satır hem + kartı olmasın diye.
        let deck = CustomDeck(
            name: "",
            languageCode: l10n.localeCode,
            sortIndex: (decks.map(\.sortIndex).max() ?? -1) + 1
        )
        modelContext.insert(deck)
        modelContext.persistCustomDecks()
        Analytics.customDeckCreate(wordCount: 0)
        router.push(.customEditor(deck.uuid.uuidString))
    }

    private func deletePending() {
        guard let deck = deckPendingDeletion else { return }
        deckPendingDeletion = nil
        Haptics.deckDeselected()
        modelContext.delete(deck)
        modelContext.persistCustomDecks()
    }
}
