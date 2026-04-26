import Foundation

// MARK: - Scan Consistency

/// Measures how consistent a scan is compared to the user's baseline and recent scans.
/// Poor consistency reduces confidence in downstream change detection.
struct ScanConsistency: Codable, Equatable, Sendable {
    var score: Int // 0-100
    var lighting: ConsistencyDimension
    var angle: ConsistencyDimension
    var distance: ConsistencyDimension
    var blur: ConsistencyDimension
    var timeOfDay: ConsistencyDimension
    var landmarkAlignment: ConsistencyDimension
    var confidenceImpact: ConfidenceImpact

    var isAcceptable: Bool { score >= 60 }
    var isGood: Bool { score >= 80 }

    enum ConsistencyDimension: String, Codable, Sendable {
        case consistent, slightlyDifferent, different, unknown

        var displayName: String {
            switch self {
            case .consistent: return "consistent"
            case .slightlyDifferent: return "slightly different"
            case .different: return "different"
            case .unknown: return "unknown"
            }
        }
    }

    enum ConfidenceImpact: String, Codable, Sendable {
        case none, minor, moderate, significant

        var displayName: String {
            switch self {
            case .none: return "No impact"
            case .minor: return "Minor"
            case .moderate: return "Moderate"
            case .significant: return "Significant"
            }
        }
    }
}

// MARK: - Timeline Markers

/// A marker on the Skin Timeline representing a routine, environmental, or user event.
struct TimelineMarker: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var date: Date
    var type: MarkerType
    var label: String
    var relatedZones: [ZoneType]?
    var icon: String? // SF Symbol name

    enum MarkerType: String, Codable, Sendable {
        case newProduct, productStopped, routineChange, missedRoutine,
             activeIngredient, irritationNoted, breakoutNoted, drynessNoted,
             amRoutine, pmRoutine, environmental, userNote

        var displayName: String {
            switch self {
            case .newProduct: return "New product"
            case .productStopped: return "Product stopped"
            case .routineChange: return "Routine change"
            case .missedRoutine: return "Missed routine"
            case .activeIngredient: return "Active ingredient"
            case .irritationNoted: return "Irritation noted"
            case .breakoutNoted: return "Breakout noted"
            case .drynessNoted: return "Dryness noted"
            case .amRoutine: return "AM routine"
            case .pmRoutine: return "PM routine"
            case .environmental: return "Environment"
            case .userNote: return "Note"
            }
        }

        var systemImage: String {
            switch self {
            case .newProduct: return "plus.circle"
            case .productStopped: return "minus.circle"
            case .routineChange: return "arrow.triangle.2.circlepath"
            case .missedRoutine: return "exclamationmark.circle"
            case .activeIngredient: return "flame"
            case .irritationNoted: return "hand.tap"
            case .breakoutNoted: return "circle.dotted"
            case .drynessNoted: return "drop"
            case .amRoutine: return "sun.max"
            case .pmRoutine: return "moon"
            case .environmental: return "cloud.sun"
            case .userNote: return "note.text"
            }
        }

        var color: String {
            switch self {
            case .newProduct, .activeIngredient: return "accent"
            case .productStopped, .missedRoutine: return "warning"
            case .routineChange, .amRoutine, .pmRoutine: return "success"
            case .irritationNoted, .breakoutNoted: return "warning"
            case .drynessNoted: return "textSecondary"
            case .environmental: return "textSecondary"
            case .userNote: return "textPrimary"
            }
        }
    }
}

// MARK: - Environmental Signal

/// An environmental condition that may correlate with skin changes.
struct EnvironmentalSignal: Codable, Equatable, Sendable {
    var type: SignalType
    var dateRange: DateRange
    var message: String
    var confidence: InsightConfidence

    enum SignalType: String, Codable, Sendable {
        case highUV, lowHumidity, highHumidity, poorAirQuality, heatSpike, coldSpike

        var displayName: String {
            switch self {
            case .highUV: return "High UV"
            case .lowHumidity: return "Low humidity"
            case .highHumidity: return "High humidity"
            case .poorAirQuality: return "Poor air quality"
            case .heatSpike: return "Heat spike"
            case .coldSpike: return "Cold spike"
            }
        }
    }

    struct DateRange: Codable, Equatable, Sendable {
        var start: Date
        var end: Date
    }
}

// MARK: - Pattern Insight

/// A personal skin pattern discovered after enough scan history.
struct PatternInsight: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var title: String
    var body: String
    var patternType: PatternType
    var unlockThreshold: Int // scan count required to unlock
    var isUnlocked: Bool
    var discoveredAt: Date?
    var relatedZones: [ZoneType]

    enum PatternType: String, Codable, Sendable {
        case routineConsistency, zoneReactivity, productLag, seasonal, scanConsistency

        var displayName: String {
            switch self {
            case .routineConsistency: return "Routine pattern"
            case .zoneReactivity: return "Zone behaviour"
            case .productLag: return "Product response"
            case .seasonal: return "Seasonal pattern"
            case .scanConsistency: return "Scan pattern"
            }
        }
    }
}

