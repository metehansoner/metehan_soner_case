# Kelime bankası

Kaynak: `Imposter/Resources/WordBank/words.json`

- 16 kategori × **20** kelime = **320** giriş
- Her giriş: `word` + `hint` (ilişkili, kısa impostor ipucu — örn. Neymar → Brezilya)
- Yerelleştirme: uygulamanın desteklediği **25 dil**
- Runtime: `WordBank.randomWord` — aktif dil + session `usedSecretWordKeys` ile turlar arası tekrar etmez
- Kelime bitince pool yenilenir
