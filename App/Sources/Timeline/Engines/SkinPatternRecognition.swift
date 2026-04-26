import Foundation

/// Detects personal skin patterns after enough scan history.
/// Unlocks progressively: 3 scans → basic, 5 → trends, 8 → routine insights, 15 → personal patterns.
enum SkinPatternRecognition {

    static let thresholds = [3, 5, 8, 15]

    /// Analyzes all sessions and returns unlocked pattern insights.
    static func analyze(
        sessions: [ScanSession],
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry]
    ) -> [PatternInsight] {
        let scanCount = sessions.count
        guard scanCount >= 3 else { return [] }

        var patterns: [PatternInsight] = []
        let sortedSessions = sessions.sorted(by: { $0.createdAt < $1.createdAt })

        // Pattern 1: Routine consistency → skin stability (unlocks at 8 scans)
        if scanCount >= 8 {
            if let pattern = detectRoutineStabilityPattern(sessions: sortedSessions, routineLogs: routineLogs) {
                patterns.append(pattern)
            }
        }

        // Pattern 2: Zone reactivity (unlocks at 5 scans)
        if scanCount >= 5 {
            if let pattern = detectZoneReactivityPattern(sessions: sortedSessions) {
                patterns.append(pattern)
            }
        }

        // Pattern 3: Product lag time (unlocks at 8 scans)
        if scanCount >= 8 {
            if let pattern = detectProductLagPattern(sessions: sortedSessions, routineChanges: routineChanges) {
                patterns.append(pattern)
            }
        }

        // Pattern 4: Scan consistency pattern (unlocks at 5 scans)
        if scanCount >= 5 {
            if let pattern = detectScanConsistencyPattern(sessions: sortedSessions) {
                patterns.append(pattern)
            }
        }

        // Pattern 5: Most stable period (unlocks at 15 scans)
        if scanCount >= 15 {
            if let pattern = detectMostStablePeriod(sessions: sortedSessions, routineLogs: routineLogs) {
                patterns.append(pattern)
            }
        }

        return patterns
    }

    // MARK: - Pattern Detectors

    private static func detectRoutineStabilityPattern(
        sessions: [ScanSession],
        routineLogs: [RoutineLogEntry]
    ) -> PatternInsight? {
        guard routineLogs.count >= 7 else { return nil }

        let calendar = Calendar.current
        let logsByWeek = Dictionary(grouping: routineLogs) { log in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: log.date)
        }

        var highAdherenceWeeks: [Date] = []
        var lowAdherenceWeeks: [Date] = []

        for (_, weekLogs) in logsByWeek {
            let adherence = Double(weekLogs.filter(\.followedRoutine).count) / Double(max(weekLogs.count, 1))
            let dates = weekLogs.map(\.date)
            if let midDate = dates.sorted().dropFirst(dates.count / 2).first {
                if adherence >= 0.85 { highAdherenceWeeks.append(midDate) }
                else if adherence < 0.4 { lowAdherenceWeeks.append(midDate) }
            }
        }

        // Compare skin stability in high vs low adherence weeks
        let highAdherenceStable = highAdherenceWeeks.contains { weekDate in
            let weekSessions = sessions.filter {
                calendar.isDate($0.createdAt, equalTo: weekDate, toGranularity: .weekOfYear)
            }
            return weekSessions.count >= 1 && weekSessions.allSatisfy { session in
                session.skinMap.zones.allSatisfy { zone in
                    zone.status.breakoutsTrend != .worsening && zone.status.rednessTrend != .worsening
                }
            }
        }

        if highAdherenceStable && !highAdherenceWeeks.isEmpty {
            return PatternInsight(
                title: "Routine consistency link",
                body: CleraCopy.Patterns.routineConsistencyStability,
                patternType: .routineConsistency,
                unlockThreshold: 8,
                isUnlocked: true,
                discoveredAt: Date(),
                relatedZones: ZoneType.allCases
            )
        }

        return nil
    }

    private static func detectZoneReactivityPattern(
        sessions: [ScanSession]
    ) -> PatternInsight? {
        guard sessions.count >= 5 else { return nil }

        var zoneChangeCounts: [ZoneType: Int] = [:]

        for i in 1..<sessions.count {
            let prev = sessions[i-1]
            let curr = sessions[i]
            for zone in curr.skinMap.zones {
                guard let prevZone = prev.skinMap.zones.first(where: { $0.zoneType == zone.zoneType }) else { continue }
                if zone.status.breakouts != prevZone.status.breakouts
                    || zone.status.redness != prevZone.status.redness {
                    zoneChangeCounts[zone.zoneType, default: 0] += 1
                }
            }
        }

        guard let mostReactive = zoneChangeCounts.max(by: { $0.value < $1.value }) else { return nil }
        guard mostReactive.value >= 3 else { return nil }

        return PatternInsight(
            title: "\(mostReactive.key.displayName) reactivity",
            body: CleraCopy.Patterns.zoneReactivity(zone: mostReactive.key.displayName),
            patternType: .zoneReactivity,
            unlockThreshold: 5,
            isUnlocked: true,
            discoveredAt: Date(),
            relatedZones: [mostReactive.key]
        )
    }

    private static func detectProductLagPattern(
        sessions: [ScanSession],
        routineChanges: [RoutineChangeLogEntry]
    ) -> PatternInsight? {
        let newProducts = routineChanges.filter { $0.changeType == .added }
        guard newProducts.count >= 1, sessions.count >= 5 else { return nil }

        // Check if changes appear 2-3 days after product introductions
        var lagDetections = 0

        for change in newProducts {
            let changeDate = change.date
            let subsequentSessions = sessions.filter { $0.createdAt > changeDate }
                .sorted(by: { $0.createdAt < $1.createdAt })

            guard subsequentSessions.count >= 2 else { continue }

            let daysToFirstChange = Calendar.current.dateComponents(
                [.day], from: changeDate, to: subsequentSessions[1].createdAt
            ).day ?? 0

            if daysToFirstChange >= 2 && daysToFirstChange <= 5 {
                let hadChanges = subsequentSessions[1].skinMap.zones.contains { zone in
                    zone.status.breakouts != .none || zone.status.redness != .none
                }
                if hadChanges { lagDetections += 1 }
            }
        }

        if lagDetections >= 1 {
            return PatternInsight(
                title: "Product response timing",
                body: CleraCopy.Patterns.productLagTime,
                patternType: .productLag,
                unlockThreshold: 8,
                isUnlocked: true,
                discoveredAt: Date(),
                relatedZones: ZoneType.allCases
            )
        }

        return nil
    }

    private static func detectScanConsistencyPattern(
        sessions: [ScanSession]
    ) -> PatternInsight? {
        // Check if scans at similar times of day show more consistent results
        let calendar = Calendar.current
        let morningScans = sessions.filter { calendar.component(.hour, from: $0.createdAt) < 12 }
        let eveningScans = sessions.filter { calendar.component(.hour, from: $0.createdAt) >= 12 }

        guard morningScans.count >= 2 || eveningScans.count >= 2 else { return nil }

        // Simple check: if user has more scans in one period, suggest consistency
        let dominantPeriod = morningScans.count > eveningScans.count ? "morning" : "evening"

        return PatternInsight(
            title: "Scan timing pattern",
            body: CleraCopy.Patterns.scanTiming(period: dominantPeriod),
            patternType: .scanConsistency,
            unlockThreshold: 5,
            isUnlocked: true,
            discoveredAt: Date(),
            relatedZones: ZoneType.allCases
        )
    }

    private static func detectMostStablePeriod(
        sessions: [ScanSession],
        routineLogs: [RoutineLogEntry]
    ) -> PatternInsight? {
        guard sessions.count >= 10 else { return nil }

        // Find the 2-week period with the fewest skin changes
        let calendar = Calendar.current
        let sorted = sessions.sorted(by: { $0.createdAt < $1.createdAt })

        var bestPeriod: (start: Date, end: Date, changeCount: Int)?

        for i in 0..<sorted.count {
            guard let twoWeeksLater = calendar.date(byAdding: .day, value: 14, to: sorted[i].createdAt) else { continue }
            let periodSessions = sorted.filter { $0.createdAt >= sorted[i].createdAt && $0.createdAt <= twoWeeksLater }
            guard periodSessions.count >= 2 else { continue }

            var changes = 0
            for j in 1..<periodSessions.count {
                for zone in periodSessions[j].skinMap.zones {
                    guard let prevZone = periodSessions[j-1].skinMap.zones.first(where: { $0.zoneType == zone.zoneType }) else { continue }
                    if zone.status.breakouts != prevZone.status.breakouts { changes += 1 }
                }
            }

            if let currentBest = bestPeriod {
                if changes < currentBest.changeCount {
                    bestPeriod = (sorted[i].createdAt, twoWeeksLater, changes)
                }
            } else {
                bestPeriod = (sorted[i].createdAt, twoWeeksLater, changes)
            }
        }

        guard let period = bestPeriod, period.changeCount <= 2 else { return nil }

        return PatternInsight(
            title: "Most stable period",
            body: CleraCopy.Patterns.mostStablePeriod,
            patternType: .routineConsistency,
            unlockThreshold: 15,
            isUnlocked: true,
            discoveredAt: Date(),
            relatedZones: ZoneType.allCases
        )
    }
}
