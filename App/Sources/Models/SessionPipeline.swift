import Foundation

/// Unified skin session processing pipeline.
///
/// Orchestrates all engines in a deterministic, explainable flow:
/// 1. Pre-flight scan quality validation
/// 2. Determine baseline vs. follow-up
/// 3. Run engines with graceful fallbacks
/// 4. Compute confidence with failure adjustments
/// 5. Collect user-facing messages
/// 6. Log analytics events
///
/// The UI consumes only the returned `SkinSessionResult`.
enum SessionPipeline {
    
    // MARK: - Main Entry Point
    
    static func process(
        scanSession: ScanSession,
        checkIn: SkinMapCheckIn?,
        currentProducts: [Product],
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        allSessions: [ScanSession],
        skinMapHistory: [SkinMap],
        experiments: [Experiment],
        skinBaseline: SkinBaseline? = nil,
        scanFailures: [SessionFailure] = []
    ) -> SkinSessionResult {
        
        let logger = AnalyticsLogger.shared
        logger.log(.scanStarted, metadata: [
            "session_type": scanSession.kind.rawValue,
            "has_check_in": checkIn != nil ? "true" : "false"
        ])
        
        // 1. Pre-flight quality validation
        let qualityValidation = validateScanQuality(scanSession.skinMap.scanQuality)
        var resolvedScanFailures = resolveScanFailures(scanFailures, qualityValidation: qualityValidation)
        
        // Determine scan status
        let hasBlockingFailure = resolvedScanFailures.contains { !$0.canContinue }
        let scanStatus: ScanStatus
        if hasBlockingFailure {
            scanStatus = .rejected
            logger.log(.scanRejected, metadata: [
                "reason": resolvedScanFailures.first { !$0.canContinue }?.failureCode.rawValue ?? "unknown"
            ])
        } else if !qualityValidation.isValid {
            scanStatus = .savedLowConfidence
            logger.log(.scanSavedLowConfidence, metadata: [
                "quality_score": String(format: "%.2f", qualityValidation.score)
            ])
        } else {
            scanStatus = .accepted
        }
        
        // 2. Determine if baseline
        let previousSessions = allSessions.filter { $0.id != scanSession.id }
        let isBaseline = previousSessions.isEmpty || scanSession.kind == .baseline
        if isBaseline {
            logger.log(.baselineCreated, metadata: [
                "is_first_scan": previousSessions.isEmpty ? "true" : "false"
            ])
        }
        
        // 3. Build user messages
        var userMessages: [String] = []
        if isBaseline {
            userMessages.append(CleraCopy.Pipeline.baselineWelcome)
        }
        if scanStatus == .savedLowConfidence {
            userMessages.append(CleraCopy.Pipeline.lowQualitySaved)
        }
        
        // 4. Enrich skin map
        var enrichedSkinMap = scanSession.skinMap
        enrichedSkinMap.checkIn = checkIn
        if skinMapHistory.count >= 2 {
            ChangeDetectionEngine.updateTrends(on: &enrichedSkinMap, using: skinMapHistory)
        }
        
        // 5. Run change detection (skip if baseline with no prior)
        let changes: ChangeDetectionResult
        if isBaseline {
            changes = ChangeDetectionResult(generatedAt: .now, mode: .latestPair, zoneChanges: [])
            resolvedScanFailures.append(SessionFailure(
                failureCode: .noPreviousSession,
                userMessage: CleraCopy.Pipeline.noPreviousSession,
                recommendedAction: CleraCopy.Pipeline.noPreviousSessionAction,
                canContinue: true,
                confidenceImpact: 0.3
            ))
        } else {
            changes = ChangeDetectionEngine.compareLatestPair(from: skinMapHistory)
        }
        
        // 6. Check for missing check-in
        if checkIn == nil {
            resolvedScanFailures.append(SessionFailure(
                failureCode: .missingCheckIn,
                userMessage: CleraCopy.Pipeline.missingCheckIn,
                recommendedAction: CleraCopy.Pipeline.missingCheckInAction,
                canContinue: true,
                confidenceImpact: 0.1
            ))
        }
        
        // 7. Check for no routine
        if currentProducts.isEmpty {
            resolvedScanFailures.append(SessionFailure(
                failureCode: .noRoutine,
                userMessage: CleraCopy.Pipeline.noRoutine,
                recommendedAction: CleraCopy.Pipeline.noRoutineAction,
                canContinue: true,
                confidenceImpact: 0.15
            ))
        }
        
        // 8. Check for inconsistent history
        if detectInconsistentHistory(sessions: allSessions) {
            resolvedScanFailures.append(SessionFailure(
                failureCode: .inconsistentHistory,
                userMessage: CleraCopy.Pipeline.inconsistentHistory,
                recommendedAction: CleraCopy.Pipeline.inconsistentHistoryAction,
                canContinue: true,
                confidenceImpact: 0.15
            ))
        }
        
        // 9. Run product intelligence
        let productIntel = ProductIntelligenceEngine.generateReport(
            products: currentProducts,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            sessions: allSessions
        )
        
        // 10. Run weekly insight
        let weeklyInsight = WeeklyInsightEngine.generate(
            from: allSessions,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            currentProducts: currentProducts,
            productIntelligence: productIntel
        )
        
        // 11. Generate daily plan with fallback
        let (dailyPlan, planEvents) = generateDailyPlanWithFallback(
            period: DailyCopilotEngine.currentPeriod(),
            currentProducts: currentProducts,
            enrichedSkinMap: enrichedSkinMap,
            weeklyInsight: weeklyInsight,
            productIntel: productIntel,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            checkIn: checkIn,
            isBaseline: isBaseline,
            logger: logger
        )
        
        // 12. Check for uncertain copilot
        var dailyPlanEvents = planEvents
        if dailyPlan.confidenceLevel == .low {
            resolvedScanFailures.append(SessionFailure(
                failureCode: .uncertainCopilot,
                userMessage: CleraCopy.Pipeline.uncertainPlan,
                recommendedAction: CleraCopy.Pipeline.uncertainPlanAction,
                canContinue: true,
                confidenceImpact: 0.2
            ))
            userMessages.append(CleraCopy.Pipeline.uncertainPlanMessage)
            dailyPlanEvents.append(.fallbackPlanGenerated)
            logger.log(.fallbackPlanGenerated, metadata: [
                "reason": "low_confidence",
                "plan_focus": dailyPlan.focus
            ])
        } else {
            dailyPlanEvents.append(.dailyPlanGenerated)
            logger.log(.dailyPlanGenerated, metadata: [
                "focus": dailyPlan.focus,
                "steps": String(dailyPlan.recommendedSteps.count)
            ])
        }
        
        // 13. Compute confidence
        let confidence = computeConfidence(
            qualityValidation: qualityValidation,
            changes: changes,
            productIntel: productIntel,
            weeklyInsight: weeklyInsight,
            dailyPlan: dailyPlan,
            skinMap: enrichedSkinMap,
            failures: resolvedScanFailures
        )
        
        let confidenceSummary = ConfidenceSummary(
            overall: confidence.overall,
            scanQuality: confidence.scanQuality,
            skinMap: confidence.skinMap,
            changeDetection: confidence.changeDetection,
            productIntelligence: confidence.productIntelligence,
            dailyPlan: confidence.dailyPlan,
            adjustedForFailures: !resolvedScanFailures.isEmpty
        )
        
        // 14. Timeline enrichment
        let scanConsistency = ScanConsistencyEngine.analyze(
            scan: scanSession,
            baseline: skinBaseline,
            recentScans: Array(previousSessions.suffix(5)),
            scanQuality: scanSession.skinMap.scanQuality
        )
        
        let whatChanged = WhatChangedEngine.generate(
            from: changes,
            consistency: scanConsistency,
            checkIn: checkIn,
            isBaseline: isBaseline
        )
        
        let dataDensity = DataDensity(scanCount: allSessions.count + 1)
        
        // Phase 2: Intelligence & Attribution
        let routineImpacts = RoutineImpactAttribution.analyze(
            sessions: allSessions,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            currentProducts: currentProducts
        )

        let environmentalSignals = EnvironmentalContextEngine.analyze(
            sessions: allSessions
        )

        let patterns = SkinPatternRecognition.analyze(
            sessions: allSessions,
            routineLogs: routineLogs,
            routineChanges: routineChanges
        )

        let markers = generateTimelineMarkers(
            from: routineLogs,
            routineChanges: routineChanges,
            checkIn: checkIn,
            sessionDate: scanSession.createdAt
        )

        let timelineEnrichment = TimelineEnrichment(
            scanConsistency: scanConsistency,
            whatChanged: whatChanged,
            markers: markers,
            environmentalSignals: environmentalSignals,
            routineImpacts: routineImpacts,
            visualDifference: nil,
            patterns: patterns,
            dataDensity: dataDensity
        )
        
        // 15. Build failure state if any unrecoverable issue
        let failureState: FailureState? = {
            guard let primary = resolvedScanFailures.first(where: { !$0.canContinue }) else { return nil }
            return FailureState(
                code: primary.failureCode,
                userMessage: primary.userMessage,
                recommendedAction: primary.recommendedAction,
                canContinue: primary.canContinue,
                confidenceImpact: primary.confidenceImpact
            )
        }()
        
        // 16. Collect all analytics events
        var allEvents: [AnalyticsEvent] = [.scanStarted]
        if scanStatus == .rejected { allEvents.append(.scanRejected) }
        if scanStatus == .savedLowConfidence { allEvents.append(.scanSavedLowConfidence) }
        if isBaseline { allEvents.append(.baselineCreated) }
        allEvents.append(contentsOf: dailyPlanEvents)
        allEvents.append(.skinSessionCompleted)
        
        logger.log(.skinSessionCompleted, metadata: [
            "scan_status": scanStatus.rawValue,
            "is_baseline": isBaseline ? "true" : "false",
            "confidence": String(format: "%.2f", confidence.overall),
            "failure_count": String(resolvedScanFailures.count),
            "consistency_score": String(scanConsistency.score)
        ])
        
        return SkinSessionResult(
            sessionId: scanSession.id,
            createdAt: scanSession.createdAt,
            scanStatus: scanStatus,
            isBaseline: isBaseline,
            failureState: failureState,
            skinMap: enrichedSkinMap,
            zoneChanges: changes.zoneChanges,
            dailyPlan: dailyPlan,
            confidenceSummary: confidenceSummary,
            userMessages: userMessages,
            analyticsEvents: allEvents,
            checkIn: checkIn,
            weeklyInsight: weeklyInsight,
            timelineEnrichment: timelineEnrichment
        )
    }
    
