import Foundation

#if canImport(FirebaseVertexAI)
import FirebaseVertexAI
#endif

// MARK: - Vertex AI Service

/// Production implementation of `AIProviding` using Firebase Vertex AI (Gemini models).
/// Falls back gracefully when Firebase is not configured.
@available(iOS 15.0, *)
final class VertexAIService: AIProviding, @unchecked Sendable {

    private let model: GenerativeModel?
    private let crashReporter: CrashReporting

    init(crashReporter: CrashReporting) {
        self.crashReporter = crashReporter

        #if canImport(FirebaseVertexAI)
        guard FirebaseConfiguration.isConfigured else {
            self.model = nil
            return
        }
        let vertexAI = VertexAI.vertexAI()
        self.model = vertexAI.generativeModel(
            modelName: "gemini-2.0-flash",
            generationConfig: GenerationConfig(
                temperature: 0.4,
                topP: 0.95,
                topK: 40,
                maxOutputTokens: 1024
            ),
            systemInstruction: ModelContent(
                role: "system",
                parts: Self.systemInstructionText
            )
        )
        #else
        self.model = nil
        #endif
    }

    // MARK: - AIProviding

    func generateInsight(context: AIInsightContext) async throws -> AIInsightResponse {
        guard let model = model else {
            throw AIError.serviceUnavailable
        }

        let prompt = buildInsightPrompt(context: context)

        do {
            #if canImport(FirebaseVertexAI)
            let response = try await model.generateContent(prompt)
            guard let text = response.text else {
                throw AIError.emptyResponse
            }
            return try parseInsightResponse(text)
            #else
            throw AIError.serviceUnavailable
            #endif
        } catch {
            crashReporter.recordError(error, context: ["ai_feature": "generateInsight"])
            throw AIError.generationFailed(error.localizedDescription)
        }
    }

    func answerQuestion(question: String, context: AIInsightContext) async throws -> String {
        guard let model = model else {
            throw AIError.serviceUnavailable
        }

        let prompt = buildQAPrompt(question: question, context: context)

        do {
            #if canImport(FirebaseVertexAI)
            let response = try await model.generateContent(prompt)
            guard let text = response.text else {
                throw AIError.emptyResponse
            }
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
            #else
            throw AIError.serviceUnavailable
            #endif
        } catch {
            crashReporter.recordError(error, context: ["ai_feature": "answerQuestion"])
            throw AIError.generationFailed(error.localizedDescription)
        }
    }

    // MARK: - Prompt Engineering

    private func buildInsightPrompt(context: AIInsightContext) -> String {
        var parts: [String] = []

        if let name = context.userName {
            parts.append("User: \(name)")
        }

        parts.append("Skin Type: \(context.skinProfile.skinType.rawValue)")
        parts.append("Sensitivity: \(context.skinProfile.sensitivity.rawValue)")
        parts.append("Primary Concerns: \(context.skinProfile.primaryConcerns.map(\.rawValue).joined(separator: ", "))")
        parts.append("Primary Goal: \(context.skinProfile.primaryGoal.rawValue)")

        if let map = context.latestSkinMap {
            parts.append("Recent Skin Map (\(map.zones.count) zones analyzed):")
            for zone in map.zones {
                parts.append("  \(zone.zoneType.displayName): breakouts=\(zone.status.breakouts.rawValue), redness=\(zone.status.redness.rawValue), dryness=\(zone.status.dryness.rawValue), texture=\(zone.status.texture.rawValue), congestion=\(zone.status.congestion.rawValue)")
            }
        }

        if let env = context.environmentalContext {
            parts.append("Current Environment: UV index \(env.uvIndex), humidity \(env.humidity)%, \(env.weatherCondition)")
        }

        let productNames = context.currentProducts.filter(\.isActive).map(\.name)
        if !productNames.isEmpty {
            parts.append("Current Products: \(productNames.joined(separator: ", "))")
        }

        if let weekly = context.weeklyInsight {
            parts.append("Weekly Insight: \(weekly.summaryTitle)")
            parts.append("Details: \(weekly.summaryText)")
        }

        parts.append("""

Generate a personalized skincare insight in this exact JSON format:
{
  "title": "Short, actionable title (max 6 words)",
  "body": "2-3 sentences of personalized, evidence-based advice. Be specific and reference the user's data.",
  "category": "hydration|texture|pigmentation|redness|routine|product|environment|general",
  "confidence": "high|medium|low",
  "suggestedActions": [
    {"title": "Action label", "actionType": "adjustRoutine|tryProduct|bookConsultation|scanAgain|readMore"}
  ]
}
""")

        return parts.joined(separator: "\n")
    }

