import Foundation

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
