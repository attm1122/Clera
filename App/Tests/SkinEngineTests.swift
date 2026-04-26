import XCTest
@testable import Clera

// MARK: - Skin Engine Tests

final class SkinEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeContext(
        skinMap: SkinMap? = nil,
        products: [Product] = [],
        routineLogs: [RoutineLogEntry] = [],
        routineChanges: [RoutineChangeLogEntry] = [],
        weather: DailyWeatherSnapshot? = nil,
        airQuality: AirQualitySnapshot? = nil,
        onboarding: Bool = true,
        sessions: [ScanSession] = []
    ) -> SkinContext {
        SkinContext(
            latestScan: sessions.first,
            baselineScan: sessions.first { $0.kind == .baseline },
            previousScan: sessions.dropFirst().first,
            scansLastSevenDays: sessions,
            skinProfile: SkinProfile(),
            latestSkinMap: skinMap,
            baselineSkinMap: nil,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            products: products,
            weatherSnapshot: weather,
            airQualitySnapshot: airQuality,
            latestCheckIn: skinMap?.checkIn,
            checkInHistory: [],
            hasCompletedOnboarding: onboarding,
            isFirstTimeUser: sessions.isEmpty
        )
    }

    private func makeSkinMap(zones: [FaceZone], checkIn: SkinMapCheckIn? = nil) -> SkinMap {
        SkinMap(zones: zones, checkIn: checkIn, confidenceLevel: 1.0)
    }

    private func makeZone(type: ZoneType, breakouts: ZoneSeverity = .none, redness: ZoneSeverity = .none, dryness: ZoneSeverity = .none, texture: ZoneSeverity = .none, congestion: ZoneSeverity = .none, irritation: ZoneSeverity = .none) -> FaceZone {
        FaceZone(
            zoneType: type,
            status: ZoneStatus(
                breakouts: breakouts,
                redness: redness,
                dryness: dryness,
                texture: texture,
                congestion: congestion,
                irritation: irritation,
                overallConfidence: 0.8
            ),
            notes: nil
        )
    }

    private func makeProduct(id: UUID = UUID(), name: String, tags: [IngredientTag] = [], period: Period = .evening, category: ProductCategory = .serum, isActive: Bool = true) -> Product {
        Product(id: id, name: name, category: category, period: period, ingredients: [], ingredientTags: tags, isActive: isActive)
    }

    private func makeLog(date: Date, products: [UUID] = [], followed: Bool = true) -> RoutineLogEntry {
        RoutineLogEntry(date: date, followedRoutine: followed, productIDs: products, notes: nil, photo: nil)
    }

    private func makeSession(kind: ScanType, skinMap: SkinMap, date: Date = .now) -> ScanSession {
        ScanSession(kind: kind, createdAt: date, photos: [], skinMap: skinMap, note: nil)
    }

    // MARK: - SkinScoreCalculator Tests

    func testScoreCalculatorReturnsScoresForAllZones() {
        let zones = ZoneType.allCases.map { makeZone(type: $0) }
        let map = makeSkinMap(zones: zones)
        let context = makeContext(skinMap: map)
        let scores = SkinScoreCalculator.calculateZoneScores(from: context.latestSkinMap)
        XCTAssertEqual(scores.count, ZoneType.allCases.count)
    }

    func testScoreCalculatorReturnsPlaceholderWhenNoMap() {
        let context = makeContext()
        let scores = SkinScoreCalculator.calculateZoneScores(from: context.latestSkinMap)
        XCTAssertEqual(scores.count, ZoneType.allCases.count)
        XCTAssertTrue(scores.allSatisfy { $0.confidence.level == .low })
    }

    func testSeverityMapping() {
        let zones = [makeZone(type: .forehead, breakouts: .high, redness: .moderate)]
        let map = makeSkinMap(zones: zones)
        let scores = SkinScoreCalculator.calculateZoneScores(from: map)
        XCTAssertEqual(scores.first?.breakout, 80)
        XCTAssertEqual(scores.first?.redness, 55)
    }

    func testOverallStateDetectsDry() {
        let zones = ZoneType.allCases.map { makeZone(type: $0, dryness: .high, congestion: .none) }
        let map = makeSkinMap(zones: zones)
        let scores = SkinScoreCalculator.calculateZoneScores(from: map)
        let state = SkinScoreCalculator.calculateOverallState(from: scores)
        XCTAssertNotNil(state.primaryConcern)
    }

    // MARK: - SkinChangeDetector Tests

    func testTrendDetectionReturnsEmptyWithoutBaseline() {
        let zones = [makeZone(type: .forehead, breakouts: .moderate)]
        let map = makeSkinMap(zones: zones)
        let context = makeContext(skinMap: map)
        let trends = SkinChangeDetector.detectTrends(context: context)
        XCTAssertTrue(trends.isEmpty)
    }

    func testTrendDetectsWorsening() {
        let baselineZones = [makeZone(type: .forehead, breakouts: .none)]
        let currentZones = [makeZone(type: .forehead, breakouts: .high)]
        let baselineMap = makeSkinMap(zones: baselineZones)
        let currentMap = makeSkinMap(zones: currentZones)
        let session = makeSession(kind: .baseline, skinMap: baselineMap, date: .now.addingTimeInterval(-86400 * 7))
        let currentSession = makeSession(kind: .daily, skinMap: currentMap)
        let context = makeContext(skinMap: currentMap, sessions: [currentSession, session])
        let trends = SkinChangeDetector.detectTrends(context: context)
        let foreheadTrends = trends[.forehead] ?? []
        let breakoutTrend = foreheadTrends.first { $0.metric == .breakoutLikeSpots }
        XCTAssertEqual(breakoutTrend?.direction, .worsening)
    }

    func testTrendDetectsImproving() {
        let baselineZones = [makeZone(type: .forehead, breakouts: .high)]
        let currentZones = [makeZone(type: .forehead, breakouts: .none)]
        let baselineMap = makeSkinMap(zones: baselineZones)
        let currentMap = makeSkinMap(zones: currentZones)
        let session = makeSession(kind: .baseline, skinMap: baselineMap, date: .now.addingTimeInterval(-86400 * 7))
        let currentSession = makeSession(kind: .daily, skinMap: currentMap)
        let context = makeContext(skinMap: currentMap, sessions: [currentSession, session])
        let trends = SkinChangeDetector.detectTrends(context: context)
        let foreheadTrends = trends[.forehead] ?? []
        let breakoutTrend = foreheadTrends.first { $0.metric == .breakoutLikeSpots }
        XCTAssertEqual(breakoutTrend?.direction, .improving)
    }

    // MARK: - EnvironmentRuleEngine Tests

    func testEnvironmentEngineReturnsEmptyWithoutWeather() {
        let context = makeContext()
        let recs = EnvironmentRuleEngine.evaluate(context: context)
        XCTAssertTrue(recs.isEmpty)
    }

    func testHighUVGeneratesRecommendation() {
        let weather = DailyWeatherSnapshot(uvIndex: 9, temperatureCelsius: 25, humidityPercent: 50, windSpeedKmh: 10, condition: .clear)
        let context = makeContext(weather: weather)
        let recs = EnvironmentRuleEngine.evaluate(context: context)
        XCTAssertTrue(recs.contains { $0.title.contains("Strong UV") })
    }

    func testLowHumidityGeneratesRecommendation() {
        let weather = DailyWeatherSnapshot(uvIndex: 2, temperatureCelsius: 25, humidityPercent: 20, windSpeedKmh: 10, condition: .clear)
        let context = makeContext(weather: weather)
        let recs = EnvironmentRuleEngine.evaluate(context: context)
        XCTAssertTrue(recs.contains { $0.title.contains("dry air") })
    }

    func testPoorAQIGeneratesRecommendation() {
        let weather = DailyWeatherSnapshot(uvIndex: 2, temperatureCelsius: 25, humidityPercent: 50, windSpeedKmh: 10, condition: .clear)
        let aqi = AirQualitySnapshot(aqi: 120, pm25: 35, dominantPollutant: "PM2.5")
        let context = makeContext(weather: weather, airQuality: aqi)
        let recs = EnvironmentRuleEngine.evaluate(context: context)
        XCTAssertTrue(recs.contains { $0.title.contains("air quality") })
    }

    // MARK: - RoutineRuleEngine Tests

    func testRoutineEngineReturnsEmptyWithNoLogs() {
        let context = makeContext()
        let trends: [ZoneType: [EngineSkinTrend]] = [:]
        let recs = RoutineRuleEngine.evaluate(context: context, trends: trends)
        XCTAssertFalse(recs.contains { $0.category == .routine && $0.priority == .high })
    }

    func testOverExfoliationDetected() {
        let product = makeProduct(name: "AHA Toner", tags: [.aha], period: .evening)
        var logs: [RoutineLogEntry] = []
        for i in 0..<8 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: .now) ?? .now
            logs.append(makeLog(date: date, products: [product.id]))
        }
        let context = makeContext(products: [product], routineLogs: logs)
        let trends: [ZoneType: [EngineSkinTrend]] = [:]
        let recs = RoutineRuleEngine.evaluate(context: context, trends: trends)
        XCTAssertTrue(recs.contains { $0.title.contains("exfoliation") })
    }

    func testRetinolExfoliantConflictDetected() {
        let retinol = makeProduct(name: "Retinol", tags: [.retinol], period: .evening)
        let aha = makeProduct(name: "AHA", tags: [.aha], period: .evening)
        let log = makeLog(date: .now, products: [retinol.id, aha.id])
        let context = makeContext(products: [retinol, aha], routineLogs: [log])
        let trends: [ZoneType: [EngineSkinTrend]] = [:]
        let recs = RoutineRuleEngine.evaluate(context: context, trends: trends)
        XCTAssertTrue(recs.contains { $0.title.contains("retinoid and exfoliant") })
    }

    func testLowAdherenceDetected() {
        var logs: [RoutineLogEntry] = []
        for i in 0..<3 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: .now) ?? .now
            logs.append(makeLog(date: date, followed: true))
        }
        let context = makeContext(routineLogs: logs)
        let trends: [ZoneType: [EngineSkinTrend]] = [:]
        let recs = RoutineRuleEngine.evaluate(context: context, trends: trends)
        XCTAssertTrue(recs.contains { $0.title.contains("consistency") })
    }

    // MARK: - ProductRuleEngine Tests

    func testRetinolWithoutSPFWarns() {
        let retinol = makeProduct(name: "Retinol", tags: [.retinol], period: .evening)
        let context = makeContext(products: [retinol])
        let trends: [ZoneType: [EngineSkinTrend]] = [:]
        let recs = ProductRuleEngine.evaluate(context: context, trends: trends)
        XCTAssertTrue(recs.contains { $0.title.contains("SPF") })
    }

    func testMultipleExfoliantsWarns() {
        let aha = makeProduct(name: "AHA", tags: [.aha])
        let bha = makeProduct(name: "BHA", tags: [.bha])
        let lactic = makeProduct(name: "Lactic", tags: [.aha])
        let context = makeContext(products: [aha, bha, lactic])
        let trends: [ZoneType: [EngineSkinTrend]] = [:]
        let recs = ProductRuleEngine.evaluate(context: context, trends: trends)
        XCTAssertTrue(recs.contains { $0.title.contains("Multiple exfoliants") })
    }

    func testBenzoylPeroxideRetinolConflictWarns() {
        let bp = makeProduct(name: "BP", tags: [.benzoylPeroxide])
        let retinol = makeProduct(name: "Retinol", tags: [.retinol])
        let context = makeContext(products: [bp, retinol])
        let trends: [ZoneType: [EngineSkinTrend]] = [:]
        let recs = ProductRuleEngine.evaluate(context: context, trends: trends)
        XCTAssertTrue(recs.contains { $0.title.contains("Benzoyl peroxide") })
    }

    func testMissingMoisturiserWarns() {
        let cleanser = makeProduct(name: "Cleanser", tags: [], category: .cleanser)
        let context = makeContext(products: [cleanser])
        let trends: [ZoneType: [EngineSkinTrend]] = [:]
        let recs = ProductRuleEngine.evaluate(context: context, trends: trends)
        XCTAssertTrue(recs.contains { $0.title.contains("moisturiser") })
    }

    // MARK: - SafetyRuleEngine Tests

    func testNormalSafetyWhenStable() {
        let zones = ZoneType.allCases.map { makeZone(type: $0) }
        let map = makeSkinMap(zones: zones)
        let context = makeContext(skinMap: map)
        let scores = SkinScoreCalculator.calculateZoneScores(from: map)
        let trends = SkinChangeDetector.detectTrends(context: context)
        let safety = SafetyRuleEngine.evaluate(context: context, trends: trends, scores: scores)
        XCTAssertEqual(safety.level, .normal)
    }

    func testUrgentReviewForCheckInIrritation() {
        let zones = ZoneType.allCases.map { makeZone(type: $0) }
        let checkIn = SkinMapCheckIn(followedRoutine: true, newProducts: false, hadIrritation: true, hadDryness: false, hadBreakouts: false, notes: nil)
        let map = makeSkinMap(zones: zones, checkIn: checkIn)
        let context = makeContext(skinMap: map)
        let scores = SkinScoreCalculator.calculateZoneScores(from: map)
        let trends = SkinChangeDetector.detectTrends(context: context)
        let safety = SafetyRuleEngine.evaluate(context: context, trends: trends, scores: scores)
        XCTAssertEqual(safety.level, .urgentReview)
    }

    func testProfessionalReviewForSevereRedness() {
        let zones = [makeZone(type: .forehead, redness: .high)]
        let map = makeSkinMap(zones: zones)
        let context = makeContext(skinMap: map)
        let scores = SkinScoreCalculator.calculateZoneScores(from: map)
        let trends = SkinChangeDetector.detectTrends(context: context)
        let safety = SafetyRuleEngine.evaluate(context: context, trends: trends, scores: scores)
        XCTAssertEqual(safety.level, .recommendProfessionalReview)
    }

    // MARK: - RecommendationRanker Tests

    func testRankerSortsByPriority() {
        let recs: [SkinRecommendation] = [
            SkinRecommendation(title: "Low", body: "", action: nil, category: .routine, priority: .low, confidence: .high, zones: [], durationDays: nil, createdAt: .now),
            SkinRecommendation(title: "High", body: "", action: nil, category: .routine, priority: .high, confidence: .high, zones: [], durationDays: nil, createdAt: .now),
            SkinRecommendation(title: "Medium", body: "", action: nil, category: .routine, priority: .medium, confidence: .high, zones: [], durationDays: nil, createdAt: .now)
        ]
        let ranked = RecommendationRanker.rank(recs)
        XCTAssertEqual(ranked[0].priority, .high)
        XCTAssertEqual(ranked[1].priority, .medium)
        XCTAssertEqual(ranked[2].priority, .low)
    }

    func testDeduplicateRemovesDuplicates() {
        let recs: [SkinRecommendation] = [
            SkinRecommendation(title: "Same", body: "A", action: nil, category: .routine, priority: .low, confidence: .high, zones: [], durationDays: nil, createdAt: .now),
            SkinRecommendation(title: "Same", body: "B", action: nil, category: .routine, priority: .low, confidence: .high, zones: [], durationDays: nil, createdAt: .now),
            SkinRecommendation(title: "Different", body: "", action: nil, category: .routine, priority: .low, confidence: .high, zones: [], durationDays: nil, createdAt: .now)
        ]
        let deduped = RecommendationRanker.deduplicate(recs)
        XCTAssertEqual(deduped.count, 2)
    }

    // MARK: - SkinEngine Integration Tests

    func testEngineGeneratesReport() {
        let zones = ZoneType.allCases.map { makeZone(type: $0) }
        let map = makeSkinMap(zones: zones)
        let context = makeContext(skinMap: map, onboarding: true)
        let report = SkinEngine.generateReport(context: context)
        XCTAssertFalse(report.summary.isEmpty)
        XCTAssertEqual(report.zoneSummaries.count, ZoneType.allCases.count)
    }

    func testEngineHandlesEmptyContext() {
        let context = makeContext()
        let report = SkinEngine.generateReport(context: context)
        XCTAssertFalse(report.summary.isEmpty)
        XCTAssertTrue(report.recommendations.isEmpty || report.confidence.level == .low)
    }

    func testEngineIncludesEnvironmentRisks() {
        let weather = DailyWeatherSnapshot(uvIndex: 9, temperatureCelsius: 25, humidityPercent: 20, windSpeedKmh: 10, condition: .clear)
        let zones = ZoneType.allCases.map { makeZone(type: $0) }
        let map = makeSkinMap(zones: zones)
        let context = makeContext(skinMap: map, weather: weather)
        let report = SkinEngine.generateReport(context: context)
        XCTAssertFalse(report.environmentRisks.isEmpty)
    }

    func testEngineSafetyAssessmentNeverNil() {
        let context = makeContext()
        let report = SkinEngine.generateReport(context: context)
        XCTAssertNotNil(report.safetyAssessment)
    }
}
