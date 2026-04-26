import Foundation

enum PlanPeriod: String, Codable {
    case morning, evening

    var displayName: String {
        switch self {
        case .morning: "This Morning's Plan"
        case .evening: "Tonight's Plan"
        }
    }
}

struct DailyPlan: Codable, Identifiable, Equatable {
    var id = UUID()
    var generatedAt: Date
    var period: PlanPeriod
    var focus: String
    var recommendedSteps: [PlanStep]
    var avoidSteps: [String]
    var reasoning: [String]
    var confidenceLevel: InsightConfidence
}

struct PlanStep: Codable, Identifiable, Equatable {
    var id = UUID()
    var order: Int
    var category: ProductCategory
    var productID: UUID?
    var productName: String?
    var instruction: String?
    var isOptional: Bool
}
