import Foundation

/// Generates safe, cosmetic, non-diagnostic insights and next steps.
enum SkinInsightGenerator {

    static let disclaimer = "Clera provides cosmetic skin tracking insights only and does not provide medical advice, diagnosis, or treatment."

    // MARK: - Top Insight

    static func topInsight(for zoneAnalysis: SkinZoneAnalysis, baseline: SkinBaseline?) -> String {
        guard let baselineMetrics = baseline?.zoneScores[zoneAnalysis.zone] else {
            return "First scan for this zone. Future scans will show comparisons."
        }

        // Find the metric with the most significant change
        let significantMetrics = zoneAnalysis.metrics
            .compactMap { (key, score) -> (SkinMetricKey, SkinMetricScore, Int)? in
                guard let baselineScore = baselineMetrics[key] else { return nil }
                let diff = abs(score.score - baselineScore)
                return (key, score, diff)
            }
            .sorted { $0.2 > $1.2 }

        guard let top = significantMetrics.first else {
            return "No significant changes detected in \(zoneAnalysis.zone.displayName)."
        }

        return insightMessage(for: top.0, zone: zoneAnalysis.zone, trend: top.1.trend)
    }

    // MARK: - Next Step

    static func nextStep(for zone: SkinZone, metric: SkinMetricKey, trend: SkinTrend) -> String {
        switch (metric, trend) {
        case (.breakoutLikeSpots, .increased), (.breakoutLikeSpots, .slightlyIncreased):
            return "Review recent products, stress, sleep, or hormonal changes."
        case (.redness, .increased), (.redness, .slightlyIncreased):
            return "Consider whether any new products or environmental factors changed."
        case (.texture, .increased), (.texture, .slightlyIncreased):
            return "Ensure consistent cleansing and moisturising."
        case (.shine, .increased), (.shine, .slightlyIncreased):
            return "Consider whether your moisturiser or cleanser changed."
        case (.dryness, .increased), (.dryness, .slightlyIncreased):
            return "Review your moisturising routine and environment."
        case (.pigmentation, .increased), (.pigmentation, .slightlyIncreased):
            return "Consider sun protection consistency and any recent sun exposure."
        case (.breakoutLikeSpots, .improved), (.breakoutLikeSpots, .slightlyReduced):
            return "Keep up your current routine."
        case (.redness, .improved), (.redness, .slightlyReduced):
            return "Your routine may be working well. Keep it consistent."
        case (.texture, .improved), (.texture, .slightlyReduced):
            return "Texture looks smoother. Keep up your current approach."
        case (.evenness, .improved), (.evenness, .slightlyReduced):
            return "Skin tone evenness is heading in a good direction."
        default:
            return "Keep up your current routine."
        }
    }

    // MARK: - Summary

    static func generateSummary(
        zoneAnalyses: [SkinZoneAnalysis],
        comparison: BaselineComparison?
    ) -> SkinAnalysisSummary {
        guard let comparison = comparison else {
            return SkinAnalysisSummary(
                overallStatus: .insufficientData,
                primaryChange: "This is your first scan. Future scans will compare against this baseline.",
                confidence: .medium,
                disclaimer: disclaimer
            )
        }

        let status = TrendAnalyzer.overallStatus(from: comparison)

        // Find the single most significant change across all zones
        var topChange: (SkinZone, SkinMetricKey, SkinTrend)?
        var topDiff = 0

        for zone in zoneAnalyses {
            guard let trends = comparison.zoneComparisons[zone.zone] else { continue }
            guard let baselineMetrics = BaselineManager().currentBaseline?.zoneScores[zone.zone] else { continue }

            for (metric, trend) in trends {
                guard let currentScore = zone.metrics[metric]?.score,
                      let baselineScore = baselineMetrics[metric] else { continue }
                let diff = abs(currentScore - baselineScore)
                if diff > topDiff && (trend == .increased || trend == .improved) {
                    topDiff = diff
                    topChange = (zone.zone, metric, trend)
                }
            }
        }

        let primaryChange: String
        if let (zone, metric, trend) = topChange {
            let metricName = metric.displayName.lowercased()
            let zoneName = zone.displayName
            switch trend {
            case .increased, .slightlyIncreased:
                primaryChange = "\(metricName.capitalized) appears increased around the \(zoneName.lowercased())."
            case .improved, .slightlyReduced:
                primaryChange = "\(metricName.capitalized) appears improved around the \(zoneName.lowercased())."
            default:
                primaryChange = "Some minor changes detected across your skin map."
            }
        } else {
            primaryChange = "Your skin looks stable compared to your baseline."
        }

        let confidence = confidenceFromZones(zoneAnalyses)

        return SkinAnalysisSummary(
            overallStatus: status,
            primaryChange: primaryChange,
            confidence: confidence,
            disclaimer: disclaimer
        )
    }

