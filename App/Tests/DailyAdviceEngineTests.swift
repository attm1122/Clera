import XCTest
@testable import Clera

// MARK: - Skin Risk Scorer Tests

final class SkinRiskScorerTests: XCTestCase {

    private func makeInputs(
        uvIndex: Double = 3,
        humidity: Double = 50,
        temp: Double = 22,
        wind: Double = 10,
        aqi: Int = 30,
        skinType: SkinType = .combination,
        sensitivity: Sensitivity = .mild,
        concerns: [SkinConcern] = [],
        hasIrritation: Bool = false,
        hasBreakouts: Bool = false,
        hasDryness: Bool = false,
        worseningZones: [ZoneType] = [],
        daysSinceScan: Int = 2,
        adherence: Double = 0.8,
        missedDays: Int = 0,
        usedExfoliant: Bool = false,
        usedRetinol: Bool = false,
        spfPresent: Bool = true
    ) -> SkinRiskScorer.RiskInputs {
        SkinRiskScorer.RiskInputs(
            weather: DailyWeatherSnapshot(uvIndex: uvIndex, temperatureCelsius: temp, humidityPercent: humidity, windSpeedKmh: wind, condition: .clear),
            airQuality: AirQualitySnapshot(aqi: aqi, pm25: nil, dominantPollutant: nil),
            skinProfile: SkinProfile(skinType: skinType, sensitivity: sensitivity, primaryConcerns: concerns),
            scanContext: ScanContext(daysSinceLastScan: daysSinceScan, latestScanDate: nil, hasRecentIrritation: hasIrritation, hasRecentBreakouts: hasBreakouts, hasRecentDryness: hasDryness, worseningZones: worseningZones),
            routineContext: RoutineContext(adherenceThisWeek: adherence, missedDaysCount: missedDays, recentlyUsedExfoliant: usedExfoliant, recentlyUsedRetinol: usedRetinol, spfPresentInRoutine: spfPresent)
        )
    }

    func testScoreUVLow() {
        XCTAssertEqual(SkinRiskScorer.scoreUV(1), 0)
        XCTAssertEqual(SkinRiskScorer.scoreUV(2), 0)
    }

    func testScoreUVMedium() {
        XCTAssertEqual(SkinRiskScorer.scoreUV(4), 15)
        XCTAssertEqual(SkinRiskScorer.scoreUV(6), 25)
    }

    func testScoreUVHigh() {
        XCTAssertEqual(SkinRiskScorer.scoreUV(8), 35)
        XCTAssertEqual(SkinRiskScorer.scoreUV(11), 40)
    }

    func testScoreHumidityOptimal() {
        XCTAssertEqual(SkinRiskScorer.scoreHumidity(50, skinType: .dry), 0)
    }

    func testScoreHumidityLowDrySkin() {
        XCTAssertEqual(SkinRiskScorer.scoreHumidity(20, skinType: .dry), 20)
    }

    func testScoreHumidityHighOilySkin() {
        XCTAssertEqual(SkinRiskScorer.scoreHumidity(80, skinType: .oily), 8)
    }

    func testScoreTemperatureComfortable() {
        XCTAssertEqual(SkinRiskScorer.scoreTemperature(20), 0)
    }

    func testScoreTemperatureCold() {
        XCTAssertEqual(SkinRiskScorer.scoreTemperature(0), 15)
    }

    func testScoreTemperatureHot() {
        XCTAssertEqual(SkinRiskScorer.scoreTemperature(30), 10)
    }

    func testScoreWindCalm() {
        XCTAssertEqual(SkinRiskScorer.scoreWind(5), 0)
    }

    func testScoreWindStrong() {
        XCTAssertEqual(SkinRiskScorer.scoreWind(30), 5)
        XCTAssertEqual(SkinRiskScorer.scoreWind(50), 10)
    }

    func testScoreAirQualityGood() {
        XCTAssertEqual(SkinRiskScorer.scoreAirQuality(30), 0)
    }

    func testScoreAirQualityPoor() {
        XCTAssertEqual(SkinRiskScorer.scoreAirQuality(120), 7)
        XCTAssertEqual(SkinRiskScorer.scoreAirQuality(200), 10)
    }

    func testScoreSkinProfileSensitive() {
        let profile = SkinProfile(skinType: .normal, sensitivity: .reactive, primaryConcerns: [])
        let weather = DailyWeatherSnapshot(uvIndex: 1, temperatureCelsius: 20, humidityPercent: 50, windSpeedKmh: 5, condition: .clear)
        XCTAssertEqual(SkinRiskScorer.scoreSkinProfile(profile, weather: weather), 8)
    }

    func testScoreSkinProfileDryAndLowHumidity() {
        let profile = SkinProfile(skinType: .dry, sensitivity: .none, primaryConcerns: [])
        let weather = DailyWeatherSnapshot(uvIndex: 1, temperatureCelsius: 20, humidityPercent: 30, windSpeedKmh: 5, condition: .clear)
        XCTAssertEqual(SkinRiskScorer.scoreSkinProfile(profile, weather: weather), 2)
    }

