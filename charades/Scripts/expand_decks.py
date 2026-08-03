#!/usr/bin/env python3
"""Append 40 new cards to each specified deck JSON file."""
import json
from pathlib import Path

LOCALES = [
    "en", "tr", "de", "ar", "be", "ca", "cs", "da", "el", "es",
    "fi", "fil", "fr", "hr", "id", "it", "ms", "nb", "nl", "pl",
    "pt", "ro", "ru", "sv", "uk",
]

DECKS_DIR = Path(__file__).resolve().parent.parent / "Charades" / "Resources" / "Decks"


def card(key, difficulty, translations):
    assert set(translations.keys()) == set(LOCALES), f"{key}: missing locales"
    return {"k": key, "d": difficulty, "t": {loc: translations[loc] for loc in LOCALES}}


def t(en, tr, de, ar, be, ca, cs, da, el, es, fi, fil, fr, hr, id_, it, ms, nb, nl, pl, pt, ro, ru, sv, uk):
    return dict(zip(LOCALES, [en, tr, de, ar, be, ca, cs, da, el, es, fi, fil, fr, hr, id_, it, ms, nb, nl, pl, pt, ro, ru, sv, uk]))


NEW_CARDS = {
    "jobs": [
        card("police_officer", 1, t("Police officer", "Polis", "Polizist", "ضابط شرطة", "Паліцыянт", "Agent de policia", "Policista", "Politibetjent", "Αστυνομικός", "Policía", "Poliisi", "Pulis", "Policier", "Policajac", "Petugas polisi", "Poliziotto", "Pegawai polis", "Politibetjent", "Politieagent", "Policjant", "Policial", "Polițist", "Полицейский", "Polis", "Поліцейський")),
        card("lawyer", 2, t("Lawyer", "Avukat", "Anwalt", "محامٍ", "Адвакат", "Advocat", "Právník", "Advokat", "Δικηγόρος", "Abogado", "Asianajaja", "Abogado", "Avocat", "Odvjetnik", "Pengacara", "Avvocato", "Peguam", "Advokat", "Advocaat", "Prawnik", "Advogado", "Avocat", "Адвокат", "Advokat", "Адвокат")),
        card("plumber", 1, t("Plumber", "Tesisatçı", "Klempner", "سبّاك", "Сантэхнік", "Llauner", "Instalatér", "Blikkenslager", "Υδραυλικός", "Fontanero", "Putkiasentaja", "Tubero", "Plombier", "Vodoinstalater", "Tukang ledeng", "Idraulico", "Tukang paip", "Rørlegger", "Loodgieter", "Hydraulik", "Canalizador", "Instalator", "Сантехник", "Rörmokare", "Сантехнік")),
        card("electrician", 1, t("Electrician", "Elektrikçi", "Elektriker", "كهربائي", "Электрык", "Electricista", "Elektrikář", "Elektriker", "Ηλεκτρολόγος", "Electricista", "Sähköasentaja", "Elektrisyan", "Électricien", "Električar", "Tukang listrik", "Elettricista", "Juruelektrik", "Elektriker", "Elektricien", "Elektryk", "Eletricista", "Electrician", "Электрик", "Elektriker", "Електрик")),
        card("carpenter", 1, t("Carpenter", "Marangoz", "Tischler", "نجّار", "Цярляр", "Fuster", "Truhlář", "Tømrer", "Ξυλουργός", "Carpintero", "Puuseppä", "Karpintero", "Charpentier", "Stolar", "Tukang kayu", "Falegname", "Tukang kayu", "Snekker", "Timmerman", "Stolarz", "Carpinteiro", "Tâmplar", "Плотник", "Snickare", "Столяр")),
        card("scientist", 2, t("Scientist", "Bilim insanı", "Wissenschaftler", "عالم", "Вучоны", "Científic", "Vědec", "Videnskabsmand", "Επιστήμονας", "Científico", "Tieteilijä", "Siyentipiko", "Scientifique", "Znanstvenik", "Ilmuwan", "Scienziato", "Saintis", "Forsker", "Wetenschapper", "Naukowiec", "Cientista", "Om de știință", "Учёный", "Forskare", "Вчений")),
        card("pharmacist", 1, t("Pharmacist", "Eczacı", "Apotheker", "صيدلي", "Фармацэўт", "Farmacèutic", "Lékárník", "Farmaceut", "Φαρμακοποιός", "Farmacéutico", "Farmaseutti", "Parmasyutiko", "Pharmacien", "Ljekarnik", "Apoteker", "Farmacista", "Ahli farmasi", "Farmasøyt", "Apotheker", "Farmaceuta", "Farmacêutico", "Farmacist", "Фармацевт", "Apotekare", "Фармацевт")),
        card("veterinarian", 1, t("Veterinarian", "Veteriner", "Tierarzt", "طبيب بيطري", "Ветерынар", "Veterinari", "Veterinář", "Dyrlæge", "Κτηνίατρος", "Veterinario", "Eläinlääkäri", "Beterinaryo", "Vétérinaire", "Veterinar", "Dokter hewan", "Veterinario", "Doktor haiwan", "Veterinær", "Dierenarts", "Weterynarz", "Veterinário", "Medic veterinar", "Ветеринар", "Veterinär", "Ветеринар")),
        card("librarian", 1, t("Librarian", "Kütüphaneci", "Bibliothekar", "أمين مكتبة", "Бібліятэкар", "Bibliotecari", "Knihovník", "Bibliotekar", "Βιβλιοθηκάριος", "Bibliotecario", "Kirjastonhoitaja", "Librarian", "Bibliothécaire", "Knjižničar", "Pustakawan", "Bibliotecario", "Pustakawan", "Bibliotekar", "Bibliothecaris", "Bibliotekarz", "Bibliotecário", "Bibliotecar", "Библиотекарь", "Bibliotekarie", "Бібліотекар")),
        card("cashier", 1, t("Cashier", "Kasiyer", "Kassierer", "أمين صندوق", "Касір", "Caixer", "Pokladní", "Kassemedarbejder", "Ταμίας", "Cajero", "Kassanhoitaja", "Cashier", "Caissier", "Blagajnik", "Kasir", "Cassiere", "Juruwang", "Kassemedarbeider", "Kassier", "Kasjer", "Caixa", "Casier", "Кассир", "Kassör", "Касир")),
        card("taxi_driver", 1, t("Taxi driver", "Taksici", "Taxifahrer", "سائق تاكسي", "Таксіст", "Taxista", "Taxikář", "Taxachauffør", "Οδηγός ταξί", "Taxista", "Taksinkuljettaja", "Taxi driver", "Chauffeur de taxi", "Taksist", "Sopir taksi", "Tassista", "Pemandu teksi", "Taxichauffør", "Taxichauffeur", "Taksówkarz", "Taxista", "Șofer de taxi", "Таксист", "Taxichaufför", "Таксист")),
        card("bus_driver", 1, t("Bus driver", "Otobüs şoförü", "Busfahrer", "سائق حافلة", "Вадзіцель аўтобуса", "Conductor d'autobús", "Řidič autobusu", "Buschauffør", "Οδηγός λεωφορείου", "Conductor de autobús", "Bussinkuljettaja", "Bus driver", "Chauffeur de bus", "Vozač autobusa", "Sopir bus", "Autista di autobus", "Pemandu bas", "Bussjåfør", "Buschauffeur", "Kierowca autobusu", "Motorista de autocarro", "Șofer de autobuz", "Водитель автобуса", "Busschaufför", "Водій автобуса")),
        card("lifeguard", 1, t("Lifeguard", "Cankurtaran", "Rettungsschwimmer", "منقذ", "Ратавальнік", "Socorrista", "Plavčík", "Livredder", "Ναυαγοσώστης", "Socorrista", "Uimavalvoja", "Lifeguard", "Maître-nageur", "Spasilac", "Penjaga pantai", "Bagnino", "Penjaga pantai", "Livredder", "Badmeester", "Ratownik", "Salva-vidas", "Salvamar", "Спасатель", "Livvakt", "Рятувальник")),
        card("personal_trainer", 1, t("Personal trainer", "Kişisel antrenör", "Personal Trainer", "مدرب شخصي", "Персанальны трэner", "Entrenador personal", "Osobní trenér", "Personlig træner", "Προσωπικός γυμναστής", "Entrenador personal", "Personal trainer", "Personal trainer", "Coach sportif", "Osobni trener", "Pelatih pribadi", "Personal trainer", "Jurulatih peribadi", "Personlig trener", "Personal trainer", "Trener personalny", "Personal trainer", "Antrenor personal", "Персональный тренер", "Personlig tränare", "Персональний тренер")),
        card("makeup_artist", 1, t("Makeup artist", "Makyaj sanatçısı", "Visagist", "فنان مكياج", "Вizaжyst", "Maquillador", "Vizažista", "Makeupartist", "Μακιγιέζ", "Maquillador", "Meikkitaiteilija", "Makeup artist", "Maquilleur", "Vizažist", "Penata rias", "Truccatore", "Jurusolek", "Sminkør", "Visagist", "Wizażysta", "Maquilhador", "Makeup artist", "Визажист", "Makeupartist", "Візажист")),
        card("journalist", 2, t("Journalist", "Gazeteci", "Journalist", "صحفي", "Журналіст", "Periodista", "Novinář", "Journalist", "Δημοσιογράφος", "Periodista", "Toimittaja", "Journalist", "Journaliste", "Novinar", "Wartawan", "Giornalista", "Wartawan", "Journalist", "Journalist", "Dziennikarz", "Jornalista", "Jurnalist", "Журналист", "Journalist", "Журналіст")),
        card("software_engineer", 2, t("Software engineer", "Yazılım mühendisi", "Softwareentwickler", "مهندس برمجيات", "Інжынер-праграміст", "Enginyer de software", "Softwarový inženýr", "Softwareingeniør", "Μηχανικός λογισμικού", "Ingeniero de software", "Ohjelmistosuunnittelija", "Software engineer", "Ingénieur logiciel", "Softverski inženjer", "Insinyur perangkat lunak", "Ingegnere del software", "Jurutera perisian", "Programvareingeniør", "Software engineer", "Inżynier oprogramowania", "Engenheiro de software", "Inginer software", "Программист", "Mjukvaruingenjör", "Інженер-програміст")),
        card("flight_attendant", 1, t("Flight attendant", "Uçuş görevlisi", "Flugbegleiter", "مضيف طيران", "Бортправаднік", "Auxiliar de vol", "Letuška", "Steward", "Αεροσυνοδός", "Azafata", "Lentoemäntä", "Flight attendant", "Hôtesse de l'air", "Stjuardesa", "Pramugari", "Assistente di volo", "Pramugara", "Flyvertinne", "Cabinepersoneel", "Stewardesa", "Comissário de bordo", "Stewardesă", "Стюардесса", "Flygvärdinna", "Бортпровідник")),
        card("paramedic", 1, t("Paramedic", "Paramedik", "Sanitäter", "مسعف", "Фельдшэр", "Paramèdic", "Záchranář", "Paramediciner", "Διακομιστής", "Paramédico", "Ensihoitaja", "Paramedic", "Ambulancier", "Medicinski tehničar", "Paramedis", "Paramedico", "Paramedik", "Ambulansearbeider", "Paramedicus", "Ratownik medyczny", "Paramédico", "Paramedic", "Фельдшер", "Ambulanspersonal", "Параmedic")),
        card("construction_worker", 1, t("Construction worker", "İnşaat işçisi", "Bauarbeiter", "عامل بناء", "Будаўнік", "Obrer de la construcció", "Stavební dělník", "Bygningsarbejder", "Οικοδόμος", "Obrero de construcción", "Rakennustyöläinen", "Construction worker", "Ouvrier du bâtiment", "Građevinski radnik", "Pekerja konstruksi", "Operaio edile", "Pekerja binaan", "Bygningsarbeider", "Bouwvakker", "Robotnik budowlany", "Operário da construção", "Muncitor în construcții", "Строитель", "Byggnadsarbetare", "Будівельник")),
        card("painter", 1, t("House painter", "Boyacı", "Maler", "دهّان", "Маляр", "Pintor", "Malíř", "Maler", "Βαφέας", "Pintor", "Maalari", "Pintor", "Peintre", "Soboslikar", "Tukang cat", "Imbianchino", "Tukang cat", "Maler", "Schilder", "Malarz", "Pintor", "Zugrav", "Маляр", "Målare", "Маляр")),
        card("gardener", 1, t("Gardener", "Bahçıvan", "Gärtner", "بستاني", "Садоўнік", "Jardiner", "Zahradník", "Gartner", "Κηπουρός", "Jardinero", "Puutarhurii", "Hardinero", "Jardinier", "Vrtlar", "Tukang kebun", "Giardiniere", "Tukang kebun", "Gartner", "Tuinier", "Ogrodnik", "Jardineiro", "Grădinar", "Садовник", "Trädgårdsmästare", "Садівник")),
        card("security_guard", 1, t("Security guard", "Güvenlik görevlisi", "Sicherheitsdienst", "حارس أمن", "Ахоўнік", "Guàrdia de seguretat", "Ostraha", "Vagt", "Φύλακας", "Guardia de seguridad", "Vartija", "Security guard", "Agent de sécurité", "Osoblje zaštite", "Petugas keamanan", "Guardia di sicurezza", "Pengawal keselamatan", "Vekter", "Beveiliger", "Ochroniarz", "Guarda de segurança", "Agent de pază", "Охранник", "Vakt", "Охоронець")),
        card("receptionist", 1, t("Receptionist", "Resepsiyonist", "Empfangsdame", "موظف استقبال", "Рэcepцыянер", "Recepcionista", "Recepční", "Receptionist", "Ρεσεψιονίστ", "Recepcionista", "Vastaanottovirkailija", "Receptionist", "Réceptionniste", "Recepcioner", "Resepsionis", "Receptionist", "Penyambut tetamu", "Resepsjonist", "Receptionist", "Recepcjonista", "Rececionista", "Recepționer", "Администратор", "Receptionist", "Адміністратор")),
        card("translator", 2, t("Translator", "Çevirmen", "Übersetzer", "مترجم", "Перакладчык", "Traductor", "Překladatel", "Oversætter", "Μεταφραστής", "Traductor", "Kääntäjä", "Tagasalin", "Traducteur", "Prevoditelj", "Penerjemah", "Traduttore", "Penterjemah", "Oversetter", "Vertaler", "Tłumacz", "Tradutor", "Traducător", "Переводчик", "Översättare", "Перекладач")),
        card("musician", 1, t("Musician", "Müzisyen", "Musiker", "موسيقي", "Музыкант", "Músic", "Hudebník", "Musiker", "Μουσικός", "Músico", "Muusikko", "Musikero", "Musicien", "Glazbenik", "Musisi", "Musicista", "Pemuzik", "Musiker", "Muzikant", "Muzyk", "Músico", "Muzician", "Музыкант", "Musiker", "Музикант")),
        card("actor", 1, t("Actor", "Aktör", "Schauspieler", "ممثل", "Аktor", "Actor", "Herec", "Skuespiller", "Ηθοποιός", "Actor", "Näyttelijä", "Aktor", "Acteur", "Glumac", "Aktor", "Attore", "Pelakon", "Skuespiller", "Acteur", "Aktor", "Ator", "Actor", "Актёр", "Skådespelare", "Актор")),
        card("fashion_designer", 2, t("Fashion designer", "Moda tasarımcısı", "Modedesigner", "مصمم أزياء", "Мадэльер", "Dissenyador de moda", "Módní návrhář", "Modedesigner", "Μοδίστρα", "Diseñador de moda", "Muotisuunnittelija", "Fashion designer", "Styliste", "Modni dizajner", "Perancang busana", "Stilista", "Pereka fesyen", "Motedesigner", "Modeontwerper", "Projektant mody", "Estilista", "Designer de modă", "Модельер", "Modedesigner", "Модельєр")),
        card("real_estate_agent", 1, t("Real estate agent", "Emlakçı", "Immobilienmakler", "وكيل عقارات", "Рэaltor", "Agent immobiliari", "Realitní makléř", "Ejendomsmægler", "Μεσίτης ακινήτων", "Agente inmobiliario", "Kiinteistönvälittäjä", "Real estate agent", "Agent immobilier", "Agent za nekretnine", "Agen properti", "Agente immobiliare", "Ejen hartanah", "Eiendomsmegler", "Makelaar", "Agent nieruchomości", "Agente imobiliário", "Agent imobiliar", "Риелтор", "Fastighetsmäklare", "Ріелтор")),
        card("banker", 1, t("Banker", "Bankacı", "Banker", "موظف بنك", "Банкір", "Banquer", "Bankéř", "Bankmand", "Τραπεζίτης", "Banquero", "Pankkiiri", "Banker", "Banquier", "Bankar", "Pegawai bank", "Banchiere", "Pegawai bank", "Bankmann", "Bankier", "Bankowiec", "Banqueiro", "Bancher", "Банкир", "Bankman", "Банкір")),
        card("accountant", 2, t("Accountant", "Muhasebeci", "Buchhalter", "محاسب", "Бухгалтар", "Comptable", "Účetní", "Revisor", "Λογιστής", "Contable", "Kirjanpitäjä", "Accountant", "Comptable", "Računovođa", "Akuntan", "Contabile", "Akauntan", "Regnskapsfører", "Accountant", "Księgowy", "Contabilista", "Contabil", "Бухгалтер", "Revisor", "Бухгалтер")),
        card("surgeon", 2, t("Surgeon", "Cerrah", "Chirurg", "جرّاح", "Хірург", "Cirurgià", "Chirurg", "Kirurg", "Χειρουργός", "Cirujano", "Kirurgi", "Surgeon", "Chirurgien", "Kirurg", "Ahli bedah", "Chirurgo", "Pakar bedah", "Kirurg", "Chirurg", "Chirurg", "Cirurgião", "Chirurg", "Хирург", "Kirurg", "Хірург")),
        card("midwife", 1, t("Midwife", "Ebe", "Hebamme", "قابلة", "Акушэрка", "Llevadora", "Porodní asistentka", "Jordemoder", "Μαία", "Comadrona", "Kätilö", "Midwife", "Sage-femme", "Primalja", "Bidan", "Ostetrica", "Bidan", "Jordmor", "Verloskundige", "Położna", "Parteira", "Moașă", "Акушерка", "Barnmorska", "Акушерка")),
        card("optometrist", 2, t("Optometrist", "Göz doktoru", "Optiker", "أخصائي بصريات", "Аптаметрыст", "Optometrista", "Optometrista", "Optiker", "Οπτικός", "Optometrista", "Optikko", "Optometrist", "Optométriste", "Optometrist", "Optometris", "Optometrista", "Optometris", "Optiker", "Opticien", "Optometrysta", "Optometrista", "Optometrist", "Окулист", "Optiker", "Окуліст")),
        card("social_worker", 2, t("Social worker", "Sosyal hizmet uzmanı", "Sozialarbeiter", "أخصائي اجتماعي", "Сацыяльны работнік", "Treballador social", "Sociální pracovník", "Socialrådgiver", "Κοινωνικός λειτουργός", "Trabajador social", "Sosiaalityöntekijä", "Social worker", "Travailleur social", "Socijalni radnik", "Pekerja sosial", "Assistente sociale", "Pekerja sosial", "Sosialarbeider", "Maatschappelijk werker", "Pracownik socjalny", "Assistente social", "Asistent social", "Социальный работник", "Socialarbetare", "Соціальний працівник")),
        card("babysitter", 1, t("Babysitter", "Bebek bakıcısı", "Babysitter", "جليسة أطفال", "Нянька", "Cuidadora de nens", "Chůva", "Babysitter", "Νταντά", "Niñera", "Lastenhoitaja", "Babysitter", "Baby-sitter", "Dadilja", "Pengasuh anak", "Baby-sitter", "Pengasuh", "Barnevakt", "Oppas", "Opiekunka", "Babysitter", "Bonă", "Няня", "Barnvakt", "Няня")),
        card("tour_guide", 1, t("Tour guide", "Tur rehberi", "Reiseführer", "دليل سياحي", "Гід", "Guia turístic", "Průvodce", "Turistguide", "Ξεναγός", "Guía turístico", "Matkaopas", "Tour guide", "Guide touristique", "Turistički vodič", "Pemandu wisata", "Guida turistica", "Pemandu pelancong", "Turistguide", "Gids", "Przewodnik turystyczny", "Guia turístico", "Ghid turistic", "Экскурсовод", "Resguide", "Екскурсовод")),
        card("fisherman", 1, t("Fisherman", "Balıkçı", "Fischer", "صيّاد", "Рыбак", "Pescador", "Rybář", "Fisker", "Ψαράς", "Pescador", "Kalastaja", "Mangingisda", "Pêcheur", "Ribič", "Nelayan", "Pescatore", "Nelayan", "Fisker", "Visser", "Rybak", "Pescador", "Pescar", "Рыбак", "Fiskare", "Рибалка")),
        card("miner", 2, t("Miner", "Madenci", "Bergmann", "عامل منجم", "Шахтар", "Minador", "Horník", "Minearbejder", "Μεταλλωρύχος", "Minero", "Kaivosmies", "Minero", "Mineur", "Rudar", "Penambang", "Minatore", "Pelombong", "Gruvearbeider", "Mijnwerker", "Górnik", "Mineiro", "Miner", "Шахтёр", "Gruvarbetare", "Шахтар")),
        card("postal_worker", 1, t("Postal worker", "Postacı", "Briefträger", "ساعي بريد", "Поштар", "Carter", "Pošťák", "Postbud", "Ταχυδρόμος", "Cartero", "Postinjakaja", "Postal worker", "Facteur", "Poštar", "Petugas pos", "Postino", "Pekerja pos", "Postbud", "Postbode", "Listonosz", "Carteiro", "Poștaș", "Почтальон", "Brevbärare", "Листоноша")),
    ],
}


def main():
    from expand_decks_data import NEW_CARDS as MORE_CARDS

    all_new = {**NEW_CARDS, **MORE_CARDS}
    deck_ids = ["jobs", "emotions", "animalsAct", "chores", "sportsAct", "dance", "superpowers", "badHabits"]
    results = []

    for deck_id in deck_ids:
        path = DECKS_DIR / f"{deck_id}.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        existing_keys = {c["k"] for c in data["cards"]}
        new_cards = all_new[deck_id]
        for c in new_cards:
            if c["k"] in existing_keys:
                raise ValueError(f"{deck_id}: duplicate key {c['k']}")
        data["cards"].extend(new_cards)
        if len(data["cards"]) < 60:
            raise ValueError(f"{deck_id}: only {len(data['cards'])} cards after append")
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        results.append((deck_id, len(data["cards"])))

    for deck_id, count in results:
        print(f"{deck_id}: {count} cards")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
