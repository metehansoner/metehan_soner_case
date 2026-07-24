# Imposter Party — Görsel Üretim Brief

> Stil referansı (mantık): clay / soft plastic 3D, yuvarlak formlar, yumuşak gölge  
> Maskot referansı: `screens/app_icon.png` + `screens/palette_preview_home_vivid.png` tilkisi  
> Oyuncu reveal referansı (layout): `ornek_uygulma_resimleri/IMG_4926 2.PNG` — **kopyalama yok**, özgün karakterler  
> Palet: Vivid Ocean (`02_renk_paleti.md`)

---

## 1. Ortak stil kuralları (tüm asset’ler)

| Kural | Detay |
|-------|--------|
| Render | 3D clay / toy, yumuşak specular, temiz kenar |
| Oran | Şeffaf PNG veya solid BG’li full-bleed (türe göre) |
| Yasak | Fakeit hırsız, uzun boyun limonata adamı, 4 kollu şef, yaylı gövde çocuk birebir kopya |
| Yasak renk | Kırmızı-pembe-magenta ekran BG’leri (Fakeit) |
| Tutarlılık | Aynı “oyuncak dünya” — tilki ile aynı kalite |

Kayıt kökü: `project_dkuman/screens/assets/`

```
assets/
  brand/
    app_icon.png
    mascot_fox.png
  modes/
    classic_imposter.png
    drawing_mode.png
  categories/
    party.png
    football.png
    ...
  players/
    player_01.png … player_15.png
    (her biri solid renkli BG’li full-bleed karakter)
```

---

## 2. Ana menü — mod kartları

### Klasik Imposter — `modes/classic_imposter.png`

| | |
|--|--|
| Konu | Maskot tilki: şapka veya kapüşon + göz maskesi, “şşş” jesti, dairesel portal’dan bakış |
| BG | Transparent veya koyu navy daire portal |
| Aksan | Cyan glow, sarı spark |
| Kullanım | Ana menü sol/sağ kart illüstrasyonu |

### Çizim modu — `modes/drawing_mode.png`

| | |
|--|--|
| Konu | Spiral defter + sevimli hayvan çizimi (rakun / baykuş — tilki değil) + cyan kalem + sarı silgi |
| Stil | Aynı clay 3D |
| Kullanım | Çizim modu kartı |

**Prompt iskeleti (mod):**  
`3D clay toy render, soft lighting, Imposter Party game asset, [SUBJECT], vivid cyan and cobalt accents, no text, no watermark, centered, high detail`

---

## 3. Kategori kartları — `categories/*.png`

Her kategori: **sağ tarafa oturan 2–3 obje kümesi**, clay 3D, şeffaf veya hafif gölge.

| Dosya | Kategori | Özgün obje önerisi (Fakeit’ten farklı) |
|-------|----------|----------------------------------------|
| `party.png` | Parti zamanı | Konfeti patlatıcı + neon parti gözlüğü + cupcake |
| `football.png` | Futbol | Stadyum düdüğü + sarı-kırmızı kart + krampon (top+kupa Fakeit’ten kaçın veya farklı açı/renk) |
| `food.png` | Yemek | Pizza dilimi + bubble tea (sushi/matcha kopyası değil) |
| `celebs.png` | Ünlüler | Spotlight + mikrofon standı + altın yıldız |
| `hobbies.png` | Hobiler | Kamera + gamepad + fırça |
| `family.png` | Aile | Aile fotoğraf çerçevesi + sıcak lamba (kalpli ev kopyası değil) |
| `education.png` | Eğitim | Mezuniyet kepi + kitap yığını (sarı otobüs değil) |
| `nature.png` | Doğa | Kamp çadırı + pusula + çam kozalağı |
| `characters.png` | Karakterler | Robot + büyücü şapkası (ejderha+prenses kopyası değil) |
| `jobs.png` | Meslekler | Laptop + kask + stetoskop (farklı kompozisyon) |
| `hollywood.png` | Hollywood | Clapper + popcorn kutusu |
| `brands.png` | Markalar | Alışveriş çantası + kulaklık |
| `places.png` | Yerler | Eyfel + piramit (Colosseum+Liberty birebir yok) |
| `animals.png` | Hayvanlar | Kedi + aslan yavrusu (papağan+shiba birebir yok) |
| `sports.png` | Sporlar | Basketbol + tenis raketi |
| `newyear.png` | Yılbaşı | Hediye kutusu + yılbaşı şapkası + kar tanesi |

