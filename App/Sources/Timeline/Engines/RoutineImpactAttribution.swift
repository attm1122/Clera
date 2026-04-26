import Foundation

/// Cautious correlation heuristics between routine events and skin changes.
/// Never claims causation. Uses "may be linked", "could contribute", "worth monitoring" only.
enum RoutineImpactAttribution {

    /// Minimum data required before showing any attribution.
    static let minimumScans = 5
    static let minimumRoutineLogs = 7

    /// Analyzes routine logs and skin changes to suggest possible links.
    static func analyze(
        sessions: [ScanSession],
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        currentProducts: [Product]
    ) -> [RoutineImpact] {

        guard sessions.count >= minimumScans,
              routineLogs.count >= minimumRoutineLogs else {
            return []
        }

        var impacts: [RoutineImpact] = []

        // 1. Routine consistency vs skin stability
        impacts.append(contentsOf: consistencyVsStability(sessions: sessions, routineLogs: routineLogs))

        // 2. New product + skin reaction
        impacts.append(contentsOf: newProductReactions(
            sessions: sessions,
            routineChanges: routineChanges,
            routineLogs: routineLogs,
            currentProducts: currentProducts
        ))

        // 3. Too many actives + irritation/dryness
        impacts.append(contentsOf: activesOverload(
            sessions: sessions,
            currentProducts: currentProducts,
            routineLogs: routineLogs
        ))

        // 4. Routine gaps + skin changes
        impacts.append(contentsOf: routineGapImpact(sessions: sessions, routineLogs: routineLogs))

        return impacts.prefix(3).map { $0 }
    }

    // MARK: - Heuristic 1: Consistency vs Stability

    private static func consistencyVsStability(
        sessions: [ScanSession],
        routineLogs: [RoutineLogEntry]
    ) -> [RoutineImpact] {
        let sortedSessions = sessions.sorted(by: { $0.createdAt < $1.createdAt })
        guard sortedSessions.count >= 4 else { return [] }

        // Split into high-adherence and low-adherence periods
        let calendar = Calendar.current
        var highAdherencePeriods: [(start: Date, end: Date)] = []
        var lowAdherencePeriods: [(start: Date, end: Date)] = []

        let logsByWeek = Dictionary(grouping: routineLogs) { log in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: log.date)
        }

        for (_, weekLogs) in logsByWeek {
            let adherence = Double(weekLogs.filter(\.followedRoutine).count) / Double(max(weekLogs.count, 1))
            if adherence >= 0.85 && weekLogs.count >= 4 {
                let dates = weekLogs.map(\.date)
                if let start = dates.min(), let end = dates.max() {
                    highAdherencePeriods.append((start, end))
                }
            } else if adherence < 0.4 && weekLogs.count >= 3 {
                let dates = weekLogs.map(\.date)
                if let start = dates.min(), let end = dates.max() {
                    lowAdherencePeriods.append((start, end))
                }
            }
        }

        var impacts: [RoutineImpact] = []

        // Check if skin was more stable during high adherence
        for (start, end) in highAdherencePeriods {
            let periodSessions = sortedSessions.filter { $0.createdAt >= start && $0.createdAt <= end }
            guard periodSessions.count >= 2 else { continue }

            let hasImprovement = periodSessions.enumerated().contains { index, session in
                guard index > 0 else { return false }
                return session.skinMap.zones.contains { zone in
                    zone.status.breakoutsTrend == .improving || zone.status.rednessTrend == .improving
                }
            }

            if hasImprovement {
                impacts.append(RoutineImpact(
                    routineEvent: "Consistent routine",
                    skinChange: "Improved stability",
                    timeGapDays: 0,
                    confidence: .moderate,
                    message: CleraCopy.RoutineImpact.consistencyImprovement,
                    isCautionary: true
                ))
            }
        }

        // Check if skin worsened during low adherence
        for (start, end) in lowAdherencePeriods {
            let periodSessions = sortedSessions.filter { $0.createdAt >= start && $0.createdAt <= end }
            guard periodSessions.count >= 2 else { continue }

            let hasWorsening = periodSessions.enumerated().contains { index, session in
                guard index > 0 else { return false }
                return session.skinMap.zones.contains { zone in
                    zone.status.breakoutsTrend == .worsening || zone.status.rednessTrend == .worsening
                }
            }

            if hasWorsening {
                impacts.append(RoutineImpact(
                    routineEvent: "Inconsistent routine",
                    skinChange: "Increased changes",
                    timeGapDays: 0,
                    confidence: .low,
                    message: CleraCopy.RoutineImpact.inconsistencyWorsening,
                    isCautionary: true
                ))
            }
        }

