# 01 — Tasarım Sistemi: "GRAND MARQUEE"

Konsept: 1950'ler mahalle sineması. Bordo kadife perde, girişte amber ampul sırası,
duvarda krem renkli film afişleri, her şeyin üzerinde hafif bir film grain'i.
Uygulama **dark-only** (`.preferredColorScheme(.dark)` ile kilitli) — sinema salonu
ışıkları hep kısıktır.

**Yorum: MODERN RETRO (onaylandı).** Palet, doku ve süslemeler retro; tipografi,
boşluklar, dokunma hedefleri ve hiyerarşi tamamen modern. Somut karşılıkları:

| | Tam nostalji (seçilmedi) | **Modern retro (seçildi)** |
|---|---|---|
| Grain opacity | %8–10 | **%5**, statik değil ama çok ince |
| Scanline | Her ekranda | **Varsayılan kapalı**, ayarlardan açılabilir |
| Yıpranma/leke | Kenarlarda yırtık, kahve lekesi | Yok — sadece kağıt dokusu |
| Tipografi | Süslü, sıkışık, tüm başlıklar serif | Oswald condensed + geniş letterSpacing, serif sadece afiş başlıklarında |
| Boşluk | Yoğun, afiş gibi dolu | Modern iOS nefes payları (16/24pt ritim) |
| Renk satürasyonu | Solmuş, sepiye kaçan | Retro palet ama net; metin kontrastı AA üstü |
| İkonografi | Elle çizilmiş | SF Symbols + retro renklendirme |

Kısacası: **uzaktan bakınca eski sinema afişi, elde tutunca 2026 iOS uygulaması.**
Görsel taslaklardaki (`assets/mockup-ana-ekran.png`) grain yoğunluğu tam nostalji
yönüne yakındı; son üründe belirgin şekilde daha ince olacak.

---

## 1. Renk paleti

Renkler asset catalog'da colorset olarak **değil**, `Theme/AppColors.swift` içinde
hex sabitleri olarak tanımlanacak. Sebep: tek dosyada tüm paleti görmek, kod
üzerinden türetme (opacity/blend) yapabilmek ve tema varyantı eklerken 40 tane
`.colorset` klasörü yönetmemek.

### Arka plan katmanları

| Token | Hex | Kullanım |
|---|---|---|
| `bgFilmBlack` | `#100C0A` | En dış katman, ekranın kenarları |
| `bgVelvetDeep` | `#2B0E15` | Kadife perde koyu tonu |
| `bgVelvetMid` | `#47161F` | Kadife perde orta tonu |
| `bgVelvetLight` | `#5E1E27` | Perde kıvrım ışığı |
| `bgSpotlight` | `#8A4B1E` | Üstten gelen sıcak spot ışığı (düşük opacity) |

Ekran arka planı bunların radial gradient'i: merkezde `bgVelvetMid`, kenarlarda
`bgFilmBlack`, üst-orta noktada `bgSpotlight` %18 opacity ile sıcak bir hale.

### Yüzeyler

| Token | Hex | Kullanım |
|---|---|---|
| `surfaceCard` | `#1C1512` | Koyu kart, liste satırı |
| `surfaceCardRaised` | `#2A201A` | Seçili/öne çıkan kart, sheet zemini |
| `surfacePoster` | `#F4E7CE` | Afiş kağıdı — açık zeminli kartlar, oyun kartı |
| `surfaceTicket` | `#E8D3A9` | Bilet kağıdı — skor kartı, kupon görünümü |

### Accent (vurgu)

| Token | Hex | Kullanım |
|---|---|---|
| `accentAmber` | `#F0A93B` | **Birincil buton**, marquee ampul, aktif chip |
| `accentAmberDeep` | `#D2861F` | Amber'in basılı/gölge tonu |
| `accentGold` | `#E3C36A` | İnce çerçeveler, ayırıcı çizgiler, "premium" işareti |
| `accentBrass` | `#A8791F` | Pirinç detay, ikincil ikon |
| `accentTeal` | `#2F7F7C` | Retro afiş teali — ikincil buton, bilgi etiketi |

### Durum renkleri

| Token | Hex | Kullanım |
|---|---|---|
| `stateCorrect` | `#4F8F5B` | DOĞRU (retro yeşil, neon değil) |
| `stateSkip` | `#C0392B` | PAS (retro kırmızı) |
| `stateWarning` | `#E0A030` | Süre azaldı |
| `stateLocked` | `#6E5B4B` | Kilitli deste, disabled |

### Metin

| Token | Hex | Kullanım |
|---|---|---|
| `textCream` | `#F6EBD6` | Birincil metin (koyu zemin) |
| `textSecondary` | `#C6B394` | İkincil/açıklama metni |
| `textMuted` | `#8B7A66` | Yardımcı, dipnot |
| `textOnPoster` | `#1C1512` | Afiş kağıdı üzerindeki metin |
| `textOnAmber` | `#201509` | Amber buton üzerindeki metin |

### Buton token'ları

| Token | Değer |
|---|---|
| `btnPrimaryBg` / `btnPrimaryText` | `accentAmber` / `textOnAmber` |
| `btnSecondaryBg` / `btnSecondaryText` | `surfaceCardRaised` + 1px `accentGold` kenar / `textCream` |
| `btnDangerBg` | `stateSkip` |
| `btnDisabledBg` / `btnDisabledText` | `#33281F` / `stateLocked` |

**Neden neon yok:** Retro palette'in inandırıcılığı düşük satürasyondan geliyor.
Yeşil `#4F8F5B` yerine `#00FF88` kullanırsak tema anında "modern oyun"a kayar.

---

## 2. Tipografi

