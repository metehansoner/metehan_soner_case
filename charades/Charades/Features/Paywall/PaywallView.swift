import SwiftUI

/// Paywall — 03-onboarding-paywall.md §2, `paywall.html`.
///
/// Yapı kararı: **önce malı göster, sonra para iste.** Ekranın üst yarısı
/// içerik duvarı, alt yarısı ödeme. Fayda listesi yok; 92 gerçek kapak sekiz
/// maddelik bir listeden daha ikna edici.
///
/// Varyant A (onboarding sonu) ve B (kilitli içeriğe dokunuş) aynı gövdeyi
/// paylaşıyor, yalnızca üst bölge ve kaçış yolu değişiyor.
struct PaywallView: View {
    let context: PaywallContext
    var variant: PaywallVariant
    var onClose: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(SubscriptionStore.self) private var store

    @State private var selectedPlan: SubscriptionStore.Plan = .weekly
    @State private var status: Status?
    /// §03 §2 varyant B: kapatma `X` 1,5 saniye gecikmeyle görünüyor.
    @State private var canDismiss = false
    /// §03 §5 `paywall_dismiss.seconds_shown`. Yarım saniyede kapatılan paywall
    /// ile 20 saniye okunan aynı satıra düşerse ölçüm hiçbir şey söylemiyor.
    @State private var shownAt = Date.now

    private enum Status: Equatable {
        case restored
        case nothingToRestore
        case purchaseFailed
    }

    var body: some View {
        ZStack(alignment: .top) {
            VelvetBackground(showsCurtain: true).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                    offerBody
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            escapeControl
        }
        .task {
            settings.paywallSeen = true
            shownAt = .now
            Analytics.paywallView(variant: variant.analyticsName, context: context.id)
            if store.offers.isEmpty { await store.refresh() }
            selectDefaultPlan()
        }
        .task {
            guard variant == .modal else { return }
            try? await Task.sleep(for: .milliseconds(1500))
            withAnimation(.easeOut(duration: 0.2)) { canDismiss = true }
        }
        .onChange(of: store.isPremium) { _, isPremium in
            if isPremium { onClose() }
        }
    }

    // MARK: Üst bölge

    @ViewBuilder
    private var header: some View {
        switch variant {
        case .onboarding:
            PosterWall(decks: DeckCatalog.v1).frame(height: 318)
        case .modal:
            contextHero
        }
    }

    /// §03 §2 varyant B: duvar %30 opaklığa çekiliyor, dokunulan destenin
    /// kapağı büyük geliyor. Kullanıcı soyut "92 deste" değil, o an istediği
    /// şeyi görüyor.
    private var contextHero: some View {
        ZStack(alignment: .bottom) {
            PosterWall(decks: DeckCatalog.v1, opacity: 0.3)

            if let deck = contextDeck {
                heroCard(for: deck).padding(.bottom, 6)
            }
        }
        .frame(height: contextDeck == nil ? 210 : 274)
    }

