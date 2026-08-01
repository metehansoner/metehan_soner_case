import SwiftUI

/// Ekran 16 — 02-ekran-akisi.md §4, davranışı 04-oyun-modlari.md §3 ve
/// 09-kesinti-ve-sinir-durumlari.md §3.
///
/// Oyun akışı `NavigationStack`in tamamının yerine render edildiği ve
/// swipe-back kapatıldığı için (§02 §5) **çıkışın tek yolu burası.** Bu ekran
/// modellenmezse kullanıcı oyunda kilitli kalıyor.
struct PauseOverlay: View {
    let reason: LiveGame.PauseReason
    /// Takım Savaşı'nda çıkış turu değil maçın tamamını siliyor (§09 §3).
    var cancelsMatch = false
    var onResume: () -> Void
    var onRestart: () -> Void
    var onHowToPlay: () -> Void
    var onExit: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @State private var isConfirmingExit = false

    var body: some View {
        ZStack {
            AppColors.bgFilmBlack.opacity(0.86)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 13) {
                    Text(l10n.t(reason == .system ? "pause.system.title" : "pause.title"))
                        .font(AppFont.display(26, weight: .bold))
                        .appTracking(6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.textCream)
                        .padding(.bottom, 6)

                    // §09 §2: sistem kesintisinde kullanıcı neden duraklandığını
                    // bilmiyor; otomatik devam da yok, o yüzden bir satır açıklama.
                    if reason == .system {
                        Text(l10n.t("pause.system.body"))
                            .textStyle(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 4)
                    }

                    PauseButton(
                        title: l10n.t("pause.resume"),
                        systemImage: "play.fill",
                        kind: .primary,
                        action: onResume
                    )
                    PauseButton(
                        title: l10n.t("pause.restart"),
                        systemImage: "arrow.counterclockwise",
                        kind: .normal,
                        action: onRestart
                    )
                    PauseButton(
                        title: l10n.t("pause.howToPlay"),
                        systemImage: "questionmark.circle",
                        kind: .normal,
                        action: onHowToPlay
                    )
                    PauseButton(
                        title: l10n.t("pause.exit"),
                        systemImage: "rectangle.portrait.and.arrow.right",
                        kind: .danger
                    ) {
                        Haptics.secondaryButton()
                        isConfirmingExit = true
                    }

                    Text(l10n.t(cancelsMatch ? "pause.exit.hint.match" : "pause.exit.hint"))
                        .textStyle(.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .padding(.top, 6)
                }
                .padding(.vertical, 26)
                .frame(maxWidth: .infinity)
            }
        }
        // §04 §3: kazara çıkış tur sonuçlarını yok ediyor, onay zorunlu.
        .confirmationDialog(
            l10n.t(cancelsMatch ? "pause.exit.confirm.title.match" : "pause.exit.confirm.title"),
            isPresented: $isConfirmingExit,
            titleVisibility: .visible
        ) {
            Button(l10n.t("pause.exit.confirm.action"), role: .destructive, action: onExit)
            Button(l10n.t("common.cancel"), role: .cancel) {}
        } message: {
            Text(l10n.t(cancelsMatch ? "pause.exit.confirm.body.match" : "pause.exit.confirm.body"))
        }
    }
}

private struct PauseButton: View {
    enum Kind { case primary, normal, danger }

    let title: String
    let systemImage: String
    var kind: Kind = .normal
    let action: () -> Void

    var body: some View {
        Button {
            if kind == .primary { Haptics.primaryButton() } else { Haptics.secondaryButton() }
            action()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(AppFont.display(14, weight: .semibold))
                    .appTracking(2.4)
                    .textCase(.uppercase)
            }
            .foregroundStyle(foreground)
            .frame(width: 236, height: 46)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(kind == .primary ? AppColors.accentAmber : AppColors.surfaceCardRaised.opacity(0.8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12).strokeBorder(
                            kind == .primary ? AppColors.accentAmber : AppColors.accentGold.opacity(0.5),
                            lineWidth: 1.5
                        )
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch kind {
        case .primary: AppColors.textOnAmber
        case .normal: AppColors.textCream
        case .danger: Color(hex: 0xE0796C)
        }
    }
}
