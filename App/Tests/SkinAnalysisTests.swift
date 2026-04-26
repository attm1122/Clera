import XCTest
@testable import Clera

// MARK: - Skin Analysis Models Tests

final class SkinAnalysisModelsTests: XCTestCase {

    func testSkinScanDefaults() {
        let scan = SkinScan(userId: "test-user")
        XCTAssertEqual(scan.userId, "test-user")
        XCTAssertTrue(scan.images.isEmpty)
        XCTAssertTrue(scan.zoneAnalyses.isEmpty)
    }

    func testScanQualityResultDefaults() {
        let quality = ScanQualityResult()
        XCTAssertFalse(quality.accepted)
        XCTAssertEqual(quality.lighting, .unknown)
        XCTAssertEqual(quality.confidence, .low)
        XCTAssertTrue(quality.issues.isEmpty)
    }

    func testSkinMetricScoreClamping() {
        let score = SkinMetricScore(score: 150, confidence: .high, trend: .stable, reason: "Test")
        XCTAssertEqual(score.score, 100)
    }

    func testSkinMetricScoreNegativeClamping() {
        let score = SkinMetricScore(score: -50, confidence: .high, trend: .stable, reason: "Test")
        XCTAssertEqual(score.score, 0)
    }

    func testSkinMetricScoreValid() {
        let score = SkinMetricScore(score: 75, confidence: .medium, trend: .improved, reason: "Good")
        XCTAssertEqual(score.score, 75)
    }

    func testSkinZoneDisplayNames() {
        XCTAssertEqual(SkinZone.forehead.displayName, "Forehead")
        XCTAssertEqual(SkinZone.nose.displayName, "Nose")
        XCTAssertEqual(SkinZone.chinJaw.displayName, "Chin / Jaw")
    }

    func testSkinMetricKeyDisplayNames() {
        XCTAssertEqual(SkinMetricKey.redness.displayName, "Redness")
        XCTAssertEqual(SkinMetricKey.texture.displayName, "Texture")
        XCTAssertEqual(SkinMetricKey.breakoutLikeSpots.displayName, "Breakout-like spots")
    }

    func testSkinTrendDisplayNames() {
        XCTAssertEqual(SkinTrend.improved.displayName, "Improved")
        XCTAssertEqual(SkinTrend.stable.displayName, "Stable")
        XCTAssertEqual(SkinTrend.insufficientData.displayName, "Insufficient data")
    }

    func testSkinAnalysisSummaryDefaults() {
        let summary = SkinAnalysisSummary()
        XCTAssertEqual(summary.overallStatus, .insufficientData)
        XCTAssertTrue(summary.primaryChange.isEmpty)
        XCTAssertFalse(summary.disclaimer.isEmpty)
    }

    func testOverallStatusDisplayNames() {
        XCTAssertEqual(SkinAnalysisSummary.OverallStatus.stable.displayName, "Stable")
        XCTAssertEqual(SkinAnalysisSummary.OverallStatus.significantChanges.displayName, "Significant changes")
    }

    func testSkinZoneAnalysisInit() {
        let analysis = SkinZoneAnalysis(zone: .forehead)
        XCTAssertEqual(analysis.zone, .forehead)
        XCTAssertTrue(analysis.metrics.isEmpty)
        XCTAssertTrue(analysis.topInsight.isEmpty)
    }

    func testSkinInsightInit() {
        let insight = SkinInsight(zone: .nose, metric: .redness, message: "Redness detected", nextStep: "Use niacinamide", confidence: .high)
        XCTAssertEqual(insight.zone, .nose)
        XCTAssertEqual(insight.metric, .redness)
    }

    func testFaceLandmarkResultDefaults() {
        let result = FaceLandmarkResult()
        XCTAssertFalse(result.faceDetected)
        XCTAssertEqual(result.boundingBox, .zero)
        XCTAssertTrue(result.landmarks.isEmpty)
    }

    func testSkinBaselineCodable() throws {
        let baseline = SkinBaseline(
            id: UUID(),
            userId: "user-1",
            createdAt: .now,
            scanId: UUID(),
            zoneScores: [.forehead: [.redness: 50]],
            lightingMetadata: SkinBaseline.LightingMetadata(brightness: 0.5, contrast: 0.6, colorTemperature: 5500),
            deviceMetadata: SkinBaseline.DeviceMetadata(deviceModel: "iPhone", cameraPosition: "front", resolution: "1920x1080")
        )
        let data = try JSONEncoder().encode(baseline)
        let decoded = try JSONDecoder().decode(SkinBaseline.self, from: data)
        XCTAssertEqual(decoded.userId, "user-1")
        XCTAssertEqual(decoded.zoneScores[.forehead]?[.redness], 50)
    }

