import CoreText
import Foundation


struct Families {
    let display: String
    let accent: String
    let ui: String
}


func families(for locale: String) -> Families {
    switch locale {
    case "ar": Families(display: "Rubik", accent: "Rubik", ui: "Rubik")
    case "el": Families(display: "Fira Sans Condensed", accent: "EB Garamond", ui: "Fira Sans")
    default: Families(display: "Oswald", accent: "Playfair Display", ui: "Rubik")
    }
}


let preferredNames: [String: [String]] = [
    "Oswald": ["Oswald-Bold", "Oswald-SemiBold"],
    "Playfair Display": ["PlayfairDisplayRoman-Black", "PlayfairDisplayItalic-BoldItalic"],
    "Rubik": ["Rubik-Regular", "Rubik-Medium", "Rubik-SemiBold", "Rubik-Bold"],
    "Fira Sans Condensed": ["FiraSansCondensed-Bold", "FiraSansCondensed-ExtraBold"],
    "Fira Sans": ["FiraSans-Regular", "FiraSans-Medium", "FiraSans-SemiBold", "FiraSans-Bold"],
    "EB Garamond": ["EBGaramond-Bold", "EBGaramondItalic-BoldItalic"],
]


let samples: [String: String] = [
    "en": "Act It Out · 12",
    "tr": "Sessiz Sinema · 12 şğüöçİI",
    "ar": "تمثيل صامت · ١٢",
    "be": "Кракадзіл · 12",
    "ca": "Mímica · 12",
    "cs": "Šarády · 12",
    "da": "Charader · 12",
    "de": "Pantomime · 12 straßen",
    "el": "Παντομίμα · 12 ΓΎΡΟΣ",
    "es": "Mímica · 12",
    "fi": "Pantomiimi · 12",
    "fil": "Pantomima · 12",
    "fr": "Les Mimes · 12 éàç",
    "hr": "Pantomima · 12",
    "id": "Pantomim · 12",
    "it": "Mimo · 12",
    "ms": "Lakonan Bisu · 12",
    "nb": "Charader · 12 æøå",
    "nl": "Hints · 12",
    "pl": "Kalambury · 12 ąćęłńóśźż",
    "pt": "Mímica · 12 ãçõ",
    "ro": "Mimă · 12 ăâîșț",
    "ru": "Крокодил · 12",
    "sv": "Charader · 12 äöå",
    "uk": "Крокодил · 12 їєґ",
]

let fontsDirectory = URL(fileURLWithPath: CommandLine.arguments[1])

var registered: [String: CTFontDescriptor] = [:]
for file in (try? FileManager.default.contentsOfDirectory(atPath: fontsDirectory.path))?.sorted() ?? [] {
    guard file.hasSuffix(".ttf") else { continue }
    let url = fontsDirectory.appendingPathComponent(file)
    guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
          let descriptor = descriptors.first,
          let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String
    else {
        print("✗ okunamadı: \(file)")
        exit(1)
    }
    registered[name] = descriptor
}

var failures: [String] = []


for (family, names) in preferredNames.sorted(by: { $0.key < $1.key }) {
    for name in names where registered[name] == nil {
        failures.append("\(family): \(name) bundle'da yok")
    }
}


for (locale, sample) in samples.sorted(by: { $0.key < $1.key }) {
    let roles = families(for: locale)
    for (role, family) in [("display", roles.display), ("accent", roles.accent), ("ui", roles.ui)] {
        guard let name = preferredNames[family]?.first, let descriptor = registered[name] else {
            failures.append("\(locale)/\(role): \(family) çözülemedi")
            continue
        }
        let font = CTFontCreateWithFontDescriptor(descriptor, 24, nil)

        var missing: [Character] = []
        for character in sample where !character.isWhitespace {
            let utf16 = Array(String(character).utf16)
            var glyphs = [CGGlyph](repeating: 0, count: utf16.count)
            if !CTFontGetGlyphsForCharacters(font, utf16, &glyphs, utf16.count) {
                missing.append(character)
            }
        }
        if !missing.isEmpty {
            failures.append("\(locale)/\(role) (\(name)): eksik glif \(String(missing))")
        }
    }
}

if failures.isEmpty {
    print("✓ \(samples.count) locale × 3 rol — eksik glif yok (\(registered.count) font yüzü)")
    exit(0)
}
for failure in failures { print("✗ \(failure)") }
exit(1)
