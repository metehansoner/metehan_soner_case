# 09 — Kesinti, Yön ve Sınır Durumları

Bu dosya bir denetim sonucunda doğdu. Dökümanın ilk sekiz bölümü **her şeyin
yolunda gittiği akışı** iyi tanımlıyordu; kopan yer, işlerin yolunda gitmediği
anlardı. Parti oyununda o anlar istisna değil, **beklenen durum**: telefon çalar,
biri uygulamayı kapatır, kelimeler biter, iki takım berabere kalır.

---

## 1. Yön (orientation) katmanı — en büyük tek boşluk

Kural şuydu: "tüm ekranlar portrait, oyun ekranı landscape kilitli". Ama oyun
akışı **tek bir `GameFlowView`** içinde yaşıyor ve o view'ın fazları iki yöne
bölünmüş durumda:

| Faz | Yön | Neden |
|---|---|---|
| `orientationPrompt` | Portrait | "Telefonu yatay çevir" istemi |
| `countdown` | **Landscape** | Telefon alna gidiyor |
| `playing` | **Landscape** | Oyun |
| `paused` | **Landscape** | Oyunun üstünde overlay, yön değişmez |
| `roundEnd` | **Landscape** | ⚠️ aşağıya bak |
| `replay` | **Landscape** | Video 16:9, yatay doğal |
| `teamHandoff` | **Landscape** | Telefon elden ele geçiyor, hâlâ yatay |
| `matchEnd` | Portrait | Jenerik akışı dikey okunuyor, oyun bitti |

**Kritik düzeltme — tur sonu ekranı landscape olacak.** İlk taslakta ekran 17
(Tur Sonu Skor) "Full" yazıyordu, yani genel kurala göre portrait. Ama süre 0'a
inince tur sonu ekranına **otomatik** geçiliyor ve o anda telefon birinin alnında,
yatay duruyor. Portrait tasarlanmış bir bilet kağıdı listesi, yatay tutulan
telefonda açılırsa kullanıcı ekranı okuyamaz. Skor listesi yatay iki kolona
yerleşecek: solda doğrular, sağda paslar.

Yön yalnızca `matchEnd`'de portrait'e döner ve orada **açık bir geçiş** vardır:
"Telefonu dikey çevir" mikro animasyonu, ekran 13'ün tersi. Maç bittiği için
kimse acele etmiyor, bu geçiş rahatsız etmiyor.

Uygulama: yön kilidi `AppDelegate.supportedInterfaceOrientationsFor` üzerinden
`LiveGame.phase`'in türettiği bir değere bağlanır (`UIWindowScene`
`requestGeometryUpdate` ile birlikte). Faz başına ayrı ayrı kilit değiştirmek
iOS'ta en çok görsel hata üreten yer olduğu için **yön yalnızca iki kez değişir:**
oyun girişinde landscape'e, maç sonunda portrait'e.

### Landscape'e çevirebilmeyen kullanıcı

Ekran 13'ün tek ilerleme koşulu cihazın fiziksel olarak yatay gelmesiydi ve
"yatay çeviremiyorum" linki yalnızca **cevap yöntemini** dokunmatiğe çeviriyordu —
yön problemini çözmüyordu. Yatakta oynayan, cihaz yön kilidi açık olan veya motor
kısıtlı kullanıcı için bu bir çıkmaz sokaktı.

Düzeltme: `Yatay çeviremiyorum` seçildiğinde oyun **portrait'te** açılır.
Kelime daha küçük punto ile (Oswald Bold 48–64) ve dokunmatik cevap ile oynanır.
Bu mod tilt kullanmaz, dolayısıyla telefonun alna konması gerekmez — kullanıcı
telefonu elinde tutup ekranı başkasına gösterir. `01` §6'da "motor kısıtlılığı
olan kullanıcı için zorunlu" denen erişilebilirlik yolu ancak böyle tamamlanıyor.

---

## 2. Kesinti politikası

Hiçbir dosyada `scenePhase`, arka plan, gelen çağrı veya ekran kilidi geçmiyordu.
Tek politika:

| Olay | Davranış |
|---|---|
| Uygulama arka plana atıldı (`scenePhase != .active`) | **Otomatik duraklat.** Timer durur, motion güncellemeleri durur, replay kaydı durdurulup o ana kadarki dosya kapatılır (bozuk dosya bırakılmaz) |
| Geri dönüş | Duraklat overlay'i açık gelir. Otomatik devam **yok** — kullanıcı telefonu alnına geri koyacak zamanı olmalı. `DEVAM ET` basınca 3 saniyelik yeni bir geri sayım ve **yeniden kalibrasyon** |
| Gelen çağrı | Arka plan ile aynı yol. Ek olarak `AVCaptureSessionWasInterrupted` dinlenir; kayıt kesilirse tur devam eder ama o turun replay'i "kısmi" işaretlenir |
| Ekran kilitlendi | Arka plan ile aynı |
| Oyun ortasında portrait'e çevirme | Yön kilidi zaten engelliyor; ama kullanıcı fiziksel olarak dikey tutarsa açı nötr banda düşer ve tetik gelmez. 8 saniye tetik gelmezse ekranda ince bir hatırlatma: "Telefonu yatay tut" |
| Düşük Güç Modu (`isLowPowerModeEnabled`) | Replay kaydı **başlatılmaz** (kullanıcıya bir kez bilgi verilir), grain ve projektör huzmesi kapanır, CoreMotion 30 Hz'de kalır (mekanik için zorunlu) |
| Termal `.serious` | Zaten tanımlı (§ `04` §4.1): kayıt durur. Ek olarak sinematik bezemeler kapanır (§ `08` §5) |
| Cihaz depolaması < 200 MB | Replay kaydı başlatılmaz, ayarlarda uyarı satırı. Uygulama içi 20 kayıt / 500 MB kotası **cihazın** boş alanını kontrol etmiyordu |

Genel ilke: **hiçbir kesinti tur sonuçlarını yok etmez.** `04` §3'te kazara çıkış
için onay ekranı koyacak kadar hassas davranılmıştı; sistem kaynaklı kesintiler
için aynı özen geçerli olmalı.

---

## 3. Duraklat ve oyundan çıkış

Duraklat davranışı tanımlıydı ama **akış diyagramında hiç yoktu**, dolayısıyla
oyundan çıkış yolu da modellenmemişti. Oyun akışı `NavigationStack`'in tamamının
yerine render edildiği ve swipe-back kapatıldığı için (§ `02` §5), çıkışın tek
yolu duraklat. Bu yol modellenmezse kullanıcı **oyunda kilitli kalır.**

| Aksiyon | Sonuç |
|---|---|
| `DEVAM ET` | 3 saniyelik geri sayım + yeniden kalibrasyon, sonra `playing` |
| `TURU YENİDEN BAŞLAT` | O turun skoru sıfırlanır, kelime havuzu tazelenir, replay kaydı silinip yeniden başlar. Takım maçında **sadece o tur** yeniden başlar |
| `ÇIKIŞ` | Onay sorulur. Klasik/Hız/Canlandır/Mix: tur iptal, ana ekrana dönüş. **Takım Savaşı: maçın tamamı iptal** — bu onay metninde açıkça yazılır ("Maç iptal edilecek, 3 turun skoru silinecek") |
| Çıkışta replay | O ana kadarki kayıt **silinir**. Yarım tur videosu arşivi kirletiyor |

### Duraklat jestinin iki çakışması

1. `DOKUN` modunda "iki parmakla dokunma" aynı zamanda bir ekran yarısına dokunma
   demek. Çözüm: dokunmatik modda duraklat jesti **yalnızca üstten aşağı
   sürükleme**; iki parmak devre dışı.
2. Tilt modunda duraklatmak için telefonu alından indirmek gerekiyor ve indirme
   hareketi kaçınılmaz olarak 40°'yi geçiyor → duraklatmadan önce **istemsiz bir
   DOĞRU veya PAS** kaydediliyordu. Çözüm: üstten aşağı sürükleme jesti
   başladığı anda motion tetikleri 600 ms kilitlenir. Histerezis ve cooldown gibi
   çok daha ince detaylar düşünülmüşken bu boşluk kalmıştı.

---

## 4. Kelime havuzunun tükenmesi

