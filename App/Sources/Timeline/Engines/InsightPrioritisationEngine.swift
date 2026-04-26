import Foundation

/// Ranks and filters insights so users see only the most relevant, high-confidence information.
/// Output: one primary insight + one optional secondary insight.
enum InsightPrioritisationEngine {

    static func prioritise(
        insights: [Insight],
        whatChanged: WhatChangedResult?,
        weeklyInsight: WeeklyInsight?,
        patterns: [PatternInsight],
        maxPrimary: Int = 1,
        maxSecondary: Int = 1
    ) -> PrioritisedInsights {

        var scoredInsights: [ScoredInsight] = []

        // Score existing insights
        for insight in insights {
            let score = computeScore(
                insight: insight,
                whatChanged: whatChanged,
                weeklyInsight: weeklyInsight
            )
            scoredInsights.append(ScoredInsight(insight: insight, score: score))
        }

        // Convert what-changed items to insights
        if let whatChanged = whatChanged {
            if let primary = whatChanged.primaryChange {
                let insight = Insight(
                    title: primary.message,
                    body: primary.message,
                    type: primary.trend == .increasing ? .regression : .improvement,
                    zone: primary.zone,
                    priority: primary.confidence == .high ? .high : .medium
                )
                scoredInsights.append(ScoredInsight(
                    insight: insight,
                    score: 10.0 + (primary.confidence == .high ? 2.0 : 0.0)
                ))
            }

            if let secondary = whatChanged.secondaryChange {
                let insight = Insight(
                    title: secondary.message,
                    body: secondary.message,
                    type: secondary.trend == .increasing ? .regression : .improvement,
                    zone: secondary.zone,
                    priority: .medium
                )
                scoredInsights.append(ScoredInsight(
                    insight: insight,
                    score: 7.0 + (secondary.confidence == .high ? 1.0 : 0.0)
                ))
            }
        }

        // Convert weekly insight zone highlights
        if let weekly = weeklyInsight {
            for highlight in weekly.zoneHighlights where highlight.trend != .stable {
                let type: InsightType = highlight.trend == .improving ? .improvement : .regression
                let insight = Insight(
                    title: "\(highlight.zone.displayName): \(highlight.trend.displayName)",
                    body: highlight.description,
                    type: type,
                    zone: highlight.zone,
                    priority: .medium
                )
                scoredInsights.append(ScoredInsight(insight: insight, score: 6.0))
            }
        }

        // Convert unlocked patterns
        for pattern in patterns where pattern.isUnlocked {
            let insight = Insight(
                title: pattern.title,
                body: pattern.body,
                type: .habit,
                zone: pattern.relatedZones.first,
                priority: .low
            )
            scoredInsights.append(ScoredInsight(insight: insight, score: 4.0))
        }

        // Sort by score descending
        scoredInsights.sort { $0.score > $1.score }

        // Deduplicate by zone + type + metric (if available in title)
        // This allows multiple insights for the same zone if they cover different metrics,
        // while preventing exact duplicates.
        var seenKeys = Set<String>()
        var deduplicated: [ScoredInsight] = []
        for scored in scoredInsights {
            let zoneKey = scored.insight.zone?.rawValue ?? "nil"
            let typeKey = scored.insight.type.rawValue
            // Extract first word of title as proxy for metric/topic
            let topicKey = scored.insight.title.split(separator: " ").first?.lowercased() ?? "none"
            let key = "\(zoneKey)|\(typeKey)|\(topicKey)"
            if seenKeys.contains(key) { continue }
            seenKeys.insert(key)
            deduplicated.append(scored)
        }

        let primary = Array(deduplicated.prefix(maxPrimary).map(\.insight))
        let secondary = Array(deduplicated.dropFirst(maxPrimary).prefix(maxSecondary).map(\.insight))

        return PrioritisedInsights(
            primary: primary,
            secondary: secondary,
            allInsights: deduplicated.map(\.insight)
        )
    }

    // MARK: - Private

    private struct ScoredInsight {
        var insight: Insight
        var score: Double
    }

    private static func computeScore(
        insight: Insight,
        whatChanged: WhatChangedResult?,
        weeklyInsight: WeeklyInsight?
    ) -> Double {
        var score: Double = 0

        // Priority weight
        score += priorityWeight(insight.priority)

        // Type weight
        score += typeWeight(insight.type)

        // Recency boost if mentioned in what-changed or weekly
        if let whatChanged = whatChanged {
            if whatChanged.primaryChange?.zone == insight.zone {
                score += 3.0
            }
            if whatChanged.secondaryChange?.zone == insight.zone {
                score += 1.5
            }
        }

        if let weekly = weeklyInsight {
            if weekly.zoneHighlights.contains(where: { $0.zone == insight.zone }) {
                score += 1.0
            }
        }

        // Zone importance (chin/jaw often most reactive)
        if insight.zone == .chinJaw {
            score += 0.5
        }

        return score
    }

    private static func priorityWeight(_ priority: InsightPriority) -> Double {
        switch priority {
        case .high: return 4.0
        case .medium: return 2.5
        case .low: return 1.0
        }
    }

    private static func typeWeight(_ type: InsightType) -> Double {
        switch type {
        case .improvement: return 3.0
        case .regression: return 3.0
        case .correlation: return 2.0
        case .habit: return 1.5
        case .environment: return 1.0
        case .productEffect: return 2.5
        }
    }
}

// MARK: - Result

struct PrioritisedInsights: Codable, Equatable, Sendable {
    var primary: [Insight]
    var secondary: [Insight]
    var allInsights: [Insight]
}