// MARK: - Nudge

/// A contextual, data-driven prompt shown to the user.
struct Nudge: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var title: String
    var body: String
    var type: NudgeType
    var priority: NudgePriority
    var createdAt: Date
    var expiresAt: Date?
    var actionLabel: String?
    var actionRoute: String? // e.g. "scan", "timeline", "routine"
    var isDismissed: Bool = false

    enum NudgeType: String, Codable, Sendable {
        case followUpScan, routineConsistency, timelineProgress, patternUnlocked,
             experimentCheck, productMonitor, environmentalAlert, generic
    }

    enum NudgePriority: String, Codable, Sendable {
        case low, medium, high

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
    }
}

// MARK: - Data Density

/// Tracks the user's scan count and unlocks progressive timeline features.
struct DataDensity: Codable, Equatable, Sendable {
    var scanCount: Int

    var level: DensityLevel {
        switch scanCount {
        case 0: return .none
        case 1: return .baseline
        case 2...3: return .forming
        case 4...7: return .earlyTrends
        case 8...14: return .patternsEmerging
        default: return .personal
        }
    }

    var nextUnlockDescription: String? {
        switch scanCount {
        case 0: return nil
        case 1: return "2 scans: your timeline starts forming"
        case 2...3: return "\(5 - scanCount) more scans to unlock trend language"
        case 4...7: return "\(8 - scanCount) more scans to unlock routine insights"
        case 8...14: return "\(15 - scanCount) more scans to unlock personal patterns"
        default: return nil
        }
    }

    enum DensityLevel: String, Codable, Sendable {
        case none, baseline, forming, earlyTrends, patternsEmerging, personal

        var displayTitle: String {
            switch self {
            case .none: return ""
            case .baseline: return "Baseline created"
            case .forming: return "Your timeline is starting to form"
            case .earlyTrends: return "Early trends are becoming visible"
            case .patternsEmerging: return "Routine patterns are getting clearer"
            case .personal: return "Clera can now detect more personal skin patterns"
            }
        }

        var displayBody: String {
            switch self {
            case .none: return ""
            case .baseline: return "Keep scanning to build your personal skin story."
            case .forming: return "Regular scans help Clera understand your skin's patterns."
            case .earlyTrends: return "You're starting to see how your skin changes over time."
            case .patternsEmerging: return "Your routine and skin changes are becoming clearer."
            case .personal: return "Clera now understands your skin's personal patterns."
            }
        }
    }
}

// MARK: - What Changed

/// The result of the "What Changed?" engine — primary and secondary insights from a scan.
struct WhatChangedResult: Codable, Equatable, Sendable {
    var generatedAt: Date
    var primaryChange: WhatChangedItem?
    var secondaryChange: WhatChangedItem?
    var stableZones: [ZoneType]
    var improvedZones: [ZoneType]
    var worsenedZones: [ZoneType]
    var overallMessage: String

    var hasChanges: Bool {
        primaryChange != nil || secondaryChange != nil
    }
}

struct WhatChangedItem: Codable, Equatable, Sendable {
    var zone: ZoneType
    var metric: String
    var trend: ChangeDirection
    var severity: ChangeMagnitude
    var confidence: InsightConfidence
    var message: String
    var percentChange: Int
}

// MARK: - Visual Difference

/// Describes which zones should be highlighted in a visual difference view.
struct VisualDifference: Codable, Equatable, Sendable {
    var highlightedZones: [ZoneHighlightDiff]
    var shouldAnimate: Bool

    struct ZoneHighlightDiff: Codable, Equatable, Sendable {
        var zone: ZoneType
        var direction: ChangeDirection
        var intensity: Double // 0.0 ... 1.0
        var metric: String
    }
}

// MARK: - Routine Impact

/// A cautious attribution link between a routine event and a skin change.
struct RoutineImpact: Codable, Equatable, Sendable {
    var routineEvent: String
    var skinChange: String
    var timeGapDays: Int
    var confidence: InsightConfidence
    var message: String
    var isCautionary: Bool // always true — never claim causation
}

// MARK: - Timeline Session Enrichment

/// Extra timeline data attached to each SkinSessionResult.
struct TimelineEnrichment: Codable, Equatable, Sendable {
    var scanConsistency: ScanConsistency?
    var whatChanged: WhatChangedResult?
    var markers: [TimelineMarker]
    var environmentalSignals: [EnvironmentalSignal]
    var routineImpacts: [RoutineImpact]
    var visualDifference: VisualDifference?
    var patterns: [PatternInsight]
    var dataDensity: DataDensity
}
