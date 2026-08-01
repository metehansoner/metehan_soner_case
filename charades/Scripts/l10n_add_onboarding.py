#!/usr/bin/env python3
"""
P11 onboarding anahtarlarını `en.json` ve `tr.json`a ekler.

Anahtarlar `howToPlay.title`ın hemen ardına giriyor: onboarding ikna, o slider
talimat veriyor (§ `03` §1) ve ikisi aynı anlatımı bölüştüğü için diff'te yan
yana durmaları çeviri sırasında karşılaştırmayı kolaylaştırıyor.
"""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIRECTORY = ROOT / "Charades" / "Resources" / "Localization"
ANCHOR = "howToPlay.title"

EN = {
    "onboarding.skip": "Skip",
    "onboarding.cta.continue": "Continue",
    "onboarding.cta.next": "Next",
    "onboarding.cta.ready": "I'm ready",
    "onboarding.welcome.title": "Welcome",
    "onboarding.welcome.body": "The liveliest kind of silent cinema. {decks} themed decks, {cards} cards, {languages} languages.",
    "onboarding.forehead.title": "Hold it to your forehead",
    "onboarding.forehead.body": "Show the screen to your friends. They act it out in silence, you guess.",
    "onboarding.tilt.title": "Tilt and answer",
    "onboarding.tilt.body": "Tilt forward for CORRECT. Tilt back for PASS. That's all.",
    "onboarding.tap.title": "Tap and answer",
    "onboarding.tap.body": "Tap the right half for CORRECT. Tap the left half for PASS. That's all.",
    "onboarding.zone.tiltForward": "Tilt forward",
    "onboarding.zone.tiltBack": "Tilt back",
    "onboarding.zone.tapRight": "Right half",
    "onboarding.zone.tapLeft": "Left half",
}

TR = {
    "onboarding.skip": "Atla",
    "onboarding.cta.continue": "Devam",
    "onboarding.cta.next": "Sıradaki",
    "onboarding.cta.ready": "Hazırım",
    "onboarding.welcome.title": "Hoş geldin",
    "onboarding.welcome.body": "Sessiz sinemanın en eğlencelisi. {decks} temalı deste, {cards} kart, {languages} dil.",
    "onboarding.forehead.title": "Telefonu alnına koy",
    "onboarding.forehead.body": "Ekranı arkadaşlarına göster. Onlar konuşmadan canlandırır, sen tahmin edersin.",
    "onboarding.tilt.title": "Eğ ve cevapla",
    "onboarding.tilt.body": "Öne eğ = DOĞRU. Arkaya eğ = PAS. Hepsi bu.",
    "onboarding.tap.title": "Dokun ve cevapla",
    "onboarding.tap.body": "Sağ yarıya dokun = DOĞRU. Sol yarıya dokun = PAS. Hepsi bu.",
    "onboarding.zone.tiltForward": "Öne eğ",
    "onboarding.zone.tiltBack": "Arkaya eğ",
    "onboarding.zone.tapRight": "Sağ yarı",
    "onboarding.zone.tapLeft": "Sol yarı",
}


def insert(code: str, additions: dict[str, str]) -> None:
    path = DIRECTORY / f"{code}.json"
    strings = json.loads(path.read_text(encoding="utf-8"))
    merged: dict[str, str] = {}
    for key, value in strings.items():
        merged[key] = value
        if key == ANCHOR:
            merged.update(additions)
    path.write_text(
        json.dumps(merged, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def main() -> int:
    insert("en", EN)
    insert("tr", TR)
    print(f"{len(EN)} anahtar eklendi: en, tr")
    return 0


if __name__ == "__main__":
    sys.exit(main())
