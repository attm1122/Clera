import Foundation

/// The complete state machine for the scan UI animation system.
/// Drives all visual feedback, haptics, and guidance in the scan flow.
enum ScanAnimationState: Equatable {
    /// Initial state before any face is detected
    case idle
    /// Face may be present but not yet confirmed
    case detectingFace
    /// Face detected but not aligned (off-center, wrong angle, too close/far)
    case faceNotAligned(guidance: String)
    /// Face aligned, evaluating lighting conditions
    case lightingCheck(guidance: String)
    /// Everything looks good — prompting user to hold steady
    case holdStill
    /// Active scan in progress (scanning line animation)
    case scanning(progress: Double)
    /// Post-capture, highlighting detected zones
    case analysingZones(currentZone: Int, totalZones: Int)
    /// Scan completed successfully
    case scanComplete
    /// Scan failed validation, needs retry
    case scanFailed(guidance: String)

    /// Whether the face oval should show a "locked" steady state
    var isFaceLocked: Bool {
        switch self {
        case .holdStill, .scanning, .analysingZones, .scanComplete:
            return true
        default:
            return false
        }
    }

    /// Whether the scanning line animation should be visible
    var showScanningLine: Bool {
        if case .scanning = self { return true }
        return false
    }

    /// Whether zone highlight animation should be visible
    var showZoneHighlights: Bool {
        if case .analysingZones = self { return true }
        return false
    }

    /// The primary guidance message for the current state
    var guidanceMessage: String {
        switch self {
        case .idle:
            return CleraCopy.ScanGuidance.positionFace
        case .detectingFace:
            return CleraCopy.ScanGuidance.detectingFace
        case .faceNotAligned(let guidance):
            return guidance
        case .lightingCheck(let guidance):
            return guidance
        case .holdStill:
            return CleraCopy.ScanGuidance.holdStillMessage
        case .scanning:
            return CleraCopy.ScanGuidance.scanning
        case .analysingZones:
            return CleraCopy.ScanGuidance.analysing
        case .scanComplete:
            return CleraCopy.ScanGuidance.scanComplete
        case .scanFailed(let guidance):
            return guidance
        }
    }

    /// The accent color for the current state (for borders, glows, indicators)
    var accentColorName: String {
        switch self {
        case .idle, .detectingFace:
            return "border"
        case .faceNotAligned:
            return "accent"
        case .lightingCheck:
            return "accent"
        case .holdStill, .scanComplete:
            return "success"
        case .scanning:
            return "success"
        case .analysingZones:
            return "accent"
        case .scanFailed:
            return "warning"
        }
    }
}

/// Wraps the animation state in an observable object for SwiftUI bindings.
@MainActor
@Observable
final class ScanAnimationStateMachine {
    private(set) var state: ScanAnimationState = .idle
    private var holdStillStartTime: Date?
    private let holdStillDuration: TimeInterval = 0.8

    /// Updates state based on the latest scan readiness result.
    /// Call this on every frame update from the scan engine.
    func update(from result: ScanReadinessResult) {
        // Don't interrupt scanning or post-scan states
        guard !state.showScanningLine && !state.showZoneHighlights else { return }

        if !result.faceDetected {
            transition(to: .idle)
            return
        }

        if !result.faceCentered || result.faceTooSmall || result.faceTooLarge {
            let guidance = alignmentGuidance(from: result)
            transition(to: .faceNotAligned(guidance: guidance))
            return
        }

        if let pose = result.headPose, !pose.isFrontal {
            let guidance = headPoseGuidance(from: pose)
            transition(to: .faceNotAligned(guidance: guidance))
            return
        }

        if result.lightingQuality != .good || result.overexposed || result.shadowDetected {
            let guidance = lightingGuidance(from: result)
            transition(to: .lightingCheck(guidance: guidance))
            return
        }

        if result.blurScore < 0.15 {
            transition(to: .faceNotAligned(guidance: CleraCopy.ScanGuidance.holdSteady))
            return
        }

        // Face is aligned, lighting is good, not blurry
        // Require a short "hold still" confirmation before allowing scan
        if holdStillStartTime == nil {
            holdStillStartTime = Date()
            transition(to: .holdStill)
        } else if let start = holdStillStartTime,
                  Date().timeIntervalSince(start) >= holdStillDuration {
            transition(to: .holdStill)
        }
    }

    /// Call when the user taps capture to begin scanning.
    func beginScanning() {
        transition(to: .scanning(progress: 0))
    }

    /// Update scan progress (0.0 ... 1.0).
    func updateScanProgress(_ progress: Double) {
        transition(to: .scanning(progress: min(max(progress, 0), 1)))
    }

    /// Call when capture is complete to begin zone analysis animation.
    func beginZoneAnalysis(zoneCount: Int = 5) {
        transition(to: .analysingZones(currentZone: 0, totalZones: zoneCount))
    }

    /// Advance to the next zone in the analysis animation.
    func advanceZone() {
        if case .analysingZones(let current, let total) = state,
           current < total - 1 {
            transition(to: .analysingZones(currentZone: current + 1, totalZones: total))
        } else {
            transition(to: .scanComplete)
        }
    }

    /// Call when scan validation fails.
    func failScan(guidance: String) {
        holdStillStartTime = nil
        transition(to: .scanFailed(guidance: guidance))
    }

    /// Reset after a failed scan so the user can retry.
    func reset() {
        holdStillStartTime = nil
        transition(to: .idle)
    }

    // MARK: - Private

    private func transition(to newState: ScanAnimationState) {
        guard newState != state else { return }

        // Haptic feedback on significant transitions
        ScanHapticManager.shared.trigger(for: newState)

        state = newState
    }

    private func alignmentGuidance(from result: ScanReadinessResult) -> String {
        if result.faceTooSmall {
            return CleraCopy.ScanGuidance.moveCloser
        } else if result.faceTooLarge {
            return CleraCopy.ScanGuidance.moveBack
        } else if !result.faceCentered {
            return CleraCopy.ScanGuidance.centreFace
        } else {
            return CleraCopy.ScanGuidance.positionFace
        }
    }

    private func headPoseGuidance(from pose: HeadPose) -> String {
        if abs(pose.yaw) > 0.15 {
            return pose.yaw > 0
                ? CleraCopy.ScanGuidance.turnLeft
                : CleraCopy.ScanGuidance.turnRight
        } else if abs(pose.pitch) > 0.15 {
            return pose.pitch > 0
                ? CleraCopy.ScanGuidance.tiltUp
                : CleraCopy.ScanGuidance.tiltDown
        } else {
            return CleraCopy.ScanGuidance.holdSteady
        }
    }

    private func lightingGuidance(from result: ScanReadinessResult) -> String {
        if result.overexposed {
            return CleraCopy.ScanGuidance.reduceGlare
        } else if result.shadowDetected {
            return CleraCopy.ScanGuidance.reduceShadows
        } else if result.lightingQuality == .tooDark {
            return CleraCopy.ScanGuidance.brighterLight
        } else if result.lightingQuality == .tooBright {
            return CleraCopy.ScanGuidance.softerLight
        } else {
            return CleraCopy.ScanGuidance.improveLighting
        }
    }
}
