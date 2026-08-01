"""Bir bölümün şeffaf kapaklarını kart zemini üstünde yan yana dizip tek JPEG üretir."""

import json
import sys
from pathlib import Path

from PIL import Image

KOK = Path(__file__).parent
SEFFAF = KOK.parent / "teslim" / "deste-kapaklari"
QC = KOK / "_qc"

KART_ZEMIN = (71, 26, 34)
HUCRE = 320
KAPAK = 260
SUTUN = 4


def main(bolum_anahtar: str, cikti_adi: str) -> None:
    desteler = json.loads((KOK / "desteler.json").read_text())
    secilen = [
        d
        for d in desteler
        if d.get("v1") and bolum_anahtar.lower() in d["bolum"].lower()
    ]
    if not secilen:
        raise SystemExit(f"'{bolum_anahtar}' bölümünde v1 destesi bulunamadı")

    satir = (len(secilen) + SUTUN - 1) // SUTUN
    tuval = Image.new("RGB", (SUTUN * HUCRE, satir * HUCRE), (20, 12, 14))

    for i, d in enumerate(secilen):
        yol = SEFFAF / f"deck_{d['id']}.png"
        kart = Image.new("RGB", (HUCRE - 24, HUCRE - 24), KART_ZEMIN)
        if yol.exists():
            amblem = Image.open(yol).convert("RGBA").resize((KAPAK, KAPAK), Image.LANCZOS)
            pay = ((HUCRE - 24) - KAPAK) // 2
            kart.paste(amblem, (pay, pay), amblem)
        tuval.paste(kart, ((i % SUTUN) * HUCRE + 12, (i // SUTUN) * HUCRE + 12))

    QC.mkdir(exist_ok=True)
    hedef = QC / cikti_adi
    tuval.save(hedef, quality=92)
    print(f"{hedef} — {len(secilen)} kapak")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
