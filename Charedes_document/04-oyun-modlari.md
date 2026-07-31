# 04 — Oyun Modları ve Mekanikler

## 1. Mod listesi

5 mod. Her modun tek bir "neden bu var" cümlesi olmalı; olmayan mod eklenmiyor.

| Mod | id | Kim tutuyor | Süre | Skor | Ücretsiz |
|---|---|---|---|---|---|
| **Klasik** | `classic` | Tahmin eden (alında) | 60s (ayarlanabilir) | Doğru sayısı | ✓ |
| **Takım Savaşı** | `teams` | Sırayla takım üyeleri | Takım başına 60s × N tur | Takım puanı | Premium |
| **Canlandır** | `actOut` | Canlandıran (ekranı sadece o görür) | 90s | Doğru sayısı | Premium |
| **Hız Turu** | `rapid` | Tahmin eden | 30s, kelime başına 5s limit | Doğru sayısı × 2 | Premium |
| **Mix** | `mix` | Klasik ile aynı | 60s | Doğru sayısı | Premium |

### Klasik (`classic`)
Referans mekanik. Telefon alında, arkadaşlar canlandırır, tilt ile cevaplanır.
Tek oyuncu tahmin eder, tur sonunda skor. Ücretsiz kullanıcının gördüğü tek mod —
oyunun ne olduğunu tam olarak öğretiyor.

### Takım Savaşı (`teams`)
2–4 takım, takım başına 1–8 kişi. Her takım sırayla tur oynar, tur sayısı
ayarlanabilir (varsayılan takım başına 3 tur). Aradaki geçiş ekranı: "SIRA KIRMIZI
TAKIMDA — telefonu Ayşe'ye ver". Maç sonunda marquee kutlama ekranı + kazanan
takımın adı ampullerle yazılır.
Neden var: App Store yorumlarında en çok istenen özellik ve rakiplerin çoğunda yok.

### Canlandır (`actOut`)
Roller ters: telefonu **canlandıran** kişi tutar, kelimeyi sadece o görür,
karşısındakiler tahmin eder. Tilt burada "tahmin edildi" (öne) / "geç" (arkaya)
anlamına gelir. Ekran içeriği tahmin edenlere görünmemeli, bu yüzden kelime
küçük ve tek satır, ekran parlaklığı düşürülür.
Neden var: klasik sessiz sinemanın gerçek hâli bu; birçok kullanıcı bunu arıyor.

Bu modda **deste uyumluluğu kritik.** "Periyodik Tablo" veya "Başkentler" gibi
desteler vücut diliyle canlandırılamaz; kullanıcı seçerse kötü bir tur yaşıyor
ve suçu uygulamaya atıyor. Bu yüzden her destenin `playability` alanı var
(`mime` / `describe` / `both`, § `05` §1). `actOut` modu seçiliyken `describe`
desteler ızgarada soluklaşır ve üstünde `ANLATMA DESTESİ` etiketi çıkar —
seçilebilir kalır ama kullanıcı ne aldığını bilir.

### Hız Turu (`rapid`)
30 saniye, kelime başına 5 saniye limit. Süre dolarsa otomatik PAS ve sonraki
kelime. Doğrular 2 puan. Ekranda kelimenin altında ince bir sayaç çubuğu erir.
Neden var: kısa oturum ihtiyacı + tekrar oynama motivasyonu (rekor kırma).

### Mix (`mix`)
Ayrı bir mod olarak duruyor çünkü kurulum ekranı farklı: 2+ deste seçilir,
karışım oranı gösterilir. Oynanış Klasik ile birebir aynı. Detay § `05`.

### Mod özellik matrisi (kodda computed property olarak)

| Mod | `usesTilt` | `usesTeams` | `perWordLimit` | `screenVisibleToGuesser` | `scoreMultiplier` |
|---|---|---|---|---|---|
| `classic` | ✓ | ✗ | — | ✓ | 1 |
| `teams` | ✓ | ✓ | — | ✓ | 1 |
| `actOut` | ✓ | ✗ | — | ✗ | 1 |
| `rapid` | ✓ | ✗ | 5s | ✓ | 2 |
| `mix` | ✓ | ✗ | — | ✓ | 1 |

