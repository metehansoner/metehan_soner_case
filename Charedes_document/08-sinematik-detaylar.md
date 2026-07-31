# 08 — Sinematik Detaylar

Tema kararı (`Grand Marquee`) sadece renk ve doku değil; oyunun **ritmine** de
sinema dili katıyor. Bu dosya o katmanın envanteri.

Canlı demo: `sinematik-ozellikler.html` (tarayıcıda açılabilir, animasyonlar
tekrar oynatılabilir).

---

## 0. Önce sınır: animasyon bütçesi

Bu bölüme geçmeden önce en önemli kural. **Bu bir parti oyunu; masada 5 kişi
bekliyor.** Sinematik geçişler tek başına güzel ama yanlış dozda konursa
uygulamanın en çok şikâyet edilen yanı olur: "başlaması çok uzun sürüyor".

Bu yüzden sert bir bütçe koyuyorum:

| Kural | Değer |
|---|---|
| Tur başına toplam atlanamaz animasyon | **≤ 3.5 saniye** (geri sayım 3s + klaket 0.5s kısa versiyon). Maçın **ilk** turunda klaket tam sürer, toplam 4.4s'e çıkar — bir maçta bir kez kabul edilebilir |
| Tek bir geçişin süresi | ≤ 900 ms |
| Kelime arası geçiş | ≤ 450 ms (mevcut karar) |
| Dokunarak atlanabilir mi? | **Biri hariç hepsi evet.** İstisna: Akademi geri sayımı (A1) — o sürede motion kalibrasyonu, kelime havuzu ve replay kaydı hazırlanıyor, atlanırsa tur bozuk başlar. Dokunmak kalan süreyi 1 saniyeye indirir, sıfırlamaz (§ `04` §3) |
| Oturumda tekrar | Klaket ve jenerik sadece **maçın ilk/son turunda**; her turda değil |
| Reduce Motion açıkken | Tüm bezemeler kapanır, sade kesme (cut) geçişi kalır |
| 3. turdan sonra | Öğretici bezemeler (tilt hatırlatıcısı, klaket detayı) otomatik kısalır |

Somut örnek: Akademi geri sayımı 3 saniye sürüyor ama o 3 saniye **zaten gerekli**
— motion kalibrasyonu, kelime havuzu hazırlığı ve replay kaydının başlaması o
sırada oluyor. Yani teknik bekleme süresini gizliyor, üzerine süre eklemiyor.
Doğru sinematik detay budur: **var olan bir bekleme anını süsler, yeni bekleme
yaratmaz.**

---

## 1. Kademe A — kesin yapılacak (yüksek etki / düşük maliyet)

### A1. Akademi Geri Sayımı (Countdown Leader)

Eski film makaralarının başındaki o meşhur geri sayım: daire, ortasında artı
işareti, dönen süpürge kolu, büyük rakam. Sinemanın en tanınabilir tek görseli.

- Düz "3 · 2 · 1" yerine bu kullanılacak. **Süre aynı (3 saniye), etki katbekat
  fazla.** Bu, § `04` §3'teki geri sayımın görsel karşılığı — ayrı bir ekran değil.
- Yapı: tam ekran krem/koyu zemin, merkezde 2 eşmerkezli daire, artı işareti,
  360°'de 1 saniyede dönen bir sektör (conic gradient), merkezde Oswald ile
  büyük rakam.
- Her rakamda: hafif haptic + `sfx_countdown_tick`. Sonunda projektör titremesi.
- SwiftUI: `Canvas` + `TimelineView(.animation)` veya `Circle().trim(from:to:)` +
  `.rotationEffect`. Çizik/toz katmanı için ince rastgele beyaz çizgiler.
- Maliyet: yarım gün. Etki: uygulamanın en çok ekran görüntüsü alınacak anı.

### A2. Klaket (Clapperboard)

Tur başlamadan önce 0.9 saniyelik klaket kapanışı.

```
┌─────────────────────────┐
│ ▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄ │  ← çubuk, yukarıdan iner ve "klak"
│  SAHNE      01          │
│  ÇEKİM      03          │
│  DESTE      HAYVANLAR   │
│  MOD        KLASİK      │
└─────────────────────────┘
```

- Çubuk kapandığı anda: ağır haptic + `sfx_skip_clack`, ekran 1 kare beyaza
  patlar, sonra klaket sola kayarak çıkar.
- Bilgi taşıyor: hangi deste, hangi mod, kaçıncı tur. Yani dekoratif değil,
  **işlevsel bir onay ekranı.** Takım modunda "ÇEKİM 03" tur numarasını veriyor.
- Sadece maçın **ilk turunda** tam gösterilir; sonraki turlarda 350 ms'lik kısa
  versiyon (sadece çubuk + tur numarası).
- Maliyet: yarım gün.

