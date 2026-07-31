import SwiftData
import SwiftUI

/// Tur sonundaki `SEPETİ KAYDET` şeridi — 02-ekran-akisi.md §24.
///
/// Kaydetme sepet ekranında değil burada: kullanıcı oraya oynamak için gitti,
/// baştan "isim ver" demek akışa fren koyardı. Kaydedilmezse sepet `GameSetup`
/// ile kaybolacak ve bu kayıp **açıkça** yazıyor — yoksa kullanıcı 20 kelimesini
/// gittikten sonra fark ediyor.
struct SaveBasketBanner: View {
    let words: [String]

    @Environment(LocalizationManager.self) private var l10n
    @Environment(SubscriptionStore.self) private var subscription
    @Environment(\.modelContext) private var modelContext

    @Query private var decks: [CustomDeck]

    @State private var isNaming = false
    @State private var draftName = ""
    @State private var savedName: String?

    private var isSlotAvailable: Bool {
        decks.count < CustomDeckLimits.maxDeckCount(isPremium: subscription.isPremium)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: savedName == nil ? "tray.and.arrow.down" : "checkmark.seal.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(savedName == nil ? AppColors.bgVelvetDeep : Color(hex: 0x3F7A4B))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.display(13, weight: .bold))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textOnPoster)

                Text(subtitle)
                    .font(AppFont.ui(9.5))
                    .foregroundStyle(Color(hex: 0x7A6A52))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if savedName == nil {
                Button {
                    Haptics.secondaryButton()
                    draftName = defaultName
                    isNaming = true
                } label: {
                    Text(l10n.t("basket.save.action"))
                        .font(AppFont.display(12, weight: .bold))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.surfacePoster)
                        .padding(.horizontal, 16)
                        .frame(height: 34)
                        .background {
                            RoundedRectangle(cornerRadius: 9).fill(AppColors.bgVelvetDeep)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 11)
                .fill(AppColors.textOnPoster.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(AppColors.textOnPoster.opacity(0.22), lineWidth: 1)
                }
        }
        .padding(.horizontal, 30)
        .alert(l10n.t("basket.save.title"), isPresented: $isNaming) {
            TextField(l10n.t("basket.save.placeholder"), text: $draftName)
                .textInputAutocapitalization(.words)
            Button(l10n.t("common.cancel"), role: .cancel) {}
            Button(l10n.t("basket.save.confirm"), action: save)
        } message: {
            Text(l10n.t("basket.save.body", count: words.count))
        }
    }

    private var title: String {
        if let savedName { return savedName }
        return l10n.t(isSlotAvailable ? "basket.save.title" : "customDeck.slotsFull")
    }

    private var subtitle: String {
        if savedName != nil { return l10n.t("basket.save.done") }
        guard isSlotAvailable else { return l10n.t("basket.save.noSlot") }
        // §02 §24: kaybın kendisi yazıyor, "kaydetmek ister misin?" değil.
        return l10n.t("basket.save.warning", count: words.count)
    }

    /// §02 §24: varsayılan isim doldurulmuş geliyor — `KENDİ KELİMELERİM · 24 TEMMUZ`.
    private var defaultName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: l10n.localeCode)
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        let name = l10n.t("basket.save.defaultName", ["date": formatter.string(from: .now)])
        return String(name.prefix(CustomDeckLimits.maxNameLength))
    }

    private func save() {
        guard isSlotAvailable else {
            Haptics.lockedWall()
            return
        }
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? defaultName : trimmed
        modelContext.insert(
            CustomDeck(
                name: name,
                languageCode: l10n.localeCode,
                words: words,
                savedFromBasket: true,
                sortIndex: (decks.map(\.sortIndex).max() ?? -1) + 1
            )
        )
        // Taslak artık kalıcı bir deste; bir sonraki açılışta sepete geri
        // dolmasın, kullanıcı aynı kelimeleri iki kayıtta görmesin.
        AppSettingsStore.shared.clearBasketDraft()
        Haptics.purchaseSucceeded()
        savedName = name
    }
}
