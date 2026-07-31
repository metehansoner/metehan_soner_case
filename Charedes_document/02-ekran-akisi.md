# 02 — Ekranlar ve Akış

## 1. Navigasyon kabuğu: tab bar yok

**Karar: bottom tab bar kaldırıldı.** Ayarlar ana ekranın **sağ üstündeki dişli
butonundan** sheet olarak açılıyor.

Gerekçe: tab bar en az iki sekme gerektirir, ama uygulamanın gerçekten tek bir
kök ekranı var — deste ızgarası. Ayarlar bir varış noktası değil, oturum başına
bir kez uğranan bir yer. Onu sekme yapmak ekranın altından 56pt + safe area
alanı kalıcı olarak götürüyordu; 92 destelik bir ızgarada bu, her ekranda yarım
kart sırası demek. Referans uygulamalar da aynı yolu seçmiş (biri sağ üstte
"Menu", diğeri sol üstte dişli).

### Ana ekran header'ı

| Konum | Öğe | Aksiyon |
|---|---|---|
| Sol üst | **VIP bileti** butonu | Paywall (modal). Premium'da altın onaylı bilet ikonu, tıklanınca abonelik durumu |
| Orta | `CHARADES` marquee logo | — |
| Sağ üst (1) | **Film makarası** ikonu — *koşullu* | Film Arşivi (ekran 22). **Sadece arşivde ≥ 1 kayıt varsa görünür**, üzerinde adet badge'i |
| **Sağ üst (2)** | **Pirinç dişli** | **Ayarlar sheet'i** |

Butonlar `HeaderCircleIconButton` stilinde: 40pt daire, `surfaceCardRaised`
zemin, 1px `accentGold` kenar, ikon `accentBrass`. Scroll aşağı indikçe header
küçülür ama bu butonlar sabit kalır (her zaman erişilebilir).

Makara ikonu koşullu, çünkü kullanıcıların çoğunda replay kaydı kapalı olacak
(varsayılan kapalı, Premium özelliği). Boş bir arşive giden kalıcı bir buton
header'ı gereksiz kalabalıklaştırır. Kayıt yokken arşive tek erişim yolu
ayarlardaki satır.

### Ayarlar sunumu

`.sheet` + `presentationDetents([.large])` + `presentationCornerRadius(28)`,
arka planı kadife perde + grain. Üstte başlık `AYARLAR`, sağ üstte kapatma
butonu, altta `KAPAT`. İçerik § `06`.

### Ekranın altı ne oldu?

Tab bar'dan boşalan alan **PlayBar**'a gidiyor: deste seçildiğinde alttan yükselen
`surfaceCardRaised` bar, solda "2 deste · 260 kart", sağda marquee `OYNA` butonu.
Seçim yoksa bar da yok, tüm alan ızgaraya kalıyor. Yani alt bölge artık sabit bir
navigasyon öğesi değil, bağlama göre çalışan bir aksiyon alanı.

---

## 2. Ekran envanteri

Toplam **23 ekran** + 3 her yerden çıkabilen overlay. Kodlama sırasında bu liste doğrudan iş kalemi listesi
olarak kullanılabilir.

### Giriş katmanı
| # | Ekran | Tip | Not |
|---|---|---|---|
| 1 | Launch / Splash | Full | Perde açılma animasyonu (1.2s), marquee logo yanar |
| 2 | Onboarding 1–5 | Bottom sheet | Ana ekran arkada görünür, § `03` |
| 3 | Paywall (onboarding sonu) | Full | Skip linki var, § `03` |

