import Foundation
import SwiftUI

// MARK: - User

struct UserProfile: Codable, Equatable {
    var name: String
    var email: String
}

struct PermissionState: Codable, Equatable {
    var cameraGranted: Bool = false
    var photoLibraryGranted: Bool = false
    var notificationsGranted: Bool = false
}

// MARK: - Skin Profile

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

// MARK: - Skin Map & Zones

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
    // Visible signs — app-derived or user-reported
    var breakouts: ZoneSeverity = .none
    var redness: ZoneSeverity = .none
    var dryness: ZoneSeverity = .none
    var texture: ZoneSeverity = .none
    var congestion: ZoneSeverity = .none
    var irritation: ZoneSeverity = .none
    
    // Trends over time
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

// MARK: - Products

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

// MARK: - Ingredients

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

// MARK: - Routine

struct Routine: Codable, Equatable {
    var morningSteps: [RoutineStep] = []
    var eveningSteps: [RoutineStep] = []
}

struct RoutineStep: Codable, Identifiable, Equatable {
    var id = UUID()
    var productID: UUID
    var order: Int
}

// MARK: - Routine

struct RoutineLogEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var followedRoutine: Bool
    var productIDs: [UUID]
    var notes: String?
    var photo: ScanPhoto?
}

struct RoutineChangeLogEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date = .now
    let productId: UUID
    let changeType: ChangeType
    var notes: String?
}

enum ChangeType: String, Codable {
    case added, removed, switched
}

// MARK: - Scans

struct ScanSession: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: ScanType
    var createdAt: Date = .now
    var photos: [ScanPhoto]
    var skinMap: SkinMap
    var note: String?
}

enum ScanType: String, Codable {
    case baseline, daily, weekly, checkIn, experimentStart, experimentEnd
}

struct ScanPhoto: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var zone: ZoneType?
    var date: Date = .now
    var imageData: Data?
    var fileName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, zone, date, fileName
    }
    
    init(zone: ZoneType?, imageData: Data? = nil, fileName: String? = nil) {
        self.zone = zone
        self.imageData = imageData
        self.fileName = fileName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.zone = try container.decodeIfPresent(ZoneType.self, forKey: .zone)
        self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? .now
        self.fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        // imageData is intentionally not persisted — loaded from disk via fileName
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(zone, forKey: .zone)
        try container.encode(date, forKey: .date)
        try container.encode(fileName, forKey: .fileName)
        // imageData is intentionally not encoded to prevent JSON bloat
    }
    
    /// Loads the UIImage from disk if fileName is set, otherwise falls back to in-memory imageData.
    func resolvedImage() -> UIImage? {
        if let fileName = fileName {
            return ImageStore.load(fileName: fileName)
        }
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        return nil
    }
}

// MARK: - Experiments

struct Experiment: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var zone: ZoneType
    var hypothesis: String
    var durationDays: Int
    var isActive: Bool
    var startDate: Date = .now
    var endDate: Date?
    var relatedProductIDs: [UUID]
    var result: ExperimentResult?
    var dailyCheckIns: [DailyCheckIn]
}

struct ExperimentResult: Codable, Equatable, Hashable {
    var outcome: ExperimentOutcome
    var notes: String?
    var finalSkinMapID: UUID?
}

enum ExperimentOutcome: String, Codable, Hashable {
    case improvement, noChange, worsened
}

struct DailyCheckIn: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var date: Date
    var skinCondition: String
    var notes: String?
    var photo: ScanPhoto?
}

// MARK: - Insights

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

// MARK: - Weekly Insight

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

// MARK: - Product Intelligence

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

// MARK: - Change Detection

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

// MARK: - Skin Session

struct SkinSession: Codable, Identifiable, Equatable {
    var id = UUID()
    var createdAt: Date
    var scan: ScanSession
    var checkIn: SkinMapCheckIn?
    var skinMap: SkinMap
    var changes: ChangeDetectionResult
    var productIntelligence: ProductIntelligenceReport
    var dailyPlan: DailyPlan
    var weeklyInsight: WeeklyInsight?
    var confidence: SessionConfidence
    var qualityValidation: ScanQualityValidation
    var failures: [SessionFailure]
}

struct SessionConfidence: Codable, Equatable {
    var scanQuality: Double
    var skinMap: Double
    var changeDetection: Double
    var productIntelligence: Double
    var dailyPlan: Double
    var overall: Double
}

