import Foundation

// MARK: - Recommendation Ranker

enum RecommendationRanker {

    static func rank(_ recommendations: [SkinRecommendation]) -> [SkinRecommendation] {
        return recommendations.sorted { a, b in
            let priorityA = priorityScore(a.priority)
            let priorityB = priorityScore(b.priority)

            if priorityA != priorityB {
                return priorityA > priorityB
            }

            let confidenceA = confidenceScore(a.confidence)
            let confidenceB = confidenceScore(b.confidence)

            if confidenceA != confidenceB {
                return confidenceA > confidenceB
            }

            return a.createdAt > b.createdAt
        }
    }

    static func deduplicate(_ recommendations: [SkinRecommendation]) -> [SkinRecommendation] {
        var seenTitles: Set<String> = []
        return recommendations.filter { rec in
            let normalised = rec.title.lowercased().trimmingCharacters(in: .whitespaces)
            if seenTitles.contains(normalised) {
                return false
            }
            seenTitles.insert(normalised)
            return true
        }
    }

    static func top(_ recommendations: [SkinRecommendation], count: Int) -> [SkinRecommendation] {
        Array(rank(deduplicate(recommendations)).prefix(count))
    }

    // MARK: - Private

    private static func priorityScore(_ priority: RecommendationPriority) -> Int {
        switch priority {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }

    private static func confidenceScore(_ confidence: EngineConfidenceLevel) -> Int {
        switch confidence {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}
