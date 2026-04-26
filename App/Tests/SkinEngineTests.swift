import XCTest
@testable import Clera

// MARK: - Skin Score Calculator Tests

final class SkinScoreCalculatorTests: XCTestCase {

    func testCalculateZoneScoresWithNilMap() {
        let scores = SkinScoreCalculator.calculateZoneScores(from: nil)
        XCTAssertEqual(scores.count, 5)
        XCTAssertTrue(scores.allSatisfy { $0.breakout == 0 })
        XCTAssertTrue(scores.allSatisfy { $0.confidence.level == .low })
    }

    func testCalculateZoneScoresWithMap() {
        let map = SampleData.sampleSkinMap
        let scores = SkinScoreCalculator.calculateZoneScores(from: map)
        XCTAssertEqual(scores.count, 5)
        // ChinJaw has breakouts=.moderate -> score 55
        let chinScore = scores.first { $0.zone == .chinJaw }
        XCTAssertEqual(chinScore?.breakout, 55)
    }

    func testSeverityToScoreMapping() {
        // Indirectly tested via calculateZoneScores
        let map = SkinMap(zones: [
            FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: .none, redness: .low, dryness: .moderate, texture: .high, congestion: .none, irritation: .low))
        ])
        let scores = SkinScoreCalculator.calculateZoneScores(from: map)
        let forehead = scores[0]
        XCTAssertEqual(forehead.breakout, 10)  // none
        XCTAssertEqual(forehead.redness, 30)   // low
        XCTAssertEqual(forehead.dryness, 55)   // moderate
        XCTAssertEqual(forehead.texture, 80)   // high
    }

    func testCalculateOverallStateEmpty() {
        let state = SkinScoreCalculator.calculateOverallState(from: [])
        XCTAssertEqual(state.overallScore, 0)
        XCTAssertNil(state.highestRiskZone)
    }

    func testCalculateOverallStateWithScores() {
        let scores = [
            ZoneSkinScore(zone: .forehead, breakout: 10, redness: 10, texture: 10, oiliness: 10, dryness: 10, pigmentation: 10, congestion: 10, sensitivity: 10, confidence: EngineConfidence(level: .high, reasons: [])),
            ZoneSkinScore(zone: .chinJaw, breakout: 80, redness: 80, texture: 80, oiliness: 80, dryness: 80, pigmentation: 80, congestion: 80, sensitivity: 80, confidence: EngineConfidence(level: .high, reasons: []))
        ]
        let state = SkinScoreCalculator.calculateOverallState(from: scores)
        XCTAssertEqual(state.highestRiskZone, .chinJaw)
        // All metrics are equal (80), so primaryConcern depends on dictionary ordering in max()
        XCTAssertNotNil(state.primaryConcern)
    }

    func testZoneAverage() {
        let score = ZoneSkinScore(zone: .forehead, breakout: 10, redness: 30, texture: 55, oiliness: 10, dryness: 10, pigmentation: 10, congestion: 10, sensitivity: 10, confidence: EngineConfidence(level: .high, reasons: []))
        XCTAssertEqual(SkinScoreCalculator.zoneAverage(score), 18) // (10+30+55+10+10+10+10+10)/8 = 18
    }

    func testHighestRiskZone() {
        let scores = [
            ZoneSkinScore(zone: .forehead, breakout: 10, redness: 10, texture: 10, oiliness: 10, dryness: 10, pigmentation: 10, congestion: 10, sensitivity: 10, confidence: EngineConfidence(level: .high, reasons: [])),
            ZoneSkinScore(zone: .nose, breakout: 80, redness: 80, texture: 80, oiliness: 80, dryness: 80, pigmentation: 80, congestion: 80, sensitivity: 80, confidence: EngineConfidence(level: .high, reasons: []))
        ]
        XCTAssertEqual(SkinScoreCalculator.highestRiskZone(scores), .nose)
    }

    func testMostImprovedZone() {
        let trends: [ZoneType: [EngineSkinTrend]] = [
            .forehead: [EngineSkinTrend(metric: .redness, direction: .improving, delta: -20, severity: .significant, confidence: EngineConfidence(level: .high, reasons: []), comparedTo: .baseline)],
            .nose: [EngineSkinTrend(metric: .redness, direction: .improving, delta: -20, severity: .significant, confidence: EngineConfidence(level: .high, reasons: []), comparedTo: .baseline), EngineSkinTrend(metric: .texture, direction: .improving, delta: -15, severity: .moderate, confidence: EngineConfidence(level: .high, reasons: []), comparedTo: .baseline)]
        ]
        XCTAssertEqual(SkinScoreCalculator.mostImprovedZone(trends), .nose)
    }
}

