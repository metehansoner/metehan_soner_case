# 03 — Onboarding, Paywall ve Monetizasyon

## 1. Onboarding

### Yapı kararı

Referans uygulamadaki en iyi fikir: onboarding **ana ekranın üzerinde bottom sheet**
olarak açılıyor. Arkada deste ızgarası bulanık değil, net görünüyor. Kullanıcı
anlatımı okurken arkadaki 92 desteyi görüyor ve "buradan çıkıp bunlara bakmak
istiyorum" hissi oluşuyor. Bunu aynen alıyoruz.

- Sheet yüksekliği: ekranın ~%55'i (`presentationDetents([.fraction(0.55)])`)
- Kapatılamaz (`interactiveDismissDisabled`)
- Arka plan: kadife perde gradient'i + grain
- İlerleme: film şeridi kareleri (**3 kare**), tıklanabilir — geri dönebilir
- Sağ üstte `ATLA` linki (son sayfa hariç)

### 3 adım

| # | Başlık | Metin | Görsel | CTA |
|---|---|---|---|---|
| 1 | HOŞ GELDİN | Sessiz sinemanın en eğlencelisi. 92 temalı deste, 12.000 kart, 25 dil. | Yelpaze halinde açılmış 4 retro afiş (**puan gösterilmez**) | `DEVAM` |
| 2 | TELEFONU ALNINA KOY | Ekranı arkadaşlarına göster. Onlar konuşmadan canlandırır, sen tahmin edersin. | Yandan silüet: telefon alında, karşıda 3 figür | `SIRADAKİ` |
| 3 | EĞ VE CEVAPLA | Öne eğ → DOĞRU. Arkaya eğ → PAS. Hepsi bu. | Telefonun iki yöne eğildiği diyagram, yeşil/kırmızı bölge | `HAZIRIM` |

### Neden 5 değil 3

Önceki sürüm 5 adımdı ve **adım 2–5, Nasıl Oynanır slider'ının 4 sayfasının
birebir kopyasıydı** (§ `02` §9): aynı başlıklar, aynı sıra, aynı görseller.
Kullanıcı ilk turuna varana kadar aynı anlatımı **iki kez** görüyordu — biri
uygulamayı hiç açmamışken, diğeri tam oynamak üzereyken.

İş bölümü artık net:

| | Onboarding (3 adım) | Nasıl Oynanır (4 sayfa) |
|---|---|---|
| Nerede | § `03` §1 | § `02` §9 |
| Ne zaman | Uygulamanın ilk açılışında, bir kez | İlk tur başlamadan, **mod başına** bir kez |
| Amacı | "Bu ne, neden indirdim, tek mekaniği ne" | "Şimdi ne yapacağım" |
| Kimin işi | İkna | Talimat |

İki birleştirme yapıldı:

- **Eski 1 + 2 → yeni 1.** Karşılama ile "desteni seç" ayrı sayfa olmayı hak
  etmiyordu; ikisi de aynı şeyi söylüyor: burada bol içerik var. Görsel olarak
  app ikonu düştü, yelpaze afişler kaldı — kullanıcı ikona **dokunarak** girdi,
  ilk ekranda ikonu tekrar göstermek hiçbir şey öğretmiyor; afişler ise içeriği
  gösteriyor.
- **Eski 3 + 4 → yeni 2.** Alna koyma ile "onlar canlandırır" tek bir sahnenin
  iki yarısı. Zaten tek illüstrasyonda ikisi birlikte var: telefon alında ve
  karşıda üç figür.

Eğme sayfası (yeni 3) **birleştirilmedi ve kısaltılmadı**, çünkü oyunun tek
mekaniği o ve dokunmatik moda geçen kullanıcıda içeriği değişen tek sayfa.

Mim illüstrasyonu (`ob_mime`) boşa çıkmıyor: Nasıl Oynanır sayfa 3'te kalıyor —
"konuşmak yasak" kuralının anlatıldığı tek yer orası ve o slider talimat işini
üstlendi.

Metin uzunluğu riski adım 2'de: iki cümle oldu. Almanca ve Fince'de İngilizce'nin
~%40 üzerine çıkabiliyor (§ `06` §2), %55'lik sheet'te taşma kontrolü bu sayfada
yapılacak.

### Social proof ekranı — v1'de yok

Önceki sürümde paywall'dan hemen önce 6. bir tam ekran vardı: defne dalları
arasında büyük puan, 3 yorum kartı, altta `OYNAMAYA BAŞLA`. Amacı kullanıcının
ödeme ekranını görmeden önce güven sinyali almasıydı.

