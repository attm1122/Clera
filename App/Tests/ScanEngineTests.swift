import XCTest
@testable import Clera

// MARK: - Scan Readiness Result Tests

final class ScanReadinessResultTests: XCTestCase {

    func testDefaultValues() {
        let result = ScanReadinessResult()
        XCTAssertFalse(result.faceDetected)
        XCTAssertFalse(result.faceCentered)
        XCTAssertFalse(result.faceTooSmall)
        XCTAssertFalse(result.faceTooLarge)
        XCTAssertNil(result.faceBounds)
        XCTAssertNil(result.headPose)
        XCTAssertEqual(result.lightingQuality, .unknown)
        XCTAssertEqual(result.blurScore, 0)
        XCTAssertEqual(result.brightnessScore, 0)
        XCTAssertEqual(result.contrastScore, 0)
        XCTAssertEqual(result.sharpnessScore, 0)
        XCTAssertFalse(result.overexposed)
        XCTAssertFalse(result.shadowDetected)
        XCTAssertEqual(result.scanReadiness, .notReady)
        XCTAssertEqual(result.confidenceScore, 0)
    }

    func testCustomInit() {
        let result = ScanReadinessResult(guidanceMessage: "Test guidance")
        XCTAssertEqual(result.guidanceMessage, "Test guidance")
    }
}

// MARK: - Head Pose Tests

final class HeadPoseTests: XCTestCase {

    func testIsFrontal() {
        let pose = HeadPose(pitch: 0, yaw: 0, roll: 0)
        XCTAssertTrue(pose.isFrontal)
    }

    func testIsFrontalYawTooLarge() {
        let pose = HeadPose(pitch: 0, yaw: 0.2, roll: 0)
        XCTAssertFalse(pose.isFrontal)
    }

    func testIsFrontalPitchTooLarge() {
        let pose = HeadPose(pitch: 0.2, yaw: 0, roll: 0)
        XCTAssertFalse(pose.isFrontal)
    }

    func testIsFrontalRollTooLarge() {
        let pose = HeadPose(pitch: 0, yaw: 0, roll: 0.2)
        XCTAssertFalse(pose.isFrontal)
    }

    func testIsLeftProfile() {
        let pose = HeadPose(pitch: 0, yaw: -0.5, roll: 0)
        XCTAssertTrue(pose.isLeftProfile)
    }

    func testIsNotLeftProfile() {
        let pose = HeadPose(pitch: 0, yaw: -0.2, roll: 0)
        XCTAssertFalse(pose.isLeftProfile)
    }

    func testIsRightProfile() {
        let pose = HeadPose(pitch: 0, yaw: 0.5, roll: 0)
        XCTAssertTrue(pose.isRightProfile)
    }

    func testIsNotRightProfile() {
        let pose = HeadPose(pitch: 0, yaw: 0.2, roll: 0)
        XCTAssertFalse(pose.isRightProfile)
    }
}

// MARK: - Scan Readiness Comparable Tests

final class ScanReadinessTests: XCTestCase {

    func testComparableOrdering() {
        let values: [ScanReadiness] = [.excellent, .good, .acceptable, .poorQuality, .notReady]
        let sorted = values.sorted()
        XCTAssertEqual(sorted, [.notReady, .poorQuality, .acceptable, .good, .excellent])
    }

    func testLessThan() {
        XCTAssertTrue(ScanReadiness.notReady < .good)
        XCTAssertTrue(ScanReadiness.poorQuality < .excellent)
        XCTAssertFalse(ScanReadiness.excellent < .good)
    }
}

// MARK: - Scan Engine Config Tests

final class ScanEngineConfigTests: XCTestCase {

    func testDefaultConfiguration() {
        let config = ScanEngine.Configuration()
        XCTAssertEqual(config.idealBrightnessRange, 0.25...0.75)
        XCTAssertEqual(config.minBlurScore, 0.12)
        XCTAssertEqual(config.minSharpnessScore, 0.08)
        XCTAssertEqual(config.minFaceArea, 0.15)
        XCTAssertEqual(config.maxFaceArea, 0.65)
    }

    func testCustomConfiguration() {
        var config = ScanEngine.Configuration()
        config.minBlurScore = 0.5
        config.idealBrightnessRange = 0.3...0.8
        XCTAssertEqual(config.minBlurScore, 0.5)
        XCTAssertEqual(config.idealBrightnessRange, 0.3...0.8)
    }
}

// MARK: - Lighting Quality Tests

final class LightingQualityTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(LightingQuality.unknown.rawValue, "unknown")
        XCTAssertEqual(LightingQuality.good.rawValue, "good")
        XCTAssertEqual(LightingQuality.tooDark.rawValue, "tooDark")
        XCTAssertEqual(LightingQuality.tooBright.rawValue, "tooBright")
        XCTAssertEqual(LightingQuality.uneven.rawValue, "uneven")
    }
}