// MARK: - Skin Change Detector Tests

final class SkinChangeDetectorTests: XCTestCase {

    func testDetectTrendsWithNoMap() {
        let context = SkinContext(latestScan: nil, baselineScan: nil, previousScan: nil, scansLastSevenDays: [], skinProfile: SkinProfile(), latestSkinMap: nil, baselineSkinMap: nil, routineLogs: [], routineChanges: [], products: [], weatherSnapshot: nil, airQualitySnapshot: nil, latestCheckIn: nil, checkInHistory: [], hasCompletedOnboarding: false, isFirstTimeUser: true)
        let trends = SkinChangeDetector.detectTrends(context: context)
        XCTAssertTrue(trends.isEmpty)
    }

    func testDetectTrendsWithBaseline() {
        let baseline = SkinMap(zones: [FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: .high, redness: .high, dryness: .high, texture: .high, congestion: .high, irritation: .high))])
        let latest = SkinMap(zones: [FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: .none, redness: .none, dryness: .none, texture: .none, congestion: .none, irritation: .none))])
        let context = SkinContext(latestScan: nil, baselineScan: nil, previousScan: nil, scansLastSevenDays: [], skinProfile: SkinProfile(), latestSkinMap: latest, baselineSkinMap: baseline, routineLogs: [], routineChanges: [], products: [], weatherSnapshot: nil, airQualitySnapshot: nil, latestCheckIn: nil, checkInHistory: [], hasCompletedOnboarding: true, isFirstTimeUser: false)
        let trends = SkinChangeDetector.detectTrends(context: context)
        XCTAssertFalse(trends.isEmpty)
        let foreheadTrends = trends[.forehead]!
        XCTAssertTrue(foreheadTrends.contains { $0.direction == .improving })
    }

    func testDetectTrendsWorsening() {
        let baseline = SkinMap(zones: [FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: .none, redness: .none, dryness: .none, texture: .none, congestion: .none, irritation: .none))])
        let latest = SkinMap(zones: [FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: .high, redness: .high, dryness: .high, texture: .high, congestion: .high, irritation: .high))])
        let context = SkinContext(latestScan: nil, baselineScan: nil, previousScan: nil, scansLastSevenDays: [], skinProfile: SkinProfile(), latestSkinMap: latest, baselineSkinMap: baseline, routineLogs: [], routineChanges: [], products: [], weatherSnapshot: nil, airQualitySnapshot: nil, latestCheckIn: nil, checkInHistory: [], hasCompletedOnboarding: true, isFirstTimeUser: false)
        let trends = SkinChangeDetector.detectTrends(context: context)
        let noseTrends = trends[.nose]!
        XCTAssertTrue(noseTrends.contains { $0.direction == .worsening && $0.severity == .significant })
    }
}

// MARK: - Safety Rule Engine Tests

final class SafetyRuleEngineTests: XCTestCase {

