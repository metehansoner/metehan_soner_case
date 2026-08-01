# 05 — Desteler, Mix ve Custom Kategoriler

## 1. Çeşitlilik ilkesi

Referans uygulamalardaki deste listelerini incelediğimde asıl gücün **sayı değil
çeşitlilik** olduğunu gördüm. 90 tane film destesi olan uygulama, 30 tane farklı
türde destesi olandan zayıf. Kullanıcı masada oturduğu bağlama uygun bir deste
arıyor: yanında çocuğu mu var, arkadaşlarıyla mı içiyor, ailesiyle bayramda mı,
uzun yolda mı.

Bu yüzden katalog **6 çeşitlilik ekseninde** dengelenecek. Her eksende yeterli
temsil yoksa yeni deste eklemek katalogu büyütür ama iyileştirmez.

| Eksen | Uçlar | Neden önemli |
|---|---|---|
| **Kitle** | 3 yaş çocuk ↔ yetişkin arkadaş grubu | Aynı uygulama hem aile akşamına hem arkadaş gecesine hizmet etmeli |
| **Oynanabilirlik** | Canlandırılabilir (`mime`) ↔ Sadece anlatılabilir (`describe`) | "Periyodik Tablo" mimikle oynanamaz; bu ayrım kaydedilmezse kullanıcı kötü bir tur yaşıyor |
| **Bilgi gerektirme** | Herkes bilir ↔ Niş/fandom | Niş desteler tutkulu kullanıcıyı bağlar ama tek başına katalog olamaz |
| **Dönem** | Güncel ↔ 80'ler/90'lar nostalji | Nostalji desteleri farklı yaş grubunu masaya katıyor |
| **Kültürel bağ** | Global ↔ Yerel (§ `06` §3.2 `adapt`) | 25 dilde "yerli hissetme" bundan geliyor |
| **Zamanlama** | Yıl boyu ↔ Sezonluk | Sezon desteleri geri dönüş sebebi yaratıyor |

### Yeni: `playability` alanı

Referans uygulamada "Act It Out: Sports", "Act It Out: Part 1", "Act It Out:
Winter Edition" gibi desteler var — yani onlar da bu sorunu fark etmiş ama
çözümü deste adına gömmüş, bu da uzun listenin içinde kayboluyor.

Bizde bu bir veri alanı olacak:

| Değer | Anlamı | Örnek deste | Hangi modlarda |
|---|---|---|---|
| `mime` | Vücut diliyle canlandırılabilir | Meslekler, Hayvanlar, Günlük İşler | Tüm modlar |
| `describe` | Canlandırılamaz, anlatılması/ipucu verilmesi gerekir | Periyodik Tablo, Başkentler, Ülkeler | Klasik, Takım, Hız (canlandırma zorunlu değil) |
| `both` | İkisi de çalışır | Film Klasikleri, Süper Kahramanlar | Tüm modlar |

Etkisi: `Canlandır` (`actOut`) modu seçiliyken deste ızgarasında `describe`
desteler soluklaşır ve üstünde küçük bir `ANLATMA DESTESİ` etiketi çıkar.
Kullanıcı yine seçebilir ama ne olduğunu bilerek seçer. Bu tek alan, "kötü tur"
şikâyetlerinin büyük kısmını engelliyor.

---

## 2. Deste kataloğu

**124 deste tanımlı, 92'si v1'de.** Kalan 32'si güncelleme yol haritası — App
Store'da "her ay yeni deste" iletişimi için hazır cephane. Her deste ~130 kart,
v1 toplamı ~12.000 kart.

Kolonlar: **P** = playability (`M` mime / `D` describe / `B` both) ·
**L** = lokalizasyon (`lit` literal / `adp` adapt) · **v1** = ilk sürümde

### `PARTİ` — 10 deste

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `party` | Parti Başlangıcı **(ÜCRETSİZ)** | M | lit | ✓ |
| `icebreaker` | Buz Kırıcı | B | lit | ✓ |
| `partyFlirty` | Flörtöz | M | adp | ✓ |
| `dares` | Cesaret | M | lit | ✓ |
| `karaoke` | Karaoke | M | adp | ✓ |
| `dance` | Dans Hareketleri | M | lit | ✓ |
| `bachelor` | Bekarlığa Veda | M | adp | ✓ |
| `birthday` | Doğum Günü | M | lit | |
| `costume` | Kostüm & Kılık | M | lit | |
| `gossip` | Dedikodu Klasikleri | B | adp | |

### `CANLANDIR` — 12 deste (hepsi `mime`)

