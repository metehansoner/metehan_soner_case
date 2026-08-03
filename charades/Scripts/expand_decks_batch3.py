#!/usr/bin/env python3
"""Append 40 new cards to Movie/TV/Music/Kids/Sports/Knowledge decks."""
import json
from pathlib import Path

LOCALES = [
    "en", "tr", "de", "ar", "be", "ca", "cs", "da", "el", "es",
    "fi", "fil", "fr", "hr", "id", "it", "ms", "nb", "nl", "pl",
    "pt", "ro", "ru", "sv", "uk",
]

DECKS_DIR = Path(__file__).resolve().parent.parent / "Charades" / "Resources" / "Decks"

TARGET = 60

DECK_IDS = [
    "cartoonMovies", "superheroes", "villains", "tvSeries", "streaming", "movieQuotes",
    "horror", "scifi", "anime", "tvCartoons", "singers", "bands", "instruments", "lyrics",
    "genres", "kpop", "actors", "kidsFirst", "fairyTales", "toys", "colorsShapes", "school",
    "dinosaurs", "animalSounds", "fruits", "vehicles", "football", "basketball", "olympics",
    "combat", "extreme", "fitness", "footballers", "space", "inventions", "historyFigures",
    "famousWomen", "mythology", "science", "books", "body",
]


def append_deck(deck_id, new_cards):
    path = DECKS_DIR / f"{deck_id}.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    existing_keys = {c["k"] for c in data["cards"]}
    for c in new_cards:
        if c["k"] in existing_keys:
            raise ValueError(f"{deck_id}: duplicate key {c['k']}")
    data["cards"].extend(new_cards)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return len(data["cards"])


def main():
    from expand_decks_batch3_data import NEW_CARDS as BATCH3A
    try:
        from expand_decks_batch3_data_rest import NEW_CARDS as BATCH3B
        NEW_CARDS = {**BATCH3A, **BATCH3B}
    except ImportError:
        NEW_CARDS = BATCH3A

    results = {"reached_60": [], "remain": []}
    for deck_id in DECK_IDS:
        if deck_id not in NEW_CARDS:
            results["remain"].append((deck_id, "missing data"))
            continue
        cards = NEW_CARDS[deck_id]
        if len(cards) != 40:
            raise ValueError(f"{deck_id}: expected 40 new cards, got {len(cards)}")
        count = append_deck(deck_id, cards)
        if count >= TARGET:
            results["reached_60"].append((deck_id, count))
        else:
            results["remain"].append((deck_id, count))

    print("=== Reached 60 ===")
    for deck_id, count in results["reached_60"]:
        print(f"  {deck_id}: {count}")
    if results["remain"]:
        print("=== Remain ===")
        for deck_id, count in results["remain"]:
            print(f"  {deck_id}: {count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
