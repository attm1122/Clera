import Foundation

// MARK: - Engine Confidence

struct EngineConfidence: Codable, Equatable, Sendable {
    var level: EngineConfidenceLevel
    var reasons: [String]
}

enum EngineConfidenceLevel: String, Codable, CaseIterable, Sendable {
    case low, medium, high
}

// MARK: - Skin Context

struct SkinContext: Codable, Equatable, Sendable {
    var latestScan: ScanSession?
    var baselineScan: ScanSession?
    var previousScan: ScanSession?
    var scansLastSevenDays: [ScanSession]
    var skinProfile: SkinProfile
    var latestSkinMap: SkinMap?
    var baselineSkinMap: SkinMap?
    var routineLogs: [RoutineLogEntry]
    var routineChanges: [RoutineChangeLogEntry]
    var products: [Product]
    var weatherSnapshot: DailyWeatherSnapshot?
    var airQualitySnapshot: AirQualitySnapshot?
    var latestCheckIn: SkinMapCheckIn?
    var checkInHistory: [SkinMapCheckIn]
    var hasCompletedOnboarding: Bool
    var isFirstTimeUser: Bool
}

// MARK: - Zone Skin Score

struct ZoneSkinScore: Codable, Equatable, Sendable {
    var zone: ZoneType
    var breakout: Int
    var redness: Int
    var texture: Int
    var oiliness: Int
    var dryness: Int
    var pigmentation: Int
    var congestion: Int
    var sensitivity: Int
    var confidence: EngineConfidence
}

// MARK: - Skin Trend

struct EngineSkinTrend: Codable, Equatable, Sendable {
    var metric: SkinMetricKey
    var direction: TrendDirection
    var delta: Int
    var severity: TrendSeverity
    var confidence: EngineConfidence
    var comparedTo: TrendComparison
}

enum TrendDirection: String, Codable, CaseIterable, Sendable {
    case improving, stable, worsening, unknown
}

enum TrendSeverity: String, Codable, CaseIterable, Sendable {
    case mild, moderate, significant
}

enum TrendComparison: String, Codable, CaseIterable, Sendable {
    case baseline, previousScan, sevenDayAverage
}

// MARK: - Skin Recommendation

struct SkinRecommendation: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var title: String
    var body: String
    var action: String?
    var category: RecommendationCategory
    var priority: RecommendationPriority
    var confidence: EngineConfidenceLevel
    var zones: [ZoneType]
    var durationDays: Int?
    var createdAt: Date
}

enum RecommendationCategory: String, Codable, CaseIterable, Sendable {
    case environment, routine, product, progress, safety
}

enum RecommendationPriority: String, Codable, CaseIterable, Sendable {
    case low, medium, high
}

// MARK: - Safety Assessment

struct SafetyAssessment: Codable, Equatable, Sendable {
    var level: SafetyLevel
    var reasons: [String]
    var message: String
}

enum SafetyLevel: String, Codable, CaseIterable, Sendable {
    case normal, caution, recommendProfessionalReview, urgentReview
}

// MARK: - Zone Summary

struct ZoneSummary: Codable, Equatable, Sendable {
    var zone: ZoneType
    var scores: ZoneSkinScore
    var trends: [EngineSkinTrend]
    var topConcern: SkinMetricKey?
    var explanation: String
}

// MARK: - Progress Highlight

struct ProgressHighlight: Codable, Equatable, Sendable {
    var kind: ProgressHighlightKind
    var zone: ZoneType?
    var metric: SkinMetricKey?
    var message: String
}

enum ProgressHighlightKind: String, Codable, CaseIterable, Sendable {
    case mostImproved, needsAttention, stable, newBaseline, milestone
}

// MARK: - Skin Engine Report

struct SkinEngineReport: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var generatedAt: Date
    var summary: String
    var skinState: SkinStateSummary
    var zoneSummaries: [ZoneSummary]
    var recommendations: [SkinRecommendation]
    var environmentRisks: [SkinRecommendation]
    var routineWarnings: [SkinRecommendation]
    var productWarnings: [SkinRecommendation]
    var progressHighlights: [ProgressHighlight]
    var safetyAssessment: SafetyAssessment
    var confidence: EngineConfidence
}

struct SkinStateSummary: Codable, Equatable, Sendable {
    var overallScore: Int
    var highestRiskZone: ZoneType?
    var mostImprovedZone: ZoneType?
    var primaryConcern: SkinMetricKey?
    var overallTrend: TrendDirection
}

// MARK: - Skin Insight

struct EngineSkinInsight: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var title: String
    var body: String
    var confidence: EngineConfidenceLevel
    var zone: ZoneType?
    var metric: SkinMetricKey?
}

// MARK: - Persisted Engine State

struct SkinEngineState: Codable, Equatable, Sendable {
    var latestReport: SkinEngineReport?
    var recommendationHistory: [SkinRecommendation]
    var dismissedRecommendationIDs: [UUID]
    var safetyHistory: [SafetyAssessment]
    var zoneTrendHistory: [ZoneType: [EngineSkinTrend]]
}
