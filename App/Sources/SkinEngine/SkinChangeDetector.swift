import Foundation

// MARK: - Skin Change Detector

enum SkinChangeDetector {

    static func detectTrends(context: SkinContext) -> [ZoneType: [EngineSkinTrend]] {
        var result: [ZoneType: [EngineSkinTrend]] = [:]

        guard let latest = context.latestSkinMap else { return result }

        for zone in latest.zones {
            let zoneType = zone.zoneType
            var trends: [EngineSkinTrend] = []

            // Compare to baseline
            if let baseline = context.baselineSkinMap?.zones.first(where: { $0.zoneType == zoneType }) {
                trends.append(contentsOf: compareZones(current: zone, previous: baseline, metric: nil, comparison: .baseline))
            }

            // Compare to previous scan
            if let previous = context.previousScan?.skinMap.zones.first(where: { $0.zoneType == zoneType }) {
                trends.append(contentsOf: compareZones(current: zone, previous: previous, metric: nil, comparison: .previousScan))
            }

            // Compare to 7-day average
            let sevenDayMaps = context.scansLastSevenDays.map(\.skinMap)
            if !sevenDayMaps.isEmpty {
                trends.append(contentsOf: compareToSevenDayAverage(current: zone, maps: sevenDayMaps))
            }

            if !trends.isEmpty {
                result[zoneType] = trends
            }
        }

        return result
    }

    // MARK: - Private

    private static func compareZones(current: FaceZone, previous: FaceZone, metric: SkinMetricKey?, comparison: TrendComparison) -> [EngineSkinTrend] {
        let metrics: [(SkinMetricKey, (FaceZone) -> ZoneSeverity)] = [
            (.breakoutLikeSpots, { $0.status.breakouts }),
            (.redness, { $0.status.redness }),
            (.texture, { $0.status.texture }),
            (.shine, { $0.status.congestion }),
            (.dryness, { $0.status.dryness }),
            (.evenness, { $0.status.congestion })
        ]

        return metrics.map { key, extractor in
            let currentScore = severityToScore(extractor(current))
            let previousScore = severityToScore(extractor(previous))
            let delta = currentScore - previousScore

            let direction: TrendDirection
            let severity: TrendSeverity
            if delta >= 15 {
                direction = .worsening
                severity = delta >= 25 ? .significant : .moderate
            } else if delta <= -10 {
                direction = .improving
                severity = delta <= -20 ? .significant : .moderate
            } else {
                direction = .stable
                severity = .mild
            }

            return EngineSkinTrend(
                metric: key,
                direction: direction,
                delta: delta,
                severity: severity,
                confidence: EngineConfidence(level: .medium, reasons: ["Compared to \(comparison.rawValue)"]),
                comparedTo: comparison
            )
        }
    }

    private static func compareToSevenDayAverage(current: FaceZone, maps: [SkinMap]) -> [EngineSkinTrend] {
        let metrics: [(SkinMetricKey, (FaceZone) -> ZoneSeverity)] = [
            (.breakoutLikeSpots, { $0.status.breakouts }),
            (.redness, { $0.status.redness }),
            (.texture, { $0.status.texture }),
            (.shine, { $0.status.congestion }),
            (.dryness, { $0.status.dryness }),
            (.evenness, { $0.status.congestion })
        ]

        return metrics.map { key, extractor in
            let currentScore = severityToScore(extractor(current))
            let sameZoneMaps = maps.compactMap { $0.zones.first(where: { $0.zoneType == current.zoneType }) }
            let avgScore = sameZoneMaps.map { severityToScore(extractor($0)) }.reduce(0, +) / max(sameZoneMaps.count, 1)
            let delta = currentScore - avgScore

            let direction: TrendDirection
            let severity: TrendSeverity
            if delta >= 15 {
                direction = .worsening
                severity = delta >= 25 ? .significant : .moderate
            } else if delta <= -10 {
                direction = .improving
                severity = delta <= -20 ? .significant : .moderate
            } else {
                direction = .stable
                severity = .mild
            }

            return EngineSkinTrend(
                metric: key,
                direction: direction,
                delta: delta,
                severity: severity,
                confidence: EngineConfidence(level: .medium, reasons: ["Compared to 7-day average"]),
                comparedTo: .sevenDayAverage
            )
        }
    }

    private static func severityToScore(_ severity: ZoneSeverity) -> Int {
        switch severity {
        case .none: return 10
        case .low: return 30
        case .moderate: return 55
        case .high: return 80
        }
    }
}