    // MARK: - Daily Plan Generation with Fallback
    
    private static func generateDailyPlanWithFallback(
        period: PlanPeriod,
        currentProducts: [Product],
        enrichedSkinMap: SkinMap,
        weeklyInsight: WeeklyInsight?,
        productIntel: ProductIntelligenceReport,
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        checkIn: SkinMapCheckIn?,
        isBaseline: Bool,
        logger: AnalyticsLogger
    ) -> (DailyPlan, [AnalyticsEvent]) {
        
        // If no products, generate a gentle starter plan
        if currentProducts.isEmpty {
            let starterPlan = DailyPlan(
                generatedAt: .now,
                period: period,
                focus: CleraCopy.Pipeline.starterPlanFocus,
                recommendedSteps: [
                    PlanStep(order: 0, category: .cleanser, productID: nil, productName: CleraCopy.Pipeline.starterCleanserName, instruction: CleraCopy.Pipeline.starterCleanserInstruction, isOptional: false),
                    PlanStep(order: 1, category: .moisturizer, productID: nil, productName: CleraCopy.Pipeline.starterMoisturizerName, instruction: CleraCopy.Pipeline.starterMoisturizerInstruction, isOptional: false),
                    PlanStep(order: 2, category: .sunscreen, productID: nil, productName: CleraCopy.Pipeline.starterSPFName, instruction: period == .morning ? CleraCopy.Pipeline.starterSPFInstruction : nil, isOptional: false)
                ].filter { $0.instruction != nil || $0.productName != nil },
                avoidSteps: [CleraCopy.Pipeline.starterAvoid],
                reasoning: [
                    CleraCopy.Pipeline.starterReasoningNoProducts,
                    CleraCopy.Pipeline.starterReasoningSimple,
                    CleraCopy.Pipeline.starterReasoningAddProducts
                ],
                confidenceLevel: .low
            )
            return (starterPlan, [.fallbackPlanGenerated])
        }
        
        let plan = DailyCopilotEngine.generatePlan(
            for: period,
            currentSkinMap: enrichedSkinMap,
            weeklyInsight: weeklyInsight,
            productIntelligence: productIntel,
            products: currentProducts,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            latestCheckIn: checkIn
        )
        
        return (plan, [])
    }
    
