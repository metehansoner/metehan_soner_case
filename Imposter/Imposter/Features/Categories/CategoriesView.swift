import SwiftUI

struct CategoriesView: View {
    @Bindable var session: GameSession
    var onBack: () -> Void
    var onPlay: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @Bindable private var store = SubscriptionStore.shared
    @State private var showSettings = false
    @State private var showHowTo = false
    @State private var showCategoryPaywall = false
    @State private var showFullPaywall = false
    @State private var pendingLockedCategoryID: String?
    @State private var adErrorMessage: String?

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                ScreenChromeHeader(
                    title: l10n.t("categories.title"),
                    onBack: {
                        Haptics.light()
                        onBack()
                    },
                    onInfo: {
                        Haptics.light()
                        showHowTo = true
                    },
                    onSettings: {
                        Haptics.light()
                        showSettings = true
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView {
                    surpriseButton
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(CategoryCatalog.all) { category in
                            categoryCard(category)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }

            VStack {
                Spacer(minLength: 0)
                PlayBar(
                    playTitle: l10n.t("common.play"),
                    count: session.selectedCategoryIDs.count,
                    countSystemImage: "square.grid.2x2.fill",
                    countAccessibilityLabel: l10n.t(
                        "categories.selected",
                        ["n": "\(session.selectedCategoryIDs.count)"]
                    ),
                    enabled: session.canContinueCategories
                ) {
                    Haptics.medium()
                    onPlay()
                }
            }

            if showCategoryPaywall {
                CategoryPaywallView(
                    onClose: {
                        showCategoryPaywall = false
                        pendingLockedCategoryID = nil
                        adErrorMessage = nil
                    },
                    onWatchAd: {
                        adErrorMessage = nil
                        RewardedAdService.shared.show(
                            onRewarded: {
                                guard let id = pendingLockedCategoryID else { return }
                                // Unlock only this category for the current session / round setup.
                                session.adUnlockedCategoryIDs.insert(id)
                                session.selectedCategoryIDs.insert(id)
                                showCategoryPaywall = false
                                pendingLockedCategoryID = nil
                                adErrorMessage = nil
                                Haptics.success()
                            },
                            onFailed: { message in
                                adErrorMessage = message
                                Haptics.error()
                                RewardedAdService.shared.preload()
                            }
                        )
                    },
                    onPurchaseYearly: {
                        Task {
                            store.selectedPlan = .yearly
                            await store.purchaseSelectedPlan()
                            guard store.isPremium else { return }
                            showCategoryPaywall = false
                            pendingLockedCategoryID = nil
                            adErrorMessage = nil
                        }
                    },
                    adErrorMessage: adErrorMessage
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .navigationBarHidden(true)
        .onSwipeBack(perform: onBack)
        .id(store.isPremium)
        .animation(.easeOut(duration: 0.2), value: showCategoryPaywall)
        .onAppear {
            if session.selectedCategoryIDs.isEmpty {
                session.selectedCategoryIDs.insert("party")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .sheet(isPresented: $showHowTo) {
            HowToPlaySheet(mode: session.selectedMode)
        }
        .fullScreenCover(isPresented: $showFullPaywall) {
            PaywallView(presentation: .modal) {
                showFullPaywall = false
            }
        }
    }

    private func isLocked(_ category: CategoryDef) -> Bool {
        category.isLocked(adUnlockedIDs: session.adUnlockedCategoryIDs)
    }

    private var surpriseButton: some View {
        Button {
            guard store.isPremium else {
                Haptics.warning()
                showFullPaywall = true
                return
            }
            guard let pick = CategoryCatalog.all.randomElement() else { return }
            Haptics.success()
            session.selectedCategoryIDs = [pick.id]
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "dice.fill")
                    .font(.system(size: 18, weight: .bold))
                Text(l10n.t("categories.surprise"))
                    .font(AppFont.display(18, weight: .black))
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColors.drawCardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppColors.accentCyan.opacity(0.6), lineWidth: 1.5)
                    )
                    .shadow(color: AppColors.accentCyan.opacity(0.4), radius: 14, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    private func categoryCard(_ category: CategoryDef) -> some View {
        let locked = isLocked(category)
        let selected = session.selectedCategoryIDs.contains(category.id)

        return Button {
            if locked {
                Haptics.warning()
                pendingLockedCategoryID = category.id
                showCategoryPaywall = true
                return
            }
            Haptics.medium()
            if selected {
                session.selectedCategoryIDs.remove(category.id)
            } else {
                session.selectedCategoryIDs.insert(category.id)
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(category.imageName)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(height: 92)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)

                    if locked {
                        badge(systemName: "lock.fill", bg: AppColors.overlayScrim, fg: AppColors.textPrimary)
                    } else if selected {
                        badge(systemName: "checkmark", bg: AppColors.accentCyan, fg: AppColors.textOnLight)
                    }
                }

                Text(l10n.t(category.titleKey))
                    .font(AppFont.display(17, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColors.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                selected && !locked
                                    ? AppColors.accentCyan
                                    : AppColors.accentCyan.opacity(0.12),
                                lineWidth: selected && !locked ? 2.5 : 1
                            )
                    )
                    .opacity(locked ? 0.72 : 1)
            )
            .shadow(color: selected && !locked ? AppColors.accentCyan.opacity(0.35) : .clear, radius: 12)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selected)
        }
        .buttonStyle(.plain)
    }

    private func badge(systemName: String, bg: Color, fg: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(fg)
            .frame(width: 26, height: 26)
            .background(Circle().fill(bg))
            .padding(8)
    }
}
