import SwiftUI

/// A soft oval face frame that animates based on scan state.
/// Shows gentle motion when face is not aligned, locks steady when ready.
struct FacePositioningGuideView: View {
    let state: ScanAnimationState
    let faceBounds: CGRect?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLocked: Bool { state.isFaceLocked }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background dim when face is detected and aligned
                if isLocked {
                    lockedBackground
                }

                // The oval face frame
                ovalFrame(in: geometry)

                // Corner brackets for precision alignment
                cornerBrackets(in: geometry)
            }
        }
    }

    // MARK: - Oval Frame

    private func ovalFrame(in geometry: GeometryProxy) -> some View {
        let ovalSize = CGSize(width: 200, height: 260)
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

        return FaceOvalShape()
            .stroke(
                frameColor,
                style: StrokeStyle(
                    lineWidth: isLocked ? 3 : 2,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: isLocked ? [] : [8, 6]
                )
            )
            .frame(width: ovalSize.width, height: ovalSize.height)
            .position(center)
            .shadow(color: frameColor.opacity(isLocked ? 0.5 : 0.2), radius: isLocked ? 12 : 6, x: 0, y: 0)
            .scaleEffect(scaleAmount)
            .opacity(opacityAmount)
            .animation(reduceMotion ? nil : animation, value: isLocked)
            .animation(reduceMotion ? nil : animation, value: state)
    }

    // MARK: - Corner Brackets

    private func cornerBrackets(in geometry: GeometryProxy) -> some View {
        let ovalSize = CGSize(width: 200, height: 260)
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let offsetX = ovalSize.width / 2
        let offsetY = ovalSize.height / 2

        return ZStack {
            // Top-left
            cornerBracket(
                at: CGPoint(x: center.x - offsetX, y: center.y - offsetY),
                rotation: .degrees(0)
            )
            // Top-right
            cornerBracket(
                at: CGPoint(x: center.x + offsetX, y: center.y - offsetY),
                rotation: .degrees(90)
            )
            // Bottom-right
            cornerBracket(
                at: CGPoint(x: center.x + offsetX, y: center.y + offsetY),
                rotation: .degrees(180)
            )
            // Bottom-left
            cornerBracket(
                at: CGPoint(x: center.x - offsetX, y: center.y + offsetY),
                rotation: .degrees(270)
            )
        }
        .opacity(isLocked ? 1 : 0.4)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: isLocked)
    }

    private func cornerBracket(at position: CGPoint, rotation: Angle) -> some View {
        LShape()
            .stroke(frameColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 18, height: 18)
            .position(position)
            .rotationEffect(rotation, anchor: .center)
    }

    // MARK: - Locked Background

    private var lockedBackground: some View {
        FaceOvalShape()
            .fill(CleraColor.success.opacity(0.06))
            .frame(width: 200, height: 260)
            .blur(radius: 8)
    }

    // MARK: - Dynamic Properties

    private var frameColor: Color {
        switch state {
        case .idle, .detectingFace:
            return CleraColor.border
        case .faceNotAligned:
            return CleraColor.accent
        case .lightingCheck:
            return CleraColor.accent.opacity(0.8)
        case .holdStill:
            return CleraColor.success
        case .scanning:
            return CleraColor.success
        case .analysingZones:
            return CleraColor.accent
        case .scanComplete:
            return CleraColor.success
        case .scanFailed:
            return Color(hex: 0xD4A017) // warm amber warning
        }
    }

    private var scaleAmount: CGFloat {
        switch state {
        case .idle, .detectingFace:
            return 1.0
        case .faceNotAligned:
            return 1.02 // subtle pulse to draw attention
        case .lightingCheck:
            return 1.0
        case .holdStill:
            return 0.98 // slight shrink to feel "locked in"
        case .scanning:
            return 0.96
        case .analysingZones:
            return 1.0
        case .scanComplete:
            return 1.0
        case .scanFailed:
            return 1.03
        }
    }

    private var opacityAmount: Double {
        switch state {
        case .idle, .detectingFace:
            return 0.6
        case .faceNotAligned:
            return 0.9
        case .lightingCheck:
            return 0.85
        case .holdStill:
            return 1.0
        case .scanning:
            return 0.9
        case .analysingZones:
            return 0.7
        case .scanComplete:
            return 1.0
        case .scanFailed:
            return 0.9
        }
    }

    private var animation: Animation {
        switch state {
        case .idle, .detectingFace:
            return .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
        case .faceNotAligned:
            return .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        case .holdStill:
            return .spring(response: 0.4, dampingFraction: 0.7)
        case .scanning:
            return .easeInOut(duration: 0.5)
        case .scanFailed:
            return .easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)
        default:
            return .easeInOut(duration: 0.4)
        }
    }
}

// MARK: - Shapes

/// A softened oval shape for the face guide.
struct FaceOvalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = min(rect.width, rect.height) * 0.48
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        return path
    }
}

/// An L-shaped corner bracket.
struct LShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let armLength = rect.width
        let thickness: CGFloat = 2.5

        // Horizontal arm
        path.move(to: CGPoint(x: 0, y: thickness / 2))
        path.addLine(to: CGPoint(x: armLength, y: thickness / 2))

        // Vertical arm
        path.move(to: CGPoint(x: thickness / 2, y: 0))
        path.addLine(to: CGPoint(x: thickness / 2, y: armLength))

        return path.strokedPath(StrokeStyle(lineWidth: thickness, lineCap: .round))
    }
}
