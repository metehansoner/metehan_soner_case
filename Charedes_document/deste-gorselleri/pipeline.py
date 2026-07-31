#!/usr/bin/env python3
"""
Şeffaf deste kapağı üretim hattı.

Görsel üretici gerçek alfa kanalı vermediği için (şeffaflık isteyince
satranç desenini boyayarak taklit ediyor), kapaklar paletimizde bulunmayan
düz magenta #FF00FF zeminle üretilip burada programatik olarak kesiliyor.

Kullanım:
    python3 pipeline.py kes            # ham/*.png -> seffaf/*.png
    python3 pipeline.py onizleme       # kapaklar.html üret
    python3 pipeline.py hepsi
"""

import json
import sys
from html import escape
from pathlib import Path

import numpy as np
from PIL import Image

KOK = Path(__file__).parent
HAM = KOK / "ham"
SEFFAF = KOK / "seffaf"
KATALOG = KOK / "desteler.json"
CIKTI_HTML = KOK.parent / "kapaklar.html"

HEDEF_BOYUT = 1024   # kare şeffaf sanat eseri
KENAR_PAY = 0.04     # içerik etrafında oranlı nefes payı
V1_TOPLAM = 92       # 05-desteler-ve-kategoriler.md § bölüm özeti


# ── Chroma key ────────────────────────────────────────────────────────
SPILL_TABAN = 12.0    # bordo outline'ın küçük doğal taşmasını yok say


def zemin_olc(arr: np.ndarray, ring: int = 10) -> np.ndarray:
    """
    Zemin rengini görselin kenar şeridinden ölçer.

    Üretici her seferinde tam #FF00FF vermiyor — biraz kayıyor. Sabit
    zemin varsaymak alfanın tam sıfıra inmemesine yol açıyordu, o yüzden
    her dosya için zemin kenardan okunuyor.
    """
    ust = arr[:ring, :, :3].reshape(-1, 3)
    alt = arr[-ring:, :, :3].reshape(-1, 3)
    sol = arr[:, :ring, :3].reshape(-1, 3)
    sag = arr[:, -ring:, :3].reshape(-1, 3)
    return np.median(np.vstack([ust, alt, sol, sag]), axis=0)