        return impacts
    }

    // MARK: - Heuristic 2: New Product Reactions

    private static func newProductReactions(
        sessions: [ScanSession],
        routineChanges: [RoutineChangeLogEntry],
        routineLogs: [RoutineLogEntry],
        currentProducts: [Product]
    ) -> [RoutineImpact] {
        let newProducts = routineChanges.filter { $0.changeType == .added }
        guard !newProducts.isEmpty else { return [] }

        var impacts: [RoutineImpact] = []
        let sortedSessions = sessions.sorted(by: { $0.createdAt > $1.createdAt })

        for change in newProducts {
            let changeDate = change.date
            let subsequentSessions = sortedSessions.filter { $0.createdAt > changeDate }
            guard let firstAfter = subsequentSessions.first else { continue }

            let daysAfter = Calendar.current.dateComponents([.day], from: changeDate, to: firstAfter.createdAt).day ?? 0

            // Check for irritation or breakouts in sessions after product addition
            let hadIssues = subsequentSessions.prefix(3).contains { session in
                session.skinMap.zones.contains { zone in
                    zone.status.irritation == .moderate || zone.status.irritation == .high
                    || zone.status.breakouts == .moderate || zone.status.breakouts == .high
                }
            }

            let productName = currentProducts.first(where: { $0.id == change.productId })?.name ?? "a new product"

            if hadIssues {
                impacts.append(RoutineImpact(
                    routineEvent: "Started \(productName)",
                    skinChange: "Visible reaction noted",
                    timeGapDays: daysAfter,
                    confidence: .low,
                    message: CleraCopy.RoutineImpact.newProductReaction(product: productName),
                    isCautionary: true
                ))
            }
        }

        return impacts
    }

    // MARK: - Heuristic 3: Actives Overload

    private static func activesOverload(
        sessions: [ScanSession],
        currentProducts: [Product],
        routineLogs: [RoutineLogEntry]
    ) -> [RoutineImpact] {
        let activeCount = currentProducts.filter {
            $0.isActive && ($0.category == .serum || $0.category == .treatment)
        }.count

        guard activeCount > 2 else { return [] }

        let recentSessions = sessions.suffix(3)
        let hadDryness = recentSessions.contains { session in
            session.skinMap.zones.contains { $0.status.dryness == .moderate || $0.status.dryness == .high }
        }
        let hadIrritation = recentSessions.contains { session in
            session.skinMap.zones.contains { $0.status.irritation == .moderate || $0.status.irritation == .high }
        }

        if hadDryness || hadIrritation {
            return [RoutineImpact(
                routineEvent: "\(activeCount) active ingredients in routine",
                skinChange: hadDryness ? "Visible dryness" : "Irritation noted",
                timeGapDays: 0,
                confidence: .low,
                message: CleraCopy.RoutineImpact.tooManyActives(count: activeCount),
                isCautionary: true
            )]
        }

        return []
    }

    // MARK: - Heuristic 4: Routine Gap Impact

    private static func routineGapImpact(
        sessions: [ScanSession],
        routineLogs: [RoutineLogEntry]
    ) -> [RoutineImpact] {
        let sortedLogs = routineLogs.sorted(by: { $0.date < $1.date })
        guard sortedLogs.count >= 2 else { return [] }

        var maxGap: Int = 0
        var gapEnd: Date?

        for i in 1..<sortedLogs.count {
            let gap = Calendar.current.dateComponents([.day], from: sortedLogs[i-1].date, to: sortedLogs[i].date).day ?? 0
            if gap > maxGap {
                maxGap = gap
                gapEnd = sortedLogs[i].date
            }
        }

        guard maxGap >= 3, let gapEndDate = gapEnd else { return [] }

        // Check if skin changed after the gap
        let postGapSessions = sessions.filter { $0.createdAt > gapEndDate }
        guard let firstPostGap = postGapSessions.first else { return [] }

        let hadChanges = firstPostGap.skinMap.zones.contains { zone in
            zone.status.breakoutsTrend == .worsening || zone.status.rednessTrend == .worsening
        }

        if hadChanges {
            return [RoutineImpact(
                routineEvent: "\(maxGap)-day routine gap",
                skinChange: "Visible changes after resuming",
                timeGapDays: maxGap,
                confidence: .low,
                message: CleraCopy.RoutineImpact.routineGap(days: maxGap),
                isCautionary: true
            )]
        }

        return []
    }
}
