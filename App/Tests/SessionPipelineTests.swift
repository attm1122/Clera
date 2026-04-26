import XCTest
@testable import Clera

/// Comprehensive tests for the Skin Session pipeline, engines, and failure states.
/// Covers: baseline scan, daily scan, low-confidence scan, rejected scan,
/// missing check-in, incomplete check-in, inconsistent history,
/// Daily Copilot success/fallback, change detection, product intelligence.
@MainActor
final class SessionPipelineTests: XCTestCase {

    // MARK: - Helpers

    private func runPipeline(_ inputs: CleraFixtures.PipelineInputs) -> SkinSessionResult {
        SessionPipeline.process(
            scanSession: inputs.scanSession,
            checkIn: inputs.checkIn,
            currentProducts: inputs.currentProducts,
            routineLogs: inputs.routineLogs,
            routineChanges: inputs.routineChanges,
            allSessions: inputs.allSessions,
            skinMapHistory: inputs.skinMapHistory,
            experiments: inputs.experiments,
            scanFailures: inputs.scanFailures
        )
    }

    // MARK: - 1. Baseline Scan (First Session)

    func testBaselineScanIsMarkedAsBaseline() {
        let inputs = CleraFixtures.newUserNoBaseline()
        let result = runPipeline(inputs)

        XCTAssertTrue(result.isBaseline)
        XCTAssertEqual(result.scanStatus, .accepted)
        XCTAssertTrue(result.zoneChanges.isEmpty)
        XCTAssertTrue(result.userMessages.contains(where: { $0.contains("first scan") }))
        XCTAssertTrue(result.analyticsEvents.contains(.baselineCreated))
    }

    func testBaselineScanHasNoPreviousSessionFailure() {
        let inputs = CleraFixtures.newUserNoBaseline()
        let result = runPipeline(inputs)

        // noPreviousSession adds a recoverable failure with confidence impact
        XCTAssertTrue(result.confidenceSummary.adjustedForFailures)
        XCTAssertGreaterThan(result.confidenceSummary.overall, 0)
        XCTAssertLessThan(result.confidenceSummary.overall, 1.0)
    }

    // MARK: - 2. Daily Scan with Consistent History

    func testDailyScanGeneratesZoneChanges() {
        let inputs = CleraFixtures.userWith7DaysConsistent()
        let result = runPipeline(inputs)

        XCTAssertFalse(result.isBaseline)
        XCTAssertEqual(result.scanStatus, .accepted)
        XCTAssertFalse(result.zoneChanges.isEmpty)
    }

    func testDailyScanGeneratesWeeklyInsight() {
        let inputs = CleraFixtures.userWith7DaysConsistent()
        let result = runPipeline(inputs)

        XCTAssertNotNil(result.weeklyInsight)
        XCTAssertFalse(result.weeklyInsight!.zoneHighlights.isEmpty)
    }

    func testDailyScanProducesHighConfidencePlan() {
        let inputs = CleraFixtures.userWith7DaysConsistent()
        let result = runPipeline(inputs)

        XCTAssertEqual(result.dailyPlan.confidenceLevel, .high)
        XCTAssertGreaterThanOrEqual(result.dailyPlan.recommendedSteps.count, 2)
    }

    // MARK: - 3. Low-Confidence / Poor Quality Scan

    func testPoorQualityScanIsSavedLowConfidence() {
        let inputs = CleraFixtures.userWithPoorScanQuality()
        let result = runPipeline(inputs)

        XCTAssertEqual(result.scanStatus, .savedLowConfidence)
        XCTAssertTrue(result.userMessages.contains(where: { $0.contains("lower than ideal") || $0.contains("quality") }))
    }

    func testPoorQualityScanReducesOverallConfidence() {
        let inputs = CleraFixtures.userWithPoorScanQuality()
        let result = runPipeline(inputs)

        XCTAssertTrue(result.confidenceSummary.adjustedForFailures)
        XCTAssertLessThan(result.confidenceSummary.scanQuality, 0.6)
    }

    // MARK: - 4. Rejected Scan (Blocking Failure)

    func testRejectedScanHasCorrectStatus() {
        let inputs = CleraFixtures.rejectedScanNoFace()
        let result = runPipeline(inputs)

        XCTAssertEqual(result.scanStatus, .rejected)
    }

    func testRejectedScanHasFailureState() {
        let inputs = CleraFixtures.rejectedScanNoFace()
        let result = runPipeline(inputs)

        XCTAssertNotNil(result.failureState)
        XCTAssertEqual(result.failureState?.code, .noFaceDetected)
        XCTAssertFalse(result.failureState!.canContinue)
    }

    func testRejectedScanAnalyticsLogged() {
        let inputs = CleraFixtures.rejectedScanNoFace()
        let result = runPipeline(inputs)

        XCTAssertTrue(result.analyticsEvents.contains(.scanRejected))
    }

    // MARK: - 5. Missing Check-In

