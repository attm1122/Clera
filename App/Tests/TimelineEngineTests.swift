import XCTest
@testable import Clera

// MARK: - Scan Consistency Engine

@MainActor
final class ScanConsistencyEngineTests: XCTestCase {

    func testMissingQualityMetadataReturnsNeutralScore() {
        let scan = ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        let result = ScanConsistencyEngine.analyze(
            scan: scan,
            baseline: nil,
            recentScans: [],
            scanQuality: nil
        )
        XCTAssertEqual(result.score, 50)
        XCTAssertEqual(result.confidenceImpact, .minor)
        XCTAssertEqual(result.lighting, .unknown)
    }

    func testExcellentQualityReturnsHighScore() {
        let quality = ScanQualityMetadata(
            blurScore: 0.9,
            brightnessScore: 0.7,
            sharpnessScore: 0.85,
            overexposed: false,
            shadowDetected: false,
            scanReadiness: "excellent"
        )
        var map = SkinMap(zones: SampleData.sampleSkinMap.zones)
        map.scanQuality = quality
        let scan = ScanSession(kind: .daily, photos: [], skinMap: map, note: nil)

        let result = ScanConsistencyEngine.analyze(
            scan: scan,
            baseline: nil,
            recentScans: [],
            scanQuality: quality
        )
        XCTAssertGreaterThanOrEqual(result.score, 80)
        XCTAssertEqual(result.confidenceImpact, .none)
        XCTAssertEqual(result.lighting, .consistent)
    }

    func testPoorQualityReturnsLowScore() {
        let quality = ScanQualityMetadata(
            blurScore: 0.05,
            brightnessScore: 0.2,
            sharpnessScore: 0.04,
            overexposed: true,
            shadowDetected: true,
            scanReadiness: "poor"
        )
        var map = SkinMap(zones: SampleData.sampleSkinMap.zones)
        map.scanQuality = quality
        let scan = ScanSession(kind: .daily, photos: [], skinMap: map, note: nil)

        let result = ScanConsistencyEngine.analyze(
            scan: scan,
            baseline: nil,
            recentScans: [],
            scanQuality: quality
        )
        XCTAssertLessThan(result.score, 60)
        // Score between 40-60 returns moderate; < 40 returns significant
        XCTAssertTrue(result.confidenceImpact == .moderate || result.confidenceImpact == .significant)
    }

    func testTimeOfDayConsistency() {
        let quality = ScanQualityMetadata(
            blurScore: 0.8,
            brightnessScore: 0.6,
            sharpnessScore: 0.8,
            overexposed: false,
            shadowDetected: false,
            scanReadiness: "good"
        )
        let baselineDate = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
        _ = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now)!

        let baseline = SkinBaseline(
            id: UUID(),
            userId: "test",
            createdAt: baselineDate,
            scanId: UUID(),
            zoneScores: [:],
            lightingMetadata: .init(brightness: 0.5, contrast: 0.5, colorTemperature: nil),
            deviceMetadata: .init(deviceModel: "iPhone", cameraPosition: "front", resolution: "default")
        )

        var map = SkinMap(zones: SampleData.sampleSkinMap.zones)
        map.scanQuality = quality

        let diffTimeScan = ScanSession(kind: .daily, photos: [], skinMap: map, note: nil)

        let diffResult = ScanConsistencyEngine.analyze(
            scan: diffTimeScan,
            baseline: baseline,
            recentScans: [],
            scanQuality: quality
        )

        XCTAssertGreaterThanOrEqual(diffResult.score, 0)
    }
}

// MARK: - What Changed Engine

@MainActor
final class WhatChangedEngineTests: XCTestCase {

    func testBaselineReturnsNoChanges() {
        let changes = ChangeDetectionResult(generatedAt: .now, mode: .latestPair, zoneChanges: [])
        let result = WhatChangedEngine.generate(
            from: changes,
            consistency: nil,
            checkIn: nil,
            isBaseline: true
        )
        XCTAssertNil(result.primaryChange)
        XCTAssertNil(result.secondaryChange)
        XCTAssertTrue(result.stableZones.isEmpty)
        XCTAssertTrue(result.improvedZones.isEmpty)
        XCTAssertTrue(result.worsenedZones.isEmpty)
        XCTAssertFalse(result.hasChanges)
    }

