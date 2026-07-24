# Sonra yapılacaklar (backlog)

> v1 çekirdek akış tamam (Faz 0–7). Aşağıdakiler bilinçli olarak ertelendi — release / polish turunda yapılır.

---

## Monetizasyon

- [ ] Gerçek **StoreKit 2** ürünleri (trial / weekly / yearly product ID’ler)
- [ ] `SubscriptionStore.purchaseSelectedPlan` mock’unu kaldır → `Product.purchase`
- [ ] `restore` → `Transaction.currentEntitlements` ile `isPremium` doğrula
- [ ] Paywall fiyatlarını App Store’dan çek (şimdilik hardcoded ₺)
- [ ] App Store Connect: abonelik grubu, intro offer, sandbox test

## Kelime bankası

- [ ] Kalan **10 dil** için kelime + ipucu çevirisi (`words.json`: de, es, fr, it, pt, ru, nl, pl, el, ro)
- [ ] İsteğe bağlı: kategori başına daha fazla kelime (12 → 20+)
- [ ] Kullanılmış kelimeleri turlar arası tekrar etmeme (session pool)

## Oyun mekaniği (opsiyonel / polish)

- [ ] Imposter’ın kelimeyi **tahmin ederek anında kazanması** (dokümanda opsiyonel)
- [ ] Sonuç öncesi **“Moment of Truth”** dramatik geçiş ekranı
- [ ] Çizim modu çıkış / pause / oy akışı ince ayar
- [ ] Mystery Twist oranlarını ayardan veya sabit tabloya bağlama (şimdi ~%70 rastgele)

## Ürün / App Store

- [ ] Privacy & Terms URL’lerini canlı sayfalarla değiştir (`imposterparty.app/...` placeholder)
- [ ] Destek e-postası doğrula (`support@imposterparty.app`)
- [ ] App Store ekran görüntüleri + açıklama (ASO, 12 dil metadata)
- [ ] App ikon tüm boyutları / marketing asset kontrolü

## Teknik borç

- [x] Asset imageset: PNG’ler yanlış `1x` kayıtlıydı → **single-scale universal** yapıldı (keskinlik)
- [ ] Xcode uyarısı: `App-Info.plist` Copy Bundle Resources’tan çıkarılmalı
- [ ] Settings / HowTo metinlerini oyun içi kurallarla birleştirme
- [ ] Gerçek cihaz + TestFlight smoke test (onboarding → paywall → klasik → çizim → rate)

## Görseller

- [x] Clay PNG’lerden düz renk BG kaldırıldı (şeffaf alpha) — kutu/sticker hissi giderildi
- [ ] **SVG yapılmaz** — clay 3D karakter/kategori asset’leri raster kalır
- [ ] İleride sadece düz UI ikonları (yıldız, spark, tab ikon) SVG/PDF vektör olabilir
- [ ] İsteğe bağlı: profesyonel rembg / yeniden üretim (daha temiz kenar)

---

**Not:** Bu liste tamamlanmadan da dahili Play / demo yapılabilir; App Store yayını öncesi özellikle StoreKit + yasal linkler kritik.