`Set<String>` ile oturum içi tekrar engelleniyordu ama havuz **bittiğinde** ne
olacağı hiçbir yerde yazılmamıştı. Üç senaryoda kesin olarak biter:

1. **5 kelimelik custom deste + 60 saniyelik tur** — custom destede oynamak için
   minimum 5 kelime yeterli görülmüş, ama bir turda 10–20 kelime geçiliyor.
2. **Uzun takım maçı** — 4 takım × 3 tur = 12 tur, tek destenin ~130 kartı
   tükenir. "Oturum içi tekrar engellenir" kuralı bunu **garanti ediyor**.
3. **Zorluk filtresi** — `ZOR` seçili ve deste ağırlıklı olarak kolay kartlardan
   oluşuyorsa filtrelenmiş havuz çok küçük kalır.

| Durum | Davranış |
|---|---|
| Havuzda kart kaldı ama < 10 | Sessizce devam, uyarı yok |
| Havuz bitti, tur sürüyor | Havuz **yeniden karıştırılıp** açılır; kartlar tekrar gelmeye başlar. Ekranda bir kez ince etiket: `DESTE BAŞA DÖNDÜ` |
| Tur öncesi filtrelenmiş havuz < 20 kart | Tur ön ayarda uyarı: "Bu zorlukta yalnızca 14 kart var. Zorluğu `HEPSİ` yapmak ister misin?" |
| Custom deste < 20 kelime | Editörde bilgi satırı: "60 saniyelik bir turda ~15 kelime geçiyor. En az 20 kelime öneririz." Engel değil, tavsiye |

Ayrıca **custom kartlarda zorluk (`d`) alanı yok** ama zorluk filtresi kartların
`d` alanına göre çalışıyor. Karar: custom kartlar `d = 0` (nötr) alır ve zorluk
filtresinden **muaf** tutulur; filtre yalnızca katalog destelerine uygulanır.

---

## 5. Takım Savaşı — eksik kurallar

Mod tanımlıydı ama sonucu belirleyen kurallar yoktu.

| Konu | Karar |
|---|---|
| Kazanan | En yüksek toplam puan |
| **Beraberlik** | **Ani ölüm turu:** berabere kalan takımlar sırayla 30 saniyelik tek tur oynar, en yüksek doğru sayısı kazanır. Yine berabere ise paylaşımlı zafer — jenerikte iki takım da `BAŞ ROL` olur. Her takım eşit tur oynadığı için beraberlik istatistiksel olarak sık; bu kural olmadan masadaki tartışmayı uygulama çözemez |
| Tur sayısı ayarı | **Takım Kurulumu ekranında** (ekran 11), takım başına 1–5 tur, varsayılan 3. Bu ayarın hangi ekranda olduğu hiçbir yerde yazılmamıştı |
| "Kart sayısı" ayarı | **Kaldırıldı.** Ekran 12'de böyle bir ayar vardı ama hiçbir mekaniğe bağlı değildi — tur yalnızca süre bitince biter. Kodlanacak ama davranışı olmayan bir ayar |
| Oyuncu adları | Takım Kurulumu'nda **opsiyonel** olarak toplanır (boş bırakılabilir). Girilirse `teamHandoff` ekranında "telefonu Ayşe'ye ver" ve jenerikte "EN İYİ CANLANDIRMA — AYŞE" mümkün olur; girilmezse takım adıyla yetinilir. Jenerikteki en gösterişli iki satır bu veriye dayanıyordu ama veri modeli onu üretmiyordu |
| 3–4. takım jenerik rolü | `BAŞ ROL` · `YARDIMCI ROL` · `KONUK OYUNCU` · `FİGÜRAN` |
| `LivePhase.teamHandoff(Int)` | Takım index'i yerine `teamHandoff(nextTeam: Int, nextPlayer: String?)` |

---

## 6. Lokalizasyon ve içerik üretimi bütçesi

§ `07` §8 geliştirmeyi yarım gün hassasiyetinde bütçeliyor (~73.5 gün) ama
adım 15 — "92 deste görseli + içerik doldurma + doğrulama script'i" — süre
hanesinde yalnızca **"paralel iş"** yazıyor. Projenin en büyük kalemi tek
kelimeyle geçilmiş durumda.