def magenta_kes(im: Image.Image) -> Image.Image:
    """
    Düz magenta zemini gerçek alfa kanalına çevirir.

    Gözlenen piksel C = A·F + (1−A)·B. Zemin B kenardan ölçülüyor ve özne
    opak olduğu için alfayı magenta taşmasından türetip F'yi unpremultiply
    ile geri kazanıyoruz. Kaba despill (R ve B'den sabit çıkarma) ince
    ışınları soğutup grileştiriyordu — bu yol tonu koruyor.
    """
    arr = np.array(im.convert("RGBA")).astype(np.float32)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]

    zemin = zemin_olc(arr)
    # Taşma ölçütü magenta ekseninde büyür; palet renklerinde G baskın
    # olduğu için negatife düşer. Ölçek zeminin kendi taşmasından geliyor.
    spill_zemin = float(min(zemin[0], zemin[2]) - zemin[1])
    if spill_zemin < 40:
        raise ValueError(f"kenarda magenta zemin bulunamadı (ölçülen {zemin})")

    spill = np.clip(np.minimum(r, b) - g - SPILL_TABAN, 0.0, None)
    alfa_ham = np.clip(1.0 - spill / max(spill_zemin - SPILL_TABAN, 1.0), 0.0, 1.0)
    ZEMIN = zemin

    # Unpremultiply ham alfa ile yapılıyor — rengi en doğru o veriyor.
    a3 = alfa_ham[:, :, None]
    c = arr[:, :, :3]
    guvenli = np.maximum(a3, 1e-3)
    f = np.clip((c - (1.0 - a3) * ZEMIN) / guvenli, 0.0, 255.0)

    # Alfa seviyeleri: magenta zeminde hafif üretim gürültüsü var, bu yüzden
    # zemin tam 0'a inmiyordu. Alt eşiğin altını sıfıra, üst eşiğin üstünü
    # bire çekiyoruz; arada kalan ince ışın kenarları yumuşak kalıyor.
    ALT, UST = 0.10, 0.90
    alfa = np.clip((alfa_ham - ALT) / (UST - ALT), 0.0, 1.0)

    # Tamamen şeffaf yerlerde renk anlamsız — komşu kirlenmesini önlemek için sıfırla
    f = np.where(alfa[:, :, None] < 0.004, 0.0, f)

    out = np.dstack([f, alfa * 255.0])
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def kareye_otur(im: Image.Image) -> Image.Image:
    """İçeriği kırpar, ortalar, kare tuvale oturtur, hedef boyuta ölçekler."""
    a = np.array(im)[:, :, 3]
    ys, xs = np.where(a > 20)
    if len(xs) == 0:
        return im.resize((HEDEF_BOYUT, HEDEF_BOYUT), Image.LANCZOS)

    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    kirpik = im.crop((x0, y0, x1 + 1, y1 + 1))

    kenar = int(max(kirpik.size) * KENAR_PAY)
    yan = max(kirpik.size) + kenar * 2
    tuval = Image.new("RGBA", (yan, yan), (0, 0, 0, 0))
    tuval.paste(
        kirpik,
        ((yan - kirpik.width) // 2, (yan - kirpik.height) // 2),
    )
    return tuval.resize((HEDEF_BOYUT, HEDEF_BOYUT), Image.LANCZOS)


def rapor(im: Image.Image) -> dict:
    a = np.array(im)[:, :, 3].flatten()
    n = len(a)
    return {
        "opak": round(100 * float(np.sum(a >= 254)) / n, 1),
        "seffaf": round(100 * float(np.sum(a <= 1)) / n, 1),
        "kenar": round(100 * float(np.sum((a > 1) & (a < 254))) / n, 2),
    }


def kes_hepsi() -> None:
    SEFFAF.mkdir(parents=True, exist_ok=True)
    hamlar = sorted(HAM.glob("*.png"))
    if not hamlar:
        print("ham/ boş — önce magenta zeminli görselleri koy")
        return

    for yol in hamlar:
        im = Image.open(yol)
        kesik = kareye_otur(magenta_kes(im))
        hedef = SEFFAF / yol.name
        kesik.save(hedef)
        r = rapor(kesik)
        kb = hedef.stat().st_size // 1024
        uyari = ""
        if r["seffaf"] < 35:
            uyari = "  ⚠ zemin tam kesilmemiş olabilir"
        elif r["opak"] < 8:
            uyari = "  ⚠ özne fazla yenmiş olabilir"
        print(
            f"{yol.stem:24s} opak %{r['opak']:<5} şeffaf %{r['seffaf']:<5} "
            f"kenar %{r['kenar']:<5} {kb} KB{uyari}"
        )


# ── Önizleme ──────────────────────────────────────────────────────────
def katalog_yukle() -> list:
    if not KATALOG.exists():
        return []
    return json.loads(KATALOG.read_text(encoding="utf-8"))


def onizleme_uret() -> None:
    katalog = katalog_yukle()
    mevcut = {p.stem.replace("deck_", "") for p in SEFFAF.glob("*.png")}

    bolumler: dict[str, list] = {}
    for d in katalog:
        if d["id"] in mevcut:
            bolumler.setdefault(d["bolum"], []).append(d)

    if not bolumler:
        print("seffaf/ içinde katalogla eşleşen kapak yok")
        return

    uretilen = sum(len(v) for v in bolumler.values())
    toplam_v1 = V1_TOPLAM

    govde = []
    for bolum, desteler in bolumler.items():
        bolum_html = escape(bolum)
        kartlar = []
        for d in desteler:
            rozet = ""
            if d["id"] == "party":
                rozet = '<div class="ribbon">Ücretsiz</div>'
            kilit = "" if d["id"] == "party" else " locked"
            kilit_kat = (
                ""
                if d["id"] == "party"
                else """
          <div class="lock-layer">
            <svg viewBox="0 0 24 24" fill="none" stroke="#E3C36A" stroke-width="1.8"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7.5a4 4 0 0 1 8 0V11"/></svg>
            <div class="stamp">VIP</div>
          </div>"""
            )
            kartlar.append(f"""
      <div class="cell">
        <div class="deck{kilit}">
          <div class="deck-inner">
            <div class="art"><img src="deste-gorselleri/seffaf/deck_{d['id']}.png" alt=""></div>
            <div class="deck-strip"><h3>{escape(d['ad'])}</h3><div class="cards">130 kart</div></div>
          </div>
          <div class="reel">Reel No. {d.get('reel', '—')}</div>{rozet}{kilit_kat}
        </div>
        <div class="cid">{d['id']}</div>
        <div class="cnote">{escape(d.get('konu', ''))}</div>
      </div>""")

        govde.append(f"""
  <div class="panel">
    <h2>{bolum_html} · {len(desteler)} kapak</h2>
    <div class="grid">{''.join(kartlar)}</div>
  </div>

  <div class="panel">
    <h2>{bolum_html} · şeffaf sanat eseri</h2>
    <p class="hint">Damalı zemin gerçek alfa kanalını gösteriyor. Zemin uygulamada çiziliyor.</p>
    <div class="grid raw">{''.join(f'''
      <div class="cell">
        <div class="frame damali"><img src="deste-gorselleri/seffaf/deck_{d['id']}.png" alt=""></div>
        <div class="cid">{escape(d['ad'])}</div>
      </div>''' for d in desteler)}</div>
  </div>""")

    html = ŞABLON.replace("{{GOVDE}}", "".join(govde))
    html = html.replace("{{URETILEN}}", str(uretilen))
    html = html.replace("{{TOPLAM}}", str(toplam_v1))
    CIKTI_HTML.write_text(html, encoding="utf-8")
    print(f"{CIKTI_HTML.name} yazıldı — {uretilen}/{toplam_v1} kapak")


ŞABLON = """<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Deste Kapakları — şeffaf üretim</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@400;500;600;700&family=Playfair+Display:ital,wght@0,700;0,900;1,700&family=Rubik:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
:root{
  --bg-film-black:#100C0A; --bg-velvet-deep:#2B0E15; --bg-velvet-mid:#47161F;
  --bg-velvet-light:#5E1E27;
  --surface-card:#1C1512; --surface-poster:#F4E7CE; --surface-ticket:#E8D3A9;
  --accent-amber:#F0A93B; --accent-gold:#E3C36A; --accent-teal:#2F7F7C;
  --state-correct:#4F8F5B;
  --text-cream:#F6EBD6; --text-secondary:#C6B394; --text-muted:#8B7A66;
  --text-on-poster:#1C1512;
  --font-display:'Oswald',Impact,sans-serif;
  --font-accent:'Playfair Display',Georgia,serif;
  --font-ui:'Rubik',-apple-system,sans-serif;
}
*{margin:0;padding:0;box-sizing:border-box;-webkit-font-smoothing:antialiased}
body{background:#0a0a0c;font-family:var(--font-ui);color:var(--text-muted);padding:48px 32px 90px}
.page-head{max-width:1280px;margin:0 auto 44px;text-align:center}
.page-head h1{font-family:var(--font-display);font-size:32px;font-weight:700;letter-spacing:3px;color:var(--accent-amber);text-transform:uppercase}
.page-head .sub{font-family:var(--font-accent);font-style:italic;font-size:17px;color:var(--text-muted);margin-top:8px}
.page-head .meta{font-size:12px;letter-spacing:1.5px;text-transform:uppercase;color:#5a5048;margin-top:14px}
.bar{max-width:340px;margin:18px auto 0;height:4px;border-radius:2px;background:rgba(227,195,106,.15);overflow:hidden}
.bar i{display:block;height:100%;background:var(--accent-amber)}
.wrap{max-width:1280px;margin:0 auto;display:flex;flex-direction:column;gap:40px}
.panel{background:#141013;border:1px solid rgba(227,195,106,.15);border-radius:16px;padding:28px 30px 32px}
.panel > h2{font-family:var(--font-display);font-size:14px;font-weight:600;letter-spacing:2.4px;color:var(--accent-gold);text-transform:uppercase;margin-bottom:6px}
.panel > .hint{font-size:12.5px;line-height:1.6;color:#7d7062;margin-bottom:20px;max-width:700px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:22px;margin-top:16px}
.cell{display:flex;flex-direction:column;gap:8px}
.cid{font-family:'SF Mono',Menlo,monospace;font-size:10px;letter-spacing:.5px;color:#5f5449;text-align:center}
.cnote{font-size:10.5px;line-height:1.45;color:#6f6357;text-align:center}
.deck{position:relative;border-radius:14px;overflow:hidden;aspect-ratio:3/4;padding:5px;background:var(--surface-card);border:1px solid rgba(227,195,106,.38);box-shadow:0 5px 16px rgba(0,0,0,.55)}
.deck-inner{position:absolute;inset:5px;border-radius:10px;overflow:hidden;display:flex;flex-direction:column;border:1px solid rgba(227,195,106,.3)}
.art{flex:1;position:relative;overflow:hidden;background:radial-gradient(circle at 50% 40%,var(--bg-velvet-light) 0%,var(--bg-velvet-mid) 55%,var(--bg-velvet-deep) 100%);display:flex;align-items:center;justify-content:center}
.art img{width:80%;height:auto;position:relative;z-index:2}
.art::after{content:'';position:absolute;inset:0;opacity:.16;background-image:radial-gradient(circle,rgba(0,0,0,.65) .7px,transparent .8px);background-size:4px 4px;z-index:3}
.deck-strip{background:linear-gradient(180deg,var(--surface-poster),var(--surface-ticket));padding:6px 7px 7px;text-align:center;position:relative;z-index:4}
.deck-strip::before{content:'';position:absolute;inset:0;opacity:.14;background-image:radial-gradient(circle,rgba(28,21,18,.5) .5px,transparent .6px);background-size:3px 3px}
.deck-strip h3{font-family:var(--font-accent);font-weight:900;font-size:12px;line-height:1.12;color:var(--text-on-poster);position:relative}
.deck-strip .cards{font-family:var(--font-ui);font-size:7px;font-weight:600;letter-spacing:1.2px;color:#6b5c46;text-transform:uppercase;margin-top:2px;position:relative}
.reel{position:absolute;top:8px;left:8px;z-index:5;font-family:var(--font-ui);font-size:6px;font-weight:700;letter-spacing:1px;color:var(--accent-gold);background:rgba(16,12,10,.72);padding:2px 4.5px;border-radius:3px;border:.5px solid rgba(227,195,106,.4);text-transform:uppercase}
.ribbon{position:absolute;top:8px;right:8px;z-index:5;font-family:var(--font-display);font-size:6.5px;font-weight:600;letter-spacing:1.2px;text-transform:uppercase;padding:2.5px 5px;border-radius:3px;background:var(--state-correct);color:#eafbec}
.deck.locked .deck-inner{filter:sepia(.62) saturate(.55) brightness(.52)}
.lock-layer{position:absolute;inset:5px;border-radius:10px;z-index:6;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:6px;background:rgba(16,12,10,.42)}
.lock-layer svg{width:22px;height:22px}
.stamp{font-family:var(--font-display);font-size:7px;font-weight:600;letter-spacing:1.4px;color:var(--accent-gold);text-transform:uppercase;border:1.5px solid var(--accent-gold);border-radius:3px;padding:2px 6px;transform:rotate(-7deg);opacity:.9}
.frame{border-radius:8px;overflow:hidden;aspect-ratio:1;display:flex;align-items:center;justify-content:center}
.frame img{width:86%;height:auto}
.frame.damali{background-image:linear-gradient(45deg,#c8c8c8 25%,transparent 25%),linear-gradient(-45deg,#c8c8c8 25%,transparent 25%),linear-gradient(45deg,transparent 75%,#c8c8c8 75%),linear-gradient(-45deg,transparent 75%,#c8c8c8 75%);background-size:20px 20px;background-position:0 0,0 10px,10px -10px,-10px 0;background-color:#aaa}
.grid.raw{grid-template-columns:repeat(auto-fill,minmax(130px,1fr))}
</style>
</head>
<body>
<div class="page-head">
  <h1>Deste Kapakları</h1>
  <div class="sub">Şeffaf RGBA · magenta chroma-key · zemin uygulamada çiziliyor</div>
  <div class="meta">{{URETILEN}} / {{TOPLAM}} v1 kapağı üretildi</div>
  <div class="bar"><i style="width:calc({{URETILEN}} / {{TOPLAM}} * 100%)"></i></div>
</div>
<div class="wrap">{{GOVDE}}</div>
</body>
</html>
"""


if __name__ == "__main__":
    komut = sys.argv[1] if len(sys.argv) > 1 else "hepsi"
    if komut in ("kes", "hepsi"):
        kes_hepsi()
    if komut in ("onizleme", "hepsi"):
        onizleme_uret()