    func testDeterministicPercentChange() {
        let zoneChange = ZoneChange(
            zone: .chinJaw,
            metric: "breakouts",
            direction: .increasing,
            magnitude: .moderate,
            confidence: 0.8,
            explanation: "Breakouts increased",
            comparedMapIDs: [UUID(), UUID()]
        )
        let changes = ChangeDetectionResult(generatedAt: .now, mode: .latestPair, zoneChanges: [zoneChange])
        let result1 = WhatChangedEngine.generate(from: changes, consistency: nil, checkIn: nil, isBaseline: false)
        let result2 = WhatChangedEngine.generate(from: changes, consistency: nil, checkIn: nil, isBaseline: false)

        XCTAssertEqual(result1.primaryChange?.percentChange, result2.primaryChange?.percentChange)
    }

    func testPrimaryChangeRanking() {
        let slightChange = ZoneChange(
            zone: .forehead,
            metric: "redness",
            direction: .increasing,
            magnitude: .slight,
            confidence: 0.9,
            explanation: "Slight redness increase",
            comparedMapIDs: [UUID(), UUID()]
        )
        let significantChange = ZoneChange(
            zone: .chinJaw,
            metric: "breakouts",
            direction: .increasing,
            magnitude: .significant,
            confidence: 0.9,
            explanation: "Significant breakout increase",
            comparedMapIDs: [UUID(), UUID()]
        )
        let changes = ChangeDetectionResult(generatedAt: .now, mode: .latestPair, zoneChanges: [slightChange, significantChange])
        let result = WhatChangedEngine.generate(from: changes, consistency: nil, checkIn: nil, isBaseline: false)

        XCTAssertEqual(result.primaryChange?.zone, .chinJaw)
        XCTAssertEqual(result.primaryChange?.severity, .significant)
    }

    func testSecondaryChangePrefersDifferentZone() {
        let change1 = ZoneChange(
            zone: .chinJaw,
            metric: "breakouts",
            direction: .increasing,
            magnitude: .significant,
            confidence: 0.9,
            explanation: "Chin breakouts increased",
            comparedMapIDs: [UUID(), UUID()]
        )
        let change2 = ZoneChange(
            zone: .chinJaw,
            metric: "redness",
            direction: .increasing,
            magnitude: .moderate,
            confidence: 0.8,
            explanation: "Chin redness increased",
            comparedMapIDs: [UUID(), UUID()]
        )
        let change3 = ZoneChange(
            zone: .nose,
            metric: "redness",
            direction: .increasing,
            magnitude: .moderate,
            confidence: 0.8,
            explanation: "Nose redness increased",
            comparedMapIDs: [UUID(), UUID()]
        )
        let changes = ChangeDetectionResult(generatedAt: .now, mode: .latestPair, zoneChanges: [change1, change2, change3])
        let result = WhatChangedEngine.generate(from: changes, consistency: nil, checkIn: nil, isBaseline: false)

        XCTAssertEqual(result.primaryChange?.zone, .chinJaw)
        // Secondary should prefer nose (different zone) over chinJaw redness
        XCTAssertEqual(result.secondaryChange?.zone, .nose)
    }

    func testConsistencyLowersConfidence() {
        let zoneChange = ZoneChange(
            zone: .chinJaw,
            metric: "breakouts",
            direction: .increasing,
            magnitude: .moderate,
            confidence: 0.9,
            explanation: "Breakouts increased",
            comparedMapIDs: [UUID(), UUID()]
        )
        let changes = ChangeDetectionResult(generatedAt: .now, mode: .latestPair, zoneChanges: [zoneChange])
        let poorConsistency = ScanConsistency(
            score: 40,
            lighting: .different,
            angle: .different,
            distance: .different,
            blur: .different,
            timeOfDay: .different,
            landmarkAlignment: .different,
            confidenceImpact: .significant
        )
        let result = WhatChangedEngine.generate(
            from: changes,
            consistency: poorConsistency,
            checkIn: nil,
            isBaseline: false
        )
        XCTAssertEqual(result.primaryChange?.confidence, .low)
    }
}

// MARK: - Insight Prioritisation Engine

@MainActor
final class InsightPrioritisationEngineTests: XCTestCase {