Gerçek hacim: 25 dil × ~12.634 dize ≈ **316.000 dize**, artı 31 `adapt` destesi
× 25 dil = **775 kültürel uyarlama turu** (§ `06` §3.2).

| Kalem | Yöntem | Tahmin |
|---|---|---|
| ~450 UI anahtarı × 25 dil | LLM + öncelikli 6 dilde insan gözden geçirme | 4 gün |
| 5 mod adı × 25 dil (transcreation) | **İnsan**, native onaylı | 2 gün |
| 92 başlık + 92 açıklama × 25 dil | LLM + taşma kontrolü (CI #6) | 3 gün |
| 61 `literal` destenin kelimeleri × 25 dil | LLM + CI #3 | 6 gün |
| 31 `adapt` destesi — öncelikli 6 dil | **İnsan/editör**, deste başına ~2 saat | 8 gün |
| 31 `adapt` destesi — kalan 19 dil | v1'de global set ile çıkar, güncellemelerde yerelleşir | v1.1+ |
| 92 deste görseli | Görsel üretim + elden geçirme (§ `01` §5) | 10 gün |
| `fil`, `ms`, `be`, `nl`, `hr` native onayı | **Dış kaynak — tedarik planı gerekiyor** | belirsiz |

**İçerik toplamı ≈ 33 gün.** Geliştirmeyle paralel yürüse bile aynı kişi
yapamaz; bu ayrı bir kaynak. Yayını bloke eden native onay bağımlılığının ise
hâlâ sahibi yok.

Buna bağlı bir çelişki de düzeltilmeli: § `06` §3.4 kontrol listesi "**her dil
için**" `adapt` destelerinde %60 yerel içerik istiyor, ama § `06` §3.2 planı
"kalan diller ilk sürümde global set ile çıkabilir" diyor ve CI #7 eşiği yalnızca
6 dile uyguluyor. Geçerli olan **CI #7**: eşik 6 öncelikli dil için zorunlu,
diğer 19 dil için hedef. Kontrol listesi buna göre okunacak.

---

## 7. Abonelik düşüşü (lapse) ve deneme sonu

`03` §4 deneme kurulumunu iyi tanımlıyordu ama **bittikten sonrasını** hiç
tanımlamıyordu.

| Durum | Davranış |
|---|---|
| Deneme bitmeden 24 saat önce | Yerel bildirim: "Deneme yarın bitiyor" (bildirim izni varsa). Sessiz kesinti şikâyet üretiyor |
| Deneme bitti, ödeme başladı | Değişiklik yok, premium devam |
| Deneme bitti, iptal edildi | Ana ekranda bir kez yumuşak bilgi kartı: "Tam bilet sona erdi. Desteler kilitli ama arşivin ve destelerin yerinde." |
| Billing retry / grace period | RevenueCat entitlement'ı aktif kabul edilir. Kullanıcıyı ödeme sorunu çözülürken cezalandırmıyoruz |
| **3 custom deste → ücretsizde 1 limiti** | Desteler **silinmez**. Hepsi görünür kalır, ilki oynanabilir, diğerleri kilit ikonuyla salt-okunur. Kullanıcının emeğini silmek en hızlı 1 yıldız sebebi |
| **5 kayıtlı Mix** | Aynı mantık: görünür, salt-okunur, oynanamaz |
| **Replay arşivi** | Dosyalar **silinmez**, arşiv salt-okunur olur: izlenebilir, kaydedilebilir, silinebilir; yeni kayıt yapılamaz. Kota ve otomatik temizlik çalışmaya devam eder — yoksa diskte 500 MB sahipsiz kalır |
| Temiz kurulum + ağ yok + gerçek abone | `03` §4 "önceki durumu koru" diyor ama temiz kurulumda önceki durum yok. Paywall'da kalıcı `SATIN ALIMLARI GERİ YÜKLE` butonu + "Bağlantı yokken abonelik doğrulanamıyor" mesajı |

---

## 8. Remote Config için varsayılan değerler

Sezon pencereleri, günlük bedava deste rotasyon havuzu ve social proof anahtarı
Remote Config'ten okunuyor. İlk açılışta ağ yoksa cache boş — sezon penceresi
bilinemez, `SEZON` chip'i ve "ŞİMDİ VİZYONDA" şeridinin ne göstereceği tanımsızdı.

- Her RC anahtarının **bundle içinde varsayılan değeri** olacak
  (`setDefaults(fromPlist:)`). Sezon pencereleri varsayılan plist'te gömülü gelir;
  RC yalnızca **üzerine yazar**.
- `SEZON` chip'i varsayılan pencerelere göre çalışır, RC yoksa da doğru davranır.
- Günlük bedava deste havuzu varsayılanı: v1'in 91 premium destesi.

### Günlük bedava destenin sınır durumları

`dayOfYear % premiumDeckCount` formülünün iki iddiası doğrulanmıyordu:

- **"Herkeste aynı deste" garantisi yok.** `premiumDeckCount` sezon destelerinin
  havuza girip çıkmasıyla, katalog 92'den 124'e büyüdükçe ve eski sürümde kalan
  kullanıcılarda **farklı** oluyor. Düzeltme: formül `dayOfYear % 91` gibi
  **sabit bir bölene** bağlanır ve havuz sırası sürümler arası değişmeyen sabit
  bir listeden okunur. Katalog büyürse liste **sonuna eklenir**, araya girmez.
- **"Sömürülemiyor" doğru değil.** Deterministik ve tarihe bağlı bir formülde
  kullanıcı cihaz saatini değiştirerek **istediği desteyi** açabilir. Kabul
  ediyoruz: maliyeti düşük, sömüren kullanıcı zaten ödemeyecekti, ve sunucu
  gerektirmemesi bu basitliğin karşılığı. Ama dökümanda "sömürülemiyor" diye
  yazmak yanlıştı.
- **Gün ortada dönerse:** açılan deste, o desteyle **oynanan oturum bitene kadar**
  açık kalır. `LiveGame` başlarken destenin kilidi çözülmüş hâli hafızaya alınır;
  tur ortasında paywall açılmaz. Masada 6 kişi varken destenin kilitlenmesi
  yapılabilecek en kötü şey.
- Gün dönümü **cihazın yerel gece yarısı**. Şeritteki geri sayım buna göre.

---

## 9. Kalan küçük düzeltmeler

| Konu | Karar |
|---|---|
| `FAVORİ` butonu var, favori listesi yok | Filtre chip'lerine `FAVORİLER` eklenir (yalnızca en az 1 favori varsa görünür) |
| Hız Turu "rekor kırma" gerekçesi, kalıcı skor yok | `AppSettingsStore`'a `rapidHighScore` eklenir, tur sonu ekranında `YENİ REKOR` şeridi |
| Ana ekran PlayBar'da çoklu seçim ↔ Mix premium | PlayBar'dan 2+ deste ile `OYNA` **Mix'tir** ve ücretsiz kullanıcıda paywall açar. İkinci desteyi seçtiği anda PlayBar'da `MIX · PREMIUM` etiketi görünür, sürprizi baştan haber verir |
| Süre/zorluk iki yerden ayarlanıyor | Ayarlardaki değer **varsayılan**, Tur Ön Ayar'daki değer **o tur için geçerli**. Tur Ön Ayar global ayarı yazmaz |
| `MIX'E EKLE` ücretsiz kullanıcıda | Paywall açar |
| Nasıl Oynanır sayfa 4 | `usesTilt == false` **veya** kullanıcı ayarlardan `DOKUN` seçtiyse gizlenir |
| `howToSeen` Mix modunda tekrar gösteriliyor | Mix, Klasik'in `howToSeen` değerini paylaşır |
| Modal paywall frekansı | Oturum başına en fazla 3 gösterim; sonrasında kilitli deste dokunuşu yalnızca kısa bir toast |
| Prompt öncelik sırası | Aynı oturumda en fazla bir prompt: soft paywall > bildirim izni > puanla bizi. Bildirim prompt'unun 8 saniyesi onboarding kapandıktan sonra başlar |
| Tur sonu düzeltmesi ↔ replay altyazısı | Düzeltme, replay zaman damgalarını da güncellemek zorunda; yoksa kullanıcı "doğru" diye düzelttiği kelimeyi replay'de kırmızı `PAS` damgasıyla görür |
| Replay zaman damgası referansı | **Video saati** (kayıt başlangıcına göre), oyun saati değil. Duraklatmada kayıt da durduğu için ikisi ayrışıyordu |
| `Çıkışta kayıtları sil` | **`Sonraki açılışta sil`** olarak yeniden adlandırıldı. iOS uygulama sonlandırılırken kod çalışacağını garanti etmiyor; verilmiş bir gizlilik sözünü tutmayan ayar, § `04` §4.2'de App Review riski olarak yazılan hatanın aynısı |
| Ücretsiz custom destede `OYNA` | 5 kelime tamamlanınca buton aktif görünür ama paywall açar: "Kendi destenle oynamak Tam Bilet'te." Ayrıca `custom_deck_locked_tap(word_count)` event'i eklenir — gating gerekçesi ancak böyle ölçülebilir |
| Mod Seçimi'nde kilit göstergesi | 4 premium mod kartında sağ üstte bilet ikonu + soluk zemin, kilitli deste kartıyla aynı dil (§ `01` §4) |
| Mix'te 0 deste seçili | `OYNA` disabled + "En az 2 deste seç" |

---

## 10. Eksik analytics event'leri

Funnel onboarding → paywall → satın alma hattını iyi kuruyordu; abonelik yaşam
döngüsü ise tamamen ölçüm dışıydı. 3 günlük denemeye dayanan bir modelde
**deneme → ödeme dönüşümü en önemli tek metrik** ve ölçülemiyordu.

Eklenecekler:

| Event | Parametre |
|---|---|
| `trial_start` | `plan` |
| `trial_convert` / `trial_cancel` | `hours_used`, `rounds_played` |
| `subscription_renew` / `subscription_expire` | `plan`, `months_active` |
| `restore_result` | `success`, `reason` |
| `mode_locked_tap` | `mode` — hangi modun dönüştürdüğü ölçülemiyordu |
| `custom_deck_locked_tap` | `word_count` |
| `paywall_view` | `variant` enum'una `vip_button` ve `manage_subscription` eklenir |
| `daily_free_deck_notification_open` | retention gerekçesinin tek kanıtı |
| `mix_save`, `session_start` | — |
| `word_pool_recycled` | `deck_ids`, `round_index` — havuz tükenmesi gerçekte ne sıklıkta oluyor |
| `notification_permission_result` | `granted` |

---

## 11. Hâlâ karar bekleyen içerik/hukuk konuları

Bunlar düzeltilebilir hatalar değil, **senin kararını** bekleyen riskler.

1. **`dares` (Cesaret) destesi** — doğruluk-cesaret içeriği 12+ için en riskli
   kategori ve editoryal inceleme listesinde hiç yoktu. `partyFlirty` ve
   `bachelor` ile aynı incelemeye alınmalı.
2. **`badHabits` (Kötü Alışkanlıklar) ve `drinks` (İçecekler)** — § `07` §7 yaş
   sınırı satırı "alkol/madde teşviki barındıran kart bulunmuyor" diye **kesin
   beyan** veriyor. Mimikle canlandırılan bir "kötü alışkanlıklar" destesi ve
   kültüre göre uyarlanan bir "içecekler" destesi, hele içerik LLM ile
   üretilirken, bu beyanı tutmanın en zor olduğu iki yer. App Store yaş sınırı
   formunda "Infrequent/Mild Alcohol, Tobacco or Drug References" işaretlenmesi
   gerekebilir.
3. **"Hiçbir istisna yok" ↔ incelenmemiş desteler** — günlük rotasyon "tüm premium
   desteler dahil, hiçbir istisna yok" diyor, ama sonucu bilinmeyen bir editoryal
   incelemeye bağlı üç deste o havuzda. "Bugün Bekarlığa Veda bedava" bildirimi
   çocuğuyla oynayan kullanıcıya gidebilir. İnceleme bitene kadar bu üç deste
   rotasyondan **muaf** tutulmalı.
4. **`pocketCreatures` — "Cep Yaratıkları"** — IP politikası bölümünün kendi
   verdiği örnek politikaya aykırı: Pokémon'un resmî tam adı **Pocket Monsters**,
   yani bu "jenerikleştirme" değil marka adının çevirisi. Başka bir ad gerekiyor.
5. **`06` §3.2'de "Diziler / Netflix"** — içerik talimatı doğrudan bir platformun
   kataloğuna bağlanmış. § `05` §3 bu markayı bilinçli olarak `streaming` /
   *Dizi Platformu Yapımları* diye jenerikleştirmişken, üretim bu tabloya göre
   yapılırsa destenin tamamı tek markanın yapımlarından oluşur ve "rastlantısal
   betimleyici kullanım" gerekçesi çöker.
6. **Marka-yoğun desteler** — IP risk tablosu "bir kartın `Titanic` olması"nı
   düşük risk sayıyor. Ama `brands`, `cars`, `techCompanies`, `socialMedia`
   destelerinin içeriği **%100 tescilli marka**. Bir kartta marka geçmesi ile
   130 kartın 130'unun marka olması aynı risk kategorisi değil; bu desteler için
   ayrı bir gerekçe ya da karar gerekiyor.
7. **Gerçek kişi hakları** — IP politikası yalnızca markayı ve telifli karakteri
   ele alıyor. Ama `actors`, `singers`, `footballers` ve özellikle
   `celebImpressions` (**Ünlü Taklitleri**) destelerinin içeriği tamamen yaşayan
   gerçek kişiler. Ticari bir uygulamada yaşayan kişilerin adıyla "taklit"
   istemek, dökümanın hiç değinmediği bir hak kategorisi (kişilik hakkı / right
   of publicity). En az bir politika satırı gerekiyor: yalnızca kamuya mal olmuş
   meslek kimliği, aşağılayıcı yönlendirme yok, şikâyet üzerine kart kaldırma yolu.
8. **`%80 TASARRUF` sabit metni** — `03` §4 "koda hiçbir fiyat yazılmayacak"
   diyor ama yıllık plan kartında sabit bir tasarruf yüzdesi var. Fiyatlar
   bölgeye göre değiştiği için bu yüzde çalışma zamanında hesaplanmalı; sabit
   yüzde bazı bölgelerde yanlış olur ve fiyat iddiası App Store incelemesinde
   denetlenen bir alan.
9. **ASO 25 dil ≠ 25 store locale** — `CFBundleLocalizations`'a 25 kod yazılabilir
   ama App Store Connect metadata locale listesi aynı değil (Belarusça ve
   Filipince için ayrı store metadata locale'i yok). "25 dilde ASO" planı olduğu
   gibi uygulanamaz; ayrıca `be`, `ca`, `fil`, `hr`, `id`, `ms`, `ro` için ASO
   hipotezi hiç yazılmamış.
10. **Paywall fayda listesi eksik satış** — `Canlandır` modu ve Replay/Film Arşivi
    paywall'da hiç anılmıyor. Replay 7.5 gün geliştirme alıp "viral paylaşım
    motoru" diye gerekçelendirilmişken satış metninde tek satırı yok.

---

## 12. Bu bölümün geliştirme etkisi

| İş | Süre |
|---|---|
| Yön katmanı (faz bazlı kilit + portrait oyun modu) | 2 gün |
| Kesinti politikası (`scenePhase`, çağrı, termal, pil, disk) | 1.5 gün |
| Kelime havuzu tükenmesi + zorluk filtresi sınır durumları | 0.5 gün |
| Takım Savaşı eksik kuralları (beraberlik, tur sayısı, oyuncu adları) | 1.5 gün |
| Abonelik düşüşü davranışları (salt-okunur durumlar) | 1.5 gün |
| RC varsayılanları + günlük deste sınır durumları | 1 gün |
| Kalan küçük düzeltmeler (§9) | 2 gün |
| Ek analytics event'leri | 0.5 gün |

**Toplam +11 gün.** Geliştirme ~62.5 günden **~73.5 güne** çıkıyor.

Bu artış kötü haber gibi görünüyor ama aslında tersi: bu 11 gün zaten
harcanacaktı — fark, şimdi planlı mı yoksa geliştirme sırasında "bir de bunu
düşünmemiştik" diye mi harcanacağı. Sınır durumları sonradan eklenince mimariye
yamayla giriyor; baştan bilinince faz makinesinin parçası oluyor.