**v1'de tamamen çıkarıldı.** Üç gerekçe üst üste bindi:

1. **Gösterecek puanımız yok.** App Store yönergeleri gerçek olmayan yorum
   uydurmayı yasaklıyor; lansmanda ne puan ne yorum var.
2. **Yerine konacak "değer önerisi" ekranı artık gereksiz.** O ekranın işi
   "3 saniyede öğrenilir, saatlerce oynanır" demekti — onboarding adım 1 zaten
   bunu söylüyor. Aynı cümleyi iki ekranda söylemek için tam ekran bir view
   yazmak, 3 adıma indirmenin bütün kazancını geri veriyor.
3. **Ekran envanterinde hiç yoktu** (§ `02` §2 giriş katmanı üç satır: Splash,
   Onboarding, Paywall). Yani kodlanacak ama bütçelenmemiş bir ekrandı; bu tür
   kalemler takvimi sessizce şişiriyor.

Aynı gerekçeyle **adım 1'deki uydurma `4.8 ★` puanı da kaldırıldı.** Sosyal kanıt
ekranını gizleyip adım 1'de puanı bırakmak riski ortadan kaldırmıyor, sadece daha
erken bir ekrana taşıyordu. Gerçek puan gelene kadar uygulamanın **hiçbir yerinde**
puan gösterilmeyecek.

Akış artık: Splash → Onboarding 1–3 → Paywall → Ana ekran.

**v1.1'e bırakılan hâli:** ilk ~500 gerçek yorumdan sonra ekran asıl biçimiyle
(gerçek puan + gerçek yorumlar, lokalize) geri gelir ve Remote Config bayrağıyla
açılır. `SocialProofView` bu yüzden klasör yapısında duruyor (§ `07` §2) ama v1
derlemesinde çağrılmıyor. Geri geldiğinde A/B ölçümü kolay: bayrak zaten var,
`paywall_view` event'i varyantı taşıyor.

### State yönetimi

`@AppStorage` yerine merkezi `AppSettingsStore` (`@Observable` + `didSet` →
UserDefaults). Anahtarlar: `onboardingDone`, `onboardingStep` (yarıda bırakıldıysa
devam), `paywallSeen`.

Bildirim izni onboarding'de **istenmeyecek.** Ana ekrana geldikten 8 saniye sonra
soft prompt olarak sorulacak — bu, izin oranını belirgin şekilde artıran bir
pattern (`Imposter/Features/Root/RootView.swift` içinde çalışan hâli var).

---

## 2. Paywall

### Varyant A — Onboarding sonu (tam ekran, "hard" değil)

Mockup: `paywall.html`, soldaki cihaz.

Yapı kararı, referans uygulamadan alındı: **önce malı göster, sonra para iste.**
Ekranın üst yarısı içerik duvarı, alt yarısı ödeme. Fayda listesi yok; 92 gerçek
kapak, sekiz maddelik bir listeden daha ikna edici.

Yukarıdan aşağıya:

1. **Afiş duvarı:** Ekranın üst ~%40'ı. Üç kolon mini deste kapağı, farklı
   hızlarda yavaş akıyor (26–34 sn döngü, ortadaki ters yönde), hafif eğik
   (−4°), aşağı doğru kadife perdeye karışıyor. Duvar bitmiyormuş hissi
   veriyor — "burada çok şey var" mesajını yazıyla değil görüntüyle söylüyor.
   Kapaklar **gerçek deste kapaklarından** diziliyor, statik kolaj değil (§ `01` §6.2).
2. **Başlık:** Pirinç plakete basılı `TAM BİLET` (ampulleri yanar) + altında
   Playfair Display ile "Tüm salonun *kilidini aç*".
3. **Tek satır özet:** `92 deste · 12.000 kart · 25 dil` / `Kendi kelimelerin ·
   Mix · Takım Savaşı · Replay`. Fayda listesinin yerini bu iki satır aldı.
