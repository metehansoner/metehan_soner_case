# 06 — Ayarlar Menüsü ve Lokalizasyon

## 1. Ayarlar ekranı (sağ üst dişli)

**5 grup / 15 satır.** Ana ekranın **sağ üstündeki pirinç dişli** butonundan
`.sheet` olarak açılır (`presentationDetents([.large])`, `presentationCornerRadius(28)`),
arka planı kadife perde + grain. Ayrı bir sekme değil — tab bar kaldırıldı, § `02` §1.
Grup başlıkları `sectionLabel` stilinde (`accentGold`, ALL CAPS, letterSpacing +2).
Satırlar `surfaceCard` kartlar içinde, aralarında 1px altın %15 çizgi.

### Grup 1 — OYUN (`settings.group.play`)

| # | Satır | Kontrol | Varsayılan | Not |
|---|---|---|---|---|
| 1 | Dil | Değer + `›` → Dil sheet'i | Sistem dili | Alt metinde dilin kendi adı: "Türkçe". Seçim anında uygulanır, restart yok (§2) |
| 2 | Tur süresi | Stepper `−  01:00  +` | 60s | 30–180s, 15s adım |
| 3 | Cevap yöntemi | Segment: `EĞ` / `DOKUN` | Eğ | Tilt yerine dokunmatik |
| 4 | Zorluk | Segment: `HEPSİ` / `KOLAY` / `ZOR` | Hepsi | Kart `d` alanına göre filtreler |

Dil satırı **bu grubun ilk sırasında**, çünkü uygulamayı yanlış dilde açan
kullanıcının ayarlarda aradığı tek şey bu; aşağıya konursa kendi dilinde olmayan
14 satırı taramak zorunda kalıyor.

Bu grupta **yetişkin içeriği anahtarı yok** — katalogda 18+ deste bulunmuyor
(§ `05` §2). Uygulama baştan sona 12+ seviyesinde.

### Grup 2 — HİS & SES (`settings.group.feel`)

| # | Satır | Kontrol | Varsayılan |
|---|---|---|---|
| 5 | Titreşim | Marquee Switch | AÇIK |
| 6 | Ses efektleri | Marquee Switch | AÇIK |
| 7 | Film efektleri (grain, çizik) | Marquee Switch | AÇIK |
| 8 | Replay kaydı | Marquee Switch | KAPALI (Premium) |
| 9 | **Film Arşivi** | Değer + `›` → Arşiv (ekran 22) | Alt metin: `14 makara · 312 MB` |

`Titreşim` anahtarı **tüm** haptikleri kapatıyor: buton ve kart dokunuşlarını da,
oyunun DOĞRU/PAS geri bildirimini de. Ayrı bir "oyun içi titreşim" anahtarı
açmıyoruz — haptiği kapatan kullanıcı ya rahatsız oluyor ya pil düşünüyor, ikisi
de kısmi çözüm istemiyor. Hangi etkileşimin hangi haptiği aldığı § `01` §4.1'de.
Anahtar kapalıyken oyun oynanabilir kalıyor, çünkü DOĞRU/PAS'ın görsel ve sesli
karşılığı da var (§ `04` §2, üç kanal birlikte).

`Film efektleri` satırı retro temanın kaçınılmaz maliyetini yönetiyor: bazı
kullanıcılar grain'i sevmez, bazı eski cihazlarda pil tüketir. Kapatınca sadece
doku katmanları kalkar, palet ve tipografi aynı kalır — uygulama "temiz retro"
görünür, kimliği kaybetmez.