25 dil desteklediğimiz için font seçimi **sadece estetik değil, teknik bir karar.**
Latin dışında üç yazı sistemi var: **Kiril** (`ru`, `uk`, `be`), **Yunan** (`el`),
**Arap** (`ar`). Çoğu popüler retro display fontunun (Bebas Neue, Alfa Slab One,
Anton) bunların hiçbiri yok. Bu yüzden geniş kapsamlı aileler seçildi.

### Ana aileler

| Rol | Font | Kullanım |
|---|---|---|
| **Display / Marquee** | **Oswald** (Bold, SemiBold) | Logo, ekran başlıkları, oyun kartındaki kelime, buton metni, geri sayım rakamı — hepsi ALL CAPS |
| **Accent / Afiş** | **Playfair Display** (Black, Bold Italic) | Deste kartı başlıkları, paywall headline, jenerik akışı, "SAHNE 1" tarzı süslemeler |
| **UI / Gövde** | **Rubik** (Regular, Medium, SemiBold, Bold) | Tüm gövde metni, liste satırları, ayarlar, açıklamalar |

Üçü de SIL Open Font License — ticari kullanım ve gömme serbest.

### Yazı sistemi kapsam matrisi

Aşağıdaki tablo Google Fonts / Fontsource'taki gerçek subset listelerinden
**doğrulandı** (Temmuz 2026), tahmine dayanmıyor:

| Font | Latin | Latin Ext | Kiril | **Yunan** | **Arap** |
|---|:--:|:--:|:--:|:--:|:--:|
| Oswald | ✓ | ✓ | ✓ | **✗** | ✗ |
| Playfair Display | ✓ | ✓ | ✓ | **✗** | ✗ |
| Rubik | ✓ | ✓ | ✓ | **✗** | ✓ |

