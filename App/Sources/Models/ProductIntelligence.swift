import Foundation

struct ProductIntelligenceReport: Codable, Identifiable, Equatable {
    var id = UUID()
    var generatedAt: Date
    var risks: [ProductRisk]
    var explanations: [String]
    var suggestedActions: [String]
    var confidenceLevel: InsightConfidence
}

struct ProductRisk: Codable, Identifiable, Equatable {
    var id = UUID()
    var severity: RiskSeverity
    var title: String
    var description: String
    var affectedProductIDs: [UUID]
    var relatedZones: [ZoneType]?
}

enum RiskSeverity: String, Codable {
    case caution, warning, info

    var displayName: String {
        switch self {
        case .caution: CleraCopy.DisplayNames.riskSeverityCaution
        case .warning: CleraCopy.DisplayNames.riskSeverityWarning
        case .info: CleraCopy.DisplayNames.riskSeverityInfo
        }
    }

    var color: String {
        switch self {
        case .caution: "#D4A017"
        case .warning: "#C75B39"
        case .info: "#5A8A9C"
        }
    }
}