    // MARK: - Scan Quality Validation
    
    private static func validateScanQuality(_ quality: ScanQualityMetadata?) -> ScanQualityValidation {
        guard let quality = quality else {
            return ScanQualityValidation(
                isValid: true,
                issues: [CleraCopy.Pipeline.qualityNoMetadata],
                score: 0.5
            )
        }
        
        var issues: [String] = []
        var score = 1.0
        
        let readiness = quality.scanReadiness.lowercased()
        if readiness.contains("poor") || readiness.contains("notready") {
            issues.append(CleraCopy.Pipeline.qualityBelowIdeal)
            score -= 0.3
        }
        
        if quality.overexposed {
            issues.append(CleraCopy.Pipeline.qualityOverexposed)
            score -= 0.15
        }
        
        if quality.shadowDetected {
            issues.append(CleraCopy.Pipeline.qualityShadow)
            score -= 0.1
        }
        
        if quality.blurScore < 0.1 {
            issues.append(CleraCopy.Pipeline.qualityBlurry)
            score -= 0.15
        }
        
        if quality.sharpnessScore < 0.1 {
            issues.append(CleraCopy.Pipeline.qualityLowSharpness)
            score -= 0.1
        }
        
        let isValid = score >= 0.6
        if issues.isEmpty {
            issues.append(CleraCopy.Pipeline.qualityLooksGood)
        }
        
        return ScanQualityValidation(
            isValid: isValid,
            issues: issues,
            score: max(score, 0)
        )
    }
    
