#!/usr/bin/env python3
"""
Lokalizasyon doğrulaması — 06-ayarlar-ve-lokalizasyon.md §2, §3.4.

Custom JSON altyapısının bedeli: Xcode'un anahtar denetimi yok. Bu script onun
yerine geçiyor ve `en.json`u referans alarak her dil için şunları denetliyor:

  1. dosya var, JSON geçerli, `meta.locale` dosya adıyla aynı
  2. anahtar pariteti — eksik (İngilizce'ye düşer) ve fazla (yazım hatası)
  3. placeholder pariteti — `{count}` çeviride kaybolursa sayı ekranda yok olur
  4. plural bütünlüğü — `.one`/`.other`, Slav dilleri ve `ar`/`ro` için `.few`
  5. taşma — `mode.*.title` ≤ 18 (§03 §3.1), `deck.*.title` ≤ 22 (§2)
  6. boş değer yok

Kullanım:
  python3 Scripts/validate_localization.py [--warn-missing]
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIRECTORY = ROOT / "Charades" / "Resources" / "Localization"

LOCALES = [
    "en", "tr", "ar", "be", "ca", "cs", "da", "de", "el", "es",
    "fi", "fil", "fr", "hr", "id", "it", "ms", "nb", "nl", "pl",
    "pt", "ro", "ru", "sv", "uk",
]

# LocalizationManager.pluralCategory ile aynı bölünme.
FEW_LOCALES = {"ru", "uk", "be", "hr", "pl", "cs", "ar", "ro"}
# Sayıya göre biçim değiştirmeyen diller yalnızca `.other` yazıyor.
OTHER_ONLY_LOCALES = {"id", "ms", "fil", "tr"}

MODE_TITLE_LIMIT = 18
DECK_TITLE_LIMIT = 22

# § `03` §1: onboarding sheet'i ekranın %55'i ve adım 2 iki cümle. Almanca ve
# Fince İngilizce'nin ~%40 üzerine çıkabildiği için (§ `06` §2) taşma kontrolü
# burada yapılıyor. Sınırlar İngilizce uzunluk + %45 pay.
KEY_LIMITS = {
    "onboarding.skip": 12,
    "onboarding.cta.continue": 16,
    "onboarding.cta.next": 16,
    "onboarding.cta.ready": 16,
    "onboarding.welcome.title": 26,
    "onboarding.forehead.title": 30,
    "onboarding.tilt.title": 26,
    "onboarding.tap.title": 26,
    "onboarding.welcome.body": 140,
    "onboarding.forehead.body": 120,
    "onboarding.tilt.body": 110,
    "onboarding.tap.body": 130,
    "onboarding.zone.tiltForward": 18,
    "onboarding.zone.tiltBack": 18,
    "onboarding.zone.tapRight": 18,
    "onboarding.zone.tapLeft": 18,
    # § `06` §1: ayar satırında başlık ile kontrol aynı satırı paylaşıyor.
    # Uzun bir başlık anahtarı ekranın dışına itiyor.
    "settings.group.feel": 22,
    "settings.group.notifications": 22,
    "settings.group.account": 20,
    "settings.group.legal": 26,
    "settings.roundDuration": 20,
    "settings.answerMethod": 20,
    "settings.answer.tilt": 10,
    "settings.answer.tap": 10,
    "settings.difficulty": 18,
    "settings.haptics": 20,
    "settings.sound": 22,
    "settings.filmEffects": 22,
    "settings.notifications": 22,
    "settings.notifications.denied": 40,
    "settings.dailyFreeDeck": 30,
    "settings.manageSubscription": 32,
    "settings.restore": 32,
    "settings.ticket.active": 26,
    "settings.ticket.renews": 26,
    "settings.contact": 22,
    "settings.rateUs": 22,
    "settings.userID.hint": 40,
    "settings.userID.copied": 16,
    "notification.dailyFreeDeck.title": 26,
    "notification.dailyFreeDeck.body": 46,
    "notification.trialEnding.title": 42,
    "notification.trialEnding.body": 90,
    # § `06` §3.4: "Paywall başlığı ve iki satır özeti taşmıyor (Almanca en
    # riskli)" ve "plan kartlarında plan adı ve alt metin tek satırda kalıyor".
    # Sınırlar bugünkü en uzun çevirinin biraz üstünde: yeni bir çeviri sessizce
    # kartı bozmadan önce burada duruyor.
    "paywall.headline.line1": 22,
    "paywall.headline.line2": 24,
    "paywall.summary.content": 60,
    "paywall.summary.features": 62,
    "paywall.title": 18,
    "paywall.plaque": 18,
    "paywall.skip": 14,
    "paywall.plan.weekly": 14,
    "paywall.plan.monthly": 14,
    "paywall.plan.yearly": 14,
    "paywall.plan.weekly.unit": 12,
    "paywall.plan.monthly.unit": 12,
    "paywall.plan.yearly.unit": 12,
    "paywall.plan.trialSub.one": 46,
    "paywall.plan.trialSub.few": 46,
    "paywall.plan.trialSub.other": 46,
    "paywall.plan.perWeek": 24,
    "paywall.band.trial.one": 24,
    "paywall.band.trial.few": 24,
    "paywall.band.trial.other": 24,
    "paywall.band.save": 22,
    "paywall.cta.trial": 20,
    "paywall.cta.buy": 20,
    "paywall.restore": 18,
    "paywall.terms": 20,
    "paywall.privacy": 20,
    "paywall.fine.trial": 78,
    "paywall.fine.cancel": 55,
    "paywall.fine.recurring": 48,
    "paywall.context.deck": 34,
    "paywall.context.mode": 32,
    "paywall.context.mix": 26,
    "paywall.context.customDeck": 34,
    "paywall.soft.title": 22,
    "paywall.soft.body.one": 42,
    "paywall.soft.body.few": 42,
    "paywall.soft.body.other": 42,
    "paywall.soft.cta": 18,
    "paywall.soft.dismiss": 12,
    "paywall.lapse.title": 30,
    "paywall.lapse.cta": 24,
}

PLACEHOLDER = re.compile(r"\{(\w+)\}")


def load(code: str) -> dict[str, str]:
    return json.loads((DIRECTORY / f"{code}.json").read_text(encoding="utf-8"))


def plural_bases(keys: set[str]) -> set[str]:
    return {key.rsplit(".", 1)[0] for key in keys if key.endswith((".one", ".few", ".other"))}


def main() -> int:
    warn_missing = "--warn-missing" in sys.argv
    english = load("en")
    bases = plural_bases(set(english))
    errors: list[str] = []
    warnings: list[str] = []

    for code in LOCALES:
        path = DIRECTORY / f"{code}.json"
        if not path.exists():
            errors.append(f"{code}: dosya yok")
            continue
        try:
            strings = load(code)
        except json.JSONDecodeError as error:
            errors.append(f"{code}: JSON geçersiz — {error}")
            continue

        if strings.get("meta.locale") != code:
            errors.append(f"{code}: meta.locale = {strings.get('meta.locale')!r}")
        if not strings.get("meta.languageName"):
            errors.append(f"{code}: meta.languageName boş")

        # 2 — anahtar pariteti
        missing = sorted(set(english) - set(strings))
        extra = sorted(set(strings) - set(english))
        if code != "en":
            # Çoğulu olmayan dillerde `.one` yazılmaması eksiklik değil.
            if code in OTHER_ONLY_LOCALES:
                missing = [k for k in missing if not k.endswith((".one", ".few"))]
            if code not in FEW_LOCALES:
                missing = [k for k in missing if not k.endswith(".few")]
                extra = [k for k in extra if not k.endswith(".few")]
            else:
                extra = [k for k in extra if not (k.endswith(".few") and k.rsplit(".", 1)[0] in bases)]

            if missing:
                target = warnings if warn_missing else errors
                target.append(f"{code}: {len(missing)} anahtar eksik (ilk 5: {missing[:5]})")
            if extra:
                errors.append(f"{code}: {len(extra)} fazla anahtar (ilk 5: {extra[:5]})")

        for key, value in strings.items():
            if not value.strip():
                errors.append(f"{code}: {key} boş")

            # 3 — placeholder pariteti
            reference = english.get(key) or english.get(key.rsplit(".", 1)[0] + ".other")
            if reference:
                expected = set(PLACEHOLDER.findall(reference))
                actual = set(PLACEHOLDER.findall(value))
                if expected != actual:
                    errors.append(f"{code}: {key} placeholder {sorted(actual)} ≠ {sorted(expected)}")

            # 5 — taşma
            if key.startswith("mode.") and key.endswith(".title") and len(value) > MODE_TITLE_LIMIT:
                errors.append(f"{code}: {key} {len(value)} karakter (> {MODE_TITLE_LIMIT}) — {value!r}")
            if key.startswith("deck.") and key.endswith(".title") and len(value) > DECK_TITLE_LIMIT:
                errors.append(f"{code}: {key} {len(value)} karakter (> {DECK_TITLE_LIMIT}) — {value!r}")
            if (limit := KEY_LIMITS.get(key)) and len(value) > limit:
                errors.append(f"{code}: {key} {len(value)} karakter (> {limit}) — {value!r}")

        # 4 — plural bütünlüğü
        for base in sorted(bases):
            if code in OTHER_ONLY_LOCALES:
                required = {"other"}
            elif code in FEW_LOCALES:
                required = {"one", "few", "other"}
            else:
                required = {"one", "other"}
            present = {suffix for suffix in ("one", "few", "other") if f"{base}.{suffix}" in strings}
            if code != "en" and not present:
                continue  # dosya o anahtarı hiç taşımıyorsa eksik anahtar denetimi zaten raporladı
            if not required <= present:
                errors.append(f"{code}: {base} plural eksik {sorted(required - present)}")

    for warning in warnings:
        print(f"! {warning}")
    if errors:
        for error in errors:
            print(f"✗ {error}")
        print(f"\n{len(errors)} hata")
        return 1

    print(f"✓ {len(LOCALES)} dil × {len(english)} anahtar — parite, placeholder, plural ve taşma temiz")
    return 0


if __name__ == "__main__":
    sys.exit(main())
