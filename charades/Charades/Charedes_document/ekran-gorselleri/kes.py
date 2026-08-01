#!/usr/bin/env python3
"""
Onboarding / Nasıl Oynanır illüstrasyonlarını magenta zeminden keser.

Chroma-key matematiği deste kapağı hattıyla aynı (`deste-gorselleri/pipeline.py`
içindeki `magenta_kes`); tek fark tuval. Kapaklar kare, bu illüstrasyonlar yatay
4:3 — sahnede iki taraf var ve kareye sıkıştırılınca figürler küçülüyor.

Kullanım:
    python3 kes.py
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

KOK = Path(__file__).parent
sys.path.insert(0, str(KOK.parent / "deste-gorselleri"))
from pipeline import magenta_kes  # noqa: E402

HAM = KOK / "ham"
SEFFAF = KOK.parent / "teslim" / "ekran-gorselleri"

HEDEF_EN = 1536      # 4:3 → 1536×1152, @3x kullanımda fazlasıyla yeterli
HEDEF_BOY = 1152
KENAR_PAY = 0.04


def orana_otur(im: Image.Image) -> Image.Image:
    """İçeriği kırpar, 4:3 tuvale nefes payıyla ortalar."""
    a = np.array(im)[:, :, 3]
    ys, xs = np.where(a > 20)
    if len(xs) == 0:
        raise ValueError("kesimden sonra opak piksel kalmadı")

    kirpik = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))

    # İçerik, kenar payı düşülmüş kutuya sığacak şekilde ölçekleniyor.
    ic_en = int(HEDEF_EN * (1 - 2 * KENAR_PAY))
    ic_boy = int(HEDEF_BOY * (1 - 2 * KENAR_PAY))
    olcek = min(ic_en / kirpik.width, ic_boy / kirpik.height)
    yeni = (max(1, round(kirpik.width * olcek)), max(1, round(kirpik.height * olcek)))
    kirpik = kirpik.resize(yeni, Image.LANCZOS)

    tuval = Image.new("RGBA", (HEDEF_EN, HEDEF_BOY), (0, 0, 0, 0))
    tuval.paste(kirpik, ((HEDEF_EN - yeni[0]) // 2, (HEDEF_BOY - yeni[1]) // 2))
    return tuval


def main() -> None:
    SEFFAF.mkdir(parents=True, exist_ok=True)
    hamlar = sorted(HAM.glob("*.png"))
    if not hamlar:
        print("ham/ boş")
        return

    for yol in hamlar:
        kesik = orana_otur(magenta_kes(Image.open(yol)))
        hedef = SEFFAF / yol.name
        kesik.save(hedef)

        a = np.array(kesik)[:, :, 3].flatten()
        n = len(a)
        opak = 100 * float(np.sum(a >= 254)) / n
        seffaf = 100 * float(np.sum(a <= 1)) / n
        kenar = 100 * float(np.sum((a > 1) & (a < 254))) / n
        print(
            f"{yol.stem:16s} opak %{opak:<5.1f} şeffaf %{seffaf:<5.1f} "
            f"kenar %{kenar:<5.2f} {hedef.stat().st_size // 1024} KB"
        )


if __name__ == "__main__":
    main()