Bu bölüm `Canlandır` modunun kalbi. Hepsi vücut diliyle oynanabilir.

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `jobs` | Meslekler | M | lit | ✓ |
| `emotions` | Duygular ve Haller | M | lit | ✓ |
| `animalsAct` | Hayvan Taklitleri | M | lit | ✓ |
| `chores` | Günlük İşler | M | lit | ✓ |
| `sportsAct` | Spor Hareketleri | M | lit | ✓ |
| `superpowers` | Süper Güçler | M | lit | ✓ |
| `badHabits` | Kötü Alışkanlıklar | M | lit | ✓ |
| `accents` | Sesler ve Aksanlar | M | adp | ✓ |
| `celebImpressions` | Ünlü Taklitleri | M | adp | ✓ |
| `winterAct` | Kış Halleri | M | lit | |
| `couplesAct` | Çiftler | M | lit | |
| `babyAct` | Bebek Halleri | M | lit | |

### `FİLM & TV` — 16 deste

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `movieClassics` | Film Klasikleri | B | adp | ✓ |
| `cartoonMovies` | Çizgi Film Filmleri | B | lit | ✓ |
| `superheroes` | Süper Kahramanlar | B | lit | ✓ |
| `villains` | Kötü Karakterler | B | lit | ✓ |
| `tvSeries` | Diziler | D | adp | ✓ |
| `streaming` | Dizi Platformu Yapımları | D | adp | ✓ |
| `anime` | Anime | B | lit | ✓ |
| `horror` | Korku Filmleri | B | lit | ✓ |
| `scifi` | Bilim Kurgu | B | lit | ✓ |
| `actors` | Oyuncular | D | adp | ✓ |
| `movieQuotes` | Unutulmaz Replikler | D | adp | ✓ |
| `tvCartoons` | Çizgi Dizi Kahramanları | B | lit | ✓ |
| `movieNight` | Film Gecesi | M | lit | |
| `directors` | Yönetmenler | D | adp | |
| `awards` | Ödül Törenleri | D | lit | |
| `fictionalChars` | Kurgusal Karakterler | B | lit | |

### `MÜZİK` — 8 deste

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `singers` | Şarkıcılar | D | adp | ✓ |
| `bands` | Gruplar | D | adp | ✓ |
| `instruments` | Enstrümanlar | M | lit | ✓ |
| `genres` | Müzik Türleri | M | lit | ✓ |
| `lyrics` | Şarkı Sözleri | D | adp | ✓ |
| `kpop` | K-Pop | D | lit | ✓ |
| `rap` | Rap & Hip-Hop | D | adp | |
| `classical` | Klasik Müzik | D | lit | |

### `ÇOCUK` — 12 deste

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `kidsFirst` | İlk Kelimeler | M | lit | ✓ |
| `animalSounds` | Hayvan Sesleri | M | lit | ✓ |
| `colorsShapes` | Renkler ve Şekiller | D | lit | ✓ |
| `fairyTales` | Peri Masalları | B | adp | ✓ |
| `toys` | Oyuncaklar | M | lit | ✓ |
| `school` | Okul | M | lit | ✓ |
| `fruits` | Meyve ve Sebzeler | M | lit | ✓ |
| `vehicles` | Araçlar | M | lit | ✓ |
| `dinosaurs` | Dinozorlar | M | lit | ✓ |
| `numbersLetters` | Sayılar ve Harfler | D | lit | |
| `bedtime` | Uyku Vakti | M | lit | |
| `kidsHeroes` | Çocuk Kahramanları | B | adp | |

### `SPOR` — 10 deste

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `football` | Futbol *(en-US: "Soccer")* | B | adp | ✓ |
| `basketball` | Basketbol | B | lit | ✓ |
| `footballers` | Futbolcular | D | adp | ✓ |
| `olympics` | Olimpiyat Sporları | M | lit | ✓ |
| `combat` | Dövüş Sporları | M | lit | ✓ |
| `extreme` | Ekstrem Sporlar | M | lit | ✓ |
| `fitness` | Fitness Hareketleri | M | lit | ✓ |
| `teams` | Kulüpler | D | adp | |
| `motorsport` | Motor Sporları | D | lit | |
| `baseball` | Beyzbol | B | adp | |

### `BİLGİ & OKUL` — 12 deste

Bu bölüm çoğunlukla `describe` — mimikle oynanmaz, ipucu vererek oynanır.
Aile ve okul kullanımının merkezi.

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `space` | Uzay | B | lit | ✓ |
| `body` | İnsan Vücudu | M | lit | ✓ |
| `inventions` | İcatlar | B | lit | ✓ |
| `historyFigures` | Tarihi Kişiler | D | adp | ✓ |
| `famousWomen` | Tarihe Geçen Kadınlar | D | adp | ✓ |
| `mythology` | Mitoloji | B | adp | ✓ |
| `science` | Bilim Kavramları | D | lit | ✓ |
| `books` | Kitaplar | D | adp | ✓ |
| `writers` | Yazarlar | D | adp | |
| `periodicTable` | Periyodik Tablo | D | lit | |
| `art` | Sanat ve Ressamlar | D | lit | |
| `professionsHistory` | Kaybolan Meslekler | M | adp | |