### Ana akış
| # | Ekran | Tip | Not |
|---|---|---|---|
| 4 | Ana Ekran (Deste Izgarası) | **Kök ekran** | Marquee logo, sol üst VIP + sağ üst makara (koşullu) ve dişli, filtre chip'leri, 2/3 kolon grid |
| 5 | Deste Detayı | Sheet | Örnek kelimeler, kart sayısı, "OYNA" |
| 6 | Mix Kurulumu | Full | Çoklu deste seçimi, karışım önizleme |
| 7 | Custom Deste Listesi | Full | Kendi destelerim (max 3) |
| 8 | Custom Deste Editörü | Full | İsim, kapak seçimi, kelime ekleme |
| 9 | Nasıl Oynanır (slider) | Sheet | 4 sayfalı, moda göre içerik değişir |
| 10 | Mod Seçimi | Sheet | 5 mod kartı, § `04` |
| 11 | Takım Kurulumu | Full | Sadece Takım Savaşı modunda |
| 12 | Tur Ön Ayar | Sheet | Süre, zorluk, kart sayısı |
| 13 | Yatay Çevir Uyarısı | Full | Landscape'e geçiş istemi |
| 14 | Geri Sayım | Full (landscape) | 3-2-1, projektör titremesi |
| 15 | Oyun Kartı | Full (landscape) | Ana oyun, tilt |
| 16 | Duraklat | Overlay | Devam / Yeniden / Çık |
| 17 | Tur Sonu Skor | **Full (landscape)** | Doğru/pas listesi iki kolonda, puan, bilet kağıdı görünümü. Landscape, çünkü süre bitince otomatik geliyor ve telefon o an yatay (§ `09` §1) |
| 18 | Replay Oynatıcı | Full | Kayıt açıksa; zaman çizelgesi işaretleri, altyazı, ağır çekim, paylaş/kaydet/sabitle/sil. § `04` §4.4 |
| 19 | Maç Sonu (Takım) | Full (**portrait**) | Jenerik akışı, kazanan takım, `TEKRAR OYNA` · `PAYLAŞ` · `ARŞİVE GİT`. Beraberlikte ani ölüm turu (§ `09` §5). Yön burada portrait'e döner, "dikey çevir" mikro animasyonuyla |

### Ayarlar (sağ üst dişliden)
| # | Ekran | Tip | Not |
|---|---|---|---|
| 20 | Ayarlar | **Sheet** (`.large`) | 4 grup / 13 satır, § `06` |
| 21 | Dil Seçimi | Sheet (ayarların üzerine) | 25 dil, her biri kendi dilinde, § `06` |

### Film Arşivi (header'daki makara ikonundan veya ayarlardan)
| # | Ekran | Tip | Not |
|---|---|---|---|
| 22 | Film Arşivi | Full | Maça göre gruplanmış kayıtlar, yatay sahne kartları, çoklu seçim. § `04` §4.3 |
| 23 | Replay Oynatıcı (arşivden) | Full | Ekran 18 ile **aynı view**, farklı giriş noktası |

### Her yerden çıkabilenler
- Paywall (modal varyant) — kilitli deste veya kilitli moda dokunuşta
- Puanla bizi sheet'i — ilk başarılı turdan sonra
- Bildirim izni soft prompt'u — ana ekranda 8 saniye gecikmeli

---

## 3. Ana akış diyagramı

Kısayol: kesikli oklar **geri dönüş** yollarıdır. Her ekranın kapanış yolu
çizilmek zorunda — önceki sürümde Duraklat, oyundan çıkış ve arşivden dönüş
diyagramda yoktu ve bu, kullanıcının oyunda kilitli kalabileceği bir boşluk
bırakıyordu (§ `09` §3).

```mermaid
flowchart TD
    A[Launch / Perde Açılışı] --> B{Onboarding<br/>tamamlandı mı?}
    B -- Hayır --> C[Onboarding 1-5<br/>bottom sheet]
    C --> D[Paywall<br/>skip'li]
    D --> E
    B -- Evet --> E[ANA EKRAN<br/>Deste Izgarası]

    E --> F[Deste Detayı]
    E --> G[Mix Kurulumu]
    E --> H[Custom Desteler]
    E --> I[Ayarlar sheet'i<br/>sağ üst dişli]
    F -.-> E
    G -.-> E
    I -.-> E
    H --> H2[Custom Deste Editörü]
    H2 -.-> H
    H -.-> E
    I --> LNG[Dil Seçimi]
    LNG -.-> I

    E --> AR[FİLM ARŞİVİ<br/>makara ikonu · kayıt varsa]
    I --> AR
    AR --> ARV[Replay Oynatıcı<br/>arşiv bağlamı]
    ARV -.-> AR
    AR -.-> E

    F --> J[Mod Seçimi]
    G --> J
    H --> J
    J --> K{Takım Savaşı mı?}
    K -- Evet --> L[Takım Kurulumu<br/>takım · tur sayısı · oyuncular]
    K -- Hayır --> M[Tur Ön Ayar]
    L --> M
    M --> N{Nasıl oynanır<br/>daha önce görüldü mü?}
    N -- Hayır --> O[Nasıl Oynanır<br/>4 sayfalı slider]
    O --> P
    N -- Evet --> P{Yatay çevrilebiliyor mu?}
    P -- Evet --> Q[Geri Sayım 3-2-1<br/>LANDSCAPE · atlanamaz]
    P -- Hayır --> PT[Portrait oyun modu<br/>dokunmatik cevap]
    PT --> Q
    Q --> R[Oyun Kartı<br/>tilt: doğru / pas]
    R --> S{Süre bitti?}
    S -- Hayır --> R

    R --> PA[DURAKLAT<br/>overlay]
    PA -- Devam --> Q
    PA -- Turu yeniden --> Q
    PA -- Çıkış + onay --> E
    KES[Kesinti: arka plan ·<br/>çağrı · ekran kilidi] --> PA

    S -- Evet --> T[Tur Sonu Skor<br/>LANDSCAPE]
    T -- Tekrar oyna --> Q
    T -- Sahneye dön --> E
    T --> U{Replay var mı?}
    U -- Evet --> V[Replay Oynatıcı<br/>altyazı · ağır çekim]
    V --> W
    U -- Hayır --> W{Takım modu ve<br/>tur kaldı mı?}
    W -- Evet --> TH[PERDE ARASI<br/>sıradaki takım]
    TH --> Q
    W -- Hayır --> Y{Takım modu mu?}
    Y -- Evet --> X[Maç Sonu · Jenerik<br/>PORTRAIT · beraberlikte<br/>ani ölüm turu]
    Y -- Hayır --> E
    X -- Tekrar oyna --> L
    X -- Arşive git --> AR
    X --> E
```

