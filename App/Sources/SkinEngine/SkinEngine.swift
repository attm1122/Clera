import Foundation

// MARK: - Skin Engine

/// Deterministic, rule-based skin intelligence engine.
/// All outputs are explainable, testable, and derived from explicit rules.
enum SkinEngine {

    static func generateReport(context: SkinContext) -> SkinEngineReport {
        let now = Date()

        // 1. Score zones
        let zoneScores = SkinScoreCalculator.calculateZoneScores(from: context.latestSkinMap)

        // 2. Detect trends
        let trends = SkinChangeDetector.detectTrends(context: context)

        // 3. Calculate overall state
        var state = SkinScoreCalculator.calculateOverallState(from: zoneScores)
        state.mostImprovedZone = SkinScoreCalculator.mostImprovedZone(trends)

        // 4. Build zone summaries
        let zoneSummaries = zoneScores.map { score in
            ZoneSummary(
                zone: score.zone,
                scores: score,
                trends: trends[score.zone] ?? [],
                topConcern: topConcern(for: score),
                explanation: InsightTemplateRenderer.renderZoneSummary(zone: score.zone, score: score, trends: trends[score.zone] ?? [])
            )
        }

        // 5. Run rule engines
        let envRisks = EnvironmentRuleEngine.evaluate(context: context)
        let routineWarnings = RoutineRuleEngine.evaluate(context: context, trends: trends)
        let productWarnings = ProductRuleEngine.evaluate(context: context, trends: trends)
        let safety = SafetyRuleEngine.evaluate(context: context, trends: trends, scores: zoneScores)

        // 6. Build progress highlights
        let progressHighlights = InsightTemplateRenderer.renderProgressHighlights(state: state, trends: trends)

        // 7. Combine and rank all recommendations
        let allRecommendations = envRisks + routineWarnings + productWarnings
        let topRecommendations = RecommendationRanker.top(allRecommendations, count: 5)

        // 8. Build summary
        let summary = InsightTemplateRenderer.renderSummary(state: state, safety: safety)

        // 9. Compute overall confidence
        let overallConfidence = computeOverallConfidence(zoneScores: zoneScores, context: context)

        return SkinEngineReport(
            id: UUID(),
            generatedAt: now,
            summary: summary,
            skinState: state,
            zoneSummaries: zoneSummaries,
            recommendations: topRecommendations,
            environmentRisks: envRisks,
            routineWarnings: routineWarnings,
            productWarnings: productWarnings,
            progressHighlights: progressHighlights,
            safetyAssessment: safety,
            confidence: overallConfidence
        )
    }

    // MARK: - Private

    private static func topConcern(for score: ZoneSkinScore) -> SkinMetricKey? {
        let metrics: [(SkinMetricKey, Int)] = [
            (.breakoutLikeSpots, score.breakout),
            (.redness, score.redness),
            (.texture, score.texture),
            (.shine, score.oiliness),
            (.dryness, score.dryness),
            (.pigmentation, score.pigmentation),
            (.evenness, score.congestion)
        ]
        return metrics.max(by: { $0.1 < $1.1 })?.0
    }

    private static func computeOverallConfidence(zoneScores: [ZoneSkinScore], context: SkinContext) -> EngineConfidence {
        var reasons: [String] = []
        var level: EngineConfidenceLevel = .high

        if zoneScores.isEmpty {
            reasons.append("No scan data available.")
            level = .low
        } else {
            let lowConfidenceZones = zoneScores.filter { $0.confidence.level == .low }
            if !lowConfidenceZones.isEmpty {
                reasons.append("Some zones have low scan confidence.")
                level = .low
            } else {
                let mediumConfidenceZones = zoneScores.filter { $0.confidence.level == .medium }
                if !mediumConfidenceZones.isEmpty {
                    reasons.append("Some zones have medium scan confidence.")
                    level = .medium
                }
            }
        }

        if context.isFirstTimeUser {
            reasons.append("First-time user — limited history for trend detection.")
            if level == .high { level = .medium }
        }

        if context.routineLogs.isEmpty {
            reasons.append("No routine history available.")
        }

        if context.products.isEmpty {
            reasons.append("No product list available.")
        }

        return EngineConfidence(level: level, reasons: reasons)
    }


}