4. **Plan kartları — 3 plan.** Bilet koçanı görünümü: ortada perfore noktalı
   çizgi, iki yanında tırtık çentiği; solda plan adı, sağda fiyat.
   | Sıra | Plan | Büyük rakam | Alt metin | Bant | Varsayılan |
   |---|---|---|---|---|---|
   | 1 | `HAFTALIK` | ₺XX / hafta | 3 gün ücretsiz, sonra yenilenir | `3 GÜN BEDAVA` | **✓ seçili** |
   | 2 | `AYLIK` | ₺XX / ay | Haftalık ₺X,XX | — | |
   | 3 | `YILLIK` | ₺XXX / yıl | Haftalık ₺XX,XX | `%XX TASARRUF` | |

   Seçili kart: 2px amber çerçeve + ampuller yanar + onay damgası. Kart
   yükseklikleri 64pt, aralık 11pt; seçili olmayan kartların alt metni tek satır.
   Haftalık en üstte ve seçili çünkü deneme sadece onda var — en kolay "evet"
   diyeceği kapı o. Yıllık en altta ama en yüksek tasarruf bandıyla.

   Her kartın büyük rakamı **kendi döneminin tam tutarı**, haftalık karşılık
   altta. Referans uygulama yıllık planda haftalık rakamı büyük, yıllık tutarı
   küçük yazıyor; biz tersini yapıyoruz. Üç kart aynı dille konuşmazsa
   karşılaştırma imkânsız hale geliyor ve App Store fiyat şeffaflığı kuralına
   yaklaşıyor.
5. **CTA:** Seçili plana bağlı — haftalıkta `ÜCRETSİZ DENE`, diğerlerinde
   `BİLETİ AL`. Altında küçük satır seçili planın tam koşulunu yazıyor
   ("Yıllık ₺XXX, otomatik yenilenir · İstediğin an iptal et").
6. **Alt satır:** `Geri Yükle` · `Koşullar` · `Gizlilik` — küçük, `textMuted`
7. **Atla:** Sağ üstte `ATLA` — onboarding varyantında **görünür**.

#### Referanstan bilinçli sapmalar

| Referans | Bizde | Neden |
|---|---|---|
| `Skip` en altta, Koşullar ile Gizlilik arasında | `ATLA` sağ üstte, görünür | Kaçış yolunu gizleme kalıbı. App Store incelemesi kapatma yolu belirsiz paywall'ları reddediyor; ayrıca ilk açılışta sıkıştırılan kullanıcı geri dönmüyor |
| "Not sure yet? Enable free access" satırı | Yok | Satır seçilebilir bir plan gibi duruyor ama ücretsiz erişim vermiyor, sadece planı değiştiriyor. Deneme bilgisi haftalık kartın kendi üstünde |
| Yıllıkta haftalık rakam büyük, yıllık tutar küçük | Tam tutar büyük | Yukarıdaki 4. madde |
| Mor–magenta neon | Amber + altın, kadife bordo | Magenta palette hiç yok; kapak hattının chroma-key rengi (§ `01` §5) |

#### Aylık kart — kaldı

İki plana inme seçeneği değerlendirildi ve reddedildi. Aylık kart **orta çapa**
işini görüyor: yıllığın ₺699,99'u tek başına pahalı görünürken yanında aylık
₺149,99 durunca yıllık ucuz geliyor. Bedeli afiş duvarının ~70pt kısalması,
kabul edildi.

### Varyant B — Modal (kilitli desteye/moda dokunuşta)

Mockup: `paywall.html`, sağdaki cihaz. Aynı plan kartları, üç fark:

- **Afiş duvarı %30 opaklığa çekilir**, öne dokunulan destenin kapağı büyük
  gelir (142pt, üstünde `BİLET GEREKLİ` bandı, altında kart sayısı). Bağlamlı
  paywall genel paywall'dan daha iyi dönüşüyor: kullanıcı soyut "92 deste"
  değil, o an istediği şeyi görüyor.
- **`ATLA` yok**; kapatma `X` butonu **1,5 saniye gecikmeyle** görünür.
  Onboarding akışında değiliz, kullanıcı bilinçli olarak kilitli bir şeye dokundu.
- **Başlık bağlamı taşır:** "*Film Klasikleri* destesinin kilidini aç", alt
  satır "Bu deste ve 91 deste daha · 12.000 kart".

Mod satışının yeri de burası: `Canlandır` afiş duvarında görünmüyor (duvar
desteleri gösteriyor), kilitli moda dokunulduğunda bu ekran modun adıyla açılıyor
(§ `09` §11 madde 10).

### Varyant C — Tur sonu soft paywall

İlk tamamlanan turdan sonra bir kez. Tur Sonu Skor ekranının üzerine yarım sheet:
"İyi oynadın. Sırada 90 deste daha var." + tek CTA + kolay kapatma.
(92 v1 destesi − 1 kalıcı ücretsiz − 1 günün bedavası = 90 kilitli.)

