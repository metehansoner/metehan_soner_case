#!/usr/bin/env python3
"""
P12 ayarlar ve bildirim anahtarlarını `en.json` ve `tr.json`a ekler.

Anahtarlar `settings.language`ın hemen ardına giriyor: ekranın ilk satırı o ve
grup sırası dosyada da okunabilir kalıyor.
"""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIRECTORY = ROOT / "Charades" / "Resources" / "Localization"
ANCHOR = "settings.language"

EN = {
    "settings.group.feel": "Feel & sound",
    "settings.group.notifications": "Notifications",
    "settings.group.account": "Account",
    "settings.group.legal": "Support & legal",
    "settings.roundDuration": "Round length",
    "settings.answerMethod": "Answering",
    "settings.answer.tilt": "Tilt",
    "settings.answer.tap": "Tap",
    "settings.difficulty": "Difficulty",
    "settings.haptics": "Vibration",
    "settings.sound": "Sound effects",
    "settings.filmEffects": "Film effects",
    "settings.notifications": "Notifications",
    "settings.notifications.denied": "Allow them in iOS Settings",
    "settings.dailyFreeDeck": "Free deck of the day",
    "settings.manageSubscription": "Manage subscription",
    "settings.restore": "Restore purchases",
    "settings.ticket.active": "Full ticket active",
    "settings.ticket.renews": "Renews {date}",
    "settings.contact": "Contact us",
    "settings.contact.subject": "Charades support",
    "settings.rateUs": "Rate us",
    "settings.userID.hint": "Press and hold to copy",
    "settings.userID.copied": "Copied",
    "settings.version": "Version {version}",
    "notification.dailyFreeDeck.title": "Now showing",
    "notification.dailyFreeDeck.body": "{deck} is free today.",
    "notification.trialEnding.title": "Your trial ends tomorrow",
    "notification.trialEnding.body": "Keep the whole theatre open, or let the ticket run out.",
}

TR = {
    "settings.group.feel": "His ve ses",
    "settings.group.notifications": "Bildirimler",
    "settings.group.account": "Hesap",
    "settings.group.legal": "Destek ve yasal",
    "settings.roundDuration": "Tur süresi",
    "settings.answerMethod": "Cevap yöntemi",
    "settings.answer.tilt": "Eğ",
    "settings.answer.tap": "Dokun",
    "settings.difficulty": "Zorluk",
    "settings.haptics": "Titreşim",
    "settings.sound": "Ses efektleri",
    "settings.filmEffects": "Film efektleri",
    "settings.notifications": "Bildirimler",
    "settings.notifications.denied": "iOS Ayarlar'dan izin verin",
    "settings.dailyFreeDeck": "Günün bedava destesi",
    "settings.manageSubscription": "Aboneliği yönet",
    "settings.restore": "Satın alımları geri yükle",
    "settings.ticket.active": "Tam bilet aktif",
    "settings.ticket.renews": "Yenileme: {date}",
    "settings.contact": "Bize ulaş",
    "settings.contact.subject": "Charades destek",
    "settings.rateUs": "Bizi puanla",
    "settings.userID.hint": "Dokunup basılı tutarak kopyala",
    "settings.userID.copied": "Kopyalandı",
    "settings.version": "Sürüm {version}",
    "notification.dailyFreeDeck.title": "Şimdi vizyonda",
    "notification.dailyFreeDeck.body": "Bugün {deck} bedava.",
    "notification.trialEnding.title": "Denemen yarın bitiyor",
    "notification.trialEnding.body": "Tüm salon açık kalsın ya da bilet sona ersin.",
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