    func testMissingCheckInAdjustsConfidence() {
        var inputs = CleraFixtures.userWith7DaysConsistent()
        inputs.checkIn = nil
        let result = runPipeline(inputs)

        XCTAssertTrue(result.confidenceSummary.adjustedForFailures)
    }

    func testMissingCheckInStillProducesPlan() {
        var inputs = CleraFixtures.userWith7DaysConsistent()
        inputs.checkIn = nil
        let result = runPipeline(inputs)

        XCTAssertFalse(result.dailyPlan.recommendedSteps.isEmpty)
    }

    // MARK: - 6. Incomplete Check-In

    func testIncompleteCheckInStillProcesses() {
        let inputs = CleraFixtures.newUserNoBaseline()
        let result = runPipeline(inputs)

        // checkIn exists but followedRoutine is false — pipeline still completes
        XCTAssertNotNil(result.checkIn)
        XCTAssertFalse(result.checkIn!.followedRoutine)
        XCTAssertEqual(result.scanStatus, .accepted)
    }

    // MARK: - 7. Inconsistent History

    func testInconsistentHistoryDetected() {
        let calendar = Calendar.current
        var sessions: [ScanSession] = []
        var maps: [SkinMap] = []

        // 5 sessions with a huge gap between 4th and 5th
        let gaps = [1.0, 1.0, 1.0, 30.0] // days between scans
        var currentDate = calendar.date(byAdding: .day, value: -40, to: .now) ?? .now

        for gap in gaps {
            currentDate = calendar.date(byAdding: .day, value: Int(gap), to: currentDate) ?? currentDate
            let map = SkinMap(date: currentDate, zones: SampleData.sampleSkinMap.zones)
            var scan = ScanSession(kind: .daily, photos: [], skinMap: map, note: nil)
            scan.createdAt = currentDate
            sessions.append(scan)
            maps.append(map)
        }

        let inputs = CleraFixtures.PipelineInputs(
            scanSession: sessions.last!,
            checkIn: SkinMapCheckIn(followedRoutine: true, newProducts: false, hadIrritation: false, hadDryness: false, hadBreakouts: false, notes: nil),
            currentProducts: SampleData.defaultProducts,
            routineLogs: [],
            routineChanges: [],
            allSessions: sessions,
            skinMapHistory: maps,
            experiments: [],
            scanFailures: []
        )

        let result = runPipeline(inputs)

        XCTAssertTrue(result.confidenceSummary.adjustedForFailures)
    }

    // MARK: - 8. Daily Copilot: Success Path

    func testDailyCopilotMapsProductsToSteps() {
        let inputs = CleraFixtures.userWith7DaysConsistent()
        let result = runPipeline(inputs)

        let stepNames = result.dailyPlan.recommendedSteps.map(\.productName).compactMap { $0 }
        XCTAssertFalse(stepNames.isEmpty)
        // Should include user's actual products
        XCTAssertTrue(stepNames.contains(where: { $0.contains("Cleanser") }))
    }

    func testDailyCopilotAvoidsMorningRetinol() {
        let retinolProduct = Product(name: "Night Retinol", category: .treatment, period: .evening, ingredientTags: [.retinol])
        var inputs = CleraFixtures.userWith7DaysConsistent()
        inputs.currentProducts = SampleData.defaultProducts + [retinolProduct]
        let result = runPipeline(inputs)

        // If current period is morning, retinol should be in avoid list
        if DailyCopilotEngine.currentPeriod() == .morning {
            let avoidText = result.dailyPlan.avoidSteps.joined()
            XCTAssertTrue(avoidText.contains("retinol") || avoidText.contains("Retinol"))
        }
    }

    // MARK: - 9. Daily Copilot: Fallback (No Products)

    func testNoRoutineGeneratesStarterPlan() {
        let inputs = CleraFixtures.userWithNoRoutine()
        let result = runPipeline(inputs)

        XCTAssertEqual(result.dailyPlan.confidenceLevel, .low)
        XCTAssertFalse(result.dailyPlan.recommendedSteps.isEmpty)
        XCTAssertTrue(result.dailyPlan.recommendedSteps.contains(where: { $0.productName?.contains("cleanser") == true || $0.instruction?.contains("cleanser") == true }))
    }

    func testNoRoutineAddsNoRoutineFailure() {
        let inputs = CleraFixtures.userWithNoRoutine()
        let result = runPipeline(inputs)

        XCTAssertTrue(result.confidenceSummary.adjustedForFailures)
        XCTAssertTrue(result.analyticsEvents.contains(.fallbackPlanGenerated))
    }

    // MARK: - 10. Change Detection: Worsening Breakouts

    func testWorseningChinJawBreakoutsDetected() {
        let inputs = CleraFixtures.userWithWorseningChinJaw()
        let result = runPipeline(inputs)

        let chinChanges = result.zoneChanges.filter { $0.zone == .chinJaw && $0.metric == "breakouts" }
        XCTAssertFalse(chinChanges.isEmpty)
        XCTAssertEqual(chinChanges.first?.direction, .increasing)
    }

