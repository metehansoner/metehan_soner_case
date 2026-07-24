# Imposter Party — Uygulama Ana Hatları

> Referans analiz: `ornek_uygulma_resimleri/` (Fakeit benzeri sosyal çıkarım / parti oyunu)
>
> **Kritik kısıtlar**
> - Renk paleti örnek uygulamadaki tonlara **benzemeyecek** (kırmızı / pembe / magenta / hot pink / lime yeşil / turuncu onboarding blokları kaçınılacak)
> - Örnekteki 3D karakter ve ikonlar **kopyalanmayacak**; benzer işlevde, özgün görseller üretilecek
> - Bu dosya: ekranlar, akış, mekanik. Renk paleti + görsel üretimi + kodlama sonraki adımlar

---

## 1. Ürün özeti

| Alan | Karar |
|------|--------|
| Tür | Offline parti / sosyal çıkarım oyunu (telefon elden ele) |
| Dil (v1) | **12 dil** · default **English** · telefon dili eşleşirse o dil (`localization/`) |
| Oyuncu sayısı | Sabit başlangıç **3** · en fazla **15** · isimler **persist edilmez** |
| Cold start | Uygulama açılışı → **Oyuncu ekle** (3 boş input) |
| Tur süresi | Min **30 sn** · Max **5 dk** |
| Tipografi / Haptics | `03_tipografi_ve_haptics.md` |
| Görseller | `04_gorsel_uretim_brief.md` · asset klasörleri `screens/assets/` |
| Platform hedefi | Mobil (iOS öncelikli UI referansı) |
| Uygulama adı | **Imposter Party** (App Store display name) |
| v1 modlar | **Klasik + Çizim** (ikisi birden) |
| Paywall | **Var** (v1’de) |
| Ateşli kategori | **Yok** |
| Mystery Twist | **Var** (v1 · varsayılan Kapalı, ayardan Açık) |
| Maskot / App ikon | **Şapkalı + göz maskeli tilki** (bkz. `screens/app_icon.png`) |
| Renk paleti | **Vivid Ocean** — `screens/palette_preview_home_vivid.png` · detay: `02_renk_paleti.md` |
| Çekirdek vaat | Bir kişi kelimeyi bilmez (impostor); diğerleri bilir. İpucu verilir, konuşulur, oy verilir. |

> ASO: isimde **Imposter** geçiyor. Subtitle (ör. “Kim Numara Yapıyor?”) store listing’de ayrıca yazılır.

### Oyun fikri (tek cümle)

Herkes aynı gizli kelimeyi görür — **impostor hariç**. Bilenler kelimeyi söylemeden tarif eder; impostor karışır veya kelimeyi tahmin ederek anında kazanabilir. Tur bitince oylama ile impostor ifşa edilir.

---

## 2. Örnek uygulamadan çıkarılan yapı (özet)

Örnek uygulama (**Fakeit**) şu katmanlara sahip:

1. **Onboarding** — 3 renkli tanıtım ekranı + ana menü üzerinde 4 adımlı eğitim modalı
2. **Paywall / abonelik** — deneme + yıllık + haftalık
3. **Ana menü** — 2 oyun modu kartı
4. **Kurulum** — oyuncu ekleme → kategori seçimi → oyun ayarları
5. **Rol dağıtımı** — telefonu ver → yukarı kaydır → kelime veya IMPOSTOR
6. **Tur** — geri sayım / çizim tuvali → duraklat → oy ver
7. **Oylama & sonuç**
8. **Ayarlar / dil / puanla / destek izni**

Bizim uygulama aynı **işlevsel iskeleti** koruyacak; görsel kimlik tamamen ayrı olacak.

---

## 3. Oyun modları

### 3.1 Klasik Impostor (birincil)

1. Oyuncular isim girer (min. 3)
2. Bir veya birden fazla kategori seçilir
3. Oyun ayarları yapılır
4. Her oyuncu sırayla telefonu alır, rolünü / kelimesini gizlice görür
5. Tartışma turu (süre sayacı)
6. Oylama
7. Sonuç + tekrar oyna

**Kazanma koşulları**

| Taraf | Nasıl kazanır |
|-------|----------------|
| Civiller | Doğru kişiye oy vererek impostoru bulur |
| Impostor | Yanlış oy alır / kaçmayı başarır **veya** süre dolmadan gizli kelimeyi tahmin eder (anında zafer) |

### 3.2 Çizim modu

- Kelime anlatımı yerine **tek çizgiyle ipucu çizme**
- Beyaz / açık tuval + renk paleti + geri al + sil
- Oyuncular sırayla çizer, telefonu devreder
- Aynı oylama / sonuç döngüsü
- Çıkış onayı: “Oyundan çık?”