struct ScanQualityValidation: Codable, Equatable {
    var isValid: Bool
    var issues: [String]
    var score: Double
}

// MARK: - Pipeline Result

enum ScanStatus: String, Codable {
    case accepted, savedLowConfidence, rejected
    
    var displayName: String {
        switch self {
        case .accepted: CleraCopy.DisplayNames.scanStatusAccepted
        case .savedLowConfidence: CleraCopy.DisplayNames.scanStatusSavedLow
        case .rejected: CleraCopy.DisplayNames.scanStatusRejected
        }
    }
}

/// The canonical output of the Skin Session pipeline.
/// The UI consumes only this object — never individual engines.
struct SkinSessionResult: Codable, Identifiable, Equatable {
    var id = UUID()
    var sessionId: UUID
    var createdAt: Date
    var scanStatus: ScanStatus
    var isBaseline: Bool
    var failureState: FailureState?
    var skinMap: SkinMap
    var zoneChanges: [ZoneChange]
    var dailyPlan: DailyPlan
    var confidenceSummary: ConfidenceSummary
    var userMessages: [String]
    var analyticsEvents: [AnalyticsEvent]
    var checkIn: SkinMapCheckIn?
    var weeklyInsight: WeeklyInsight?
    var timelineEnrichment: TimelineEnrichment?
}

struct FailureState: Codable, Equatable {
    var code: FailureCode
    var userMessage: String
    var recommendedAction: String
    var canContinue: Bool
    var confidenceImpact: Double
}

struct ConfidenceSummary: Codable, Equatable {
    var overall: Double
    var scanQuality: Double
    var skinMap: Double
    var changeDetection: Double
    var productIntelligence: Double
    var dailyPlan: Double
    var adjustedForFailures: Bool
}

struct PipelineContext: Codable, Equatable {
    var scanSession: ScanSession
    var checkIn: SkinMapCheckIn?
    var currentProducts: [Product]
    var routineLogs: [RoutineLogEntry]
    var routineChanges: [RoutineChangeLogEntry]
    var allSessions: [ScanSession]
    var skinMapHistory: [SkinMap]
    var experiments: [Experiment]
    var scanFailures: [SessionFailure]
}

struct PipelineStepResult: Codable, Equatable {
    var stepName: String
    var succeeded: Bool
    var skipped: Bool
    var reason: String?
}

enum AnalyticsEvent: String, Codable {
    case scanStarted = "scan_started"
    case scanRejected = "scan_rejected"
    case scanSavedLowConfidence = "scan_saved_low_confidence"
    case baselineCreated = "baseline_created"
    case skinSessionCompleted = "skin_session_completed"
    case dailyPlanGenerated = "daily_plan_generated"
    case fallbackPlanGenerated = "fallback_plan_generated"
    case pipelineError = "pipeline_error"
}

// MARK: - Failure States

enum FailureCode: String, Codable {
    case noFaceDetected
    case multipleFaces
    case faceNotCentred
    case poorLighting
    case harshGlare
    case blurryImage
    case faceTooClose
    case faceTooFar
    case extremeHeadAngle
    case scanConfidenceLow
    case missingCheckIn
    case noRoutine
    case noPreviousSession
    case inconsistentHistory
    case noBaseline
    case uncertainCopilot
    
    var displayName: String {
        switch self {
        case .noFaceDetected: CleraCopy.DisplayNames.failureNoFace
        case .multipleFaces: CleraCopy.DisplayNames.failureMultipleFaces
        case .faceNotCentred: CleraCopy.DisplayNames.failureOffCentre
        case .poorLighting: CleraCopy.DisplayNames.failurePoorLighting
        case .harshGlare: CleraCopy.DisplayNames.failureGlare
        case .blurryImage: CleraCopy.DisplayNames.failureBlurry
        case .faceTooClose: CleraCopy.DisplayNames.failureTooClose
        case .faceTooFar: CleraCopy.DisplayNames.failureTooFar
        case .extremeHeadAngle: CleraCopy.DisplayNames.failureExtremeAngle
        case .scanConfidenceLow: CleraCopy.DisplayNames.failureLowConfidence
        case .missingCheckIn: CleraCopy.DisplayNames.failureMissingCheckIn
        case .noRoutine: CleraCopy.DisplayNames.failureNoRoutine
        case .noPreviousSession: CleraCopy.DisplayNames.failureFirstScan
        case .inconsistentHistory: CleraCopy.DisplayNames.failureInconsistentHistory
        case .noBaseline: CleraCopy.DisplayNames.failureNoBaseline
        case .uncertainCopilot: CleraCopy.DisplayNames.failureUncertainPlan
        }
    }
}