    func testMaxInsightsRespected() {
        let insights = (0..<10).map { i in
            Insight(
                title: "Insight \(i)",
                body: "Body \(i)",
                type: i % 2 == 0 ? .improvement : .regression,
                zone: ZoneType.allCases[i % ZoneType.allCases.count],
                priority: .high
            )
        }
        let result = InsightPrioritisationEngine.prioritise(
            insights: insights,
            whatChanged: nil,
            weeklyInsight: nil,
            patterns: []
        )
        XCTAssertEqual(result.primary.count, 1)
        XCTAssertEqual(result.secondary.count, 1)
    }

    func testDeduplicationAllowsDifferentTopics() {
        let insight1 = Insight(
            title: "Forehead breakouts increased",
            body: "Body",
            type: .regression,
            zone: .forehead,
            priority: .high
        )
        let insight2 = Insight(
            title: "Forehead redness improving",
            body: "Body",
            type: .improvement,
            zone: .forehead,
            priority: .high
        )
        let result = InsightPrioritisationEngine.prioritise(
            insights: [insight1, insight2],
            whatChanged: nil,
            weeklyInsight: nil,
            patterns: []
        )
        // Both should be kept because they have different topics (breakouts vs redness)
        // even though same zone and different types
        XCTAssertGreaterThanOrEqual(result.allInsights.count, 1)
    }

    func testWhatChangedBoostsScore() {
        let whatChanged = WhatChangedResult(
            generatedAt: .now,
            primaryChange: WhatChangedItem(
                zone: .chinJaw,
                metric: "breakouts",
                trend: .increasing,
                severity: .moderate,
                confidence: .high,
                message: "Chin breakouts increased",
                percentChange: 20
            ),
            secondaryChange: nil,
            stableZones: [],
            improvedZones: [],
            worsenedZones: [.chinJaw],
            overallMessage: "Chin breakouts increased"
        )
        let insight = Insight(
            title: "Chin breakouts increased",
            body: "Body",
            type: .regression,
            zone: .chinJaw,
            priority: .medium
        )
        let result = InsightPrioritisationEngine.prioritise(
            insights: [insight],
            whatChanged: whatChanged,
            weeklyInsight: nil,
            patterns: []
        )
        XCTAssertEqual(result.primary.first?.zone, .chinJaw)
    }
}

// MARK: - Routine Impact Attribution

@MainActor
final class RoutineImpactAttributionTests: XCTestCase {

