import SwiftUI

/// Ekran 9 — Nasıl Oynanır (§ `02` §4).
///
/// Onboarding 3 adıma indikten sonra **detaylı anlatımın tek sahibi bu ekran**
/// (§ `03` §1): onboarding ikna ediyor, bu slider talimat veriyor. Pratik
/// sonucu, slider kısaltılmıyor — yedeği yok.
///
/// Gösterim kuralı § `02` §4: mod başına bir kez otomatik
/// (`AppSettingsStore.howToSeenModes`), sonrasında Deste Detayı ve Duraklat
/// ekranındaki `?` butonundan her zaman.
struct HowToPlaySlider: View {
    let mode: GameMode
    /// Otomatik gösterimde son sayfanın butonu `HAZIRIZ` ve tur başlıyor;
    /// `?` ile açıldığında `KAPAT` ve hiçbir şey başlamıyor.
    var startsRound: Bool
    var onClose: () -> Void
    var onFinish: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings

    @State private var index = 0

    #if DEBUG
    /// Simülatörde sayfa kaydırılamıyor; `-HowToPage 4` doğrudan o sayfayı açıyor.
    private var debugStartPage: Int? {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.drop(while: { $0 != "-HowToPage" }).dropFirst().first.flatMap(Int.init)
    }
    #endif

    var body: some View {
        SheetScaffold(title: l10n.t("howToPlay.title"), onClose: onClose) {
            VStack(spacing: 0) {
                FilmStripProgress(total: pages.count, current: index)
                    .frame(width: 132)
                    .padding(.bottom, 4)

                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { offset, page in
                        HowToPlayPage(page: page)
                            .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Text(l10n.t("howToPlay.pageCount", ["current": "\(index + 1)", "total": "\(pages.count)"]))
                    .font(AppFont.display(11, weight: .semibold))
                    .appTracking(2.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.accentBrass)
                    .padding(.bottom, 12)

                Button(l10n.t(isLastPage ? finishKey : "howToPlay.next")) {
                    Haptics.primaryButton()
                    advance()
                }
                .buttonStyle(MarqueeButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .animation(.easeOut(duration: 0.2), value: index)
            // §03 §5: hangi sayfada bırakıldığı, slider'ın uzunluğunu
            // tartışmanın tek verisi.
            .onChange(of: index, initial: true) { _, page in
                Analytics.howToView(mode: mode.id, page: page + 1)
            }
            #if DEBUG
            .onAppear {
                if let page = debugStartPage { index = min(page, pages.count) - 1 }
            }
            #endif
        }
    }

    private var isLastPage: Bool { index >= pages.count - 1 }
    private var finishKey: String { startsRound ? "howToPlay.ready" : "common.close" }

    private func advance() {
        guard isLastPage else {
            index += 1
            return
        }
        settings.markHowToPlaySeen(mode)
        onFinish()
    }

    /// § `02` §4'teki dört sayfa. İki kural içeriği moda göre değiştiriyor:
    ///
    /// 1. `Canlandır`da sayfa 2 ve 3 **yer değişiyor** ve metinler tersine
    ///    dönüyor — o modda telefonu canlandıran tutuyor (§ `04` §1).
    /// 2. Sayfa 4 `usesTilt == false` **veya** kullanıcı ayarlardan `DOKUN`
    ///    seçtiyse gizleniyor (§ `09` §9): olmayan bir jesti anlatan sayfa,
    ///    kullanıcıyı oyunun bozuk olduğuna ikna ediyor.
    private var pages: [HowToPage] {
        let deck = HowToPage(
            titleKey: "howToPlay.deck.title",
            bodyKey: "howToPlay.deck.body",
            artwork: .posterFan
        )
        let forehead = HowToPage(
            titleKey: mode == .actOut ? "howToPlay.hold.actOut.title" : "howToPlay.hold.title",
            bodyKey: mode == .actOut ? "howToPlay.hold.actOut.body" : "howToPlay.hold.body",
            artwork: .illustration("ob_forehead")
        )
        let mime = HowToPage(
            titleKey: mode == .actOut ? "howToPlay.mime.actOut.title" : "howToPlay.mime.title",
            bodyKey: mode == .actOut ? "howToPlay.mime.actOut.body" : "howToPlay.mime.body",
            emphasisKey: "howToPlay.mime.emphasis",
            artwork: .illustration("ob_mime")
        )
        let tilt = HowToPage(
            titleKey: "howToPlay.tilt.title",
            bodyKey: "howToPlay.tilt.body",
            artwork: .tiltDiagram
        )

        var pages = mode == .actOut ? [deck, mime, forehead] : [deck, forehead, mime]
        if mode.usesTilt, !settings.prefersTouchAnswers {
            pages.append(tilt)
        }
        return pages
    }
}

// MARK: - Sayfa

struct HowToPage {
    enum Artwork {
        /// Yelpaze gibi açılmış 4 afiş — üretilmiş görsel yok, kart anatomisi
        /// zaten kodda (§ `01` §4), dört kopyası açıyla diziliyor.
        case posterFan
        case illustration(String)
        /// Yatay telefonun öne/arkaya eğildiği yeşil/kırmızı diyagram.
        case tiltDiagram
    }

    let titleKey: String
    let bodyKey: String
    var emphasisKey: String?
    let artwork: Artwork
}

private struct HowToPlayPage: View {
    let page: HowToPage

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        VStack(spacing: 0) {
            artwork
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 12)

            Text(l10n.t(page.titleKey))
                .font(AppFont.display(20, weight: .bold))
                .appTracking(2.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textCream)
                .padding(.top, 10)

            VStack(spacing: 2) {
                Text(l10n.t(page.bodyKey))
                    .font(AppFont.ui(13))
                    .foregroundStyle(AppColors.textSecondary)

                if let emphasisKey = page.emphasisKey {
                    Text(l10n.t(emphasisKey))
                        .font(AppFont.ui(13, weight: .bold))
                        .foregroundStyle(AppColors.textCream)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.top, 7)
            .padding(.horizontal, 26)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var artwork: some View {
        switch page.artwork {
        case .posterFan:
            PosterFan()
        case .illustration(let name):
            Image(name)
                .resizable()
                .scaledToFit()
        case .tiltDiagram:
            TiltAnswerDiagram()
        }
    }
}