struct SessionFailure: Codable, Identifiable, Equatable {
    var id = UUID()
    var failureCode: FailureCode
    var userMessage: String
    var recommendedAction: String
    var canContinue: Bool
    var confidenceImpact: Double
    var isResolved: Bool = false
}

// MARK: - Settings

struct ReminderSettings: Codable, Equatable {
    var enabled: Bool = false
    var preferredTime: Date = Date(timeIntervalSinceReferenceDate: 31_200)
    var cadence: ReminderCadence = .daily
}

enum ReminderCadence: String, CaseIterable, Codable {
    case daily, alternateDays, weekly
    
    var displayName: String {
        switch self {
        case .daily: "Every Day"
        case .alternateDays: "Every Other Day"
        case .weekly: "Weekly"
        }
    }
}

struct PrivacySettings: Codable, Equatable {
    var shareAnalytics: Bool = false
    var savePhotos: Bool = true
    var consentState: PrivacyConsentState = PrivacyConsentState()
}

// MARK: - Capture

enum CaptureAngle: String, CaseIterable, Identifiable, Codable {
    case front, left, right
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var guidance: String {
        switch self {
        case .front: "Face the camera directly, relax your expression."
        case .left: "Turn your head slightly to show your left profile."
        case .right: "Turn your head slightly to show your right profile."
        }
    }
}

// MARK: - Daily Copilot

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

// MARK: - Sample Data

enum SampleData {
    static let defaultProducts: [Product] = [
        Product(name: "Gentle Cleanser", category: .cleanser, period: .both, ingredientTags: []),
        Product(name: "Vitamin C Serum", category: .serum, period: .morning, ingredientTags: [.vitaminC]),
        Product(name: "Niacinamide Serum", category: .serum, period: .evening, ingredientTags: [.niacinamide]),
        Product(name: "Moisturizer", category: .moisturizer, period: .both, ingredientTags: [.hyaluronicAcid, .ceramides]),
        Product(name: "Sunscreen SPF 50", category: .sunscreen, period: .morning, ingredientTags: [.spf])
    ]
    
    static var sampleSkinMap: SkinMap {
        SkinMap(zones: [
            FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: .low, redness: .none, texture: .low)),
            FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: .low, redness: .low, texture: .moderate)),
            FaceZone(zoneType: .leftCheek, status: ZoneStatus(breakouts: .none, redness: .none, texture: .low)),
            FaceZone(zoneType: .rightCheek, status: ZoneStatus(breakouts: .low, redness: .none, texture: .low)),
            FaceZone(zoneType: .chinJaw, status: ZoneStatus(breakouts: .moderate, redness: .low, texture: .moderate))
        ])
    }
    
    static let sampleInsights: [Insight] = [
        Insight(title: "Redness improving", body: "Nose redness down 40% since last week. Keep using niacinamide.", type: .improvement, zone: .nose, priority: .high),
        Insight(title: "Breakout pattern detected", body: "Jaw breakouts correlate with late nights. Sleep earlier this week.", type: .habit, zone: .chinJaw, priority: .medium),
        Insight(title: "Texture looking smoother", body: "Left cheek texture improved significantly after adding vitamin C.", type: .productEffect, zone: .leftCheek, priority: .medium)
    ]
    
    static var sampleWeeklyReport: WeeklyReport {
        WeeklyReport(weekEnding: .now, summary: "Great week! Overall skin condition improved by 25%.", topImprovement: "Nose texture smoother after consistent niacinamide use.", watchArea: "Chin & jaw still breaking out — review evening routine.", photoComparisons: [])
    }
    
    static let sampleExperiments: [Experiment] = [
        Experiment(name: "Niacinamide Test", zone: .nose, hypothesis: "Niacinamide will reduce nose redness over 2 weeks.", durationDays: 14, isActive: true, relatedProductIDs: [defaultProducts[2].id], dailyCheckIns: [])
    ]
}
