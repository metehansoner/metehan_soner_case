# CHARADES — Proje Dökümanı (Retro / Sinematik)

Bu klasör, iOS uygulaması kodlanmaya başlanmadan önce tüm ürün, tasarım ve teknik
kararların netleştirildiği çalışma dökümanıdır. Amaç: kodlamaya geçtiğimizde
"bunu nasıl yapacağız?" sorusunu hiç sormamak.

> Durum: **v1.0 — Ana kararlar onaylandı.** Tasarım yönü, monetizasyon, v1 kapsamı
> ve gating netleşti (§6). Kodlamaya başlanabilir; kalan maddeler uygulama
> sırasında çözülecek detaylar.

---

## Döküman haritası

| Dosya | İçerik |
|---|---|
| `00-OZET.md` | Bu dosya: ürün özeti, karar tablosu, açık sorular |
| `01-tasarim-sistemi.md` | Renk paleti, fontlar, doku/efektler, buton ve kart anatomisi |
| `02-ekran-akisi.md` | Tüm ekranlar, navigasyon kabuğu, akış diyagramı |
| `03-onboarding-paywall.md` | 5 adım onboarding, paywall varyantları, gating stratejisi |
| `04-oyun-modlari.md` | Oyun modları, tilt mekaniği, tur akışı, skor sistemi |
| `05-desteler-ve-kategoriler.md` | Çeşitlilik ilkesi, 124 destelik katalog, IP politikası, Mix, Custom Deck, veri şeması |
| `06-ayarlar-ve-lokalizasyon.md` | Ayarlar menüsü, 25 dil, çeviri altyapısı, kültürel yerelleştirme tabloları, ASO |
| `07-teknik-mimari.md` | Klasör yapısı, bağımlılıklar, state yönetimi, analytics |
| `08-sinematik-detaylar.md` | Sinema dili geçişleri, animasyon bütçesi, kademe A/B/C |
| `09-kesinti-ve-sinir-durumlari.md` | **Denetim sonucu.** Yön katmanı, kesinti politikası, kelime havuzu tükenmesi, beraberlik, abonelik düşüşü, içerik bütçesi, karar bekleyen riskler |
| `ornek-ekranlar.html` | iPhone 17 Pro'da ana ekran, ayarlar, oyun ekranı (tarayıcıda aç) |
| `sinematik-ozellikler.html` | Sinematik geçişlerin canlı animasyon demosu (tarayıcıda aç) |
| `film-arsivi.html` | Film Arşivi ve Replay Oynatıcı mockup'ı (tarayıcıda aç) |

---

## 1. Ürün tek cümlede

Telefonu alnına koyup arkadaşlarının canlandırdığı kelimeleri tahmin ettiğin,
92 temalı deste ve 25 dil desteği olan, **eski sinema salonu estetiğinde** bir
parti oyunu.

## 2. Neden retro/sinematik?

Kategorideki tüm rakipler (Charades!, Heads Up!, Imposter) **parlak mavi + yuvarlak
balon** dilini kullanıyor. Ekran görüntülerinde gördüğümüz referans uygulama da
tam olarak bu. Retro sinema yönü bize üç somut avantaj veriyor:

1. **App Store'da anında ayırt edilebilirlik.** Screenshot'lar rakiplerin arasında
   farklı görünür, bu doğrudan tıklama oranı demek.
2. **Tema ile mekanik örtüşüyor.** "Sessiz sinema" oyunu zaten sinema kavramının
   içinden geliyor: perde, afiş, film şeridi, marquee ışıkları, "SAHNE 1 / ÇEKİM 3".
   Zorlama bir tema değil, oyunun kendi dili.
3. **Görsel üretimi kolay ve tutarlı.** 92 destenin kart görselini AI ile üretirken
   "retro film afişi, sınırlı palet, grain" tek bir prompt iskeleti veriyor; her
   kart aynı aileden görünüyor. Referans uygulamada kartlar birbirinden kopuk
   (fotoğraf + illüstrasyon + logo karışık) — bizde olmayacak.

**Tema adı: "GRAND MARQUEE"** — 1950'ler sinema salonu: bordo kadife perde,
amber ampul sırası, krem afiş kağıdı, film grain'i, pirinç detaylar.

## 3. Referans uygulamadan aldığımız / almadığımız

| Aldığımız | Neden |
|---|---|
| Onboarding'in ana ekran üzerinde **bottom sheet** olarak açılması | Kullanıcı arkada içeriği (desteleri) görür, "burada ne var" merakı oluşur |
| Onboarding sonunda **social proof ekranı** (puan + yorumlar) | Paywall'dan hemen önce güven inşa eder, dönüşümü ölçülebilir şekilde artırır |
| Deste filtre chip'leri (Tümü / Popüler / Parti …) | 92 deste chip'siz yönetilemez |
| Tilt mekaniği (öne eğ = doğru, arkaya eğ = pas) | Kategorinin standardı, kullanıcı bunu bekliyor |
| Ayarlarda **UserID kopyalama** | Destek taleplerini eşleştirmek için |
| Haftalık plan + 3 gün ücretsiz deneme | Bu kategoride en yüksek dönüşümü veren yapı |
| Üç planlı yapı (haftalık / aylık / yıllık) | Farklı ödeme alışkanlıklarını karşılıyor |
| **1 ücretsiz deste** ile agresif gating | Kanıtlanmış model; 3 günlük deneme kapıyı zaten açıyor |
| **Replay kaydı** (ön kameradan tur videosu) | Viral paylaşım motoru; App Store'da güçlü bir satır |

