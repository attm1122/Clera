import SwiftUI

/// Displays animated quality feedback states with calm, non-alarming language.
/// Shows soft icon + message transitions for lighting, blur, distance, angle, and success states.
struct QualityFeedbackOverlay: View {
    let state: ScanAnimationState
    let result: ScanReadinessResult

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 10) {
            feedbackIcon
                .frame(width: 36, height: 36)
                .background(feedbackIconBackground)

            VStack(alignment: .leading, spacing: 2) {
                Text(feedbackTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(feedbackTitleColor)

                Text(state.guidanceMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(CleraColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                .fill(feedbackBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                        .stroke(feedbackBorderColor, lineWidth: 1)
                )
        )
        .background(
            RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                .fill(feedbackBackground)
                .shadow(color: feedbackShadowColor, radius: 12, x: 0, y: 4)
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom).combined(with: .scale(scale: 0.95))),
            removal: .opacity.combined(with: .move(edge: .bottom))
        ))
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: state)
    }

    // MARK: - Icon

    @ViewBuilder
    private var feedbackIcon: some View {
        switch state {
        case .idle, .detectingFace:
            Image(systemName: "face.smiling")
                .font(.system(size: 18))
                .foregroundStyle(CleraColor.textSecondary)

        case .faceNotAligned:
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 16))
                .foregroundStyle(CleraColor.accent)
                .symbolEffect(.bounce, options: .repeating, value: isAnimating)

        case .lightingCheck:
            Image(systemName: "sun.max")
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: 0xD4A017))
                .symbolEffect(.pulse, options: .repeating, value: isAnimating)

        case .holdStill:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(CleraColor.success)

        case .scanning:
            Image(systemName: "viewfinder")
                .font(.system(size: 18))
                .foregroundStyle(CleraColor.success)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(isAnimating ? .linear(duration: 2).repeatForever(autoreverses: false) : .default, value: isAnimating)

        case .analysingZones:
            Image(systemName: "sparkles")
                .font(.system(size: 18))
                .foregroundStyle(CleraColor.accent)
                .scaleEffect(isAnimating ? 1.15 : 1.0)
                .animation(isAnimating ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isAnimating)

        case .scanComplete:
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22))
                .foregroundStyle(CleraColor.success)

        case .scanFailed:
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: 0xD4A017))
        }
    }

    private var feedbackIconBackground: some View {
        Circle()
            .fill(iconBackgroundColor)
    }

    // MARK: - Colors

    private var feedbackBackground: Color {
        switch state {
        case .idle, .detectingFace:
            return CleraColor.surface
        case .faceNotAligned:
            return CleraColor.accentSoft.opacity(0.5)
        case .lightingCheck:
            return Color(hex: 0xFFF8E7).opacity(0.8) // warm cream
        case .holdStill:
            return Color(hex: 0xF0F5E8).opacity(0.8) // soft green
        case .scanning:
            return Color(hex: 0xF0F5E8).opacity(0.8)
        case .analysingZones:
            return CleraColor.accentSoft.opacity(0.4)
        case .scanComplete:
            return Color(hex: 0xF0F5E8).opacity(0.9)
        case .scanFailed:
            return Color(hex: 0xFFF8E7).opacity(0.8)
        }
    }

    private var feedbackBorderColor: Color {
        switch state {
        case .idle, .detectingFace:
            return CleraColor.border
        case .faceNotAligned:
            return CleraColor.accent.opacity(0.3)
        case .lightingCheck:
            return Color(hex: 0xD4A017).opacity(0.3)
        case .holdStill, .scanning, .scanComplete:
            return CleraColor.success.opacity(0.3)
        case .analysingZones:
            return CleraColor.accent.opacity(0.25)
        case .scanFailed:
            return Color(hex: 0xD4A017).opacity(0.3)
        }
    }

    private var feedbackShadowColor: Color {
        switch state {
        case .holdStill, .scanComplete:
            return CleraColor.success.opacity(0.15)
        case .scanFailed:
            return Color(hex: 0xD4A017).opacity(0.1)
        default:
            return Color.black.opacity(0.06)
        }
    }

    private var iconBackgroundColor: Color {
        switch state {
        case .idle, .detectingFace:
            return CleraColor.surface
        case .faceNotAligned:
            return CleraColor.accent.opacity(0.1)
        case .lightingCheck:
            return Color(hex: 0xD4A017).opacity(0.1)
        case .holdStill, .scanning, .scanComplete:
            return CleraColor.success.opacity(0.12)
        case .analysingZones:
            return CleraColor.accent.opacity(0.1)
        case .scanFailed:
            return Color(hex: 0xD4A017).opacity(0.1)
        }
    }

    private var feedbackTitle: String {
        switch state {
        case .idle, .detectingFace:
            return "Positioning"
        case .faceNotAligned:
            return "Adjust position"
        case .lightingCheck:
            return "Lighting"
        case .holdStill:
            return "Hold still"
        case .scanning:
            return "Scanning"
        case .analysingZones:
            return "Analysing"
        case .scanComplete:
            return "Done"
        case .scanFailed:
            return "Let's try again"
        }
    }

    private var feedbackTitleColor: Color {
        switch state {
        case .idle, .detectingFace:
            return CleraColor.textSecondary
        case .faceNotAligned:
            return CleraColor.accent
        case .lightingCheck:
            return Color(hex: 0xB8860B)
        case .holdStill, .scanning, .scanComplete:
            return CleraColor.success
        case .analysingZones:
            return CleraColor.accent
        case .scanFailed:
            return Color(hex: 0xB8860B)
        }
    }

    // MARK: - Animation helpers

    private var isAnimating: Bool {
        switch state {
        case .faceNotAligned, .lightingCheck, .scanning, .analysingZones:
            return true
        default:
            return false
        }
    }
}

// MARK: - Mini indicator row (for the old guidance overlay replacement)

struct ScanMiniIndicators: View {
    let result: ScanReadinessResult

    var body: some View {
        HStack(spacing: 8) {
            miniIndicator(
                icon: "face.smiling",
                label: CleraCopy.ScanFlow.faceIndicator,
                active: result.faceDetected,
                color: result.faceDetected ? CleraColor.success : CleraColor.textSecondary
            )
            miniIndicator(
                icon: "target",
                label: CleraCopy.ScanFlow.centreIndicator,
                active: result.faceCentered,
                color: result.faceCentered ? CleraColor.success : CleraColor.textSecondary
            )
            miniIndicator(
                icon: "sun.max",
                label: CleraCopy.ScanFlow.lightIndicator,
                active: result.lightingQuality == .good,
                color: result.lightingQuality == .good ? CleraColor.success : CleraColor.textSecondary
            )
            miniIndicator(
                icon: "camera.aperture",
                label: CleraCopy.ScanFlow.sharpIndicator,
                active: result.blurScore >= 0.15,
                color: result.blurScore >= 0.15 ? CleraColor.success : CleraColor.textSecondary
            )
        }
    }

    private func miniIndicator(icon: String, label: String, active: Bool, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(active ? CleraColor.textPrimary : CleraColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