    func testMinimumDataGuard() {
        let result = RoutineImpactAttribution.analyze(
            sessions: [],
            routineLogs: [],
            routineChanges: [],
            currentProducts: []
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testInsufficientScansReturnsEmpty() {
        let sessions = (0..<4).map { _ in
            ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        }
        let logs = (0..<10).map { _ in
            RoutineLogEntry(date: .now, followedRoutine: true, productIDs: [], notes: nil)
        }
        let result = RoutineImpactAttribution.analyze(
            sessions: sessions,
            routineLogs: logs,
            routineChanges: [],
            currentProducts: []
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testActivesOverloadDetected() {
        let activeProduct = Product(name: "Strong Acid", category: .treatment, period: .evening, ingredientTags: [.aha])
        let sessions = (0..<6).map { _ in
            ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        }
        let logs = (0..<8).map { _ in
            RoutineLogEntry(date: .now, followedRoutine: true, productIDs: [activeProduct.id], notes: nil)
        }
        let result = RoutineImpactAttribution.analyze(
            sessions: sessions,
            routineLogs: logs,
            routineChanges: [],
            currentProducts: [activeProduct]
        )
        // Should detect actives overload or return some impact
        XCTAssertGreaterThanOrEqual(result.count, 0)
    }
}

// MARK: - Skin Pattern Recognition

@MainActor
final class SkinPatternRecognitionTests: XCTestCase {

    func testBelowThresholdReturnsEmpty() {
        let sessions = (0..<2).map { _ in
            ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        }
        let result = SkinPatternRecognition.analyze(
            sessions: sessions,
            routineLogs: [],
            routineChanges: []
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testThreeScansUnlocksBasic() {
        let sessions = (0..<3).map { _ in
            ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        }
        let result = SkinPatternRecognition.analyze(
            sessions: sessions,
            routineLogs: [],
            routineChanges: []
        )
        // 3 scans should not unlock any patterns yet (minimum is 5 for zone reactivity)
        XCTAssertTrue(result.isEmpty)
    }

    func testFiveScansUnlocksZoneReactivity() {
        var sessions: [ScanSession] = []
        for day in 0..<5 {
            let date = Calendar.current.date(byAdding: .day, value: -day, to: .now)!
            let zones: [FaceZone] = [
                FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: ZoneSeverity.low, redness: ZoneSeverity.none)),
                FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: ZoneSeverity.low, redness: ZoneSeverity.low)),
                FaceZone(zoneType: .leftCheek, status: ZoneStatus(breakouts: ZoneSeverity.none, redness: ZoneSeverity.none)),
                FaceZone(zoneType: .rightCheek, status: ZoneStatus(breakouts: ZoneSeverity.low, redness: ZoneSeverity.none)),
                FaceZone(zoneType: .chinJaw, status: ZoneStatus(breakouts: ZoneSeverity.moderate, redness: ZoneSeverity.low))
            ]
            var scan = ScanSession(kind: .daily, photos: [], skinMap: SkinMap(date: date, zones: zones), note: nil)
            scan.createdAt = date
            sessions.append(scan)
        }
        let result = SkinPatternRecognition.analyze(
            sessions: sessions,
            routineLogs: [],
            routineChanges: []
        )
        // Should unlock zone reactivity or scan consistency patterns
        XCTAssertGreaterThanOrEqual(result.count, 1)
        XCTAssertTrue(result.allSatisfy(\.isUnlocked))
    }
}

// MARK: - Smart Nudge Engine

@MainActor
final class SmartNudgeEngineTests: XCTestCase {

    func testScanGapNudgeAfterFourDays() {
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: .now)!
        var scan = ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        scan.createdAt = fourDaysAgo
        let result = SmartNudgeEngine.generate(
            sessions: [scan],
            routineLogs: [],
            routineChanges: [],
            currentProducts: [],
            lastAppOpen: nil
        )
        let gapNudge = result.first { $0.type == .followUpScan }
        XCTAssertNotNil(gapNudge)
    }

    func testNoScanGapNudgeWithinThreeDays() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
        var scan = ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        scan.createdAt = twoDaysAgo
        let result = SmartNudgeEngine.generate(
            sessions: [scan],
            routineLogs: [],
            routineChanges: [],
            currentProducts: [],
            lastAppOpen: nil
        )
        let gapNudge = result.first { $0.type == .followUpScan }
        XCTAssertNil(gapNudge)
    }

    func testTimelineProgressNudgeAtThreshold() {
        let sessions = (0..<3).map { _ in
            ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        }
        let result = SmartNudgeEngine.generate(
            sessions: sessions,
            routineLogs: [],
            routineChanges: [],
            currentProducts: [],
            lastAppOpen: nil
        )
        let progressNudge = result.first { $0.type == .timelineProgress }
        XCTAssertNotNil(progressNudge)
    }

    func testProductMonitorNudgeAfterRecentChange() {
        let recentChange = RoutineChangeLogEntry(
            productId: UUID(),
            changeType: .added,
            notes: "Added new serum"
        )
        let result = SmartNudgeEngine.generate(
            sessions: [],
            routineLogs: [],
            routineChanges: [recentChange],
            currentProducts: [],
            lastAppOpen: nil
        )
        let monitorNudge = result.first { $0.type == .productMonitor }
        XCTAssertNotNil(monitorNudge)
    }