    // MARK: - Private

    private static func insightMessage(for metric: SkinMetricKey, zone: SkinZone, trend: SkinTrend) -> String {
        let zoneName = zone.displayName.lowercased()
        let metricName = metric.displayName.lowercased()

        switch (metric, trend) {
        case (.redness, .increased), (.redness, .slightlyIncreased):
            return "Redness appears increased around the \(zoneName)."
        case (.redness, .improved), (.redness, .slightlyReduced):
            return "Redness appears calmer around the \(zoneName)."
        case (.redness, .stable):
            return "Redness looks stable around the \(zoneName)."

        case (.texture, .increased), (.texture, .slightlyIncreased):
            return "Texture appears slightly rougher around the \(zoneName)."
        case (.texture, .improved), (.texture, .slightlyReduced):
            return "Texture looks smoother around the \(zoneName)."
        case (.texture, .stable):
            return "Texture looks stable around the \(zoneName)."

        case (.breakoutLikeSpots, .increased), (.breakoutLikeSpots, .slightlyIncreased):
            return "Breakout-like spots appear increased around the \(zoneName)."
        case (.breakoutLikeSpots, .improved), (.breakoutLikeSpots, .slightlyReduced):
            return "Breakout-like spots appear reduced around the \(zoneName)."
        case (.breakoutLikeSpots, .stable):
            return "Breakout-like spots look stable around the \(zoneName)."

        case (.pigmentation, .increased), (.pigmentation, .slightlyIncreased):
            return "Pigmentation appears slightly more noticeable around the \(zoneName)."
        case (.pigmentation, .improved), (.pigmentation, .slightlyReduced):
            return "Pigmentation appears less noticeable around the \(zoneName)."
        case (.pigmentation, .stable):
            return "Pigmentation looks consistent around the \(zoneName)."

        case (.shine, .increased), (.shine, .slightlyIncreased):
            return "Shine appears higher around the \(zoneName), suggesting more oiliness."
        case (.shine, .improved), (.shine, .slightlyReduced):
            return "Shine appears lower around the \(zoneName)."
        case (.shine, .stable):
            return "Shine looks stable around the \(zoneName)."

        case (.dryness, .increased), (.dryness, .slightlyIncreased):
            return "Dryness signals appear slightly elevated around the \(zoneName)."
        case (.dryness, .improved), (.dryness, .slightlyReduced):
            return "Dryness signals appear lower around the \(zoneName)."
        case (.dryness, .stable):
            return "Dryness signals look consistent around the \(zoneName)."

        case (.evenness, .improved), (.evenness, .slightlyReduced):
            return "Skin tone evenness appears improved around the \(zoneName)."
        case (.evenness, .increased), (.evenness, .slightlyIncreased):
            return "Skin tone evenness appears slightly reduced around the \(zoneName)."
        case (.evenness, .stable):
            return "Colour distribution looks consistent around the \(zoneName)."

        default:
            return "\(metricName.capitalized) around the \(zoneName) is being tracked."
        }
    }

    private static func confidenceFromZones(_ zones: [SkinZoneAnalysis]) -> ScanQualityResult.QualityConfidence {
        let scores = zones.map { $0.confidence }
        let highCount = scores.filter { $0 == .high }.count
        let lowCount = scores.filter { $0 == .low }.count

        if highCount >= 3 { return .high }
        if lowCount >= 3 { return .low }
        return .medium
    }
}