    func testNormalSkin() {
        let context = SkinContext(latestScan: nil, baselineScan: nil, previousScan: nil, scansLastSevenDays: [], skinProfile: SkinProfile(), latestSkinMap: nil, baselineSkinMap: nil, routineLogs: [], routineChanges: [], products: [], weatherSnapshot: nil, airQualitySnapshot: nil, latestCheckIn: nil, checkInHistory: [], hasCompletedOnboarding: true, isFirstTimeUser: false)
        let scores = [ZoneSkinScore(zone: .forehead, breakout: 10, redness: 10, texture: 10, oiliness: 10, dryness: 10, pigmentation: 10, congestion: 10, sensitivity: 10, confidence: EngineConfidence(level: .high, reasons: []))]
        let safety = SafetyRuleEngine.evaluate(context: context, trends: [:], scores: scores)
        XCTAssertEqual(safety.level, .normal)
    }

    func testUrgentReviewFromCheckIn() {
        let context = SkinContext(latestScan: nil, baselineScan: nil, previousScan: nil, scansLastSevenDays: [], skinProfile: SkinProfile(), latestSkinMap: nil, baselineSkinMap: nil, routineLogs: [], routineChanges: [], products: [], weatherSnapshot: nil, airQualitySnapshot: nil, latestCheckIn: SkinMapCheckIn(followedRoutine: true, newProducts: false, hadIrritation: true, hadDryness: false, hadBreakouts: false, notes: nil), checkInHistory: [], hasCompletedOnboarding: true, isFirstTimeUser: false)
        let safety = SafetyRuleEngine.evaluate(context: context, trends: [:], scores: [])
        XCTAssertEqual(safety.level, .urgentReview)
    }

    func testSevereRednessProfessionalReview() {
        let scores = [ZoneSkinScore(zone: .forehead, breakout: 10, redness: 80, texture: 10, oiliness: 10, dryness: 10, pigmentation: 10, congestion: 10, sensitivity: 10, confidence: EngineConfidence(level: .high, reasons: []))]
        let safety = SafetyRuleEngine.evaluate(context: .emptyContext(), trends: [:], scores: scores)
        XCTAssertEqual(safety.level, .recommendProfessionalReview)
    }

    func testMultipleModerateConcerns() {
        let scores = [
            ZoneSkinScore(zone: .forehead, breakout: 55, redness: 55, texture: 10, oiliness: 10, dryness: 10, pigmentation: 10, congestion: 10, sensitivity: 10, confidence: EngineConfidence(level: .high, reasons: [])),
            ZoneSkinScore(zone: .nose, breakout: 55, redness: 55, texture: 10, oiliness: 10, dryness: 10, pigmentation: 10, congestion: 10, sensitivity: 10, confidence: EngineConfidence(level: .high, reasons: [])),
            ZoneSkinScore(zone: .chinJaw, breakout: 55, redness: 55, texture: 10, oiliness: 10, dryness: 10, pigmentation: 10, congestion: 10, sensitivity: 10, confidence: EngineConfidence(level: .high, reasons: []))
        ]
        let safety = SafetyRuleEngine.evaluate(context: .emptyContext(), trends: [:], scores: scores)
        XCTAssertEqual(safety.level, .caution)
    }
}

// MARK: - Recommendation Ranker Tests

final class RecommendationRankerTests: XCTestCase {

    func testRankByPriority() {
        let recs = [
            SkinRecommendation(title: "Low", body: "B", action: nil, category: .routine, priority: .low, confidence: .high, zones: [], durationDays: nil, createdAt: Date(timeIntervalSince1970: 100)),
            SkinRecommendation(title: "High", body: "B", action: nil, category: .routine, priority: .high, confidence: .low, zones: [], durationDays: nil, createdAt: Date(timeIntervalSince1970: 100)),
            SkinRecommendation(title: "Medium", body: "B", action: nil, category: .routine, priority: .medium, confidence: .medium, zones: [], durationDays: nil, createdAt: Date(timeIntervalSince1970: 100))
        ]
        let ranked = RecommendationRanker.rank(recs)
        XCTAssertEqual(ranked[0].title, "High")
        XCTAssertEqual(ranked[1].title, "Medium")
        XCTAssertEqual(ranked[2].title, "Low")
    }