    func testScoreScanTrendAllFlags() {
        let context = ScanContext(daysSinceLastScan: 10, latestScanDate: nil, hasRecentIrritation: true, hasRecentBreakouts: true, hasRecentDryness: true, worseningZones: [.forehead])
        XCTAssertEqual(SkinRiskScorer.scoreScanTrend(context), 8)
    }

    func testScoreRoutineLowAdherence() {
        let context = RoutineContext(adherenceThisWeek: 0.3, missedDaysCount: 4, recentlyUsedExfoliant: false, recentlyUsedRetinol: false, spfPresentInRoutine: true)
        XCTAssertEqual(SkinRiskScorer.scoreRoutine(context), 2)
    }

    func testScoreRoutineExfoliantNoSPF() {
        let context = RoutineContext(adherenceThisWeek: 1.0, missedDaysCount: 0, recentlyUsedExfoliant: true, recentlyUsedRetinol: false, spfPresentInRoutine: false)
        XCTAssertEqual(SkinRiskScorer.scoreRoutine(context), 3)
    }

    func testCalculateTotalScoreCapped() {
        let inputs = makeInputs(uvIndex: 12, humidity: 10, temp: 35, wind: 60, aqi: 200, skinType: .dry, sensitivity: .reactive, concerns: [.redness], hasIrritation: true, hasBreakouts: true, hasDryness: true, worseningZones: [.forehead], daysSinceScan: 10, adherence: 0.3, usedExfoliant: true, spfPresent: false)
        let breakdown = SkinRiskScorer.calculate(inputs: inputs)
        XCTAssertEqual(breakdown.totalScore, 100)
        XCTAssertEqual(breakdown.level, .extreme)
    }

    func testCalculateLowRisk() {
        let inputs = makeInputs()
        let breakdown = SkinRiskScorer.calculate(inputs: inputs)
        XCTAssertLessThan(breakdown.totalScore, 50)
        XCTAssertEqual(breakdown.level, .low)
    }
}

// MARK: - Advice Copy Engine Tests

final class AdviceCopyEngineTests: XCTestCase {

    private func makeInputs(
        uvScore: Int = 0,
        humidityScore: Int = 0,
        tempScore: Int = 0,
        windScore: Int = 0,
        aqScore: Int = 0,
        skinProfileScore: Int = 0,
        scanScore: Int = 0,
        routineScore: Int = 0,
        time: TimeOfDay = .morning,
        uvIndex: Double = 1,
        humidity: Double = 50,
        temp: Double = 22,
        wind: Double = 5,
        aqi: Int = 30,
        skinType: SkinType = .combination,
        hasIrritation: Bool = false,
        hasBreakouts: Bool = false,
        hasDryness: Bool = false,
        worseningZones: [ZoneType] = [],
        daysSinceScan: Int = 2,
        adherence: Double = 0.8,
        usedExfoliant: Bool = false,
        usedRetinol: Bool = false,
        spfPresent: Bool = true
    ) -> AdviceCopyEngine.CopyInputs {
        let total = uvScore + humidityScore + tempScore + windScore + aqScore + skinProfileScore + scanScore + routineScore
        let breakdown = SkinRiskScorer.RiskBreakdown(
            uvScore: uvScore, humidityScore: humidityScore, temperatureScore: tempScore,
            windScore: windScore, airQualityScore: aqScore, skinProfileScore: skinProfileScore,
            scanTrendScore: scanScore, routineScore: routineScore,
            totalScore: total, level: SkinRiskLevel.from(score: total)
        )
        return AdviceCopyEngine.CopyInputs(
            riskBreakdown: breakdown,
            timeOfDay: time,
            weather: DailyWeatherSnapshot(uvIndex: uvIndex, temperatureCelsius: temp, humidityPercent: humidity, windSpeedKmh: wind, condition: .clear),
            airQuality: AirQualitySnapshot(aqi: aqi, pm25: nil, dominantPollutant: nil),
            skinProfile: SkinProfile(skinType: skinType, sensitivity: .mild, primaryConcerns: []),
            scanContext: ScanContext(daysSinceLastScan: daysSinceScan, latestScanDate: nil, hasRecentIrritation: hasIrritation, hasRecentBreakouts: hasBreakouts, hasRecentDryness: hasDryness, worseningZones: worseningZones),
            routineContext: RoutineContext(adherenceThisWeek: adherence, missedDaysCount: 0, recentlyUsedExfoliant: usedExfoliant, recentlyUsedRetinol: usedRetinol, spfPresentInRoutine: spfPresent)
        )
    }

