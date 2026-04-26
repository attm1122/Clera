import Foundation

enum InsightEngine {
    static func generateInsights(
        from sessions: [ScanSession],
        routineLogs: [RoutineLogEntry],
        experiments: [Experiment],
        existingInsights: [Insight]
    ) -> [Insight] {
        var insights: [Insight] = []

        insights.append(contentsOf: improvementInsights(from: sessions))
        insights.append(contentsOf: regressionInsights(from: sessions))
        insights.append(contentsOf: experimentInsights(from: experiments, sessions: sessions))
        insights.append(contentsOf: routineInsights(from: routineLogs, sessions: sessions))
        insights.append(contentsOf: suggestionInsights(from: sessions, experiments: experiments))

        // Deduplicate by title + zone
        var seen = Set<String>()
        return insights.filter {
            let key = "\($0.title)|\($0.zone?.rawValue ?? "nil")"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    // MARK: - Improvement Insights

    private static func improvementInsights(from sessions: [ScanSession]) -> [Insight] {
        guard sessions.count >= 2 else { return [] }
        let sorted = sessions.sorted(by: { $0.createdAt < $1.createdAt })
        guard let latest = sorted.last, let previous = sorted.dropLast().last else { return [] }

        var insights: [Insight] = []
        for zone in latest.skinMap.zones {
            guard let prevZone = previous.skinMap.zones.first(where: { $0.zoneType == zone.zoneType }) else { continue }

            if prevZone.status.breakouts.numericScore > zone.status.breakouts.numericScore {
                insights.append(Insight(
                    title: "\(zone.zoneType.displayName) breakouts improving",
                    body: CleraCopy.InsightEngine.breakoutsImproved(from: prevZone.status.breakouts.displayName.lowercased(), to: zone.status.breakouts.displayName.lowercased()),
                    type: .improvement,
                    zone: zone.zoneType,
                    priority: .high
                ))
            }
            if prevZone.status.redness.numericScore > zone.status.redness.numericScore {
                insights.append(Insight(
                    title: "\(zone.zoneType.displayName) redness calming",
                    body: CleraCopy.InsightEngine.rednessImproved,
                    type: .improvement,
                    zone: zone.zoneType,
                    priority: .medium
                ))
            }
        }
        return insights
    }

    // MARK: - Regression Insights

    private static func regressionInsights(from sessions: [ScanSession]) -> [Insight] {
        guard sessions.count >= 2 else { return [] }
        let sorted = sessions.sorted(by: { $0.createdAt < $1.createdAt })
        guard let latest = sorted.last, let previous = sorted.dropLast().last else { return [] }

        var insights: [Insight] = []
        for zone in latest.skinMap.zones {
            guard let prevZone = previous.skinMap.zones.first(where: { $0.zoneType == zone.zoneType }) else { continue }

            if prevZone.status.breakouts.numericScore < zone.status.breakouts.numericScore {
                insights.append(Insight(
                    title: "\(zone.zoneType.displayName) breakouts increased",
                    body: CleraCopy.InsightEngine.breakoutsIncreased(from: prevZone.status.breakouts.displayName.lowercased(), to: zone.status.breakouts.displayName.lowercased()),
                    type: .regression,
                    zone: zone.zoneType,
                    priority: .high
                ))
            }
        }
        return insights
    }

    // MARK: - Experiment Insights

    private static func experimentInsights(from experiments: [Experiment], sessions: [ScanSession]) -> [Insight] {
        var insights: [Insight] = []

        for experiment in experiments where experiment.isActive {
            let days = Calendar.current.dateComponents([.day], from: experiment.startDate, to: .now).day ?? 0
            if days > 0 && days % 7 == 0 {
                insights.append(Insight(
                    title: "\(experiment.name) — week \(days / 7) check",
                    body: CleraCopy.InsightEngine.experimentWeekCheck(days: days, zone: experiment.zone.displayName),
                    type: .correlation,
                    zone: experiment.zone,
                    priority: .medium
                ))
            }
        }

        for experiment in experiments where !experiment.isActive {
            guard let result = experiment.result else { continue }
            let outcomeText = result.outcome == .improvement ? "showed improvement" : result.outcome == .worsened ? "did not help" : "had no clear effect"
            insights.append(Insight(
                title: "\(experiment.name) completed",
                body: CleraCopy.InsightEngine.experimentCompleted(name: experiment.name, outcome: outcomeText, notes: result.notes ?? ""),
                type: .correlation,
                zone: experiment.zone,
                priority: .high
            ))
        }

        return insights
    }

    // MARK: - Routine Insights

    private static func routineInsights(from logs: [RoutineLogEntry], sessions: [ScanSession]) -> [Insight] {
        guard logs.count >= 3, sessions.count >= 2 else { return [] }

        let sortedLogs = logs.sorted(by: { $0.date < $1.date })
        let recentLogs = Array(sortedLogs.suffix(7))
        let adherence = Double(recentLogs.filter(\.followedRoutine).count) / Double(max(recentLogs.count, 1))

        var insights: [Insight] = []
        if adherence < 0.5 && recentLogs.count >= 3 {
            insights.append(Insight(
                title: "Routine adherence is low",
                body: CleraCopy.InsightEngine.routineAdherenceLow(pct: Int(adherence * 100)),
                type: .habit,
                zone: nil,
                priority: .medium
            ))
        } else if adherence >= 0.9 && recentLogs.count >= 5 {
            insights.append(Insight(
                title: "Great routine consistency",
                body: CleraCopy.InsightEngine.routineAdherenceHigh,
                type: .habit,
                zone: nil,
                priority: .low
            ))
        }

        return insights
    }

    // MARK: - Experiment Suggestions

    private static func suggestionInsights(from sessions: [ScanSession], experiments: [Experiment]) -> [Insight] {
        guard let latestSession = sessions.sorted(by: { $0.createdAt > $1.createdAt }).first else { return [] }

        // Find zones with recurring issues that don't have active experiments
        let activeZones = Set(experiments.filter(\.isActive).map(\.zone))
        var insights: [Insight] = []

        for zone in latestSession.skinMap.zones {
            guard !activeZones.contains(zone.zoneType),
                  zone.status.breakouts == .moderate || zone.status.breakouts == .high || zone.status.redness == .moderate || zone.status.redness == .high else { continue }

            let issue = zone.status.breakouts == .moderate || zone.status.breakouts == .high ? "breakouts" : "redness"
            insights.append(Insight(
                title: "Try an experiment for \(zone.zoneType.displayName)",
                body: CleraCopy.InsightEngine.suggestExperiment(zone: zone.zoneType.displayName, issue: issue),
                type: .environment,
                zone: zone.zoneType,
                priority: .high
            ))
        }

        return insights
    }

}