---

## 4. Ekran haritası ve kullanıcı akışı

```
Splash / İlk açılış
    │
    ├─► Onboarding 1 → 2 → 3
    │         │
    │         └─► Paywall → Atla / Abone ol
    │
    └─► Ana Menü
            │
            ├─ Klasik Impostor ──► Oyuncu Ekle → Kategoriler → Oyun Ayarları
            │                              │
            │                              └─► Rol Dağıtımı döngüsü
            │                                       │
            │                                       └─► Tur (timer) → Oylama → Sonuç
            │
            └─ Çizim Modu ──► (aynı kurulum) → Çizim Turu → Oylama → Sonuç

Global (her yerden):
  • Ayarlar (bottom sheet)
  • Bilgi / Nasıl oynanır
  • Dil seçimi
  • Rate Us modalı
  • Destek / gizlilik izni (onboarding sonrası)
```

### İlk açılış (post-home) eğitim modalı (4 adım)

Ana menü üzerinde ilk kez gösterilir:

| Adım | Başlık | İçerik |
|------|--------|--------|
| 1 | Temaları seç | Ruh haline uygun bir veya birden fazla tema |
| 2 | Rolünü kontrol et | Herkes kelimeyi görür; impostor sadece rolünü görür |
| 3 | İpucu ver | Bilen için net, impostor için kafa karıştırıcı çağrışım |
| 4 | Oy verme zamanı | Doğru = kazandın / Yanlış = impostor kazanır + kelime tahmini uyarısı |

---

## 5. Ekran envanteri (detay)

### A. Onboarding

| # | Ekran | Amaç | UI iskeleti |
|---|--------|------|-------------|
| A1 | Anında eğlence | Parti / yolculuk / buz kırıcı vaadi | Üst: 3’lü karakter grubu · Orta: başlık + kısa metin · Alt: CTA (“Ben de varım!”) |
| A2 | Kim numara yapıyor? | Çekirdek kural | Üst: “biri farklı” sahnesi · Metin · CTA (“Anladım”) |
| A3 | Akıllıca konuş | İpucu mekaniği | Üst: sunucu / mascot + konuşma balonu · Metin · CTA (“Oynayalım!”) |

### B. Monetizasyon

| # | Ekran | Not |
|---|--------|-----|
| B1 | Paywall | **v1 zorunlu** · Ücretsiz deneme / yıllık / haftalık; “En popüler” rozeti; Koşullar · Gizlilik · Atla · Geri yükle |

> Fiyatlar ve paket isimleri ürün kararı; v1’de UI + Store bağlantı iskeleti hazır olur.

### C. Ana menü & global

| # | Ekran | İçerik |
|---|--------|--------|
| C1 | Ana menü | Logo + Ayarlar + Info · 2 büyük mod kartı (Klasik / Çizim) |
| C2 | Ayarlar sheet | Detay: **`05_ayarlar_ekrani.md`** · Dil · Bize ulaş · Gizlilik · Koşullar · Titreşim · User ID · Kapat |
| C3 | Dil sheet | 12 dil listesi + checkmark + Geri |
| C4 | Rate Us modal | Karakter + 5 yıldız CTA |
| C5 | Destek deneyimi | Apple destek verisi izni · Kabul et / Reddet |

### D. Kurulum

| # | Ekran | Kurallar |
|---|--------|----------|
| D1 | Oyuncu ekle | **Her app açılışında buraya gelinir** · her zaman **3 sabit boş** input · `+ Oyuncu ekle` ile en fazla **15** · isimler session-only (kapatınca silinir) · Devam için 3 isim dolu olmalı |
| D2 | Kategoriler | Scroll kart listesi · kilitli / açık · çoklu seçim · alt bar: **OYNA \| N kategori** |
| D3 | Oyun ayarları | Aşağıdaki ayarlar · alt bar: **OYNA \| N impostor** |

**Cold start davranışı**

1. Onboarding / paywall sadece ilk kurulumda
2. Sonraki her açılış → **Oyuncu ekle** (3 boş slot)
3. Son seçilen oyun modu (Klasik / Çizim) hatırlanır; header’dan ana menüye dönülebilir
4. Oyuncu isimleri ve aktif oyun state’i **persist edilmez** — her seferinde yeniden set

**Oyun ayarları alanları**

