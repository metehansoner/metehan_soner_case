#!/usr/bin/env python3
"""Generate expand_decks_batch3_data_rest.py with all 32 remaining decks."""
import json
from pathlib import Path
from expand_decks_batch3_data import LOCALES, card, t, sc

OUT = Path(__file__).parent / "expand_decks_batch3_data_rest.py"


def fill(en, overrides):
    m = {loc: en for loc in LOCALES}
    m["en"] = en
    m.update(overrides)
    return m


def lit(key, d, en, o):
    return card(key, d, fill(en, o))


def adapt(key, d, en, o, od=1):
    return card(key, d, fill(en, o))


def adapt_list(prefix, start, items, d=1):
    out = []
    for i, (en, locs) in enumerate(items, start=start):
        dd = locs.pop("_d", d) if isinstance(locs, dict) else d
        out.append(adapt(f"{prefix}_{i:02d}", dd, en, locs))
    return out


def lit_list(items):
    return [lit(k, d, e, o) for k, d, e, o in items]


NEW = {}

# tvCartoons
NEW["tvCartoons"] = lit_list([
    ("family_guy", 1, "Family Guy", {"es": "Padre de familia", "fr": "Les Griffin", "ru": "Гриффины", "uk": "Гріфіни"}),
    ("futurama", 1, "Futurama", {"ru": "Футурама", "uk": "Футурама"}),
    ("american_dad", 1, "American Dad!", {"es": "Padre americano", "ru": "Американский папаша", "uk": "Американський тато"}),
    ("king_hill", 1, "King of the Hill", {"fr": "Les Rois du Texas", "ru": "Царь горы", "uk": "Король пагорбів"}),
    ("bob_burgers", 1, "Bob's Burgers", {}),
    ("archer", 2, "Archer", {"ru": "Арчер", "uk": "Арчер"}),
    ("bojack", 2, "BoJack Horseman", {}),
    ("amphibia", 1, "Amphibia", {"ru": "Амфибия", "uk": "Амфібія"}),
    ("owl_house", 1, "The Owl House", {"tr": "Baykuş Evi", "uk": "Будинок сови"}),
    ("ducktales", 1, "DuckTales", {"es": "Patoaventuras", "fr": "La Bande à Picsou", "ru": "Утиные истории", "uk": "Качині історії"}),
    ("darkwing", 1, "Darkwing Duck", {"es": "El Pato Darkwing", "fr": "Myster Mask", "ru": "Чёрный Плащ", "uk": "Чорний Плащ"}),
    ("animaniacs", 1, "Animaniacs", {}),
    ("pink_panther", 1, "The Pink Panther", {"tr": "Pembe Panter", "es": "La Pantera Rosa", "fr": "La Panthère rose", "ru": "Розовая пантера", "uk": "Рожева пантера"}),
    ("inspector_gadget", 1, "Inspector Gadget", {"tr": "Müfettiş Gadget", "fr": "Inspecteur Gadget", "ru": "Инспектор Гаджет", "uk": "Інспектор Гаджет"}),
    ("care_bears", 1, "Care Bears", {"tr": "Sevimli Ayılar", "es": "Osos Amorosos", "fr": "Les Bisounours", "ru": "Мишки-заботы", "uk": "Ведмедики-турботливі"}),
    ("smurfs", 1, "The Smurfs", {"tr": "Şirinler", "de": "Die Schlümpfe", "es": "Los Pitufos", "fr": "Les Schtroumpfs", "ru": "Смурфики", "uk": "Смurfики"}),
    ("powerpuff", 1, "The Powerpuff Girls", {"tr": "Powerpuff Girls", "es": "Las Supernenas", "fr": "Les Super Nanas", "ru": "Суперкрошки", "uk": "Супердівчата"}),
    ("johnny_bravo", 1, "Johnny Bravo", {}),
    ("courage_dog", 1, "Courage the Cowardly Dog", {"es": "Coraje, el perro cobarde", "fr": "Courage le chien froussard", "ru": "Хrabryj pes", "uk": "Хоробрий пес"}),
    ("dexter_lab", 1, "Dexter's Laboratory", {"tr": "Dexter'ın Laboratuvarı", "de": "Dexters Labor", "es": "El laboratorio de Dexter", "fr": "Le Laboratoire de Dexter", "ru": "Лаборатория Декстера", "uk": "Лабораторія Декстера"}),
    ("fairly_odd", 1, "The Fairly OddParents", {"es": "Los padrinos mágicos", "fr": "Mes parrains sont magiques", "ru": "Волшебные родители", "uk": "Чарівні батьки"}),
    ("avatar_korra", 1, "The Legend of Korra", {"tr": "Korra Efsanesi", "es": "La leyenda de Korra", "fr": "La Légende de Korra", "ru": "Легенда о Корре", "uk": "Легенда про Korra"}),
    ("over_garden", 1, "Over the Garden Wall", {}),
    ("star_forces", 1, "Star vs. the Forces of Evil", {"es": "Star vs. las fuerzas del mal", "fr": "Star vs. les Forces du Mal", "ru": "Star против сил зла", "uk": "Star проти сил зла"}),
    ("clone_high", 2, "Clone High", {}),
    ("foster_home", 1, "Foster's Home for Imaginary Friends", {}),
    ("flintstones", 1, "The Flintstones", {"tr": "Taş Devri", "de": "Die Flintstones", "es": "Los Picapiedra", "fr": "Les Pierrafeu", "ru": "Флинстоуны", "uk": "Флінстоуни"}),
    ("jetsons", 1, "The Jetsons", {"tr": "Jetgiller", "de": "Die Jetsons", "es": "Los Supersónicos", "fr": "Les Jetson", "ru": "Джетсоны", "uk": "Джетсони"}),
    ("speed_racer", 1, "Speed Racer", {}),
    ("he_man", 1, "He-Man", {}),
    ("she_ra", 1, "She-Ra", {}),
    ("thundercats", 1, "ThunderCats", {}),
    ("voltron", 1, "Voltron", {}),
    ("gumball", 1, "The Amazing World of Gumball", {"tr": "Gumball", "es": "El asombroso mundo de Gumball", "fr": "Le Monde incroyable de Gumball", "ru": "Удивительный мир Гамбола", "uk": "Дивовижний світ Гамбола"}),
    ("camp_lazlo", 1, "Camp Lazlo", {}),
    ("chowder", 1, "Chowder", {}),
    ("johnny_test", 1, "Johnny Test", {}),
    ("wacky_races", 1, "Wacky Races", {}),
    ("totally_spies", 1, "Totally Spies!", {}),
    ("winx_club", 1, "Winx Club", {}),
])