    func testBaselineComparisonCodable() throws {
        let comparison = BaselineComparison(
            baselineId: UUID(),
            daysSinceBaseline: 7,
            zoneComparisons: [.forehead: [.redness: .improved]],
            overallChangePercentage: 12.5
        )
        let data = try JSONEncoder().encode(comparison)
        let decoded = try JSONDecoder().decode(BaselineComparison.self, from: data)
        XCTAssertEqual(decoded.daysSinceBaseline, 7)
        XCTAssertEqual(decoded.overallChangePercentage, 12.5)
    }
}

// MARK: - Trend Analyzer Tests

final class TrendAnalyzerTests: XCTestCase {

    func testTrendStable() {
        let trend = TrendAnalyzer.trendForMetric(currentScore: 52, baselineScore: 50)
        XCTAssertEqual(trend, .stable)
    }

    func testTrendSlightlyIncreased() {
        let trend = TrendAnalyzer.trendForMetric(currentScore: 56, baselineScore: 50)
        XCTAssertEqual(trend, .slightlyIncreased)
    }

    func testTrendIncreased() {
        let trend = TrendAnalyzer.trendForMetric(currentScore: 80, baselineScore: 50)
        XCTAssertEqual(trend, .increased)
    }

    func testTrendSlightlyReduced() {
        let trend = TrendAnalyzer.trendForMetric(currentScore: 45, baselineScore: 50)
        XCTAssertEqual(trend, .slightlyReduced)
    }

    func testTrendImproved() {
        let trend = TrendAnalyzer.trendForMetric(currentScore: 20, baselineScore: 50)
        XCTAssertEqual(trend, .improved)
    }

    func testTrendEvennessIncreasedIsImproved() {
        // For evenness, higher score is better (inverted logic)
        let trend = TrendAnalyzer.trendForMetric(currentScore: 80, baselineScore: 50, metric: .evenness)
        XCTAssertEqual(trend, .improved)
    }

    func testTrendEvennessDecreasedIsWorse() {
        let trend = TrendAnalyzer.trendForMetric(currentScore: 20, baselineScore: 50, metric: .evenness)
        XCTAssertEqual(trend, .increased)
    }

    func testCompareWithMissingBaselineData() {
        let current: [SkinZone: [SkinMetricKey: SkinMetricScore]] = [
            .forehead: [.redness: SkinMetricScore(score: 50, confidence: .high, trend: .stable, reason: "")]
        ]
        let baseline = SkinBaseline(
            id: UUID(), userId: "u", createdAt: .now, scanId: UUID(),
            zoneScores: [:], // no data for forehead
            lightingMetadata: SkinBaseline.LightingMetadata(brightness: 0.5, contrast: 0.5, colorTemperature: nil),
            deviceMetadata: SkinBaseline.DeviceMetadata(deviceModel: "iPhone", cameraPosition: "front", resolution: "x")
        )
        let comparison = TrendAnalyzer.compare(current: current, baseline: baseline)
        XCTAssertEqual(comparison.zoneComparisons[.forehead]?[.redness], .insufficientData)
    }

    func testOverallStatusInsufficientData() {
        let comparison = BaselineComparison(baselineId: UUID(), daysSinceBaseline: 0, zoneComparisons: [:], overallChangePercentage: 0)
        XCTAssertEqual(TrendAnalyzer.overallStatus(from: comparison), .insufficientData)
    }

    func testOverallStatusStable() {
        let comparison = BaselineComparison(
            baselineId: UUID(), daysSinceBaseline: 7,
            zoneComparisons: [.forehead: [.redness: .stable, .texture: .stable]],
            overallChangePercentage: 0
        )
        XCTAssertEqual(TrendAnalyzer.overallStatus(from: comparison), .stable)
    }

    func testOverallStatusSignificantChanges() {
        let comparison = BaselineComparison(
            baselineId: UUID(), daysSinceBaseline: 7,
            zoneComparisons: [
                .forehead: [.redness: .increased, .texture: .increased],
                .nose: [.redness: .increased, .texture: .stable]
            ],
            overallChangePercentage: 25
        )
        XCTAssertEqual(TrendAnalyzer.overallStatus(from: comparison), .significantChanges)
    }