Koşul: `!isPremium && !softPaywallSeen && roundsCompleted >= 1`

> **Düzeltme:** Bu koşul önceden `!paywallSeen` idi. **Çalışmıyordu.** Varyant A
> onboarding sonunda herkese gösterildiği için `paywallSeen` her kullanıcıda
> `true` oluyor, dolayısıyla tur sonu soft paywall'ı **hiç tetiklenmiyordu.**
> Kodlanıp bir kez bile gösterilmeyecek bir ekrandı. Ayrı bir `softPaywallSeen`
> anahtarı gerekiyor; ürünün en yüksek dönüşüm potansiyeli olan an (ilk keyifli
> turun hemen sonrası) buna bağlı.

---

## 3. Gating stratejisi (ücretsiz / premium sınırı)

**Karar: 1 ücretsiz deste.** Referans uygulamadaki agresif model. Kapıyı 3 günlük
ücretsiz deneme açıyor; içeriğin tamamı denemeye giren kullanıcıya sunuluyor.

| Özellik | Ücretsiz | Premium |
|---|---|---|
| Deste | **1 deste** (Parti Başlangıcı) + günlük rotasyonlu 1 bedava deste | 92 deste |
| Oyun modu | Klasik | Klasik, Takım Savaşı, Canlandır, Hız Turu, Mix, Kendi Kelimelerin |
| Mix | ✗ | ✓ 2–8 deste karıştırma (§ `05` §6) |
| Custom deste | 1 taslak oluşturulabilir, **oynanamaz** | 3 aktif deste |
| Tur sayısı | **Sınırsız** | Sınırsız |
| Replay kaydı | ✗ | ✓ |
| Reklam | Yok (uygulamada hiç reklam olmayacak) | Yok |
| Dil | 25 dil (kısıtsız) | 25 dil |

Neden tur sayısı sınırsız: parti oyununda "tur bitti, bekle" demek masadaki 6
kişinin eğlencesini kesmek demek — o kullanıcı bir daha açmıyor. Duvarı **içerik
çeşitliliğine** koyuyoruz, oynama hakkına değil.

Neden reklam yok: masada 6 kişi varken araya giren video reklam deneyimi öldürüyor.
Ayrıca reklamsız oluş, abonelik değer önerisini netleştiriyor. (`Imposter`'da
rewarded ad modeli var; burada bilinçli olarak kullanılmıyor.)

Custom deste ücretsizde "oluştur ama oynayamazsın" — kullanıcı emek harcayıp 20
kelime yazdıktan sonra dönüşüm oranı yüksek oluyor. Emeği kaybolmuyor, satın
alınca aynı deste hazır bekliyor.

### Risk azaltıcı 1 — "BUGÜNÜN BEDAVA DESTESİ"

Tek ücretsiz destenin riski: kullanıcı 92 destenin kalitesini hiç görmeden karar
veriyor. Çözüm, her gün premium destelerden birinin 24 saat açılması.

- Ana ekranın en üstünde marquee şeridi: `ŞİMDİ VİZYONDA — FİLM KLASİKLERİ · 14:22:07`
  (geri sayım ile). Kart normal ızgarada da kilitsiz görünür, üstünde `BUGÜN BEDAVA`
  bandı olur.
- Seçim deterministik: `dayOfYear % premiumDeckCount` — sunucu gerekmiyor, tüm
  kullanıcılarda aynı deste açılıyor (sosyal konuşma yaratıyor), ve cihaz saati
  değiştirilse bile sadece başka bir desteye geçiyor, sömürülemiyor.
- Rotasyon havuzu Remote Config'ten okunur; istenirse sezona göre yönlendirilebilir.
- Ölçüm: `daily_free_deck_play` ve o günden gelen `paywall_view` oranı.

Bu özellik ikinci bir işi de yapıyor: **her gün uygulamayı açmak için sebep.**
Parti oyunları doğası gereği düşük retention'a sahiptir; günlük rotasyon bunu
bildirimle birleştirdiğimizde ("Bugün Süper Kahramanlar bedava") anlamlı bir
geri dönüş kanalı oluyor.

### Risk azaltıcı 2 — kilitli destede kelime önizlemesi