Diyagramda düzeltilen dört yapısal hata:

1. **Duraklat ve çıkış yolu yoktu.** `R`'den tek çıkış "süre bitti" idi; oyuna
   giren kullanıcının turu bitirmeden dönme yolu diyagramda hiç görünmüyordu.
   Oyun akışı `NavigationStack`'in yerine render edildiği ve swipe-back kapalı
   olduğu için bu, gerçekten kilitlenme riski demekti.
2. **Arşiv, oyun akışına bağlanmıştı.** `AR → V → W` zinciri, sadece eski
   kaydını izleyen kullanıcıyı "tur kaldı mı?" kararına ve oradan geri sayıma
   düşürüyordu. Arşiv oynatıcısı artık ayrı bir düğüm (`ARV`) ve arşive dönüyor.
3. **Takım olmayan modlar takım maç sonuna gidiyordu.** `W -- Hayır --> X` her
   modda geçerliydi, yani tek başına Klasik oynayan kullanıcıya "BAŞ ROL /
   KIRMIZI TAKIM" jeneriği açılıyordu. `Y` kararı eklendi.
4. **`TEKRAR OYNA` ve `SAHNEYE DÖN` kenarları yoktu.** Ekran 17'de tanımlı
   butonların akışta karşılığı yoktu; oysa "tur bitti, tekrar oynayalım"
   uygulamanın en yüksek frekanslı aksiyonu.

---

## 4. Ekran detayları

### 4 — Ana Ekran (Deste Izgarası)

Yukarıdan aşağıya:

1. **Header (sabit, scroll'da küçülür)**
   - Orta: `CHARADES` marquee logo — Oswald Bold 44, çevresinde 14 ampul,
     sıralı yanıp sönme.
   - **Sol üst: VIP bileti butonu** (premium değilse amber bilet, premium ise
     altın onaylı bilet). Paywall'a gider.
   - **Sağ üst: film makarası** (koşullu, arşivde kayıt varsa) → Film Arşivi.
   - **Sağ üst: pirinç dişli** → Ayarlar sheet'i.
   - Logonun altında ince altın çizgi + `SESSİZ SİNEMA` sekonder etiketi.
   - Scroll'da logo 44 → 24'e küçülür, iki buton boyutunu korur.

2. **Filtre chip satırı** (yatay scroll, sticky) — **16 chip**
   `TÜMÜ` · `POPÜLER` · `YENİ` · `PARTİ` · `CANLANDIR` · `FİLM & TV` · `MÜZİK` ·
   `ÇOCUK` · `SPOR` · `BİLGİ` · `MARKA` · `NOSTALJİ` · `DÜNYA` · `HAYVANLAR` ·
   `EV` · `SEZON`
   Aktif chip: `accentAmber` zemin, `textOnAmber` metin, ampul çerçeve.
   Pasif: şeffaf + `accentGold` kenar.
   `SEZON` sadece ilgili tarih penceresinde, `POPÜLER` ve `YENİ` dinamik hesaplanır.
   Chip sayısı 16'ya çıktığı için satır sonunda sağa doğru bir gradient fade
   olacak — kaydırılabilir olduğu görsel olarak belli olsun.

   > **Düzeltme:** Liste önceden 15 chip'ti ve 13 bölümden **`MARKA & TEKNOLOJİ`
   > eksikti** (3 dinamik chip + 12 bölüm chip'i). O bölümün 8 destesi — 6'sı
   > v1'de — filtreyle hiç erişilemiyordu. Chip sayısı bölüm sayısıyla eşleşmek
   > zorunda: 3 + 13 = 16. Bunu CI'da doğrulayan bir test eklenecek (§ `05` §5).

3. **"ŞİMDİ VİZYONDA" şeridi** — günlük bedava desteyi duyuran marquee bandı:
   solda küçük ampullü çerçeve içinde destenin kartı, sağda `BUGÜN BEDAVA` +
   deste adı + geri sayım (`14:22:07`). Dokununca doğrudan Deste Detayı açılır.
   Premium kullanıcıda bu şerit gizlenir (onun için anlamsız).

4. **"BENİM DESTELERİM" bölümü** — `sectionLabel` başlık + sağda grid toggle
   (2 kolon / 3 kolon). Kullanıcının ücretsiz + satın alınmış + custom desteleri.

5. **Öne çıkan satır (yatay scroll):** `MIX` kartı ve `CUSTOM DESTE` kartı burada,
   diğerlerinden farklı görsel dille (Mix: dönen film makarası; Custom: boş afiş +
   artı işareti).

6. **Deste ızgarası** — 3:4 kartlar, 2 veya 3 kolon, 12pt aralık. Kilitli kartlar
   sepia + kilit + "BİLET GEREKLİ" mührü. Lazy yükleme.

7. **PlayBar (alt sabit, sadece seçim varsa)** — `surfaceCardRaised` zemin,
   solda "2 deste · 260 kart", sağda marquee `OYNA` butonu. Tab bar olmadığı için
   doğrudan safe area'nın üzerinde oturur. Seçim yoksa bar görünmez ve tüm dikey
   alan ızgaraya kalır.

Kaydırma davranışı: aşağı kaydırınca header küçülür (logo 44 → 24), chip satırı
yapışır, VIP ve dişli butonları sabit kalır.

### 5 — Deste Detayı (sheet)

Üstte 3:4 kart görseli (blur'lu arka plan olarak da kullanılır), altında:
- Playfair Display başlık + kısa açıklama (lokalize)
- Meta satırı: `130 KART` · `KOLAY` · `4+ OYUNCU`
- **Örnek kelimeler:** 6 kelime, kağıt etiket görünümünde chip'ler. Premium
  olmayan kullanıcıya kilitli destede de gösterilir — merak uyandırır.
- Butonlar: birincil `OYNA`, ikincil `MIX'E EKLE`, ikon buton `FAVORİ`
- Kilitliyse birincil buton `BİLETİ AL` olur ve paywall'ı açar.

### 9 — Nasıl Oynanır (slider)

**Senin özellikle istediğin ekran.** 4 sayfalı yatay slider, sheet içinde.
İlerleme göstergesi: film şeridi kareleri (aktif kare amber, geçilenler altın,
gelecekler soluk) — nokta yerine tema ile uyumlu.

Klasik/Takım/Hız modları için içerik:

| Sayfa | Başlık | Metin | Görsel |
|---|---|---|---|
| 1 | DESTENİ SEÇ | Onlarca temalı desteden birini ya da birkaçını karıştır. | Yelpaze gibi açılmış 4 afiş |
| 2 | TELEFONU ALNINA KOY | Ekranı arkadaşlarına göster, kelimeyi sadece onlar görsün. | Yandan silüet: telefon alında, karşıda 3 kişi |
| 3 | ONLAR ANLATSIN | Konuşmadan canlandırsınlar, sen tahmin et. | Mim yapan figür, üstünde konuşma balonu çizili-üstü |
| 4 | EĞ VE CEVAPLA | Öne eğ = DOĞRU. Arkaya eğ = PAS. | Telefonun iki yöne eğildiği diyagram, yeşil/kırmızı |

`Canlandır` modu seçilmişse sayfa 2 ve 3 yer değişir ve metinler "sen canlandır,
onlar tahmin etsin" olarak değişir. `usesTilt == false` olan bir mod eklenirse
sayfa 4 otomatik gizlenir.

Gösterim kuralı: mod başına **bir kez** otomatik gösterilir
(`howToSeen: Set<String>` UserDefaults'ta). Sonrasında Deste Detayı ve Duraklat
ekranındaki `?` butonundan her zaman açılabilir.

### 13 — Yatay Çevir Uyarısı

Tam ekran, ortada dönen telefon ikonu animasyonu + `TELEFONU YATAY ÇEVİR`.
Cihaz landscape'e geldiğinde otomatik ilerler (buton yok). Alt kısımda küçük
"Yatay çeviremiyorum" linki → dokunmatik moda geçer (tilt kapalı, ekranın
yarılarına dokunma ile oynanır).

### 15 — Oyun Kartı (landscape)

- Zemin `surfacePoster`, üst ve altta film sprocket şeridi.
- Ortada kelime: Oswald Bold, 96'dan başlayıp sığana kadar küçülür (min 44).
- Sol üst: kalan süre, büyük mono rakamlar; son 10 saniyede `stateWarning`e döner
  ve her saniye hafif haptic + retro "tik" sesi.
- Sağ üst: `DOĞRU 7` sayacı.
- Alt orta: çok küçük `PAS ↰ | ↱ DOĞRU` hatırlatıcısı (ilk 3 turda görünür).
- Tilt cevabı: tam ekran renk basar (yeşil/kırmızı), ortada damga animasyonu
  (`DOĞRU` / `PAS` eğik mühür), 0.45s sonra sonraki kelime yukarıdan düşer.
- Duraklat: iki parmakla dokunma veya üst kenardan aşağı sürükleme.

### 17 — Tur Sonu Skor

Bilet kağıdı (`surfaceTicket`) görünümünde dikey liste: her kelime, solunda
yeşil onay veya kırmızı çarpı. **Yanlış işaretlenen kelimeye dokunarak düzeltme**
yapılabilir (parti oyunlarında kritik: "o aslında doğruydu!"). Üstte büyük puan,
altında `TEKRAR OYNA` / `SIRADAKİ TAKIM` / `SAHNEYE DÖN`.

---

## 5. Navigasyon mimarisi

- Kök: tek bir `NavigationStack` + `NavigationPath`. `TabView` **yok.**
- Rotalar: `enum AppRoute: Hashable { case mix, customList, customEditor(String?), teamSetup, archive, archivePlayer(String) }`
  (Deste Detayı, Mod Seçimi, Tur Ön Ayar, Ayarlar ve Dil sheet olarak sunulur,
  path'e girmez.) `archive` ve `archivePlayer` **oyun akışının dışında** —
  Film Arşivi'nden açılan oynatıcı, tur sonunda açılan oynatıcı ile aynı view'ı
  kullanır ama farklı yere döner: arşive, oyun akışına değil.
- Oyun akışı **navigation stack'e push edilmez.** Oyun başlarken `LiveGame`
  nesnesi oluşur ve `NavigationStack`'in tamamının yerine `GameFlowView` render
  edilir. Sebep: oyun sırasında geri butonu ve swipe-back olmamalı; yanlışlıkla
  turu bölmek en can sıkıcı hata olur.
- `LiveGame == nil` olduğunda ana yapı geri döner, kullanıcı bıraktığı scroll
  pozisyonunda bulur.
- Faz makinesi: tek kaynak § `07` §5'teki `LivePhase`. Bu dosyada ayrıca
  tanımlanmıyor — önceden burada `teamHandoff` içermeyen eksik bir kopyası vardı
  ve iki döküman çelişiyordu.
- Ekranlar `navigationBarHidden(true)` kullandığı için native swipe-back kaybolur;
  `Imposter` projesindeki `.onSwipeBack { }` modifier'ı taşınacak.

---

## 6. Boş ve hata durumları

| Durum | Ne gösterilir |
|---|---|
| Custom deste yok | Boş afiş çerçevesi + "İlk destenizi yazın" + `DESTE OLUŞTUR` |
| Custom destede < 5 kelime | `OYNA` disabled + "En az 5 kelime gerekli" |
| Mix'te tek deste seçili | "Mix için en az 2 deste seç" |
| Filtre sonucu boş | Film şeridi ikonu + "Bu bölümde henüz deste yok" |
| Motion sensörü yok/izin sorunu | Otomatik dokunmatik moda düşer, bilgi banner'ı |
| Kamera izni reddedildi (replay) | Replay ayarı kapatılır + ayarlara yönlendiren metin |
| Satın alma başarısız | Sheet üzerinde retro "BİLET GEÇERSİZ" uyarısı + tekrar dene |
| Ağ yok (paywall) | Fiyatlar yerine iskelet (shimmer) + "Bağlantı bekleniyor" |
