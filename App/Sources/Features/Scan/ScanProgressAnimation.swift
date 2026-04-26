import SwiftUI

/// A gentle scanning line that moves vertically across the face frame.
/// Uses a soft glow rather than a harsh laser effect.
struct ScanProgressAnimation: View {
    let progress: Double // 0.0 ... 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let scanY = geometry.size.height * (1.0 - progress)

            ZStack {
                // Soft vertical glow beam
                glowBeam(at: scanY, width: geometry.size.width)

                // The scanning line itself
                scanLine(at: scanY, width: geometry.size.width)

                // Subtle horizontal flare at the line
                flare(at: scanY, width: geometry.size.width)
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Subviews

    private func glowBeam(at y: CGFloat, width: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        CleraColor.success.opacity(0.0),
                        CleraColor.success.opacity(0.15),
                        CleraColor.success.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width, height: 80)
            .position(x: width / 2, y: y)
            .blur(radius: 12)
    }

    private func scanLine(at y: CGFloat, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        CleraColor.success.opacity(0.3),
                        CleraColor.success.opacity(0.9),
                        CleraColor.success.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width * 0.75, height: 2.5)
            .position(x: width / 2, y: y)
            .shadow(color: CleraColor.success.opacity(0.6), radius: 6, x: 0, y: 0)
    }

    private func flare(at y: CGFloat, width: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        CleraColor.success.opacity(0.0),
                        CleraColor.success.opacity(0.5),
                        CleraColor.success.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width * 0.4, height: 1)
            .position(x: width / 2, y: y)
            .blur(radius: 3)
    }
}

/// A container that animates the scanning line over a fixed duration.
struct ScanProgressContainer: View {
    let duration: TimeInterval
    let onComplete: () -> Void

    @State private var progress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScanProgressAnimation(progress: progress)
            .onAppear {
                if reduceMotion {
                    // Jump to complete for reduced motion
                    progress = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onComplete()
                    }
                } else {
                    withAnimation(.easeInOut(duration: duration)) {
                        progress = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                        onComplete()
                    }
                }
            }
    }
}
