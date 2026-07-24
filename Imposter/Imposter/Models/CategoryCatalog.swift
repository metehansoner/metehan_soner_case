import Foundation

struct CategoryDef: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let descKey: String
    let imageName: String
    let isFree: Bool

    var isLocked: Bool { !isFree && !SubscriptionStore.shared.isPremium }
}

enum CategoryCatalog {
    static let all: [CategoryDef] = [
        .init(id: "party", titleKey: "categories.party", descKey: "categories.partyDesc", imageName: "category_party", isFree: true),
        .init(id: "football", titleKey: "categories.football", descKey: "categories.footballDesc", imageName: "category_football", isFree: true),
        .init(id: "food", titleKey: "categories.food", descKey: "categories.foodDesc", imageName: "category_food", isFree: false),
        .init(id: "celebs", titleKey: "categories.celebs", descKey: "categories.celebsDesc", imageName: "category_celebs", isFree: false),
        .init(id: "hobbies", titleKey: "categories.hobbies", descKey: "categories.hobbiesDesc", imageName: "category_hobbies", isFree: false),
        .init(id: "family", titleKey: "categories.family", descKey: "categories.familyDesc", imageName: "category_family", isFree: false),
        .init(id: "education", titleKey: "categories.education", descKey: "categories.educationDesc", imageName: "category_education", isFree: false),
        .init(id: "nature", titleKey: "categories.nature", descKey: "categories.natureDesc", imageName: "category_nature", isFree: false),
        .init(id: "characters", titleKey: "categories.characters", descKey: "categories.charactersDesc", imageName: "category_characters", isFree: false),
        .init(id: "jobs", titleKey: "categories.jobs", descKey: "categories.jobsDesc", imageName: "category_jobs", isFree: false),
        .init(id: "hollywood", titleKey: "categories.hollywood", descKey: "categories.hollywoodDesc", imageName: "category_hollywood", isFree: false),
        .init(id: "brands", titleKey: "categories.brands", descKey: "categories.brandsDesc", imageName: "category_brands", isFree: false),
        .init(id: "places", titleKey: "categories.places", descKey: "categories.placesDesc", imageName: "category_places", isFree: false),
        .init(id: "animals", titleKey: "categories.animals", descKey: "categories.animalsDesc", imageName: "category_animals", isFree: false),
        .init(id: "sports", titleKey: "categories.sports", descKey: "categories.sportsDesc", imageName: "category_sports", isFree: false),
        .init(id: "newyear", titleKey: "categories.newyear", descKey: "categories.newyearDesc", imageName: "category_newyear", isFree: false)
    ]

    static func recommendedImposters(for playerCount: Int) -> Int {
        switch playerCount {
        case ...5: return 1
        case 6...8: return 2
        default: return min(3, max(1, playerCount / 3))
        }
    }

    static func maxImposters(for playerCount: Int) -> Int {
        max(1, playerCount - 2)
    }
}