# instruments
NEW["instruments"] = lit_list([
    ("mandolin", 1, "Mandolin", {"tr": "Mandolin", "de": "Mandoline", "ar": "ماندولين", "es": "Mandolina", "fr": "Mandoline", "ru": "Мандолина", "uk": "Мандоліна"}),
    ("oboe", 1, "Oboe", {"tr": "Obua", "de": "Oboe", "ar": "أوبوا", "es": "Oboe", "fr": "Hautbois", "ru": "Гобой", "uk": "Гобой"}),
    ("french_horn", 1, "French horn", {"tr": "Korno", "de": "Waldhorn", "ar": "بوق", "es": "Trompa", "fr": "Cor d'harmonie", "ru": "Валторна", "uk": "Валторна"}),
    ("tuba", 1, "Tuba", {"tr": "Tuba", "de": "Tuba", "ar": "تuba", "es": "Tuba", "fr": "Tuba", "ru": "Тuba", "uk": "Тuba"}),
    ("organ", 1, "Organ", {"tr": "Org", "de": "Orgel", "ar": "أرgan", "es": "Órgano", "fr": "Orgue", "ru": "Орган", "uk": "Орган"}),
    ("maracas", 1, "Maracas", {"tr": "Marakas", "de": "Maracas", "ar": "مارacas", "es": "Maracas", "fr": "Maracas", "ru": "Маракасы", "uk": "Маракаси"}),
    ("castanets", 1, "Castanets", {"tr": "Kastanyet", "de": "Kastagnetten", "ar": "كستانيت", "es": "Castañuelas", "fr": "Castagnettes", "ru": "Кастañеты", "uk": "Кастañети"}),
    ("conga", 1, "Conga drum", {"tr": "Konga", "de": "Conga", "es": "Conga", "fr": "Conga", "ru": "Кonga", "uk": "Кonga"}),
    ("bongo", 1, "Bongo drums", {"tr": "Bongo", "de": "Bongos", "es": "Bongós", "fr": "Bongos", "ru": "Бongos", "uk": "Бongos"}),
    ("triangle_i", 1, "Triangle", {"tr": "Üçgen", "de": "Triangel", "ar": "مثلث", "es": "Triángulo", "fr": "Triangle", "ru": "Треугольник", "uk": "Трикутник"}),
    ("recorder", 1, "Recorder", {"tr": "Blok flüt", "de": "Blockflöte", "ar": "مزمار", "es": "Flauta dulce", "fr": "Flûte à bec", "ru": "Блокфлейта", "uk": "Сопілка"}),
    ("pan_flute", 1, "Pan flute", {"tr": "Pan flüt", "de": "Panflöte", "es": "Flauta de pan", "fr": "Flûte de Pan", "ru": "Пан-флейта", "uk": "Пан-флейта"}),
    ("didgeridoo", 2, "Didgeridoo", {}),
    ("steel_drum", 1, "Steel drum", {"tr": "Çelik davul", "de": "Steel Drum", "es": "Steel drum", "fr": "Steel drum"}),
    ("gong", 1, "Gong", {"tr": "Gong", "de": "Gong", "ar": "Gong", "fr": "Gong", "ru": "Gong", "uk": "Gong"}),
    ("cymbals", 1, "Cymbals", {"tr": "Zil", "de": "Becken", "ar": "صنج", "es": "Platillos", "fr": "Cymbales", "ru": "Тарелки", "uk": "Тарелки"}),
    ("marimba", 2, "Marimba", {}),
    ("vibraphone", 2, "Vibraphone", {"de": "Vibraphon", "es": "Vibrafono", "fr": "Vibraphone"}),
    ("double_bass", 1, "Double bass", {"tr": "Kontrbas", "de": "Kontrabass", "es": "Contrabajo", "fr": "Contrebasse", "ru": "Контрабас", "uk": "Контрабас"}),
    ("electric_guitar", 1, "Electric guitar", {"tr": "Elektro gitar", "de": "E-Gitarre", "ar": "جيتار كهربائي", "es": "Guitarra eléctrica", "fr": "Guitare électrique", "ru": "Электрогитара", "uk": "Електрогітара"}),
    ("keytar", 2, "Keytar", {}),
    ("melodica", 2, "Melodica", {"tr": "Melodika", "de": "Melodica", "es": "Melódica"}),
    ("autoharp", 2, "Autoharp", {}),
    ("zither", 2, "Zither", {"tr": "Kanun", "de": "Zither", "es": "Cítara", "fr": "Cithare", "ru": "Цитра", "uk": "Цитра"}),
    ("sitar", 2, "Sitar", {}),
    ("tabla", 2, "Tabla", {}),
    ("djembe", 1, "Djembe", {"fr": "Djembé"}),
    ("kazoo", 1, "Kazoo", {}),
    ("whistle_m", 1, "Whistle", {"tr": "Düdük", "de": "Pfeife", "ar": "صافرة", "es": "Silbato", "fr": "Sifflet", "ru": "Свисток", "uk": "Свисток"}),
    ("cowbell", 1, "Cowbell", {"tr": "İnek çanı", "de": "Kuhglocke", "ar": "جرس", "es": "Cencerro", "fr": "Cloche"}),
    ("rainstick", 2, "Rainstick", {}),
    ("theremin", 2, "Theremin", {"fr": "Thérémine", "ru": "Терemin", "uk": "Терemin"}),
    ("drum_machine", 1, "Drum machine", {"tr": "Drum makinesi", "de": "Drum Machine", "ar": "آلة الطبول", "es": "Caja de ritmos", "fr": "Boîte à rythmes"}),
    ("turntable", 1, "Turntable", {"tr": "Pikap", "de": "Plattenspieler", "es": "Tocadiscos", "fr": "Platine"}),
    ("microphone_inst", 1, "Microphone", {"tr": "Mikrofon", "de": "Mikrofon", "ar": "ميكrofon", "es": "Micrófono", "fr": "Microphone", "ru": "Микрофон", "uk": "Мікрофон"}),
    ("music_stand", 1, "Music stand", {"tr": "Nota sehpası", "de": "Notenständer", "ar": "حامل", "es": "Atril", "fr": "Pupitre", "ru": "Пюпитр", "uk": "Пюпітр"}),
    ("metronome", 1, "Metronome", {"tr": "Metronom", "de": "Metronom", "es": "Metrónomo", "fr": "Métronome", "ru": "Метronome", "uk": "Метronome"}),
    ("pick_guitar", 1, "Guitar pick", {"tr": "Pençe", "de": "Plektrum", "es": "Púa", "fr": "Médiator", "ru": "Мediator", "uk": "Мediator"}),
    ("capo", 2, "Capo", {"tr": "Kapo", "de": "Kapodaster", "es": "Cejilla", "fr": "Capodastre"}),
])