    func testDeduplicate() {
        let recs = [
            SkinRecommendation(title: "Same", body: "A", action: nil, category: .routine, priority: .high, confidence: .high, zones: [], durationDays: nil, createdAt: .now),
            SkinRecommendation(title: "Same", body: "B", action: nil, category: .routine, priority: .low, confidence: .low, zones: [], durationDays: nil, createdAt: .now)
        ]
        let deduped = RecommendationRanker.deduplicate(recs)
        XCTAssertEqual(deduped.count, 1)
    }

    func testTopLimitsCount() {
        let recs = (0..<10).map { i in
            SkinRecommendation(title: "\(i)", body: "B", action: nil, category: .routine, priority: .high, confidence: .high, zones: [], durationDays: nil, createdAt: .now)
        }
        let top = RecommendationRanker.top(recs, count: 3)
        XCTAssertEqual(top.count, 3)
    }
}

// MARK: - Product Rule Engine Tests

final class ProductRuleEngineTests: XCTestCase {

    func testEmptyProducts() {
        let context = SkinContext.emptyContext()
        let recs = ProductRuleEngine.evaluate(context: context, trends: [:])
        XCTAssertTrue(recs.isEmpty)
    }

    func testRetinolWithoutSPF() {
        let products = [Product(name: "Retinol", category: .serum, period: .evening, ingredientTags: [.retinol])]
        let context = SkinContext.emptyContext(products: products)
        let recs = ProductRuleEngine.evaluate(context: context, trends: [:])
        XCTAssertTrue(recs.contains { $0.title.contains("SPF") })
    }

    func testMultipleExfoliants() {
        let products = [
            Product(name: "AHA", category: .serum, period: .evening, ingredientTags: [.aha]),
            Product(name: "BHA", category: .serum, period: .evening, ingredientTags: [.bha]),
            Product(name: "Glycolic", category: .toner, period: .evening, ingredientTags: [.aha])
        ]
        let context = SkinContext.emptyContext(products: products)
        let recs = ProductRuleEngine.evaluate(context: context, trends: [:])
        XCTAssertTrue(recs.contains { $0.title.contains("Multiple exfoliants") })
    }

    func testBenzoylPeroxideAndRetinol() {
        let products = [
            Product(name: "BP", category: .treatment, period: .evening, ingredientTags: [.benzoylPeroxide]),
            Product(name: "Retinol", category: .serum, period: .evening, ingredientTags: [.retinol])
        ]
        let context = SkinContext.emptyContext(products: products)
        let recs = ProductRuleEngine.evaluate(context: context, trends: [:])
        XCTAssertTrue(recs.contains { $0.title.contains("Benzoyl peroxide and retinol") })
    }

    func testMissingMoisturiser() {
        let products = [Product(name: "Cleanser", category: .cleanser, period: .both, ingredientTags: [])]
        let context = SkinContext.emptyContext(products: products)
        let recs = ProductRuleEngine.evaluate(context: context, trends: [:])
        XCTAssertTrue(recs.contains { $0.title.contains("moisturiser") })
    }

    func testTooManyActives() {
        let products = [
            Product(name: "Retinol", category: .serum, period: .evening, ingredientTags: [.retinol]),
            Product(name: "VitC", category: .serum, period: .morning, ingredientTags: [.vitaminC]),
            Product(name: "BP", category: .treatment, period: .evening, ingredientTags: [.benzoylPeroxide]),
            Product(name: "AHA", category: .serum, period: .evening, ingredientTags: [.aha]),
            Product(name: "AzA", category: .treatment, period: .evening, ingredientTags: [.azelaicAcid])
        ]
        let context = SkinContext.emptyContext(products: products)
        let recs = ProductRuleEngine.evaluate(context: context, trends: [:])
        XCTAssertTrue(recs.contains { $0.title.contains("Many active") })
    }
}

