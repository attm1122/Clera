import SwiftUI

/// A single insight row for the timeline, with confidence and zone info.
struct TimelineInsightRow: View {
    let insight: Insight
    let confidence: InsightConfidence?

    var body: some View {
        HStack(spacing: CleraSpacing.md) {
            insightIcon
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                        .fill(insightColor.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)
                    .lineLimit(2)

                Text(insight.body)
                    .font(.system(size: 13))
                    .foregroundStyle(CleraColor.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let confidence = confidence {
                    ConfidencePill(confidence: confidence)
                        .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var insightIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 16))
            .foregroundStyle(insightColor)
    }

    private var iconName: String {
        switch insight.type {
        case .improvement: return "arrow.down.circle"
        case .regression: return "arrow.up.circle"
        case .correlation: return "link"
        case .productEffect: return "drop"
        case .habit: return "bed.double"
        case .environment: return "cloud.sun"
        }
    }

    private var insightColor: Color {
        switch insight.type {
        case .improvement: return CleraColor.success
        case .regression: return CleraColor.accent
        case .correlation: return CleraColor.accent
        case .productEffect: return CleraColor.accent
        case .habit: return CleraColor.textSecondary
        case .environment: return CleraColor.textSecondary
        }
    }
}