    // MARK: - Scan Failure Resolution
    
    private static func resolveScanFailures(
        _ scanFailures: [SessionFailure],
        qualityValidation: ScanQualityValidation
    ) -> [SessionFailure] {
        var resolved = scanFailures
        
        if !qualityValidation.isValid && !scanFailures.contains(where: { $0.failureCode == .scanConfidenceLow }) {
            resolved.append(SessionFailure(
                failureCode: .scanConfidenceLow,
                userMessage: CleraCopy.ScanFailure.scanConfidenceLowMessage,
                recommendedAction: CleraCopy.ScanFailure.scanConfidenceLowAction,
                canContinue: true,
                confidenceImpact: 0.25
            ))
        }
        
        return resolved
    }
    
    // MARK: - History Consistency Check
    
    private static func detectInconsistentHistory(sessions: [ScanSession]) -> Bool {
        guard sessions.count >= 3 else { return false }
        let sorted = sessions.sorted(by: { $0.createdAt < $1.createdAt })
        var gaps: [TimeInterval] = []
        for i in 1..<sorted.count {
            gaps.append(sorted[i].createdAt.timeIntervalSince(sorted[i-1].createdAt))
        }
        let avgGap = gaps.reduce(0, +) / Double(gaps.count)
        let maxGap = gaps.max() ?? 0
        return avgGap > 0 && maxGap > avgGap * 3
    }
    
    // MARK: - Confidence Computation
    