// MARK: - Environment Rule Engine Tests

final class EnvironmentRuleEngineTests: XCTestCase {

    func testNoWeather() {
        let context = SkinContext.emptyContext()
        let recs = EnvironmentRuleEngine.evaluate(context: context)
        XCTAssertTrue(recs.isEmpty)
    }

    func testHighUV() {
        let weather = DailyWeatherSnapshot(uvIndex: 9, temperatureCelsius: 25, humidityPercent: 50, windSpeedKmh: 10, condition: .clear)
        let context = SkinContext.emptyContext(weather: weather)
        let recs = EnvironmentRuleEngine.evaluate(context: context)
        XCTAssertTrue(recs.contains { $0.title.contains("Strong UV") })
    }

    func testLowHumidity() {
        let weather = DailyWeatherSnapshot(uvIndex: 1, temperatureCelsius: 25, humidityPercent: 20, windSpeedKmh: 10, condition: .clear)
        let context = SkinContext.emptyContext(weather: weather)
        let recs = EnvironmentRuleEngine.evaluate(context: context)
        XCTAssertTrue(recs.contains { $0.title.contains("dry air") })
    }

    func testPoorAirQuality() {
        let weather = DailyWeatherSnapshot(uvIndex: 1, temperatureCelsius: 25, humidityPercent: 50, windSpeedKmh: 10, condition: .clear)
        let aqi = AirQualitySnapshot(aqi: 150, pm25: 50, dominantPollutant: "PM2.5")
        let context = SkinContext.emptyContext(weather: weather, aqi: aqi)
        let recs = EnvironmentRuleEngine.evaluate(context: context)
        XCTAssertTrue(recs.contains { $0.title.contains("Poor air quality") })
    }

    func testHotWeather() {
        let weather = DailyWeatherSnapshot(uvIndex: 1, temperatureCelsius: 32, humidityPercent: 50, windSpeedKmh: 10, condition: .clear)
        let context = SkinContext.emptyContext(weather: weather)
        let recs = EnvironmentRuleEngine.evaluate(context: context)
        XCTAssertTrue(recs.contains { $0.title.contains("Hot weather") })
    }

    func testWindy() {
        let weather = DailyWeatherSnapshot(uvIndex: 1, temperatureCelsius: 20, humidityPercent: 50, windSpeedKmh: 30, condition: .clear)
        let context = SkinContext.emptyContext(weather: weather)
        let recs = EnvironmentRuleEngine.evaluate(context: context)
        XCTAssertTrue(recs.contains { $0.title.contains("Windy") })
    }
}

// MARK: - Insight Template Renderer Tests

final class InsightTemplateRendererTests: XCTestCase {

    func testRenderSummaryNormal() {
        let state = SkinStateSummary(overallScore: 50, highestRiskZone: nil, mostImprovedZone: nil, primaryConcern: nil, overallTrend: .stable)
        let safety = SafetyAssessment(level: .normal, reasons: [], message: "")
        let summary = InsightTemplateRenderer.renderSummary(state: state, safety: safety)
        XCTAssertTrue(summary.contains("balanced"))
    }

    func testRenderSummaryUrgent() {
        let state = SkinStateSummary(overallScore: 50, highestRiskZone: nil, mostImprovedZone: nil, primaryConcern: .redness, overallTrend: .stable)
        let safety = SafetyAssessment(level: .urgentReview, reasons: [], message: "")
        let summary = InsightTemplateRenderer.renderSummary(state: state, safety: safety)
        XCTAssertTrue(summary.contains("irritation"))
    }

    func testRenderSummaryRednessConcern() {
        let state = SkinStateSummary(overallScore: 50, highestRiskZone: .forehead, mostImprovedZone: nil, primaryConcern: .redness, overallTrend: .stable)
        let safety = SafetyAssessment(level: .normal, reasons: [], message: "")
        let summary = InsightTemplateRenderer.renderSummary(state: state, safety: safety)
        XCTAssertTrue(summary.contains("Redness"))
    }