### `MARKA & TEKNOLOJİ` — 8 deste

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `brands` | Markalar | D | adp | ✓ |
| `cars` | Otomobil Markaları | D | adp | ✓ |
| `socialMedia` | Sosyal Medya | M | lit | ✓ |
| `videoGames` | Video Oyunları | B | lit | ✓ |
| `mobileGames` | Mobil Oyunlar | B | lit | ✓ |
| `techCompanies` | Teknoloji Şirketleri | D | lit | ✓ |
| `gadgets` | Teknolojik Aletler | M | lit | |
| `fashion` | Moda ve Markalar | D | adp | |

### `NOSTALJİ` — 6 deste

Farklı yaş grubunu masaya katan bölüm. Referans uygulamada "Back to 90's",
"Reminiscing '80s", "the 2000s", "Best of the Decade" var ve popüler işaretli —
talep gerçek.

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `nineties` | 90'lara Dönüş | B | adp | ✓ |
| `eighties` | 80'ler | B | adp | ✓ |
| `twoThousands` | 2000'ler | B | adp | ✓ |
| `retroTech` | Eski Teknoloji | M | lit | ✓ |
| `childhoodGames` | Sokak Oyunları | M | adp | ✓ |
| `decadeBest` | On Yılın En'leri | D | adp | |

### `DÜNYA & SEYAHAT` — 8 deste

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `countries` | Ülkeler | D | lit | ✓ |
| `cities` | Şehirler | D | adp | ✓ |
| `capitals` | Başkentler | D | lit | ✓ |
| `flags` | Bayraklar | D | lit | ✓ |
| `landmarks` | Görülmesi Gereken Yerler | B | lit | ✓ |
| `food` | Yemekler | M | adp | ✓ |
| `drinks` | İçecekler | M | adp | ✓ |
| `bucketList` | Yapılacaklar Listesi | M | lit | |

### `HAYVANLAR & DOĞA` — 6 deste

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `animals` | Hayvanlar | M | lit | ✓ |
| `seaLife` | Deniz Canlıları | M | lit | ✓ |
| `birds` | Kuşlar | M | lit | ✓ |
| `dogBreeds` | Köpek Irkları | D | lit | ✓ |
| `catBreeds` | Kedi Irkları | D | lit | |
| `nature` | Doğa ve Hava | M | lit | |

### `EV & GÜNLÜK HAYAT` — 6 deste

Referans uygulamadaki "Around the House" ve "Everyday Essentials" desteleri
akıllı bir seçim: en kolay canlandırılan ve en geniş kitleye hitap eden içerik.
Yeni oyuncu için ideal başlangıç.

| id | Deste | P | L | v1 |
|---|---|---|---|---|
| `household` | Evdeki Eşyalar | M | lit | ✓ |
| `everyday` | Günlük İhtiyaçlar | M | lit | ✓ |
| `kitchen` | Mutfak | M | lit | ✓ |
| `clothes` | Kıyafetler | M | lit | ✓ |
| `tools` | Aletler | M | lit | |
| `hobbies` | Hobiler | M | lit | |

### `SEZON & TATİL` — 10 deste (tarih penceresine göre görünür)

| id | Deste | Pencere | P | L | v1 |
|---|---|---|---|---|---|
| `newYear` | Yılbaşı | 15 Ara – 5 Oca | M | lit | ✓ |
| `christmas` | Noel | 1 – 31 Ara | B | lit | ✓ |
| `christmasMovies` | Noel Filmleri | 1 – 31 Ara | D | lit | ✓ |
| `valentine` | Sevgililer Günü | 7 – 20 Şub | M | lit | ✓ |
| `halloween` | Cadılar Bayramı | 20 – 31 Eki | B | lit | ✓ |
| `ramadan` | Ramazan | hicri takvim | M | adp | ✓ |
| `eid` | Bayram | hicri takvim | M | adp | ✓ |
| `summer` | Yaz | Haz – Ağu | M | lit | ✓ |
| `backToSchool` | Okul Açılışı | 25 Ağu – 20 Eyl | M | lit | |
| `easter` | Paskalya | değişken | M | lit | |

`ramadan` ve `eid` destelerinin varlığı önemli: 25 dilin içinde Arapça, Endonezce,
Malayca ve Türkçe var — bu dört pazarın toplamı küçük değil ve rakip uygulamalarda
bu içerik hiç yok. Referans uygulamada 10 tane Noel/Paskalya destesi varken tek
bir bayram destesi bulunmuyor. Bizim için net bir boşluk.

