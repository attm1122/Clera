import XCTest
@testable import Clera

// MARK: - Models Tests

/// Tests for Models.swift computed properties, logic, and Codable conformance.
/// Focuses on behavior, not trivial struct initialization.
final class ModelsTests: XCTestCase {

    // MARK: - ZoneStatus

    func testZoneStatusOverallSeverityHigh() {
        let status = ZoneStatus(breakouts: .high, redness: .none, dryness: .none, texture: .none, congestion: .none, irritation: .none)
        XCTAssertEqual(status.overallSeverity, .high)
    }

    func testZoneStatusOverallSeverityModerate() {
        let status = ZoneStatus(breakouts: .low, redness: .moderate, dryness: .none, texture: .none, congestion: .none, irritation: .none)
        XCTAssertEqual(status.overallSeverity, .moderate)
    }

    func testZoneStatusOverallSeverityLow() {
        let status = ZoneStatus(breakouts: .low, redness: .none, dryness: .none, texture: .none, congestion: .none, irritation: .none)
        XCTAssertEqual(status.overallSeverity, .low)
    }

    func testZoneStatusOverallSeverityNone() {
        let status = ZoneStatus(breakouts: .none, redness: .none, dryness: .none, texture: .none, congestion: .none, irritation: .none)
        XCTAssertEqual(status.overallSeverity, .none)
    }

    func testZoneStatusOverallTrendWorsening() {
        let status = ZoneStatus(
            breakouts: .none, redness: .none, dryness: .none, texture: .none, congestion: .none, irritation: .none,
            breakoutsTrend: .worsening, rednessTrend: .worsening, drynessTrend: .stable, textureTrend: .stable, congestionTrend: .stable, irritationTrend: .stable
        )
        XCTAssertEqual(status.overallTrend, .worsening)
    }

    func testZoneStatusOverallTrendImproving() {
        let status = ZoneStatus(
            breakouts: .none, redness: .none, dryness: .none, texture: .none, congestion: .none, irritation: .none,
            breakoutsTrend: .improving, rednessTrend: .improving, drynessTrend: .stable, textureTrend: .stable, congestionTrend: .stable, irritationTrend: .stable
        )
        XCTAssertEqual(status.overallTrend, .improving)
    }

    func testZoneStatusOverallTrendStable() {
        let status = ZoneStatus(
            breakouts: .none, redness: .none, dryness: .none, texture: .none, congestion: .none, irritation: .none,
            breakoutsTrend: .improving, rednessTrend: .worsening, drynessTrend: .stable, textureTrend: .stable, congestionTrend: .stable, irritationTrend: .stable
        )
        XCTAssertEqual(status.overallTrend, .stable)
    }

    func testZoneStatusOverallTrendUnknown() {
        let status = ZoneStatus(
            breakouts: .none, redness: .none, dryness: .none, texture: .none, congestion: .none, irritation: .none,
            breakoutsTrend: .unknown, rednessTrend: .unknown, drynessTrend: .unknown, textureTrend: .unknown, congestionTrend: .unknown, irritationTrend: .unknown
        )
        XCTAssertEqual(status.overallTrend, .unknown)
    }

    func testZoneStatusMetricsCount() {
        let status = ZoneStatus(breakouts: .low, redness: .moderate, dryness: .high, texture: .none, congestion: .low, irritation: .none)
        let metrics = status.metrics
        XCTAssertEqual(metrics.count, 6)
        XCTAssertEqual(metrics[0].label, "Breakouts")
        XCTAssertEqual(metrics[0].severity, .low)
        XCTAssertEqual(metrics[1].label, "Redness")
        XCTAssertEqual(metrics[1].severity, .moderate)
    }

    // MARK: - ZoneSeverity

    func testZoneSeverityDisplayNames() {
        XCTAssertFalse(ZoneSeverity.none.displayName.isEmpty)
        XCTAssertFalse(ZoneSeverity.low.displayName.isEmpty)
        XCTAssertFalse(ZoneSeverity.moderate.displayName.isEmpty)
        XCTAssertFalse(ZoneSeverity.high.displayName.isEmpty)
    }

