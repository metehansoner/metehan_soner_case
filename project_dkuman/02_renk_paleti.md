# Imposter Party — Renk Paleti (Vivid Ocean)

> **Durum:** Onaylı  
> **Referans ekran:** `screens/palette_preview_home_vivid.png`  
> **Maskot / ikon:** `screens/app_icon.png`  
> **Örnek Fakeit’ten uzak:** kırmızı / pembe / magenta / lime / turuncu arka plan yok

---

## 1. Kimlik

| | |
|--|--|
| İsim | **Vivid Ocean** |
| His | Canlı parti · gizem · kobalt–turkuaz enerji |
| Maskot | Şapkalı / maskeli turuncu tilki (app ikon + Klasik kart) |

---

## 2. Token’lar

### Çekirdek

| Token | Hex | Kullanım |
|-------|-----|----------|
| `bg.primary` | `#0047E8` | Ana arka plan (canlı elektrik mavisi) |
| `bg.primaryMid` | `#1A6BFF` | Arka plan gradyan orta |
| `bg.primaryTop` | `#3D8BFF` | Arka plan üst (daha açık) |
| `bg.glow` | `#66B3FF` | Merkez spotlight |
| `bg.glowCyan` | `#00E5FF` | Üst cyan wash |
| `bg.grid` | `#A8D4FF` @ ~22% | İnce grid çizgileri |
| `surface.card` | `#001A4D` | Klasik mod kartı, sheet’ler (koyu kontrast) |
| `surface.cardElevated` | `#0A2F7A` | Yükseltilmiş yüzey |
| `surface.canvas` | `#F4F7FB` | Çizim tuvali |
| `accent.cyan` | `#00F0FF` | Neon glow border, aktif vurgu |
| `accent.cyanDeep` | `#00C8E8` | Çizim kartı gradyan başlangıcı |
| `accent.blue` | `#3D7BFF` | Çizim kartı gradyan bitiş |
| `accent.yellow` | `#FFEF00` | Cırtlak sarı · yıldız / spark |
| `text.primary` | `#FFFFFF` | Başlık |
| `text.secondary` | `#E8F2FF` | Alt metin |
| `text.onLight` | `#001A4D` | Açık buton üzeri |

### Durum

| Token | Hex | Kullanım |
|-------|-----|----------|
| `state.success` | `#3DDC97` | Doğru oy / kazandın |
| `state.danger` | `#FF5A6A` | Yanlış / çık / uyarı (kırmızı ama **sadece durum**; arka plan değil) |
| `state.warning` | `#FFE566` | Uyarı ikonu (sarı accent ile aynı aile) |
| `state.locked` | `#6B7FA6` | Kilitli kategori |
| `overlay.scrim` | `#050B18` @ 55% | Modal arkası |

### Butonlar

| Token | Değer | Kullanım |
|-------|--------|----------|
| `btn.primary.bg` | `#FFFFFF` | Ana CTA (OYNA, Devam) |
| `btn.primary.text` | `#0B1F4A` | |
| `btn.secondary.bg` | `#122858` | İkincil |
| `btn.secondary.border` | `#00E5FF` | Glow kenar |
| `btn.danger.bg` | `#FF5A6A` | Çık / sil onay |
| `btn.disabled.bg` | `#2A3A5C` | Pasif |
| `btn.disabled.text` | `#6B7FA6` | |

---

## 3. Gradyanlar

| Ad | CSS-benzeri | Nerede |
|----|-------------|--------|
| `grad.screen` | `linear(180deg, #3D8BFF → #1A6BFF → #0047E8)` + merkez `#66B3FF` + üst cyan wash | Ana ekranlar |
| `grad.drawCard` | `linear(135deg, #00C8E8 → #3D7BFF)` | Çizim modu kartı |
| `grad.ctaGlow` | cyan outer glow `#00F0FF` 40–55% | Seçili kart / neon kenar |

---

## 4. Tipografi & şekil (renk bağlamı)

| | |
|--|--|
| Logo | Kalın yuvarlak sans, beyaz + koyu navy gölge/outline |
| Gövde | Yuvarlak sans, `text.primary` / `text.secondary` |
| Köşe | Büyük radius (~24–32pt kart, pill buton) |
| Glow | Cyan dış glow — özellikle seçili / portal halkası |

---

## 5. Kaçınılacaklar (Fakeit ayrımı)

| Yapma | Neden |
|-------|--------|
| Kırmızı–pembe–magenta ekran BG | Örnek Fakeit kimliği |
| Lime / turuncu onboarding blokları | Örnek Fakeit onboarding |
| Mor / indigo “AI default” tema | Ayrı marka isteniyor |
| Durum kırmızısını arka plan yapmak | Sadece error / çıkış için |

---

## 6. Preview notu

`palette_preview_home_vivid.png` içindeki **alt tab bar** (Odalar / Liderlik / Görevler) renk referansı içindi.  
**v1 ürün kapsamı** hâlâ offline parti akışı (ana menü → kurulum → oyun); online oda / liderlik / görev sistemi v1’de yok. İleride istenirse ayrı karar.

---

## 7. Sonraki adım

1. Onboarding / kategori / paywall ekranlarını aynı token’larla üret  
2. `03_gorsel_uretim_brief.md` — tilki maskot + kategori ikonları  
3. Kodda theme tokens (`colors.ts` / benzeri)

---

*Onay: kullanıcı · vivid tonlar · 2026-07-24*
