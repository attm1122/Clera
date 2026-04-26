import Foundation

/// Rule-based weekly insight engine.
/// Analyzes the last 7 days of scans, skin maps, routine adherence,
/// product changes, and reported changes to generate non-clinical insights.
enum WeeklyInsightEngine {
    
    static func generate(
        from sessions: [ScanSession],
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        currentProducts: [Product],
        productIntelligence: ProductIntelligenceReport? = nil
    ) -> WeeklyInsight? {
        guard sessions.count >= 1 else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let weekSessions = sessions.filter { $0.createdAt >= weekAgo }.sorted(by: { $0.createdAt < $1.createdAt })
        let weekMaps = weekSessions.map(\.skinMap)
        guard let firstMap = weekMaps.first, let latestMap = weekMaps.last else { return nil }
        
        // Zone analysis
        let zoneHighlights = analyzeZones(first: firstMap, latest: latestMap)
        
        // Routine adherence
        let weekLogs = routineLogs.filter { $0.date >= weekAgo }
        let adherence = calculateAdherence(logs: weekLogs)
        
        // Product changes
        let recentChanges = routineChanges.filter { $0.date >= weekAgo }
        let activeActives = currentProducts.filter { $0.isActive && ($0.category == .serum || $0.category == .treatment) }.count
        
        // Check-in analysis
        let checkIns = weekMaps.compactMap(\.checkIn)
        let issueCounts = countReportedIssues(checkIns: checkIns)
        
        // Scan quality
        let qualityIssues = weekMaps.compactMap(\.scanQuality).filter { quality in
            let readiness = quality.scanReadiness.lowercased()
            return readiness.contains("poor") || readiness.contains("notready")
        }
        
        // Build contributors
        var contributors: [Contributor] = []
        contributors.append(contentsOf: routineContributors(adherence: adherence, logs: weekLogs, zoneTrends: zoneHighlights))
        contributors.append(contentsOf: productContributors(changes: recentChanges, actives: activeActives, issueCounts: issueCounts, intelligence: productIntelligence))
        contributors.append(contentsOf: scanQualityContributors(qualityIssues: qualityIssues, totalScans: weekSessions.count))
        contributors.append(contentsOf: habitContributors(issueCounts: issueCounts, checkIns: checkIns))
        
        // Determine overall direction
        let improvingCount = zoneHighlights.filter { $0.trend == .improving }.count
        let worseningCount = zoneHighlights.filter { $0.trend == .worsening }.count
        let overallTrend: ZoneTrend = {
            if worseningCount > improvingCount { return .worsening }
            if improvingCount > worseningCount { return .improving }
            return .stable
        }()
        
        // Confidence
        let confidence = computeConfidence(weekScans: weekSessions.count, qualityIssues: qualityIssues.count, adherence: adherence)
        
        // Summary
        let (title, text) = buildSummary(
            overallTrend: overallTrend,
            improvingCount: improvingCount,
            worseningCount: worseningCount,
            zoneHighlights: zoneHighlights,
            adherence: adherence,
            scanCount: weekSessions.count
        )
        
        let nextStep = buildNextStep(
            overallTrend: overallTrend,
            contributors: contributors,
            zoneHighlights: zoneHighlights,
            adherence: adherence,
            activeActives: activeActives
        )
        
        return WeeklyInsight(
            generatedAt: now,
            weekEnding: now,
            summaryTitle: title,
            summaryText: text,
            zoneHighlights: zoneHighlights,
            possibleContributors: contributors,
            recommendedNextStep: nextStep,
            confidenceLevel: confidence,
            safetyDisclaimer: CleraCopy.WeeklyInsight.disclaimer
        )
    }
    
    // MARK: - Zone Analysis
    