Yeni mod eklemek = enum'a bir case + bu matriste bir satır. Ekran kodu
değişmiyor. Lokalizasyon anahtarları otomatik türetilir:
`mode.\(id).title`, `mode.\(id).subtitle`, `mode.\(id).rule` ve ikon
`mode_icon_\(id)`.

### Mod isimleri kültürel olarak yerelleştirilir

**Yukarıdaki Türkçe isimler birer `id` değil, sadece Türkçe karşılıklar.** Mod
isimleri 25 dile **birebir çevrilmeyecek**, her dilde o kültürün bu oyunu tanıdığı
isim kullanılacak. Bu, ürünün "yerli hissettirmesi" açısından belki en yüksek
etkili lokalizasyon kararı.

En net örnek `actOut` modu. İngilizce "Act It Out" ifadesini kelime kelime
çevirmek her dilde tuhaf duruyor; oysa bu oyunun her ülkede zaten bir adı var:

| Dil | Mod adı | Bu isim nereden geliyor |
|---|---|---|
| Türkçe | **Sessiz Sinema** | Türkiye'de oyunun yerleşik adı |
| Rusça | **Крокодил** | Rusya'da bu oyun "Krokodil" diye bilinir, "pantomim" denmez |
| Ukraynaca | **Крокодил** | Aynı gelenek |
| Lehçe | **Kalambury** | Polonya'da charades'in kendi adı |
| Hollandaca | **Hints** | Hollanda'da onlarca yıl yayınlanan TV programından gelen yerleşik isim |
| Fransızca | **Les Mimes** | "Le jeu des mimes" |
| İtalyanca | **Mimo** | |
| İspanyolca | **Mímica** | |
| Almanca | **Pantomime** | "Scharade" de kullanılıyor ama Pantomime daha yaygın |
| Fince | **Pantomiimi** | |
| İngilizce | **Act It Out** | |

Bir Rus kullanıcı listede "Крокодил" görürse "bu uygulama bizi biliyor" diyor;
"Пантомима" görürse çeviri kokusu alıyor. Aynı fark her dilde geçerli.

**Tüm modların 25 dildeki isim tabloları § `06-ayarlar-ve-lokalizasyon.md` §3'te.**

Uygulama kuralları:
- Mod kartındaki başlık için **maksimum 18 karakter.** Bazı dillerde doğal
  karşılık uzun oluyor (Lehçe `Błyskawiczna runda` = 18, tam sınırda); build script
  bu sınırı aşan `mode.*.title` anahtarlarını raporlar. Malayca'da `Pertempuran
  Pasukan` 19 karakterle sınırı aşıyordu, `Perang Pasukan` olarak kısaltıldı.
- Mod adı ile alt açıklama (`subtitle`) birlikte anlam taşımalı. Yerelleştirilmiş
  ad mekaniği tam anlatmıyorsa açıklama telafi eder: Hollandaca `Hints` tek başına
  "canlandırma" demiyor, alt satır "Speel het uit, laat ze raden" ile netleşiyor.
- `id` değerleri (`actOut`, `rapid`…) **asla değişmez.** Analytics, JSON anahtarları
  ve asset isimleri bunlara bağlı. Yerelleştirme sadece görünen metinde.

---

## 2. Tilt mekaniği (en kritik teknik parça)

`Imposter` projesinde CoreMotion hiç kullanılmamış, bu kısım sıfırdan yazılacak.
Yanlış yapıldığında oyunun tamamı hatalı hissettirir, o yüzden detaylandırıyorum.

### Kurulum
```
CMMotionManager
  deviceMotionUpdateInterval = 1/30   // 30 Hz yeterli, 60 Hz pil yakar
  startDeviceMotionUpdates(using: .xArbitraryZVertical)
