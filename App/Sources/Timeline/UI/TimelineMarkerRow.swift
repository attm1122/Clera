import SwiftUI

/// Shows routine and environmental markers as small pills on the timeline.
struct TimelineMarkerRow: View {
    let markers: [TimelineMarker]

    var body: some View {
        if !markers.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(markers) { marker in
                        markerPill(marker: marker)
                    }
                }
            }
        }
    }

    private func markerPill(marker: TimelineMarker) -> some View {
        HStack(spacing: 4) {
            Image(systemName: marker.type.systemImage)
                .font(.system(size: 10))
            Text(marker.label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(markerColor(for: marker.type))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(markerColor(for: marker.type).opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(markerColor(for: marker.type).opacity(0.2), lineWidth: 1)
        )
    }

    private func markerColor(for type: TimelineMarker.MarkerType) -> Color {
        switch type.color {
        case "accent": return CleraColor.accent
        case "success": return CleraColor.success
        case "warning": return Color(hex: 0xD4A017)
        case "textPrimary": return CleraColor.textPrimary
        case "textSecondary": return CleraColor.textSecondary
        default: return CleraColor.textSecondary
        }
    }
}
