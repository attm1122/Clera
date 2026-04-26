import Foundation

// MARK: - Insight Template Renderer

enum InsightTemplateRenderer {

    static func renderSummary(state: SkinStateSummary, safety: SafetyAssessment) -> String {
        switch safety.level {
        case .urgentReview:
            return "Your skin shows signs of significant irritation. Consider simplifying your routine and monitoring closely."
        case .recommendProfessionalReview:
            return "Some metrics are elevated. If they persist, speaking with a skincare professional may be helpful."
        case .caution:
            return "Your skin has some changes worth watching. Stay consistent and track how it responds."
        case .normal:
            break
        }

        guard let concern = state.primaryConcern else {
            return "Your skin looks balanced today. Keep up your consistent routine."
        }

        switch concern {
        case .redness:
            return "Redness is the most noticeable pattern right now. A gentle, simplified routine may help."
        case .breakoutLikeSpots:
            return "Breakout-like spots are the main focus area. Consistent cleansing and avoiding new products can help."
        case .texture:
            return "Texture is the primary observation. Gentle exfoliation and hydration support smoother skin over time."
        case .shine:
            return "Oiliness is most noticeable. A light, non-comedogenic routine helps manage shine without over-drying."
        case .dryness:
            return "Dryness is the main pattern. Focus on barrier support and avoid over-exfoliation."
        case .pigmentation:
            return "Pigmentation variations are most visible. Consistent SPF is the most important step for this concern."
        case .evenness:
            return "Evenness is the primary observation. A balanced routine and patience are key here."
        }
    }

    static func renderZoneSummary(zone: ZoneType, score: ZoneSkinScore, trends: [EngineSkinTrend]) -> String {
        var parts: [String] = []

        let topMetric = topConcern(for: score)
        if let metric = topMetric {
            parts.append("\(metric.displayName) is the most noticeable pattern here.")
        }

        let improving = trends.filter { $0.direction == .improving }
        let worsening = trends.filter { $0.direction == .worsening }

        if !improving.isEmpty {
            let names = improving.map { $0.metric.displayName }.joined(separator: ", ")
            parts.append("\(names) look(s) improved compared to baseline.")
        }

        if !worsening.isEmpty {
            let names = worsening.map { $0.metric.displayName }.joined(separator: ", ")
            parts.append("\(names) may be more pronounced — worth monitoring.")
        }

        if parts.isEmpty {
            parts.append("This zone looks stable. Keep tracking over time.")
        }

        return parts.joined(separator: " ")
    }

    static func renderProgressHighlights(state: SkinStateSummary, trends: [ZoneType: [EngineSkinTrend]]) -> [ProgressHighlight] {
        var highlights: [ProgressHighlight] = []

        // Most improved
        if let improvedZone = state.mostImprovedZone {
            highlights.append(ProgressHighlight(
                kind: .mostImproved,
                zone: improvedZone,
                metric: nil,
                message: "\(improvedZone.displayName) shows the most improvement overall."
            ))
        }

        // Needs attention
        if let riskZone = state.highestRiskZone {
            highlights.append(ProgressHighlight(
                kind: .needsAttention,
                zone: riskZone,
                metric: state.primaryConcern,
                message: "\(riskZone.displayName) is the area to focus on right now."
            ))
        }

        // Stable baseline
        let allStable = trends.values.flatMap { $0 }.allSatisfy { $0.direction == .stable }
        if allStable && !trends.isEmpty {
            highlights.append(ProgressHighlight(
                kind: .stable,
                zone: nil,
                metric: nil,
                message: "Your skin is holding steady — consistency is working."
            ))
        }

        // Milestone: first scan after baseline
        if trends.isEmpty && state.overallScore > 0 {
            highlights.append(ProgressHighlight(
                kind: .newBaseline,
                zone: nil,
                metric: nil,
                message: "This is your first scan. Come back in a week to see how your skin changes."
            ))
        }

        return highlights
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
}