### Yetişkin içeriği — yok

**Karar: uygulamada 18+ / yetişkin içerikli deste bulunmayacak.** Ne ayar
arkasında gizli, ne ayrı bölüm olarak. `Ateşli`, `İçki Oyunu`, `Sadece
Yetişkinler` gibi desteler katalogdan tamamen çıkarıldı.

Bu kararın somut karşılıkları:

| Konu | Sonuç |
|---|---|
| App Store yaş sınırı | **12+** rahatça (17+ riski ortadan kalktı) |
| Ayarlar | "Yetişkin içeriği" anahtarı yok — bir satır eksildi |
| Filtre chip'leri | `18+` chip'i yok |
| Günlük bedava deste rotasyonu | Tüm premium desteler havuza dahil; hiçbir istisna yok |
| Deste veri modeli | `isAdult` alanı yok |
| Kurumsal kullanım | Uygulama okul, aile ve iş yeri etkinliklerinde sorunsuz önerilebilir |

Bu, ürünü zayıflatan değil netleştiren bir karar. Yetişkin içeriği olan bir
parti oyunu, "aile oyunu" olarak konumlanamıyor ve App Store'un aile/eğitim
listelerine giremiyor — oysa bu kategoride keşfedilebilirliğin büyük kısmı
oradan geliyor.

**İçerik sınırı (tüm katalog için geçerli):** Cinsel içerik, alkol/madde teşviki,
küfür ve müstehcen ima yok. `PARTİ` bölümündeki `partyFlirty` (Flörtöz) ve
`bachelor` (Bekarlığa Veda) desteleri korundu ama içerikleri **12+ seviyesinde**
kalacak: "ilk buluşma", "çiçek göndermek", "gelinlik" gibi kartlar; ima içeren
hiçbir kart yok. Bu iki deste editoryal gözden geçirmede ayrıca kontrol edilecek
ve sınırda kalırlarsa çıkarılacak.

### Bölüm özeti

**13 bölüm, 124 deste tanımlı, 92'si v1'de.**

| Bölüm | Toplam | v1 | Ağırlıklı `playability` |
|---|---|---|---|
| Parti | 10 | 7 | mime |
| Canlandır | 12 | 9 | mime |
| Film & TV | 16 | 12 | both |
| Müzik | 8 | 6 | describe |
| Çocuk | 12 | 9 | mime |
| Spor | 10 | 7 | mixed |
| Bilgi & Okul | 12 | 8 | describe |
| Marka & Teknoloji | 8 | 6 | mixed |
| Nostalji | 6 | 5 | both |
| Dünya & Seyahat | 8 | 7 | describe |
| Hayvanlar & Doğa | 6 | 4 | mime |
| Ev & Günlük Hayat | 6 | 4 | mime |
| Sezon & Tatil | 10 | 8 | mime |
| **Toplam** | **124** | **92** | |

Dağılım kontrolü: `mime` %49 (61 deste), `both` %22 (27), `describe` %29 (36).
Hedeflenen denge bu —
`Canlandır` modu için yeterli mime destesi var, `describe` desteler de bilgi/aile
oyunu ihtiyacını karşılıyor.

Filtre chip'leri (**16 adet**, yatay scroll):
`TÜMÜ` · `POPÜLER` · `YENİ` · `PARTİ` · `CANLANDIR` · `FİLM & TV` · `MÜZİK` ·
`ÇOCUK` · `SPOR` · `BİLGİ` · `MARKA` · `NOSTALJİ` · `DÜNYA` · `HAYVANLAR` ·
`EV` · `SEZON`

3 dinamik/genel chip + **13 bölüm chip'i** = 16. Bölüm sayısı ile chip sayısı
eşleşmek zorunda; bir bölümün chip'i yoksa o bölümün desteleri filtreyle
erişilemez hâle geliyor (bu hata bir kez oldu: `MARKA & TEKNOLOJİ` chip'i eksikti,
8 deste filtre dışında kalmıştı). CI doğrulaması #8 bunu kontrol edecek.

`POPÜLER` ve `YENİ` dinamik: ilki kullanım verisinden (Remote Config ile
güncellenen liste), ikincisi son 60 günde eklenen desteler.
`SEZON` sadece ilgili tarih penceresinde görünür.

---

## 3. Fikri mülkiyet (IP) riski — dikkat

Referans uygulamalarda `Harry Potter`, `Pokemons`, `Breaking Bad`, `Netflix
Series`, `Disney`, `Simpsons` gibi **doğrudan marka adı taşıyan desteler** var.
Bunlar bize cazip görünüyor ama iki farklı risk seviyesi karıştırılıyor:

| Kullanım | Risk | Örnek |
|---|---|---|
| Marka adını **kelime kartı içinde** kullanmak | Düşük — betimleyici kullanım | "Filmler" destesinde bir kartın "Titanic" olması |
| Marka adını **deste adı** yapmak | Orta | Deste adının "Harry Potter" olması |
| Marka **logosunu/karakter görselini** deste kapağında kullanmak | **Yüksek** | Pokémon karakteri çizilmiş kapak |

Kararımız:
- **Katalogda hiçbir destenin adı bir marka değil.** Referans uygulamadaki
  "Netflix Series" bizde `streaming` — *Dizi Platformu Yapımları*. İleride bu tür
  bir fandom destesi eklenirse aynı kural uygulanacak: "Harry Potter" değil
  `wizardWorld` — *Büyücü Dünyası*; "Pokemon" değil `pocketCreatures` —
  *Cep Yaratıkları*.
- Kapak görsellerinde **hiçbir telifli karakter, logo veya tanınabilir tasarım
  olmayacak.** Retro afiş estetiği bu konuda avantaj: soyut/atmosferik kapak
  zaten tema gereği.
- Kelime kartları içinde eser ve karakter adları kullanılıyor — bu, bir bilgi
  yarışması sorusunda film adı geçmesiyle aynı kategoride.
- Kullanıcı yine arama/keşifle bulabiliyor: deste açıklamasında "büyücülük
  okulu, sihirli yaratıklar ve asalar" gibi ifadeler yeterince açık.

Bu, referans uygulamalardan **bilinçli olarak ayrıldığımız** bir nokta. Onların
yaklaşımı işliyor olabilir ama App Store'da bir marka şikâyeti tüm uygulamanın
kaldırılmasına yol açabiliyor; 124 destelik bir katalogda bu riski 4-5 deste
için almaya değmez.

---

## 4. Ücretsiz erişim ve sezon

### Ücretsiz erişim

**Kalıcı ücretsiz deste: 1 adet — "Parti Başlangıcı" (`party`).**
Seçim gerekçesi: hem yetişkin hem karma masada çalışıyor, kelimeleri kolay
canlandırılıyor (ilk deneyimde başarı hissi veriyor), ve hiçbir kültürel/yaş
kısıtı yok. `PARTİ` bölümünün ilk destesi.

**Günlük rotasyonlu bedava deste: her gün 1 premium deste 24 saat açık.**
- Seçim: `dayOfYear % premiumDeckCount` — deterministik, sunucusuz, tüm
  kullanıcılarda aynı deste. Cihaz saati oynanırsa sadece başka bir desteye
  geçer, tüm desteler açılamaz.
- Rotasyon havuzu **tüm premium desteler** — hiçbir istisna yok. Katalogda
  yetişkin içerikli deste bulunmadığı için "çocuklu masaya sürpriz düşmesin"
  diye dışlanacak deste kalmadı. Sadece sezon desteleri, penceresi dışındayken
  havuzdan çıkar (Ağustos'ta Noel destesi açmak anlamsız olur).
- Ana ekranda en üstte marquee şeridi + geri sayım, kartta `BUGÜN BEDAVA` bandı.
- Detay ve gerekçe: § `03-onboarding-paywall.md` §3.

`DeckDef` içinde ayrıca `isFree: Bool` alanı var; günlük rotasyon bundan bağımsız
bir runtime kontrolü (`DeckCatalog.dailyFreeDeckID`) ile hesaplanır — asset veya
JSON değişikliği gerektirmez.

### Sezon mantığı
`SEZON` chip'i sadece ilgili tarih penceresinde görünür (örn. 15 Aralık–5 Ocak
arası Yılbaşı destesi ana ekranın en üstünde "ŞİMDİ VİZYONDA" şeridinde). Tarih
aralıkları koda gömülmez, Remote Config'ten okunur.

---

## 5. Veri modeli

### Deste metadata — Swift'te (tek kaynak)

```swift
struct DeckDef: Identifiable, Hashable {
    let id: String              // "movieClassics"
    let section: DeckSection    // .movieTV
    let reelNumber: Int         // kartta gösterilen "REEL No. 07"
    let playability: Playability // .mime / .describe / .both
    let localization: LocalizationStyle // .literal / .adapt
    let difficulty: Difficulty  // .easy / .medium / .hard
    let minPlayers: Int
    let isFree: Bool
    let seasonWindow: DateWindow?
    let addedAt: Date           // "YENİ" chip'i için

    // Türetilen — elle yazılmaz
    var titleKey: String { "deck.\(id).title" }
    var descKey: String  { "deck.\(id).desc" }
    var imageName: String { "deck_\(id)" }

    // Runtime
    var isLocked: Bool { !isFree
        && !SubscriptionStore.shared.isPremium
        && DeckCatalog.dailyFreeDeckID != id }

    func isRecommended(for mode: GameMode) -> Bool {
        mode == .actOut ? playability != .describe : true
    }
}
```