    func testPrimaryAdviceUVHighMorning() {
        let inputs = makeInputs(uvScore: 30, time: .morning, uvIndex: 9)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.primaryAdvice.contains("UV is high"))
    }

    func testPrimaryAdviceUVHighNight() {
        let inputs = makeInputs(uvScore: 30, time: .night, uvIndex: 9)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.primaryAdvice.contains("UV was high"))
    }

    func testPrimaryAdviceDryness() {
        let inputs = makeInputs(humidityScore: 20, humidity: 15, skinType: .dry)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.primaryAdvice.contains("dryness"))
    }

    func testPrimaryAdviceHeatBreakouts() {
        let inputs = makeInputs(tempScore: 15, temp: 35, skinType: .oily)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.primaryAdvice.contains("breakouts") || copy.primaryAdvice.contains("oil"))
    }

    func testPrimaryAdviceIrritation() {
        let inputs = makeInputs(hasIrritation: true)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.primaryAdvice.contains("irritation"))
    }

    func testPrimaryAdviceAirQuality() {
        let inputs = makeInputs(aqScore: 10, aqi: 150)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.primaryAdvice.contains("air quality"))
    }

    func testPrimaryAdviceRetinolMorning() {
        let inputs = makeInputs(time: .morning, usedRetinol: true)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.primaryAdvice.contains("exfoliant") || copy.primaryAdvice.contains("SPF"))
    }

    func testPrimaryAdviceWind() {
        let inputs = makeInputs(windScore: 10, wind: 50)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.primaryAdvice.contains("wind"))
    }

    func testPrimaryAdviceLowAdherence() {
        let inputs = makeInputs(routineScore: 3, adherence: 0.3)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.primaryAdvice.contains("consistency"))
    }

    func testPrimaryAdviceDefault() {
        let inputs = makeInputs()
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertFalse(copy.primaryAdvice.isEmpty)
    }

    func testSecondaryAdviceModerateUV() {
        let inputs = makeInputs(uvScore: 20, uvIndex: 6)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.secondaryAdvice.contains("UV is moderate"))
    }

    func testSecondaryAdviceScanGap() {
        let inputs = makeInputs(daysSinceScan: 5)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.secondaryAdvice.contains("scan"))
    }

    func testSecondaryAdviceDefault() {
        let inputs = makeInputs()
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertFalse(copy.secondaryAdvice.isEmpty)
    }

    func testActionsMorningUV() {
        let inputs = makeInputs(uvScore: 20, time: .morning, uvIndex: 7)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.actions.contains(where: { $0.title == "Apply SPF" }))
    }

    func testActionsEveningIrritation() {
        let inputs = makeInputs(time: .evening, hasIrritation: true)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.actions.contains(where: { $0.title == "Soothe and repair" }))
    }

    func testActionsNightSleep() {
        let inputs = makeInputs(time: .night)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.actions.contains(where: { $0.title == "Get good sleep" }))
    }

    func testActionsSortedByPriority() {
        let inputs = makeInputs(uvScore: 20, time: .morning, uvIndex: 7, humidity: 20, skinType: .dry)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        let priorities = copy.actions.map { $0.priority }
        for i in 0..<(priorities.count - 1) {
            let current = priorities[i]
            let next = priorities[i + 1]
            let currentOrder: Int = { switch current { case .essential: 0; case .recommended: 1; case .optional: 2 } }()
            let nextOrder: Int = { switch next { case .essential: 0; case .recommended: 1; case .optional: 2 } }()
            XCTAssertLessThanOrEqual(currentOrder, nextOrder)
        }
    }

    func testAffectedZonesDefault() {
        let inputs = makeInputs()
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertEqual(copy.affectedZones.count, 5)
    }

    func testAffectedZonesBreakouts() {
        let inputs = makeInputs(hasBreakouts: true)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.affectedZones.contains(.chinJaw))
        XCTAssertTrue(copy.affectedZones.contains(.forehead))
    }

    func testEnvironmentFactorsUV() {
        let inputs = makeInputs(uvIndex: 9)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.factors.contains(where: { $0.kind == .uv }))
    }

    func testEnvironmentFactorsHumidityLow() {
        let inputs = makeInputs(humidity: 15)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.factors.contains(where: { $0.kind == .humidity }))
    }

    func testEnvironmentFactorsHumidityHigh() {
        let inputs = makeInputs(humidity: 90)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.factors.contains(where: { $0.kind == .humidity }))
    }

    func testEnvironmentFactorsTemperatureHigh() {
        let inputs = makeInputs(temp: 40)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.factors.contains(where: { $0.kind == .temperature }))
    }

    func testEnvironmentFactorsTemperatureLow() {
        let inputs = makeInputs(temp: -5)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.factors.contains(where: { $0.kind == .temperature }))
    }

    func testEnvironmentFactorsWind() {
        let inputs = makeInputs(wind: 40)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.factors.contains(where: { $0.kind == .wind }))
    }

    func testEnvironmentFactorsAirQuality() {
        let inputs = makeInputs(aqi: 120)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.factors.contains(where: { $0.kind == .airQuality }))
    }

    func testDataSources() {
        let inputs = makeInputs(daysSinceScan: 5)
        let copy = AdviceCopyEngine.generate(inputs: inputs)
        XCTAssertTrue(copy.dataSources.contains("Current weather data"))
        XCTAssertTrue(copy.dataSources.contains("Skin profile"))
        XCTAssertTrue(copy.dataSources.contains("Time of day"))
    }
}