### A3. Perde Açılışı (Curtain Reveal)

Soğuk açılışta iki kadife perde kanadı yana açılır, arkasından marquee logo
ampulleri sırayla yanar.

- 1.2 saniye, sadece **soğuk açılışta** (arka plandan dönüşte yok).
- `sfx_curtain_open` + `sfx_bulb_flicker`.
- Teknik olarak launch screen'den sonraki ilk view; bu sürede JSON katalog
  yükleniyor ve RevenueCat/Firebase başlıyor. Yine "var olan beklemeyi süsleme"
  ilkesi.

### A4. Film Şeridi Geçişi (Frame Advance)

Kelime geçişleri. Şu anki plan "yukarıdan düşer" idi; bunu film karesi mantığına
oturtuyoruz: mevcut kelime yukarı kayar, kenarlarda sprocket delikleri bir an
hızlanır, yeni kelime alttan gelir. Sanki makara bir kare ilerlemiş.

- 450 ms, `sfx_card_slide` (kağıt sürtünmesi).
- SwiftUI: `.transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))`
  + sprocket şeridinde kısa bir `offset` animasyonu.

### A5. Kavis İşareti (Cue Mark)

Eski filmlerde makara değişimini operatöre haber veren, sağ üst köşede 4 kare
boyunca görünen küçük daire. Bizde **son 10 saniye uyarısında** çıkacak: sağ üst
köşede 3 kez yanıp sönen ince daire.

- Toplam 200 ms, hiç yer kaplamıyor, hiç süre eklemiyor.
- Bunu fark eden kullanıcı sayısı az olacak; ama fark edenler tam olarak
  "bu uygulamayı sinema seven biri yapmış" diyecek kişiler. Bu tür detaylar
  App Store yorumlarında ismen anılır.

---

## 2. Kademe B — yapılmalı (orta maliyet, güçlü etki)

### B1. Jenerik Akışı (Credits Roll) — maç sonu

Takım Savaşı bittiğinde skorlar tablo olarak değil **film jeneriği** olarak akar:

```
              SUNAR

        BAŞ ROL
        KIRMIZI TAKIM · 24 PUAN

        YARDIMCI ROL
        MAVİ TAKIM · 19 PUAN

        EN İYİ CANLANDIRMA
        AYŞE · 9 doğru

        EN ÇOK PAS GEÇEN
        MEHMET · 6 pas
```

- Playfair Display, ortalı, yukarı doğru yavaş akış, `sfx_win_fanfare`.
- Alt kısımda `TEKRAR OYNA` ve `PAYLAŞ` sabit durur — jeneriği beklemek zorunlu
  değil, dokunuşla sonuna atlanır.
- **"En iyi canlandırma" ve "en çok pas geçen" gibi ödüller uydurulmuş değil,
  gerçek veriden geliyor.** Takım modunda kimin sırasında kaç doğru olduğu
  zaten tutuluyor. Bu, jeneriği dekorasyondan çıkarıp masada konuşulan bir şeye
  çeviriyor.

### B2. Perde Arası (Intermission) — takım geçişi

Takım değişiminde düz "Sıra Kırmızı Takımda" yerine eski sinemaların perde arası
kartı: ortada `PERDE ARASI`, altında sıradaki takım ve kişi adı, kenarlarda
kadife perde, hafif nostaljik "büfe" tipografisi.

- 5 saniyelik otomatik geri sayım + `HAZIRIM` butonu (beklemek zorunlu değil).
- Bu ekran zaten gerekli (telefonun elden ele geçmesi lazım), sadece giydiriliyor.

### B3. Afiş Açılışı (Poster Reveal) — deste detayı

Deste detay sheet'i açılırken kartın afişi üzerinden soldan sağa bir **spot ışığı
süpürmesi** geçer (0.6 s), sonra sabitlenir. Afişin vitrine yeni konmuş hissi.

### B4. Letterbox Bantları

Önemli anlarda (tur sonu, maç sonu) üstten ve alttan siyah sinemaskop bantları
içe kayar, içerik 2.39:1 orana sıkışır, sonra geri açılır.

- 300 ms giriş. Sadece iki yerde kullanılacak — her yerde kullanılırsa etkisini
  kaybediyor ve ekranı daraltıyor.

### B5. Başlık Kartı (Title Card)

Tur başlarken klaketten sonra 500 ms'lik açılış jeneriği kartı:
küçük punto `TAKDİM EDER` üstte, altında büyük Oswald ile **deste adı**.
Klaketle birlikte tek akış gibi görünür.

---

## 3. Kademe C — lüks (v1.1 veya artan zaman)