    func testRenderZoneSummaryStable() {
        let score = ZoneSkinScore(zone: .forehead, breakout: 10, redness: 10, texture: 10, oiliness: 10, dryness: 10, pigmentation: 10, congestion: 10, sensitivity: 10, confidence: EngineConfidence(level: .high, reasons: []))
        let summary = InsightTemplateRenderer.renderZoneSummary(zone: .forehead, score: score, trends: [])
        // When all metrics are equal, topConcern returns the first max, and with no trends, it falls back to stable message
        XCTAssertFalse(summary.isEmpty)
    }

    func testRenderProgressHighlightsNewBaseline() {
        let state = SkinStateSummary(overallScore: 50, highestRiskZone: nil, mostImprovedZone: nil, primaryConcern: nil, overallTrend: .unknown)
        let highlights = InsightTemplateRenderer.renderProgressHighlights(state: state, trends: [:])
        XCTAssertTrue(highlights.contains { $0.kind == .newBaseline })
    }

    func testRenderProgressHighlightsMostImproved() {
        let state = SkinStateSummary(overallScore: 50, highestRiskZone: .nose, mostImprovedZone: .forehead, primaryConcern: .redness, overallTrend: .improving)
        let highlights = InsightTemplateRenderer.renderProgressHighlights(state: state, trends: [.forehead: [EngineSkinTrend(metric: .redness, direction: .improving, delta: -20, severity: .significant, confidence: EngineConfidence(level: .high, reasons: []), comparedTo: .baseline)]])
        XCTAssertTrue(highlights.contains { $0.kind == .mostImproved })
        XCTAssertTrue(highlights.contains { $0.kind == .needsAttention })
    }
}

// MARK: - Skin Engine Integration Tests

final class SkinEngineIntegrationTests: XCTestCase {

    func testGenerateReportWithEmptyContext() {
        let context = SkinContext.emptyContext()
        let report = SkinEngine.generateReport(context: context)
        XCTAssertFalse(report.summary.isEmpty)
        XCTAssertEqual(report.zoneSummaries.count, 5) // default zones when nil map
        XCTAssertEqual(report.confidence.level, .low)
    }

    func testGenerateReportWithSampleData() {
        let map = SampleData.sampleSkinMap
        let context = SkinContext(latestScan: nil, baselineScan: nil, previousScan: nil, scansLastSevenDays: [], skinProfile: SkinProfile(), latestSkinMap: map, baselineSkinMap: nil, routineLogs: [], routineChanges: [], products: SampleData.defaultProducts, weatherSnapshot: nil, airQualitySnapshot: nil, latestCheckIn: nil, checkInHistory: [], hasCompletedOnboarding: true, isFirstTimeUser: false)
        let report = SkinEngine.generateReport(context: context)
        XCTAssertFalse(report.summary.isEmpty)
        XCTAssertEqual(report.zoneSummaries.count, 5)
        XCTAssertNotNil(report.skinState.highestRiskZone)
    }
}

// MARK: - Helpers

private extension SkinContext {
    static func emptyContext(
        products: [Product] = [],
        weather: DailyWeatherSnapshot? = nil,
        aqi: AirQualitySnapshot? = nil
    ) -> SkinContext {
        SkinContext(
            latestScan: nil,
            baselineScan: nil,
            previousScan: nil,
            scansLastSevenDays: [],
            skinProfile: SkinProfile(),
            latestSkinMap: nil,
            baselineSkinMap: nil,
            routineLogs: [],
            routineChanges: [],
            products: products,
            weatherSnapshot: weather,
            airQualitySnapshot: aqi,
            latestCheckIn: nil,
            checkInHistory: [],
            hasCompletedOnboarding: true,
            isFirstTimeUser: false
        )
    }
}
