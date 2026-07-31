# 07 — Teknik Mimari

Bu bölüm `Imposter` projesindeki (`/Users/metehansoner/desk/Works/Imposter`)
mevcut ve çalışan yapıyı temel alıyor; neyin aynen taşınacağı ve neyin
değiştirileceği açıkça belirtildi.

---

## 1. Temel kararlar

| Konu | Karar | Gerekçe |
|---|---|---|
| UI | %100 SwiftUI | Imposter'da kanıtlanmış; UIKit sadece haptics/font/pasteboard köprüsü |
| Minimum iOS | **17.0** | `@Observable`, SwiftData, `ContentUnavailableView` |
| Swift dili | **6.0 language mode** | Imposter'da 5.0 kalmış; yeni projede baştan 6 ile başlamak sonradan geçmekten çok kolay |
| Cihaz | Sadece iPhone | iPad v1'de yok |
| Yön | Tüm ekranlar portrait, **oyun ekranı landscape kilitli** | Alna konan telefon yatay durur |
| Renk şeması | Dark-only (`.preferredColorScheme(.dark)`) | Tema gereği |
| Xcode proje | `objectVersion 77` + synchronized folders | Dosya eklerken `pbxproj` düzenlemek gerekmiyor |
| Veri | JSON (desteler) + SwiftData (custom desteler) + UserDefaults (ayarlar) | |

---

## 2. Klasör yapısı

```
Charades/
├── CharadesApp.swift
├── Features/
│   ├── Root/            RootView, AppRoute, HeaderBar
│   ├── Onboarding/      OnboardingSheet, SocialProofView
│   ├── Decks/           DecksHomeView, DeckCard, DeckDetailSheet, FilterChips
│   ├── Mix/             MixSetupView, SavedMixesRow
│   ├── CustomDeck/      CustomDeckListView, CustomDeckEditorView, CoverPicker
│   ├── HowToPlay/       HowToPlaySlider
│   ├── ModeSelect/      ModeSelectSheet, ModeCard
│   ├── Teams/           TeamSetupView, TeamTurnHandoffView
│   ├── Game/            GameFlowView, OrientationPromptView, CountdownView,
│   │                    GameCardView, PauseOverlay, RoundEndView, MatchEndView
│   ├── Replay/          ReplayRecorder, ReplayPlayerView, ReplayArchiveView,
│   │                    ReplayReelCard, ReplayStore (kota + FIFO + temizlik)
│   ├── Paywall/         PaywallView, PlanCard, RateUsSheet
│   └── Settings/        SettingsView, LanguageSheet, SubscriptionCard
├── Models/
│   ├── DeckCatalog.swift        // 124 DeckDef (92'si v1), tek kaynak
│   ├── DeckSection.swift
│   ├── CardBank.swift           // JSON okuma + lazy cache
│   ├── GameMode.swift           // 5 mod + özellik matrisi
│   ├── LiveGame.swift           // @Observable, faz makinesi, skor
│   ├── GameSetup.swift          // seçili desteler, mod, süre, takımlar
│   └── CustomDeck.swift         // SwiftData @Model
├── Services/
│   ├── SubscriptionStore.swift  // RevenueCat
│   ├── LocalizationManager.swift
│   ├── AppSettingsStore.swift
│   ├── MotionService.swift      // CoreMotion tilt — YENİ
│   ├── SoundService.swift       // AVAudioSession — YENİ
│   ├── Haptics.swift
│   ├── Analytics.swift          // Firebase sarmalayıcı — YENİ
│   └── RemoteFlags.swift        // Remote Config sarmalayıcı
├── Components/
│   ├── Buttons.swift            // MarqueeButtonStyle, SecondaryStyle
│   ├── MarqueeSwitch.swift
│   ├── GrainOverlay.swift
│   ├── VelvetBackground.swift
│   ├── BulbRow.swift
│   ├── FilmStripProgress.swift
│   ├── PlayBar.swift
│   └── SwipeBack.swift
├── Theme/
│   ├── AppColors.swift
│   └── AppFonts.swift
└── Resources/
    ├── Fonts/                   // Oswald, Playfair Display, Rubik
    ├── Decks/                   // 92 × {id}.json (v1)
    ├── Localization/            // 25 × {kod}.json
    └── Sounds/                  // 12 × sfx_*.m4a
```

---

## 3. State yönetimi

Klasik MVVM (ayrı `ViewModels/` klasörü) **kullanılmıyor.** Bunun yerine
`@Observable` model/servis sınıfları doğrudan View'lara enjekte ediliyor —
`Imposter`'da bu yaklaşım 6.800 satırda temiz kalmış.

| Nesne | Tip | Ömür |
|---|---|---|
| `AppSettingsStore.shared` | `@Observable` singleton | Uygulama ömrü |
| `LocalizationManager.shared` | `@Observable` singleton | Uygulama ömrü |
| `SubscriptionStore.shared` | `@Observable` singleton | Uygulama ömrü |
| `GameSetup` | `@Observable`, `RootView`'da `@State` | Kurulum akışı |
| `LiveGame` | `@Observable`, `RootView`'da `@State?` | Tek maç |
| `MotionService` | `@Observable` singleton | Sadece oyun sırasında aktif |

