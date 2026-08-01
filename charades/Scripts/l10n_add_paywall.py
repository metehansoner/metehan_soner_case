#!/usr/bin/env python3
"""
P10 paywall anahtarlarını `en.json` ve `tr.json`a ekler ve `en.json`daki sırayı
tüm dillere uygular.

Anahtarlar `paywall.title`ın hemen ardına giriyor; dosya sırası ekrandaki sıra
değil ama ilgili anahtarların bir arada durması diff'i okunur tutuyor.
"""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIRECTORY = ROOT / "Charades" / "Resources" / "Localization"
ANCHOR = "paywall.title"

EN = {
    "paywall.plaque": "Full ticket",
    "paywall.headline.line1": "Unlock the",
    "paywall.headline.line2": "whole theatre",
    "paywall.summary.content": "{decks} decks · {cards} cards · {languages} languages",
    "paywall.summary.features": "Your own words · Mix · Team Battle · Replay",
    "paywall.plan.weekly": "Weekly",
    "paywall.plan.monthly": "Monthly",
    "paywall.plan.yearly": "Yearly",
    "paywall.plan.weekly.unit": "/ week",
    "paywall.plan.monthly.unit": "/ month",
    "paywall.plan.yearly.unit": "/ year",
    "paywall.plan.trialSub.one": "{count} day free, then renews",
    "paywall.plan.trialSub.other": "{count} days free, then renews",
    "paywall.plan.perWeek": "{price} per week",
    "paywall.band.trial.one": "{count} day free",
    "paywall.band.trial.other": "{count} days free",
    "paywall.band.save": "Save {percent}%",
    "paywall.cta.trial": "Try it free",
    "paywall.cta.buy": "Get the ticket",
    "paywall.fine.trial": "You pay nothing if you cancel before the trial ends.",
    "paywall.fine.recurring": "{plan} {price}, renews automatically.",
    "paywall.fine.cancel": "Cancel any time in Settings.",
    "paywall.restore": "Restore",
    "paywall.terms": "Terms",
    "paywall.privacy": "Privacy",
    "paywall.skip": "Skip",
    "paywall.loading": "Loading plans…",
    "paywall.offline": "Your subscription can't be verified without a connection.",
    "paywall.restore.done": "Your subscription is back.",
    "paywall.restore.none": "No subscription found to restore.",
    "paywall.purchase.failed": "The purchase couldn't be completed.",
    "paywall.context.deck": "Unlock the {title} deck",
    "paywall.context.deck.sub.one": "This deck and {count} more · {cards} cards",
    "paywall.context.deck.sub.other": "This deck and {count} more · {cards} cards",
    "paywall.context.mode": "Unlock {title}",
    "paywall.context.mix": "Unlock Mix",
    "paywall.context.customDeck": "Play your own decks",
    "paywall.soft.title": "Nicely played.",
    "paywall.soft.body.one": "{count} more deck is waiting.",
    "paywall.soft.body.other": "{count} more decks are waiting.",
    "paywall.soft.cta": "See the ticket",
    "paywall.soft.dismiss": "Later",
    "paywall.notice.locked": "This one comes with the full ticket.",
    "paywall.lapse.title": "Your ticket has ended.",
    "paywall.lapse.body": "The decks are locked, but your archive and your own decks are right where you left them.",
    "paywall.lapse.cta": "Get the ticket again",
}

TR = {
    "paywall.plaque": "Tam bilet",
    "paywall.headline.line1": "Tüm salonun",
    "paywall.headline.line2": "kilidini aç",
    "paywall.summary.content": "{decks} deste · {cards} kart · {languages} dil",
    "paywall.summary.features": "Kendi kelimelerin · Mix · Takım Savaşı · Replay",
    "paywall.plan.weekly": "Haftalık",
    "paywall.plan.monthly": "Aylık",
    "paywall.plan.yearly": "Yıllık",
    "paywall.plan.weekly.unit": "/ hafta",
    "paywall.plan.monthly.unit": "/ ay",
    "paywall.plan.yearly.unit": "/ yıl",
    "paywall.plan.trialSub.one": "{count} gün ücretsiz, sonra yenilenir",
    "paywall.plan.trialSub.other": "{count} gün ücretsiz, sonra yenilenir",
    "paywall.plan.perWeek": "Haftalık {price}",
    "paywall.band.trial.one": "{count} gün bedava",
    "paywall.band.trial.other": "{count} gün bedava",
    "paywall.band.save": "%{percent} tasarruf",
    "paywall.cta.trial": "Ücretsiz dene",
    "paywall.cta.buy": "Bileti al",
    "paywall.fine.trial": "Deneme bitmeden iptal edersen ücret alınmaz.",
    "paywall.fine.recurring": "{plan} {price}, otomatik yenilenir.",
    "paywall.fine.cancel": "İstediğin an Ayarlar'dan iptal edebilirsin.",
    "paywall.restore": "Geri yükle",
    "paywall.terms": "Koşullar",
    "paywall.privacy": "Gizlilik",
    "paywall.skip": "Atla",
    "paywall.loading": "Planlar yükleniyor…",
    "paywall.offline": "Bağlantı yokken abonelik doğrulanamıyor.",
    "paywall.restore.done": "Aboneliğin geri geldi.",
    "paywall.restore.none": "Geri yüklenecek abonelik bulunamadı.",
    "paywall.purchase.failed": "Satın alma tamamlanamadı.",
    "paywall.context.deck": "{title} destesinin kilidini aç",
    "paywall.context.deck.sub.one": "Bu deste ve {count} deste daha · {cards} kart",
    "paywall.context.deck.sub.other": "Bu deste ve {count} deste daha · {cards} kart",
    "paywall.context.mode": "{title} modunun kilidini aç",
    "paywall.context.mix": "Mix'in kilidini aç",
    "paywall.context.customDeck": "Kendi destelerinle oyna",
    "paywall.soft.title": "İyi oynadın.",
    "paywall.soft.body.one": "Sırada {count} deste daha var.",
    "paywall.soft.body.other": "Sırada {count} deste daha var.",
    "paywall.soft.cta": "Bileti gör",
    "paywall.soft.dismiss": "Sonra",
    "paywall.notice.locked": "Bu, Tam Bilet'te açılıyor.",
    "paywall.lapse.title": "Tam bilet sona erdi.",
    "paywall.lapse.body": "Desteler kilitli ama arşivin ve kendi destelerin yerinde duruyor.",
    "paywall.lapse.cta": "Bileti yeniden al",
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
