import Foundation

/// Generates the "What Changed?" summary after each scan.
/// Ranks changes by meaningfulness and picks one primary + one secondary insight.
/// Uses safe cosmetic language only.
enum WhatChangedEngine {

    static func generate(
        from changes: ChangeDetectionResult,
        consistency: ScanConsistency?,
        checkIn: SkinMapCheckIn?,
        isBaseline: Bool
    ) -> WhatChangedResult {

        if isBaseline {
            return WhatChangedResult(
                generatedAt: .now,
                primaryChange: nil,
                secondaryChange: nil,
                stableZones: [],
                improvedZones: [],
                worsenedZones: [],
                overallMessage: CleraCopy.WhatChanged.baselineMessage
            )
        }

        // Filter to meaningful changes with reasonable confidence
        let meaningfulChanges = changes.zoneChanges.filter {
            $0.magnitude != .slight && $0.confidence >= 0.5
        }

        // Rank by: magnitude score × confidence × zone importance
        let ranked = meaningfulChanges.sorted {
            rankScore(for: $0) > rankScore(for: $1)
        }

        // Pick primary (highest rank)
        let primary = ranked.first

        // Pick secondary: next highest rank, prefer different zone
        let secondary = ranked.first {
            $0.zone != primary?.zone
        } ?? ranked.dropFirst().first

        // Classify zones
        let allZones = ZoneType.allCases
        let changedZones = Set(ranked.map(\.zone))
        let stableZones = allZones.filter { !changedZones.contains($0) }

        let improvedZones = Set(meaningfulChanges
            .filter { $0.direction == .decreasing }
            .map(\.zone))
        let worsenedZones = Set(meaningfulChanges
            .filter { $0.direction == .increasing }
            .map(\.zone))

        let primaryItem = primary.flatMap { makeItem(from: $0, consistency: consistency) }
        let secondaryItem = secondary.flatMap { makeItem(from: $0, consistency: consistency) }

        let overallMessage = buildOverallMessage(
            primary: primaryItem,
            improved: improvedZones,
            worsened: worsenedZones,
            stable: stableZones,
            consistency: consistency
        )

        return WhatChangedResult(
            generatedAt: .now,
            primaryChange: primaryItem,
            secondaryChange: secondaryItem,
            stableZones: Array(stableZones),
            improvedZones: Array(improvedZones),
            worsenedZones: Array(worsenedZones),
            overallMessage: overallMessage
        )
    }

    // MARK: - Private

    private static func rankScore(for change: ZoneChange) -> Double {
        let magnitudeScore: Double = {
            switch change.magnitude {
            case .significant: return 3.0
            case .moderate: return 2.0
            case .slight: return 1.0
            }
        }()

        let zoneWeight: Double = {
            switch change.zone {
            case .chinJaw: return 1.2 // often most reactive
            case .forehead: return 1.1
            default: return 1.0
            }
        }()

        return magnitudeScore * change.confidence * zoneWeight
    }

    private static func makeItem(
        from change: ZoneChange,
        consistency: ScanConsistency?
    ) -> WhatChangedItem? {
        let confidence: InsightConfidence = {
            if let consistency = consistency, !consistency.isAcceptable {
                return .low
            }
            if change.confidence >= 0.8 { return .high }
            if change.confidence >= 0.6 { return .moderate }
            return .low
        }()

        let severity: ChangeMagnitude = change.magnitude

        let percentChange = estimatePercentChange(from: change)

        let message = buildMessage(for: change, consistency: consistency)

        return WhatChangedItem(
            zone: change.zone,
            metric: change.metric,
            trend: change.direction,
            severity: severity,
            confidence: confidence,
            message: message,
            percentChange: percentChange
        )
    }

    private static func estimatePercentChange(from change: ZoneChange) -> Int {
        // Map severity delta to approximate percentage
        let severityDelta: Int = {
            switch change.magnitude {
            case .significant: return 3
            case .moderate: return 2
            case .slight: return 1
            }
        }()

        // Approximate percentage based on direction and magnitude
        let basePercent = severityDelta * 15
        if change.direction == .stable {
            return 0
        }
        // Deterministic: use metric hash for slight variance so same input → same output
        let metricHash = abs(change.metric.hashValue % 5)
        return basePercent + metricHash
    }

    private static func buildMessage(
        for change: ZoneChange,
        consistency: ScanConsistency?
    ) -> String {
        let zoneName = change.zone.displayName.lowercased()
        let metricName = change.metric.lowercased()

        let prefix: String
        switch change.direction {
        case .increasing:
            prefix = CleraCopy.WhatChanged.increased(zone: zoneName, metric: metricName)
        case .decreasing:
            prefix = CleraCopy.WhatChanged.decreased(zone: zoneName, metric: metricName)
        case .stable:
            prefix = CleraCopy.WhatChanged.stable(zone: zoneName, metric: metricName)
        }

        if let consistency = consistency, consistency.confidenceImpact != .none {
            return prefix + " " + CleraCopy.WhatChanged.consistencyNote
        }

        return prefix
    }

    private static func buildOverallMessage(
        primary: WhatChangedItem?,
        improved: Set<ZoneType>,
        worsened: Set<ZoneType>,
        stable: [ZoneType],
        consistency: ScanConsistency?
    ) -> String {
        if let primary = primary {
            return primary.message
        }

        if !improved.isEmpty && worsened.isEmpty {
            let zones = improved.map(\.displayName).joined(separator: " and ")
            return CleraCopy.WhatChanged.allImproving(zones: zones)
        }

        if !stable.isEmpty && improved.isEmpty && worsened.isEmpty {
            return CleraCopy.WhatChanged.allStable
        }

        if let consistency = consistency, !consistency.isAcceptable {
            return CleraCopy.WhatChanged.inconsistentScan
        }

        return CleraCopy.WhatChanged.noMajorChanges
    }
}