> **Düzeltme:** Bu dökümanın önceki sürümü Oswald için "Yunanca" yazıyordu.
> **Yanlış.** Oswald'ın subset listesi `latin, latin-ext, cyrillic, cyrillic-ext,
> vietnamese` — Yunan glifi yok. Playfair ve Rubik'te de yok. Yani Yunanca (`el`)
> locale'inde **üç fontun hiçbiri çalışmıyordu** ve tüm arayüz sistem fontuna
> düşüyordu; o dilde tasarım kimliği tamamen kayboluyordu.

### Locale'e göre font ikamesi

Arapça için zaten bir ikame mekanizması vardı; Yunanca da aynı mekanizmaya
bağlanıyor. Tek yeni kavram yok, sadece tablo genişliyor.

| Locale | Display | Accent | UI | Not |
|---|---|---|---|---|
| Diğer 23 dil | Oswald | Playfair Display | Rubik | Varsayılan |
| `ar` Arapça | **Rubik Bold** | Rubik Bold | Rubik | Oswald ve Playfair'de Arap glifi yok. Display rolü Rubik Bold'a düşer |
| `el` Yunanca | **Fira Sans Condensed** (Bold/ExtraBold) | **EB Garamond** (Bold, Bold Italic) | **Fira Sans** (Regular–Bold) | Üçü de Yunan + Yunan Ext içeriyor, doğrulandı |

Yunanca ikamesinin seçim gerekçesi:

- **Fira Sans Condensed** — Yunanca destekleyen fontlar arasında Oswald'a en yakın
  siluete sahip olan. Condensed, ALL CAPS'te dar ve dik duruyor, marquee
  tipografisi bozulmuyor. Ayrıca aynı aileden **Fira Sans** UI rolünü de
  karşılıyor, yani Yunanca için tek aile iki rolü çözüyor.
- **EB Garamond** — old-style serif; Playfair'in didone karakterinden farklı ama
  ikisi de afiş/jenerik serif'i olarak okunuyor. Yunanca tipografide zaten
  referans kabul edilen bir aile (politonik Yunanca desteği tam).
- Yunanca subset'leri küçük: ağırlık başına 10–20 KB. Sadece Yunan subset'i
  gömülür, Latin kopyaları bundle'a girmez.

Ucuz alternatif: Yunanca'da serif rolünü de Fira Sans Condensed'e vermek (EB
Garamond hiç eklenmez). Tema o dilde biraz zayıflar ama bundle 3 dosya azalır.
Yunanca öncelikli bir pazar değilse kabul edilebilir.

### Kapsam dışı kalanlar

25 dilde **CJK (Çince/Japonca/Korece), Tayca, Hintçe, İbranice yok.** Dolayısıyla
bu yazı sistemleri için font stratejisi gerekmiyor. İleride Japonca veya Korece
eklenirse tipografi kararı **baştan açılmak zorunda** — Oswald'ın CJK karşılığı
yok ve ALL CAPS mantığı CJK'de anlamsız. Bu, dil listesi büyütülürken bilinmesi
gereken bir maliyet.

**Fallback zinciri:** Her ağırlık için PostScript ad adayları denenir → bulunamazsa
aile + symbolic trait → o da olmazsa `.system(design: .serif)`. Font bundle'a
girmezse uygulama çirkinleşir ama çökmez. (Bu pattern `Imposter/Theme/AppFonts.swift`
içinde çalışıyor, aynen taşınacak.)

`AppFont` katmanı locale kontrolünü **tek yerde** yapar; çağrı yerlerinde
(`Text(...).font(.marquee)`) hiçbir koşul yazılmaz. Dil değişimi anında olduğu
için (§ `06`) font ailesi de restart'sız değişmek zorunda — bu yüzden font
çözümü statik bir sabit değil, `LocalizationManager.current` üzerinden türetilen
bir değer olacak.

### Doğrulama testi

Yayın öncesi kontrol listesine (§ `06` §3.4) eklenecek bir birim testi:
her desteklenen locale için o dilin karakter kümesinden örnek bir dize alınıp
seçilen fontta **gerçekten çizilebildiği** doğrulanır (`CTFontGetGlyphsForCharacters`
ile eksik glif taraması). Böylece "Yunanca gliflerin yokluğu" gibi bir hata bir
daha gözden kaçmaz, CI'da yakalanır.

### Tip ölçeği

| Stil | Font / Boyut / Ağırlık | Özellik |
|---|---|---|
| `marquee` | Oswald Bold 44 | ALL CAPS, letterSpacing +2, amber glow shadow |
| `screenTitle` | Oswald Bold 28 | ALL CAPS, letterSpacing +1.5 |
| `posterTitle` | Playfair Display Black 22 | Deste kartı üstü |
| `gameWord` | Oswald Bold 64–96 (dinamik küçültme) | Oyun kartı, landscape, ALL CAPS |
| `sectionLabel` | Rubik SemiBold 12 | ALL CAPS, letterSpacing +2, `accentGold` |
| `body` | Rubik Regular 16 | |
| `bodyStrong` | Rubik SemiBold 16 | |
| `caption` | Rubik Regular 13 | `textSecondary` |
| `buttonLabel` | Oswald SemiBold 18 | ALL CAPS, letterSpacing +1 |

Sinematik katman ve Film Arşivi ile gelen ek stiller:

| Stil | Font / Boyut / Ağırlık | Nerede |
|---|---|---|
| `leaderNumber` | Oswald Bold 150 | Akademi geri sayımı rakamı (§ `08` A1) |
| `clapperField` | Oswald SemiBold 16 | Klaket satır değerleri; etiketler `Rubik Bold 8.5` |
| `creditsRole` | Rubik Bold 9.5 | Jenerik rol etiketi, letterSpacing +4, `accentGold` |
| `creditsName` | Playfair Display Black 25 | Jenerik takım/oyuncu adı (§ `08` B1) |
| `reelLabel` | Oswald SemiBold 9 | Arşiv kartındaki `SAHNE 03` etiketi |
| `subtitleWord` | Oswald Bold 34 | Replay oynatıcı altyazısı (§ `04` §4.4) |

Bu stiller de aynı locale ikamesinden geçer; Yunanca'da `leaderNumber` ve
`subtitleWord` Fira Sans Condensed'e, `creditsName` EB Garamond'a düşer.

---

## 3. Doku ve efekt katmanları

Retro hissi renkten çok **dokudan** geliyor. Hepsi prosedürel/SwiftUI ile
üretilecek, Lottie veya video kullanılmayacak.

| Katman | Nasıl | Nerede |
|---|---|---|
| **Film grain** | `Canvas` + deterministik seed'li noise, **%5 opacity**, 12 fps'te 3 kare arası döngü | Tüm ekranlarda en üst katman |
| **Vignette** | Radial gradient, kenarlarda `bgFilmBlack` %45 | Tüm ekranlar |
| **Marquee ampuller** | Kapsül kenarına dizilmiş 8–14 daire, sıralı yanıp sönme (0.12s offset) | Logo çerçevesi, birincil buton, kazanan skor kartı |
| **Kadife perde** | Dikey gradient şeritler, üstte `bgVelvetLight` kıvrım vurgusu | Onboarding ve paywall sheet arka planı |
| **Film şeridi (sprocket)** | Kenarda tekrarlayan yuvarlatılmış kare deliği | Deste kartı kenarı, tur sonu ekranı |
| **Işık sızıntısı (light leak)** | Köşeden gelen turuncu radial, %12 | Ana ekran sağ üst |
| **Scanline / çizik** | 2px aralıklı yatay çizgi, %3 — **varsayılan KAPALI**, ayarlardan açılır | Sadece oyun ekranı |
| **Projektör titremesi** | Ekran parlaklığında ±%2, 0.8s periyot | Sadece geri sayım ekranı |

Performans notu: grain ve ampul animasyonları 12 fps'te (`TimelineView(.animation(minimumInterval: 1/12))`)
çalışacak; 60 fps'te çizmek gereksiz pil tüketiyor ve retro his için 12 fps zaten
daha doğru duruyor.

---

## 4. Komponent anatomisi

### Birincil buton — "Marquee Button"
Kapsül, `accentAmber` zemin, `textOnAmber` metin, alt kenarda 3px `accentAmberDeep`
şerit (basılınca kaybolur → fiziksel tuş hissi), çevresinde 10 adet küçük ampul
noktası, basılıyken `scale 0.97`. Disabled'da ampuller söner.

### İkincil buton
Şeffaf zemin, 1.5px `accentGold` kenar, `textCream` metin. İçeride hafif
`surfaceCardRaised` dolgu.

### Deste kartı (Deck Card)
- Oran **3:4** (film afişi oranı, referans uygulamadaki kare karttan daha sinematik)
- Köşe yarıçapı 14 (yumuşak değil, afiş gibi)
- 1px `accentGold` iç çerçeve, 8px iç boşluk
- Alt kısımda kağıt dokulu şerit + Playfair Display başlık
- Sol üst köşede `REEL No. 07` etiketi (deste sırası)
- Sağ alt köşede kart sayısı: `130 KART` (deste başına hedef ~130, § `05` §2)
- **Kilitli hâli:** görsel %70 sepia + karartma, ortada pirinç kilit ikonu,
  üstünde "BİLET GEREKLİ" mührü (hafif eğik, damga dokusu)
- **Seçili hâli:** 2px `accentAmber` çerçeve + ampul dizisi yanar + `scale 1.03`

### Oyun kartı (landscape)
Tam ekran `surfacePoster` (krem kağıt), üstte ve altta film sprocket şeridi,
ortada `gameWord` ALL CAPS `textOnPoster`. Üst köşede kalan süre, alt köşede skor.
Tilt geri bildirimi: öne eğilince ekran `stateCorrect` yeşiline, arkaya eğilince
`stateSkip` kırmızısına tam ekran boyanır ve büyük ikon + damga animasyonu çıkar.

### Liste satırı (Ayarlar)
`surfaceCard` zemin, sol ikon `accentBrass`, başlık `bodyStrong`, sağda değer
veya toggle. Satır araları 1px `accentGold` %15 opacity çizgi.

### Toggle — "Marquee Switch"
Native `Toggle` yerine iki segmentli kapsül: `KAPALI` / `AÇIK`. Aktif segment
`accentAmber` zemin + `textOnAmber`. Retro anahtar hissi verir ve tema ile
tutarlı olur.

### Sheet
`presentationCornerRadius(28)`, üstte kadife perde gradient'i, tepede altın
tutamak çizgisi (grabber), zemin `surfaceCardRaised`.

### 4.1 Haptik dili — hangi dokunuş ne titriyor

Bu tablo olmadan haptik "her yere `.impact(.medium)`" olarak kodlanıyor ve
uygulama titreşiyor ama hiçbir şey anlatmıyor. Amaç şu: **her dokunuş kendi
fiziksel karşılığını versin.** Amber buton mekanik bir tuş, filtre chip'i bir
seçici, kilitli kart bir duvar — üçü aynı hissedilemez.

Tek kural üstte: **kullanıcının başlatmadığı hiçbir şey titremez.** Scroll,
otomatik kelime geçişi, toast, sheet açılışı ve ekran değişimleri haptik almaz.
Bir kullanıcı aksiyonu da **en fazla bir** haptik üretir.

| Etkileşim | Haptik | Neden bu |
|---|---|---|
| Birincil buton (`OYNA`, `BİLETİ AL`) | `.impact(.medium)` | Alt kenardaki 3px şeridin kaybolmasıyla eşzamanlı — tuşun oturması |
| İkincil buton, `›` satırları | `.impact(.light)` | Aksiyon var ama ağırlığı yok |
| Deste kartı seçme | `.impact(.rigid)` | Net klik: "kart PlayBar'a girdi" |
| Deste kartı seçimi kaldırma | `.impact(.soft)` | Aynı hareketin yumuşak tersi; ikisi ayırt edilebilir olmalı |
| Filtre chip'i, dil satırı | `.selection` | `UISelectionFeedbackGenerator` tam bunun için var: bir kümede gezinmek |
| Tur süresi stepper adımı | `.selection` | Her 15 saniye bir tık |
| Stepper sınırı (30s / 180s) | `.impact(.soft, 0.4)` | Tek küçük darbe: değer değişmedi ama dokunuş algılandı |
| Marquee Switch açılırken | `.impact(.rigid, 0.8)` | Fiziksel anahtar sesi/hissi |
| Marquee Switch kapanırken | `.impact(.soft, 0.6)` | Aynı anahtarın geri düşmesi |
| **Kilitli deste / kilitli mod** | `.impact(.rigid, 0.6)` | Donuk bir çarpma. `.error` **kullanılmıyor** — kullanıcı hata yapmadı, sadece duvara dokundu |
| **DOĞRU** | `.success` | § `04` §2 |
| **PAS** | `.warning` | § `04` §2 |
| Son 10 saniye, her saniye | `.impact(.light, 0.4)` | Tik sesiyle birlikte, nabız gibi |
| Süre bitti | `.impact(.heavy)` | Tek ağır darbe |
| Geri sayım rakamları (3, 2, 1) | `.impact(.medium)` | § `08` A1 |
| Klaket çubuğu kapanması | `.impact(.heavy)` | § `08` A2 — "klak" |
| Satın alma başarılı | `.success` | Bilet damgasıyla eşzamanlı |
| Satın alma başarısız | `.error` | Burada gerçekten hata var |
| Maç sonu / yeni rekor | `.success` | Fanfarla birlikte |
| Kelime geçişi (450 ms) | **yok** | Turda 10–20 kelime geçiyor; her birine haptik koymak sürekli titreşim demek |
| Scroll, sheet, navigasyon | **yok** | Sistem zaten hareketle söylüyor |

Kodlamada üç teknik kural, üçü de atlanınca hissedilir:

- **`prepare()` çağrılmadan ilk haptik ~100 ms gecikiyor.** Generator, anın
  hemen öncesinde hazırlanır: butonda parmak *inince* (tetik değil), geri sayım
  başlarken, tur başlarken. DOĞRU/PAS için `MotionService` eşiğe yaklaştığında
  hazırlık yapılabilir.
- **Generator'lar yeniden kullanılır**, her çağrıda `UIImpactFeedbackGenerator()`
  oluşturulmaz — hem gecikme hem pil.
- **DOĞRU/PAS haptiği eşiğin geçildiği anda çalar**, animasyon bittiğinde değil.
  Aksi hâlde oyunun tek mekaniği gecikmeli hissediliyor. 400 ms cooldown
  (§ `04` §2) haptik yığılmasını da baştan engelliyor.

İki gerçeği bilmek destek yazışmasını kısaltıyor:

- **iOS'un kendi "Sistem Titreşimi" anahtarı kapalıysa hiçbir haptik çalmaz** ve
  bu anahtarı okumanın public API'si yok. Yani bizim anahtarımız `AÇIK` görünürken
  kullanıcı hiçbir şey hissetmeyebilir. "Titreşim çalışmıyor" bildirimlerinin ilk
  cevabı bu; ayar satırının altına açıklama koymuyoruz (yanlış yerde uzun metin),
  destek şablonuna giriyor.
- **Mikrofonla kayıt sırasında iOS haptiği susturur.** Replay kaydımız sessiz
  (§ `04` §4.1), o yüzden etkilenmiyoruz — ama sonradan kayda ses eklenirse
  oyunun DOĞRU/PAS haptiği kaybolur. Bu, ses ekleme kararının gizli maliyeti.

Core Haptics (`CHHapticEngine`) v1'de **kullanılmıyor**; `UIFeedbackGenerator`
yukarıdaki tablonun tamamını karşılıyor. v1.1'de film şeridi geçişine özel bir
"tırtıklı makara" deseni düşünülebilir, tek gerçek gerekçesi olacak yer orası.

---

## 5. Deste görselleri için üretim reçetesi

92 deste kapağı **şeffaf amblem** olarak üretiliyor: zemin görselin içinde
değil, uygulamada çiziliyor. Boyut **1024×1024 kare RGBA**, kart içinde art
alanının %80 genişliğinde ortalanıyor.

### 5.1 Neden şeffaf

| | Opak 3:4 görsel | Şeffaf kare amblem |
|---|---|---|
| Palet sadakati | Her üretimde bordo tonu kayıyor | Zemin token'dan gelir, kayamaz |
| Kâğıt kenarı | Kartın altın çerçevesiyle çift çerçeve yapıyor | Sorun ortadan kalkıyor |
| Bölüm tonlaması | Sabit | Art alanı gradyanı bölüme göre değişebilir |
| Kilitli sepya | Tüm görsele uygulanıyor | Yalnız amblemi etkiler, zemin sabit kalır |

### 5.2 Kritik teknik gerçek

Görsel üretici **gerçek alfa kanalı vermiyor.** "Transparent background" denince
satranç desenini boyayarak taklit ediyor; çıkan dosya `RGB` modunda ve köşe
pikselleri beyaz. Bu yüzden kapaklar **paletimizde bulunmayan düz magenta
`#FF00FF` zeminle** üretilip `deste-gorselleri/pipeline.py` ile programatik
kesiliyor.