| Ayar | Kontrol | Kural |
|------|---------|--------|
| Mystery Twist | Açık / Kapalı | v1’de var · varsayılan Kapalı |
| Impostor sayısı | − / + stepper | Oyuncu sayısına göre önerilen; min 1 |
| Tur süresi | − / + stepper | **Min 0:30 · Max 5:00** · adım 30 sn · varsayılan 2:00 |
| Impostorlar için ipuçları | Açık / Kapalı | Impostora kelime hakkında ipucu |

### E. Rol dağıtımı (pass-the-phone)

| # | Ekran | Davranış |
|---|--------|----------|
| E1 | Telefonu X’e ver | Oyuncu adı + karakter + Devam |
| E2 | Ön-reveal | Oyuncu adı / kategori ipucu + “Gizli kelimeyi görmek için yukarı kaydır” |
| E3a | Reveal — sivil | Grup ikonu + **gizli kelime** |
| E3b | Reveal — impostor | Impostor ikonu + **İMPOSTOR** + opsiyonel “İpucu: …” |
| E4 | Başlamaya hazırız | Tüm roller dağıtıldıktan sonra · “Oyunu başlat” |

Her oyuncuya sırayla atanır: **15 hazır karakter + renkli solid BG** (bkz. `04_gorsel_uretim_brief.md`). Referans stil: `ornek_uygulma_resimleri/IMG_4926 2.PNG` (clay 3D + renkli BG + swipe-up) — görseller özgün, renkler Vivid Ocean ailesi.

### F. Tur — Klasik

| # | Ekran | İçerik |
|---|--------|--------|
| F1 | Tartışma | Büyük timer · “Sormaya başla!” · Duraklat |
| F2 | Nasıl oynanır modal | 3 kural maddesi · Anladım |
| F3 | Duraklatılmış | Devam et · Oy ver |

### G. Tur — Çizim

| # | Ekran | İçerik |
|---|--------|--------|
| G1 | Tur başlangıç overlay | “X başlıyor” · tek çizgiyle çiz talimatı |
| G2 | Aktif çizim | Tuval · 8 renk · Undo · Sil · Timer · Duraklat · Oy ver |
| G3 | Duraklatıldı | “Dokun / Devam et” |
| G4 | Oyundan çık? | İptal / Çık |

### H. Oylama & sonuç

| # | Ekran | İçerik |
|---|--------|--------|
| H1 | Impostor kim? | Oyuncu kartları grid · seçim rozeti |
| H2 | Oyları gönder | Alt bar CTA |
| H3 | Sonuçlar | Kazanan taraf metni · impostor kartı · gizli kelime · Tekrar oyna |
| H4 | Gerçeğin anı (opsiyonel) | Kısa dramatik geçiş / tipografi ekranı |

**Sonuç metin varyantları (örnek)**

- Impostor kazandı — “İmpostor fark edilmeden kaçtı”
- Civiller kazandı — (karşı metin; kodda eklenecek)
- Impostor kelimeyi bildi — anında zafer varyantı

---

## 6. Kategori listesi (v1 içerik)

Örnek uygulamadan derlenen kategoriler. Kart yapısı: **başlık · kısa açıklama · kilit durumu · illüstrasyon**.

| Kategori | Açıklama (özet) | V1 kilit |
|----------|-----------------|----------|
| Parti zamanı | Rahat eğlence, kahkaha, kaos | Açık |
| Futbol | Goller, efsaneler, fan rolü | Açık |
| Yemek | Lezzetli konular; yanlış söyleme | Kilitli |
| Ünlüler | Film, müzik, ünlü isimler | Kilitli |
| Hobiler | Tutkular, gizli zevkler | Kilitli |
| Aile | Aile seni tanısa da yakalayabilir | Kilitli |
| Eğitim | Sınav, ders, okul hayatı | Kilitli |
| Doğa | Ağaçlar, okyanus, vahşi yaşam | Kilitli |
| Karakterler | Kahramanlar, kötüler, efsaneler | Kilitli |
| Meslekler | Cerrah’tan yayıncıya | Kilitli |
| Hollywood | Filmler, oyuncular, ikonik anlar | Kilitli |
| Markalar | Ünlü markalar / günlük eşyalar | Kilitli |
| Yerler | Ülkeler, simgeler, şehirler | Kilitli |
| Hayvanlar | Evcil + vahşi | Kilitli |
| Sporlar | Hayran ol veya numara yap | Kilitli |
| Yılbaşı | Kış / kutlama | Kilitli |

> **Ateşli** kategori kasıtlı olarak **dahil edilmedi** (yaş / içerik riski).
>
> Kilitli kategoriler abonelik / satın alma ile açılır (paywall ile bağlı).

---

