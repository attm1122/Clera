import SwiftUI

/// Shows progressive timeline density states to encourage consistent scanning.
struct DataDensityBadge: View {
    let density: DataDensity

    var body: some View {
        if density.scanCount > 0 {
            HStack(spacing: CleraSpacing.sm) {
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(density.level.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)

                    Text(density.level.displayBody)
                        .font(.system(size: 12))
                        .foregroundStyle(CleraColor.textSecondary)
                        .lineLimit(2)

                    if let nextUnlock = density.nextUnlockDescription {
                        Text(nextUnlock)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CleraColor.accent)
                            .padding(.top, 2)
                    }
                }

                Spacer()
            }
            .padding(CleraSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                    .fill(CleraColor.accentSoft.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                    .stroke(CleraColor.accent.opacity(0.15), lineWidth: 1)
            )
        }
    }

    private var iconName: String {
        switch density.level {
        case .none: return "circle"
        case .baseline: return "record.circle"
        case .forming: return "chart.line.uptrend.xyaxis"
        case .earlyTrends: return "chart.bar"
        case .patternsEmerging: return "sparkles"
        case .personal: return "star.fill"
        }
    }
}
