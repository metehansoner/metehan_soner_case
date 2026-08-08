import SwiftUI


struct PaywallView: View {
    let context: PaywallContext
    var variant: PaywallVariant
    var onClose: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedPlan: SubscriptionStore.Plan = .weekly
    @State private var status: Status?

    @State private var canDismiss = false


    @State private var shownAt = Date.now

    private enum Status: Equatable {
        case restored
        case nothingToRestore
        case purchaseFailed
    }


    private var prefersScrollLayout: Bool {
        typeSize.isAccessibilitySize || AppLayout.isRegularWidth(horizontalSizeClass)
    }


    private var usesShowcaseChrome: Bool {
        variant == .onboarding
            || context == .vipButton
            || context == .roundEnd
    }

    var body: some View {
        ZStack(alignment: .top) {
            VelvetBackground(showsCurtain: true).ignoresSafeArea()

            GeometryReader { geometry in
                let headerHeight = showcaseHeaderHeight(for: geometry.size.height)
                let needsScroll = prefersScrollLayout
                    || geometry.size.height < (usesShowcaseChrome ? 780 : 680)

                Group {
                    if needsScroll {
                        ScrollView {
                            column(fillsHeight: false, headerHeight: headerHeight)
                                .padding(.bottom, 28)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    } else {
                        column(fillsHeight: true, headerHeight: headerHeight)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .readableWidth()
                .frame(width: geometry.size.width, height: geometry.size.height)
            }


            .ignoresSafeArea(edges: .top)

            topChrome
        }
        .task {
            settings.paywallSeen = true
            shownAt = .now
            Analytics.paywallView(variant: variant.analyticsName, context: context.id)
            await store.refresh()
            selectDefaultPlan()
        }
        .onChange(of: store.offers.map(\.id)) { _, _ in
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


    private var topChrome: some View {
        HStack(alignment: .top) {
            restoreControl
            Spacer(minLength: 8)
            escapeControl
        }
        .padding(.horizontal, 12)
        .safeAreaPadding(.top, 8)
    }


    private func column(fillsHeight: Bool, headerHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            header(height: headerHeight)

            if fillsHeight { Spacer(minLength: 4) }

            offerCopy

            if fillsHeight { Spacer(minLength: 8) }

            callToAction
                .padding(.horizontal, 20)
                .padding(.top, fillsHeight ? 4 : 22)
                .padding(.bottom, fillsHeight ? 12 : 24)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: fillsHeight ? .infinity : nil,
            alignment: .top
        )
    }

    private func showcaseHeaderHeight(for screenHeight: CGFloat) -> CGFloat {
        guard usesShowcaseChrome else {
            return min(274, max(180, screenHeight * 0.28))
        }

        return min(340, max(160, screenHeight * 0.32))
    }


    @ViewBuilder
    private func header(height: CGFloat) -> some View {
        if usesShowcaseChrome {
            PosterWall(decks: DeckCatalog.v1)
                .frame(height: height)
        } else {
            contextHero
                .frame(height: height)
        }
    }


    private var contextHero: some View {
        ZStack(alignment: .bottom) {
            PosterWall(decks: DeckCatalog.v1, opacity: 0.3)

            if let deck = contextDeck {
                heroCard(for: deck).padding(.bottom, 6)
            }
        }
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
                .appTracking(1.3)
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


    private var offerCopy: some View {
        VStack(spacing: 0) {
            if usesShowcaseChrome {
                plaque
                headline.padding(.top, 14)
            } else {
                contextHeadline
            }

            subline.padding(.top, 7)

            plans.padding(.top, 18)
        }
        .padding(.horizontal, 20)

        .padding(.top, usesShowcaseChrome ? -6 : 10)
        .frame(maxWidth: .infinity)
    }


    private var plaque: some View {
        Text(l10n.t("paywall.plaque"))
            .font(AppFont.display(22, weight: .bold))
            .appTracking(3.6)
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
            if usesShowcaseChrome {
                Text(l10n.t("paywall.summary.features"))
            }
        }
        .font(AppFont.ui(12))
        .foregroundStyle(AppColors.textSecondary)
        .multilineTextAlignment(.center)
        .lineSpacing(3)
    }


    @ViewBuilder
    private var plans: some View {
        if store.offers.isEmpty {
            unavailableNotice
        } else {
            VStack(spacing: 15) {
                ForEach(store.offers) { offer in
                    PlanCard(offer: offer, isSelected: offer.plan == selectedPlan) {


                        Analytics.paywallPlanSelect(plan: offer.plan.rawValue)
                        selectedPlan = offer.plan
                    }
                }
            }
        }
    }


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


    private var restoreControl: some View {
        Button {
            Task { await restore() }
        } label: {
            if store.isRestoring {
                ProgressView()
                    .tint(AppColors.textSecondary)
                    .scaleEffect(0.85)
                    .frame(height: 14)
            } else {
                Text(l10n.t("paywall.restore"))
                    .font(AppFont.display(12, weight: .semibold))
                    .appTracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(store.isRestoring)
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


    @ViewBuilder
    private var escapeControl: some View {
        switch variant {
        case .onboarding:
            Button(action: dismiss) {
                Text(l10n.t("paywall.skip"))
                    .font(AppFont.display(12, weight: .semibold))
                    .appTracking(2)
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

        case .modal:
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 38, height: 38)
                    .background {
                        Circle()
                            .fill(AppColors.bgFilmBlack.opacity(0.66))
                            .overlay {
                                Circle().strokeBorder(
                                    AppColors.accentGold.opacity(0.34), lineWidth: 1
                                )
                            }
                    }
                    .frame(width: 52, height: 52)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("common.close"))
            .opacity(canDismiss ? 1 : 0)
            .allowsHitTesting(canDismiss)
        }
    }


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


    private func selectDefaultPlan() {
        guard !store.offers.contains(where: { $0.plan == selectedPlan }) else { return }
        selectedPlan = store.offers.first?.plan ?? .weekly
    }


    private var selectedOffer: SubscriptionStore.PlanOffer? {
        store.offers.first { $0.plan == selectedPlan }
    }


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