Deste Detayı sheet'i kilitli destelerde de açılır ve **6 örnek kelime** gösterir
(kağıt etiket chip'leri). "Ne satın alıyorum?" sorusunun cevabı. Bu, kilitli
kartı sadece kilit ikonuyla göstermekten belirgin şekilde daha iyi çalışır çünkü
kullanıcı içeriğin seviyesini (çok kolay mı, çok niş mi) görebiliyor.

---

## 4. RevenueCat kurulumu

`Imposter` projesindeki `SubscriptionStore` yapısı taşınacak (savunmacı
entitlement/offering çözümlemesi dahil).

| Ayar | Değer |
|---|---|
| Entitlement ID | `premium` |
| Offering | Dashboard'da "Current" işaretli olan (kodda hardcode yok) |
| Ürünler | `com.metes.charades.premium.weekly` (3 gün trial) · `.monthly` · `.yearly` |
| Paket çözümleme | Önce `PackageType` (`.weekly` / `.monthly` / `.annual`), tutmazsa product ID ile |
| Aile Paylaşımı | App Store Connect'te üçü de "Family Sharable" |
| Trial | **Sadece haftalık planda** 3 gün. Aylık ve yıllıkta trial yok |

Taşınacak savunmacı davranışlar:
- Entitlement adı dashboard'da değişse bile aktif entitlement varsa premium ver
  (ödeme yapan kullanıcıyı asla kilitleme).
- `customerInfo` çekilemezse önceki premium durumunu koru — offline'da abonelik
  iptal edilmiş gibi davranma.
- `customerInfoStream` ile canlı dinleme.
- Fiyatlar her zaman store'dan (`localizedPriceString`, `localizedPricePerWeek`);
  koda hiçbir fiyat yazılmayacak.

### Trial mantığı
Seçili planın `introductoryPrice` değeri varsa CTA `ÜCRETSİZ DENE` ve alt metin
"3 gün ücretsiz, sonra {fiyat}/hafta"; yoksa CTA `DEVAM ET` ve trial metni
gizlenir. Bu kontrol **plan değiştikçe canlı güncellenir**: kullanıcı yıllığa
geçtiğinde CTA `DEVAM ET`e döner. Üç planlı yapıda bu şart — aksi hâlde yıllık
seçili durumda "Ücretsiz dene" yazmak yanıltıcı olur ve App Store reddi sebebidir.
Daha önce trial kullanmış kullanıcıda `introductoryPrice` gelmez, otomatik olarak
doğru metin gösterilir.

---

## 5. Ölçüm (funnel event'leri)

Bunlar **v1'de baştan** kurulacak. (`Imposter`'da Firebase ekli ama tek bir
`logEvent` çağrısı yok — funnel'ı sonradan kurmak kaybedilmiş veri demek.)

| Event | Parametre |
|---|---|
| `onboarding_step_view` | `step` (1–3) |
| `onboarding_skip` | `step` |
| `onboarding_complete` | — |
| `paywall_view` | `variant` (onboarding/modal/soft), `context` (deck id) |
| `paywall_plan_select` | `plan` |
| `paywall_purchase_start` / `_success` / `_fail` | `plan`, `error_code` |
| `paywall_dismiss` | `variant`, `seconds_shown` |
| `deck_open` / `deck_locked_tap` | `deck_id` |
| `daily_free_deck_view` / `_play` | `deck_id` |
| `mode_select` | `mode` |
| `howto_view` | `mode`, `page` |
| `round_start` / `round_complete` | `mode`, `deck_ids`, `duration`, `correct`, `skipped` |
| `custom_deck_create` / `_word_add` | `word_count` |
| `language_change` | `from`, `to` |
| `replay_save` / `replay_share` | `source` (`round_end` \| `archive`), `slow_motion_used` |
| `replay_archive_open` | `entry` (`header` \| `settings` \| `match_end`), `reel_count` |
| `replay_archive_play` | `age_days` — kayıt kaç gün sonra tekrar izlendi |
| `replay_pin` / `replay_delete` | — |
| `replay_quota_evict` | `evicted_count` — kota dolduğu için silinen kayıt |

`replay_archive_play` ile `age_days` özellikle önemli: eğer kimse kayıtları
1 günden sonra açmıyorsa arşiv ekranı yatırıma değmiyor demektir ve v1.1'de
sadeleştirilir. Bu, özelliği ölçülebilir tutan tek event.

Kritik kural: `userId` (UUID) hem RevenueCat `appUserID`'si hem Firebase
`setUserID`'si olarak **aynı** kullanılacak. Böylece "hangi kullanıcı hangi
funnel'dan geçip satın aldı" sorusu cevaplanabilir olur.
