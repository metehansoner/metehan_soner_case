# Kodlama — Faz durumu

| Faz | Durum | Not |
|-----|--------|-----|
| **0** Temizlik + Theme + L10n + Haptics + Fonts | ✅ | Build OK |
| **1** Cold start → Oyuncu ekle + Onboarding | ✅ | Build OK |
| **2** Ana menü + Ayarlar sheet | ✅ | Mode kartları, Settings, Language, HowTo |
| **3** Kategoriler + Oyun ayarları | ✅ | 16 kategori, süre 30sn–5dk, impostor, twist |
| **4** Klasik oyun döngüsü | ✅ | Reveal · timer · oy · sonuç |
| **5** Çizim modu | ✅ | Tuval · renkler · tur · pause · oy |
| **6** Paywall + Rate Us | ✅ | Onboarding sonrası paywall · kilitli kategori · Rate Us |
| **7** Mystery Twist + Kelime bankası | ✅ | 4 twist · 16 kategori × 12 kelime (en/tr) |

> **Ertelenen işler:** [`07_sonra_yapilacaklar.md`](./07_sonra_yapilacaklar.md) (StoreKit, kelime çevirileri, polish, App Store)

## Faz 0–1 özeti

- SwiftData şablon kaldırıldı
- Vivid Ocean `AppColors` + `OceanBackground`
- Fredoka / Nunito fontları
- 12 dil JSON (`Resources/Localization`)
- Haptics + `AppSettingsStore` (persist)
- `GameSession` (oyuncular session-only)
- Onboarding 3 sayfa → Add Players (3–15)
- Home sheet: mod seçimi (Klasik / Çizim)
