import Foundation

struct Product: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var category: ProductCategory
    var period: Period
    var ingredients: [String]
    var ingredientTags: [IngredientTag]
    var isActive: Bool
    var addedDate: Date
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, category: ProductCategory, period: Period, ingredients: [String] = [], ingredientTags: [IngredientTag] = [], isActive: Bool = true, addedDate: Date = .now, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.category = category
        self.period = period
        self.ingredients = ingredients
        self.ingredientTags = ingredientTags
        self.isActive = isActive
        self.addedDate = addedDate
        self.sortOrder = sortOrder
    }
}

enum ProductCategory: String, CaseIterable, Codable {
    case cleanser, toner, serum, moisturizer, sunscreen, treatment, mask, other

    var displayName: String {
        switch self {
        case .cleanser: "Cleanser"
        case .toner: "Toner"
        case .serum: "Serum"
        case .moisturizer: "Moisturizer"
        case .sunscreen: "Sunscreen"
        case .treatment: "Treatment"
        case .mask: "Mask"
        case .other: "Other"
        }
    }
}

enum Period: String, CaseIterable, Codable {
    case morning, evening, both

    var displayName: String {
        switch self {
        case .morning: "Morning"
        case .evening: "Evening"
        case .both: "AM & PM"
        }
    }
}

enum IngredientTag: String, CaseIterable, Codable {
    case retinol, aha, bha, niacinamide, vitaminC, benzoylPeroxide, azelaicAcid, hyaluronicAcid, ceramides, peptides, spf

    var displayName: String {
        switch self {
        case .retinol: "Retinol"
        case .aha: "AHA"
        case .bha: "BHA"
        case .niacinamide: "Niacinamide"
        case .vitaminC: "Vitamin C"
        case .benzoylPeroxide: "Benzoyl Peroxide"
        case .azelaicAcid: "Azelaic Acid"
        case .hyaluronicAcid: "Hyaluronic Acid"
        case .ceramides: "Ceramides"
        case .peptides: "Peptides"
        case .spf: "SPF"
        }
    }

    var isExfoliant: Bool {
        self == .aha || self == .bha
    }

    var isPhotosensitizing: Bool {
        self == .retinol || self == .aha || self == .bha
    }

    var isActiveTreatment: Bool {
        isExfoliant || self == .retinol || self == .vitaminC || self == .benzoylPeroxide || self == .azelaicAcid
    }

    var color: String {
        switch self {
        case .retinol: "#C75B39"
        case .aha, .bha: "#D4A017"
        case .niacinamide: "#5B8C5A"
        case .vitaminC: "#E8A838"
        case .benzoylPeroxide: "#6B8E9F"
        case .azelaicAcid: "#8B7AA8"
        case .hyaluronicAcid, .ceramides, .peptides: "#5A8A9C"
        case .spf: "#E07B39"
        }
    }
}
