import Foundation

enum ChangeDirection: String, Codable {
    case increasing, decreasing, stable

    var displayName: String {
        switch self {
        case .increasing: "Increasing"
        case .decreasing: "Decreasing"
        case .stable: "Stable"
        }
    }

    var zoneTrend: ZoneTrend {
        switch self {
        case .increasing: .worsening
        case .decreasing: .improving
        case .stable: .stable
        }
    }
}

enum ChangeMagnitude: String, Codable {
    case slight, moderate, significant

    var numericScore: Int {
        switch self {
        case .slight: 1
        case .moderate: 2
        case .significant: 3
        }
    }

    var displayName: String {
        switch self {
        case .slight: "Slight"
        case .moderate: "Moderate"
        case .significant: "Significant"
        }
    }
}

struct ZoneChange: Codable, Identifiable, Equatable {
    var id = UUID()
    var zone: ZoneType
    var metric: String
    var direction: ChangeDirection
    var magnitude: ChangeMagnitude
    var confidence: Double
    var explanation: String
    var comparedMapIDs: [UUID]
}

struct ChangeDetectionResult: Codable, Equatable {
    var generatedAt: Date
    var mode: DetectionMode
    var zoneChanges: [ZoneChange]
}

enum DetectionMode: String, Codable {
    case latestPair, rolling3Scan, sevenDay

    var displayName: String {
        switch self {
        case .latestPair: "Current vs Previous"
        case .rolling3Scan: "3-Scan Trend"
        case .sevenDay: "7-Day Trend"
        }
    }
}
