import XCTest
@testable import Clera

// MARK: - NoOp AI Service Tests

final class NoOpAIServiceTests: XCTestCase {
    private let service = NoOpAIService()

    func testGenerateInsightThrowsServiceUnavailable() async {
        do {
            _ = try await service.generateInsight(context: .empty)
            XCTFail("Expected error")
        } catch let error as AIError {
            XCTAssertEqual(error, .serviceUnavailable)
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testAnswerQuestionThrowsServiceUnavailable() async {
        do {
            _ = try await service.answerQuestion(question: "Hello", context: .empty)
            XCTFail("Expected error")
        } catch let error as AIError {
            XCTAssertEqual(error, .serviceUnavailable)
        } catch {
            XCTFail("Unexpected error type")
        }
    }
}

// MARK: - Daily Advice Models Tests

final class SkinRiskLevelTests: XCTestCase {
    func testFromScoreLow() {
        XCTAssertEqual(SkinRiskLevel.from(score: 0), .low)
        XCTAssertEqual(SkinRiskLevel.from(score: 25), .low)
    }

    func testFromScoreModerate() {
        XCTAssertEqual(SkinRiskLevel.from(score: 26), .moderate)
        XCTAssertEqual(SkinRiskLevel.from(score: 50), .moderate)
    }

    func testFromScoreHigh() {
        XCTAssertEqual(SkinRiskLevel.from(score: 51), .high)
        XCTAssertEqual(SkinRiskLevel.from(score: 75), .high)
    }

    func testFromScoreExtreme() {
        XCTAssertEqual(SkinRiskLevel.from(score: 76), .extreme)
        XCTAssertEqual(SkinRiskLevel.from(score: 100), .extreme)
    }

    func testDisplayNames() {
        XCTAssertEqual(SkinRiskLevel.low.displayName, "Low Risk")
        XCTAssertEqual(SkinRiskLevel.extreme.displayName, "Extreme Risk")
    }

    func testColorHexValues() {
        XCTAssertEqual(SkinRiskLevel.low.colorHex, 0x99A744)
        XCTAssertEqual(SkinRiskLevel.moderate.colorHex, 0xD4A017)
    }

    func testSFSymbols() {
        XCTAssertEqual(SkinRiskLevel.low.sfSymbol, "checkmark.shield.fill")
        XCTAssertEqual(SkinRiskLevel.high.sfSymbol, "exclamationmark.octagon.fill")
    }
}

final class FactorSeverityTests: XCTestCase {
    func testScoreWeights() {
        XCTAssertEqual(FactorSeverity.mild.scoreWeight, 1)
        XCTAssertEqual(FactorSeverity.moderate.scoreWeight, 2)
        XCTAssertEqual(FactorSeverity.significant.scoreWeight, 3)
        XCTAssertEqual(FactorSeverity.severe.scoreWeight, 4)
    }
}

final class TimeOfDayTests: XCTestCase {
    func testDisplayNames() {
        XCTAssertEqual(TimeOfDay.morning.displayName, "Morning")
        XCTAssertEqual(TimeOfDay.night.displayName, "Tonight")
    }

    func testAdviceContext() {
        XCTAssertTrue(TimeOfDay.morning.adviceContext.contains("day ahead"))
        XCTAssertTrue(TimeOfDay.evening.adviceContext.contains("overnight"))
    }
}

final class DailyAdviceModelsCodableTests: XCTestCase {
    func testDailyWeatherSnapshotCodable() throws {
        let snapshot = DailyWeatherSnapshot(uvIndex: 5, temperatureCelsius: 22, humidityPercent: 60, windSpeedKmh: 10, condition: .partlyCloudy)
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(DailyWeatherSnapshot.self, from: data)
        XCTAssertEqual(decoded.uvIndex, 5)
        XCTAssertEqual(decoded.condition, .partlyCloudy)
    }

    func testAirQualitySnapshotCodable() throws {
        let snapshot = AirQualitySnapshot(aqi: 45, pm25: 12.5, dominantPollutant: "PM2.5")
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(AirQualitySnapshot.self, from: data)
        XCTAssertEqual(decoded.aqi, 45)
        XCTAssertEqual(decoded.pm25, 12.5)
    }

    func testEnvironmentFactorCodable() throws {
        let factor = EnvironmentFactor(kind: .uv, severity: .significant, description: "High UV", recommendation: "Wear SPF")
        let data = try JSONEncoder().encode(factor)
        let decoded = try JSONDecoder().decode(EnvironmentFactor.self, from: data)
        XCTAssertEqual(decoded.kind, .uv)
        XCTAssertEqual(decoded.severity, .significant)
    }

    func testScanContextCodable() throws {
        let context = ScanContext(daysSinceLastScan: 3, latestScanDate: nil, hasRecentIrritation: true, hasRecentBreakouts: false, hasRecentDryness: false, worseningZones: [.forehead])
        let data = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(ScanContext.self, from: data)
        XCTAssertEqual(decoded.daysSinceLastScan, 3)
        XCTAssertTrue(decoded.hasRecentIrritation)
    }

    func testRoutineContextCodable() throws {
        let context = RoutineContext(adherenceThisWeek: 0.85, missedDaysCount: 1, recentlyUsedExfoliant: false, recentlyUsedRetinol: true, spfPresentInRoutine: true)
        let data = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(RoutineContext.self, from: data)
        XCTAssertEqual(decoded.adherenceThisWeek, 0.85)
        XCTAssertTrue(decoded.spfPresentInRoutine)
    }

    func testDailyAdviceWidgetPayloadCodable() throws {
        let payload = DailyAdviceWidgetPayload(generatedAt: .now, result: nil, history: [])
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(DailyAdviceWidgetPayload.self, from: data)
        XCTAssertEqual(decoded.version, 1)
    }
}
