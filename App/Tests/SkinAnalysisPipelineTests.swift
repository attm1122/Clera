import XCTest
import UIKit
@testable import Clera

// MARK: - Skin Analysis Result Mapping Tests

final class SkinAnalysisResultMappingTests: XCTestCase {

    func testToSkinMap() {
        let result = SkinAnalysisResult(
            scanId: UUID(),
            userId: "user-1",
            createdAt: .now,
            quality: ScanQualityResult(),
            zones: [
                SkinZoneAnalysis(
                    zone: .forehead,
                    metrics: [
                        .breakoutLikeSpots: SkinMetricScore(score: 60, confidence: .high, trend: .increased, reason: ""),
                        .redness: SkinMetricScore(score: 30, confidence: .medium, trend: .stable, reason: "")
                    ]
                )
            ],
            summary: SkinAnalysisSummary()
        )

        let skinMap = result.toSkinMap()
        XCTAssertEqual(skinMap.zones.count, 1)
        XCTAssertEqual(skinMap.zones.first?.zoneType, .forehead)
        XCTAssertEqual(skinMap.zones.first?.status.breakouts, .moderate)
        XCTAssertEqual(skinMap.zones.first?.status.redness, .low)
        XCTAssertEqual(skinMap.zones.first?.status.breakoutsTrend, .worsening)
        XCTAssertEqual(skinMap.zones.first?.status.rednessTrend, .stable)
    }

    func testZoneStatusMissingMetrics() {
        let zone = SkinZoneAnalysis(zone: .nose, metrics: [:])
        // Since toZoneStatus is private, test via toSkinMap
        let result = SkinAnalysisResult(
            scanId: UUID(), userId: "u", createdAt: .now,
            quality: ScanQualityResult(),
            zones: [zone],
            summary: SkinAnalysisSummary()
        )
        let skinMap = result.toSkinMap()
        XCTAssertEqual(skinMap.zones.first?.status.breakouts, ZoneSeverity.none)
        XCTAssertEqual(skinMap.zones.first?.status.redness, ZoneSeverity.none)
        XCTAssertEqual(skinMap.zones.first?.status.breakoutsTrend, ZoneTrend.unknown)
        XCTAssertEqual(skinMap.zones.first?.status.rednessTrend, ZoneTrend.unknown)
    }

    func testSeverityMapping() {
        let result = SkinAnalysisResult(
            scanId: UUID(), userId: "u", createdAt: .now,
            quality: ScanQualityResult(),
            zones: [
                SkinZoneAnalysis(zone: .chinJaw, metrics: [
                    .breakoutLikeSpots: SkinMetricScore(score: 10, confidence: .high, trend: .stable, reason: ""),
                    .redness: SkinMetricScore(score: 25, confidence: .high, trend: .stable, reason: ""),
                    .dryness: SkinMetricScore(score: 50, confidence: .high, trend: .stable, reason: ""),
                    .texture: SkinMetricScore(score: 80, confidence: .high, trend: .stable, reason: "")
                ])
            ],
            summary: SkinAnalysisSummary()
        )
        let map = result.toSkinMap()
        let status = map.zones.first!.status
        XCTAssertEqual(status.breakouts, .none)
        XCTAssertEqual(status.redness, .low)
        XCTAssertEqual(status.dryness, .moderate)
        XCTAssertEqual(status.texture, .high)
    }

    func testTrendMapping() {
        let result = SkinAnalysisResult(
            scanId: UUID(), userId: "u", createdAt: .now,
            quality: ScanQualityResult(),
            zones: [
                SkinZoneAnalysis(zone: .leftCheek, metrics: [
                    .breakoutLikeSpots: SkinMetricScore(score: 50, confidence: .high, trend: .improved, reason: ""),
                    .redness: SkinMetricScore(score: 50, confidence: .high, trend: .stable, reason: ""),
                    .shine: SkinMetricScore(score: 50, confidence: .high, trend: .increased, reason: ""),
                    .texture: SkinMetricScore(score: 50, confidence: .high, trend: .insufficientData, reason: "")
                ])
            ],
            summary: SkinAnalysisSummary()
        )
        let status = result.toSkinMap().zones.first!.status
        XCTAssertEqual(status.breakoutsTrend, .improving)
        XCTAssertEqual(status.rednessTrend, .stable)
        XCTAssertEqual(status.congestionTrend, .worsening)
        XCTAssertEqual(status.textureTrend, .unknown)
    }
}

