import SwiftUI

struct CategoriesView: View {
    @Bindable var session: GameSession
    var onBack: () -> Void
    var onPlay: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @Bindable private var store = SubscriptionStore.shared
    @State private var showSettings = false
    @State private var showFullPaywall = false
    @State private var showCategoryPaywall = false
    @State private var pendingLockedCategoryID: String?
    /// Alternates between full paywall and category (ad + yearly) paywall.
    @State private var preferCategoryPaywallNext = true

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
                    onSettings: {
                        Haptics.light()
                        showSettings = true
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(CategoryCatalog.all) { category in
                            categoryCard(category)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
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
                    },
                    onWatchAd: {
                        // Placeholder until rewarded ads are connected.
                        if let id = pendingLockedCategoryID {
                            session.adUnlockedCategoryIDs.insert(id)
                            session.selectedCategoryIDs.insert(id)
                        }
                        showCategoryPaywall = false
                        pendingLockedCategoryID = nil
                        Haptics.success()
                    },
                    onPurchaseYearly: {
                        Task {
                            store.selectedPlan = .yearly
                            await store.purchaseSelectedPlan()
                            showCategoryPaywall = false
                            pendingLockedCategoryID = nil
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .navigationBarHidden(true)
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
        .fullScreenCover(isPresented: $showFullPaywall) {
            PaywallView(presentation: .modal) {
                showFullPaywall = false
                pendingLockedCategoryID = nil
            }
        }
    }

    private func isLocked(_ category: CategoryDef) -> Bool {
        category.isLocked(adUnlockedIDs: session.adUnlockedCategoryIDs)
    }

    private func categoryCard(_ category: CategoryDef) -> some View {
        let locked = isLocked(category)
        let selected = session.selectedCategoryIDs.contains(category.id)

        return Button {
            if locked {
                Haptics.warning()
                pendingLockedCategoryID = category.id
                if preferCategoryPaywallNext {
                    showCategoryPaywall = true
                } else {
                    showFullPaywall = true
                }
                preferCategoryPaywallNext.toggle()
                return
            }
            Haptics.medium()
            if selected {
                session.selectedCategoryIDs.remove(category.id)
            } else {
                session.selectedCategoryIDs.insert(category.id)
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(l10n.t(category.titleKey))
                            .font(AppFont.display(22, weight: .black))
                            .foregroundStyle(AppColors.textPrimary)
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if selected && !locked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.accentCyan)
                        }
                    }

                    Text(l10n.t(category.descKey))
                        .font(AppFont.ui(13))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }

                Spacer(minLength: 4)

                Image(category.imageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 108, height: 108)
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            }
            .padding(.leading, 18)
            .padding(.trailing, 10)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppColors.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(
                                selected && !locked
                                    ? AppColors.accentCyan
                                    : AppColors.accentCyan.opacity(0.12),
                                lineWidth: selected && !locked ? 2 : 1
                            )
                    )
                    .opacity(locked ? 0.72 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