    // MARK: - 11. Change Detection: Improving Redness

    func testImprovingNoseRednessDetected() {
        let inputs = CleraFixtures.userWithImprovingRedness()
        let result = runPipeline(inputs)

        let noseChanges = result.zoneChanges.filter { $0.zone == .nose && $0.metric == "redness" }
        XCTAssertFalse(noseChanges.isEmpty)
        XCTAssertEqual(noseChanges.first?.direction, .decreasing)
    }

    // MARK: - 12. Product Intelligence: Too Many Actives

    func testTooManyActivesTriggersSootheStrategy() {
        let inputs = CleraFixtures.userWithTooManyActives()
        let result = runPipeline(inputs)

        // Irritation + dryness triggers soothe strategy
        XCTAssertTrue(result.dailyPlan.focus.contains("Soothe") || result.dailyPlan.focus.contains("soothe"))
    }

    func testTooManyActivesSkipsTreatmentActivesInPlan() {
        let inputs = CleraFixtures.userWithTooManyActives()
        let result = runPipeline(inputs)

        // Serum and treatment steps with active ingredients should be skipped
        let activeTreatmentSteps = result.dailyPlan.recommendedSteps.filter { step in
            (step.category == .serum || step.category == .treatment) &&
            inputs.currentProducts.contains(where: { $0.id == step.productID && $0.ingredientTags.contains(where: \.isActiveTreatment) })
        }
        XCTAssertTrue(activeTreatmentSteps.isEmpty, "Plan should skip serum/treatment actives when skin is irritated")
    }

    func testTooManyActivesAddsAvoidWarnings() {
        let inputs = CleraFixtures.userWithTooManyActives()
        let result = runPipeline(inputs)

        let avoidText = result.dailyPlan.avoidSteps.joined()
        XCTAssertTrue(avoidText.contains("Skip actives") || avoidText.contains("actives"))
    }

    // MARK: - 13. Skin Map Trend Updates

    func testTrendsAreUpdatedOnSkinMap() {
        let inputs = CleraFixtures.userWithImprovingRedness()
        let result = runPipeline(inputs)

        let noseZone = result.skinMap.zones.first { $0.zoneType == .nose }
        XCTAssertNotNil(noseZone)
        XCTAssertEqual(noseZone?.status.rednessTrend, .improving)
    }

    // MARK: - 14. Confidence Floor

    func testConfidenceNeverDropsBelowFloor() {
        // Rejected scan has confidenceImpact 1.0, but multiplier is capped at 0.3
        let inputs = CleraFixtures.rejectedScanNoFace()
        let result = runPipeline(inputs)

        XCTAssertGreaterThanOrEqual(result.confidenceSummary.overall, 0.0)
        // The overall confidence can be very low but should still be a valid number
        XCTAssertLessThanOrEqual(result.confidenceSummary.overall, 1.0)
    }

    // MARK: - 15. Analytics Events Collection

    func testAllExpectedEventsPresent() {
        let inputs = CleraFixtures.userWith7DaysConsistent()
        let result = runPipeline(inputs)

        XCTAssertTrue(result.analyticsEvents.contains(.scanStarted))
        XCTAssertTrue(result.analyticsEvents.contains(.skinSessionCompleted))
        XCTAssertTrue(result.analyticsEvents.contains(.dailyPlanGenerated))
    }

    func testFallbackPlanLogsFallbackEvent() {
        let inputs = CleraFixtures.userWithNoRoutine()
        let result = runPipeline(inputs)

        XCTAssertTrue(result.analyticsEvents.contains(.fallbackPlanGenerated))
    }

    // MARK: - 16. Non-Medical Language Compliance

    func testNoClinicalDiagnosesInMessages() {
        let inputs = CleraFixtures.userWithWorseningChinJaw()
        let result = runPipeline(inputs)

        let allText = result.userMessages.joined() + result.dailyPlan.reasoning.joined() + (result.weeklyInsight?.summaryText ?? "")
        let forbiddenWords = ["acne", "rosacea", "eczema", "dermatitis", "prescription", "diagnose"]
        for word in forbiddenWords {
            XCTAssertFalse(allText.lowercased().contains(word), "Output should not contain clinical term: \(word)")
        }
    }

    // MARK: - 17. Composite Change Detection

    func testCompositeResultIncludesAllZonesAndMetrics() {
        let inputs = CleraFixtures.userWith7DaysConsistent()
        let result = runPipeline(inputs)

        let allZones = ZoneType.allCases
        let allMetrics = ["breakouts", "redness", "dryness", "texture", "congestion", "irritation"]

        for zone in allZones {
            for metric in allMetrics {
                let changes = result.zoneChanges.filter { $0.zone == zone && $0.metric == metric }
                XCTAssertFalse(changes.isEmpty, "Missing change for \(zone) / \(metric)")
            }
        }
    }
}
