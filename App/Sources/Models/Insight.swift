import Foundation

struct Insight: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var body: String
    var type: InsightType
    var zone: ZoneType?
    var priority: InsightPriority
    var isDismissed: Bool = false
}

enum InsightType: String, Codable {
    case improvement, regression, correlation, productEffect, habit, environment

    var displayName: String {
        switch self {
        case .improvement: "Improvement"
        case .regression: "Change"
        case .correlation: "Link"
        case .productEffect: "Product"
        case .habit: "Habit"
        case .environment: "Environment"
        }
    }
}

enum InsightPriority: String, Codable {
    case high, medium, low
}

struct WeeklyReport: Codable, Identifiable, Equatable {
    var id = UUID()
    var weekEnding: Date
    var summary: String
    var topImprovement: String
    var watchArea: String
    var photoComparisons: [UUID]
}

struct WeeklyInsight: Codable, Identifiable, Equatable {
    var id = UUID()
    var generatedAt: Date
    var weekEnding: Date
    var summaryTitle: String
    var summaryText: String
    var zoneHighlights: [ZoneHighlight]
    var possibleContributors: [Contributor]
    var recommendedNextStep: String
    var confidenceLevel: InsightConfidence
    var safetyDisclaimer: String
}

struct ZoneHighlight: Codable, Identifiable, Equatable {
    var id = UUID()
    var zone: ZoneType
    var trend: ZoneTrend
    var primaryMetric: String
    var description: String
}

struct Contributor: Codable, Identifiable, Equatable {
    var id = UUID()
    var type: ContributorType
    var description: String
    var confidence: InsightConfidence
}

enum ContributorType: String, Codable {
    case routine, product, environment, habit, scanQuality, unknown

    var displayName: String {
        switch self {
        case .routine: "Routine"
        case .product: "Product"
        case .environment: "Environment"
        case .habit: "Habit"
        case .scanQuality: "Scan Quality"
        case .unknown: "Unknown"
        }
    }
}

enum InsightConfidence: String, Codable {
    case high, moderate, low

    var displayName: String {
        switch self {
        case .high: CleraCopy.DisplayNames.insightConfidenceHigh
        case .moderate: CleraCopy.DisplayNames.insightConfidenceModerate
        case .low: CleraCopy.DisplayNames.insightConfidenceLow
        }
    }
}
