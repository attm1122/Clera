import SwiftUI

/// Animates the sequential highlighting of skin zones after capture.
/// Shows soft translucent overlays over each zone in turn.
struct ZoneDetectionAnimationView: View {
    let currentZone: Int
    let totalZones: Int
    let onZoneComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let zoneNames = ["Forehead", "Nose", "Left cheek", "Right cheek", "Chin & jaw"]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Zone overlays
                ForEach(0..<min(totalZones, zoneNames.count), id: \.self) { index in
                    zoneOverlay(
                        index: index,
                        geometry: geometry
                    )
                }

                // Zone label
                zoneLabel
            }
        }
        .onAppear {
            triggerZoneHaptic()
            if !reduceMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onZoneComplete()
                }
            } else {
                onZoneComplete()
            }
        }
    }

    // MARK: - Zone Overlay

    private func zoneOverlay(index: Int, geometry: GeometryProxy) -> some View {
        let isActive = index == currentZone
        let isPast = index < currentZone

        return zoneShape(for: index, in: geometry)
            .fill(
                isActive
                    ? CleraColor.accent.opacity(0.15)
                    : CleraColor.success.opacity(isPast ? 0.08 : 0.0)
            )
            .overlay(
                zoneShape(for: index, in: geometry)
                    .stroke(
                        isActive ? CleraColor.accent.opacity(0.6) : CleraColor.success.opacity(isPast ? 0.3 : 0.0),
                        lineWidth: isActive ? 2 : 1
                    )
            )
            .scaleEffect(isActive ? 1.02 : 1.0)
            .opacity(isActive ? 1 : (isPast ? 0.6 : 0))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: currentZone)
    }

    // MARK: - Zone Shapes

    private func zoneShape(for index: Int, in geometry: GeometryProxy) -> Path {
        let w = geometry.size.width
        let h = geometry.size.height
        let cx = w / 2
        let cy = h / 2

        // Approximate face proportions within the oval guide
        let faceTop = cy - h * 0.28
        let faceBottom = cy + h * 0.32
        let faceLeft = cx - w * 0.18
        let faceRight = cx + w * 0.18
        let midY = cy - h * 0.02

        switch index {
        case 0: // Forehead
            return foreheadPath(
                top: faceTop,
                bottom: midY - h * 0.08,
                left: faceLeft,
                right: faceRight
            )
        case 1: // Nose
            return nosePath(
                top: midY - h * 0.08,
                bottom: midY + h * 0.12,
                centerX: cx,
                width: w * 0.08
            )
        case 2: // Left cheek
            return cheekPath(
                top: midY - h * 0.06,
                bottom: faceBottom - h * 0.06,
                left: faceLeft,
                right: cx - w * 0.02
            )
        case 3: // Right cheek
            return cheekPath(
                top: midY - h * 0.06,
                bottom: faceBottom - h * 0.06,
                left: cx + w * 0.02,
                right: faceRight
            )
        case 4: // Chin & jaw
            return chinPath(
                top: faceBottom - h * 0.08,
                bottom: faceBottom,
                left: faceLeft + w * 0.04,
                right: faceRight - w * 0.04
            )
        default:
            return Path()
        }
    }

    private func foreheadPath(top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat) -> Path {
        var path = Path()
        let width = right - left
        let cornerRadius: CGFloat = width * 0.35
        path.addRoundedRect(
            in: CGRect(x: left, y: top, width: width, height: bottom - top),
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius),
            style: .continuous
        )
        return path
    }

    private func nosePath(top: CGFloat, bottom: CGFloat, centerX: CGFloat, width: CGFloat) -> Path {
        var path = Path()
        let left = centerX - width / 2
        let w = width
        let h = bottom - top

        path.move(to: CGPoint(x: centerX, y: top))
        path.addLine(to: CGPoint(x: left + w, y: top + h * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: left, y: top + h * 0.3),
            control: CGPoint(x: centerX, y: bottom - h * 0.1)
        )
        path.closeSubpath()
        return path
    }

    private func cheekPath(top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = (right - left) * 0.3
        path.addRoundedRect(
            in: CGRect(x: left, y: top, width: right - left, height: bottom - top),
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius),
            style: .continuous
        )
        return path
    }

    private func chinPath(top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat) -> Path {
        var path = Path()
        let width = right - left
        let height = bottom - top
        let cornerRadius = min(width, height) * 0.4
        path.addRoundedRect(
            in: CGRect(x: left, y: top, width: width, height: height),
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius),
            style: .continuous
        )
        return path
    }

    // MARK: - Zone Label

    private var zoneLabel: some View {
        VStack(spacing: 6) {
            if currentZone < zoneNames.count {
                Text(zoneNames[currentZone])
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(CleraColor.surface)
                            .shadow(color: CleraColor.border.opacity(0.5), radius: 4, x: 0, y: 2)
                    )
            }

            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<min(totalZones, zoneNames.count), id: \.self) { index in
                    Circle()
                        .fill(index <= currentZone ? CleraColor.accent : CleraColor.border)
                        .frame(width: index == currentZone ? 8 : 6, height: index == currentZone ? 8 : 6)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: currentZone)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 20)
    }

    private func triggerZoneHaptic() {
        ScanHapticManager.shared.zoneAdvanceHaptic(zoneIndex: currentZone)
    }
}


