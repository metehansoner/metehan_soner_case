#!/usr/bin/env python3
"""Generate expand_decks_batch3_data_rest.py for remaining 32 decks."""
from expand_decks_batch3_data import LOCALES, card, t, sc

OUT = __import__("pathlib").Path(__file__).parent / "expand_decks_batch3_data_rest.py"


def lit(key, d, en, tr, de, ar, es, fr, ru, uk, **kw):
    """Literal card with major locales + sc-style fill for rest from en."""
    vals = {loc: en for loc in LOCALES}
    vals.update({"en": en, "tr": tr, "de": de, "ar": ar, "es": es, "fr": fr, "ru": ru, "uk": uk})
    vals.update(kw)
    for loc in LOCALES:
        if loc not in vals or vals[loc] is None:
            vals[loc] = en
    return card(key, d, {loc: vals[loc] for loc in LOCALES})


def adapt(key, d, mapping):
    assert set(mapping.keys()) == set(LOCALES), f"{key}: {set(mapping.keys()) ^ set(LOCALES)}"
    return card(key, d, mapping)


def num_cards(prefix, start, items, d_default=1):
    out = []
    for i, item in enumerate(items, start=start):
        k = f"{prefix}_{i:02d}"
        if isinstance(item, tuple) and len(item) == 2:
            d, c = item
        else:
            d, c = d_default, item
        out.append(c if hasattr(c, "get") and "k" in c else c)
        if not (hasattr(out[-1], "get") and "k" in out[-1]):
            pass
    return out


# Helper to build numbered adapt cards from (en, {locale: text}) list
def adapt_list(prefix, start, pairs, d=1):
    cards = []
    for i, (en, locs) in enumerate(pairs, start=start):
        m = {loc: en for loc in LOCALES}
        m["en"] = en
        m.update(locs)
        cards.append(adapt(f"{prefix}_{i:02d}", d, m))
    return cards


def lit_list(items):
    return [lit(*args) for args in items]


NEW_CARDS = {}