| Almadığımız | Neden |
|---|---|
| Parlak mavi tema | Ayırt edilebilirlik (§2) |
| Karışık kart görsel dili | Tutarsız görünüyor, marka hissi vermiyor |
| Görsele gömülü deste başlıkları | 25 dilde 92 görseli yeniden üretmek imkânsız; başlıklar kodda basılır |
| Sadece dikey (portrait) oyun ekranı | Alna konan telefon **yatay** olmalı, oyun ekranı landscape kilitli |
| Reklam (rewarded/interstitial) | Masada 6 kişi varken araya giren reklam deneyimi öldürüyor |

## 4. Görsel taslaklar

İlk yön denemeleri (nihai tasarım değil, tema tartışması için):

- Ana ekran: `/Users/metehansoner/.cursor/projects/Users-metehansoner-desk-Works-Charedes-document/assets/mockup-ana-ekran.png`
- Oyun ekranı (landscape + doğru cevap geri bildirimi): `/Users/metehansoner/.cursor/projects/Users-metehansoner-desk-Works-Charedes-document/assets/mockup-oyun-ekrani.png`

Taslaklar üzerine notlar:
- Ana ekran taslağındaki grain ve kadife dokusu, § `01`'de tanımlanan "tam
  nostalji" yönüne yakın. Küçük ekranda okunabilirlik için son üründe grain
  yoğunluğu düşürülecek (§ Açık Kararlar #4).
- Deste kartlarındaki başlıklar taslakta görsele gömülü görünüyor; gerçek
  uygulamada başlık **ayrı bir kağıt şeride lokalize metinle** basılacak, aksi
  hâlde 25 dil imkânsız olur.
- Kilitli kart (Classics) sepia + pirinç kilit yaklaşımı taslakta iyi çalışıyor,
  aynen korunuyor.

## 5. Karar tablosu (netleşmiş olanlar)

| Konu | Karar |
|---|---|
| Platform | iOS 17+, iPhone, SwiftUI |
| Tema | Grand Marquee (retro sinema), **modern retro** yorumu, dark-only |
| Navigasyon | **Tab bar yok.** Tek kök ekran (deste ızgarası); ayarlar sağ üst dişliden sheet olarak açılır, VIP bileti sol üstte |
| Oyun ekranı yönü | Landscape (zorunlu), diğer tüm ekranlar portrait |
| Ana mekanik | CoreMotion tilt: öne eğ = DOĞRU, arkaya eğ = PAS |
| Oyun modları | 5 mod: Klasik, Takım Savaşı, Canlandır, Hız Turu, Mix — **hepsi v1'de** |
| Deste sayısı | **124 deste tanımlı, 92'si v1'de** / ~12.000 kart. 13 bölüm |
| Deste çeşitliliği | 6 eksende dengelenmiş (kitle, oynanabilirlik, bilgi, dönem, kültür, sezon) + `playability` alanı (`mime`/`describe`/`both`) |
| IP politikası | Deste adlarında ve kapaklarda **marka/telifli karakter yok** — jenerik adlandırma |
| Deste kapakları | **92/92 üretildi.** Şeffaf amblem (1024×1024 RGBA), görselde yazı yok → 25 dilde tek görsel. Bkz. `kapaklar.html` |
| Ekran görselleri | Onboarding illüstrasyonları **2/2 üretildi**; kalan tüm ikonlar SF Symbols ya da kodla çiziliyor. Bkz. `01` §6 |
| App ikonu | **Seçildi ve üretildi** — alında film şeridi kart, altında gözler. `ekran-gorselleri/app-ikonu/ikon-1024.png` |
| Ücretsiz erişim | **1 deste** (Parti Başlangıcı) + günlük rotasyonlu 1 bedava deste |
| Monetizasyon | Sadece abonelik (RevenueCat), reklam **yok** |
| Abonelik planları | **Haftalık (3 gün deneme) · Aylık · Yıllık** |
| Replay kaydı | **v1'de var** (ön kameradan tur videosu) |
| Ses | 12 parçalık retro ses paketi, v1'de |
| Sinematik katman | Akademi geri sayımı, klaket, perde açılışı, film karesi geçişi, kavis işareti, jenerik akışı, perde arası. **Tur başına atlanamaz animasyon ≤ 2.5 s.** § `08` |
| Dil | 25 dil, uygulama içi dil seçimi, restart gerektirmez |
| Tipografi | **Oswald** (display) · **Playfair Display** (afiş) · **Rubik** (UI). `ar` → Rubik Bold, `el` → **Fira Sans Condensed / EB Garamond / Fira Sans** (üçünde de Yunan glifi yok). § `01` §2 |
| Yerelleştirme yaklaşımı | **Çeviri değil transcreation:** mod ve deste isimleri her kültürün kendi adıyla (`actOut` → tr "Sessiz Sinema", ru "Крокодил", pl "Kalambury", nl "Hints") |
| Onboarding | 5 adım bottom sheet + ardından paywall |
| Ayarlar | 4 grup / 13 satır |
| Replay arşivi | **Film Arşivi** ekranı — kalıcı depolama, 20 kayıt / 500 MB kotası, altyazılı ve ağır çekimli oynatıcı. § `04` §4.2–4.4 |
| Custom deste | Ücretsiz 1 taslak (oynanamaz), Premium 3 aktif deste |

## 6. Onaylanan kararlar

| Konu | Karar | Etkisi |
|---|---|---|
| Retro yön | **Modern retro** | Palet ve doku retro, tipografi temiz. Grain %5, scanline varsayılan kapalı. Detay § `01` |
| Abonelik | **Haftalık (3 gün deneme) + Aylık + Yıllık** | Paywall'da 3 bilet kuponu, haftalık varsayılan seçili. Detay § `03` |
| v1 kapsamı | **Tam kapsam:** Takım Savaşı, Mix, Custom deste, Replay kaydı + Film Arşivi, Canlandır modu | Geliştirme ~56.5 + sinematik 6 + sınır durumları 11 = **~73.5 gün**. İçerik üretimi ayrı ~33 gün (§ `09` §6). Detay § `07` §8, § `08` §6, § `09` §12 |
| Gating | **1 ücretsiz deste** | Agresif model; risk azaltma için günlük rotasyonlu bedava deste eklendi. Detay § `03` §3 |
| Ses | **12 parçalık retro ses paketi** | v1'de. Liste § `04` §5 |

### Gating kararına eklenen risk azaltıcı

Tek ücretsiz deste, kullanıcının oyunu tadıp satın almasını zorlaştırıyor. Kararı
korumak ama riski azaltmak için iki mekanizma ekledim (§ `03` §3'te detaylı):

1. **"BUGÜNÜN BEDAVA DESTESİ"** — her gün premium destelerden biri 24 saat açılır,
   ana ekranın en üstünde marquee şeridinde duyurulur. Kullanıcı içeriğin
   kalitesini görür, üstelik her gün uygulamayı açmak için sebebi olur (retention).
2. **Kilitli destelerde örnek kelime önizlemesi** — deste detayında 6 örnek kelime
   her zaman görünür. "Ne alıyorum" sorusunu cevaplıyor.

Bu ikisi olmadan tek deste ile dönüşüm oranı düşük kalma riski taşıyor.
Onaylamazsan çıkarırım, ama en azından #2'yi tutmanı öneririm.

## 7. Denetim (31 Temmuz)

Döküman uçtan uca üç açıdan denetlendi: sayısal tutarlılık, akış mantığı,
monetizasyon/içerik. **Düzeltilen 24 hata** ve **§ `09` olarak eklenen eksik
bölüm** o denetimin sonucu. En ciddi üç bulgu:

1. **Tur sonu soft paywall'ı hiç çalışmıyordu** — koşulu `!paywallSeen` idi ama
   onboarding paywall'ı herkese gösterildiği için bu bayrak her zaman `true`.
   Kodlanıp bir kez bile görünmeyecek bir ekran. Ürünün en yüksek dönüşüm anı.
2. **`MARKA & TEKNOLOJİ` bölümünün filtre chip'i yoktu** — 8 destesi (6'sı v1'de)
   filtreyle hiç erişilemiyordu. 13 bölüm, 12 chip.
3. **Yön (orientation) katmanı tanımsızdı** — tur sonu ekranı portrait
   tasarlanmıştı ama süre bitince telefon yatay hâlde otomatik açılıyordu.

Kalan karar bekleyen riskler § `09` §11'de.

## 8. Kalan detaylar (uygulama sırasında çözülecek)

- Yıllık/aylık/haftalık fiyat noktaları (App Store Connect'te belirlenecek)
- Katalogdaki v1 dışı 32 destenin güncelleme takvimi
- `partyFlirty` ve `bachelor` destelerinin editoryal gözden geçirmesi (12+ sınırında kalmalı)
- Social proof ekranının ne zaman açılacağı (ilk 500 gerçek yorumdan sonra)
- Custom deste paylaşımı (kısa kod ile) — v1.1
- Sinematik Kademe C'den hangileri v1'e girecek (§ `08` §3) — artan zamana göre karar
- Film Arşivi'nin tam sürümü mü minimum sürümü mü yapılacak (3.5 gün / 1.5 gün, § `07` §8 adım 13b)
- Yunanca'da EB Garamond eklenecek mi, yoksa serif rolü de Fira Sans Condensed'e mi verilecek (§ `01` §2)
- 20 kayıt / 500 MB kotasının gerçek kullanımda yeterli olup olmadığı — `replay_quota_evict` ile izlenecek
- Projektör döngü sesinin ayrı bir alt anahtar gerektirip gerektirmediği (§ `08` C7)
