import Foundation

// MARK: - Skin Score Calculator

enum SkinScoreCalculator {
    enum Thresholds {
        static let highConfidence = 0.7
        static let mediumConfidence = 0.4
        static let severityNoneScore = 10
        static let severityLowScore = 30
        static let severityModerateScore = 55
        static let severityHighScore = 80
    }

    static func calculateZoneScores(from skinMap: SkinMap?) -> [ZoneSkinScore] {
        guard let skinMap = skinMap else {
            return ZoneType.allCases.map { zone in
                ZoneSkinScore(
                    zone: zone,
                    breakout: 0,
                    redness: 0,
                    texture: 0,
                    oiliness: 0,
                    dryness: 0,
                    pigmentation: 0,
                    congestion: 0,
                    sensitivity: 0,
                    confidence: EngineConfidence(level: .low, reasons: ["No scan data available"])
                )
            }
        }

        return skinMap.zones.map { faceZone in
            let status = faceZone.status
            let confidence = faceZone.status.overallConfidence

            return ZoneSkinScore(
                zone: faceZone.zoneType,
                breakout: severityToScore(status.breakouts),
                redness: severityToScore(status.redness),
                texture: severityToScore(status.texture),
                oiliness: severityToScore(status.congestion),
                dryness: severityToScore(status.dryness),
                pigmentation: severityToScore(status.redness),
                congestion: severityToScore(status.congestion),
                sensitivity: severityToScore(status.irritation),
                confidence: EngineConfidence(
                    level: confidence > Thresholds.highConfidence ? .high : confidence > Thresholds.mediumConfidence ? .medium : .low,
                    reasons: confidence > Thresholds.highConfidence ? ["Good scan quality"] : ["Limited scan confidence"]
                )
            )
        }
    }

    static func calculateOverallState(from scores: [ZoneSkinScore]) -> SkinStateSummary {
        guard !scores.isEmpty else {
            return SkinStateSummary(
                overallScore: 0,
                highestRiskZone: nil,
                mostImprovedZone: nil,
                primaryConcern: nil,
                overallTrend: .unknown
            )
        }

        let avgScore = scores.map { zoneAverage($0) }.reduce(0, +) / scores.count
        let highestRisk = scores.max { zoneAverage($0) < zoneAverage($1) }
        let allMetrics = scores.flatMap { scoreMetrics($0) }
        let primaryConcern = allMetrics.max { $0.value < $1.value }?.key

        return SkinStateSummary(
            overallScore: avgScore,
            highestRiskZone: highestRisk?.zone,
            mostImprovedZone: nil,
            primaryConcern: primaryConcern,
            overallTrend: .unknown
        )
    }

    // MARK: - Helpers

    private static func severityToScore(_ severity: ZoneSeverity) -> Int {
        switch severity {
        case .none: return Thresholds.severityNoneScore
        case .low: return Thresholds.severityLowScore
        case .moderate: return Thresholds.severityModerateScore
        case .high: return Thresholds.severityHighScore
        }
    }

    static func zoneAverage(_ score: ZoneSkinScore) -> Int {
        let values = [score.breakout, score.redness, score.texture, score.oiliness, score.dryness, score.pigmentation, score.congestion, score.sensitivity]
        return values.reduce(0, +) / values.count
    }

    static func highestRiskZone(_ scores: [ZoneSkinScore]) -> ZoneType? {
        scores.max { zoneAverage($0) < zoneAverage($1) }?.zone
    }

    static func mostImprovedZone(_ trends: [ZoneType: [EngineSkinTrend]]) -> ZoneType? {
        var bestZone: ZoneType?
        var bestImprovement = 0
        for (zone, zoneTrends) in trends {
            let improvement = zoneTrends.filter { $0.direction == .improving }.count
            if improvement > bestImprovement {
                bestImprovement = improvement
                bestZone = zone
            }
        }
        return bestZone
    }

    private static func scoreMetrics(_ score: ZoneSkinScore) -> [SkinMetricKey: Int] {
        [
            .breakoutLikeSpots: score.breakout,
            .redness: score.redness,
            .texture: score.texture,
            .shine: score.oiliness,
            .dryness: score.dryness,
            .pigmentation: score.pigmentation,
            .evenness: score.congestion
        ]
    }
}
