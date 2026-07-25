# Kelime bankası

Kaynak: `Imposter/Resources/WordBank/words.json`

- 16 kategori × 12 kelime = 192 giriş
- Her giriş: `word` + `hint` (kısa impostor ipucu)
- Yerelleştirme: uygulamanın desteklediği **25 dil** (`LocalizationManager.supportedLocales` ile aynı)
- Runtime: `WordBank.randomWord` — aktif uygulama diline göre seçer; yoksa `en`’e düşer
- Not: Marka / ünlü / karakter özel adları çoğu dilde orijinal bırakılabilir
