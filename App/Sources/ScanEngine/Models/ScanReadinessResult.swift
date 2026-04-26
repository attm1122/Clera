import CoreGraphics
import Foundation

/// The only model the UI consumes. No knowledge of which CV provider produced it.
struct ScanReadinessResult: Sendable, Equatable {
    var faceDetected: Bool = false
    var faceCentered: Bool = false
    var faceTooSmall: Bool = false
    var faceTooLarge: Bool = false
    var faceBounds: CGRect?
    var headPose: HeadPose?
    var lightingQuality: LightingQuality = .unknown
    var blurScore: Double = 0
    var brightnessScore: Double = 0
    var contrastScore: Double = 0
    var sharpnessScore: Double = 0
    var overexposed: Bool = false
    var shadowDetected: Bool = false
    var scanReadiness: ScanReadiness = .notReady
    var guidanceMessage: String = CleraCopy.ScanGuidance.positionFace
    var confidenceScore: Double = 0
}

struct HeadPose: Codable, Sendable, Equatable {
    var pitch: Double = 0 // up (-) / down (+)
    var yaw: Double = 0   // left (-) / right (+)
    var roll: Double = 0  // tilt

    var isFrontal: Bool {
        abs(yaw) < 0.15 && abs(pitch) < 0.15 && abs(roll) < 0.15
    }

    var isLeftProfile: Bool {
        yaw < -0.35 && yaw > -0.85
    }

    var isRightProfile: Bool {
        yaw > 0.35 && yaw < 0.85
    }
}

enum LightingQuality: String, Codable, Sendable {
    case unknown
    case good
    case tooDark
    case tooBright
    case uneven
}

enum ScanReadiness: Comparable, Sendable {
    case notReady
    case poorQuality
    case acceptable
    case good
    case excellent
}
