# 10 — Kodlama Planı: AI'a Verilecek İş Bölümlemesi

§ `07` §8'de bir geliştirme sırası var ama o **insan ekibi için gün tahmini
tablosu**. Bir AI'a doğrudan verilince iki yerde tıkanıyor:

1. **Sınır durumları sonda toplanmış.** § `07` §8'in 17. satırı ("kesinti ve
   sınır durumları, 11 gün") tek kalem hâlinde listenin sonunda duruyor. Ama
   içindeki "yön katmanı" oyun ekranının **temeli** — sonradan eklenemez.
   § `09` §12 bunu kendisi söylüyor: "sınır durumları sonradan eklenince
   mimariye yamayla giriyor, baştan bilinince faz makinesinin parçası oluyor."
   AI o tabloyu sırayla uygularsa tam olarak uyarılan hatayı yapıyor.
2. **Hangi dokümanı ne zaman okuyacağı yazılmamış.** 10 doküman var; hepsini her
   prompt'a koymak modelin dikkatini dağıtıyor ve "her şeyi birden yaz" eğilimi
   doğuruyor. Her paketin kendi girdi listesi olmalı.

Bu dosya o iki sorunu çözüyor: aynı işi **19 pakete** bölüyor, her paketin
girdi dokümanlarını, üreteceği dosyaları ve kabul kriterini yazıyor.

