import Foundation
import SwiftUI

struct SkinMap: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let scanId: UUID?
    var zones: [FaceZone]
    var checkIn: SkinMapCheckIn?
    var scanQuality: ScanQualityMetadata?
    var confidenceLevel: Double

    init(id: UUID = UUID(), date: Date = .now, scanId: UUID? = nil, zones: [FaceZone], checkIn: SkinMapCheckIn? = nil, scanQuality: ScanQualityMetadata? = nil, confidenceLevel: Double = 1.0) {
        self.id = id
        self.date = date
        self.scanId = scanId
        self.zones = zones
        self.checkIn = checkIn
        self.scanQuality = scanQuality
        self.confidenceLevel = confidenceLevel
    }
}

struct SkinMapCheckIn: Codable, Equatable {
    var followedRoutine: Bool = false
    var newProducts: Bool = false
    var hadIrritation: Bool = false
    var hadDryness: Bool = false
    var hadBreakouts: Bool = false
    var notes: String?
}

struct ScanQualityMetadata: Codable, Equatable {
    var blurScore: Double = 0
    var brightnessScore: Double = 0
    var sharpnessScore: Double = 0
    var overexposed: Bool = false
    var shadowDetected: Bool = false
    var scanReadiness: String = "unknown"
}

struct FaceZone: Codable, Identifiable, Equatable {
    var id = UUID()
    var zoneType: ZoneType
    var status: ZoneStatus
    var notes: String?
}

enum ZoneType: String, CaseIterable, Codable {
    case forehead, nose, leftCheek, rightCheek, chinJaw

    var displayName: String {
        switch self {
        case .forehead: "Forehead"
        case .nose: "Nose"
        case .leftCheek: "Left Cheek"
        case .rightCheek: "Right Cheek"
        case .chinJaw: "Chin & Jaw"
        }
    }

    var systemImage: String {
        switch self {
        case .forehead: "eyes.inverse"
        case .nose: "nose"
        case .leftCheek: "face.dashed"
        case .rightCheek: "face.dashed.fill"
        case .chinJaw: "mouth"
        }
    }
}

struct ZoneStatus: Codable, Equatable {
    var breakouts: ZoneSeverity = .none
    var redness: ZoneSeverity = .none
    var dryness: ZoneSeverity = .none
    var texture: ZoneSeverity = .none
    var congestion: ZoneSeverity = .none
    var irritation: ZoneSeverity = .none

    var breakoutsTrend: ZoneTrend = .unknown
    var rednessTrend: ZoneTrend = .unknown
    var drynessTrend: ZoneTrend = .unknown
    var textureTrend: ZoneTrend = .unknown
    var congestionTrend: ZoneTrend = .unknown
    var irritationTrend: ZoneTrend = .unknown

    var overallConfidence: Double = 1.0

    var overallSeverity: ZoneSeverity {
        let severities = [breakouts, redness, dryness, texture, congestion, irritation]
        if severities.contains(.high) { return .high }
        if severities.contains(.moderate) { return .moderate }
        if severities.contains(.low) { return .low }
        return .none
    }

    var overallTrend: ZoneTrend {
        let trends = [breakoutsTrend, rednessTrend, drynessTrend, textureTrend, congestionTrend, irritationTrend]
        let improvingCount = trends.filter { $0 == .improving }.count
        let worseningCount = trends.filter { $0 == .worsening }.count
        if worseningCount > improvingCount { return .worsening }
        if improvingCount > worseningCount { return .improving }
        if trends.allSatisfy({ $0 == .unknown }) { return .unknown }
        return .stable
    }

    var metrics: [(label: String, severity: ZoneSeverity, trend: ZoneTrend)] {
        [
            ("Breakouts", breakouts, breakoutsTrend),
            ("Redness", redness, rednessTrend),
            ("Dryness", dryness, drynessTrend),
            ("Texture", texture, textureTrend),
            ("Congestion", congestion, congestionTrend),
            ("Irritation", irritation, irritationTrend)
        ]
    }
}

enum ZoneSeverity: String, CaseIterable, Codable {
    case none, low, moderate, high

    var numericScore: Int {
        switch self {
        case .none: 0
        case .low: 1
        case .moderate: 2
        case .high: 3
        }
    }

    var displayName: String {
        switch self {
        case .none: CleraCopy.DisplayNames.zoneSeverityClear
        case .low: CleraCopy.DisplayNames.zoneSeverityLow
        case .moderate: CleraCopy.DisplayNames.zoneSeverityModerate
        case .high: CleraCopy.DisplayNames.zoneSeverityHigh
        }
    }

    var color: Color {
        switch self {
        case .none: .green
        case .low: .yellow
        case .moderate: .orange
        case .high: .red
        }
    }

    var icon: String {
        switch self {
        case .none: "checkmark.circle.fill"
        case .low: "exclamationmark.circle.fill"
        case .moderate: "exclamationmark.triangle.fill"
        case .high: "xmark.circle.fill"
        }
    }
}

enum ZoneTrend: String, CaseIterable, Codable {
    case improving, stable, worsening, unknown

    var displayName: String {
        switch self {
        case .improving: CleraCopy.DisplayNames.zoneTrendImproving
        case .stable: CleraCopy.DisplayNames.zoneTrendStable
        case .worsening: CleraCopy.DisplayNames.zoneTrendWorsening
        case .unknown: CleraCopy.DisplayNames.zoneTrendUnknown
        }
    }

    var color: Color {
        switch self {
        case .improving: .green
        case .stable: CleraColor.accent
        case .worsening: .orange
        case .unknown: CleraColor.textSecondary
        }
    }

    var icon: String {
        switch self {
        case .improving: "arrow.down.forward"
        case .stable: "equal"
        case .worsening: "arrow.up.forward"
        case .unknown: "minus"
        }
    }
}