`Replay kaydı` açıldığında **önce** bir bilgi ekranı gelir ("bu kayıtlar masadaki
herkesi çekiyor, oyunculara haber ver"), sonra kamera izni istenir. Reddedilirse
anahtar otomatik kapanır ve altında sistem ayarlarına giden bir açıklama satırı
çıkar.

`Film Arşivi` satırı arşive giden **kalıcı** yol. Header'daki makara ikonu
koşulludur (kayıt yoksa görünmez), bu satır her zaman burada — kullanıcı "nereye
kaydediliyor" sorusunu ayarlarda arıyor.

Arşiv ekranının kendi içinde iki alt ayar var (ayarlar listesini şişirmemek için
oraya taşındı, § `04` §4.2):

| Alt ayar | Kontrol | Varsayılan |
|---|---|---|
| Otomatik silme | Segment: `7 GÜN` / `30 GÜN` / `SÜRESİZ` | 30 gün |
| Çıkışta kayıtları sil | Marquee Switch | KAPALI |
| Arşivi temizle | Yıkıcı buton + onay | — |

### Grup 3 — BİLDİRİMLER (`settings.group.notifications`)

| # | Satır | Kontrol | Varsayılan |
|---|---|---|---|
| 10 | Bildirimler | Marquee Switch | KAPALI (izin alınmamış) |
| 11 | Günlük bedava deste | Marquee Switch | AÇIK — **yalnızca 10 açıkken görünür** |

**Bu grup önceki sürümde yoktu ve gerekçesi "iki kaynak senkronsuz kalır"dı.**
Endişe gerçek ama çözümü satırı hiç koymamak değil; asıl sorun şuydu: soft
prompt'u bir kez kapatan kullanıcının bildirimleri **uygulama içinden açmasının
hiçbir yolu yoktu.** iOS Ayarlar'da da görünmüyordu, çünkü izin hiç istenmemiş
bir uygulama o listede yer almıyor. Yani özellik sessizce erişilemez oluyordu.

Senkron sorunu şu ayrımla çözülüyor: **izin iOS'un, içerik bizim.** Satır 10
izni kopyalamıyor, `UNAuthorizationStatus`'u *gösteriyor*; tek yerel tercih
satır 11, o da hangi bildirimi göndereceğimiz.

| Sistem durumu | Satır 10 | Dokunulunca |
|---|---|---|
| `.notDetermined` | KAPALI | Sistem izin diyaloğu açılır; onaylanırsa AÇIK'a geçer |
| `.authorized` | AÇIK | Kapatılırsa planlanmış bildirimler iptal edilir (`removeAllPendingNotificationRequests`). Sistem izni **geri alınmaz** — böyle bir API yok, zaten gerekmiyor |
| `.denied` | KAPALI + soluk | iOS Ayarlar'a gider (`openSettingsURLString`), altında tek satır: "iOS Ayarlar'dan izin verin" |

Durum her `scenePhase == .active` geçişinde yeniden okunuyor. Kullanıcı izni iOS
Ayarlar'dan geri alırsa satır uygulamaya dönüldüğünde kendiliğinden `.denied`
görünümüne düşüyor — korkulan senkronsuzluk tam olarak burada engelleniyor.

### Ne gönderiyoruz

İki bildirim, **ikisi de yerel.** Sunucu yok: APNs, push sertifikası,
`aps-environment` entitlement'ı ve Firebase Messaging bağımlılığı **hiç
girmiyor** (§ `07` §4).

| Bildirim | Zamanlama | Metin |
|---|---|---|
| Günlük bedava deste | Cihazın yerel saatiyle 18:00 | "ŞİMDİ VİZYONDA — Bugün {deste} bedava" |
| Deneme bitiyor | Deneme bitiminden 24 saat önce, tek seferlik | § `09` §7 |

18:00 seçimi keyfi değil: bu bir parti oyunu, akşam açılıyor. Sabah gönderilen
"bugün bedava" bildirimi akşama kadar unutulur.

Üç teknik tuzak, üçü de sonradan bulunması pahalı:

- **Tekrarlayan tetik kullanılamıyor.** `UNCalendarNotificationTrigger(repeats: true)`
  tek bir sabit metin taşır, ama bizim metnimizde **o günün deste adı** var.
  Çözüm: her açılışta önümüzdeki ~14 gün için deste adları hesaplanıp ayrı ayrı
  planlanır (§ `09` §8'deki sabit bölenli formül bunu deterministik yapıyor),
  eskiler temizlenir. 64 bekleyen bildirim sınırının çok altında kalıyoruz.
- **Dil değişince bekleyen bildirimler eski dilde kalıyor.** Planlanmış
  bildirimin metni planlama anında sabitleniyor; kullanıcı ayarlardan dili
  değiştirirse bir sonraki akşam Türkçe uygulamada İngilizce bildirim düşer.
  `LocalizationManager` dil değiştirdiğinde **bekleyen tüm bildirimler yeniden
  planlanacak.** Aynı şey abonelik durumu değişince de geçerli: premium olan
  kullanıcıya "bugün bedava" bildirimi anlamsız, iptal edilir.
- **Provisional authorization** (`.provisional`, izin diyaloğu olmadan sessiz
  bildirim) değerlendirildi ve **kullanılmıyor.** İzin oranını yükseltirdi ama
  bildirimimizin tüm değeri zamanında görülmesinde; Bildirim Merkezi'nde sessizce
  bekleyen "bugün bedava" hiçbir işe yaramıyor.

İzin isteme yeri değişmiyor: onboarding'de sorulmuyor, ana ekranda 8 saniye
gecikmeli soft prompt (§ `03`), oturum başına tek prompt kuralı § `09` §9'da.
Ayarlar satırı bu akışın yerine geçmiyor, **ikinci bir kapı** açıyor.
Analytics: `notification_permission_result(granted)` ve
`notification_setting_toggle(row, value)`.

### Grup 4 — HESAP (`settings.group.account`)

| # | Satır | Aksiyon |
|---|---|---|
| 12 | Aboneliği Yönet | Premium ise sistem abonelik sayfası; değilse Paywall (modal) |
| 13 | Satın Alımları Geri Yükle | `SubscriptionStore.restore()` + sonuç toast'ı |

Premium kullanıcıda bu grubun üstünde ayrıca bir **altın bilet kartı** görünür:
"TAM BİLET AKTİF · Yenileme: 12 Ağustos 2026". Ödediği şeyi görmesi iptal
oranını düşürüyor.

### Grup 5 — DESTEK & YASAL (`settings.group.legal`)

| # | Satır | Aksiyon |
|---|---|---|
| 14 | Bize Ulaş | `mailto:` — konu satırında UserID ve app sürümü hazır gelir |
| 15 | Bizi Puanla | `requestReview` |
| — | Gizlilik Politikası | `Link` |
| — | Kullanım Koşulları | `Link` |

(Gizlilik/Koşullar satır sayısına dahil edilmedi; en altta küçük punto, yan yana
iki link olarak duruyor.)

### En alt — kimlik kartı
```
UserID: A7F3-9C21-4E88
Dokunup basılı tutarak kopyala
Sürüm 1.0 (12)
```
Kopyalandığında 1.5 saniye "KOPYALANDI" durumu gösterilir. Destek taleplerinde
kullanıcıyı eşleştirmek için. UserID, RevenueCat `appUserID` ve Firebase
`setUserID` ile **aynı** değer.

---

## 2. Lokalizasyon: 25 dil

### Dil listesi

`Imposter` projesindeki 25 dil ile birebir aynı — çeviri dosyalarının bir kısmı
ve dil altyapısı doğrudan taşınabilir.

| # | Dil | Kod | Kendi adı |
|---|---|---|---|
| 1 | İngilizce | `en` | English |
| 2 | Türkçe | `tr` | Türkçe |
| 3 | Almanca | `de` | Deutsch |
| 4 | Arapça | `ar` | العربية |
| 5 | Belarusça | `be` | Беларуская |
| 6 | Katalanca | `ca` | Català |
| 7 | Çekçe | `cs` | Čeština |
| 8 | Danca | `da` | Dansk |
| 9 | Yunanca | `el` | Ελληνικά |
| 10 | İspanyolca | `es` | Español |
| 11 | Filipince | `fil` | Filipino |
| 12 | Fince | `fi` | Suomi |
| 13 | Fransızca | `fr` | Français |
| 14 | Hırvatça | `hr` | Hrvatski |
| 15 | Endonezce | `id` | Bahasa Indonesia |
| 16 | İtalyanca | `it` | Italiano |
| 17 | Malayca | `ms` | Bahasa Melayu |
| 18 | Norveççe Bokmål | `nb` | Norsk bokmål |
| 19 | Hollandaca | `nl` | Nederlands |
| 20 | Lehçe | `pl` | Polski |
| 21 | Portekizce | `pt` | Português |
| 22 | Romence | `ro` | Română |
| 23 | Rusça | `ru` | Русский |
| 24 | İsveççe | `sv` | Svenska |
| 25 | Ukraynaca | `uk` | Українська |

`Info.plist` → `CFBundleLocalizations` bu 25 kodu içerecek (App Store'da "Diller"
bölümünde görünmesi için zorunlu).

### Altyapı kararı: `.xcstrings` mi, custom JSON mu?

`Imposter` custom JSON kullanıyor (`Services/LocalizationManager.swift` +
`Resources/Localization/{kod}.json`). İyi tarafı: dil değişimi anında, restart
gerekmiyor, İngilizce üzerine merge fallback'i sayesinde eksik anahtar asla ham
key olarak görünmüyor.

**Karar: custom JSON devam.** Gerekçe:
- Uygulama içi dil değişimi anında olmalı (kullanıcı dili değiştirip hemen
  oynayacak). `.xcstrings` ile bunu yapmak `Bundle` swizzling gerektiriyor.
- Kelime verisi (`Resources/Decks/*.json`) zaten aynı çok-dilli JSON şemasında;
  iki farklı lokalizasyon mekanizması taşımak gereksiz.
- Merge fallback davranışı bizim için kritik: 25 dile 92 deste açıklaması
  eklerken bir dilde eksik kalan anahtar İngilizce görünür, ekranda `deck.x.title`
  yazmaz.

Kaybettiğimiz: Xcode'un export/import lokalizasyon iş akışı ve otomatik plural
desteği. Plural ihtiyacı için basit bir kural ekleniyor: anahtarın `.one` / `.other`
varyantları (`round.wordCount.one` / `.other`), `t(_:count:)` bunu seçer.
Slav dilleri için `.few` de destekleniyor (`ru`, `uk`, `pl`, `hr`, `cs`).

### Anahtar konvansiyonu

Noktalı namespace, `Imposter` ile aynı:
```
common.continue, common.cancel, common.next
onboarding.3.title, onboarding.3.body, onboarding.3.cta
paywall.plan.weekly.trial
deck.movies.title, deck.movies.desc
mode.rapid.title, mode.rapid.rule
settings.group.play, settings.language
howto.classic.2.title, howto.classic.2.body
game.correct, game.skip, game.timeUp
```
Placeholder formatı süslü parantez: `"{n} kelime"`, `"{team} kazandı"`.
`%@` kullanılmıyor — JSON'da tip güvenliği olmadığı için isimli placeholder
çeviri hatalarını azaltıyor.

### Dil seçim ekranı (Dil sheet'i)

- 25 satır, her biri **kendi dilinde** yazılı (`meta.languageName` anahtarından
  okunur, kod içinde de hardcoded fallback tablosu bulunur).
- Sağda seçili olanda altın onay işareti.
- Üstte arama alanı yok (25 satır kaydırılabilir uzunlukta).
- Seçim anında: `localeCode` güncellenir → UserDefaults'a `languageOverride`
  yazılır → JSON yeniden yüklenir → `LocalizationManager` `@Observable` olduğu
  için tüm ekranlar anında yeniden çizilir. **Restart yok.**
- Analytics: `language_change(from:to:)`

### İlk açılışta dil seçimi
`Locale.preferredLanguages` sırayla taranır, desteklenen ilk dil seçilir; hiçbiri
tutmazsa `en`. Alias tablosu gerekli (OS eski etiketler döndürebiliyor):
`tl→fil`, `no/nn→nb`, `in→id`, `pt-BR→pt`. Desteklenmeyenler `en`'e düşer:
`zh-*`, `ja`, `ko`, `th`, `hi`, `he`/`iw` (İbranice 25 dilde yok).

### RTL (Arapça)
Arapça tek RTL dilimiz. Yapılacaklar:
- Tüm layout `leading/trailing` kullanacak, asla `left/right` değil.
- Yön bağımlı ikonlar (`›`, geri oku) `.flipsForRightToLeftLayoutDirection(true)`.
- Display fontu Arapça'da Rubik Bold'a düşer (Oswald'da Arapça glifi yok).
  Yunanca için de benzer bir ikame var ama o RTL değil; tam tablo § `01` §2'de.
- Tilt yönü değişmez — fiziksel hareket dilden bağımsız.
- Onboarding slider'ı ve film şeridi ilerlemesi RTL'de sağdan sola akar.
- Test: `-AppleTextDirection YES` + Arapça locale ile en az bir tam tur oynanmalı.

### Çeviri üretim ve kalite

**Dil başına** hacim: ~450 UI anahtarı + 92 deste başlığı + 92 açıklama +
~12.000 kelime ≈ 12.634 dize.

**25 dille çarpınca toplam ≈ 316.000 dize.** Önceki sürüm bu satırı "toplam
çeviri hacmi" diye yazıyordu — 25 kat eksik hesap. Bu, projenin en büyük tek
kalemi ve § `07` §8'de "paralel iş" olarak geçiştirilmiş durumda; geliştirme
yarım gün hassasiyetinde bütçelenmişken içerik üretimi bütçesiz. Boşluk § `09`
§6'da ele alınıyor.

| Katman | Yöntem |
|---|---|
| UI anahtarları (~450) | LLM ile çeviri + `en`/`tr`/`de` insan gözden geçirmesi |
| Deste başlık/açıklama (184) | LLM + ekran taşma kontrolü (§ aşağıda) |
| Kelime kartları (12.000) | LLM ile toplu çeviri, **kültürel uyarlama kuralları ile** |

Kelime çevirisinde kritik kural: **birebir çeviri değil, yerelleştirme.**
"Ünlüler" destesindeki bir Amerikan TV sunucusu Türk kullanıcı için oynanamaz.
Bu yüzden `t` sözlüğünde bazı kartlar dile göre **farklı kişi/şey** içerebilir;
`k` (anahtar) aynı kalır, çeviri yerel karşılığı olur. Hangi destelerin yerel
uyarlama gerektirdiği JSON'da işaretlenir: `"localize": "adapt"` vs `"literal"`.

Ekran taşma kontrolü: Almanca ve Fince başlıklar İngilizce'nin ~%40 üzerinde
uzunlukta olabiliyor. Deste kartı başlığı 2 satırda sığmalı; build script her
dildeki `deck.*.title` uzunluğunu kontrol edip 22 karakteri geçenleri raporlar.

---

## 3. Kültürel yerelleştirme (transcreation)

Bu bölüm dökümanın en çok atlanan ama en yüksek etkili kısmı. **Çeviri ile
yerelleştirme farklı işlerdir.** Bir parti oyununda kullanıcı metni okumuyor,
metni *tanıyor*. Tanımadığı bir ifade gördüğünde "bu uygulama çeviri" diyor ve
güveni düşüyor.

Kural: **UI mekanik metinleri çevrilir, isimler yerelleştirilir.**
"Süre bitti" her dilde aynı şeydir, çevrilir. Ama bir oyunun adı, bir destenin
adı ve bir kartın içindeki ünlü kişi — bunlar kültüre bağlıdır, uyarlanır.

### 3.1 Mod isimleri — 25 dil

`id` değerleri asla değişmez; aşağıdaki tablolar sadece `mode.{id}.title`
anahtarının içeriğidir.

#### `classic` — Klasik mod
Bu modda sadelik doğru: her dilde "klasik" kelimesinin karşılığı kullanılıyor,
çünkü mod adı burada bir söz değil bir etiket.

| Dil | Ad | Dil | Ad |
|---|---|---|---|
| `en` | Classic | `it` | Classico |
| `tr` | Klasik | `ms` | Klasik |
| `de` | Klassisch | `nb` | Klassisk |
| `ar` | كلاسيكي | `nl` | Klassiek |
| `be` | Класічны | `pl` | Klasyczny |
| `ca` | Clàssic | `pt` | Clássico |
| `cs` | Klasika | `ro` | Clasic |
| `da` | Klassisk | `ru` | Классика |
| `el` | Κλασικό | `sv` | Klassisk |
| `es` | Clásico | `uk` | Класика |
| `fi` | Klassinen | `fil` | Klasiko |
| `fr` | Classique | `hr` | Klasik |
| `id` | Klasik | | |

#### `actOut` — Canlandırma modu (en kritik olan)
Her dilde **o ülkenin bu oyuna verdiği isim.** Türkçe'de "Sessiz Sinema",
Rusça'da "Крокодил", Lehçe'de "Kalambury", Hollandaca'da "Hints".

| Dil | Ad | Not |
|---|---|---|
| `en` | Act It Out | |
| `tr` | **Sessiz Sinema** | Türkiye'de oyunun yerleşik adı |
| `de` | Pantomime | "Scharade" da anlaşılır, Pantomime daha yaygın |
| `ar` | تمثيل صامت | "sessiz oyunculuk" |
| `be` | **Кракадзіл** | Rusça geleneğin Belarusça yazımı |
| `ca` | Mímica | |
| `cs` | Šarády | |
| `da` | Charader | |
| `el` | Παντομίμα | |
| `es` | Mímica | |
| `fi` | Pantomiimi | |
| `fil` | Pantomima | Alternatif: **Pinoy Henyo** — Filipinler'de alna kelime koyup tahmin etme oyununun ünlü adı. Marka çağrışımı riski var, native onayı gerekli |
| `fr` | Les Mimes | |
| `hr` | Pantomima | |
| `id` | Pantomim | |
| `it` | Mimo | |
| `ms` | Lakonan Bisu | "sessiz oyun" — Pantomim de kullanılabilir |
| `nb` | Charader | |
| `nl` | **Hints** | Hollanda'da uzun yıllar yayınlanan TV programından gelen yerleşik isim |
| `pl` | **Kalambury** | Polonya'da charades'in kendi adı |
| `pt` | Mímica | |
| `ro` | Mimă | |
| `ru` | **Крокодил** | Rusya'da bu oyunun adı budur; "Пантомима" çeviri kokar |
| `sv` | Charader | |
| `uk` | **Крокодил** | Aynı gelenek |

#### `teams` — Takım Savaşı

| Dil | Ad | Dil | Ad |
|---|---|---|---|
| `en` | Team Battle | `it` | Sfida a squadre |
| `tr` | Takım Savaşı | `ms` | Perang Pasukan |
| `de` | Team-Duell | `nb` | Lagkamp |
| `ar` | معركة الفرق | `nl` | Teamstrijd |
| `be` | Бітва камандаў | `pl` | Bitwa drużyn |
| `ca` | Batalla d'equips | `pt` | Batalha de Equipes |
| `cs` | Bitva týmů | `ro` | Bătălia echipelor |
| `da` | Holdkamp | `ru` | Битва команд |
| `el` | Μάχη ομάδων | `sv` | Lagkamp |
| `es` | Batalla de equipos | `uk` | Битва команд |
| `fi` | Joukkuetaisto | `fil` | Labanan ng Grupo |
| `fr` | Duel d'équipes | `hr` | Borba ekipa |
| `id` | Duel Tim | | |

#### `rapid` — Hız Turu
Burada dikkat: birçok dilde "yıldırım/şimşek" metaforu kullanılıyor
(`Blitzrunde`, `Lynrunde`, `Blixtrunda`, `Bliksemronde`) — bu doğal, korunmalı.
Rusça ve Ukraynaca'da tek kelime `Блиц` yeterli ve satranç kültüründen tanıdık.

| Dil | Ad | Dil | Ad |
|---|---|---|---|
| `en` | Speed Round | `it` | Turno lampo |
| `tr` | Hız Turu | `ms` | Pusingan Pantas |
| `de` | Blitzrunde | `nb` | Lynrunde |
| `ar` | جولة سريعة | `nl` | Bliksemronde |
| `be` | Бліц | `pl` | Błyskawiczna runda |
| `ca` | Ronda ràpida | `pt` | Rodada Relâmpago |
| `cs` | Bleskové kolo | `ro` | Rundă fulger |
| `da` | Lynrunde | `ru` | Блиц |
| `el` | Γύρος ταχύτητας | `sv` | Blixtrunda |
| `es` | Ronda rápida | `uk` | Бліц |
| `fi` | Pikakierros | `fil` | Bilisan Mo |
| `fr` | Manche éclair | `hr` | Brza runda |
| `id` | Ronde Kilat | | |

#### `mix` — Mix

| Dil | Ad | Dil | Ad |
|---|---|---|---|
| `en` | Mix | `it` | Misto |
| `tr` | Karışık | `ms` | Campuran |
| `de` | Mix | `nb` | Miks |
| `ar` | خليط | `nl` | Mix |
| `be` | Мікс | `pl` | Miks |
| `ca` | Barreja | `pt` | Mistura |
| `cs` | Mix | `ro` | Amestec |
| `da` | Miks | `ru` | Микс |
| `el` | Μιξ | `sv` | Mix |
| `es` | Mezcla | `uk` | Мікс |
| `fi` | Sekoitus | `fil` | **Halo-halo** | 
| `fr` | Mélange | `hr` | Miks |
| `id` | Campur | | |

`fil` için `Halo-halo`: Filipince'de "karışık" demek ve aynı zamanda ülkenin en
bilinen karışık tatlısının adı. Tam olarak aradığımız türden bir yerelleştirme —
kullanıcı gülümsüyor. Native onayı alınacak.

#### `ownWords` — Kendi Kelimelerin
Burada `classic` gibi davranıyoruz: bu bir kültürel oyun adı değil, bir etiket.
Çeviri düz, tek dikkat noktası **18 karakter sınırı** (§ `04` §1) — "kendi
kelimeleriniz" biçimindeki uzun kurulumlar birçok dilde sınırı aşıyor, o yüzden
her dilde kısa hâli seçildi.

| Dil | Ad | Dil | Ad |
|---|---|---|---|
| `en` | Own Words | `it` | Parole tue |
| `tr` | Kendi Kelimelerin | `ms` | Kata Sendiri |
| `de` | Eigene Wörter | `nb` | Egne ord |
| `ar` | كلماتكم | `nl` | Eigen woorden |
| `be` | Свае словы | `pl` | Własne słowa |
| `ca` | Paraules pròpies | `pt` | Suas palavras |
| `cs` | Vlastní slova | `ro` | Cuvinte proprii |
| `da` | Egne ord | `ru` | Свои слова |
| `el` | Δικές σου λέξεις | `sv` | Egna ord |
| `es` | Tus palabras | `uk` | Свої слова |
| `fi` | Omat sanat | `fil` | Sariling Salita |
| `fr` | Vos mots | `hr` | Vlastite riječi |
| `id` | Kata Sendiri | | |

En uzunu Türkçe (17) ve Yunanca (16) — ikisi de sınırın altında ama mod kartında
iki satıra düşecek, tasarım buna hazır olmalı.

> Tüm bu isimler native konuşur gözden geçirmesinden geçmeli. Özellikle
> `fil` (Pinoy Henyo / Halo-halo), `ms` (Lakonan Bisu), `be` (Кракадзіл) ve
> `nl` (Hints) maddeleri kültürel iddia içeriyor; yanlışsa etkisi ters olur.
> Bu 4 dil için doğrulama yapılmadan yayına girmeyecek.

### 3.2 Deste isimleri ve içeriği

Aynı ilke destelere de uygulanır. `05-desteler-ve-kategoriler.md` §2'de tanımlanan
`"localize": "adapt" | "literal"` alanı bunu yönetir.

| Deste | `literal` (çevrilir) | `adapt` (uyarlanır) |
|---|---|---|
| Hayvanlar, Meslekler, Duygular, Renkler, Vücut, Uzay | ✓ | |
| Ünlüler | | ✓ Her ülkenin kendi ünlüleri. Türkiye'de Cem Yılmaz, Rusya'da başka isimler |
| Şarkıcılar & Gruplar | | ✓ Yerel müzik sahnesi ağırlıklı, %30 global |
| Markalar | | ✓ Yerel zincirler ve marketler eklenir |
| Yemekler | | ✓ Türkçe'de mantı, İtalyanca'da farklı bir set |
| Diziler / Netflix | | ✓ Yerel yapımlar + global Netflix içeriği |
| Spor | | ✓ **Deste adı bile değişir:** `football` destesi `en-US` için "Soccer", diğer yerlerde "Football" |
| Tarihi Kişiler | | ✓ Ulusal tarih figürleri eklenir |
| Şehirler | | ✓ Yerel şehirler öne alınır |
| Peri Masalları | | ✓ Yerel halk masalları (Keloğlan, Nasreddin Hoca) |

Uyarlama kuralı: `adapt` işaretli destelerde kartın `k` anahtarı sabit kalır ama
`t` sözlüğündeki değer **farklı bir kişi/şey** olabilir. Örnek:

```json
{ "k": "celeb_comedian_01",
  "t": { "en": "Kevin Hart", "tr": "Cem Yılmaz", "ru": "Иван Ургант", "de": "Otto Waalkes" } }
```

Bu, klasik çeviri araçlarıyla yapılamayan bir iş; her `adapt` destesi için dil
başına ayrı bir üretim turu gerekiyor. 92 destenin ~30'u `adapt`, gerisi `literal`.
Plan: `literal` desteler tek seferde üretilir, `adapt` desteler pazar önceliğine
göre sıralanır (`en`, `tr`, `de`, `es`, `ru`, `fr` önce; kalan diller ilk sürümde
İngilizce/global set ile çıkabilir ve sonraki güncellemelerde yerelleşir).

### 3.3 Uygulama adı ve ASO (App Store araması)

Bu, mod isimleriyle aynı meselenin en para getiren tarafı: **kullanıcı bu oyunu
App Store'da kendi dilindeki adıyla arıyor.** "Charades" kelimesini arayan Rus
kullanıcı yok; "Крокодил" arayan çok.

App Store Connect'te her locale için ayrı **alt başlık (subtitle)** ve
**anahtar kelime** alanı var. Uygulama adı marka olarak "Charades" kalır, alt
başlık yerelleşir:

| Locale | Aranan asıl kelime | Alt başlık önerisi |
|---|---|---|
| `en` | charades, heads up | Party game for friends |
| `tr` | sessiz sinema, tabu | Sessiz Sinema Parti Oyunu |
| `ru` | крокодил, шляпа | Крокодил — игра для компании |
| `uk` | крокодил | Крокодил — гра для компанії |
| `pl` | kalambury | Kalambury — gra imprezowa |
| `nl` | hints | Hints — spel voor groepen |
| `de` | pantomime, scharade | Pantomime-Partyspiel |
| `fr` | mimes, jeu de mime | Les Mimes — jeu de soirée |
| `es` | mímica | Mímica — juego de fiesta |
| `it` | mimo | Mimo — gioco di gruppo |
| `pt` | mímica | Mímica — jogo de festa |
| `cs` | šarády | Šarády — párty hra |
| `fi` | pantomiimi | Pantomiimi-peli porukalle |
| `sv` / `da` / `nb` | charader | Charader — partyspel |
| `el` | παντομίμα | Παντομίμα — παιχνίδι πάρτι |
| `ar` | تمثيل صامت | لعبة جماعية ممتعة |

Bu tablo yayın öncesi ASO araştırmasıyla (App Store arama hacmi verisi)
kesinleştirilecek; buradaki liste başlangıç hipotezi.

### 3.4 Yerelleştirme kontrol listesi (yayın öncesi)

Her dil için tek tek işaretlenecek:

- [ ] 6 mod adı native onaylı ve ≤18 karakter
- [ ] 92 deste adı ≤22 karakter, kart üzerinde 2 satırda sığıyor
- [ ] `adapt` destelerinde en az %60 yerel içerik var
- [ ] Onboarding 3 adımının metni ekranda taşmıyor
- [ ] Paywall başlığı ve iki satır özeti taşmıyor (Almanca en riskli; fayda
      listesi kaldırıldı, § `03` §2)
- [ ] Paywall plan kartlarında plan adı ve alt metin tek satırda kalıyor
- [ ] Plural formları doğru (`ru`, `uk`, `pl`, `hr`, `cs` için `.few` dahil)
- [ ] Sayı ve süre formatı locale'e uygun (`01:00` ayırıcısı)
- [ ] Arapça'da tüm ekranlar RTL'de doğru, display fontu Rubik'e düşüyor
- [ ] **Yunanca'da fontlar Fira Sans Condensed / EB Garamond / Fira Sans'a düşüyor**
      — Oswald, Playfair ve Rubik'te Yunan glifi yok (§ `01` §2)
- [ ] **Eksik glif taraması geçti** — her locale için örnek dize seçilen fontta
      gerçekten çiziliyor (`CTFontGetGlyphsForCharacters` testi, CI'da otomatik)
- [ ] App Store alt başlığı ve anahtar kelimeleri girildi