## 7. Temel oyun kuralları (ürün mantığı)

1. **Oyuncu:** başlangıçta 3 sabit slot · max 15 · her açılışta yeniden isim girilir  
2. **Impostor sayısı:** oyuncu sayısına göre önerilen + manuel ayar  
3. **Kelime havuzu:** seçili kategorilerden rastgele  
4. **Rol gizliliği:** swipe-up reveal; telefon elden ele  
5. **İpucu kuralları:** kelimeyi söylemeden tarif / çiz  
6. **Timer:** **30 sn – 5 dk** · dolunca veya “Oy ver” ile oylama  
7. **Oylama:** seçilen oyuncu impostor mu kontrol  
8. **Opsiyonel:** Mystery Twist, impostor ipucu, kelime tahmini anında zafer  
9. **Dil:** sistem dili desteklenen 12 dildeyse o; değilse **English**  
10. **Titreşim:** buton / geçiş haptics — `03_tipografi_ve_haptics.md`  

---

## 8. Tasarım yönü

### Onaylı palet

→ **`02_renk_paleti.md` (Vivid Ocean)** · referans: `screens/palette_preview_home_vivid.png`

### Tipografi & haptics

→ **`03_tipografi_ve_haptics.md`**

### Görseller

→ **`04_gorsel_uretim_brief.md`**  
Asset’ler: `screens/assets/` (mod kartları, kategoriler, 15 oyuncu karakteri)

### Örnekten alınacak UX kalıpları (evet)

- Büyük yuvarlatılmış kartlar
- Sticky alt aksiyon barı (`OYNA | özet`)
- Pass-the-phone + swipe-up reveal
- Bottom sheet ayarlar / dil
- Mod kartları (ana menü)
- Clay / 3D oyuncak illüstrasyon (tilki maskot mantığı)

### Örnekten bilinçli olarak uzaklaşılacaklar (hayır)

| Örnek | Bizim yaklaşım |
|-------|----------------|
| Kırmızı–pembe–magenta gradyanlar | Vivid Ocean (kobalt / cyan / sarı) |
| Lime / turuncu Fakeit onboarding | Aynı Vivid Ocean token’ları |
| Maskeli hırsız mascot | Şapkalı maskeli tilki |
| Fakeit kategori objeleri birebir | Aynı tema, farklı objeler |
| “Fakeit” tipografi | Fredoka + Nunito |

---

## 9. Teknik notlar (ileriye dönük)

| Konu | Not |
|------|-----|
| Veri | Oyuncular session state; roller; kategoriler; ayarlar |
| Persist | Dil tercihi (manuel override), titreşim aç/kapa, abonelik, onboarding görüldü, son oyun modu |
| Persist etme | Oyuncu isimleri, aktif tur, oylar |
| Kelime bankası | Kategori → kelime listesi (JSON) |
| Lokalizasyon | `localization/{lang}.json` · 12 dil · fallback `en` |
| Monetizasyon | StoreKit / Play Billing |
| Haptics | Light / medium / success — ayardan kapatılabilir |

---

## 10. Doküman sırası

| Dosya | Durum | İçerik |
|-------|--------|--------|
| `01_uygulama_ana_hatlari.md` | Tamam | Ekranlar, akış, mekanik |
| `02_renk_paleti.md` | Onaylı | Vivid Ocean |
| `03_tipografi_ve_haptics.md` | Tamam | Font + titreşim |
| `04_gorsel_uretim_brief.md` | Tamam | Mod / kategori / oyuncu görselleri |
| `05_ayarlar_ekrani.md` | Tamam | Ayarlar + Dil sheet |
| `localization/` | **Tamam (12/12)** | en default · sistem dili eşleşmesi |
| Kodlama | Sonra | UI + oyun motoru |

---

## 11. Sabitlenen kararlar

| Konu | Karar |
|------|--------|
| İsim | **Imposter Party** |
| v1 modlar | Klasik + Çizim |
| Paywall | Var |
| Ateşli | Yok |
| Mystery Twist | Var (varsayılan Kapalı) |
| Maskot | Şapkalı, göz maskeli tilki → app ikon |
| Renk paleti | Vivid Ocean (onaylı) |
| Oyuncu | 3–15 · her açılışta yeniden |
| Tur süresi | 30 sn – 5 dk |
| Dil | 12 dil · default EN · sistem dili eşleşmesi |
| Font | Fredoka (display) + Nunito (UI) |
| Haptics | Açık (varsayılan) · ayardan kapatılır |

---

*Güncelleme: 2026-07-25 · oyuncu / dil / görsel / haptics*