| # | Detay | Not |
|---|---|---|
| C1 | **Projektör huzmesi + toz** | Ana ekranın üstünde konik ışık, içinde yavaş süzülen toz zerreleri. `Canvas` + 40 partikül, 12 fps. Güzel ama pil maliyeti var, "Film efektleri" anahtarına bağlı |
| C2 | **Kare atlaması (frame jitter)** | ~20 saniyede bir, 1 karelik 2px dikey zıplama + parlaklıkta %2 düşüş. Yıpranmış film hissi. **Çok ince olmalı**, aksi hâlde bug sanılır |
| C3 | **Reel yanığı** | Turlar arası dairesel yanma/parlama geçişi |
| C4 | **Bilet koçanı yırtılması** | Satın alma başarılı olduğunda bilet perforasyondan yırtılır, koçan köşeye uçar. `sfx_ticket_stamp` |
| C5 | **Fragman kartı** | Kilitli destelerde deste detayı, örnek kelimeleri fragman yazısı gibi akıtır ("YAKINDA VİZYONDA") |
| C6 | **Marquee kovalayan ampuller** | ŞİMDİ VİZYONDA şeridinde ampullerin sırayla koşması (chase light) |
| C7 | **Ses: projektör döngüsü** | Oyun ekranı boyunca çok kısık makara tıkırtısı. Bazı kullanıcı bunu sevmez → ayrı bir alt anahtar gerekebilir |
| C8 | **App ikonu sezonluk varyant** | Aralık'ta marquee'de kar, Ekim'de balkabağı ampul. `setAlternateIconName` |

---

## 4. Nereye sinematik detay KONMAYACAK

Bunu yazmak eklemek kadar önemli:

| Yer | Neden |
|---|---|
| **Oyun kartının kendisi (kelime ekranı)** | Kullanıcı burada 60 saniye boyunca tek şeye bakıyor: kelimeye. Grain ve sprocket şeridi dışında hiçbir hareket olmayacak. Dönen ışık, akan toz, titreşen çerçeve → kelimeyi okumayı zorlaştırır |
| **Doğru/pas geri bildirimi** | 450 ms içinde net olmalı. Damga animasyonu var, üzerine ikinci bir efekt eklenmeyecek |
| **Deste ızgarası scroll'u** | 92 kartlık ızgarada her karta giriş animasyonu koymak scroll'u ağırlaştırır. Kartlar sadece görünür |
| **Ayarlar** | İşlevsel ekran. Perde arka planı ve tipografi yeterli |
| **Paywall** | Dikkati fiyat ve CTA'da tutmak gerekiyor. Tek bezeme: seçili plan kartının ampulleri |

---

## 5. Erişilebilirlik ve performans

- **Reduce Motion:** Akademi geri sayımı sabit rakama, klaket anlık kesmeye,
  perde açılışı basit fade'e, jenerik akışı statik listeye döner. Hiçbir bilgi
  kaybolmaz — bütün bezemeler bilgi taşımayan katman olarak tasarlanıyor.
- **Film efektleri anahtarı (ayarlar §2):** kapalıyken grain, kavis işareti,
  kare atlaması, projektör huzmesi ve toz kapanır. Geçişler (klaket, geri sayım,
  jenerik) kalır — onlar tema değil, akışın parçası.
- **12 fps kuralı:** grain, ampul, toz gibi süregelen efektler 12 fps'te çizilir
  (`TimelineView(.animation(minimumInterval: 1/12))`). 60 fps'te çizmek hem
  gereksiz hem retro hisse ters.
- **Termal koruma:** `ProcessInfo.thermalState == .serious` olduğunda projektör
  huzmesi ve toz otomatik kapanır (replay kaydıyla aynı mantık).
- Her animasyon `.id()` ile kimliklenip yeniden başlatılabilir olmalı; yarım
  kalmış geçiş oyun akışını bloklamamalı. Animasyon bir `Task` değil, view
  durumundan türetilen bir sonuç olmalı.

---

## 6. Geliştirme sırası

Kademe A'nın tamamı, oyun döngüsü çalışır hâle geldikten hemen sonra (§ `07` §8'de
4. adımdan sonra) tek bir blokta yapılacak — dağıtılırsa tutarlılığı bozuluyor.

| Blok | İçerik | Süre |
|---|---|---|
| Sinematik I | A1 Akademi geri sayımı, A2 Klaket, A4 Kare geçişi, A5 Kavis işareti | 2 gün |
| Sinematik II | A3 Perde açılışı, B5 Başlık kartı, B3 Afiş açılışı, B4 Letterbox | 2 gün |
| Sinematik III | B1 Jenerik akışı, B2 Perde arası | 2 gün |
| Kademe C | Artan zamana göre, v1.1'e ertelenebilir | — |

Toplam ek: **6 gün.** § `09`'daki 11 günle birlikte genel takvim ~56.5 günden
**~73.5 güne** çıkıyor (§ `07` §8).