# genres
NEW["genres"] = lit_list([
    ("indie", 1, "Indie", {"tr": "Indie", "de": "Indie", "es": "Indie", "fr": "Indie", "ru": "Инди", "uk": "Інді"}),
    ("edm", 1, "EDM", {"tr": "EDM", "de": "EDM", "es": "EDM", "fr": "EDM", "ru": "EDM", "uk": "EDM"}),
    ("house", 1, "House music", {"tr": "House", "de": "House", "es": "House", "fr": "House", "ru": "House", "uk": "House"}),
    ("trance", 1, "Trance", {"tr": "Trance", "de": "Trance", "es": "Trance", "fr": "Trance", "ru": "Trance", "uk": "Trance"}),
    ("dubstep", 1, "Dubstep", {"tr": "Dubstep", "de": "Dubstep", "es": "Dubstep", "fr": "Dubstep", "ru": "Dubstep", "uk": "Dubstep"}),
    ("grime", 2, "Grime", {"tr": "Grime", "de": "Grime", "es": "Grime", "fr": "Grime", "ru": "Grime", "uk": "Grime"}),
    ("afrobeats", 1, "Afrobeats", {"tr": "Afrobeats", "de": "Afrobeats", "es": "Afrobeats", "fr": "Afrobeats", "ru": "Afrobeats", "uk": "Afrobeats"}),
    ("reggaeton", 1, "Reggaeton", {"tr": "Reggaeton", "de": "Reggaeton", "es": "Reggaetón", "fr": "Reggaeton", "ru": "Reggaeton", "uk": "Reggaeton"}),
    ("trap", 1, "Trap", {"tr": "Trap", "de": "Trap", "es": "Trap", "fr": "Trap", "ru": "Trap", "uk": "Trap"}),
    ("drill", 1, "Drill", {"tr": "Drill", "de": "Drill", "es": "Drill", "fr": "Drill", "ru": "Drill", "uk": "Drill"}),
    ("gospel", 1, "Gospel", {"tr": "Gospel", "de": "Gospel", "es": "Gospel", "fr": "Gospel", "ru": "Gospel", "uk": "Gospel"}),
    ("blues_rock", 1, "Blues rock", {"tr": "Blues rock", "de": "Blues-Rock", "es": "Blues rock", "fr": "Blues rock", "ru": "Blues rock", "uk": "Blues rock"}),
    ("progressive", 2, "Progressive rock", {"tr": "Progressive rock", "de": "Progressive Rock", "es": "Rock progresivo", "fr": "Rock progressif", "ru": "Progressive rock", "uk": "Progressive rock"}),
    ("hard_rock", 1, "Hard rock", {"tr": "Hard rock", "de": "Hard Rock", "es": "Hard rock", "fr": "Hard rock", "ru": "Hard rock", "uk": "Hard rock"}),
    ("alternative", 1, "Alternative rock", {"tr": "Alternatif rock", "de": "Alternative Rock", "es": "Rock alternativo", "fr": "Rock alternatif", "ru": "Alternative rock", "uk": "Alternative rock"}),
    ("ambient", 2, "Ambient", {"tr": "Ambient", "de": "Ambient", "es": "Ambient", "fr": "Ambient", "ru": "Ambient", "uk": "Ambient"}),
    ("lofi", 1, "Lo-fi", {"tr": "Lo-fi", "de": "Lo-fi", "es": "Lo-fi", "fr": "Lo-fi", "ru": "Lo-fi", "uk": "Lo-fi"}),
    ("swing", 1, "Swing", {"tr": "Swing", "de": "Swing", "es": "Swing", "fr": "Swing", "ru": "Swing", "uk": "Swing"}),
    ("bossa_nova", 2, "Bossa nova", {"tr": "Bossa nova", "de": "Bossa Nova", "es": "Bossa nova", "fr": "Bossa nova", "ru": "Bossa nova", "uk": "Bossa nova"}),
    ("flamenco", 2, "Flamenco", {"tr": "Flamenko", "de": "Flamenco", "es": "Flamenco", "fr": "Flamenco", "ru": "Flamenco", "uk": "Flamenco"}),
    ("tango", 1, "Tango", {"tr": "Tango", "de": "Tango", "es": "Tango", "fr": "Tango", "ru": "Tango", "uk": "Tango"}),
    ("cumbia", 2, "Cumbia", {"tr": "Cumbia", "de": "Cumbia", "es": "Cumbia", "fr": "Cumbia", "ru": "Cumbia", "uk": "Cumbia"}),
    ("ska", 2, "Ska", {"tr": "Ska", "de": "Ska", "es": "Ska", "fr": "Ska", "ru": "Ska", "uk": "Ska"}),
    ("grunge", 1, "Grunge", {"tr": "Grunge", "de": "Grunge", "es": "Grunge", "fr": "Grunge", "ru": "Grunge", "uk": "Grunge"}),
    ("emo", 1, "Emo", {"tr": "Emo", "de": "Emo", "es": "Emo", "fr": "Emo", "ru": "Emo", "uk": "Emo"}),
    ("shoegaze", 2, "Shoegaze", {"tr": "Shoegaze", "de": "Shoegaze", "es": "Shoegaze", "fr": "Shoegaze", "ru": "Shoegaze", "uk": "Shoegaze"}),
    ("new_wave", 2, "New wave", {"tr": "New wave", "de": "New Wave", "es": "New wave", "fr": "New wave", "ru": "New wave", "uk": "New wave"}),
    ("synthpop", 1, "Synth-pop", {"tr": "Synth-pop", "de": "Synth-Pop", "es": "Synth-pop", "fr": "Synth-pop", "ru": "Synth-pop", "uk": "Synth-pop"}),
    ("baroque", 2, "Baroque", {"tr": "Barok", "de": "Barock", "es": "Barroco", "fr": "Baroque", "ru": "Baroque", "uk": "Baroque"}),
    ("romantic", 2, "Romantic classical", {"tr": "Romantik", "de": "Romantik", "es": "Romanticismo", "fr": "Romantisme", "ru": "Romantic classical", "uk": "Romantic classical"}),
    ("world_music", 1, "World music", {"tr": "Dünya müziği", "de": "Weltmusik", "es": "Música del mundo", "fr": "Musique du monde", "ru": "World music", "uk": "World music"}),
    ("soundtrack", 1, "Soundtrack", {"tr": "Film müziği", "de": "Soundtrack", "es": "Banda sonora", "fr": "Bande originale", "ru": "Soundtrack", "uk": "Soundtrack"}),
    ("children_music", 1, "Children's music", {"tr": "Çocuk müziği", "de": "Kinderlieder", "es": "Música infantil", "fr": "Musique pour enfants", "ru": "Children's music", "uk": "Children's music"}),
    ("acapella", 2, "A cappella", {"tr": "A cappella", "de": "A cappella", "es": "A cappella", "fr": "A cappella", "ru": "A cappella", "uk": "A cappella"}),
    ("instrumental", 1, "Instrumental", {"tr": "Enstrümantal", "de": "Instrumental", "es": "Instrumental", "fr": "Instrumental", "ru": "Instrumental", "uk": "Instrumental"}),
    ("chillout", 1, "Chillout", {"tr": "Chillout", "de": "Chillout", "es": "Chillout", "fr": "Chillout", "ru": "Chillout", "uk": "Chillout"}),
    ("garage", 2, "Garage rock", {"tr": "Garage rock", "de": "Garage Rock", "es": "Garage rock", "fr": "Garage rock", "ru": "Garage rock", "uk": "Garage rock"}),
    ("motown", 2, "Motown", {"tr": "Motown", "de": "Motown", "es": "Motown", "fr": "Motown", "ru": "Motown", "uk": "Motown"}),
    ("funk", 1, "Funk", {"tr": "Funk", "de": "Funk", "es": "Funk", "fr": "Funk", "ru": "Funk", "uk": "Funk"}),
    ("dancehall", 1, "Dancehall", {"tr": "Dancehall", "de": "Dancehall", "es": "Dancehall", "fr": "Dancehall", "ru": "Dancehall", "uk": "Dancehall"}),
])