Ayar kalıcılığı deseni (`@AppStorage` yerine, daha merkezi ve test edilebilir):
```swift
var soundEnabled: Bool {
    didSet { defaults.set(soundEnabled, forKey: Key.soundEnabled) }
}
```

`Haptics` ve `SoundService` deseni: koşul **içeride**, çağrı yerinde değil.
```swift
static func correct() {
    guard AppSettingsStore.shared.hapticsEnabled else { return }
    ...
}
```
Böylece 100+ çağrı noktasında tek satır yazılıyor. (`Imposter/Services/Haptics.swift`
aynen taşınacak.)

---

## 4. Bağımlılıklar

| Paket | Linklenecek ürünler | Amaç |
|---|---|---|
| `RevenueCat/purchases-ios-spm` | **sadece** `RevenueCat` | Abonelik |
| `firebase/firebase-ios-sdk` | `FirebaseAnalytics`, `FirebaseRemoteConfig` | Funnel + feature flag |

Bu kadar. Özellikle **eklenmeyecekler:**
- `RevenueCatUI` — paywall elle yazılıyor, tema uyumu için zorunlu. (Imposter'da
  linklenmiş ama kullanılmıyor, boşuna binary yükü.)
- `FirebaseFirestore` — v1'de sunucu ihtiyacı yok. Custom deste paylaşımı (v1.1)
  gelirse eklenir.
- `GoogleMobileAds` — reklam yok.
- `Lottie` — tüm animasyonlar SwiftUI (`Canvas`, `TimelineView`, `withAnimation`).
  Imposter'daki `TwinklingStarField` prosedürel yaklaşımı grain/ampul efektleri
  için birebir uyarlanacak.

---

## 5. Oyun faz makinesi

```swift
enum LivePhase: Equatable {
    case orientationPrompt
    case countdown(Int)        // 3, 2, 1
    case playing
    case paused
    case roundEnd
    case replay
    case teamHandoff(Int)      // sıradaki takım index'i
    case matchEnd
}
```

`GameFlowView` içinde tek `switch live.phase`. Associated value'lu case'lerde
`.id(...)` ile view kimliği zorlanır → geçiş animasyonları temiz kalır.
(`Imposter/Models/LiveGame.swift` içindeki `LivePhase` deseni ile aynı.)

Timer: her ekran kendi `Timer.publish` publisher'ını kurar, azaltma tek noktada
`LiveGame.tick()` içinde ve **faz korumalı** (`guard phase == .playing`). Bu
koruma olmadan duraklatma sırasında sayaç akmaya devam ediyor.

---

## 6. Performans hedefleri

| Metrik | Hedef |
|---|---|
| Soğuk açılıştan ana ekrana | < 1.5s (perde animasyonu bunun içinde) |
| Ana ekran scroll | 60 fps, deste görselleri lazy + downsampled |
| Oyun ekranı | 60 fps; grain katmanı 12 fps'te ayrı `TimelineView` |
| Motion güncelleme | 30 Hz |
| Bellek | < 180 MB (replay kaydı aktifken < 260 MB) |
| IPA boyutu | < 60 MB |

Deste görselleri ana ekranda tam çözünürlükte yüklenmez; kart boyutuna göre
downsample edilmiş türev kullanılır (`ImageRenderer` veya asset catalog'da
ikinci bir küçük varyant).

---

## 7. Gizlilik ve App Store hazırlığı

| Konu | Durum |
|---|---|
| `NSCameraUsageDescription` | Replay için, **v1'de gerekli** |
| `NSPhotoLibraryAddUsageDescription` | Replay kaydetme için, **v1'de gerekli** |
| `NSMotionUsageDescription` | CoreMotion için gerekli değil (device motion izin istemiyor) ama Privacy Manifest'te beyan edilecek |
| ATT / IDFA | **Yok** — reklam olmadığı için tracking izni istenmiyor. Bu, App Store'da güçlü bir gizlilik profili demek |
| Privacy Manifest (`PrivacyInfo.xcprivacy`) | Zorunlu: `NSPrivacyCollectedDataTypes` (analytics, purchase), `NSPrivacyAccessedAPITypes` (UserDefaults: `CA92.1`) |
| Nutrition label | "Uygulamaya Bağlı Veri: Satın Alma, Kullanım Verisi, Tanımlayıcılar" |
| Aile Paylaşımı | **Üç** abonelik ürününün hepsi için açık (haftalık, aylık, yıllık) |
| Yaş sınırı | **12+** — katalogda 18+ deste yok, yetişkin içeriği anahtarı yok. Cinsel içerik, alkol/madde teşviki ve küfür barındıran kart bulunmuyor. Bu, App Store'un aile ve eğitim listelerine girebilmek için bilinçli bir karar |

---

## 8. Geliştirme sırası (öneri)

Her adım kendi içinde çalışan bir uygulama bırakıyor; bu, ara kontrol için önemli.