```
Landscape'te alna konmuş telefonda anlamlı eksen **`attitude.roll`** (cihazın
uzun ekseni yatay olduğu için). İşaret cihazın hangi tarafa yatırıldığına göre
değişir (`landscapeLeft` ↔ `landscapeRight`).

> **Kritik:** İşaret **kalibrasyon anında bir kez** okunup tur boyunca sabitlenir.
> Her ölçümde `UIDevice.current.orientation` sorgulanmaz — alna konmuş telefonda
> bu değer `.faceUp`, `.portrait` veya `.unknown` dönebilir, hatta tur ortasında
> `landscapeLeft` ↔ `landscapeRight` arasında salınabilir. İşaret tur ortasında
> dönerse **öne eğmek PAS, arkaya eğmek DOĞRU** olur; yani oyunun tek mekaniği
> tersine döner ve kullanıcı bunu "uygulama bozuk" olarak yaşar. `sign` bir kez
> hesaplanıp `LiveGame` içinde saklanacak.

### Eşik ve durum makinesi

| Durum | Koşul | Aksiyon |
|---|---|---|
| `neutral` | \|açı\| < 25° | Bekle |
| `armedCorrect` | açı > 40° (öne eğim) | DOĞRU tetikle |
| `armedSkip` | açı < −40° (arkaya eğim) | PAS tetikle |
| `cooldown` | tetiklendikten sonra | \|açı\| < 20°'ye dönene kadar yeni tetik yok |

Kritik detaylar:
- **Histerezis zorunlu:** tetikleme 40°, sıfırlama 20°. Tek eşik kullanılırsa
  telefon eşik sınırında titrerken 5 kelime birden geçiyor.
- **Cooldown 400ms** + "nötre dönme" koşulu birlikte. İkisinden biri eksikse
  hatalı çift tetikleme oluyor.
- **Kalibrasyon:** geri sayım **sırasında**, cihaz sabitlendiği anda `baseline`
  alınır. Herkesin alnı ve tutuş açısı farklı; sabit sıfır noktası kullanmak bazı
  kullanıcılarda oyunu oynanamaz yapıyor.
  **Sabitlik kontrolü zorunlu:** son 10 ölçümün varyansı bir eşiğin altına
  düşmeden baseline alınmaz. Önceki taslak "geri sayım biterken o anki açı"
  diyordu — ama geri sayımın son anı tam olarak kullanıcının telefonu alnına
  *götürdüğü* an, yani hareket hâlindeki bir açı. Yanlış baseline = tüm tur boyunca
  kaymış eşikler. Geri sayım bitene kadar sabitlik sağlanamazsa son ölçüm
  kullanılır ve tur içi yeniden kalibrasyon devreye girer (aşağıda).
- **Tur içi yeniden kalibrasyon:** 8 saniye boyunca hiç tetik gelmezse ve açı
  nötr bandın dışında sabit duruyorsa baseline sessizce güncellenir. Kullanıcı
  telefonu tur ortasında kaydırdığında oyunun kilitlenmesini engelliyor.
- **Yumuşatma:** son 3 ölçümün ortalaması (basit hareketli ortalama). Ham veri
  el titremesiyle gürültülü.
- **Cevap anında motion güncellemesi durur**, animasyon bitince yeniden başlar.
  Aksi hâlde animasyon sırasında ikinci tetik geliyor.
- **Dokunmatik yedek:** ekranın sol yarısı PAS, sağ yarısı DOĞRU. Hem erişilebilirlik
  için hem motion sensörü sorunlu cihazlar için hem de kullanıcı isterse ayarlardan
  kalıcı seçebilir.

### Geri bildirim (üç kanal birlikte)
| Kanal | DOĞRU | PAS |
|---|---|---|
| Görsel | Tam ekran `stateCorrect` + eğik `DOĞRU` mührü | Tam ekran `stateSkip` + `PAS` mührü |
| Haptic | `.success` notification feedback | `.warning` |
| Ses | Retro tiyatro zili "ding" | Projektör "klak" |

Süre 0.45s, sonra sonraki kelime yukarıdan düşer (film karesinin ilerlemesi gibi).

---

## 3. Tur akışı

```
Mod seçimi → (Takım kurulumu) → Tur ön ayar → Nasıl oynanır (ilk kez)
  → Yatay çevir → Geri sayım (3-2-1) → OYUN → Tur sonu skor
  → (Replay) → sonraki tur veya maç sonu