    private static func analyzeZones(first: SkinMap, latest: SkinMap) -> [ZoneHighlight] {
        var highlights: [ZoneHighlight] = []
        
        for zone in latest.zones {
            guard let firstZone = first.zones.first(where: { $0.zoneType == zone.zoneType }) else { continue }
            
            let metrics: [(String, ZoneSeverity, ZoneSeverity)] = [
                ("Breakouts", firstZone.status.breakouts, zone.status.breakouts),
                ("Redness", firstZone.status.redness, zone.status.redness),
                ("Dryness", firstZone.status.dryness, zone.status.dryness),
                ("Texture", firstZone.status.texture, zone.status.texture),
                ("Congestion", firstZone.status.congestion, zone.status.congestion),
                ("Irritation", firstZone.status.irritation, zone.status.irritation)
            ]
            
            let changes = metrics.map { (label, first, latest) -> (label: String, delta: Int) in
                (label, latest.numericScore - first.numericScore)
            }
            
            let improving = changes.filter { $0.delta < 0 }
            let worsening = changes.filter { $0.delta > 0 }
            
            let trend: ZoneTrend
            let primaryMetric: String
            let description: String
            
            if !improving.isEmpty && worsening.isEmpty {
                trend = .improving
                let top = improving.min { abs($0.delta) < abs($1.delta) } ?? improving[0]
                primaryMetric = top.label
                description = CleraCopy.WeeklyInsight.improvingDescription
            } else if !worsening.isEmpty && improving.isEmpty {
                trend = .worsening
                let top = worsening.max { $0.delta < $1.delta } ?? worsening[0]
                primaryMetric = top.label
                description = CleraCopy.WeeklyInsight.worseningDescription
            } else if !improving.isEmpty && !worsening.isEmpty {
                trend = .stable
                primaryMetric = "Mixed"
                description = CleraCopy.WeeklyInsight.mixedDescription
            } else {
                trend = .stable
                let worstMetric = metrics.max { $0.1.numericScore < $1.1.numericScore } ?? metrics[0]
                primaryMetric = worstMetric.0
                description = worstMetric.2.numericScore == 0
                    ? CleraCopy.WeeklyInsight.lookingClear
                    : CleraCopy.WeeklyInsight.noSignificantChange
            }
            
            highlights.append(ZoneHighlight(
                zone: zone.zoneType,
                trend: trend,
                primaryMetric: primaryMetric,
                description: description
            ))
        }
        
        return highlights.sorted {
            let order: [ZoneTrend] = [.worsening, .improving, .stable, .unknown]
            guard let idx0 = order.firstIndex(of: $0.trend), let idx1 = order.firstIndex(of: $1.trend) else { return false }
            return idx0 < idx1
        }
    }
    
    // MARK: - Routine Analysis
    
    private static func calculateAdherence(logs: [RoutineLogEntry]) -> Double {
        let expected = 14.0 // 2x per day
        guard !logs.isEmpty else { return 0 }
        let followed = Double(logs.filter(\.followedRoutine).count)
        return min(followed / expected, 1.0)
    }
    
    private static func routineContributors(
        adherence: Double,
        logs: [RoutineLogEntry],
        zoneTrends: [ZoneHighlight]
    ) -> [Contributor] {
        var contributors: [Contributor] = []
        let hasWorsening = zoneTrends.contains(where: { $0.trend == .worsening })
        
        if adherence < 0.4 && logs.count >= 3 {
            contributors.append(Contributor(
                type: .routine,
                description: CleraCopy.WeeklyInsight.contributorRoutineLow(Int(adherence * 100)),
                confidence: .moderate
            ))
        } else if adherence >= 0.85 && logs.count >= 5 && !hasWorsening {
            contributors.append(Contributor(
                type: .routine,
                description: CleraCopy.WeeklyInsight.contributorRoutineHigh,
                confidence: .high
            ))
        }
        
        return contributors
    }
    
    // MARK: - Product Analysis
    
    private static func productContributors(
        changes: [RoutineChangeLogEntry],
        actives: Int,
        issueCounts: IssueCounts,
        intelligence: ProductIntelligenceReport?
    ) -> [Contributor] {
        var contributors: [Contributor] = []
        
        // New product warnings
        let newProducts = changes.filter { $0.changeType == .added }
        if !newProducts.isEmpty {
            let hadIssues = issueCounts.irritation > 0 || issueCounts.breakouts > 0
            contributors.append(Contributor(
                type: .product,
                description: hadIssues
                    ? CleraCopy.WeeklyInsight.contributorNewProductWithIssues
                    : CleraCopy.WeeklyInsight.contributorNewProductWatch,
                confidence: hadIssues ? .moderate : .low
            ))
        }
        
        // Overuse of actives
        if actives > 2 {
            contributors.append(Contributor(
                type: .product,
                description: CleraCopy.WeeklyInsight.contributorTooManyActives(actives),
                confidence: .moderate
            ))
        }
        
        // Incorporate product intelligence risks
        if let intelligence = intelligence {
            for risk in intelligence.risks where risk.severity != .info {
                contributors.append(Contributor(
                    type: .product,
                    description: risk.description,
                    confidence: risk.severity == .warning ? .moderate : .low
                ))
            }
        }
        
        return contributors
    }
    
    // MARK: - Scan Quality
    
    private static func scanQualityContributors(qualityIssues: [ScanQualityMetadata], totalScans: Int) -> [Contributor] {
        guard !qualityIssues.isEmpty else { return [] }
        return [Contributor(
            type: .scanQuality,
            description: totalScans == qualityIssues.count
                ? CleraCopy.WeeklyInsight.contributorAllScansLowQuality
                : CleraCopy.WeeklyInsight.contributorSomeScansLowQuality(count: qualityIssues.count, total: totalScans),
            confidence: .low
        )]
    }
    
    // MARK: - Habit / Check-in Analysis
    