| Aşama | İş | Süre tahmini |
|---|---|---|
| 1 | Proje iskeleti, `Theme` (renk+font+grain+ampul), `Components` | 3 gün |
| 2 | Navigasyon kabuğu, ana ekran + 10 deste ile ızgara, header, filtre chip'leri | 4 gün |
| 3 | `MotionService` + oyun ekranı + geri sayım + tur sonu (Klasik mod) — **oynanabilir ilk sürüm** | 5 gün |
| 4 | Mod seçimi, Hız Turu, Canlandır, Nasıl Oynanır slider'ı | 3 gün |
| 5 | Takım Savaşı (kurulum, geçiş, maç sonu) | 4 gün |
| 6 | Mix + kaydedilmiş karışımlar | 3 gün |
| 7 | Custom deste (SwiftData, editör, kapak seçici) | 4 gün |
| 8 | `LocalizationManager` + 25 dil + dil sheet'i + RTL geçişi | 4 gün |
| 9 | RevenueCat + 3 plan + 3 paywall varyantı + gating + günlük bedava deste | 5 gün |
| 10 | Onboarding + social proof + soft prompt'lar | 3 gün |
| 11 | Ayarlar ekranı (13 satır) | 2 gün |
| 12 | Ses paketi (12 parça) entegrasyonu, haptics geçişi | 2 gün |
| 13 | **Replay kaydı** (AVCapture, birleştirme, paylaşım, termal koruma) | 4 gün |
| 13b | **Film Arşivi** (kalıcı depolama, kota/FIFO, arşiv ekranı, oynatıcıda altyazı + ağır çekim + zaman çizelgesi işaretleri) | 3.5 gün |
| 14 | Analytics event'leri + Remote Config flag'leri | 2 gün |
| 15 | 92 deste görseli + içerik doldurma + doğrulama script'i | paralel, **~33 gün ayrı kaynak** (§ `09` §6) |
| 17 | **Kesinti ve sınır durumları** (yön katmanı, `scenePhase`, kelime havuzu, beraberlik, abonelik düşüşü, RC varsayılanları) | 11 gün |
| 16 | Cilalama, erişilebilirlik, App Store materyalleri | 5 gün |

Toplam geliştirme: **~56.5 gün** + sinematik katman 6 gün (§ `08` §6) + kesinti ve
sınır durumları 11 gün (§ `09` §12) = **~73.5 gün**.

**İçerik üretimi paralel yürür ama "bedava" değil:** ~33 gün, ayrı bir kaynak
(§ `09` §6). Adım 15'in süre hanesinde yalnızca "paralel iş" yazması bu kalemi
görünmez kılıyordu — geliştirme yarım gün hassasiyetinde bütçelenmişken projenin
en büyük kalemi ölçüsüzdü.

Replay kaydı 13. adımda, yani oyun döngüsü tamamen oturduktan sonra. Sebep: kamera
oturumu ile oyun ekranının aynı anda çalışması ancak oyun ekranı stabil olduğunda
güvenle test edilebilir. Ayarlardaki anahtar ve izin akışı 11. adımda hazırlanır,
13'te bağlanır.

13b (Film Arşivi) ayrı bir adım, çünkü kaydetme ile **arşivleme** farklı işler:
biri `AVCaptureSession`, diğeri dosya yaşam döngüsü, kota yönetimi ve liste
ekranı. 13b kesilirse 13 hâlâ çalışır (tur sonunda oynat + paylaş), sadece
sonradan izleme olmaz. Takvim sıkışırsa buradaki minimum sürüm 1.5 gün:
kalıcı depolama + düz liste + oynat/paylaş/sil. Altyazı, ağır çekim ve zaman
çizelgesi işaretleri v1.1'e kalabilir.

---

## 9. `Imposter`'dan doğrudan taşınacak dosyalar

Yeniden yazılmayacak, kopyalanıp tema/isim uyarlaması yapılacak:

| Kaynak | Uyarlama |
|---|---|
| `Theme/AppFonts.swift` | Font isimleri Oswald/Playfair/Rubik olacak, fallback zinciri aynı |
| `Services/Haptics.swift` | Aynen |
| `Services/AppSettingsStore.swift` | Anahtarlar yeni ayarlara göre |
| `Services/LocalizationManager.swift` | Aynen + plural desteği eklenecek |
| `Services/SubscriptionStore.swift` | Ürün ID'leri ve entitlement aynı mantık; rewarded ad kısmı çıkarılacak |
| `Components/SwipeBack.swift` | Aynen |
| `Components/Buttons.swift` | Görsel tamamen yeni, yapı aynı |
| `Models/WordBank.swift` | `CardBank` olarak, deste başına lazy yüklemeye çevrilecek |
| `Features/Root/RootView.swift` | Faz/route mantığı referans; tek `NavigationStack` yapısı zaten uyumlu |
| `Resources/Localization/*.json` | `common.*`, `settings.*`, `paywall.*` anahtarları büyük ölçüde geçerli — 25 dilde hazır çeviri kazanımı |

Son kalem önemli: 25 dilde ortak UI anahtarlarının çevirisi zaten mevcut. Bu,
lokalizasyon işinin belki %30'unu hazır getiriyor.