Kesme matematiği: gözlenen piksel `C = A·F + (1−A)·B`. Zemin `B` her dosyanın
kenar şeridinden **ölçülüyor** — üretici tam `#FF00FF` vermiyor, biraz kayıyor
ve sabit zemin varsayınca alfa tam sıfıra inmiyor. Alfa magenta taşmasından
türetiliyor, renk `F` unpremultiply ile geri kazanılıyor.

> Kaba despill (R ve B'den sabit değer çıkarma) denendi ve **ince ışınları
> soğutup grileştirdi.** Işın çelengi amblem kalıbının parçası olduğu için bu
> 92 kapağın tamamını bozardı; unpremultiply yolu tonu koruyor.

### 5.3 Prompt iskeleti

```
Vintage 1950s screen-printed poster style illustration of a single centered
emblem: {KONU}, framed loosely by a subtle symmetrical starburst of thin
radiating lines.
The illustration uses ONLY these four colors: cream #F4E7CE, amber gold
#F0A93B, muted teal #2F7F7C, and dark burgundy #47161F for outlines and
internal shading.
Screen-printed halftone dot texture visible inside the shapes.
CRITICAL BACKGROUND REQUIREMENT: place the entire artwork on a perfectly flat,
uniform, solid pure magenta background, exact color #FF00FF, completely even
with no gradient, no texture, no grain, no shading, no vignette and no drop
shadow anywhere on the magenta. Magenta must not appear anywhere inside the
illustration.
No frame, no border, no paper edge.
Absolutely no text, no letters, no numbers, no watermark, no logos.
Flat vector-like illustration, not photorealistic.
```

### 5.4 Kurallar

- **Görselin üzerine yazı üretilmeyecek.** Başlık uygulama tarafında lokalize
  metinle basılıyor — 25 dilde 92 görseli yeniden üretmek imkânsız olurdu.
  (Referans uygulamada başlıklar görsele gömülü, bu yüzden tek dilde kalıyorlar.)
- **Saydam/tül nesne yasak.** Chroma-key saydam özneyi kurtaramaz: magenta
  içinden geçer ve nesne pembeye boyanır. `bachelor` destesinde duvak tül
  üretildi ve pembe çıktı; opak krem duvakla yeniden üretildi. Cam, tül, duman,
  sabun köpüğü konu olarak seçilmeyecek — seçilirse "fully OPAQUE, not sheer,
  not translucent" ibaresi prompt'a eklenecek.
- **Pembe/mor/eflatun yasak.** Amblemin içinde magenta eksenine yakın renk
  olursa key onu zemin sanıp delik açar. Prompt'ta açıkça yasaklanıyor.
- **Gözenekli doku dolu gövde olarak istenecek.** File, ızgara, hasır, örgü,
  kafes gibi arası boşluklu dokular gerçek delikli üretilirse key o boşlukları
  keser ve amblem ortasında yırtık gibi görünür. `basketball` destesinde pota
  filesi gerçek örgü olarak geldi, dolu krem gövde + üstüne çizilmiş baklava
  deseniyle yeniden üretildi. Prompt'a "SOLID FILLED … mesh drawn only as thin
  lines on top of the solid fill, no see-through gaps" ibaresi ekleniyor.
- Ana özne kare tuvale ortalanıyor; içerik etrafında %4 nefes payı bırakılıyor.
- **Kadraj dışına uzantı yasak.** Asılı nesnelerde üretici zinciri/ipi tuvalin
  üst kenarına kadar götürüp kesiyor; kartta amblem kırpılmış görünüyor.
  `ramadan` destesinde fener zinciri kenardan taştı, kısa ve kapalı bir askı
  halkasıyla yeniden üretildi. Prompt'a "nothing touching or running off the
  image edges" ibaresi ekleniyor.
- Fotoğraf kullanılmayacak — tek bir fotoğraf tüm ızgarayı bozar.
- Dosya adı: `deck_{id}.png` → `Assets.xcassets/deck_{id}.imageset/`

### 5.5 Kalite kontrolü

`deste-gorselleri/kontrol.py` her kapağı üç ölçütle tarıyor ve bunlar CI'a
bağlanacak:

| Ölçüt | Nasıl | Eşik |
|---|---|---|
| Palet dışı renk | Opak piksellerin palete RGB uzaklığı | > %18 → **hata** |
| Pembe kalıntı | Key'in kaçırdığı magenta piksel | > %0.4 → **hata** |
| İç boşluk | Kenardan flood fill; dışa bağlı olmayan şeffaf bölge | > %0.5 → **incele** |

> İç boşluk tek başına hata sayılmıyor. Maskenin göz deliği, düdüğün kordon
> ilmeği, çalar saatin kulp kemeri gibi **meşru kapalı boşluklar** da bu ölçüte
> düşüyor ve kartta zeminin görünmesi doğru davranış. `animalsAct`, `sportsAct`
> ve `badHabits` bu yüzden işaretlendi, üçü de sağlam çıktı. Key'in gerçekten
> öznenin içini yediği durumun ayırt edici işareti palet ihlali ya da pembe
> kalıntıdır; ikisi de sıfırsa boşluk kasıtlıdır.

Sağlıklı bir kapakta şeffaf oran **%70–80**, yumuşak kenar **%2–4** civarında.
Şeffaf oran %35'in altına düşerse zemin kesilmemiş, opak oran %8'in altına
düşerse özne yenmiş demektir.

Sayısal kontrol amblemin **anlamını** denetlemiyor: IP ihlali, yaş uygunluğu,
aynı bölümdeki iki amblemin birbirine benzemesi gibi sorunlar ancak gözle
görülüyor. `deste-gorselleri/kontak.py {bölüm} {dosya}` bir bölümün kapaklarını
gerçek kart zemini üstünde ızgaraya dizip tek JPEG üretiyor; bölüm bitince önce
buna, sonra `kapaklar.html`e bakılıyor.

### 5.6 Üretim durumu

v1'in **92 kapağının tamamı üretildi.** Bölüm bölüm ilerlendi, her bölümün
sonunda kontak sayfasıyla gözle bakıldı. Çıktılar:

**Uygulamaya girecek dosyalar `teslim/` altında toplu**, üretim artıkları kendi
klasörlerinde kalıyor. Ayrımın sebebi pratik: Xcode'a eklenecek varlıkları
seçerken 92 kesilmiş kapağın yanında 92 magenta ham dosya, kontak sayfaları ve
elenmiş ikon adayları durmuyor. `teslim/` içeriği asset catalog'a olduğu gibi
kopyalanabilir.

| Klasör | İçerik | Uygulamaya girer |
|---|---|---|
| `teslim/deste-kapaklari/` | 92 kesilmiş kapak (1024×1024 RGBA) | ✓ |
| `teslim/ekran-gorselleri/` | 2 onboarding illüstrasyonu (4:3 RGBA) | ✓ |
| `teslim/app-ikonu/` | `ikon-1024.png` (RGB, alfasız) | ✓ |
| `deste-gorselleri/ham/` | Magenta zeminli üretim çıktıları (RGB, arşiv) | ✗ |
| `deste-gorselleri/_qc/`, `ekran-gorselleri/_qc/` | Kontak ve karşılaştırma sayfaları | ✗ |
| `ekran-gorselleri/app-ikonu/` | Elenen 7 ikon adayı | ✗ |
| `deste-gorselleri/{varyantlar,seffaf-test}/` | Stil arayışı denemeleri | ✗ |
| `kapaklar.html` | Bölüm bölüm gözden geçirme sayfası | ✗ |

Üç script de çıktısını `teslim/` altına yazıyor (`pipeline.py`, `kes.py`);
`kontrol.py` ve `kontak.py` oradan okuyor.

### 5.7 Dosya boyutu — hedef aşıldı, çözüm hazır

Ham çıktı **92 kapak = 64 MB**, kapak başına ortalama 681 KB. § `05` §8'in
hedefi 17 MB'dı ve § `07` §6'nın IPA hedefi 60 MB — yani kapaklar tek başına
tüm bütçeyi yiyor.

Sebep şaşırtıcı: görseller düz vektör gibi *görünüyor* ama tek bir kapakta
**110.000 farklı RGBA değeri** var. Üretici düz alanlara gözle görünmeyen hafif
gradyan ve gürültü koyuyor, PNG de bunu sıkıştıramıyor.

Ölçülen seçenekler (12 kapak örneğinden 92'ye ölçeklendi):

| Seçenek | Toplam | Not |
|---|---|---|
| 1024 RGBA (bugünkü) | 64 MB | Master, arşivde kalır |
| 512 RGBA | 21 MB | Hâlâ fazla |
| 1024 + 64 renk | 7 MB | Çözünürlük kaybı yok |
| **512 + 64 renk** | **2.6 MB** | Önerilen |

Renk sayısını 64'e indirmek gözle fark edilmiyor — ortalama piksel hatası 1.7/255
ve karşılaştırma `deste-gorselleri/_qc/boyut-karsilastirma.jpg`. 512 yeterli
çünkü kart ızgarada ~180pt genişliğinde, amblem kartın %80'i: @3x'te bile 430 px
görünüyor, 1024 iki kat fazla.

Karar: **master 1024 arşivde kalır, uygulamaya 512 + 64 renk girer.** Dönüşüm
teslim anında tek geçişte yapılır, ham dosyalar bozulmaz.

Palet ve pembe kalıntı ölçütlerinden **hiçbir kapak hata almıyor.** 18 kapak iç
boşluk uyarısı veriyor; hepsi maske göz deliği, çaydanlık kulpu, fener askısı
gibi kasıtlı boşluklar.

Üretim sırasında yeniden çekilen kapaklar ve nedenleri özetle: IP sızması
(`superheroes`, `streaming`, `anime`, `tvCartoons`), palet ihlali (`genres`,
`vehicles`), gerçek delikli doku (`basketball`), kart zeminiyle karışan gövde
rengi (`nineties`, `retroTech`), görselde harf (`badHabits`), kadraj taşması
(`ramadan`), konunun deste adını karşılamaması (`cars`).

---

## 6. Kapak dışı görsel varlık envanteri

Onboarding, Nasıl Oynanır ve paywall ekranları için **ikon üretmiyoruz.** Üç
kaynağa dağıtıyoruz ve üretilecek liste yalnızca 4 kaleme iniyor.

### 6.1 SF Symbols — üretim yok

Tüm arayüz ikonları SF Symbols, amber/pirinç tonuna boyanıyor (§1). Gerekçe
maliyet değil davranış: Dynamic Type ile ölçekleniyor, RTL dillerde yön
gerektiren semboller otomatik aynalanıyor, VoiceOver etiketleri hazır geliyor.
Elle çizilmiş ikon kümesi bu üçünü 25 dilde tek tek üstlenmek demek.

Paywall'ın sekiz satırlık fayda listesi ve onun pirinç ikonları **kaldırıldı**
(§ `03` §2): ekranın üst yarısını akan afiş duvarı devraldı, değer önerisi iki
satır özete indi. Dolayısıyla o ikon kümesine artık ihtiyaç yok — üretilecek
listeyi de, 25 dilde taşma kontrolünü de küçültüyor.

### 6.2 Kodla çizilenler — üretim yok

Bunlar statik görsel olarak üretilmemeli, çünkü ya **canlı veriye** ya da
**kullanıcı durumuna** bağlı; PNG olarak dondurulursa yanlış bilgi verir.

| Yer | Neden kod |
|---|---|
| **Onboarding 1** / Nasıl Oynanır 1 — yelpaze afişler | **Gerçek deste kapaklarından** diziliyor. Statik çizim, kapak seti değişince yalan söyler |
| **Onboarding 3** / Nasıl Oynanır 4 — eğme diyagramı | Telefonun eğilmesi **animasyonla** öğretiliyor; ayrıca kullanıcı dokunmatik moda geçtiyse bu sayfa gizleniyor ya da dokunma anlatımına dönüyor (§`09`). Statik görsel iki durumu karşılayamaz |
| Paywall görsel şeridi | Aynı kapak kolajı; modal varyantta **o destenin** kartı büyük gösteriliyor |
| Film şeridi ilerleme göstergesi, sprocket şerit, kupon tırtığı | Sayfa sayısına göre uzuyor, komponent |

Eğme diyagramında yeşil/kırmızı bölge tek ayırt edici olamaz — renk körlüğü için
ok yönü ve `DOĞRU`/`PAS` damga şekli de farklı (§7).

Onboarding 3 adıma indiğinde (§ `03` §1) app ikonu + marquee çerçeve kalemi bu
listeden **düştü**: eski adım 1'in görseliydi, o adım yelpaze afişlerle
birleştirildi. Kullanıcı uygulamaya ikona dokunarak giriyor, ilk ekranda ikonu
tekrar göstermenin bilgi değeri yok.

### 6.3 Üretilecekler — 4 kalem

| # | Varlık | Ölçü | Durum |
|---|---|---|---|
| 1 | Alnında telefon tutan figür, karşısında 3 kişi | 4:3, şeffaf | **Üretildi** — `teslim/ekran-gorselleri/ob_forehead.png`. Onboarding 2 + Nasıl Oynanır 2 |
| 2 | Mim yapan figür + üstü çizili konuşma balonu | 4:3, şeffaf | **Üretildi** — `teslim/ekran-gorselleri/ob_mime.png`. Yalnızca Nasıl Oynanır 3 |
| 3 | App ikonu | 1024×1024 opak | **Üretildi** — `teslim/app-ikonu/ikon-1024.png` (aday H) |
| 4 | App Store ekran görüntüleri | Cihaz başına set | Bekliyor; §`03` ASO ile birlikte |

İlk ikisi deste kapağı hattının chroma-key matematiğini aynen kullanıyor
(`ekran-gorselleri/kes.py`, `pipeline.magenta_kes`'i içe alıyor), tek fark tuvalin
kare değil 4:3 olması — sahnede iki taraf var, kareye sıkışınca figürler küçülüyor.
`kontrol.py` artık klasör argümanı alıyor, aynı ölçütler bu görsellere de
uygulanıyor. Buna ek iki kural giriyor:

- **İnsan figürleri silüet.** Ten rengi, saç tipi, yüz hattı, giyim kültürü
  yok — dolu tek renk gövde. 25 dilde tek görsel kullanacağız; belirgin bir etnik
  ya da kültürel okuma taşıyan figür bazı pazarlarda yabancı duruyor. Silüet
  ayrıca amblem diliyle de tutarlı.
- **Cinsiyet nötr.** Saç, etek, göğüs hattı gibi işaret yok; omuz ve duruşla
  ayrışan üç ayrı beden.

Görselde yazı yasağı burada da geçerli: konuşma balonu **boş** ve üstü çizili,
içine "..." bile yazılmıyor.

Kapaklarda karşılaşmadığımız iki hata bu iki görselde çıktı ve kural oldu:

- **Ten rengi kayması.** "Silüet" denince üretici figürü şeftali/bej tonda
  veriyor; palet kontrolünden geçse bile figür etnik okuma kazanıyor. Prompt'ta
  krem "eski kağıt rengi" olarak tanımlanıp *NOT peach, NOT beige, NOT tan*
  ibaresi ekleniyor.
- **Bordo çizgi bordo zeminde kayboluyor.** Kapaklarda ince bordo kontur amblemin
  kendi içinde kalıyor, ama bu sahnelerde bakış çizgileri figürler *arasında*
  gidiyor ve kadife zemine düşüyor. Zemine değen her çizgi amber/altın olacak.

### 6.4 App ikonu

Adaylar `ekran-gorselleri/app-ikonu/` altında, karşılaştırma sayfası
`ekran-gorselleri/_qc/app-ikonu.jpg`. Adaylar 260/120/60 px olarak yan yana
basılıyor, çünkü ikonun asıl sınavı 60 px.

| Aday | Fikir | 60 px'te |
|---|---|---|
| A | Ampullü marquee tabelası | Okunuyor, silüeti belirgin; ama oyunun ne olduğunu anlatmıyor |
| B | Alnında telefon tutan profil + ampul yayı | Telefon ince banda dönüşüp saç bandı gibi duruyor, ampul yayı dağılıyor |
| D | Alında ampullü kart, altında gözler, kartta kalın yıldız | Yıldız lekeye dönüyor |
| E | Aynı kompozisyon, kartta üç eşit boş satır | Üç satır ayrı ayrı ayakta kalıyor, gözler net |
| E2 | Aynısı, satırlar kademeli uzunlukta | En iyisi — kademeli satır "gizli yazı" okunuyor, eşit satırın hamburger menü riski yok |
| F | Ters şema: krem kart, amber çerçeve, bordo satırlar | Bordo satırlar tek koyu lekeye birleşiyor; ayrıca kart kremi yüz kremiyle aynı, kart–yüz sınırı kayboluyor |
| G | Kartı iki el tutuyor, kart hafif eğik | 260 px'te anlatımı en net aday, ama eller 60 px'te gürültüye dönüşüp kartı küçültüyor |
| H | Kart film şeridi: üstte ve altta sprocket delik sırası | E2'ye en yakın rakip; delikler kesikli bant olarak hayatta kalıyor, ama şerit jenerik "video kartı" gibi de okunabiliyor |

Tur 2 karşılaştırması `ekran-gorselleri/_qc/app-ikonu-tur2.jpg`. Finalistler
**E2** ve **H** oldu; ayrım fikirde: E2'nin ampul çerçevesi arayüzün marquee
diline, H'nin şeridi film motifine bağlanıyor.

**Karar: H — film şeridi kart.** Teslim dosyası
`teslim/app-ikonu/ikon-1024.png` (RGB, 1024×1024, alfa yok).
Sprocket delikleri 60 px'te kesikli bant olarak ayakta kalıyor ve şerit, ampul
çerçevesinden daha az piksel harcayıp kart yüzeyini büyük bırakıyor — üç boş
satır bu yüzden daha net okunuyor.

**Kompozisyon kararı, alında kart + altında gözler.** Referans olarak bakılan
uygulamanın ikonu da bu yapıyı kullanıyor ve küçük boyutta çalışmasının nedeni
belli: alındaki kart tek büyük düz şekil, gözler iki yüksek kontrastlı leke —
ikisi de 60 px'te hayatta kalıyor. Bizde tek fark, kartın üzerine **yazı
konmaması**: referans ikonda uygulama adı karta gömülü, biz 25 dil için tek ikon
kullandığımızdan onun yerine sprocket şeridi ve boş satır çubukları var. Üç
kademeli boş çubuk "kartta bir kelime var ama sen göremiyorsun" fikrini tek harf
kullanmadan anlatıyor.

Yüz burada da silüet kuralına tabi: **krem düz dolgu, ten tonu yok**, sadece
gözler ve kaşlar bordo. Gözlerin turkuaz irisi paletin içinden geliyor.

App ikonu için katı kurallar: **alfa kanalı ve şeffaflık yasak**, köşeler
yuvarlanmamış tam kare verilir (iOS kendi maskeler) ve kartın kenarları köşelere
dayanmaz — squircle maskesi köşeye taşan detayı kırpıyor. İkonun içine metin
konmaz. Teslim dosyası bu ölçütlerden geçti: RGB, palet dışı %0.69 (yalnızca
anti-alias kenarları), pembe/mor kalıntı yok, dört köşe opak.

---

## 7. Erişilebilirlik

- Metin/zemin kontrastı: `textCream` üzerine `surfaceCard` = 11.4:1, amber buton
  üzerine `textOnAmber` = 9.8:1. Hepsi WCAG AA üstü.
- Grain ve scanline **Reduce Transparency** ve ayarlardaki "Film efektleri"
  kapalıyken devre dışı.
- Ampul yanıp sönmesi **Reduce Motion** açıkken durur (sabit yanık kalır).
- Tilt mekaniğine alternatif: oyun kartında ekranın sol/sağ yarısına dokunma da
  PAS/DOĞRU çalışır. Motor kısıtlılığı olan kullanıcı için zorunlu.
- Dynamic Type: gövde metinleri ölçeklenir; `gameWord` kendi dinamik küçültme
  mantığını kullanır.
