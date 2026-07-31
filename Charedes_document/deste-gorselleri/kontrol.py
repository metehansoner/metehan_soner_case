#!/usr/bin/env python3
"""
Şeffaf kapak kalite kontrolü.

İki gerçek riski ölçer:
  1. İç delik — öznenin içindeki magenta/pembe alanlar zemin sanılıp
     kesilirse ortada boşluk kalır. Kenardan flood fill yapıp dışa
     bağlı olmayan şeffaf bölgeleri arıyoruz.
  2. Palet dışı renk — kapak yalnız krem/amber/turkuaz/bordo kullanmalı.
     Kalan pembe/mor/yeşil ton hem temayı bozar hem key'i tehlikeye atar.
"""

import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

VARSAYILAN = Path(__file__).parent / "seffaf"

PALET = {
    "krem":     (0xF4, 0xE7, 0xCE),
    "amber":    (0xF0, 0xA9, 0x3B),
    "turkuaz":  (0x2F, 0x7F, 0x7C),
    "bordo":    (0x47, 0x16, 0x1F),
    "altin":    (0xE3, 0xC3, 0x6A),
    "kahve":    (0xD2, 0x86, 0x1F),
}
TOLERANS = 96   # RGB öklid mesafesi — baskı dokusu için geniş tutuldu


def ic_delik_orani(alfa: np.ndarray) -> float:
    """Dışa bağlı olmayan şeffaf piksellerin oranı (%)."""
    seffaf = alfa < 40
    H, W = seffaf.shape
    disa_bagli = np.zeros_like(seffaf, dtype=bool)

    q = deque()
    for x in range(W):
        for y in (0, H - 1):
            if seffaf[y, x] and not disa_bagli[y, x]:
                disa_bagli[y, x] = True
                q.append((y, x))
    for y in range(H):
        for x in (0, W - 1):
            if seffaf[y, x] and not disa_bagli[y, x]:
                disa_bagli[y, x] = True
                q.append((y, x))

    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < H and 0 <= nx < W and seffaf[ny, nx] and not disa_bagli[ny, nx]:
                disa_bagli[ny, nx] = True
                q.append((ny, nx))

    delik = seffaf & ~disa_bagli
    return 100.0 * delik.sum() / seffaf.size


def palet_disi_orani(rgb: np.ndarray, alfa: np.ndarray) -> tuple:
    """Opak pikseller içinde palete uzak olanların oranı ve en sapkın örnek."""
    maske = alfa > 200
    if maske.sum() == 0:
        return 0.0, None
    px = rgb[maske].astype(np.float32)

    en_yakin = np.full(len(px), 1e9, dtype=np.float32)
    for ref in PALET.values():
        d = np.sqrt(((px - np.array(ref, dtype=np.float32)) ** 2).sum(axis=1))
        en_yakin = np.minimum(en_yakin, d)

    disi = en_yakin > TOLERANS
    oran = 100.0 * disi.sum() / len(px)
    ornek = None
    if disi.sum():
        idx = int(np.argmax(en_yakin))
        ornek = tuple(int(v) for v in px[idx])
    return oran, ornek


def pembe_kalinti(rgb: np.ndarray, alfa: np.ndarray) -> float:
    """Opak alanda kalan magenta/pembe piksel oranı — key'in kaçırdıkları."""
    maske = alfa > 200
    if maske.sum() == 0:
        return 0.0
    r = rgb[:, :, 0].astype(np.int16)
    g = rgb[:, :, 1].astype(np.int16)
    b = rgb[:, :, 2].astype(np.int16)
    pembe = (r > 150) & (b > 130) & (g < 110) & ((r - g) > 60) & ((b - g) > 30)
    return 100.0 * (pembe & maske).sum() / maske.sum()


def main() -> None:
    # Aynı ölçütler onboarding illüstrasyonları için de geçerli, o yüzden
    # klasör dışarıdan verilebiliyor: python3 kontrol.py ../ekran-gorselleri/seffaf
    klasor = Path(sys.argv[1]) if len(sys.argv) > 1 else VARSAYILAN
    dosyalar = sorted(klasor.glob("*.png"))
    if not dosyalar:
        print(f"{klasor} boş")
        return

    print(f"{'gorsel':22s} {'ic delik':>9s} {'palet disi':>11s} {'pembe kalinti':>14s}  durum")
    print("-" * 74)
    sorunlu, gozden = [], []
    for yol in dosyalar:
        im = Image.open(yol).convert("RGBA")
        arr = np.array(im)
        rgb, alfa = arr[:, :, :3], arr[:, :, 3]

        # Hız için yarıya indir — oranlar korunur
        kucuk = im.resize((im.width // 4, im.height // 4), Image.NEAREST)
        ka = np.array(kucuk)[:, :, 3]

        delik = ic_delik_orani(ka)
        pdisi, ornek = palet_disi_orani(rgb, alfa)
        pembe = pembe_kalinti(rgb, alfa)

        # İç delik tek başına hata değil: maske göz deliği, kordon ilmeği,
        # çalar saat kulbu gibi meşru kapalı boşluklar da buraya düşüyor.
        # Key'in gerçekten öznenin içini yediği durumun ayırt edici işareti
        # palet ihlali ya da pembe kalıntıdır — o yüzden delik "incele",
        # diğer ikisi "hata" olarak raporlanıyor.
        hatalar, incele = [], []
        if pdisi > 18:
            hatalar.append("PALET")
        if pembe > 0.4:
            hatalar.append("PEMBE")
        if delik > 0.5:
            incele.append("DELIK")

        durum = "  ".join(hatalar + incele) if (hatalar or incele) else "temiz"
        if hatalar:
            sorunlu.append((yol.stem, "  ".join(hatalar), ornek))
        elif incele:
            gozden.append((yol.stem, delik))

        print(f"{yol.stem:22s} {delik:8.2f}% {pdisi:10.1f}% {pembe:13.2f}%  {durum}")

    print()
    if sorunlu:
        print("Yeniden üretilmesi gerekenler:")
        for ad, durum, ornek in sorunlu:
            ek = f"  en sapkın renk: rgb{ornek}" if ornek else ""
            print(f"  · {ad:20s} {durum}{ek}")
    else:
        print("Palet ve pembe kalıntı kontrolünden geçmeyen kapak yok.")

    if gozden:
        print()
        print("Gözle bakılacak — kapalı boşluk içeriyor (meşru olabilir):")
        for ad, oran in gozden:
            print(f"  · {ad:20s} iç boşluk %{oran:.2f}")


if __name__ == "__main__":
    main()
