# Imposter Party — Ayarlar Ekranı

> Palet: Vivid Ocean (`02_renk_paleti.md`)  
> Tipografi: Fredoka / Nunito (`03_tipografi_ve_haptics.md`)  
> Referans UX: Fakeit bottom sheet — görsel kimlik ayrı

---

## 1. Erişim

| Nokta | Davranış |
|-------|----------|
| Ana menü | Sağ üst **dişli** ikonu |
| Kategoriler / oyun ayarları header | Aynı dişli (tutarlı) |
| Açılış | Altından kayan **bottom sheet** (tam sayfa push değil) |
| Kapatma | “Kapat” butonu · sheet dışına tap · aşağı swipe |

Haptic: sheet açılışında **Light**.

---

## 2. Ayarlar sheet — layout

```
┌─────────────────────────────────┐
│     (dimmed ana menü arkada)    │
│  ┌───────────────────────────┐  │
│  │      Settings             │  │  ← title centered, Nunito/Fredoka Bold white
│  │                           │  │
│  │  Language            🌐 › │  │
│  │  Contact us          ✉ ›  │  │
│  │  Privacy             🛡 ›  │  │
│  │  Terms of use        📄 ›  │  │
│  │  Vibration        [ ON ]  │  │  ← pill toggle Kapalı|Açık
│  │                           │  │
│  │  User ID: xxxxxxxx-….     │  │  ← caption, long-press copy
│  │                           │  │
│  │  [        Close         ] │  │  ← primary dark/cyan-border pill
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### Görsel token’lar

| Eleman | Stil |
|--------|------|
| Sheet BG | `grad.screen` veya `#123A7A → #0B1F4A` · üst köşe radius ~28–32 |
| Başlık | `text.primary` · `type.title` |
| Satır metin | Beyaz · Nunito SemiBold 17 |
| Satır ikon | Beyaz outline · sağda chevron (toggle satırında chevron yok) |
| Ayırıcı | İnce `#2A5BB8` @ 30% veya sadece spacing |
| Scrim | `overlay.scrim` |
| Close butonu | `btn.primary` beyaz metin koyu **veya** `surface.card` + cyan border + beyaz metin |

### Satır listesi (sıra sabit)

| # | Key | Aksiyon |
|---|-----|---------|
| 1 | `settings.language` | → Dil sheet |
| 2 | `settings.contact` | `mailto:` destek adresi |
| 3 | `settings.privacy` | URL (Safari / in-app browser) |
| 4 | `settings.terms` | URL |
| 5 | `settings.vibration` | Toggle · persist |
| — | `settings.userId` | UUID göster · long-press kopyala + Light haptic |
| 6 | `common.close` | Sheet kapat |

---

## 3. Titreşim satırı

```
  Vibration          [ Off | On ]
                       └── seçili: beyaz pill, koyu yazı
                           seçili değil: transparan, beyaz yazı
```

- Varsayılan: **On**
- Persist: `UserDefaults` / SharedPreferences `hapticsEnabled`
- Kapalıysa tüm haptics no-op (`03_tipografi_ve_haptics.md`)

---

## 4. Dil sheet

Ayarlar → Language ile açılır (aynı tip bottom sheet, üzerine stack veya replace).

```
┌───────────────────────────┐
│         Language          │
│                           │
│  English              ✓   │  ← aktif dil check (cyan)
│  Türkçe                   │
│  Русский                  │
│  Español                  │
│  Português                │
│  Deutsch                  │
│  Français                 │
│  Italiano                 │
│  Ελληνικά                 │
│  Română                   │
│  Nederlands               │
│  Polski                   │
│                           │
│  [        Back          ] │
└───────────────────────────┘
```

### Dil listesi (gösterim adı = `meta.languageName`)

| Kod | Sıra |
|-----|------|
| en, tr, ru, es, pt, de, fr, it, el, ro, nl, pl | Yukarıdaki gibi |

### Davranış

1. Satıra tap → dil hemen uygulanır (UI string’leri yenilenir)  
2. Persist: `languageOverride = "tr"` vb.  
3. Override silinmez; kullanıcı “sistem dili”ne dönmek isterse ileride eklenebilir — **v1’de yok**  
4. İlk açılışta override yoksa: cihaz dili destekleniyorsa o, değilse `en`  
5. Checkmark: `accent.cyan`  
6. Back → Ayarlar sheet’ine dön  

Haptic: dil seçiminde **Medium**.

---

## 5. Info (i) butonu — ayarlar değil

Header’daki **i** ayarlar sheet’i açmaz.

| Durum | Davranış |
|-------|----------|
| Ana menü / ilk kez | 4 adımlı tutorial modal (zaten tanımlı) |
| Oyun içinde | `round.howToTitle` modal |

---

## 6. Persist özeti

| Anahtar | Tip | Varsayılan |
|---------|-----|------------|
| `hapticsEnabled` | Bool | `true` |
| `languageOverride` | String? | `null` → sistem / en |
| `userId` | UUID string | ilk açılışta üret, kalıcı |
| `onboardingDone` | Bool | false |
| `lastGameMode` | classic \| drawing | classic |

---

## 7. Dış linkler (placeholder)

| Madde | v1 hedef |
|-------|----------|
| Contact | `mailto:support@imposterparty.app` (domain sonra) |
| Privacy | `https://…/privacy` |
| Terms | `https://…/terms` |

---

## 8. Wireframe notu (kod)

- Component: `SettingsSheet` + `LanguageSheet`
- Presentation: modal bottom sheet, detent ~%65–75
- Satırlar: `SettingsRow` (title, trailing icon/chevron/toggle)
- Lokalizasyon key’leri hazır (`settings.*`, `common.close`)

---

## 9. Onay checklist

- [x] Bottom sheet (tam sayfa değil)
- [x] 5 satır + User ID + Close
- [x] Titreşim toggle
- [x] 12 dilli Language sheet
- [x] Vivid Ocean token’ları
- [x] Görsel mockup — `screens/settings_preview.png` · `screens/settings_language_preview.png`

---

*Imposter Party · 2026-07-25*