Bu türetme kuralı önemli: 124 deste × 3 anahtar = 372 string'i elle yazmak yerine
id'den üretiliyor. (`Imposter/Models/CategoryCatalog.swift` aynı yaklaşımı
kullanıyor ve iyi çalışıyor.)

`isRecommended(for:)` § `05` §1'deki `playability` mantığını uyguluyor: `Canlandır`
modunda `describe` desteler soluklaşıp `ANLATMA DESTESİ` etiketi alıyor, ama
seçilebilir kalıyorlar.

### Kelime verisi — JSON

`Imposter`'da tüm kelimeler tek `words.json` dosyasında (590 KB) tutuluyor.
Bizde 12.000 kart × 25 dil olacak; tek dosya **~15 MB** eder ve açılışta tamamı
parse edilir. Bu yüzden **deste başına ayrı dosya:**

```
Resources/Decks/
  movies.json
  animals.json
  ...
```

Şema:
```json
{
  "id": "movies",
  "version": 3,
  "localize": "adapt",
  "cards": [
    {
      "k": "titanic",
      "t": { "en": "Titanic", "tr": "Titanik", "de": "Titanic", "ar": "تيتانيك" },
      "d": 1
    }
  ]
}
```
- `k`: dilden bağımsız kalıcı anahtar (tekrar kontrolü ve analytics için)
- `t`: 25 dilin çevirisi
- `d`: zorluk 1–3 (tur içinde kolaydan zora sıralama opsiyonu için)
- `localize`: `"literal"` (birebir çevrilir) veya `"adapt"` (içerik kültüre göre
  uyarlanır — aynı `k` anahtarı farklı dilde farklı kişi/şey olabilir).
  Detay ve hangi destenin hangisi olduğu: § `06-ayarlar-ve-lokalizasyon.md` §3.2

Deste **isimleri** de aynı ilkeye tabidir: `deck.{id}.title` anahtarı çeviri değil
yerelleştirmedir (örnek: `football` destesi `en-US` locale'inde "Soccer" olur).
Mod isimleri için 25 dilin tam tabloları § `06` §3.1'de.

Yükleme: deste seçildiğinde lazy yüklenir, `NSCache` ile son 5 deste bellekte
tutulur. Ana ekranda hiçbir kelime dosyası okunmaz.

### Derleme zamanı doğrulama (öğrenilen ders)

`Imposter`'da `CategoryCatalog` içinde `hollywood` kategorisi tanımlı ama
`words.json`'da o anahtar yok — kullanıcı o kategoriyi seçtiğinde sessizce başka
kategorinin kelimeleri geliyor. Fark edilmemiş, çünkü doğrulama yok.

Bunu engellemek için **build script + unit test:**
1. `DeckDef` listesindeki her `id` için `Resources/Decks/{id}.json` var mı?
2. Her JSON'daki `cards` sayısı ≥ 60 mı?
3. Her kartın `t` sözlüğünde 25 dilin **tamamı** var mı? (eksik olan raporlanır)
4. Her `deck_{id}` imageset asset catalog'da var mı?
5. Her `deck.{id}.title` ve `.desc` anahtarı `en.json`'da var mı?
6. Hiçbir dilde `deck.*.title` 22 karakteri, `mode.*.title` 18 karakteri geçiyor mu?
7. `localize: "adapt"` işaretli destelerde öncelikli 6 dil (`en`, `tr`, `de`,
   `es`, `ru`, `fr`) için yerel içerik oranı %60'ın altında mı? (kartların
   `t` değerleri İngilizce ile birebir aynıysa uyarlanmamış sayılır)
