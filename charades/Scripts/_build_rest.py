#!/usr/bin/env python3
"""Build expand_decks_batch3_data_rest.py with all remaining 32 decks."""
import json
import textwrap
from pathlib import Path
from expand_decks_batch3_data import LOCALES, card, t, sc

OUT = Path(__file__).parent / "expand_decks_batch3_data_rest.py"


def T(*args):
    return t(*args)


def C(key, d, *args):
    return card(key, d, T(*args))


def A(key, d, m):
    assert set(m) == set(LOCALES), key
    return card(key, d, m)


def adapt_row(prefix, n, en, locs, d=1):
    m = {loc: en for loc in LOCALES}
    m["en"] = en
    m.update(locs)
    return A(f"{prefix}_{n:02d}", d, m)


NEW = {}

# tvCartoons 40
NEW["tvCartoons"] = [
    C("family_guy", 1, "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Padre de familia", "Family Guy", "Family Guy", "Les Griffin", "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Family Guy", "Гриффины", "Family Guy", "Гріфіни"),
    C("futurama", 1, "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Futurama", "Футурама", "Futurama", "Футурама"),
    C("american_dad", 1, "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "Padre americano", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "American Dad!", "Американский папаша", "American Dad!", "Американський тато"),
    C("king_hill", 1, "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "Les Rois du Texas", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "King of the Hill", "Царь горы", "King of the Hill", "Король пагорбів"),
    C("bob_burgers", 1, "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers", "Bob's Burgers"),
    C("archer", 2, "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Archer", "Арчер", "Archer", "Арчер"),
    C("bojack", 2, "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman", "BoJack Horseman"),
    C("amphibia", 1, "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia", "Amphibia"),
    C("owl_house", 1, "The Owl House", "Baykuş Evi", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House", "The Owl House"),
    C("ducktales", 1, "DuckTales", "DuckTales", "DuckTales", "DuckTales", "DuckTales", "DuckTales", "DuckTales", "Patoaventuras", "DuckTales", "DuckTales", "La Bande à Picsou", "DuckTales", "DuckTales", "DuckTales", "DuckTales", "DuckTales", "DuckTales", "DuckTales", "DuckTales", "DuckTales", "DuckTales", "Утиные истории", "DuckTales", "Качині історії"),
    C("darkwing", 1, "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "El Pato Darkwing", "Darkwing Duck", "Darkwing Duck", "Myster Mask", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Darkwing Duck", "Чёрный Плащ", "Darkwing Duck", "Чорний Плащ"),
    C("animaniacs", 1, "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs", "Animaniacs"),
    C("pink_panther", 1, "The Pink Panther", "Pembe Panter", "The Pink Panther", "The Pink Panther", "The Pink Panther", "The Pink Panther", "The Pink Panther", "La Pantera Rosa", "The Pink Panther", "The Pink Panther", "La Panthère rose", "The Pink Panther", "The Pink Panther", "The Pink Panther", "The Pink Panther", "The Pink Panther", "The Pink Panther", "The Pink Panther", "The Pink Panther", "The Pink Panther", "The Pink Panther", "Розовая пантера", "The Pink Panther", "Рожева пантера"),
    C("inspector_gadget", 1, "Inspector Gadget", "Müfettiş Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspecteur Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Inspector Gadget", "Инспектор Гаджет", "Inspector Gadget", "Інспектор Гаджет"),
    C("care_bears", 1, "Care Bears", "Sevimli Ayılar", "Care Bears", "Care Bears", "Care Bears", "Care Bears", "Care Bears", "Osos Amorosos", "Care Bears", "Care Bears", "Les Bisounours", "Care Bears", "Care Bears", "Care Bears", "Care Bears", "Care Bears", "Care Bears", "Care Bears", "Care Bears", "Care Bears", "Care Bears", "Мишки-заботы", "Care Bears", "Ведмедики-турботливі"),
    C("smurfs", 1, "The Smurfs", "Şirinler", "Die Schlümpfe", "The Smurfs", "The Smurfs", "The Smurfs", "The Smurfs", "Los Pitufos", "The Smurfs", "The Smurfs", "Les Schtroumpfs", "The Smurfs", "The Smurfs", "The Smurfs", "The Smurfs", "The Smurfs", "The Smurfs", "The Smurfs", "The Smurfs", "The Smurfs", "The Smurfs", "Смурфики", "The Smurfs", "Смurfики"),
    C("powerpuff", 1, "The Powerpuff Girls", "Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "Las Supernenas", "The Powerpuff Girls", "The Powerpuff Girls", "Les Super Nanas", "The Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "The Powerpuff Girls", "Суперкрошки", "The Powerpuff Girls", "Супердівчата"),
    C("johnny_bravo", 1, "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo", "Johnny Bravo"),
    C("courage_dog", 1, "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Coraje, el perro cobarde", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage le chien froussard", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Courage the Cowardly Dog", "Хrabryj pes", "Courage the Cowardly Dog", "Хоробрий пес"),
    C("dexter_lab", 1, "Dexter's Laboratory", "Dexter'ın Laboratuvarı", "Dexters Labor", "Dexter's Laboratory", "Dexter's Laboratory", "Dexter's Laboratory", "Dexter's Laboratory", "El laboratorio de Dexter", "Dexter's Laboratory", "Dexter's Laboratory", "Le Laboratoire de Dexter", "Dexter's Laboratory", "Dexter's Laboratory", "Dexter's Laboratory", "Dexter's Laboratory", "Dexter's Laboratory", "Dexter's Laboratory", "Dexter's Laboratory", "Dexter's Laboratory", "Dexter's Laboratory", "Dexter's Laboratory", "Лаборатория Декстера", "Dexter's Laboratory", "Лабораторія Декстера"),
    C("fairly_odd", 1, "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "Los padrinos mágicos", "The Fairly OddParents", "The Fairly OddParents", "Mes parrains sont magiques", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "The Fairly OddParents", "Волшебные родители", "The Fairly OddParents", "Чарівні батьки"),
    C("avatar_korra", 1, "The Legend of Korra", "Korra Efsanesi", "The Legend of Korra", "The Legend of Korra", "The Legend of Korra", "The Legend of Korra", "The Legend of Korra", "La leyenda de Korra", "The Legend of Korra", "The Legend of Korra", "La Légende de Korra", "The Legend of Korra", "The Legend of Korra", "The Legend of Korra", "The Legend of Korra", "The Legend of Korra", "The Legend of Korra", "The Legend of Korra", "The Legend of Korra", "The Legend of Korra", "The Legend of Korra", "Легенда о Корре", "The Legend of Korra", "Легенда про Korra"),
    C("over_garden", 1, "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall", "Over the Garden Wall"),
    C("star_forces", 1, "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. las fuerzas del mal", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. les Forces du Mal", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star vs. the Forces of Evil", "Star против сил зла", "Star vs. the Forces of Evil", "Star проти сил зла"),
    C("clone_high", 2, "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High", "Clone High"),
    C("foster_home", 1, "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends", "Foster's Home for Imaginary Friends"),
    C("flintstones", 1, "The Flintstones", "Taş Devri", "Die Flintstones", "The Flintstones", "The Flintstones", "The Flintstones", "The Flintstones", "Los Picapiedra", "The Flintstones", "The Flintstones", "Les Pierrafeu", "The Flintstones", "The Flintstones", "The Flintstones", "The Flintstones", "The Flintstones", "The Flintstones", "The Flintstones", "The Flintstones", "The Flintstones", "The Flintstones", "Флинстоуны", "The Flintstones", "Флінстоуни"),
    C("jetsons", 1, "The Jetsons", "Jetgiller", "Die Jetsons", "The Jetsons", "The Jetsons", "The Jetsons", "The Jetsons", "Los Supersónicos", "The Jetsons", "The Jetsons", "Les Jetson", "The Jetsons", "The Jetsons", "The Jetsons", "The Jetsons", "The Jetsons", "The Jetsons", "The Jetsons", "The Jetsons", "The Jetsons", "The Jetsons", "Джетсоны", "The Jetsons", "Джетсони"),
    C("speed_racer", 1, "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer", "Speed Racer"),
    C("he_man", 1, "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man", "He-Man"),
    C("she_ra", 1, "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra", "She-Ra"),
    C("thundercats", 1, "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats", "ThunderCats"),
    C("voltron", 1, "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron", "Voltron"),
    C("gumball", 1, "The Amazing World of Gumball", "Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "El asombroso mundo de Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "Le Monde incroyable de Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "The Amazing World of Gumball", "Удивительный мир Гамбола", "The Amazing World of Gumball", "Дивовижний світ Гамбола"),
    C("camp_lazlo", 1, "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo", "Camp Lazlo"),
    C("chowder", 1, "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder", "Chowder"),
    C("johnny_test", 1, "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test", "Johnny Test"),
    C("wacky_races", 1, "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races", "Wacky Races"),
    C("totally_spies", 1, "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!", "Totally Spies!"),
    C("winx_club", 1, "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club", "Winx Club"),
    C("avatar_legends", 1, "Avatar: The Last Airbender", "Avatar: Son Hava Bükücü", "Avatar: Der Herr der Elemente", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: La leyenda de Aang", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: Le Dernier Maître de l'air", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Avatar: The Last Airbender", "Аватар: Легенда об Аанге", "Avatar: The Last Airbender", "Аватар: Легенда про Aang"),
]

assert len(NEW["tvCartoons"]) == 40, len(NEW["tvCartoons"])

# Due to size, import remaining decks from companion module if present
try:
    from _build_rest_decks import add_remaining
    add_remaining(NEW, C, A, adapt_row, T, sc)
except ImportError:
    pass

# Validate counts
for deck, cards in NEW.items():
    if len(cards) != 40:
        raise SystemExit(f"{deck}: expected 40, got {len(cards)}")

# Serialize to Python source
parts = [
    '"""Remaining deck expansion data (batch 3 part 2)."""\n',
    "from expand_decks_batch3_data import LOCALES, card, t, sc\n\n",
    "NEW_CARDS = ",
    json.dumps(NEW, ensure_ascii=False, indent=2),
    "\n",
]
OUT.write_text("".join(parts), encoding="utf-8")
print(f"Wrote {OUT} with {len(NEW)} decks: {list(NEW.keys())}")