    private func buildQAPrompt(question: String, context: AIInsightContext) -> String {
        var parts: [String] = []

        if let name = context.userName {
            parts.append("User: \(name)")
        }

        parts.append("Skin Profile: \(context.skinProfile.skinType.rawValue), sensitivity: \(context.skinProfile.sensitivity.rawValue), concerns: \(context.skinProfile.primaryConcerns.map(\.rawValue).joined(separator: ", "))")

        if let map = context.latestSkinMap {
            let zoneSummaries = map.zones.map { "\($0.zoneType.displayName): dryness=\($0.status.dryness.rawValue), redness=\($0.status.redness.rawValue), texture=\($0.status.texture.rawValue)" }
            parts.append("Latest Skin Map: \(zoneSummaries.joined(separator: "; "))")
        }

        let productNames = context.currentProducts.filter(\.isActive).map(\.name)
        if !productNames.isEmpty {
            parts.append("Products: \(productNames.joined(separator: ", "))")
        }

        parts.append("\nQuestion: \(question)")
        parts.append("\nAnswer in 2-3 concise sentences. Be specific to their profile and products. Do not recommend medical treatment.")

        return parts.joined(separator: "\n")
    }

    private func parseInsightResponse(_ text: String) throws -> AIInsightResponse {
        // Extract JSON from possible markdown code block
        let jsonString: String
        if let start = text.range(of: "{"), let end = text.range(of: "}", range: start.upperBound..<text.endIndex) {
            jsonString = String(text[start.lowerBound...end.upperBound])
        } else {
            jsonString = text
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw AIError.parsingFailed
        }

        struct ParsedInsight: Decodable {
            let title: String
            let body: String
            let category: String
            let confidence: String
            let suggestedActions: [ParsedAction]

            struct ParsedAction: Decodable {
                let title: String
                let actionType: String
            }
        }

        let parsed = try JSONDecoder().decode(ParsedInsight.self, from: data)

        let actions = parsed.suggestedActions.map { action in
            AISuggestedAction(
                title: action.title,
                actionType: Self.parseActionType(action.actionType)
            )
        }

        return AIInsightResponse(
            title: parsed.title,
            body: parsed.body,
            category: AIInsightCategory(rawValue: parsed.category) ?? .general,
            confidence: AIConfidenceLevel(rawValue: parsed.confidence) ?? .medium,
            suggestedActions: actions
        )
    }

    // MARK: - Helpers

    private static func parseActionType(_ raw: String) -> AIActionType {
        switch raw.lowercased() {
        case "adjustroutine", "adjust_routine": return .adjustRoutine
        case "tryproduct", "try_product": return .tryProduct
        case "bookconsultation", "book_consultation": return .bookConsultation
        case "scanagain", "scan_again": return .scanAgain
        default: return .readMore
        }
    }

    private static var systemInstructionText: String {
        """
        You are Clera, a knowledgeable and empathetic skincare advisor.
        You analyze user skin data and provide concise, actionable, evidence-based advice.
        Rules:
        - Never diagnose medical conditions.
        - Base recommendations on the user's actual scan scores, products, and environment.
        - Keep responses focused and practical.
        - Suggest specific product types or routine adjustments when relevant.
        - If data is limited, acknowledge uncertainty and suggest a scan.
        """
    }
}

// MARK: - AI Errors

enum AIError: Error, Equatable {
    case serviceUnavailable
    case emptyResponse
    case generationFailed(String)
    case parsingFailed

    var localizedDescription: String {
        switch self {
        case .serviceUnavailable:
            return "AI insights are temporarily unavailable."
        case .emptyResponse:
            return "Received an empty response from the AI."
        case .generationFailed(let reason):
            return "Failed to generate insight: \(reason)"
        case .parsingFailed:
            return "Failed to parse the AI response."
        }
    }
}
