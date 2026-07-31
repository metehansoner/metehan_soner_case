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
- İlerleme: film şeridi kareleri (5 kare), tıklanabilir — geri dönebilir
- Sağ üstte `ATLA` linki (son sayfa hariç)

### 5 adım

| # | Başlık | Metin | Görsel | CTA |
|---|---|---|---|---|
| 1 | HOŞ GELDİN | Sessiz sinemanın en eğlencelisi. 92 deste, 12.000 kart, 25 dil. | App ikonu + marquee çerçeve (**puan gösterilmez**) | `DEVAM` |
| 2 | DESTENİ SEÇ | Onlarca temalı desteden birini seç ya da birkaçını karıştır. | Yelpaze halinde açılmış 4 retro afiş | `SIRADAKİ` |
| 3 | TELEFONU ALNINA KOY | Ekranı arkadaşlarına göster. Kelimeyi sen görmüyorsun, onlar görüyor. | Yandan silüet: telefon alında, karşıda 3 figür | `SIRADAKİ` |
| 4 | ONLAR ANLATIR, SEN TAHMİN EDERSİN | Konuşmak yasak. Sadece hareket, mimik, jest. | Mim yapan figür + üstü çizili konuşma balonu | `SIRADAKİ` |
| 5 | EĞ VE CEVAPLA | Öne eğ → DOĞRU. Arkaya eğ → PAS. Hepsi bu. | Telefonun iki yöne eğildiği diyagram, yeşil/kırmızı bölge | `HAZIRIM` |

### Adım 6 — Social proof (tam ekran)

Referans uygulamada bu ekran paywall'dan hemen önce geliyor ve bilinçli bir
karar: kullanıcı ödeme ekranını görmeden önce "bu uygulamaya 174 bin kişi 4.8
vermiş" bilgisini alıyor. Bizde de aynı yerde olacak.

Aynı gerekçe **adım 1 için de geçerliydi** — orada da uydurma bir `4.8 ★` puan
gösteriliyordu. Kaldırıldı: adım 6 gizlenip adım 1'de puan kalırsa risk ortadan
kalkmıyor, sadece daha erken bir ekrana taşınıyor. Gerçek puan gelene kadar
uygulamanın hiçbir yerinde puan gösterilmeyecek.

- Üstte defne dalları arasında büyük puan (retro ödül plaketi görünümü)
- 3 yorum kartı, avatar + 5 yıldız + kısa metin — **yorumlar lokalize edilir**
- Alt: birincil `OYNAMAYA BAŞLA` → paywall

> Uyarı: App Store yönergeleri gerçek olmayan yorum uydurmayı yasaklar. Lansmanda
> gerçek puanımız olmadığı için bu ekran **v1'de gizli kalacak**, ilk 500 gerçek
> yorumdan sonra açılacak. Yerine "3 saniyede öğrenilir, saatlerce oynanır" gibi
> bir değer önerisi ekranı gösterilecek. Remote Config ile açılıp kapanabilir.

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

Yukarıdan aşağıya:

1. **Görsel şerit:** Ekranın üst %35'i — deste kartlarının hafif eğik, üst üste
   binmiş kolajı, aşağı doğru kadife perdeye karışır. Referans uygulamadaki
   "ızgara + fade" fikri ama afiş estetiğiyle.
2. **Başlık:** `TAM BİLET` (Playfair Display Black) + alt satır "Tüm salon senin."
3. **Fayda listesi** — her satır başında pirinç ikon:
   - 92 temalı deste, 13 bölüm
   - 12.000+ kart
   - 3 özel deste oluştur
   - Desteleri karıştır (Mix)
   - Takım Savaşı ve Hız Turu modları
   - Reklamsız, sınırsız oyun
   - Aile Paylaşımı dahil
4. **Plan kartları — 3 plan.** Bilet kuponu görünümünde, kenarları tırtıklı.
   | Sıra | Plan | Alt metin | Bant | Varsayılan |
   |---|---|---|---|---|
   | 1 | `HAFTALIK` | 3 gün ücretsiz, sonra ₺XX/hafta | `EN POPÜLER` | **✓ seçili** |
   | 2 | `AYLIK` | ₺XX/ay (haftalık ₺X.XX) | — | |
   | 3 | `YILLIK` | ₺XXX/yıl (haftalık ₺X.XX) | `%80 TASARRUF` | |

   Seçili kart: 2px amber çerçeve + ampuller yanar + onay damgası.
   Üç plan dikey listede sıkışmaması için kart yükseklikleri 64pt, aralık 10pt;
   seçili olmayan kartların alt metni tek satır. Haftalık en üstte ve seçili
   çünkü deneme sadece onda var — kullanıcının en kolay "evet" diyeceği kapı o.
   Yıllık en altta ama en yüksek tasarruf bandıyla; karşılaştırma yapan kullanıcı
   onu buluyor.
5. **CTA:** `ÜCRETSİZ DENE` + altında küçük "Şimdi ödeme alınmaz · İstediğin an iptal et"
6. **Alt satır:** `Geri Yükle` · `Koşullar` · `Gizlilik` — küçük, `textMuted`
7. **Atla:** Sağ üstte `ATLA` — onboarding varyantında **görünür**.

### Varyant B — Modal (kilitli desteye/moda dokunuşta)

Aynı içerik, iki fark:
- `ATLA` yok; kapatma `X` butonu **1.5 saniye gecikmeyle** görünür.
- Başlıkta bağlam var: "FİLM & TV destesinin kilidini aç" + o destenin kartı büyük
  gösterilir. Bağlamlı paywall genel paywall'dan daha iyi dönüşüyor.

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
| Oyun modu | Klasik | Klasik, Takım Savaşı, Canlandır, Hız Turu, Mix |
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
| `onboarding_step_view` | `step` (1–5) |
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