    func testOverallStatusNoticeableChanges() {
        let comparison = BaselineComparison(
            baselineId: UUID(), daysSinceBaseline: 7,
            zoneComparisons: [
                .forehead: [.redness: .increased, .texture: .stable, .shine: .stable],
                .nose: [.redness: .stable, .texture: .stable, .shine: .stable]
            ],
            overallChangePercentage: 10
        )
        XCTAssertEqual(TrendAnalyzer.overallStatus(from: comparison), .noticeableChanges)
    }
}

// MARK: - Skin Insight Generator Tests

final class SkinInsightGeneratorTests: XCTestCase {

    func testTopInsightFirstScan() {
        let zone = SkinZoneAnalysis(zone: .forehead)
        let insight = SkinInsightGenerator.topInsight(for: zone, baseline: nil)
        XCTAssertTrue(insight.contains("First scan"))
    }

    func testTopInsightNoBaselineForZone() {
        let baseline = SkinBaseline(
            id: UUID(), userId: "u", createdAt: .now, scanId: UUID(),
            zoneScores: [.nose: [.redness: 40]],
            lightingMetadata: SkinBaseline.LightingMetadata(brightness: 0.5, contrast: 0.5, colorTemperature: nil),
            deviceMetadata: SkinBaseline.DeviceMetadata(deviceModel: "iPhone", cameraPosition: "front", resolution: "x")
        )
        let zone = SkinZoneAnalysis(zone: .forehead, metrics: [.redness: SkinMetricScore(score: 50, confidence: .high, trend: .stable, reason: "")])
        let insight = SkinInsightGenerator.topInsight(for: zone, baseline: baseline)
        XCTAssertTrue(insight.contains("First scan"))
    }

    func testTopInsightDetectsRednessIncrease() {
        let baseline = SkinBaseline(
            id: UUID(), userId: "u", createdAt: .now, scanId: UUID(),
            zoneScores: [.forehead: [.redness: 30, .texture: 40]],
            lightingMetadata: SkinBaseline.LightingMetadata(brightness: 0.5, contrast: 0.5, colorTemperature: nil),
            deviceMetadata: SkinBaseline.DeviceMetadata(deviceModel: "iPhone", cameraPosition: "front", resolution: "x")
        )
        let zone = SkinZoneAnalysis(
            zone: .forehead,
            metrics: [
                .redness: SkinMetricScore(score: 80, confidence: .high, trend: .increased, reason: ""),
                .texture: SkinMetricScore(score: 42, confidence: .high, trend: .stable, reason: "")
            ]
        )
        let insight = SkinInsightGenerator.topInsight(for: zone, baseline: baseline)
        XCTAssertTrue(insight.contains("Redness"))
    }

    func testNextStepBreakoutIncreased() {
        let step = SkinInsightGenerator.nextStep(for: .chinJaw, metric: .breakoutLikeSpots, trend: .increased)
        XCTAssertTrue(step.contains("products"))
    }

    func testNextStepRednessImproved() {
        let step = SkinInsightGenerator.nextStep(for: .leftCheek, metric: .redness, trend: .improved)
        XCTAssertTrue(step.contains("working well"))
    }

    func testNextStepTextureDefault() {
        let step = SkinInsightGenerator.nextStep(for: .nose, metric: .texture, trend: .stable)
        XCTAssertEqual(step, "Keep up your current routine.")
    }

    func testGenerateSummaryNoComparison() {
        let summary = SkinInsightGenerator.generateSummary(zoneAnalyses: [], comparison: nil)
        XCTAssertEqual(summary.overallStatus, .insufficientData)
        XCTAssertTrue(summary.primaryChange.contains("first scan"))
        XCTAssertTrue(summary.disclaimer.contains("cosmetic"))
    }

    func testConfidenceFromZonesHigh() {
        let zones = [
            SkinZoneAnalysis(zone: .forehead, confidence: .high),
            SkinZoneAnalysis(zone: .nose, confidence: .high),
            SkinZoneAnalysis(zone: .leftCheek, confidence: .high)
        ]
        let comparison = BaselineComparison(
            baselineId: UUID(), daysSinceBaseline: 7,
            zoneComparisons: [:],
            overallChangePercentage: 0
        )
        let summary = SkinInsightGenerator.generateSummary(zoneAnalyses: zones, comparison: comparison)
        XCTAssertEqual(summary.confidence, .high)
    }

