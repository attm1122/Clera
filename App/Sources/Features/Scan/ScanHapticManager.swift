import UIKit

/// Provides haptic feedback for scan state transitions.
/// Respects accessibility reduced-motion settings.
@MainActor
final class ScanHapticManager {
    static let shared = ScanHapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private var lastState: ScanAnimationState?
    private var hasPrepared = false

    private init() {}

    /// Call when the scan view appears to prepare haptics.
    func prepare() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        lightImpact.prepare()
        mediumImpact.prepare()
        softImpact.prepare()
        notification.prepare()
        selection.prepare()
        hasPrepared = true
    }

    /// Trigger the appropriate haptic for a state transition.
    func trigger(for state: ScanAnimationState) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        guard hasPrepared else { return }

        // Debounce: don't re-trigger for the same state
        guard state != lastState else { return }
        lastState = state

        switch state {
        case .idle, .detectingFace:
            // No haptic — too frequent
            break

        case .faceNotAligned:
            // Soft nudge when alignment shifts
            softImpact.impactOccurred(intensity: 0.4)

        case .lightingCheck:
            // Subtle hint that something needs attention
            softImpact.impactOccurred(intensity: 0.3)

        case .holdStill:
            // Light "lock" feedback — face is aligned
            lightImpact.impactOccurred(intensity: 0.6)
            // Also give selection feedback to indicate readiness
            selection.selectionChanged()

        case .scanning:
            // Medium impact to signal action beginning
            mediumImpact.impactOccurred(intensity: 0.5)

        case .analysingZones:
            // Gentle pulse per zone — handled separately via advanceZone
            break

        case .scanComplete:
            // Success!
            notification.notificationOccurred(.success)

        case .scanFailed:
            // Soft warning — not an error buzzer
            notification.notificationOccurred(.warning)
        }
    }

    /// Triggered when advancing through zone analysis.
    func zoneAdvanceHaptic(zoneIndex: Int) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        guard hasPrepared else { return }
        // Gentle ticking feel as zones are processed
        selection.selectionChanged()
    }

    /// Triggered on capture button press.
    func captureButtonPressed() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        guard hasPrepared else { return }
        mediumImpact.impactOccurred(intensity: 0.7)
    }

    /// Reset state tracking when the scan flow resets.
    func reset() {
        lastState = nil
    }
}