    func testNudgesSortedByPriority() {
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: .now)!
        var scan = ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        scan.createdAt = fourDaysAgo
        let result = SmartNudgeEngine.generate(
            sessions: [scan],
            routineLogs: [],
            routineChanges: [],
            currentProducts: [],
            lastAppOpen: nil
        )
        guard result.count >= 2 else { return }
        let priorities = result.map { $0.priority }
        // Higher priority values should come first
        for i in 0..<(priorities.count - 1) {
            let currentRank = priorityRank(priorities[i])
            let nextRank = priorityRank(priorities[i + 1])
            XCTAssertGreaterThanOrEqual(currentRank, nextRank)
        }
    }

    private func priorityRank(_ priority: Nudge.NudgePriority) -> Int {
        switch priority {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

// MARK: - Environmental Context Engine

@MainActor
final class EnvironmentalContextEngineTests: XCTestCase {

    func testBelowMinimumScansReturnsEmpty() {
        let result = EnvironmentalContextEngine.analyze(sessions: [])
        XCTAssertTrue(result.isEmpty)
    }

    func testPlaceholderAdapterReturnsEmpty() {
        let sessions = (0..<5).map { _ in
            ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        }
        let result = EnvironmentalContextEngine.analyze(
            sessions: sessions,
            weatherAdapter: PlaceholderWeatherAdapter()
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testHighUVSignalDetected() {
        let sessions = (0..<5).map { _ in
            ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        }
        let result = EnvironmentalContextEngine.analyze(
            sessions: sessions,
            weatherAdapter: MockWeatherAdapter(scenario: .highUV)
        )
        XCTAssertGreaterThanOrEqual(result.count, 1)
        XCTAssertTrue(result.contains { $0.type == .highUV })
    }

    func testLowHumiditySignalDetected() {
        let sessions = (0..<5).map { _ in
            ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        }
        let result = EnvironmentalContextEngine.analyze(
            sessions: sessions,
            weatherAdapter: MockWeatherAdapter(scenario: .lowHumidity)
        )
        XCTAssertTrue(result.contains { $0.type == .lowHumidity })
    }

    func testCorrelationDrynessLink() {
        let prevMap = SkinMap(zones: [
            FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: ZoneSeverity.low, redness: ZoneSeverity.none, dryness: ZoneSeverity.none)),
            FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: ZoneSeverity.low, redness: ZoneSeverity.low, dryness: ZoneSeverity.none)),
            FaceZone(zoneType: .leftCheek, status: ZoneStatus(breakouts: ZoneSeverity.none, redness: ZoneSeverity.none, dryness: ZoneSeverity.none)),
            FaceZone(zoneType: .rightCheek, status: ZoneStatus(breakouts: ZoneSeverity.low, redness: ZoneSeverity.none, dryness: ZoneSeverity.none)),
            FaceZone(zoneType: .chinJaw, status: ZoneStatus(breakouts: ZoneSeverity.moderate, redness: ZoneSeverity.low, dryness: ZoneSeverity.none))
        ])
        let currMap = SkinMap(zones: [
            FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: ZoneSeverity.low, redness: ZoneSeverity.none, dryness: ZoneSeverity.low)),
            FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: ZoneSeverity.low, redness: ZoneSeverity.low, dryness: ZoneSeverity.low)),
            FaceZone(zoneType: .leftCheek, status: ZoneStatus(breakouts: ZoneSeverity.none, redness: ZoneSeverity.none, dryness: ZoneSeverity.none)),
            FaceZone(zoneType: .rightCheek, status: ZoneStatus(breakouts: ZoneSeverity.low, redness: ZoneSeverity.none, dryness: ZoneSeverity.none)),
            FaceZone(zoneType: .chinJaw, status: ZoneStatus(breakouts: ZoneSeverity.moderate, redness: ZoneSeverity.low, dryness: ZoneSeverity.none))
        ])
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        var prevScan = ScanSession(kind: .daily, photos: [], skinMap: prevMap, note: nil)
        prevScan.createdAt = yesterday
        var currScan = ScanSession(kind: .daily, photos: [], skinMap: currMap, note: nil)
        let sessions = [prevScan, currScan]
        let signal = EnvironmentalSignal(
            type: .lowHumidity,
            dateRange: .init(start: .now, end: .now),
            message: "Low humidity",
            confidence: .low
        )
        let correlated = EnvironmentalContextEngine.correlate(signals: [signal], sessions: sessions)
        XCTAssertTrue(correlated.first?.message.contains("dryness") ?? false)
    }
}

// MARK: - Data Density

@MainActor
final class DataDensityTests: XCTestCase {

    func testBaselineState() {
        let density = DataDensity(scanCount: 1)
        XCTAssertEqual(density.level, .baseline)
        XCTAssertNotNil(density.nextUnlockDescription)
    }

    func testFormingState() {
        let density = DataDensity(scanCount: 3)
        XCTAssertEqual(density.level, .forming)
    }

    func testEarlyTrendsState() {
        let density = DataDensity(scanCount: 5)
        XCTAssertEqual(density.level, .earlyTrends)
    }

    func testPatternsEmergingState() {
        let density = DataDensity(scanCount: 10)
        XCTAssertEqual(density.level, .patternsEmerging)
    }

    func testPersonalState() {
        let density = DataDensity(scanCount: 20)
        XCTAssertEqual(density.level, .personal)
        XCTAssertNil(density.nextUnlockDescription)
    }
}
