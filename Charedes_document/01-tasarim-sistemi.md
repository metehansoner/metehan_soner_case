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

| Klasör | İçerik |
|---|---|
| `deste-gorselleri/ham/` | Magenta zeminli üretim çıktıları (RGB, arşiv) |
| `deste-gorselleri/seffaf/` | Kesilmiş kapaklar (1024×1024 RGBA, uygulamaya girecek) |
| `deste-gorselleri/_qc/` | Bölüm kontak sayfaları |
| `kapaklar.html` | Bölüm bölüm gözden geçirme sayfası |

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

Paywall fayda listesindeki "pirinç ikon"lar da buradan:

| Fayda satırı | Sembol |
|---|---|
| 92 temalı deste, 13 bölüm | `rectangle.stack.fill` |
| 12.000+ kart | `square.grid.3x3.fill` |
| 3 özel deste oluştur | `square.and.pencil` |
| Desteleri karıştır (Mix) | `shuffle` |
| Takım Savaşı ve Hız Turu | `flag.2.crossed.fill` |
| Reklamsız, sınırsız oyun | `infinity` |
| Aile Paylaşımı dahil | `person.2.fill` |

### 6.2 Kodla çizilenler — üretim yok

Bunlar statik görsel olarak üretilmemeli, çünkü ya **canlı veriye** ya da
**kullanıcı durumuna** bağlı; PNG olarak dondurulursa yanlış bilgi verir.

| Yer | Neden kod |
|---|---|
| Onboarding 1 — app ikonu + marquee çerçeve | Ampuller animasyonlu; çerçeve zaten komponent |
| Onboarding 2 / Nasıl Oynanır 1 — yelpaze afişler | **Gerçek deste kapaklarından** diziliyor. Statik çizim, kapak seti değişince yalan söyler |
| Onboarding 5 / Nasıl Oynanır 4 — eğme diyagramı | Telefonun eğilmesi **animasyonla** öğretiliyor; ayrıca kullanıcı dokunmatik moda geçtiyse bu sayfa gizleniyor ya da dokunma anlatımına dönüyor (§`09`). Statik görsel iki durumu karşılayamaz |
| Paywall görsel şeridi | Aynı kapak kolajı; modal varyantta **o destenin** kartı büyük gösteriliyor |
| Film şeridi ilerleme göstergesi, sprocket şerit, kupon tırtığı | Sayfa sayısına göre uzuyor, komponent |

Eğme diyagramında yeşil/kırmızı bölge tek ayırt edici olamaz — renk körlüğü için
ok yönü ve `DOĞRU`/`PAS` damga şekli de farklı (§7).

### 6.3 Üretilecekler — 4 kalem

| # | Varlık | Ölçü | Durum |
|---|---|---|---|
| 1 | Alnında telefon tutan figür, karşısında 3 kişi | 4:3, şeffaf | **Üretildi** — `ekran-gorselleri/seffaf/ob_forehead.png` |
| 2 | Mim yapan figür + üstü çizili konuşma balonu | 4:3, şeffaf | **Üretildi** — `ekran-gorselleri/seffaf/ob_mime.png` |
| 3 | App ikonu | 1024×1024 opak | 3 aday üretildi, seçim bekliyor |
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

Üç aday `ekran-gorselleri/app-ikonu/` altında, karşılaştırma sayfası
`ekran-gorselleri/_qc/app-ikonu.jpg`. Adaylar 300/120/60 px olarak yan yana
basılıyor, çünkü ikonun asıl sınavı 60 px.

| Aday | Fikir | 60 px'te |
|---|---|---|
| A | Ampullü marquee tabelası | Okunuyor — silüeti belirgin, parlak amber çember dikkat çekiyor |
| B | Alnında telefon tutan profil + ampul yayı | Kafa okunuyor, telefon ince bir banda dönüşüp saç bandı gibi duruyor; ampul yayı dağılıyor |
| C | Ampullü madalyon içinde aynı profil | Çember baskın, kafa lekeye dönüyor, telefon yok oluyor |

App ikonu için katı kurallar: **alfa kanalı ve şeffaflık yasak**, köşeler yuvarlanmamış
tam kare verilir (iOS kendi maskeler), ikonun içine metin konmaz — 25 dilde tek
ikon kullanıyoruz.

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