    private func heroCard(for deck: DeckDef) -> some View {
        DeckMiniPoster(deck: deck)
            .frame(width: 142, height: 190)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.accentGold, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.7), radius: 18, y: 12)
            .shadow(color: AppColors.accentAmber.opacity(0.42), radius: 23)
            .overlay(alignment: .top) { lockBadge.offset(y: -9) }
    }

    private var lockBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill").font(.system(size: 8, weight: .bold))
            Text(l10n.t("deck.locked.stamp"))
                .font(AppFont.ui(8, weight: .bold))
                .tracking(1.3)
                .textCase(.uppercase)
        }
        .foregroundStyle(AppColors.accentGold)
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background {
            RoundedRectangle(cornerRadius: 5)
                .fill(AppColors.bgFilmBlack)
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(AppColors.accentGold, lineWidth: 1)
                }
        }
        .fixedSize()
    }

    // MARK: Gövde

    private var offerBody: some View {
        VStack(spacing: 0) {
            if variant == .onboarding {
                plaque
                headline.padding(.top, 14)
            } else {
                contextHeadline
            }

            subline.padding(.top, 7)

            plans.padding(.top, 20)

            callToAction.padding(.top, 22)
        }
        .padding(.horizontal, 20)
        .padding(.top, variant == .onboarding ? 0 : 13)
        .padding(.bottom, 24)
    }

    /// §03 §2 madde 2: pirinç plakete basılı `TAM BİLET`, ampulleri yanar.
    private var plaque: some View {
        Text(l10n.t("paywall.plaque"))
            .font(AppFont.display(22, weight: .bold))
            .tracking(3.6)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.surfacePoster)
            .shadow(color: AppColors.accentAmber.opacity(0.5), radius: 8)
            .padding(.horizontal, 22)
            .padding(.vertical, 7)
            .background {
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.bgVelvetDeep.opacity(0.92),
                                AppColors.bgFilmBlack.opacity(0.9),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(AppColors.accentBrass, lineWidth: 1.5)
                    }
                    .shadow(color: AppColors.accentAmber.opacity(0.22), radius: 13)
            }
            .overlay {
                BulbFrame(countPerEdge: 4, diameter: 4.5, color: AppColors.accentAmber)
                    .padding(.horizontal, 14)
                    .padding(.vertical, -2)
            }
    }

    private var headline: some View {
        VStack(spacing: 0) {
            Text(l10n.t("paywall.headline.line1"))
                .font(AppFont.accent(25, weight: .bold))
                .foregroundStyle(AppColors.textCream)
            Text(l10n.t("paywall.headline.line2"))
                .font(AppFont.accent(25, weight: .bold, italic: true))
                .foregroundStyle(AppColors.accentGold)
        }
        .multilineTextAlignment(.center)
        .lineSpacing(2)
    }

    /// §03 §2 varyant B: başlık bağlamı taşıyor. Deste/mod adı altın ve italik
    /// vurgulanıyor; dizgideki yeri dilden dile değiştiği için metin içinde
    /// aranıp biçimlendiriliyor.
    private var contextHeadline: some View {
        Text(highlighted(contextTitleTemplate, emphasis: contextName))
            .font(AppFont.accent(22, weight: .bold))
            .foregroundStyle(AppColors.textCream)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }

    private var subline: some View {
        VStack(spacing: 2) {
            Text(contextSummary)
            if variant == .onboarding {
                Text(l10n.t("paywall.summary.features"))
            }
        }
        .font(AppFont.ui(12))
        .foregroundStyle(AppColors.textSecondary)
        .multilineTextAlignment(.center)
        .lineSpacing(3)
    }

    // MARK: Planlar

    @ViewBuilder
    private var plans: some View {
        if store.offers.isEmpty {
            unavailableNotice
        } else {
            VStack(spacing: 15) {
                ForEach(store.offers) { offer in
                    PlanCard(offer: offer, isSelected: offer.plan == selectedPlan) {
                        // Varsayılan plan teklifler gelince programatik
                        // oturuyor; funnel'da seçim sayılan tek şey dokunuş.
                        Analytics.paywallPlanSelect(plan: offer.plan.rawValue)
                        selectedPlan = offer.plan
                    }
                }
            }
        }
    }

    /// §09 §7 son satır: temiz kurulum + ağ yok + gerçek abone. Planlar
    /// gelmediğinde kullanıcıyı boş ekranla bırakmıyoruz; geri yükleme yolu
    /// aşağıdaki alt satırda her zaman duruyor.
    private var unavailableNotice: some View {
        VStack(spacing: 10) {
            if store.isLoadingOffers {
                ProgressView().tint(AppColors.accentGold)
                Text(l10n.t("paywall.loading"))
            } else {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.accentBrass)
                Text(l10n.t("paywall.offline"))
            }
        }
        .font(AppFont.ui(12))
        .foregroundStyle(AppColors.textMuted)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
    }

    // MARK: CTA + alt satır

    private var callToAction: some View {
        VStack(spacing: 0) {
            Button {
                Task { await purchase() }
            } label: {
                if store.isPurchasing {
                    ProgressView().tint(AppColors.textOnAmber)
                } else {
                    Text(ctaTitle)
                }
            }
            .buttonStyle(MarqueeButtonStyle())
            .disabled(selectedOffer == nil || store.isPurchasing)

            Text(fineprint)
                .font(AppFont.ui(10))
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 9)

            if let status {
                Text(l10n.t(statusKey(status)))
                    .font(AppFont.ui(10.5, weight: .medium))
                    .foregroundStyle(
                        status == .restored ? AppColors.stateCorrect : AppColors.stateSkip
                    )
                    .multilineTextAlignment(.center)
                    .padding(.top, 7)
            }

            legalRow.padding(.top, 11)
        }
    }

    private var legalRow: some View {
        HStack(spacing: 18) {
            Button {
                Task { await restore() }
            } label: {
                Text(l10n.t("paywall.restore"))
            }
            .disabled(store.isRestoring)

            if let terms = LegalLinks.terms {
                Link(l10n.t("paywall.terms"), destination: terms)
            }
            if let privacy = LegalLinks.privacy {
                Link(l10n.t("paywall.privacy"), destination: privacy)
            }
        }
        .font(AppFont.ui(10.5))
        .foregroundStyle(AppColors.textMuted)
        .buttonStyle(.plain)
    }

    /// §03 §2: `ATLA` onboarding varyantında görünür ve sağ üstte — kaçış yolu
    /// gizlenmiyor. Modalda yerini 1,5 saniye gecikmeli `X` alıyor.
    @ViewBuilder
    private var escapeControl: some View {
        switch variant {
        case .onboarding:
            Button(action: dismiss) {
                Text(l10n.t("paywall.skip"))
                    .font(AppFont.display(12, weight: .semibold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(AppColors.bgFilmBlack.opacity(0.55))
                            .overlay {
                                Capsule().strokeBorder(
                                    AppColors.accentGold.opacity(0.3), lineWidth: 1
                                )
                            }
                    }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)
            .padding(.top, 4)

        case .modal:
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background {
                        Circle()
                            .fill(AppColors.bgFilmBlack.opacity(0.66))
                            .overlay {
                                Circle().strokeBorder(
                                    AppColors.accentGold.opacity(0.34), lineWidth: 1
                                )
                            }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("common.close"))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)
            .padding(.top, 6)
            .opacity(canDismiss ? 1 : 0)
            .allowsHitTesting(canDismiss)
        }
    }

    // MARK: Eylemler

    /// Satın alma başarıyla bitince paywall kapanıyor ama bu bir `dismiss`
    /// değil: funnel'da "vazgeçti" ile "aldı" aynı satıra düşmemeli.
    private func dismiss() {
        Analytics.paywallDismiss(
            variant: variant.analyticsName,
            secondsShown: Date.now.timeIntervalSince(shownAt)
        )
        onClose()
    }

    private func purchase() async {
        guard let offer = selectedOffer else { return }
        status = nil
        let plan = offer.plan.rawValue
        Analytics.paywallPurchaseStart(plan: plan)

        switch await store.purchase(offer) {
        case .purchased:
            Analytics.paywallPurchaseSuccess(plan: plan)
            Haptics.purchaseSucceeded()
            SoundService.ticketStamp()
            onClose()
        case .cancelled:
            // İptal bir hata değil; App Store sayfasını açıp kapatmak
            // `purchase_fail` sayılırsa hata oranı okunamaz hâle geliyor.
            break
        case .failed(let code):
            Analytics.paywallPurchaseFail(plan: plan, errorCode: code)
            Haptics.purchaseFailed()
            status = .purchaseFailed
        }
    }

    private func restore() async {
        status = nil
        let restored = await store.restore()
        status = restored ? .restored : .nothingToRestore
        if restored {
            Haptics.purchaseSucceeded()
            SoundService.ticketStamp()
            onClose()
        }
    }

    /// §03 §2 madde 4: haftalık en üstte ve seçili, çünkü deneme yalnızca onda
    /// var — en kolay "evet" diyeceği kapı o.
    private func selectDefaultPlan() {
        guard !store.offers.contains(where: { $0.plan == selectedPlan }) else { return }
        selectedPlan = store.offers.first?.plan ?? .weekly
    }

    // MARK: Türetilen metinler

    private var selectedOffer: SubscriptionStore.PlanOffer? {
        store.offers.first { $0.plan == selectedPlan }
    }

    /// §03 §4: deneme kontrolü plan değiştikçe canlı güncelleniyor. Yıllık
    /// seçiliyken "ücretsiz dene" yazmak App Store reddi sebebi.
    private var ctaTitle: String {
        l10n.t(selectedOffer?.hasTrial == true ? "paywall.cta.trial" : "paywall.cta.buy")
    }

    private var fineprint: String {
        guard let offer = selectedOffer else { return l10n.t("paywall.fine.cancel") }
        let condition =
            offer.hasTrial
            ? l10n.t("paywall.fine.trial")
            : l10n.t(
                "paywall.fine.recurring",
                [
                    "plan": l10n.t("paywall.plan.\(offer.plan.rawValue)"),
                    "price": offer.price,
                ]
            )
        return condition + "\n" + l10n.t("paywall.fine.cancel")
    }

    private var contextDeck: DeckDef? {
        guard case .lockedDeck(let id) = context else { return nil }
        return DeckCatalog.deck(id)
    }

    private var contextName: String? {
        switch context {
        case .lockedDeck(let id):
            DeckCatalog.deck(id).map { l10n.t($0.titleKey) }
        case .lockedMode(let id):
            GameMode(rawValue: id).map { l10n.t($0.titleKey) }
        default:
            nil
        }
    }

    private var contextTitleTemplate: String {
        switch context {
        case .lockedDeck:
            l10n.t("paywall.context.deck", ["title": contextName ?? ""])
        case .lockedMode:
            l10n.t("paywall.context.mode", ["title": contextName ?? ""])
        case .mix:
            l10n.t("paywall.context.mix")
        case .customDeck:
            l10n.t("paywall.context.customDeck")
        case .vipButton, .roundEnd:
            l10n.t("paywall.headline.line1") + " " + l10n.t("paywall.headline.line2")
        }
    }

    private var contextSummary: String {
        if case .lockedDeck = context {
            return l10n.t(
                "paywall.context.deck.sub",
                count: max(DeckCatalog.v1.count - 1, 0),
                ["cards": Self.formatted(DeckCatalog.advertisedCardCount)]
            )
        }
        return l10n.t(
            "paywall.summary.content",
            [
                "decks": Self.formatted(DeckCatalog.v1.count),
                "cards": Self.formatted(DeckCatalog.advertisedCardCount),
                "languages": Self.formatted(LocalizationManager.supportedLocales.count),
            ]
        )
    }

    private func statusKey(_ status: Status) -> String {
        switch status {
        case .restored: "paywall.restore.done"
        case .nothingToRestore: "paywall.restore.none"
        case .purchaseFailed: "paywall.purchase.failed"
        }
    }

    private static func formatted(_ value: Int) -> String {
        value.formatted(.number)
    }

    /// Şablonun içindeki deste/mod adını altın ve italik yapıyor. Adın cümledeki
    /// yeri her dilde farklı olduğu için indeks değil arama kullanılıyor.
    private func highlighted(_ text: String, emphasis: String?) -> AttributedString {
        var attributed = AttributedString(text)
        guard let emphasis, !emphasis.isEmpty,
              let range = attributed.range(of: emphasis)
        else { return attributed }

        attributed[range].foregroundColor = AppColors.accentGold
        attributed[range].font = AppFont.accent(22, weight: .bold, italic: true)
        return attributed
    }
}