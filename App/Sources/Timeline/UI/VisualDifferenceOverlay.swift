import SwiftUI

/// Overlays highlighted zone boundaries on a photo to show where changes occurred.
struct VisualDifferenceOverlay: View {
    let zones: [ZoneHighlight]
    let imageSize: CGSize

    struct ZoneHighlight: Identifiable {
        let id = UUID()
        let zone: ZoneType
        let direction: ChangeDirection
        let intensity: Double // 0.0 ... 1.0
    }

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / imageSize.width, geo.size.height / imageSize.height)
            let offsetX = (geo.size.width - imageSize.width * scale) / 2
            let offsetY = (geo.size.height - imageSize.height * scale) / 2

            ZStack {
                ForEach(zones) { highlight in
                    ZoneOverlayShape(zone: highlight.zone)
                        .fill(highlight.color.opacity(0.25 + highlight.intensity * 0.5))
                        .scaleEffect(scale)
                        .offset(x: offsetX, y: offsetY)

                    ZoneOverlayShape(zone: highlight.zone)
                        .stroke(highlight.color, lineWidth: 2)
                        .scaleEffect(scale)
                        .offset(x: offsetX, y: offsetY)
                }
            }
        }
    }
}

private extension VisualDifferenceOverlay.ZoneHighlight {
    var color: Color {
        switch direction {
        case .increasing:
            return Color(hex: 0xC75B39) // warm warning red
        case .decreasing:
            return Color(hex: 0x4A7C59) // success green
        case .stable:
            return Color(hex: 0x996C48) // copper accent
        }
    }
}

private struct ZoneOverlayShape: Shape {
    let zone: ZoneType

    var rect: CGRect {
        switch zone {
        case .forehead:
            return CGRect(x: 0.25, y: 0.05, width: 0.50, height: 0.20)
        case .nose:
            return CGRect(x: 0.35, y: 0.30, width: 0.30, height: 0.25)
        case .leftCheek:
            return CGRect(x: 0.05, y: 0.35, width: 0.30, height: 0.25)
        case .rightCheek:
            return CGRect(x: 0.65, y: 0.35, width: 0.30, height: 0.25)
        case .chinJaw:
            return CGRect(x: 0.25, y: 0.60, width: 0.50, height: 0.30)
        }
    }

    func path(in bounds: CGRect) -> Path {
        Path(
            CGRect(
                x: rect.origin.x * bounds.width,
                y: rect.origin.y * bounds.height,
                width: rect.width * bounds.width,
                height: rect.height * bounds.height
            )
        )
    }
}