# kpop
NEW["kpop"] = [card(k, d, sc(n, ar=n, ru=n, uk=n)) if d == 1 else card(k, d, fill(n, {})) for k, d, n in [
    ("ateez", 1, "ATEEZ"), ("gidle_k", 1, "(G)I-DLE"), ("mamamoo", 1, "MAMAMOO"), ("got7", 1, "GOT7"), ("monsta_x", 1, "MONSTA X"),
    ("shinee", 1, "SHINee"), ("super_junior", 1, "Super Junior"), ("girls_generation", 1, "Girls' Generation"), ("bigbang", 1, "BIGBANG"), ("2ne1", 1, "2NE1"),
    ("wanna_one", 1, "Wanna One"), ("ioi", 1, "I.O.I"), ("fromis_9", 1, "fromis_9"), ("everglow", 1, "EVERGLOW"), ("dreamcatcher", 1, "Dreamcatcher"),
    ("mamamoo_solar", 1, "Solar"), ("iu", 1, "IU"), ("psy", 1, "PSY"), ("jhope", 1, "j-hope"), ("suga", 1, "SUGA"),
    ("v_bts", 1, "V"), ("jimin", 1, "Jimin"), ("taeyang", 1, "Taeyang"), ("gdragon", 1, "G-Dragon"), ("rose_bp", 1, "Rosé"),
    ("jisoo", 1, "Jisoo"), ("chaeyoung", 1, "Chaeyoung"), ("sana", 1, "Sana"), ("momo", 1, "Momo"), ("nayeon", 1, "Nayeon"),
    ("hyunjin", 1, "Hyunjin"), ("felix", 1, "Felix"), ("yeonjun", 1, "Yeonjun"), ("karina", 1, "Karina"), ("winter_aespa", 1, "Winter"),
    ("wonyoung", 1, "Wonyoung"), ("yujin", 1, "Yujin"), ("sakura", 1, "Sakura"), ("kazuha", 1, "Kazuha"), ("chaewon", 1, "Chaewon"),
]]