// MARK: - Simulator Skin Analyzer Tests

final class SimulatorSkinAnalyzerTests: XCTestCase {

    func testIsRunningOnSimulator() {
        // Should be true since we run on simulator
        XCTAssertTrue(SimulatorSkinAnalyzer.isRunningOnSimulator)
    }

    func testAnalyzeProducesResult() {
        let image = UIImage(systemName: "person.fill") ?? UIImage()
        let result = SimulatorSkinAnalyzer.analyze(
            scanId: UUID(),
            userId: "test-user",
            frontImage: image
        )

        XCTAssertEqual(result.userId, "test-user")
        XCTAssertTrue(result.quality.accepted)
        XCTAssertEqual(result.quality.lighting, .good)
        XCTAssertEqual(result.zones.count, 5)

        for zone in result.zones {
            XCTAssertFalse(zone.metrics.isEmpty)
            XCTAssertFalse(zone.topInsight.isEmpty)
        }
    }

    func testAnalyzeAllZonesPresent() {
        let image = UIImage(systemName: "face.smiling") ?? UIImage()
        let result = SimulatorSkinAnalyzer.analyze(
            scanId: UUID(), userId: "u", frontImage: image
        )
        let zoneTypes = Set(result.zones.map { $0.zone })
        XCTAssertEqual(zoneTypes, Set(SkinZone.allCases))
    }

    func testAnalyzeMetricsInRange() {
        let image = UIImage(systemName: "person.crop.rectangle") ?? UIImage()
        let result = SimulatorSkinAnalyzer.analyze(
            scanId: UUID(), userId: "u", frontImage: image
        )
        for zone in result.zones {
            for (_, score) in zone.metrics {
                XCTAssertGreaterThanOrEqual(score.score, 0)
                XCTAssertLessThanOrEqual(score.score, 100)
            }
        }
    }
}

// MARK: - Image Store Tests

final class ImageStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ImageStore.deleteAll()
    }

    override func tearDown() {
        ImageStore.deleteAll()
        super.tearDown()
    }

    func testGenerateFileName() {
        let scanId = UUID()
        let name = ImageStore.generateFileName(angle: .front, scanId: scanId)
        XCTAssertTrue(name.hasPrefix(scanId.uuidString))
        XCTAssertTrue(name.hasSuffix("front.jpg"))
    }

    func testSaveAndLoad() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }

        let fileName = "test_save.jpg"
        let url = ImageStore.save(image, fileName: fileName)
        XCTAssertNotNil(url)

        let loaded = ImageStore.load(fileName: fileName)
        XCTAssertNotNil(loaded)
    }

    func testLoadNonExistent() {
        let loaded = ImageStore.load(fileName: "does_not_exist.jpg")
        XCTAssertNil(loaded)
    }

    func testDelete() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        let fileName = "test_delete.jpg"
        ImageStore.save(image, fileName: fileName)

        XCTAssertNotNil(ImageStore.load(fileName: fileName))
        ImageStore.delete(fileName: fileName)
        XCTAssertNil(ImageStore.load(fileName: fileName))
    }

    func testDeleteAll() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let image = renderer.image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        ImageStore.save(image, fileName: "a.jpg")
        ImageStore.save(image, fileName: "b.jpg")

        ImageStore.deleteAll()
        XCTAssertNil(ImageStore.load(fileName: "a.jpg"))
        XCTAssertNil(ImageStore.load(fileName: "b.jpg"))
    }
}
