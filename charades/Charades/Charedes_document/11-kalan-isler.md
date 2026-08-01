# 11 — Kalan İşler (P18 sonrası)

**Durum:** Kodlama paketleri **P0–P18 tamamlandı.** Uygulama derleniyor,
oynanıyor; erişilebilirlik, lokalizasyon altyapısı, ekran görüntüsü script'i ve
sinematik katman yerinde.

Bu dosya “sırada ne var?” sorusunun cevabı. Kod paketleri bitti; yayın ve içerik
yolu hâlâ açık. Kaynaklar: `00` §8, `06` §3.3–3.4, `09` §6 / §11, `10` §4,
oturum kararları (ASO ertelendi, ses sentetik).

---

## 0. Özet

| Katman | Durum |
|---|---|
| Kod (P0–P18) | Tamam |
| İçerik (92 deste kelime) | **Açık** — şu an 3 örnek deste |
| Yayın materyali (ASO, fiyat, Connect) | **Açık** |
| Prod anahtarlar (RC / Firebase) | **Açık** (yapılandırma) |
| Gerçek ses tasarımı | **Açık** (yerine sentetik `.caf`) |
| v1.1 / ertelenen ürün | Bilinçli dışarıda |

---

## 1. Yayını bloke edenler (öncelik yüksek)

Bunlar olmadan App Store’a “tam ürün” olarak çıkmak zayıf veya imkânsız.

### 1.1 Deste içeriği (~33 gün, ayrı kaynak — `09` §6, `10` §4)

Kod **3 örnek deste** ile çalışıyor (`party`, `movieClassics`, `cities`).
Katalog metadata’sı 92 deste için hazır; JSON’u olmayan deste CI’da kırılıyor.

| Kalem | Not |
|---|---|
| 61 `literal` deste × 25 dil | LLM + CI |
| 31 `adapt` deste — 6 öncelikli dil | İnsan/editör (~8 gün) |
| 31 `adapt` — kalan 19 dil | v1’de global set kabul edilebilir (`09` §6) |
| Deste adı / açıklama × 25 dil | Taşma kontrolü (`06` CI) |
| `fil`, `ms`, `be`, `nl`, `hr` native onayı | Tedarik planı yok — belirsiz |

Kapak görselleri dökümana göre **92/92 üretildi**; asıl açık iş kelime/kart
JSON’ları.

### 1.2 ASO metinleri (P18’de bilinçli ertelendi — `06` §3.3)

| Kalem | Durum |
|---|---|
| Alt başlık (subtitle) × store locale | Yazılmadı |
| Anahtar kelimeler | Yazılmadı |
| Açıklama / What’s New | Yazılmadı |
| Arama hacmi ile hipotez doğrulama | Bekliyor |

Dikkat (`09` §11.9): **25 uygulama dili ≠ 25 App Store metadata locale.**
`be`, `fil` vb. için ayrı store metadata yok; plan buna göre daraltılmalı.
`be`, `ca`, `fil`, `hr`, `id`, `ms`, `ro` için ASO hipotezi dökümanda hiç yok.

### 1.3 App Store ekran görüntüleri — tüm diller

Script hazır: `charades/Scripts/build_store_screenshots.py`.

| Üretilen | Eksik |
|---|---|
| `en` 6.9" + 6.5" (6 sahne) | Diğer ~22 dil |
| `tr` 6.9" örnek | 6.5" diğer diller |
| `ar` 6.9" örnek (RTL) | Connect’e yükleme / kırpma kontrolü |

Komut örneği:

```bash
python3 Scripts/build_store_screenshots.py --lang de
python3 Scripts/build_store_screenshots.py --size 6.5 --lang tr
```

Bağımlılık (Arapça başlık): `Pillow`, `arabic-reshaper`, `python-bidi`.

### 1.4 App Store Connect / hesap işleri (`00` §8)

| Kalem | Not |
|---|---|
| Haftalık / aylık / yıllık fiyat noktaları | Connect’te belirlenecek |
| Aile Paylaşımı (`Family Sharable`) | Üç plan |
| Yaş derecesi 12+ + içerik uyarıları | Alkol/madde referansı varsa Mild (`09` §11) |
| Gizlilik etiketleri | ATT yok; `PrivacyInfo.xcprivacy` kodda var |
| Destek URL / gizlilik politikası URL | Connect zorunlu alanlar |
| Uygulama ikonu 1024 | Üretildi (`teslim/`); Xcode asset kontrolü |

### 1.5 Prod yapılandırma

| Kalem | Not |
|---|---|
| RevenueCat API key (`RevenueCatAPIKey`) | Info.plist / xcconfig — yoksa mock offer |
| App Store ürün ID’leri ↔ RC entitlement | Plan kartları gerçek fiyat çekmeli |
| Firebase (`GoogleService-Info.plist`) | Prod proje / Analytics / Remote Config |
| Release imzalama, TestFlight | — |

---

## 2. Yayın öncesi kalite (kod hazır, insan/cihaz şart)

### 2.1 Lokalizasyon kontrol listesi (`06` §3.4)

Otomatik: `validate_localization.py` + `font_check` geçiyor (711 anahtar × 25 dil,
glif taraması temiz). Hâlâ **manuel** işaretlenecekler:

- [ ] 6 mod adı native onaylı, ≤18 karakter
- [ ] 92 deste adı ≤22 karakter (içerik gelince)
- [ ] `adapt` destelerinde öncelikli 6 dilde ≥%60 yerel içerik
- [ ] Cihazda Almanca/Fince paywall + onboarding taşma turu
- [ ] Plural (`ru`, `uk`, `pl`, `hr`, `cs` `.few`)
- [ ] Sayı/süre locale formatı
- [ ] App Store alt başlık + anahtar kelime girildi

### 2.2 Cihaz / erişilebilirlik dumanı

P18’de simülatör + kısmi kontroller yapıldı. Cihazda tekrar:

- [ ] Dynamic Type (AX boyutları) — oyun kelimesi / sayaç sabit kalıyor mu
- [ ] VoiceOver — MarqueeSwitch, ayarlar, arşiv, paywall
- [ ] Reduce Motion — klaket, perde, soft paywall
- [ ] Gerçek cihaz tilt + dokunmatik yedek
- [ ] Replay: kamera izni, termal, arka plan kesintisi
- [ ] Abonelik: satın alma, restore, lapse kartı (sandbox)

### 2.3 Ses (P13)

12 parçalık paket **sentetik `.caf`** ile duruyor; gerçek ses tasarımı
değiştirilecek. Aynı dosya adları / `SoundService` API’si korunmalı.

---

## 3. Dökümandaki açık kararlar (`00` §8, `09` §11)

Kod yazmadan önce netleştirilmesi gerekenler:

| # | Konu | Etki |
|---|---|---|
| 1 | `partyFlirty` / `bachelor` (+ ilgili) editoryal 12+ incelemesi | Rotasyondan muaf tutma (`09` §11.3) |
| 2 | `pocketCreatures` adı IP’ye aykırı — yeniden adlandırma | Katalog |
| 3 | “Diziler / Netflix” üretim talimatı → jenerik platform | `adapt` içerik |
| 4 | Marka-yoğun desteler (`brands`, `cars`, …) politika | İçerik / risk |
| 5 | Gerçek kişi hakları (`actors`, `celebImpressions`, …) | Politika satırı |
| 6 | `%80 TASARRUF` sabit → çalışma zamanı hesabı | Paywall |
| 7 | Aylık plan kartı kalacak mı | Paywall / RC |
| 8 | v1 dışı 32 deste güncelleme takvimi | İçerik yol haritası |
| 9 | Social proof ekranı ne zaman (ilk ~500 yorum sonrası) | v1.1 ürün |
| 10 | Yunanca serif: EB Garamond mi, Fira Condensed mi | Tipografi (kısmen çözülmüş olabilir) |
| 11 | 20 kayıt / 500 MB kota yeterli mi | `replay_quota_evict` ile izle |
| 12 | Projektör döngü sesi ayrı alt anahtar mı (`08` C7) | Ayarlar / ses |

---

## 4. Bilinçli olarak v1 dışı / v1.1

Bunlar “unutuldu” değil; dökümanda ertelenmiş:

| Kalem | Kaynak |
|---|---|
| Social proof / puan ekranı (gerçek yorumlarla) | `03` §1, `00` §8 |
| Custom deste paylaşımı (kısa kod) | `00` §8 |
| Sinematik **Kademe C** | `08` §3 |
| 31 `adapt` × kalan 19 dilin tam yerelleşmesi | `09` §6 |
| Push bildirim altyapısı | Yerel bildirim yeterli (`00`) |
| Reklam / ATT | Bilinçli yok |

---

## 5. Önerilen sıra (yayına giden yol)

```
1. Prod anahtarlar (RC + Firebase) + sandbox satın alma
2. ASO metinleri (öncelikli store locale’ler) + fiyatlar Connect’te
3. Ekran görüntüleri: öncelikli diller (en, tr, de, es, fr, ru, ar, …)
4. İçerik: en az “v1 oynanır set” (ücretsiz + birkaç premium + 1 adapt dil seti)
5. IP / 12+ editoryal kararlar (§3) — rotasyon ve katalog temizliği
6. Gerçek ses paketi (görsel/ASO’dan bağımsız, paralel olabilir)
7. TestFlight → cihaz QA (§2.2)
8. App Review gönderimi
```

İçerik (1.1) en uzun kalem; ASO + Connect (1.2–1.4) içerikle **paralel**
yürüyebilir.

---

## 6. Kod tarafında “tamam” sayılanlar (referans)

Tekrar yazmaya gerek yok; kontrol için:

- P0–P18 paketleri (`10-kodlama-plani.md`)
- 25 dil UI JSON + `LocalizationManager`
- Erişilebilirlik: Dynamic Type, 44pt, kontrast, VoiceOver, Reduce Motion (P18)
- Ekran görüntüsü script’i + örnek `en`/`tr`/`ar` setleri
- Film Arşivi tam sürüm (P15), sinematik A+B (P17)
- Analytics + Remote Config sarmalayıcıları (P16)
- Sentetik ses + haptik dili (P13) — API hazır, asset geçici

---

## 7. Bu dosyanın güncellenmesi

Bir kalem bittiğinde buradan silin veya `[x]` ile işaretleyin. Yeni ertelenen iş
çıkarsa §3 veya §4’e ekleyin; kod paketi tablosuna geri dönülmez — P18 son
kod paketiydi.