8. **Her bölümün bir filtre chip'i var mı?** Bölüm sayısı = chip sayısı − 3
   (dinamik chip'ler). Bu kontrol olmadığı için `MARKA & TEKNOLOJİ` bölümü
   chip'siz kalmış ve 8 destesi filtreyle erişilemez hâle gelmişti.
9. **Her locale için font glif taraması** — o dilin örnek dizesi seçilen fontta
   gerçekten çiziliyor mu (§ `01` §2). Yunanca glif eksikliği bu testle yakalanır.

Bu 9 kontrol CI'da fail ederse merge edilmez. 92 deste × 25 dil ölçeğinde elle
takip imkânsız — nitekim yukarıdaki 8 ve 9 numaralı kontrollerin yokluğu bu
dökümanda iki gerçek hataya yol açtı.

---

## 6. MIX

### Ne işe yarıyor
Birden fazla desteyi tek havuzda karıştırıp oynamak. Uzun oturumlarda tek deste
tekrarlayıcı oluyor; Mix her kelimede sürpriz veriyor. Premium'un en somut
faydalarından biri.

### Mix Kurulum ekranı
- Üstte: `MIX` marquee başlığı + "Desteleri karıştır, kimse ne geleceğini bilmesin"
- Deste ızgarası, çoklu seçim. Seçili kartlarda amber çerçeve + sıra numarası.
- Ortada canlı özet: film makarası ikonu + `4 DESTE · 520 KART`
- Karışım göstergesi: yatay yığın çubuk, her destenin katkı oranı kendi renginde
- Alt: `KARIŞTIR VE OYNA`
- Kural: min 2, max 8 deste. 8'den fazlası kelime çeşitliliğini anlamsızlaştırıyor
  ve kurulum ekranını yönetilemez yapıyor.

### Kaydedilmiş karışımlar
Kullanıcı bir karışımı isimlendirip kaydedebilir (max 5): "Cuma Gecesi Karışımı".
Ana ekranda `BENİM DESTELERİM` bölümünde özel kart olarak görünür — kapağı
seçili destelerin kolajı. Tekrar oynama oranını belirgin artıran küçük bir özellik.

### Karıştırma algoritması
Naif yaklaşım (tüm kelimeleri birleştir + shuffle) 300 kartlı bir deste ile 60
kartlı desteyi karıştırınca küçük destenin kelimeleri neredeyse hiç gelmiyor.
Bunun yerine **ağırlıklı round-robin:** her destenin kendi karıştırılmış kuyruğu
olur, seçim sırasında desteler eşit olasılıkla çekilir. Böylece 60 kartlı deste
de görünür oluyor. Deste başına ağırlık kullanıcıya gösterilmez, sadece "eşit"
davranır.

---

## 7. CUSTOM DESTE

Kullanıcının kendi kelimelerine **iki kapı** var ve ikisini karıştırmamak gerekiyor:

| | Kelime Sepeti (`ownWords` modu) | Custom deste editörü |
|---|---|---|
| Nereden | Mod Seçimi | Ana ekran → `BENİM DESTELERİM` |
| Amacı | **Şimdi oynamak** | Kalıcı bir deste yapmak |
| Zorunlu alan | Yalnızca kelimeler | İsim + kelimeler (kapak opsiyonel) |
| Kaydetme | Tur **sonunda**, opsiyonel | Baştan, zorunlu |
| Ekran | 24 (§ `02`) | 8 |

Aynı iki bileşeni paylaşıyorlar: kelime giriş satırı ve toplu ekleme alanı.
Kaydedilen sepet bu bölümdeki limitlere ve depolamaya tabi oluyor — yani sepet
"kaydedilmemiş bir custom deste", ayrı bir veri tipi değil.

### Limitler
| | Ücretsiz | Premium |
|---|---|---|
| Deste sayısı | 1 (taslak, oynanamaz) | 3 |
| Kelime / deste | 100 | 100 |
| Oynamak için min kelime | 5 | 5 |

### Editör ekranı
- **İsim** — tek satır, max 24 karakter, marquee önizlemesi canlı güncellenir
- **Kapak** — 12 hazır retro afiş şablonu (soyut, konusuz: kadife, film şeridi,
  yıldız, spot ışığı…) + istenirse Photos'tan görsel seçme (Premium).
  Seçilen görsele otomatik olarak sepia + grain + altın çerçeve uygulanır →
  kullanıcı kapağı tema dışına çıkamaz, ızgara bozulmaz. Bu, custom içeriğin
  tasarımı bozmasını engelleyen kritik detay.
- **Kelime listesi** — üstte tek satır giriş + `EKLE`. Klavye açık kalır,
  Enter ile hızlı ekleme (30 kelime yazan kullanıcı için şart). Her satır
  sağa kaydırarak silinir, uzun basıp sürükleyerek sıralanır.
- **Toplu ekleme** — çok satırlı bir metin alanına yapıştır, satır/virgül ile
  ayrılır. "Hazır listemi yapıştırayım" isteğini karşılar.
- **Sayaç** — `18 / 100 kelime`, 5'in altında uyarı.
- Alt: `KAYDET` · `KAYDET VE OYNA`

### Kaydedilen sepetin kapağı
Sepet akışında kapak seçimi yok, ama kaydedilen deste ızgarada görünecek ve
kapaksız kart ızgarayı bozuyor. Karar: **kaydedilen sepete 12 şablondan biri
otomatik atanır** (deste adının hash'inden deterministik olarak — aynı isim aynı
kapağı alır, rastgele değil). Kullanıcı sonradan editörden değiştirebilir.

### Depolama
`SwiftData` (iOS 17+ zaten minimum): `CustomDeck` ve `CustomCard` modelleri.
UserDefaults'a JSON gömmekten daha temiz ve sıralama/silme işlemleri kolay.
iCloud senkronizasyonu v1'de **yok** (`.none`) — sonradan `ModelConfiguration`
ile açılabilir, veri şeması buna hazır tutulacak.

### Custom deste ve dil
Custom kelimeler çevrilmez, kullanıcının yazdığı dilde kalır. Deste kartında
küçük bir dil etiketi gösterilir (`TR`). Kullanıcı dili değiştirirse custom
desteler yine listede kalır, uyarı yok — kendi yazdığı içeriği görmek istiyor.

### Paylaşma (v1.1)
Custom desteyi kısa kodla (`CHRD-7K2M`) paylaşma. Karşı taraf kodu girip desteyi
içe aktarır. Sunucu gerekiyor (Firestore yeterli, zaten bağımlılıkta var). Viral
döngü potansiyeli yüksek ama v1'i geciktirmemesi için sonraya bırakılıyor.

---

## 8. Kart görselleri üretim planı

v1 için **92 deste görseli** (kalan 32'si güncellemelerde). Üretim sırası:

1. **8 pilot kart** — ücretsiz `party` + her `playability` türünden ve farklı
   bölümlerden örnekler (`jobs`, `movieClassics`, `countries`, `kidsFirst`,
   `nineties`, `football`, `christmas`). Bunlarla stil kilitlenir.
   Farklı bölümlerden seçmenin sebebi: retro afiş dilinin "Periyodik Tablo" gibi
   soyut bir konuda da çalıştığını görmek. Sadece kolay konularla stil onaylanırsa
   sonradan tıkanılıyor.
2. Stil onaylandıktan sonra kalan 84, bölüm bölüm (bölüm içinde görsel tutarlılık
   daha kolay yakalanıyor).
3. Her kapak **1024×1024 şeffaf PNG** (RGBA). Eski plandaki 1080×1440 opak kart
   terk edildi: kart zemini, krem başlık şeridi ve çerçeve uygulamada çiziliyor,
   görsel yalnızca ortadaki amblem. Böylece kapak 25 dilde tek dosya kalıyor ve
   tema değişse zemin koda dokunarak güncelleniyor (§ `01` §5).
4. Toplam boyut: ham master 1024×1024 RGBA olarak **64 MB** çıktı (kapak başına
   681 KB) — bu satırdaki eski `92 × ~180 KB = ~17 MB` tahmini ölçüldüğünde
   yanlış çıktı. Uygulamaya **512 px + 64 renk** türev giriyor: **2.6 MB**, gözle
   fark edilmiyor. Ölçüm ve gerekçe § `01` §5.7. On-Demand Resources'a gerek yok.
5. Prompt iskeleti ve kurallar § `01-tasarim-sistemi.md` §5'te.

İki kesin kural:

- **Görsel üzerine yazı basılmayacak** — başlıklar uygulamada lokalize metinle
  çizilir, yoksa 25 dil için 92 görseli yeniden üretmek gerekirdi.
- **Hiçbir telifli karakter, logo veya tanınabilir tasarım kullanılmayacak** (§3).
  Referans uygulamalarda Pokémon, Simpsons, Harry Potter görselleri var; bizde
  konu soyut/atmosferik anlatılacak.

### Bölüm bazlı renk ipuçları

124 kart aynı 4 renkli paletten üretilince ızgara monotonlaşıyor. Çözüm: her
bölüme paletin içinden **baskın bir ton** atamak. Palet dışına çıkılmıyor, sadece
ağırlık değişiyor — ızgarada göz bölümleri ayırt ediyor ama tema bozulmuyor.

| Bölüm | Baskın ton |
|---|---|
| Parti | `accentAmber` ağırlıklı, sıcak |
| Canlandır | `accentTeal` ağırlıklı |
| Film & TV | `bgVelvetDeep` ağırlıklı, koyu |
| Müzik | `accentBrass` + krem |
| Çocuk | `surfacePoster` ağırlıklı, açık ve ferah |
| Spor | `stateCorrect` yeşili + krem |
| Bilgi & Okul | `accentTeal` + koyu, ansiklopedik |
| Nostalji | soluk krem + `accentAmberDeep` |
| Dünya & Seyahat | teal + krem, harita hissi |
| Hayvanlar & Doğa | yeşil + amber |
| Ev & Günlük | krem ağırlıklı, sade |
| Sezon | mevsime göre (Noel kırmızı-yeşil, Yaz amber) |
