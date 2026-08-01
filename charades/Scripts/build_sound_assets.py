#!/usr/bin/env python3
"""
Retro ses paketi — 04-oyun-modlari.md §5.

12 kısa parça (<1.5s). Bunlar **yer tutucu**: temanın karakterini taşıyan
sentetik sinyaller; ses tasarımı geldiğinde aynı dosya adlarıyla değiştirilir,
SoundService dokunulmaz.

Çıktı: Charades/Resources/Sounds/*.caf (afconvert ile WAV → CAF).
"""

from __future__ import annotations

import math
import pathlib
import random
import struct
import subprocess
import tempfile
import wave

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "Charades" / "Resources" / "Sounds"
RATE = 44100


def clamp(x: float) -> float:
    return max(-1.0, min(1.0, x))


def write_wav(path: pathlib.Path, samples: list[float]) -> None:
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        frames = b"".join(struct.pack("<h", int(clamp(s) * 32767)) for s in samples)
        wav.writeframes(frames)


def to_caf(wav_path: pathlib.Path, caf_path: pathlib.Path) -> None:
    subprocess.run(
        ["afconvert", "-f", "caff", "-d", "LEI16", str(wav_path), str(caf_path)],
        check=True,
        capture_output=True,
    )


def tone(freq: float, duration: float, amp: float = 0.4, decay: float = 6.0) -> list[float]:
    n = int(RATE * duration)
    out = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-decay * t)
        out.append(amp * env * math.sin(2 * math.pi * freq * t))
    return out


def noise(duration: float, amp: float = 0.2, decay: float = 12.0) -> list[float]:
    n = int(RATE * duration)
    rng = random.Random(42)
    out = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-decay * t)
        out.append(amp * env * (rng.random() * 2 - 1))
    return out


def mix(*tracks: list[float]) -> list[float]:
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for track in tracks:
        for i, sample in enumerate(track):
            out[i] += sample
    peak = max((abs(s) for s in out), default=1.0) or 1.0
    if peak > 0.95:
        scale = 0.95 / peak
        out = [s * scale for s in out]
    return out


def pad(samples: list[float], before: float = 0, after: float = 0) -> list[float]:
    return [0.0] * int(RATE * before) + samples + [0.0] * int(RATE * after)


def loopable_hum(duration: float = 1.0, amp: float = 0.035) -> list[float]:
    """Projektör motoru — döngüde tıkırtı olmasın diye sabit zarf."""
    n = int(RATE * duration)
    out = []
    for i in range(n):
        t = i / RATE
        sample = (
            0.55 * math.sin(2 * math.pi * 52 * t)
            + 0.25 * math.sin(2 * math.pi * 104 * t)
            + 0.12 * math.sin(2 * math.pi * 156 * t)
            + 0.08 * math.sin(2 * math.pi * 30 * t)
        )
        out.append(amp * sample)
    return out


def build() -> dict[str, list[float]]:
    rng = random.Random(7)

    # Perde açılışı — yumuşak yükselen whoosh.
    curtain = []
    for i in range(int(RATE * 0.9)):
        t = i / RATE
        env = math.sin(math.pi * min(1.0, t / 0.9)) ** 1.4
        hiss = (rng.random() * 2 - 1) * 0.18
        rumble = 0.22 * math.sin(2 * math.pi * (90 + 40 * t) * t)
        curtain.append(0.45 * env * (hiss + rumble))

    # Ampul kırpışması — kısa elektrik çıtırtısı.
    flicker = []
    for i in range(int(RATE * 0.45)):
        t = i / RATE
        bursts = sum(math.exp(-80 * abs(t - b)) for b in (0.04, 0.11, 0.19, 0.28))
        flicker.append(0.35 * bursts * (rng.random() * 2 - 1) * (0.4 + 0.6 * math.sin(2 * math.pi * 1800 * t)))

    # Geri sayım tiki — tahta blok.
    tick = mix(tone(980, 0.07, amp=0.38, decay=28), tone(1960, 0.05, amp=0.12, decay=40))

    # DOĞRU — tiyatro zili (iki ton).
    bell = mix(
        tone(880, 0.7, amp=0.42, decay=4.5),
        tone(1320, 0.55, amp=0.22, decay=5.5),
        pad(tone(1760, 0.35, amp=0.1, decay=7), before=0.02),
    )

    # PAS — projektör klak.
    clack = mix(
        noise(0.06, amp=0.55, decay=55),
        tone(220, 0.08, amp=0.25, decay=35),
        pad(tone(110, 0.05, amp=0.18, decay=40), before=0.01),
    )

    # Son 10 sn uyarısı — daha tiz tik.
    warn = mix(tone(1480, 0.06, amp=0.32, decay=32), tone(2960, 0.04, amp=0.1, decay=45))

    # Süre bitti — uzun zil.
    time_up = mix(
        tone(660, 1.1, amp=0.45, decay=2.8),
        tone(990, 0.9, amp=0.28, decay=3.2),
        tone(1320, 0.7, amp=0.14, decay=3.8),
    )

    # Kart kayması — kağıt sürtünmesi.
    slide = []
    for i in range(int(RATE * 0.28)):
        t = i / RATE
        env = math.sin(math.pi * min(1.0, t / 0.28))
        slide.append(0.22 * env * (rng.random() * 2 - 1) * (0.5 + 0.5 * math.sin(2 * math.pi * 2400 * t)))

    # Mekanik tuş.
    tap = mix(
        noise(0.025, amp=0.4, decay=90),
        tone(1600, 0.04, amp=0.18, decay=50),
        tone(420, 0.05, amp=0.12, decay=40),
    )

    # Maç sonu — kısa majör arpej.
    fanfare = mix(
        tone(523.25, 0.35, amp=0.28, decay=5),
        pad(tone(659.25, 0.35, amp=0.28, decay=5), before=0.08),
        pad(tone(783.99, 0.45, amp=0.32, decay=4), before=0.16),
        pad(tone(1046.5, 0.55, amp=0.3, decay=3.5), before=0.24),
    )

    # Bilet damgası — tok vuruş.
    stamp = mix(
        tone(90, 0.18, amp=0.55, decay=18),
        noise(0.08, amp=0.35, decay=40),
        pad(tone(180, 0.1, amp=0.2, decay=25), before=0.015),
    )

    return {
        "sfx_curtain_open": curtain,
        "sfx_bulb_flicker": flicker,
        "sfx_projector_loop": loopable_hum(1.0),
        "sfx_countdown_tick": tick,
        "sfx_correct_bell": bell,
        "sfx_skip_clack": clack,
        "sfx_tick_warning": warn,
        "sfx_time_up": time_up,
        "sfx_card_slide": slide,
        "sfx_button_tap": tap,
        "sfx_win_fanfare": fanfare,
        "sfx_ticket_stamp": stamp,
    }


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    pieces = build()
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = pathlib.Path(tmp)
        for name, samples in pieces.items():
            wav = tmp_path / f"{name}.wav"
            caf = OUT / f"{name}.caf"
            write_wav(wav, samples)
            to_caf(wav, caf)
            duration = len(samples) / RATE
            print(f"{name}.caf  {duration:.2f}s  {caf.stat().st_size} B")
    print(f"\n{len(pieces)} parça → {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