# Fix kpop cards - use sc properly
NEW["kpop"] = [card(k, d, fill(n, {"ar": n, "ru": n, "uk": n})) for k, d, n in [
    ("ateez", 1, "ATEEZ"), ("mamamoo", 1, "MAMAMOO"), ("got7", 1, "GOT7"), ("monsta_x", 1, "MONSTA X"),
    ("shinee", 1, "SHINee"), ("super_junior", 1, "Super Junior"), ("girls_gen", 1, "Girls' Generation"), ("bigbang", 1, "BIGBANG"), ("twice_n", 1, "2NE1"),
    ("wanna_one", 1, "Wanna One"), ("fromis_9", 1, "fromis_9"), ("everglow", 1, "EVERGLOW"), ("dreamcatcher", 1, "Dreamcatcher"),
    ("iu", 1, "IU"), ("psy", 1, "PSY"), ("jhope", 1, "j-hope"), ("suga", 1, "SUGA"), ("v_bts", 1, "V"), ("jimin_k", 1, "Jimin"),
    ("taeyang", 1, "Taeyang"), ("gdragon", 1, "G-Dragon"), ("rose_bp", 1, "Rosé"), ("jisoo", 1, "Jisoo"), ("chaeyoung", 1, "Chaeyoung"),
    ("sana", 1, "Sana"), ("momo", 1, "Momo"), ("nayeon", 1, "Nayeon"), ("hyunjin", 1, "Hyunjin"), ("felix", 1, "Felix"),
    ("yeonjun", 1, "Yeonjun"), ("karina", 1, "Karina"), ("winter_a", 1, "Winter"), ("wonyoung", 1, "Wonyoung"), ("yujin", 1, "Yujin"),
    ("sakura_k", 1, "Sakura"), ("kazuha", 1, "Kazuha"), ("chaewon", 1, "Chaewon"), ("sunmi", 1, "Sunmi"), ("hwasa", 1, "Hwasa"),
    ("dahyun", 1, "Dahyun"), ("minji", 1, "Minji"), ("haerin", 1, "Haerin"), ("hanni", 1, "Hanni"),
]]

# Continue with more decks in part 2 - import from extension
from _build_all_decks_ext import extend  # noqa: E402
extend(NEW, lit, lit_list, adapt, adapt_list, fill, card, sc, t)

for deck, cards in NEW.items():
    if len(cards) != 40:
        raise SystemExit(f"{deck}: expected 40, got {len(cards)}")

OUT.write_text(
    '"""Remaining deck expansion data (batch 3 part 2)."""\n\nNEW_CARDS = '
    + json.dumps(NEW, ensure_ascii=False, indent=2)
    + "\n",
    encoding="utf-8",
)
print(f"Wrote {OUT} with {len(NEW)} decks")