# ── tvCartoons (literal) ──
NEW_CARDS["tvCartoons"] = lit_list([
    ("family_guy", 1, "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Padre de familia", "Les Griffin", "Гриффины", "Гріфіни"),
    ("futurama", 1, "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Футурама", "Футурама"),
    ("american_dad", 1, "American Dad!", "American Dad!", "American Dad!", "American Dad!", "Padre americano", "American Dad!", "Американский папаша", "Американський тато"),
    ("king_hill", 1, "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "Les Rois du Texas", "Царь горы", "Король пагорбів"),
    ("bob_burgers", 1, "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Боб's Burgers", "Боб's Burgers", tr="Bob's Burgers"),
    ("archer", 2, "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Арчер", "Арчер"),
    ("bojack", 2, "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "БоДжек Хorsman", "БоДжек Хorsman"),
    ("steven_future", 1, "Steven Universe Future", "Steven Universe Future", "Steven Universe Future", "Steven Universe Future", "Steven Universe Future", "Steven Universe Future", "Вселенная Стeven", "Всесвіт Стeven"),
    ("amphibia", 1, "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Амфибия", "Амфібія"),
    ("owl_house", 1, "The Owl House", "Baykuş Evi", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "Сова House", "Будинок сови", be="Сова House", ca="The Owl House", cs="The Owl House", da="The Owl House", el="The Owl House", fi="The Owl House", fil="The Owl House", hr="The Owl House", id="The Owl House", it="The Owl House", ms="The Owl House", nb="The Owl House", nl="The Owl House", pl="The Owl House", pt="The Owl House", ro="The Owl House", sv="The Owl House"),
    ("ducktales", 1, "DuckTales", "DuckTales", "DuckTales", "DuckTales", "Patoaventuras", "La Bande à Picsou", "Утиные истории", "Качині історії"),
    ("darkwing", 1, "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "El Pato Darkwing", "Myster Mask", "Чёрный Плащ", "Чорний Плащ"),
    ("animaniacs", 1, "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Анимaniacs", "Аніманiacs"),
    ("pink_panther", 1, "The Pink Panther", "Pembe Panter", "The Pink Panther", "The Pink Panther", "La Pantera Rosa", "La Panthère rose", "Розовая пантера", "Рожева пантера"),
    ("inspector_gadget", 1, "Inspector Gadget", "Müfettiş Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspecteur Gadget", "Инспектор Гаджет", "Інспектор Гаджет"),
    ("care_bears", 1, "Care Bears", "Sevimli Ayılar", "Care Bears", "Care Bears", "Osos Amorosos", "Les Bisounours", "Мишки-заботы", "Ведмедики-турботливі"),
    ("smurfs", 1, "The Smurfs", "Şirinler", "Die Schlümpfe", "The Smurfs", "Los Pitufos", "Les Schtroumpfs", "Смурфики", "Смurfики"),
    ("powerpuff", 1, "The Powerpuff Girls", "Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "Las Supernenas", "Les Super Nanas", "Суперкрошки", "Супердівчата"),
    ("johnny_bravo", 1, "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo"),
    ("courage_cowardly", 1, "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Coraje, el perro cobarde", "Courage le chien froussard", "Хrabryj pes", "Хоробрий пес"),
    ("dexter_lab", 1, "Dexter's Laboratory", "Dexter'ın Laboratuvarı", "Dexters Labor", "Dexter's Laboratory", "El laboratorio de Dexter", "Le Laboratoire de Dexter", "Лаборатория Декстера", "Лабораторія Декстера"),
    ("johnny_test", 1, "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test"),
    ("fairly_odd", 1, "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "Los padrinos mágicos", "Mes parrains sont magiques", "Волшебные родители", "Чарівні батьки"),
    ("avatar_korra", 1, "The Legend of Korra", "Korra Efsanesi", "The Legend of Korra", "The Legend of Korra", "La leyenda de Korra", "La Légende de Korra", "Легенда о Корре", "Легенда про Korra"),
    ("over_garden", 1, "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall"),
    ("star_butterfly", 1, "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. las fuerzas del mal", "Star vs. les Forces du Mal", "Star против сил зла", "Star проти сил зла"),
    ("gravity_falls_again", 1, "Weirdmageddon", "Weirdmageddon", "Weirdmageddon", "Weirdmageddon", "Weirdmageddon", "Weirdmageddon", "Weirdmageddon", "Weirdmageddon"),
    ("clone_high", 2, "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High"),
    ("foster_home", 1, "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends"),
    ("camp_lazlo", 1, "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo"),
    ("chowder", 1, "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder"),
    ("flintstones", 1, "The Flintstones", "Taş Devri", "Die Flintstones", "The Flintstones", "Los Picapiedra", "Les Pierrafeu", "Флинстоуны", "Флінстоуни"),
    ("jetsons", 1, "The Jetsons", "Jetgiller", "Die Jetsons", "The Jetsons", "Los Supersónicos", "Les Jetson", "Джетсоны", "Джетсони"),
    ("wacky_races", 1, "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races"),
    ("speed_racer", 1, "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer"),
    ("he_man", 1, "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man"),
    ("she_ra", 1, "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra"),
    ("thundercats", 1, "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats"),
    ("voltron", 1, "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron"),
    ("gumball", 1, "The Amazing World of Gumball", "Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "El asombroso mundo de Gumball", "Le Monde incroyable de Gumball", "Удивительный мир Гамбола", "Дивовижний світ Гамбола"),
])

print(f"tvCartoons: {len(NEW_CARDS['tvCartoons'])}")

# Write partial output for validation
lines = ['"""Remaining deck expansion data (batch 3 part 2)."""\n']
lines.append("from expand_decks_batch3_data import LOCALES, card, t, sc\n\n")
lines.append("NEW_CARDS = {\n")
for deck, cards in NEW_CARDS.items():
    lines.append(f'    "{deck}": [\n')
    for c in cards:
        lines.append(f"        {repr(c)},\n")
    lines.append("    ],\n")
lines.append("}\n")
OUT.write_text("".join(lines), encoding="utf-8")
print(f"Wrote {OUT} ({len(lines)} lines approx)")