```

### Geri sayım
3 saniye, Akademi geri sayımı görselinde (§ `08` A1). Bu sürede: motion baseline
kalibrasyonu, kelime havuzu hazırlanması, replay kaydının başlatılması yapılır.
Yani teknik hazırlığı gizleyen bir ekran.

> **Bu ekran atlanamaz** — § `08` §0'daki "tüm animasyonlar dokunuşla atlanabilir"
> kuralının tek istisnası. Sebep: geri sayım atlanırsa baseline alınmamış, kelime
> havuzu hazırlanmamış ve kayıt başlamamış olur; tur bozuk başlar. Dokunmak
> geri sayımı **kısaltmaz**, sadece kalan süreyi 1 saniyeye indirir ve o 1 saniye
> hazırlığın tamamlanması için ayrılır. Sabırsız kullanıcı (parti ortamında
> herkes) tam olarak bu ekrana dokunacak kişi olduğu için bu ayrım önemli.

### Kelime havuzu
Tur başında seçili destelerin kelimeleri karıştırılır, `Set<String>` ile oturum
içi tekrar engellenir. **De-duplication İngilizce anahtar üzerinden** yapılır —
kullanıcı ortada dil değiştirse bile tekrar kontrolü bozulmaz (`Imposter/Models/WordBank.swift`
içindeki `englishKey` yaklaşımı).

### Süre
- Ayarlanabilir: 30s – 180s, 15s adımlarla. Varsayılan **60s**.
- Hız Turu'nda sabit 30s (ayar kilitli, "Hız Turu'nda süre sabittir" notu).
- Son 10 saniye: sayaç `stateWarning`e döner, her saniye hafif haptic + tik sesi.
- 0'da: ağır haptic, zil sesi, otomatik Tur Sonu ekranına geçiş.

### Duraklat
İki parmakla dokunma veya üstten aşağı sürükleme. Overlay: `DEVAM ET` /
`TURU YENİDEN BAŞLAT` / `NASIL OYNANIR?` / `ÇIKIŞ`. Çıkışta onay sorulur
(kazara çıkış tur sonuçlarını yok eder).

### Skorlama
| Olay | Puan |
|---|---|
| Doğru | +1 (Hız Turu'nda +2) |
| Pas | 0 |
| Süre dolduğunda ekranda kalan kelime | Sayılmaz |
Ceza puanı yok — parti oyununda negatif puan eğlenceyi kırıyor.
Tur Sonu ekranında yanlış işaretlenmiş kelime dokunarak düzeltilebilir, puan
anında güncellenir.

---

## 4. Replay kaydı (v1'de — onaylandı)

Tur boyunca ön kameradan sessiz video kaydı, tur sonunda oynatma/paylaşma.
Viral paylaşım için en güçlü özellik, ama hafife alınmayacak bir iş.

### 4.1 Kayıt

- `AVCaptureSession` + `AVCaptureMovieFileOutput`, ön kamera, 720p, 30fps, ses yok.
- Kamera izni **ilk kullanımda** istenir, ayarlar satırında açıklaması olur.
- Kayıt geri sayımda başlar, tur bitiminde durur.
- Doğru/pas anları zaman damgası olarak kaydedilir → oynatıcıda zaman çizelgesi
  işaretleri ve "en iyi anlar" otomatik kesiti buradan üretiliyor.
- Oyun ekranı çıktısı ile kamera görüntüsü birleştirilmiş dışa aktarım (kelime +
  yüz aynı karede) → `AVMutableComposition`. Bu kısım tek başına 3-4 gün iş.
- Ayarlarda varsayılan **kapalı** (gizlilik + pil). Premium özelliği.
- Landscape oyun ekranında kamera önizlemesi **gösterilmez** — kullanıcı kendini
  görmesin, doğal davransın. Sadece küçük bir kırmızı kayıt noktası.
- Pil ve ısınma: 60 saniyelik turda 720p kayıt kabul edilebilir; ama arka arkaya
  10 tur oynanan takım maçında ısınma olabilir. Termal durum izlenecek
  (`ProcessInfo.thermalState`), `.serious` seviyesinde kayıt otomatik durur ve
  kullanıcıya bilgi verilir.

### 4.2 Depolama ve kota

İlk taslakta kayıtlar `tmp` klasörüne yazılıp uygulama kapanınca silinecekti.
**Bu karar değişti** — çünkü kamera izni metninde "sonradan izleyebilmeniz için"
diyorken kaydı uygulama kapanınca silmek hem kullanıcıya verilen sözü tutmuyor
hem de App Review'da izin metni ile gerçek kullanımın uyuşmaması olarak
işaretlenebiliyor.

| Konu | Karar |
|---|---|
| Konum | `Library/Application Support/Replays/` — kalıcı |
| iCloud yedeği | **Hariç** (`isExcludedFromBackupKey = true`). Video yedeği kullanıcının iCloud kotasını yer, şikâyet konusu olur |
| Kota | **En fazla 20 kayıt veya 500 MB** — hangisi önce dolarsa. FIFO: en eskisi silinir |
| Otomatik temizlik | 30 günden eski kayıtlar silinir. Ayarlanabilir: `7 GÜN` / `30 GÜN` / `SÜRESİZ` |
| Sabitleme | Kullanıcı bir kaydı **sabitlerse** (`📌`) FIFO ve otomatik temizlikten muaf olur |
| Şeffaflık | Ayarlarda toplam boyut görünür + "Arşivi Temizle" |

Kotanın olmaması bu tür özelliklerin klasik batış sebebi: birkaç hafta sonra
uygulama 4 GB yer kaplıyor, kullanıcı Ayarlar → Depolama'da görüyor ve siliyor.
20 kayıt / 500 MB sınırı bunu baştan engelliyor.

### 4.3 Film Arşivi (ekran 22)

Kayıtları sonradan izleyebileceğin ekran. Tema ile birebir oturuyor: her **maç**
bir film, her **tur** bir sahne.

```
┌──────────────────────────────────┐
│  ‹        FİLM ARŞİVİ    DÜZENLE │
│                                  │
│  ▸ 14 makara · 312 MB · 30 gün   │  ← özet şeridi
│                                  │
│  HAYVANLAR · 24 TEMMUZ           │  ← maç grubu
│  ┌──────┐ ┌──────┐ ┌──────┐      │
│  │SAHNE │ │SAHNE │ │SAHNE │  →   │  ← yatay kaydırma
│  │  01  │ │  02📌│ │  03  │      │
│  │ 9 ✓  │ │ 6 ✓  │ │ 11 ✓ │      │
│  └──────┘ └──────┘ └──────┘      │
│                                  │
│  90'LAR TÜRKİYE · 22 TEMMUZ      │
│  ┌──────┐ ┌──────┐               │
│  ...                             │
└──────────────────────────────────┘
```

- Kart görseli: videonun ortasından alınan kare, üzerine bilet tipografisiyle
  `SAHNE 03`, süre ve o turdaki doğru sayısı. Sabitlenmişse köşede iğne ikonu.
- Uzun basış → `Oynat` · `Photos'a Kaydet` · `Paylaş` · `Sabitle` · `Sil`.
- `DÜZENLE` ile çoklu seçim → toplu silme veya toplu kaydetme.
- Arşiv boşsa: makara illüstrasyonu + "Henüz makara yok. Replay kaydını açıp bir
  tur oyna." + ayarlara kısayol.
