import Foundation

/// Generates contextual, data-driven nudges based on scan history, skin changes, and routine behaviour.
/// Never uses shame, fear, or generic reminder language.
enum SmartNudgeEngine {

    /// Generates relevant nudges for the current app state.
    static func generate(
        sessions: [ScanSession],
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        currentProducts: [Product],
        lastAppOpen: Date?
    ) -> [Nudge] {
        var nudges: [Nudge] = []
        let now = Date()

        // 1. Follow-up scan nudge (if last scan showed changes)
        if let followUp = followUpScanNudge(sessions: sessions, now: now) {
            nudges.append(followUp)
        }

        // 2. Routine consistency nudge
        if let routine = routineConsistencyNudge(routineLogs: routineLogs, now: now) {
            nudges.append(routine)
        }

        // 3. Timeline progress nudge
        if let progress = timelineProgressNudge(sessions: sessions) {
            nudges.append(progress)
        }

        // 4. Experiment check nudge
        if let experiment = experimentCheckNudge(sessions: sessions, now: now) {
            nudges.append(experiment)
        }

        // 5. Product monitor nudge
        if let product = productMonitorNudge(routineChanges: routineChanges, sessions: sessions, now: now) {
            nudges.append(product)
        }

        // 6. Scan gap nudge (gentle, not shaming)
        if let gap = scanGapNudge(sessions: sessions, now: now) {
            nudges.append(gap)
        }

        // Sort by priority, remove expired, limit to 3
        return nudges
            .filter { $0.expiresAt == nil || $0.expiresAt! > now }
            .sorted { priorityRank($0.priority) > priorityRank($1.priority) }
            .prefix(3)
            .map { $0 }
    }

    // MARK: - Nudge Generators

    private static func followUpScanNudge(
        sessions: [ScanSession],
        now: Date
    ) -> Nudge? {
        guard let latest = sessions.sorted(by: { $0.createdAt > $1.createdAt }).first else { return nil }
        let daysSinceScan = Calendar.current.dateComponents([.day], from: latest.createdAt, to: now).day ?? 0
        guard daysSinceScan >= 2, daysSinceScan <= 5 else { return nil }

        // Check if last scan showed changes
        let hadChanges = latest.skinMap.zones.contains { zone in
            zone.status.breakoutsTrend == .worsening || zone.status.rednessTrend == .worsening
        }
        guard hadChanges else { return nil }

        return Nudge(
            title: "Follow-up scan",
            body: CleraCopy.Nudges.followUpScan,
            type: .followUpScan,
            priority: .high,
            createdAt: now,
            expiresAt: Calendar.current.date(byAdding: .day, value: 3, to: now),
            actionLabel: CleraCopy.Timeline.nudgeActionScan,
            actionRoute: "scan"
        )
    }

    private static func routineConsistencyNudge(
        routineLogs: [RoutineLogEntry],
        now: Date
    ) -> Nudge? {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let recentLogs = routineLogs.filter { $0.date >= weekAgo }
        guard recentLogs.count >= 3 else { return nil }

        let adherence = Double(recentLogs.filter(\.followedRoutine).count) / Double(recentLogs.count)

        if adherence >= 0.85 {
            return Nudge(
                title: "Great routine consistency",
                body: CleraCopy.Nudges.routineConsistencyGreat,
                type: .routineConsistency,
                priority: .low,
                createdAt: now,
                expiresAt: Calendar.current.date(byAdding: .day, value: 2, to: now),
                actionLabel: CleraCopy.Timeline.nudgeActionScan,
                actionRoute: "scan"
            )
        } else if adherence < 0.4 {
            return Nudge(
                title: "Routine check-in",
                body: CleraCopy.Nudges.routineConsistencyLow,
                type: .routineConsistency,
                priority: .medium,
                createdAt: now,
                expiresAt: Calendar.current.date(byAdding: .day, value: 2, to: now),
                actionLabel: CleraCopy.Timeline.nudgeActionRoutine,
                actionRoute: "routine"
            )
        }

        return nil
    }

    private static func timelineProgressNudge(
        sessions: [ScanSession]
    ) -> Nudge? {
        let count = sessions.count
        let thresholds = [3, 5, 8, 15]

        // Only nudge right after crossing a threshold
        guard thresholds.contains(count) else { return nil }

        let message: String
        switch count {
        case 3: message = CleraCopy.Nudges.timelineForming
        case 5: message = CleraCopy.Nudges.timelineTrends
        case 8: message = CleraCopy.Nudges.timelinePatterns
        case 15: message = CleraCopy.Nudges.timelinePersonal
        default: return nil
        }

        return Nudge(
            title: "Timeline progress",
            body: message,
            type: .timelineProgress,
            priority: .low,
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            actionLabel: CleraCopy.Timeline.viewTimeline,
            actionRoute: "timeline"
        )
    }

    private static func experimentCheckNudge(
        sessions: [ScanSession],
        now: Date
    ) -> Nudge? {
        // This would check active experiments; simplified for now
        return nil
    }

    private static func productMonitorNudge(
        routineChanges: [RoutineChangeLogEntry],
        sessions: [ScanSession],
        now: Date
    ) -> Nudge? {
        let recentChanges = routineChanges.filter {
            Calendar.current.dateComponents([.day], from: $0.date, to: now).day ?? 7 <= 7
        }
        guard !recentChanges.isEmpty else { return nil }

        return Nudge(
            title: "New product check-in",
            body: CleraCopy.Nudges.productMonitor,
            type: .productMonitor,
            priority: .medium,
            createdAt: now,
            expiresAt: Calendar.current.date(byAdding: .day, value: 5, to: now),
            actionLabel: CleraCopy.Timeline.nudgeActionScan,
            actionRoute: "scan"
        )
    }

    private static func scanGapNudge(
        sessions: [ScanSession],
        now: Date
    ) -> Nudge? {
        guard let latest = sessions.sorted(by: { $0.createdAt > $1.createdAt }).first else { return nil }
        let daysSince = Calendar.current.dateComponents([.day], from: latest.createdAt, to: now).day ?? 0

        // Only nudge after 4+ days, not before
        guard daysSince >= 4 else { return nil }

        // Cap at 14 days to avoid nagging
        guard daysSince <= 14 else { return nil }

        let message = daysSince >= 7
            ? CleraCopy.Nudges.scanGapLong
            : CleraCopy.Nudges.scanGapShort

        return Nudge(
            title: "Update your timeline",
            body: message,
            type: .followUpScan,
            priority: .medium,
            createdAt: now,
            expiresAt: Calendar.current.date(byAdding: .day, value: 2, to: now),
            actionLabel: CleraCopy.Timeline.nudgeActionScan,
            actionRoute: "scan"
        )
    }

    // MARK: - Helpers

    private static func priorityRank(_ priority: Nudge.NudgePriority) -> Int {
        switch priority {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}