    private static func habitContributors(issueCounts: IssueCounts, checkIns: [SkinMapCheckIn]) -> [Contributor] {
        var contributors: [Contributor] = []
        
        if issueCounts.irritation >= 2 {
            contributors.append(Contributor(
                type: .habit,
                description: CleraCopy.WeeklyInsight.contributorIrritation(issueCounts.irritation),
                confidence: .moderate
            ))
        }
        
        if issueCounts.dryness >= 2 {
            contributors.append(Contributor(
                type: .habit,
                description: CleraCopy.WeeklyInsight.contributorDryness(issueCounts.dryness),
                confidence: .moderate
            ))
        }
        
        if issueCounts.breakouts >= 2 {
            contributors.append(Contributor(
                type: .habit,
                description: CleraCopy.WeeklyInsight.contributorBreakouts(issueCounts.breakouts),
                confidence: .moderate
            ))
        }
        
        if issueCounts.newProducts && issueCounts.irritation + issueCounts.breakouts > 0 {
            contributors.append(Contributor(
                type: .product,
                description: CleraCopy.WeeklyInsight.contributorNewProductLinked,
                confidence: .low
            ))
        }
        
        return contributors
    }
    
    // MARK: - Summary Building
    
    private static func buildSummary(
        overallTrend: ZoneTrend,
        improvingCount: Int,
        worseningCount: Int,
        zoneHighlights: [ZoneHighlight],
        adherence: Double,
        scanCount: Int
    ) -> (title: String, text: String) {
        let title: String
        let text: String
        
        switch overallTrend {
        case .improving:
            title = CleraCopy.WeeklyInsight.titleImproving
            let zones = zoneHighlights.filter { $0.trend == .improving }.prefix(2).map { $0.zone.displayName }.joined(separator: " and ")
            text = CleraCopy.WeeklyInsight.improvingBody(zones: zones, scanCount: scanCount)
        case .worsening:
            title = CleraCopy.WeeklyInsight.titleWorsening
            let zones = zoneHighlights.filter { $0.trend == .worsening }.prefix(2).map { $0.zone.displayName }.joined(separator: " and ")
            text = CleraCopy.WeeklyInsight.worseningBody(zones: zones)
        case .stable:
            title = CleraCopy.WeeklyInsight.titleStable
            let activeZones = zoneHighlights.filter { $0.primaryMetric != "Mixed" && $0.description != CleraCopy.WeeklyInsight.lookingClear }
            if activeZones.isEmpty {
                text = CleraCopy.WeeklyInsight.stableBodyCalm
            } else {
                text = CleraCopy.WeeklyInsight.stableBodyMixed
            }
        case .unknown:
            title = CleraCopy.WeeklyInsight.titleNoData
            text = CleraCopy.WeeklyInsight.noDataBody
        }
        
        return (title, text)
    }
    
    // MARK: - Next Step
    
    private static func buildNextStep(
        overallTrend: ZoneTrend,
        contributors: [Contributor],
        zoneHighlights: [ZoneHighlight],
        adherence: Double,
        activeActives: Int
    ) -> String {
        // Priority order for next steps
        if adherence < 0.4 {
            return CleraCopy.WeeklyInsight.nextStepConsistency
        }
        
        if contributors.contains(where: { $0.type == .product && $0.description.contains("actives") }) {
            return CleraCopy.WeeklyInsight.nextStepSimplify
        }
        
        if let worsening = zoneHighlights.first(where: { $0.trend == .worsening }) {
            return CleraCopy.WeeklyInsight.nextStepWatchZone(worsening.zone.displayName)
        }
        
        if contributors.contains(where: { $0.type == .product && $0.confidence == .moderate }) {
            return CleraCopy.WeeklyInsight.nextStepMonitorProduct
        }
        
        if overallTrend == .improving {
            return CleraCopy.WeeklyInsight.nextStepKeepStable
        }
        
        if overallTrend == .stable {
            return CleraCopy.WeeklyInsight.nextStepKeepScanning
        }
        
        return CleraCopy.WeeklyInsight.nextStepBuildPicture
    }
    
    // MARK: - Confidence
    
    private static func computeConfidence(weekScans: Int, qualityIssues: Int, adherence: Double) -> InsightConfidence {
        if weekScans < 2 { return .low }
        if qualityIssues > 0 { return .low }
        if weekScans >= 5 && adherence >= 0.5 { return .high }
        if weekScans >= 3 { return .moderate }
        return .low
    }
    
    // MARK: - Helpers
    
    private struct IssueCounts {
        var irritation = 0
        var dryness = 0
        var breakouts = 0
        var newProducts = false
    }
    
    private static func countReportedIssues(checkIns: [SkinMapCheckIn]) -> IssueCounts {
        var counts = IssueCounts()
        for checkIn in checkIns {
            if checkIn.hadIrritation { counts.irritation += 1 }
            if checkIn.hadDryness { counts.dryness += 1 }
            if checkIn.hadBreakouts { counts.breakouts += 1 }
            if checkIn.newProducts { counts.newProducts = true }
        }
        return counts
    }
    
}
