import Foundation

enum TrendAnalyzer {
    enum Thresholds {
        static let stable: Double = 0.05
        static let significant: Double = 0.15
        static let baselineZeroDenominator: Double = 100.0
    }

    /// Threshold-based trend determination.
    /// - Under 5% change = stable
    /// - 5-15% change = slight change
    /// - 15%+ change = meaningful change
    static func compare(
        current: [SkinZone: [SkinMetricKey: SkinMetricScore]],
        baseline: SkinBaseline
    ) -> BaselineComparison {
        var zoneComparisons: [SkinZone: [SkinMetricKey: SkinTrend]] = [:]
        var totalChange: Double = 0
        var metricCount: Int = 0

        for (zone, currentMetrics) in current {
            var metricTrends: [SkinMetricKey: SkinTrend] = [:]
            for (metric, currentScore) in currentMetrics {
                guard let baselineScore = baseline.zoneScores[zone]?[metric] else {
                    metricTrends[metric] = .insufficientData
                    continue
                }
                let trend = trendForMetric(
                    currentScore: currentScore.score,
                    baselineScore: baselineScore,
                    metric: metric
                )
                metricTrends[metric] = trend

                let change = abs(Double(currentScore.score - baselineScore))
                totalChange += change
                metricCount += 1
            }
            zoneComparisons[zone] = metricTrends
        }

        let overallChangePercentage = metricCount > 0 ? totalChange / Double(metricCount) : 0
        let daysSinceBaseline = Calendar.current.dateComponents(
            [.day],
            from: baseline.createdAt,
            to: .now
        ).day ?? 0

        return BaselineComparison(
            baselineId: baseline.id,
            daysSinceBaseline: daysSinceBaseline,
            zoneComparisons: zoneComparisons,
            overallChangePercentage: overallChangePercentage
        )
    }

    /// Default trend comparison assuming higher score is worse (covers 6 of 7 metrics).
    static func trendForMetric(currentScore: Int, baselineScore: Int) -> SkinTrend {
        trendForMetric(currentScore: currentScore, baselineScore: baselineScore, metric: nil)
    }

    static func overallStatus(from comparison: BaselineComparison) -> SkinAnalysisSummary.OverallStatus {
        let allTrends = comparison.zoneComparisons.values.flatMap { $0.values }
        let increasedCount = allTrends.filter { $0 == .increased }.count
        let slightlyIncreasedCount = allTrends.filter { $0 == .slightlyIncreased }.count
        let improvedCount = allTrends.filter {
            $0 == .improved || $0 == .reduced || $0 == .slightlyReduced
        }.count

        let total = allTrends.count
        guard total > 0 else { return .insufficientData }

        let badRatio = Double(increasedCount + slightlyIncreasedCount) / Double(total)
        let goodRatio = Double(improvedCount) / Double(total)

        let significantChangeThreshold = 0.2
        let noticeableChangeThreshold = 0.1
        let goodChangeThreshold = 0.2

        if badRatio >= significantChangeThreshold {
            return .significantChanges
        } else if badRatio >= noticeableChangeThreshold || goodRatio >= goodChangeThreshold {
            return .noticeableChanges
        } else if badRatio > 0 || goodRatio > 0 {
            return .stableWithMinorChanges
        } else {
            return .stable
        }
    }

    // MARK: - Internal

    static func trendForMetric(
        currentScore: Int,
        baselineScore: Int,
        metric: SkinMetricKey?
    ) -> SkinTrend {
        let diff = Double(currentScore - baselineScore)
        let percentChange = baselineScore != 0
            ? abs(diff / Double(baselineScore))
            : abs(diff / Thresholds.baselineZeroDenominator)
        let higherIsWorse = metric != .evenness

        if percentChange < Thresholds.stable {
            return .stable
        }

        let increased = currentScore > baselineScore
        let significant = percentChange >= Thresholds.significant

        if higherIsWorse {
            if increased {
                return significant ? .increased : .slightlyIncreased
            } else {
                return significant ? .improved : .slightlyReduced
            }
        } else {
            if increased {
                return significant ? .improved : .slightlyReduced
            } else {
                return significant ? .increased : .slightlyIncreased
            }
        }
    }
}
