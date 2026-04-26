import XCTest
@testable import Clera

final class DailySkinAdviceEngineTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear widget store temp directory to prevent stale data between test runs
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("clera-widget-tests")
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Risk Scorer Tests

    func testScoreUVLow() {
        XCTAssertEqual(SkinRiskScorer.scoreUV(0), 0)
        XCTAssertEqual(SkinRiskScorer.scoreUV(2), 0)
        XCTAssertEqual(SkinRiskScorer.scoreUV(2.5), 5)
    }

    func testScoreUVModerate() {
        XCTAssertEqual(SkinRiskScorer.scoreUV(4), 15)
        XCTAssertEqual(SkinRiskScorer.scoreUV(6), 25)
    }

    func testScoreUVHigh() {
        XCTAssertEqual(SkinRiskScorer.scoreUV(8), 35)
        XCTAssertEqual(SkinRiskScorer.scoreUV(11), 40)
        XCTAssertEqual(SkinRiskScorer.scoreUV(12), 40)
    }

    func testScoreHumidity() {
        XCTAssertEqual(SkinRiskScorer.scoreHumidity(15, skinType: .normal), 20)
        XCTAssertEqual(SkinRiskScorer.scoreHumidity(25, skinType: .normal), 15)
        XCTAssertEqual(SkinRiskScorer.scoreHumidity(35, skinType: .normal), 10)
        XCTAssertEqual(SkinRiskScorer.scoreHumidity(55, skinType: .normal), 0)
        XCTAssertEqual(SkinRiskScorer.scoreHumidity(75, skinType: .normal), 5)
        XCTAssertEqual(SkinRiskScorer.scoreHumidity(90, skinType: .normal), 8)
    }

    func testScoreHumidityDrySkinBoost() {
        // Dry skin gets a +3 boost in low humidity, capped at 20
        let dryLow = SkinRiskScorer.scoreHumidity(25, skinType: .dry)
        let normalLow = SkinRiskScorer.scoreHumidity(25, skinType: .normal)
        XCTAssertEqual(dryLow, min(normalLow + 3, 20))
    }

    func testScoreHumidityOilySkinBoost() {
        // Oily skin gets a +3 boost in high humidity
        let oilyHigh = SkinRiskScorer.scoreHumidity(75, skinType: .oily)
        let normalHigh = SkinRiskScorer.scoreHumidity(75, skinType: .normal)
        XCTAssertEqual(oilyHigh, min(normalHigh + 3, 20))
    }

    func testScoreTemperature() {
        XCTAssertEqual(SkinRiskScorer.scoreTemperature(2), 15)
        XCTAssertEqual(SkinRiskScorer.scoreTemperature(8), 10)
        XCTAssertEqual(SkinRiskScorer.scoreTemperature(20), 0)
        XCTAssertEqual(SkinRiskScorer.scoreTemperature(30), 10)
        XCTAssertEqual(SkinRiskScorer.scoreTemperature(35), 15)
    }

    func testScoreWind() {
        XCTAssertEqual(SkinRiskScorer.scoreWind(10), 0)
        XCTAssertEqual(SkinRiskScorer.scoreWind(20), 3)
        XCTAssertEqual(SkinRiskScorer.scoreWind(30), 5)
        XCTAssertEqual(SkinRiskScorer.scoreWind(50), 10)
    }

    func testScoreAirQuality() {
        XCTAssertEqual(SkinRiskScorer.scoreAirQuality(30), 0)
        XCTAssertEqual(SkinRiskScorer.scoreAirQuality(75), 3)
        XCTAssertEqual(SkinRiskScorer.scoreAirQuality(120), 7)
        XCTAssertEqual(SkinRiskScorer.scoreAirQuality(160), 10)
    }

    func testScoreSkinProfile() {
        let weather = DailyWeatherSnapshot(uvIndex: 3, temperatureCelsius: 20, humidityPercent: 50, windSpeedKmh: 10, condition: .clear)
        XCTAssertEqual(SkinRiskScorer.scoreSkinProfile(SkinProfile(sensitivity: .none), weather: weather), 0)
        XCTAssertEqual(SkinRiskScorer.scoreSkinProfile(SkinProfile(sensitivity: .reactive), weather: weather), 8)
    }

    func testScoreSkinProfileRednessAndHighUV() {
        let highUVWeather = DailyWeatherSnapshot(uvIndex: 7, temperatureCelsius: 20, humidityPercent: 50, windSpeedKmh: 10, condition: .clear)
        let profile = SkinProfile(sensitivity: .mild, primaryConcerns: [.redness])
        XCTAssertEqual(SkinRiskScorer.scoreSkinProfile(profile, weather: highUVWeather), 4) // mild(2) + redness+UV(2)
    }

    func testScoreScanTrend() {
        let ctx = ScanContext(daysSinceLastScan: 2, latestScanDate: .now, hasRecentIrritation: true, hasRecentBreakouts: true, hasRecentDryness: true, worseningZones: [.chinJaw])
        XCTAssertEqual(SkinRiskScorer.scoreScanTrend(ctx), 8)
    }

    func testScoreRoutine() {
        let lowAdherence = RoutineContext(adherenceThisWeek: 0.3, missedDaysCount: 3, recentlyUsedExfoliant: false, recentlyUsedRetinol: false, spfPresentInRoutine: true)
        XCTAssertEqual(SkinRiskScorer.scoreRoutine(lowAdherence), 2)

        let exfoliantNoSPF = RoutineContext(adherenceThisWeek: 0.8, missedDaysCount: 0, recentlyUsedExfoliant: true, recentlyUsedRetinol: false, spfPresentInRoutine: false)
        XCTAssertEqual(SkinRiskScorer.scoreRoutine(exfoliantNoSPF), 3)
    }

    func testRiskLevelFromScore() {
        XCTAssertEqual(SkinRiskLevel.from(score: 0), .low)
        XCTAssertEqual(SkinRiskLevel.from(score: 25), .low)
        XCTAssertEqual(SkinRiskLevel.from(score: 26), .moderate)
        XCTAssertEqual(SkinRiskLevel.from(score: 50), .moderate)
        XCTAssertEqual(SkinRiskLevel.from(score: 51), .high)
        XCTAssertEqual(SkinRiskLevel.from(score: 75), .high)
        XCTAssertEqual(SkinRiskLevel.from(score: 76), .extreme)
        XCTAssertEqual(SkinRiskLevel.from(score: 100), .extreme)
    }

    func testTotalScoreCappedAt100() {
        let weather = DailyWeatherSnapshot(uvIndex: 12, temperatureCelsius: 40, humidityPercent: 10, windSpeedKmh: 60, condition: .clear)
        let aq = AirQualitySnapshot(aqi: 200, pm25: 100, dominantPollutant: "PM2.5")
        let profile = SkinProfile(skinType: .dry, sensitivity: .reactive, primaryConcerns: [.redness, .breakouts])
        let scan = ScanContext(daysSinceLastScan: 10, latestScanDate: .now, hasRecentIrritation: true, hasRecentBreakouts: true, hasRecentDryness: true, worseningZones: [.chinJaw, .forehead])
        let routine = RoutineContext(adherenceThisWeek: 0.2, missedDaysCount: 5, recentlyUsedExfoliant: true, recentlyUsedRetinol: true, spfPresentInRoutine: false)

        let inputs = SkinRiskScorer.RiskInputs(weather: weather, airQuality: aq, skinProfile: profile, scanContext: scan, routineContext: routine)
        let breakdown = SkinRiskScorer.calculate(inputs: inputs)
        XCTAssertEqual(breakdown.totalScore, 100)
    }

    // MARK: - Engine Integration Tests

    func testHighUVDayAdvice() async {
        let inputs = defaultEngineInputs()
        let env = compositeProvider(scenario: .highUV)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertGreaterThanOrEqual(advice.riskScore, 25)
        XCTAssertTrue(advice.primaryAdvice.localizedCaseInsensitiveContains("UV") || advice.primaryAdvice.localizedCaseInsensitiveContains("SPF"))
        XCTAssertTrue(advice.dataSourcesUsed.contains("Current weather data"))
    }

    func testLowHumidityDryWeatherAdvice() async {
        let inputs = defaultEngineInputs()
        let env = compositeProvider(scenario: .lowHumidity)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertGreaterThanOrEqual(advice.riskScore, 15)
        XCTAssertTrue(advice.primaryAdvice.localizedCaseInsensitiveContains("dry") || advice.primaryAdvice.localizedCaseInsensitiveContains("humid"))
    }

    func testPoorAirQualityAdvice() async {
        let inputs = defaultEngineInputs()
        let env = compositeProvider(scenario: .poorAirQuality)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertTrue(advice.primaryAdvice.localizedCaseInsensitiveContains("air") || advice.primaryAdvice.localizedCaseInsensitiveContains("pollution") || advice.primaryAdvice.localizedCaseInsensitiveContains("cleanse"))
        XCTAssertTrue(advice.environmentFactors.contains(where: { $0.kind == .airQuality }))
    }

    func testHighWindAdvice() async {
        let inputs = defaultEngineInputs()
        let env = compositeProvider(scenario: .highWind)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertTrue(advice.environmentFactors.contains(where: { $0.kind == .wind }))
    }

    func testRecentIrritationScanAdvice() async {
        var inputs = defaultEngineInputs()
        let irritatedMap = SkinMap(zones: SampleData.sampleSkinMap.zones, checkIn: SkinMapCheckIn(followedRoutine: true, newProducts: false, hadIrritation: true, hadDryness: false, hadBreakouts: false, notes: nil))
        let session = ScanSession(kind: .daily, photos: [], skinMap: irritatedMap, note: nil)
        inputs = DailySkinAdviceEngine.EngineInputs(
            skinProfile: inputs.skinProfile,
            latestSkinMap: irritatedMap,
            sessions: [session],
            routineLogs: inputs.routineLogs,
            currentProducts: inputs.currentProducts,
            timeOfDay: .evening
        )
        let env = compositeProvider(scenario: .pleasant)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertTrue(advice.scanContext?.hasRecentIrritation == true)
        XCTAssertTrue(advice.primaryAdvice.localizedCaseInsensitiveContains("irritation") || advice.primaryAdvice.localizedCaseInsensitiveContains("soothe") || advice.primaryAdvice.localizedCaseInsensitiveContains("repair"))
    }

    func testMissedRoutineAdherenceAdvice() async {
        var inputs = defaultEngineInputs()
        inputs = DailySkinAdviceEngine.EngineInputs(
            skinProfile: inputs.skinProfile,
            latestSkinMap: inputs.latestSkinMap,
            sessions: inputs.sessions,
            routineLogs: [],
            currentProducts: inputs.currentProducts,
            timeOfDay: .morning
        )
        let env = compositeProvider(scenario: .pleasant)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertEqual(advice.routineContext?.adherenceThisWeek, 0)
        XCTAssertTrue(advice.primaryAdvice.localizedCaseInsensitiveContains("routine") || advice.primaryAdvice.localizedCaseInsensitiveContains("consistency") || advice.secondaryAdvice.localizedCaseInsensitiveContains("consistency"))
    }

    func testExfoliantUsedRecentlyAdvice() async {
        let exfoliant = Product(name: "Glycolic Toner", category: .toner, period: .evening, ingredientTags: [.aha])
        var inputs = defaultEngineInputs()
        let log = RoutineLogEntry(date: .now, followedRoutine: true, productIDs: [exfoliant.id], notes: nil)
        inputs = DailySkinAdviceEngine.EngineInputs(
            skinProfile: inputs.skinProfile,
            latestSkinMap: inputs.latestSkinMap,
            sessions: inputs.sessions,
            routineLogs: [log],
            currentProducts: [exfoliant],
            timeOfDay: .morning
        )
        let env = compositeProvider(scenario: .pleasant)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertTrue(advice.routineContext?.recentlyUsedExfoliant == true)
        XCTAssertTrue(advice.primaryAdvice.localizedCaseInsensitiveContains("exfoliant") || advice.primaryAdvice.localizedCaseInsensitiveContains("SPF") || advice.primaryAdvice.localizedCaseInsensitiveContains("active"))
    }

    func testNoWeatherDataFallback() async {
        let inputs = defaultEngineInputs()
        let env = CompositeEnvironmentProvider(
            weather: PlaceholderWeatherProvider(),
            uv: PlaceholderUVProvider(),
            airQuality: PlaceholderAirQualityProvider()
        )
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertEqual(advice.confidence, .low)
        XCTAssertEqual(advice.weatherSnapshot?.uvIndex, 0)
        XCTAssertTrue(advice.primaryAdvice.count > 0)
    }

    func testNoScanHistoryAvailable() async {
        var inputs = defaultEngineInputs()
        inputs = DailySkinAdviceEngine.EngineInputs(
            skinProfile: inputs.skinProfile,
            latestSkinMap: nil,
            sessions: [],
            routineLogs: inputs.routineLogs,
            currentProducts: inputs.currentProducts,
            timeOfDay: .morning
        )
        let env = compositeProvider(scenario: .pleasant)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertEqual(advice.scanContext?.daysSinceLastScan, 999)
        XCTAssertNil(advice.scanContext?.latestScanDate)
        XCTAssertEqual(advice.confidence, .low)
    }

    func testTimeOfDayMorningAdvice() async {
        var inputs = defaultEngineInputs()
        inputs = DailySkinAdviceEngine.EngineInputs(
            skinProfile: inputs.skinProfile,
            latestSkinMap: inputs.latestSkinMap,
            sessions: inputs.sessions,
            routineLogs: inputs.routineLogs,
            currentProducts: inputs.currentProducts,
            timeOfDay: .morning
        )
        let env = compositeProvider(scenario: .highUV)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertEqual(advice.timeOfDay, .morning)
        XCTAssertTrue(advice.recommendedActions.contains(where: { $0.timeContext == .morning }))
    }

    func testTimeOfDayEveningAdvice() async {
        var inputs = defaultEngineInputs()
        inputs = DailySkinAdviceEngine.EngineInputs(
            skinProfile: inputs.skinProfile,
            latestSkinMap: inputs.latestSkinMap,
            sessions: inputs.sessions,
            routineLogs: inputs.routineLogs,
            currentProducts: inputs.currentProducts,
            timeOfDay: .evening
        )
        let env = compositeProvider(scenario: .pleasant)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertEqual(advice.timeOfDay, .evening)
        XCTAssertTrue(advice.recommendedActions.contains(where: { $0.timeContext == .evening }))
    }

    func testWidgetPayloadGeneration() async {
        let inputs = defaultEngineInputs()
        let env = compositeProvider(scenario: .pleasant)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        DailyAdviceWidgetStore.write(result: advice)
        let payload = DailyAdviceWidgetStore.read()

        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.version, 1)
        XCTAssertNotNil(payload?.result)
        XCTAssertEqual(payload?.result?.riskScore, advice.riskScore)
        XCTAssertEqual(payload?.result?.primaryAdvice, advice.primaryAdvice)
    }

    func testWidgetPayloadStaleDataRejection() async {
        let advice = await DailySkinAdviceEngine.generateAdvice(
            inputs: defaultEngineInputs(),
            environment: compositeProvider(scenario: .pleasant)
        )
        DailyAdviceWidgetStore.write(result: advice)

        // Manually backdate the payload by rewriting with old date
        let stalePayload = DailyAdviceWidgetPayload(version: 1, generatedAt: Calendar.current.date(byAdding: .hour, value: -25, to: .now) ?? .now, result: advice, history: [])
        DailyAdviceWidgetStore.writeForTest(payload: stalePayload)

        let readPayload = DailyAdviceWidgetStore.read()
        XCTAssertNil(readPayload)
    }

    func testZoneSpecificRecommendations() async {
        let breakoutMap = SkinMap(zones: [
            FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: .low, redness: .none)),
            FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: .low, redness: .none)),
            FaceZone(zoneType: .leftCheek, status: ZoneStatus(breakouts: .none, redness: .none)),
            FaceZone(zoneType: .rightCheek, status: ZoneStatus(breakouts: .none, redness: .none)),
            FaceZone(zoneType: .chinJaw, status: ZoneStatus(breakouts: .high, redness: .moderate))
        ], checkIn: SkinMapCheckIn(followedRoutine: true, newProducts: false, hadIrritation: false, hadDryness: false, hadBreakouts: true, notes: nil))
        let session = ScanSession(kind: .daily, photos: [], skinMap: breakoutMap, note: nil)

        var inputs = defaultEngineInputs()
        inputs = DailySkinAdviceEngine.EngineInputs(
            skinProfile: inputs.skinProfile,
            latestSkinMap: breakoutMap,
            sessions: [session],
            routineLogs: inputs.routineLogs,
            currentProducts: inputs.currentProducts,
            timeOfDay: .evening
        )
        let env = compositeProvider(scenario: .pleasant)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertTrue(advice.affectedZones.contains(.chinJaw))
        XCTAssertTrue(advice.scanContext?.hasRecentBreakouts == true)
    }

    func testProviderMockScenarios() async {
        for scenario in MockWeatherProvider.MockWeatherScenario.allCases {
            let provider = MockWeatherProvider(scenario: scenario)
            let weather = await provider.fetchCurrent()
            XCTAssertGreaterThanOrEqual(weather.uvIndex, 0)
            XCTAssertGreaterThanOrEqual(weather.humidityPercent, 0)
            XCTAssertLessThanOrEqual(weather.humidityPercent, 100)
        }
    }

    func testColdDryDayAdvice() async {
        let inputs = defaultEngineInputs()
        let env = compositeProvider(scenario: .coldDry)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertGreaterThanOrEqual(advice.riskScore, 15)
        XCTAssertTrue(advice.environmentFactors.contains(where: { $0.kind == .temperature }) || advice.environmentFactors.contains(where: { $0.kind == .humidity }))
    }

    func testHeatSpikeAdvice() async {
        let inputs = defaultEngineInputs()
        let env = compositeProvider(scenario: .heatSpike)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertGreaterThanOrEqual(advice.riskScore, 10)
        XCTAssertTrue(advice.environmentFactors.contains(where: { $0.kind == .temperature }))
    }

    func testRainyDayAdvice() async {
        let inputs = defaultEngineInputs()
        let env = compositeProvider(scenario: .rainy)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertLessThan(advice.riskScore, 30)
        XCTAssertTrue(advice.weatherSnapshot?.condition == .rain)
    }

    func testRetinolMorningAdvice() async {
        let retinol = Product(name: "Retinol 0.5%", category: .treatment, period: .evening, ingredientTags: [.retinol])
        let log = RoutineLogEntry(date: .now, followedRoutine: true, productIDs: [retinol.id], notes: nil)
        var inputs = defaultEngineInputs()
        inputs = DailySkinAdviceEngine.EngineInputs(
            skinProfile: inputs.skinProfile,
            latestSkinMap: inputs.latestSkinMap,
            sessions: inputs.sessions,
            routineLogs: [log],
            currentProducts: [retinol],
            timeOfDay: .morning
        )
        let env = compositeProvider(scenario: .pleasant)
        let advice = await DailySkinAdviceEngine.generateAdvice(inputs: inputs, environment: env)

        XCTAssertTrue(advice.routineContext?.recentlyUsedRetinol == true)
        XCTAssertTrue(advice.primaryAdvice.localizedCaseInsensitiveContains("exfoliant") || advice.primaryAdvice.localizedCaseInsensitiveContains("SPF") || advice.primaryAdvice.localizedCaseInsensitiveContains("retinol"))
    }

    // MARK: - Helpers

    private func defaultEngineInputs() -> DailySkinAdviceEngine.EngineInputs {
        DailySkinAdviceEngine.EngineInputs(
            skinProfile: SkinProfile(),
            latestSkinMap: SampleData.sampleSkinMap,
            sessions: [ScanSession(kind: .baseline, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)],
            routineLogs: [],
            currentProducts: SampleData.defaultProducts,
            timeOfDay: .morning
        )
    }

    private func compositeProvider(scenario: MockWeatherProvider.MockWeatherScenario) -> CompositeEnvironmentProvider {
        CompositeEnvironmentProvider(
            weather: MockWeatherProvider(scenario: scenario),
            uv: MockUVProvider(scenario: scenario),
            airQuality: MockAirQualityProvider(scenario: scenario)
        )
    }
}
