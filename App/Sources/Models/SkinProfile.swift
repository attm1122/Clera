import Foundation

struct SkinProfile: Codable, Equatable {
    var skinType: SkinType = .combination
    var sensitivity: Sensitivity = .mild
    var primaryConcerns: [SkinConcern] = []
    var primaryGoal: SkinGoal = .evenTone
    var ageRange: AgeRange = .range25to34
    var stressLevel: StressLevel = .moderate
}

enum SkinType: String, CaseIterable, Codable {
    case dry, oily, combination, normal, unknown
}

enum Sensitivity: String, CaseIterable, Codable {
    case none, mild, moderate, reactive
}

enum SkinConcern: String, CaseIterable, Codable {
    case breakouts, blackheads, redness, texture, dullness, hyperpigmentation, darkCircles, largePores

    var displayName: String {
        switch self {
        case .breakouts: "Breakouts"
        case .blackheads: "Blackheads"
        case .redness: "Redness"
        case .texture: "Texture"
        case .dullness: "Dullness"
        case .hyperpigmentation: "Dark Spots"
        case .darkCircles: "Dark Circles"
        case .largePores: "Large Pores"
        }
    }
}

enum SkinGoal: String, CaseIterable, Codable {
    case clearerSkin, evenTone, smootherTexture, fewerBreakouts, youthfulRadiance, minimizePores

    var displayName: String {
        switch self {
        case .clearerSkin: "Clearer Skin"
        case .evenTone: "Even Tone"
        case .smootherTexture: "Smoother Texture"
        case .fewerBreakouts: "Fewer Breakouts"
        case .youthfulRadiance: "Youthful Radiance"
        case .minimizePores: "Minimize Pores"
        }
    }
}

enum AgeRange: String, CaseIterable, Codable {
    case under18, range18to24, range25to34, range35to44, range45to54, over54

    var displayName: String {
        switch self {
        case .under18: "Under 18"
        case .range18to24: "18-24"
        case .range25to34: "25-34"
        case .range35to44: "35-44"
        case .range45to54: "45-54"
        case .over54: "55+"
        }
    }
}

enum StressLevel: String, CaseIterable, Codable {
    case low, moderate, high
}
