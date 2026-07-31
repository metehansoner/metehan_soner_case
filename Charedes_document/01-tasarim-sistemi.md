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

92 destenin görselini tutarlı üretmek için tek prompt iskeleti. Boyut **1080×1440
(3:4)**, `@2x` ve `@3x` türevleri.

```
Vintage 1950s movie poster illustration of {KONU},
limited color palette: deep burgundy #47161F, cream #F4E7CE,
amber #F0A93B, muted teal #2F7F7C,
screen-printed texture, visible halftone dots, heavy film grain,
slightly faded and worn paper edges, high contrast,
bold simple composition with clear central subject,
no text, no letters, no watermark, flat illustration, not photorealistic
```

Kurallar:
- **Görselin üzerine yazı üretilmeyecek.** Başlık uygulama tarafında lokalize
  metinle basılıyor — 25 dilde 92 görseli yeniden üretmek imkânsız olurdu.
  (Referans uygulamada başlıklar görsele gömülü, bu yüzden tek dilde kalıyorlar.)
- Ana özne kartın üst %60'ında; alt %40 başlık şeridi için nefes alanı.
- Fotoğraf kullanılmayacak — tek bir fotoğraf tüm ızgarayı bozar.
- Dosya adı: `deck_{id}` → `Assets.xcassets/deck_movies.imageset/`

---

## 6. Erişilebilirlik

- Metin/zemin kontrastı: `textCream` üzerine `surfaceCard` = 11.4:1, amber buton
  üzerine `textOnAmber` = 9.8:1. Hepsi WCAG AA üstü.
- Grain ve scanline **Reduce Transparency** ve ayarlardaki "Film efektleri"
  kapalıyken devre dışı.
- Ampul yanıp sönmesi **Reduce Motion** açıkken durur (sabit yanık kalır).
- Tilt mekaniğine alternatif: oyun kartında ekranın sol/sağ yarısına dokunma da
  PAS/DOĞRU çalışır. Motor kısıtlılığı olan kullanıcı için zorunlu.
- Dynamic Type: gövde metinleri ölçeklenir; `gameWord` kendi dinamik küçültme
  mantığını kullanır.