Kart UI: sol metin (lokalize) · sağ bu PNG · kilit ikonu ayrı UI.

---

## 4. Oyuncu karakterleri — min. 15

**Amaç:** Rol dağıtımı / oylama / sonuç — her oyuncuya 1 karakter + solid renkli arka plan.

**Layout referansı (IMG_4926 mantığı):**

```
┌─────────────────────────┐
│  ←     {PlayerName}     │
│                         │
│     [ 3D karakter ]     │
│     (renkli solid BG)   │
│                         │
│  Swipe up to see word   │
│           ^             │
└─────────────────────────┘
```

### Stil

- Clay 3D, abartılı sevimli / absürt parti karakterleri
- Her karakter **farklı siluet** (tilki maskot ile karışmasın — tilki marka; oyuncular ayrı cast)
- Full-bleed PNG: karakter + **solid BG rengi** gömülü (veya karakter transparent + kodda BG)

### 15 karakter brief

| ID | Karakter konsepti | BG hex (Vivid / canlı) |
|----|-------------------|-------------------------|
| `player_01` | Teleskop gözlüklü uzay tilkisi yavrusu (maskotsuz) | `#1A6FE8` |
| `player_02` | Balon hayvan çeviren soytarı ayı | `#12C4C8` |
| `player_03` | DJ kulaklıklı penguen | `#0B3D4A` |
| `player_04` | Sualtı maskeli yüzen kedi | `#2B6CFF` |
| `player_05` | Pizza kuryesi robot | `#FFE566` (metin koyu) |
| `player_06` | Kaykaycı kirpi | `#F08A3A` |
| `player_07` | Mikrofonlu star kuş | `#7B5CFF` |
| `player_08` | Şef şapkalı su samuru | `#00B894` |
| `player_09` | Dedektif pelerinli baykuş | `#123A7A` |
| `player_10` | Confetti topu tutan tavşan | `#FF6B9D` |
| `player_11` | Astronot kurbağa | `#00E5FF` (metin koyu) |
| `player_12` | Spor bandajlı kurt | `#E17055` |
| `player_13` | Sihirli kitaplı tilki yavrusu (maskesiz) | `#6C5CE7` |
| `player_14` | Buz kreması külahlı panda | `#81ECEC` (metin koyu) |
| `player_15` | Neon gözlüklü bukalemun | `#0984E3` |

> Not: BG’lerde canlı solid renkler kullanılır (örnekteki turuncu ekran mantığı). Fakeit turuncusu zorunlu değil; çeşitlilik şart. Açık BG’lerde `text.onLight`.

### Atama mantığı

- Oyuncu index `i` → `player_{(i % 15) + 1}`
- Aynı partide 15’e kadar unique; 15’ten fazla olmaz (max 15 oyuncu)

### Prompt iskeleti (oyuncu)

`Full-bleed mobile game character screen asset, 3D clay toy style soft plastic, [CHARACTER], solid flat background color [HEX], centered full body or 3/4, playful expression, no UI text, no watermark, Imposter Party art style matching masked fox mascot quality`

---

## 5. Diğer görseller

| Asset | Açıklama |
|-------|----------|
| `brand/mascot_fox.png` | Rate Us, paywall, onboarding — şapkalı maskeli tilki |
| Onboarding sahneleri | 3 sahne; tilki + parti cast; Vivid Ocean BG |
| Impostor rol ikonu | Küçük: maske + şapka siluet (cyan/kırmızı durum değil, marka cyan) |

---

## 6. Üretim sırası — checklist

| Batch | İçerik | Durum |
|-------|--------|--------|
| 1 | Mod kartları (2) | ✅ `assets/modes/` |
| 2 | 15 oyuncu karakteri | ✅ `assets/players/` |
| 3 | 16 kategori ikonu | ✅ `assets/categories/` |
| 4 | Onboarding / paywall / rate-us sahneleri | ⏳ Sonra |

---

*Imposter Party · 2026-07-25 · görseller üretildi*