    private static func computeConfidence(
        qualityValidation: ScanQualityValidation,
        changes: ChangeDetectionResult,
        productIntel: ProductIntelligenceReport,
        weeklyInsight: WeeklyInsight?,
        dailyPlan: DailyPlan,
        skinMap: SkinMap,
        failures: [SessionFailure]
    ) -> SessionConfidence {
        var scanQualityScore = qualityValidation.score
        
        let skinMapScore: Double = {
            let hasCheckIn = skinMap.checkIn != nil
            let hasQuality = skinMap.scanQuality != nil
            var score = 0.7
            if hasCheckIn { score += 0.15 }
            if hasQuality { score += 0.1 }
            return min(score, 0.95)
        }()
        
        let changeDetectionScore: Double = {
            let avgConfidence = changes.zoneChanges.map(\.confidence).reduce(0, +) / Double(max(changes.zoneChanges.count, 1))
            return avgConfidence
        }()
        
        let productIntelScore: Double = {
            switch productIntel.confidenceLevel {
            case .high: return 0.9
            case .moderate: return 0.7
            case .low: return 0.5
            }
        }()
        
        let weeklyInsightScore: Double = {
            guard let insight = weeklyInsight else { return 0.4 }
            switch insight.confidenceLevel {
            case .high: return 0.85
            case .moderate: return 0.65
            case .low: return 0.45
            }
        }()
        
        let dailyPlanScore: Double = {
            switch dailyPlan.confidenceLevel {
            case .high: return 0.9
            case .moderate: return 0.7
            case .low: return 0.5
            }
        }()
        
        // Apply failure confidence impacts
        let totalImpact = failures.map(\.confidenceImpact).reduce(0, +)
        let impactFactor = max(1.0 - totalImpact, 0.3)
        
        scanQualityScore *= impactFactor
        let adjustedSkinMapScore = skinMapScore * impactFactor
        let adjustedChangeScore = changeDetectionScore * impactFactor
        let adjustedProductScore = productIntelScore * impactFactor
        let adjustedWeeklyScore = weeklyInsightScore * impactFactor
        let adjustedDailyScore = dailyPlanScore * impactFactor
        
        let weights: [Double] = [0.15, 0.15, 0.20, 0.15, 0.15, 0.20]
        let scores = [scanQualityScore, adjustedSkinMapScore, adjustedChangeScore, adjustedProductScore, adjustedWeeklyScore, adjustedDailyScore]
        let overall = zip(scores, weights).map(*).reduce(0, +)
        
        return SessionConfidence(
            scanQuality: scanQualityScore,
            skinMap: adjustedSkinMapScore,
            changeDetection: adjustedChangeScore,
            productIntelligence: adjustedProductScore,
            dailyPlan: adjustedDailyScore,
            overall: overall
        )
    }

    // MARK: - Timeline Markers

    /// Generates timeline markers from routine logs, changes, and check-in data
    /// that occurred near the scan session date.
    private static func generateTimelineMarkers(
        from routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        checkIn: SkinMapCheckIn?,
        sessionDate: Date
    ) -> [TimelineMarker] {
        var markers: [TimelineMarker] = []
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .day, value: -2, to: sessionDate) ?? sessionDate

        // Routine logs within 2 days of scan
        for log in routineLogs where log.date >= windowStart && log.date <= sessionDate {
            let type: TimelineMarker.MarkerType = {
                let hour = calendar.component(.hour, from: log.date)
                return log.followedRoutine ? (hour < 12 ? .amRoutine : .pmRoutine) : .missedRoutine
            }()
            markers.append(TimelineMarker(
                date: log.date,
                type: type,
                label: type.displayName,
                relatedZones: nil,
                icon: type.systemImage
            ))
        }

        // Routine changes within 2 days of scan
        for change in routineChanges where change.date >= windowStart && change.date <= sessionDate {
            let type: TimelineMarker.MarkerType = {
                switch change.changeType {
                case .added: return .newProduct
                case .removed: return .productStopped
                case .switched: return .routineChange
                }
            }()
            markers.append(TimelineMarker(
                date: change.date,
                type: type,
                label: change.notes ?? type.displayName,
                relatedZones: nil,
                icon: type.systemImage
            ))
        }

        // Check-in symptoms as markers
        if let checkIn = checkIn {
            if checkIn.hadIrritation {
                markers.append(TimelineMarker(
                    date: sessionDate,
                    type: .irritationNoted,
                    label: TimelineMarker.MarkerType.irritationNoted.displayName,
                    relatedZones: nil,
                    icon: TimelineMarker.MarkerType.irritationNoted.systemImage
                ))
            }
            if checkIn.hadDryness {
                markers.append(TimelineMarker(
                    date: sessionDate,
                    type: .drynessNoted,
                    label: TimelineMarker.MarkerType.drynessNoted.displayName,
                    relatedZones: nil,
                    icon: TimelineMarker.MarkerType.drynessNoted.systemImage
                ))
            }
            if checkIn.hadBreakouts {
                markers.append(TimelineMarker(
                    date: sessionDate,
                    type: .breakoutNoted,
                    label: TimelineMarker.MarkerType.breakoutNoted.displayName,
                    relatedZones: nil,
                    icon: TimelineMarker.MarkerType.breakoutNoted.systemImage
                ))
            }
            if checkIn.newProducts {
                markers.append(TimelineMarker(
                    date: sessionDate,
                    type: .newProduct,
                    label: "New product noted",
                    relatedZones: nil,
                    icon: TimelineMarker.MarkerType.newProduct.systemImage
                ))
            }
        }

        return markers.sorted(by: { $0.date < $1.date })
    }
}