- En üstte bir kez görünen ve kapatılabilen bilgi satırı: **"Kayıtlar yalnızca bu
  cihazda. Hiçbir yere gönderilmiyor."**

**Giriş noktaları** (üçü birlikte, çünkü tek başına hiçbiri yeterli değil):

1. Ana ekran header'ında dişlinin solunda küçük **makara ikonu** — sadece arşivde
   en az 1 kayıt varsa görünür, üzerinde adet badge'i. Header'ı gereksiz
   kalabalıklaştırmamak için koşullu.
2. Ayarlar → Grup 2'de `Film Arşivi ›` satırı — kalıcı ve tahmin edilebilir yol.
3. Maç sonu jenerik ekranında `ARŞİVE GİT` bağlantısı — kaydın var olduğunu tam
   ilgili olduğu anda öğreniyor.

### 4.4 Replay Oynatıcı (ekran 18/23)

Tur sonunda otomatik açılan oynatıcı ile arşivden açılan oynatıcı **aynı ekran**;
sadece giriş noktası farklı.

| Öğe | Detay |
|---|---|
| Zaman çizelgesi işaretleri | Doğru anları yeşil, pas anları kırmızı çentik. Dokununca o ana atlar. Bu veri zaten kaydediliyor, sadece görselleştiriliyor |
| **Altyazı** | Oynatma sırasında o anda ekranda olan kelime, altta film altyazısı gibi görünür + `DOĞRU`/`PAS` damgası. Zaman damgalarından türetilir |
| **Ağır çekim** | `1x` / `0.5x` segmenti. Komik anların yarısı ağır çekimde ortaya çıkıyor; bu tek kontrol paylaşım oranını gözle görülür artırıyor |
| En iyi anlar | ~15 saniyelik otomatik kesit, doğru damgalarının yoğunlaştığı bölgelerden |
| Aksiyonlar | `Paylaş` · `Photos'a Kaydet` · `Sabitle` · `Sil` |
| Çerçeve | Video, sprocket delikli film şeridi çerçevesi içinde oynar (§ `08`) |

