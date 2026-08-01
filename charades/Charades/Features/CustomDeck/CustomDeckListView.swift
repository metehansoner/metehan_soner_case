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
                        ForEach(Array(decks.enumerated()), id: \.element.uuid) { index, deck in
                            row(deck, isReadOnly: index >= slotLimit)
                        }

                        addRow
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
            Text(l10n.t("customDeck.delete.body", ["name": deckPendingDeletion?.name ?? ""]))
        }
    }

    // MARK: Başlık

    private var navBar: some View {
        HStack(spacing: 0) {
            Button {
                Haptics.secondaryButton()
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .flipsForRightToLeftLayoutDirection(true)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.accentGold)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("common.back"))

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

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
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
                    Text(deck.name)
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
                Image(systemName: hasFreeSlot ? "plus" : "lock.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(hasFreeSlot ? AppColors.accentGold : AppColors.stateLocked)

                Text(l10n.t(hasFreeSlot ? "customDeck.new" : "customDeck.slotsFull"))
                    .font(AppFont.display(14, weight: .semibold))
                    .appTracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(hasFreeSlot ? AppColors.accentGold : AppColors.stateLocked)

                if hasFreeSlot {
                    Text(l10n.t("customDeck.list.emptySlot", ["index": "\(decks.count + 1)"]))
                        .font(AppFont.ui(10))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background {
                RoundedRectangle(cornerRadius: 13)
                    .fill(AppColors.surfaceCard.opacity(0.4))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13).strokeBorder(
                            AppColors.accentGold.opacity(hasFreeSlot ? 0.42 : 0.18),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                        )
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Eylemler

    private func createDeck() {
        guard hasFreeSlot else {
            Haptics.lockedWall()
            router.openPaywall(.customDeck)
            return
        }
        Haptics.secondaryButton()
        // İsimsiz deste hemen yazılıyor: editör otomatik kaydediyor (mockup'taki
        // "otomatik kaydedilir" alt başlığı), yani düzenlenecek bir kayıt şart.
        let deck = CustomDeck(
            name: l10n.t("customDeck.defaultName"),
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
