# Imposter Party — Tipografi & Haptics

---

## 1. Tipografi

| Rol | Font | Ağırlıklar | Kullanım |
|-----|------|------------|----------|
| **Display / Logo** | [Fredoka](https://fonts.google.com/specimen/Fredoka) | SemiBold–Bold | Imposter Party logo, büyük ekran başlıkları, timer |
| **UI / Gövde** | [Nunito](https://fonts.google.com/specimen/Nunito) | Regular, SemiBold, Bold | Butonlar, kart başlıkları, açıklamalar, form |

### Ölçek (iOS pt — yaklaşık)

| Token | Size | Font | Örnek |
|-------|------|------|--------|
| `type.display` | 34–40 | Fredoka Bold | IMPOSTER PARTY, timer `01:58` |
| `type.title` | 24–28 | Fredoka SemiBold / Nunito Bold | Ekran başlığı (Kategoriler) |
| `type.cardTitle` | 20–22 | Nunito Bold | Klasik Imposter, kategori adı |
| `type.body` | 15–17 | Nunito Regular | Açıklama metinleri |
| `type.button` | 17–18 | Nunito Bold | OYNA, Devam |
| `type.caption` | 12–13 | Nunito Regular | “En az 3 oyuncu”, kullanıcı ID |

### Kurallar

- Logo: beyaz + koyu navy outline/gölge (Vivid Ocean)
- Satır aralığı rahat; uzun lokalizasyonlar için `body` flex shrink
- ASLA Inter / Roboto / sistem default’a düşme (fallback: Nunito → SF Rounded benzeri)

### iOS / Android notu

- iOS: font dosyalarını bundle’a ekle (`Fredoka-*.ttf`, `Nunito-*.ttf`)
- Android: `res/font` + Compose/XML `fontFamily`
- React Native: `expo-font` / `useFonts`

---

## 2. Haptics (titreşim)

Varsayılan: **Açık** · Ayarlar → Titreşim ile kapatılır.

| Olay | Yoğunluk (iOS) | Android eşdeğer | Not |
|------|----------------|-----------------|-----|
| Buton tap (primary/secondary) | `UIImpactFeedbackGenerator` **Light** | `EFFECT_CLICK` | Her CTA |
| Segment / stepper (+/−) | **Light** | `EFFECT_TICK` | |
| Kart seçimi (kategori, oy) | **Medium** | `EFFECT_CLICK` | |
| Swipe-up reveal (kelime / impostor) | **Medium** | `EFFECT_HEAVY_CLICK` | Gizem anı |
| Ekran geçişi (push) | **Soft / Light** | kısa tick | Nav transition |
| Oyunu başlat / oyları gönder | **Medium** | `EFFECT_DOUBLE_CLICK` | |
| Kazanç (civiller) | **Success** notification | `CONFIRM` | |
| Impostor kazandı / yanlış oy | **Warning** veya **Error** | `REJECT` | |
| Timer son 10 sn (her sn) | **Light** | tick | Opsiyonel |
| Timer bitti | **Heavy** | heavy click | |

### Uygulama kuralları

1. Titreşim kapalıysa tüm generator’lar no-op
2. Sistem “Reduce Motion” ile çakışmaz; haptics ayrı tercih
3. Ardışık spam yok: 100 ms debounce aynı kontrolde
4. Modal aç/kapa: Light

---

*Imposter Party · 2026-07-25*
