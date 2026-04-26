import Foundation

// MARK: - Session Recorder

/// Encapsulates the complex logic of recording a scan session,
/// running the pipeline, and creating backward-compatible legacy objects.
enum SessionRecorder {

    static func record(
        kind: ScanType,
        photos: [ScanPhoto],
        skinMap: SkinMap,
        note: String,
        checkIn: SkinMapCheckIn?,
        scanQuality: ScanQualityMetadata?,
        currentProducts: [Product],
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        experiments: [Experiment],
        skinBaseline: SkinBaseline?,
        existingResults: [SkinSessionResult],
        existingSessions: [SkinSession],
        existingProductIntel: [ProductIntelligenceReport]
    ) -> (session: ScanSession, result: SkinSessionResult, legacySession: SkinSession, updatedMapHistory: [SkinMap]) {

        var map = skinMap
        map.checkIn = checkIn
        map.scanQuality = scanQuality

        let session = ScanSession(kind: kind, photos: photos, skinMap: map, note: note)

        var updatedMapHistory = existingResults.map(\.skinMap) + [map]

        // Compute and apply trend changes
        if updatedMapHistory.count >= 2 {
            var latestMap = updatedMapHistory[updatedMapHistory.count - 1]
            ChangeDetectionEngine.updateTrends(on: &latestMap, using: updatedMapHistory)
            updatedMapHistory[updatedMapHistory.count - 1] = latestMap
            map = latestMap
        }

        let allSessions = existingResults.map { ScanSession(kind: $0.isBaseline ? .baseline : .daily, createdAt: $0.createdAt, photos: [], skinMap: $0.skinMap, note: nil) } + [session]

        // Run unified pipeline
        let result = SessionPipeline.process(
            scanSession: session,
            checkIn: checkIn,
            currentProducts: currentProducts,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            allSessions: allSessions,
            skinMapHistory: updatedMapHistory,
            experiments: experiments,
            skinBaseline: skinBaseline
        )

        // Legacy SkinSession for backward compatibility
        let qualityScore = result.skinMap.scanQuality?.scanReadiness.lowercased().contains("poor") == true ? 0.5 : 0.85
        let productIntel = existingProductIntel.last ?? ProductIntelligenceEngine.generateReport(
            products: currentProducts,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            sessions: allSessions
        )

        let legacySession = SkinSession(
            createdAt: result.createdAt,
            scan: session,
            checkIn: checkIn,
            skinMap: result.skinMap,
            changes: ChangeDetectionResult(generatedAt: .now, mode: .latestPair, zoneChanges: result.zoneChanges),
            productIntelligence: productIntel,
            dailyPlan: result.dailyPlan,
            weeklyInsight: result.weeklyInsight,
            confidence: SessionConfidence(
                scanQuality: result.confidenceSummary.scanQuality,
                skinMap: result.confidenceSummary.skinMap,
                changeDetection: result.confidenceSummary.changeDetection,
                productIntelligence: result.confidenceSummary.productIntelligence,
                dailyPlan: result.confidenceSummary.dailyPlan,
                overall: result.confidenceSummary.overall
            ),
            qualityValidation: ScanQualityValidation(
                isValid: result.scanStatus != ScanStatus.savedLowConfidence && result.scanStatus != ScanStatus.rejected,
                issues: result.userMessages,
                score: qualityScore
            ),
            failures: result.failureState.map {
                [SessionFailure(
                    failureCode: $0.code,
                    userMessage: $0.userMessage,
                    recommendedAction: $0.recommendedAction,
                    canContinue: $0.canContinue,
                    confidenceImpact: $0.confidenceImpact
                )]
            } ?? []
        )

        return (session, result, legacySession, updatedMapHistory)
    }
}

// MARK: - Report Generator

/// Encapsulates all insight, report, and plan generation logic.
enum ReportGenerator {

    static func generateInsights(
        sessions: [ScanSession],
        routineLogs: [RoutineLogEntry],
        experiments: [Experiment],
        existingInsights: [Insight]
    ) -> [Insight] {
        InsightEngine.generateInsights(
            from: sessions,
            routineLogs: routineLogs,
            experiments: experiments,
            existingInsights: existingInsights
        )
    }

    static func generateProductIntelligence(
        products: [Product],
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        sessions: [ScanSession]
    ) -> ProductIntelligenceReport {
        ProductIntelligenceEngine.generateReport(
            products: products,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            sessions: sessions
        )
    }

    static func generateWeeklyInsight(
        sessions: [ScanSession],
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        currentProducts: [Product],
        productIntelligence: ProductIntelligenceReport
    ) -> WeeklyInsight? {
        WeeklyInsightEngine.generate(
            from: sessions,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            currentProducts: currentProducts,
            productIntelligence: productIntelligence
        )
    }

    static func generateNudges(
        sessions: [ScanSession],
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        currentProducts: [Product],
        existingNudges: [Nudge]
    ) -> [Nudge] {
        let fresh = SmartNudgeEngine.generate(
            sessions: sessions,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            currentProducts: currentProducts,
            lastAppOpen: nil
        )
        // Merge with existing, preserving dismissed state
        var merged = existingNudges.filter(\.isDismissed)
        for nudge in fresh {
            if !existingNudges.contains(where: { $0.id == nudge.id && $0.isDismissed }) {
                merged.append(nudge)
            }
        }
        return merged
    }
}