    func testConfidenceFromZonesLow() {
        let zones = [
            SkinZoneAnalysis(zone: .forehead, confidence: .low),
            SkinZoneAnalysis(zone: .nose, confidence: .low),
            SkinZoneAnalysis(zone: .leftCheek, confidence: .low)
        ]
        let comparison = BaselineComparison(
            baselineId: UUID(), daysSinceBaseline: 7,
            zoneComparisons: [:],
            overallChangePercentage: 0
        )
        let summary = SkinInsightGenerator.generateSummary(zoneAnalyses: zones, comparison: comparison)
        XCTAssertEqual(summary.confidence, .low)
    }
}

// MARK: - Face Zone Mapper Tests

final class FaceZoneMapperTests: XCTestCase {

    func testMapZonesNoFaceDetected() {
        let landmarks = FaceLandmarkResult()
        let zones = FaceZoneMapper.mapZones(from: landmarks)
        XCTAssertTrue(zones.isEmpty)
    }

    func testMapZonesMissingRequiredLandmarks() {
        var landmarks = FaceLandmarkResult()
        landmarks.faceDetected = true
        landmarks.landmarks = [
            FaceLandmarkResult.FaceLandmark(type: .faceContour, points: [CGPoint(x: 0, y: 0)])
            // Missing other required landmarks
        ]
        let zones = FaceZoneMapper.mapZones(from: landmarks)
        XCTAssertTrue(zones.isEmpty)
    }

    func testMapZonesWithAllLandmarks() {
        let contour = [
            CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.5, y: 0.05), CGPoint(x: 0.8, y: 0.1),
            CGPoint(x: 0.85, y: 0.5), CGPoint(x: 0.8, y: 0.9), CGPoint(x: 0.5, y: 0.95), CGPoint(x: 0.2, y: 0.9), CGPoint(x: 0.15, y: 0.5)
        ]
        let leftBrow = [CGPoint(x: 0.25, y: 0.2), CGPoint(x: 0.4, y: 0.18)]
        let rightBrow = [CGPoint(x: 0.6, y: 0.18), CGPoint(x: 0.75, y: 0.2)]
        let leftEye = [CGPoint(x: 0.28, y: 0.28), CGPoint(x: 0.38, y: 0.26)]
        let rightEye = [CGPoint(x: 0.62, y: 0.26), CGPoint(x: 0.72, y: 0.28)]
        let noseCrest = [CGPoint(x: 0.48, y: 0.25), CGPoint(x: 0.5, y: 0.35), CGPoint(x: 0.52, y: 0.25)]
        let noseTip = [CGPoint(x: 0.48, y: 0.4), CGPoint(x: 0.52, y: 0.4)]
        let outerLips = [CGPoint(x: 0.42, y: 0.55), CGPoint(x: 0.58, y: 0.55), CGPoint(x: 0.5, y: 0.62)]
        let medianLine = [CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.5, y: 0.95)]

        var landmarks = FaceLandmarkResult()
        landmarks.faceDetected = true
        landmarks.landmarks = [
            FaceLandmarkResult.FaceLandmark(type: .faceContour, points: contour),
            FaceLandmarkResult.FaceLandmark(type: .leftEyebrow, points: leftBrow),
            FaceLandmarkResult.FaceLandmark(type: .rightEyebrow, points: rightBrow),
            FaceLandmarkResult.FaceLandmark(type: .leftEye, points: leftEye),
            FaceLandmarkResult.FaceLandmark(type: .rightEye, points: rightEye),
            FaceLandmarkResult.FaceLandmark(type: .noseCrest, points: noseCrest),
            FaceLandmarkResult.FaceLandmark(type: .noseTip, points: noseTip),
            FaceLandmarkResult.FaceLandmark(type: .outerLips, points: outerLips),
            FaceLandmarkResult.FaceLandmark(type: .medianLine, points: medianLine)
        ]

        let zones = FaceZoneMapper.mapZones(from: landmarks)
        XCTAssertEqual(zones.keys.count, 5)
        XCTAssertNotNil(zones[.forehead])
        XCTAssertNotNil(zones[.nose])
        XCTAssertNotNil(zones[.leftCheek])
        XCTAssertNotNil(zones[.rightCheek])
        XCTAssertNotNil(zones[.chinJaw])
    }
}
