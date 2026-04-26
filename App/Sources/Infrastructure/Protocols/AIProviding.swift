import Foundation

// MARK: - AIProviding Protocol

/// Abstract generative AI service for personalized skincare insights.
/// The app depends on this protocol, not on Firebase Vertex AI directly.
protocol AIProviding: Sendable {
    /// Generates a personalized skincare insight based on the user's current skin data.
    /// Returns nil if the AI service is unavailable or the prompt cannot be processed.
    func generateInsight(
        context: AIInsightContext
    ) async throws -> AIInsightResponse

    /// Answers a user skincare question with context from their profile and recent scans.
    func answerQuestion(
        question: String,
        context: AIInsightContext
    ) async throws -> String
}

// MARK: - AI Context Models

/// Context passed to the AI for generating personalized responses.
struct AIInsightContext: Sendable {
    let skinProfile: SkinProfile
    let latestSkinMap: SkinMap?
    let recentSessions: [ScanSession]
    let currentProducts: [Product]
    let routineLogs: [RoutineLogEntry]
    let weeklyInsight: WeeklyInsight?
    let environmentalContext: EnvironmentalContext?
    let userName: String?

    static let empty = AIInsightContext(
        skinProfile: SkinProfile(),
        latestSkinMap: nil,
        recentSessions: [],
        currentProducts: [],
        routineLogs: [],
        weeklyInsight: nil,
        environmentalContext: nil,
        userName: nil
    )
}

struct AIInsightResponse: Sendable {
    let title: String
    let body: String
    let category: AIInsightCategory
    let confidence: AIConfidenceLevel
    let suggestedActions: [AISuggestedAction]
}

enum AIInsightCategory: String, Sendable {
    case hydration
    case texture
    case pigmentation
    case redness
    case routine
    case product
    case environment
    case general
}

enum AIConfidenceLevel: String, Sendable {
    case high
    case medium
    case low
}

struct AISuggestedAction: Sendable {
    let title: String
    let actionType: AIActionType
}

enum AIActionType: Sendable {
    case adjustRoutine
    case tryProduct
    case bookConsultation
    case scanAgain
    case readMore
}

enum AIError: Error, Equatable {
    case serviceUnavailable
    case emptyResponse
    case generationFailed(String)
    case parsingFailed
    case safetyBlocked(reason: String)
    case responseIncomplete(reason: String)
}

struct EnvironmentalContext: Sendable {
    let uvIndex: Int
    let humidity: Int
    let temperature: Double
    let airQualityIndex: Int?
    let weatherCondition: String
}