**Toplam süre değişmedi.** Aşağıdaki paketlerin toplamı 73,5 gün — § `07` §8'deki
~74 gün ile aynı iş. Yeni iş eklenmedi, yalnızca yeniden dağıtıldı. (Yarım günlük
fark § `09` §12'deki yuvarlamadan geliyor.)

---

## 0. Kullanım kuralları

**Bir paket = bir oturum.** Paketi bitirmeden sonrakine geçilmiyor. Her paket
sonunda **derlenen ve çalışan** bir uygulama kalıyor — bu, ara kontrolün tek
güvenilir yolu.

**Her prompt'a daima eklenecek üç şey:**

| Dosya | Neden |
|---|---|
| `00-OZET.md` | Ürünün ne olduğu ve alınmış kararlar |
| `07-teknik-mimari.md` | Klasör yapısı, state yönetimi, faz makinesi, bağımlılıklar |
| `01-tasarim-sistemi.md` §1–§4 | Renk/font token'ları ve komponent anatomisi |

Bunların üstüne o pakete özel bölümler ekleniyor (aşağıdaki tabloda).

**AI'a açıkça söylenecek dört şey:**

1. **Mockup HTML'leri görsel referans, kod kaynağı değil.** `ornek-ekranlar.html`
   ekranın nasıl görünmesi gerektiğini gösteriyor; CSS'i SwiftUI'ya çevirmek
   **yanlış**. Renkler ve ölçüler § `01`'deki token'lardan okunuyor. (HTML'deki
   `--accent-amber` gibi değişkenler zaten o token'ların kopyası.)
2. **`Imposter`'dan taşınacak dosyalar sıfırdan yazılmayacak.** § `07` §9'da
   10 kalemlik liste var; özellikle `Resources/Localization/*.json` 25 dilde
   hazır çeviri getiriyor, yeniden üretmek saatlerce boşa iş.
3. **`teslim/` klasöründeki görseller final asset.** Deste kapakları
   (512×512 RGBA), app ikonu, onboarding illüstrasyonları üretilmiş durumda.
   Yeni görsel üretmeye çalışmayacak.
4. **Bir paketin sınır durumları o paketin içinde.** Tabloda "sınır durumları"
   sütunu var; oradaki maddeler o paket yazılırken ele alınıyor, "sonra
   toparlarız" listesine gitmiyor.

---

## 1. Paket 0 — Proje kurulumu

§ `07` §8'in 1. adımı "proje iskeleti" diye tek satırdı. Sıfırdan başlayan bir
AI için bu yetersiz, o yüzden ayrı paket ve somut:

| Konu | Değer |
|---|---|
| Proje adı / hedef | `Charades` |
| Minimum iOS | 17.0 |
| Swift dili | 6.0 language mode (Imposter'da 5.0 kalmıştı, yeni projede baştan 6) |
| Xcode proje formatı | `objectVersion 77` + **synchronized folders** — dosya eklerken `pbxproj` düzenlemek gerekmiyor |
| Cihaz | Sadece iPhone |
| Renk şeması | `.preferredColorScheme(.dark)`, uygulama genelinde kilitli |
| Yön | `Info.plist`'te portrait **ve** landscape açık; kilit ekran bazında kodla (§ `09` §1). Info.plist'te sadece portrait bırakılırsa oyun ekranı yatay dönemiyor |
| SPM paketleri | `RevenueCat` (sadece `RevenueCat` ürünü), `firebase-ios-sdk` (sadece `FirebaseAnalytics` + `FirebaseRemoteConfig`) |
| Eklenmeyecek | `RevenueCatUI`, `FirebaseFirestore`, `FirebaseMessaging`, `GoogleMobileAds`, `Lottie` — gerekçeleri § `07` §4 |
| Fontlar | Oswald, Playfair Display, Rubik → `Resources/Fonts/` + `Info.plist` `UIAppFonts` |

Klasör iskeleti § `07` §2'deki ağaca göre **boş dosyalarla** kuruluyor. Sebep:
sonraki paketler "dosyayı nereye koyayım" sorusunu sormuyor, yer zaten hazır.

**Kabul kriteri:** uygulama açılıyor, koyu bordo zemin var, ortada Oswald ile
`CHARADES` yazıyor, üç font da yüklenmiş (fallback'e düşmediği ekranda görünüyor),
iki SPM paketi çözülmüş, proje uyarısız derleniyor.

**Süre:** 1 gün.

---

## 2. Paket sırası

Sütunlar: **Girdi** = bu paket için prompt'a eklenecek ek bölümler (§0'daki üç
dosyanın üstüne). **Sınır durumları** = § `09`'dan bu pakete taşınan maddeler.

| # | Paket | Girdi | Sınır durumları | Kabul kriteri | Gün |
|---|---|---|---|---|---|
| **P0** | Proje kurulumu | § `07` tamamı | — | Yukarıda | 1 |
| **P1** | Tema + komponent kütüphanesi | § `01` tamamı, § `08` §5 | — | `AppColors`, `AppFonts`, `VelvetBackground`, `GrainOverlay`, `BulbRow`, `Buttons`, `MarqueeSwitch`, `FilmStripProgress` hazır; bir demo ekranda hepsi görünüyor | 2 |
| **P2** | Veri katmanı | § `05` tamamı, § `09` §6 | Kelime havuzu şeması | `DeckDef`, `DeckCatalog`, `CardBank` (lazy + cache), `CustomDeck` (SwiftData şeması), **3 örnek deste JSON'u** ve CI doğrulama script'i | 1,5 |
| **P3** | Navigasyon kabuğu + ana ekran | § `02` §1, §4 (ekran 4–5) | Boş/hata durumları (§ `02` §6) | Tek `NavigationStack`, tab bar yok; header (VIP + makara + dişli), filtre chip'leri, 2/3 kolon ızgara, deste detayı sheet'i; ızgarada gerçek kapak görselleri | 2,5 |
| **P4** | **Yön katmanı + Klasik oyun döngüsü** | § `04` §1–3, § `07` §5, § `09` §1–3 | **Yön katmanı (2g), kesinti politikası (1,5g)** | `MotionService` (tilt), `LivePhase` faz makinesi, Yatay Çevir → 3-2-1 → oyun kartı → duraklat → tur sonu; `scenePhase`, çağrı, termal, pil kesintileri; **oynanabilir ilk sürüm** | 8,5 |
| **P5** | Diğer tek kişilik modlar | § `04` §1, §2, § `02` §4 (ekran 9) | Kelime havuzu tükenmesi (0,5g) | Mod seçimi sheet'i, Hız Turu, Canlandır (`playability` filtresi dahil), Nasıl Oynanır slider'ı | 3,5 |
| **P6** | Takım Savaşı | § `04` §2, § `09` §5, § `08` §B1–B2 | **Beraberlik, tur sayısı, oyuncu adları (1,5g)** | Takım kurulumu, `teamHandoff` perde arası, maç sonu jeneriği, ani ölüm turu | 5,5 |
| **P7** | Mix | § `05` §Mix | Karışım sınırları (2–8 deste) | Mix kurulumu, karışım önizlemesi, kaydedilmiş karışımlar | 3 |
| **P8** | Custom deste + Kendi Kelimelerin | § `05` §Custom, § `02` §4 (ekran 8, 24) | 3 slot sınırı, min. kelime sayısı | Editör, kapak seçici, toplu yapıştırma, Kelime Sepeti, tur sonunda kaydetme | 5,5 |
| **P9** | Lokalizasyon | § `06` §2–4, § `01` §2 | Font ikamesi, RTL, taşan metin | `LocalizationManager` + plural, 25 dil, dil sheet'i, RTL geçişi, mod/deste adlarının kültürel karşılıkları | 4 |
| **P10** | Para kazanma | § `03` tamamı, § `09` §7 | **Abonelik düşüşü (1,5g), RC varsayılanları + günlük deste (1g)** | RevenueCat, 3 plan, paywall A ve B, gating, günlük rotasyonlu bedava deste, salt-okunur durumlar | 7,5 |
| **P11** | Onboarding | § `03` §1 | İlk açılış + izin sırası | 3 adım sheet, arkada net ızgara, soft prompt'lar | 2 |
| **P12** | Ayarlar | § `06` §1, §3 | Bildirim izni reddi | 15 satır, dil satırı, titreşim/ses/replay anahtarları, abonelik kartı | 2 |
| **P13** | Ses + haptik | § `04` §5, § `01` §4.1 | Sessiz mod, kulaklık | 12 parça ses paketi, `SoundService`, haptik dili tablosu | 2 |
| **P14** | Replay kaydı | § `04` §4.1–4.2, § `09` §4 | Termal koruma, disk dolu, izin reddi | `ReplayRecorder`, tur sonunda oynat + paylaş | 4 |
| **P15** | Film Arşivi | § `04` §4.3–4.4 | Kota, FIFO, sabitlenmiş kayıt | `ReplayStore`, arşiv ekranı, oynatıcıda altyazı + ağır çekim + zaman çizelgesi | 3,5 |
| **P16** | Analytics + flag'ler | § `07` §7, § `03` §5 | — | Firebase sarmalayıcıları, funnel event'leri, Remote Config anahtarları | 2,5 |
| **P17** | Sinematik katman | § `08` tamamı | Reduced Motion | Kademe A tamamı + kademe B; animasyon bütçesi (tur başına ≤ 2,5 sn atlanamaz) | 6 |
| **P18** | Cilalama + App Store | § `01` §7, § `06` §5, § `09` §9 | Kalan küçük düzeltmeler (2g) | Erişilebilirlik denetimi, Dynamic Type, kontrast, ekran görüntüleri, ASO metinleri | 7 |

**Toplam: 73,5 gün.**

---

## 3. Neden bu sıra

**P4 neden bu kadar büyük (8,5 gün) ve neden 4. sırada?** Çünkü uygulamanın
kalbi orada: tilt mekaniği, faz makinesi, yön yönetimi ve kesinti politikası.
Bu paket bitince **oynanabilir bir oyun** var — sadece Klasik mod, tek deste
ama gerçekten oynanıyor. Bundan sonraki her paket bu çalışan çekirdeğin üstüne
ekleme yapıyor. Erken oynanabilirlik, yanlış varsayımları en ucuz yerde
yakalamanın tek yolu: tilt eşiği yanlışsa bunu 4. pakette öğrenmek, 14. pakette
öğrenmekten çok daha iyi.

**Lokalizasyon neden 9. sırada, daha erken değil?** Metinler baştan
`LocalizationManager` üzerinden okunuyor (P1'den itibaren anahtar kullanılıyor),
ama 25 dilin doldurulması ekranlar oturduktan sonra. Ekran tasarımı değişirken
25 dili senkron tutmak boşa iş. Buna karşılık **anahtar kullanımı ertelenmiyor** —
sabit string yazılıp sonra toplanması en pahalı yol.

**Para kazanma neden 10. sırada?** Gating'in çalışması için gating'lenecek
şeylerin var olması gerekiyor: Takım Savaşı, Mix, Custom deste, Canlandır. Bunlar
P5–P8'de bitiyor. Paywall'ı daha önce yazmak, hangi özelliğin kilitli olacağını
bilmeden kilit yazmak olur.

**Replay neden 14. sırada?** § `07` §8'in gerekçesi geçerli: kamera oturumu ile
oyun ekranının aynı anda çalışması ancak oyun ekranı stabil olduğunda güvenle
test edilebilir. Ayarlardaki anahtar P12'de hazırlanıyor, P14'te bağlanıyor.

**Sinematik katman neden sonda?** § `08` §0'daki bütçe kuralı: animasyonlar
mevcut beklemeleri süslüyor, yeni bekleme yaratmıyor. Süslenecek beklemelerin
önce var olması gerekiyor. Tersi sırada animasyon, akışı belirlemeye başlıyor.

---

## 4. İçerik üretimi ayrı bir yol

92 destenin kelime listeleri **kodlama işi değil** ve AI'ın kod oturumlarını
bloklamıyor. § `09` §6'ya göre ~33 gün ayrı kaynak.

**Kodlama bu yüzden 3 örnek deste ile başlıyor** (P2). Seçim önemli: biri
ücretsiz deste (`Parti Başlangıcı`), biri premium (`Film Klasikleri`), biri
`describe` oynanabilirliğinde olan (`Dünya Şehirleri`). Böylece gating,
`playability` filtresi ve kart havuzu mantığı üç desteyle test edilebiliyor —
92'sini beklemeye gerek yok.

Katalog metadata'sı (`DeckCatalog.swift`, 92 `DeckDef`) ise **kod**, P2'de
yazılıyor. Metadata ile JSON içeriği arasındaki tutarlılığı CI script'i
denetliyor: metadata'da olup JSON'u olmayan deste derlemeyi kırıyor. Bu yüzden
P2'de yazılan script, içerik akarken tek koruma.

---

## 5. İlk prompt şablonu

P0 için, olduğu gibi kopyalanabilir:

```
Charades adında bir iOS uygulaması yazacağız. Tüm ürün ve tasarım kararları
ekteki dökümanlarda; hiçbir karar yeniden verilmeyecek, dökümanda yazan neyse o
uygulanacak. Bir karar dökümanda yoksa bana sor, kendin varsayma.

Bu oturumda sadece PAKET 0 yapılacak: proje kurulumu.
Kapsam ve kabul kriteri: 10-kodlama-plani.md §1.
Mimari kararlar: 07-teknik-mimari.md §1, §2, §4.
Tema token'ları: 01-tasarim-sistemi.md §1, §2.

Kurallar:
- Paket 0 dışına çıkma. Ekran kodu yazma, model yazma, servis yazma.
- Klasör iskeletini 07 §2'deki ağaca göre boş dosyalarla kur.
- ornek-ekranlar.html sadece görsel referans; CSS'i SwiftUI'ya çevirmeye
  çalışma, renkleri 01 §1'deki token tablosundan al.
- Imposter projesinden taşınacak dosyalar 07 §9'da listeli; onları bu pakette
  kopyalama, sırası gelince yapacağız.
- Bitirince kabul kriterini tek tek doğrula ve hangi maddeyi nasıl
  karşıladığını yaz.

Ekli dökümanlar: 00-OZET.md, 07-teknik-mimari.md, 01-tasarim-sistemi.md
```

Sonraki paketlerde ilk paragraf aynı kalıyor, sadece paket numarası, girdi
listesi ve "kapsam dışına çıkma" cümlesi değişiyor.

**Neden "kapsam dışına çıkma" her prompt'ta var:** bu dokümanlar bütün ürünü
anlatıyor ve modelin doğal eğilimi tamamını birden yazmaya çalışmak. Tek
pakette kalmak, her adımda çalışan bir uygulama bırakma kuralının önkoşulu.

**Neden "bir karar dökümanda yoksa sor":** dokümanlar kararların gerekçelerini
de taşıyor (neden tab bar yok, neden neon yeşil yok, neden aylık kart var).
Model boşluğu kendi varsayımıyla doldurursa gerekçe zinciri kopuyor ve tutarsızlık
sonradan fark ediliyor.

---

## 6. Paket bitiş kontrol listesi

Her paket sonunda, sonrakine geçmeden:

- [ ] Uygulama uyarısız derleniyor ve cihazda açılıyor
- [ ] Paketin kabul kriteri maddeleri tek tek doğrulandı
- [ ] Yeni metin varsa lokalizasyon anahtarı üzerinden yazıldı (sabit string yok)
- [ ] Yeni renk/font varsa § `01` token'ından geldi (hex sabiti gömülmedi)
- [ ] Paketin sınır durumları sütunundaki maddeler ele alındı
- [ ] Önceki paketlerin çalışan davranışı bozulmadı