Altyazı ve ağır çekim, replay'i "kendimizi izliyoruz" seviyesinden "bunu gruba
atacağım" seviyesine taşıyan iki detay. İkisi de mevcut veriden üretiliyor, yeni
bir kayıt maliyeti yok.

### 4.5 Gizlilik

Bu özellik masadaki **başka insanların** yüzünü kaydediyor; dolayısıyla tek
kullanıcıdan izin almak yeterli değil.

- Replay kaydı ilk kez açılırken, kamera izninden **önce** bir bilgi ekranı:
  "Bu kayıtlar masadaki herkesi çekiyor. Açmadan önce oyunculara haber ver."
  Onay kutusu yok, sadece bilgilendirme — ama bu satır etik olarak gerekli ve
  App Review'da da olumlu karşılanıyor.
- Kayıtlar sunucuya **hiç** gönderilmiyor; paylaşım tamamen sistem paylaşım
  sayfası üzerinden, kullanıcının seçtiği yere.
- Ayarlarda `Çıkışta kayıtları sil` anahtarı — eski `tmp` davranışını isteyenler
  için (varsayılan kapalı).

`Info.plist`: `NSCameraUsageDescription` = "Tur sırasında eğlenceli anlarınızı
kaydedip sonradan Film Arşivi'nden izleyebilmeniz için kameraya erişim gerekiyor.
Kayıtlar yalnızca cihazınızda kalır, hiçbir yere gönderilmez."

---

## 5. Ses tasarımı (retro paket)

12 parça, hepsi kısa (<1.5s), `.caf` veya `.m4a`. Temanın yarısı ses ile kuruluyor.

| Dosya | Ne zaman |
|---|---|
| `sfx_curtain_open` | Splash / uygulama açılışı |
| `sfx_bulb_flicker` | Logo ampulleri yanarken |
| `sfx_projector_loop` | Oyun ekranı boyunca çok kısık döngü (opsiyonel) |
| `sfx_countdown_tick` | 3-2-1 |
| `sfx_correct_bell` | DOĞRU — tiyatro zili |
| `sfx_skip_clack` | PAS — projektör klak |
| `sfx_tick_warning` | Son 10 saniye |
| `sfx_time_up` | Süre bitti — uzun zil |
| `sfx_card_slide` | Kelime geçişi — kağıt sürtünmesi |
| `sfx_button_tap` | Buton — mekanik tuş |
| `sfx_win_fanfare` | Maç sonu — kısa orkestra |
| `sfx_ticket_stamp` | Satın alma başarılı — damga |

`AVAudioSession` kategorisi `.ambient` + `mixWithOthers` → kullanıcının müziğini
kesmez (parti ortamında müzik açık olur, bu önemli). Sessiz mod anahtarına saygı
gösterilir. Ayarlardan tek anahtarla kapatılabilir.
