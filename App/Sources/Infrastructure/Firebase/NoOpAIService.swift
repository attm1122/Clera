import Foundation

// MARK: - No-Op AI Service

/// Fallback AI service used when Firebase Vertex AI is not available.
/// Returns errors for all AI operations so the UI can degrade gracefully.
final class NoOpAIService: AIProviding, Sendable {
    func generateInsight(context: AIInsightContext) async throws -> AIInsightResponse {
        throw AIError.serviceUnavailable
    }

    func answerQuestion(question: String, context: AIInsightContext) async throws -> String {
        throw AIError.serviceUnavailable
    }
}
