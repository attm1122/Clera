import SwiftUI

struct InsightCard: View {
    let insight: Insight

    var body: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: iconForType(insight.type))
                        .font(.system(size: 14))
                        .foregroundStyle(colorForPriority(insight.priority))
                    Text(insight.type.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CleraColor.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Spacer()
                    priorityDot
                }

                Text(insight.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)

                Text(insight.body)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let zone = insight.zone {
                    HStack(spacing: 4) {
                        Image(systemName: zone.systemImage)
                            .font(.system(size: 10))
                        Text(zone.displayName)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(CleraColor.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(CleraColor.accentSoft)
                    )
                }
            }
        }
    }

    private var priorityDot: some View {
        Circle()
            .fill(colorForPriority(insight.priority))
            .frame(width: 8, height: 8)
    }

    private func iconForType(_ type: InsightType) -> String {
        switch type {
        case .improvement: "arrow.up.forward"
        case .regression: "arrow.down.forward"
        case .correlation: "link"
        case .productEffect: "drop"
        case .habit: "bed.double"
        case .environment: "sun.max"
        }
    }

    private func colorForPriority(_ priority: InsightPriority) -> Color {
        switch priority {
        case .high: .red
        case .medium: CleraColor.accent
        case .low: CleraColor.textSecondary
        }
    }
}