    func testZoneSeverityIcons() {
        XCTAssertEqual(ZoneSeverity.none.icon, "checkmark.circle.fill")
        XCTAssertEqual(ZoneSeverity.low.icon, "exclamationmark.circle.fill")
        XCTAssertEqual(ZoneSeverity.moderate.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(ZoneSeverity.high.icon, "xmark.circle.fill")
    }

    // MARK: - ZoneTrend

    func testZoneTrendDisplayNames() {
        XCTAssertFalse(ZoneTrend.improving.displayName.isEmpty)
        XCTAssertFalse(ZoneTrend.stable.displayName.isEmpty)
        XCTAssertFalse(ZoneTrend.worsening.displayName.isEmpty)
        XCTAssertFalse(ZoneTrend.unknown.displayName.isEmpty)
    }

    func testZoneTrendIcons() {
        XCTAssertEqual(ZoneTrend.improving.icon, "arrow.down.forward")
        XCTAssertEqual(ZoneTrend.stable.icon, "equal")
        XCTAssertEqual(ZoneTrend.worsening.icon, "arrow.up.forward")
        XCTAssertEqual(ZoneTrend.unknown.icon, "minus")
    }

    // MARK: - IngredientTag

    func testIngredientTagExfoliants() {
        XCTAssertTrue(IngredientTag.aha.isExfoliant)
        XCTAssertTrue(IngredientTag.bha.isExfoliant)
        XCTAssertFalse(IngredientTag.niacinamide.isExfoliant)
        XCTAssertFalse(IngredientTag.retinol.isExfoliant)
    }

    func testIngredientTagPhotosensitizing() {
        XCTAssertTrue(IngredientTag.retinol.isPhotosensitizing)
        XCTAssertTrue(IngredientTag.aha.isPhotosensitizing)
        XCTAssertTrue(IngredientTag.bha.isPhotosensitizing)
        XCTAssertFalse(IngredientTag.niacinamide.isPhotosensitizing)
        XCTAssertFalse(IngredientTag.hyaluronicAcid.isPhotosensitizing)
    }

    func testIngredientTagActiveTreatment() {
        XCTAssertTrue(IngredientTag.retinol.isActiveTreatment)
        XCTAssertTrue(IngredientTag.vitaminC.isActiveTreatment)
        XCTAssertTrue(IngredientTag.benzoylPeroxide.isActiveTreatment)
        XCTAssertTrue(IngredientTag.azelaicAcid.isActiveTreatment)
        XCTAssertFalse(IngredientTag.hyaluronicAcid.isActiveTreatment)
        XCTAssertFalse(IngredientTag.ceramides.isActiveTreatment)
    }

    func testIngredientTagColors() {
        let tags: [IngredientTag] = [.retinol, .aha, .niacinamide, .vitaminC, .hyaluronicAcid, .spf]
        for tag in tags {
            XCTAssertFalse(tag.color.isEmpty, "\(tag) should have a color")
            XCTAssertTrue(tag.color.hasPrefix("#"), "\(tag) color should be hex")
        }
    }

    // MARK: - ChangeDirection

    func testChangeDirectionZoneTrendMapping() {
        XCTAssertEqual(ChangeDirection.increasing.zoneTrend, .worsening)
        XCTAssertEqual(ChangeDirection.decreasing.zoneTrend, .improving)
        XCTAssertEqual(ChangeDirection.stable.zoneTrend, .stable)
    }

    func testChangeDirectionDisplayNames() {
        XCTAssertEqual(ChangeDirection.increasing.displayName, "Increasing")
        XCTAssertEqual(ChangeDirection.decreasing.displayName, "Decreasing")
        XCTAssertEqual(ChangeDirection.stable.displayName, "Stable")
    }

    // MARK: - ScanPhoto Codable

    func testScanPhotoCodableRoundTrip() throws {
        let photo = ScanPhoto(zone: .forehead, fileName: "test.jpg")
        let data = try JSONEncoder().encode(photo)
        let decoded = try JSONDecoder().decode(ScanPhoto.self, from: data)
        XCTAssertEqual(decoded.zone, .forehead)
        XCTAssertEqual(decoded.fileName, "test.jpg")
        XCTAssertNil(decoded.imageData) // intentionally not persisted
    }

    func testScanPhotoDecodesWithoutId() throws {
        let json = """
        {"zone": "forehead", "fileName": "test.jpg"}
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ScanPhoto.self, from: data)
        XCTAssertNotNil(decoded.id)
        XCTAssertEqual(decoded.zone, .forehead)
    }

    // MARK: - SkinProfile Defaults

    func testSkinProfileDefaults() {
        let profile = SkinProfile()
        XCTAssertEqual(profile.skinType, .combination)
        XCTAssertEqual(profile.sensitivity, .mild)
        XCTAssertTrue(profile.primaryConcerns.isEmpty)
        XCTAssertEqual(profile.primaryGoal, .evenTone)
        XCTAssertEqual(profile.ageRange, .range25to34)
        XCTAssertEqual(profile.stressLevel, .moderate)
    }

    // MARK: - SkinMap

    func testSkinMapInit() {
        let zones = [
            FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: .none, redness: .none, dryness: .none, texture: .none, congestion: .none, irritation: .none)),
            FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: .low, redness: .none, dryness: .none, texture: .none, congestion: .none, irritation: .none))
        ]
        let map = SkinMap(zones: zones)
        XCTAssertEqual(map.zones.count, 2)
        XCTAssertEqual(map.confidenceLevel, 1.0)
        XCTAssertNil(map.scanQuality)
    }

    // MARK: - Product

    func testProductDefaults() {
        let product = Product(name: "Test Cleanser", category: .cleanser, period: .both)
        XCTAssertTrue(product.isActive)
        XCTAssertEqual(product.ingredients, [])
        XCTAssertEqual(product.ingredientTags, [])
        XCTAssertEqual(product.sortOrder, 0)
    }

    // MARK: - Experiment

    func testExperimentDefaults() {
        let exp = Experiment(name: "Test", zone: .forehead, hypothesis: "H", durationDays: 7, isActive: true, relatedProductIDs: [], dailyCheckIns: [])
        XCTAssertNil(exp.endDate)
        XCTAssertNil(exp.result)
        XCTAssertTrue(exp.dailyCheckIns.isEmpty)
    }

    // MARK: - Insight

    func testInsightDefaults() {
        let insight = Insight(title: "T", body: "B", type: .improvement, zone: .nose, priority: .high)
        XCTAssertFalse(insight.isDismissed)
    }

    // MARK: - ReminderSettings

    func testReminderSettingsDefaults() {
        let settings = ReminderSettings()
        XCTAssertFalse(settings.enabled)
        XCTAssertEqual(settings.cadence, .daily)
    }

    // MARK: - PrivacySettings

    func testPrivacySettingsDefaults() {
        let settings = PrivacySettings()
        XCTAssertFalse(settings.shareAnalytics)
        XCTAssertTrue(settings.savePhotos)
    }

    // MARK: - FailureCode

    func testFailureCodeDisplayNames() {
        let codes: [FailureCode] = [.noFaceDetected, .poorLighting, .blurryImage, .noBaseline]
        for code in codes {
            XCTAssertFalse(code.displayName.isEmpty, "\(code) should have a display name")
        }
    }

    // MARK: - SampleData

    func testSampleDataDefaultProducts() {
        XCTAssertFalse(SampleData.defaultProducts.isEmpty)
        XCTAssertTrue(SampleData.defaultProducts.allSatisfy(\.isActive))
    }

    func testSampleDataSkinMap() {
        let map = SampleData.sampleSkinMap
        XCTAssertEqual(map.zones.count, 5)
        XCTAssertTrue(map.zones.contains { $0.zoneType == .forehead })
    }

    func testSampleDataInsights() {
        XCTAssertFalse(SampleData.sampleInsights.isEmpty)
        XCTAssertTrue(SampleData.sampleInsights.allSatisfy { !$0.title.isEmpty })
    }

    func testSampleDataWeeklyReport() {
        let report = SampleData.sampleWeeklyReport
        XCTAssertFalse(report.summary.isEmpty)
    }

    func testSampleDataExperiments() {
        XCTAssertFalse(SampleData.sampleExperiments.isEmpty)
        XCTAssertTrue(SampleData.sampleExperiments[0].isActive)
    }

    // MARK: - Codable Conformance (round-trip)

    func testSkinProfileCodable() throws {
        let original = SkinProfile(skinType: .oily, sensitivity: .reactive, primaryConcerns: [.breakouts, .texture], primaryGoal: .clearerSkin, ageRange: .range18to24, stressLevel: .high)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SkinProfile.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testSkinMapCodable() throws {
        let original = SampleData.sampleSkinMap
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SkinMap.self, from: data)
        XCTAssertEqual(decoded.zones.count, original.zones.count)
    }

    func testProductCodable() throws {
        let original = Product(name: "Serum", category: .serum, period: .morning, ingredients: ["Water", "Niacinamide"], ingredientTags: [.niacinamide])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Product.self, from: data)
        XCTAssertEqual(decoded.name, "Serum")
        XCTAssertEqual(decoded.ingredients, ["Water", "Niacinamide"])
    }

    func testWeeklyInsightCodable() throws {
        let original = WeeklyInsight(generatedAt: .now, weekEnding: .now, summaryTitle: "Title", summaryText: "Text", zoneHighlights: [], possibleContributors: [], recommendedNextStep: "Step", confidenceLevel: .high, safetyDisclaimer: "Disclaimer")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WeeklyInsight.self, from: data)
        XCTAssertEqual(decoded.summaryTitle, "Title")
    }

    func testSkinSessionResultCodable() throws {
        let original = SkinSessionResult(sessionId: UUID(), createdAt: .now, scanStatus: .accepted, isBaseline: false, skinMap: SampleData.sampleSkinMap, zoneChanges: [], dailyPlan: DailyPlan(generatedAt: .now, period: .morning, focus: "Hydration", recommendedSteps: [], avoidSteps: [], reasoning: [], confidenceLevel: .high), confidenceSummary: ConfidenceSummary(overall: 0.9, scanQuality: 0.9, skinMap: 0.9, changeDetection: 0.9, productIntelligence: 0.9, dailyPlan: 0.9, adjustedForFailures: false), userMessages: [], analyticsEvents: [])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SkinSessionResult.self, from: data)
        XCTAssertEqual(decoded.scanStatus, .accepted)
    }
}
