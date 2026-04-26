import SwiftUI

/// A post-scan card showing the primary and secondary skin changes.
/// Uses safe cosmetic language and confidence-aware styling.
struct WhatChangedCard: View {
    let result: WhatChangedResult?
    let onViewTimeline: () -> Void

    var body: some View {
        if let result = result, result.hasChanges {
            CleraCard {
                VStack(alignment: .leading, spacing: CleraSpacing.md) {
                    header

                    if let primary = result.primaryChange {
                        changeRow(item: primary, isPrimary: true)
                    }

                    if let secondary = result.secondaryChange {
                        Divider()
                            .foregroundStyle(CleraColor.border)
                        changeRow(item: secondary, isPrimary: false)
                    }

                    Button(CleraCopy.Timeline.viewTimeline) {
                        onViewTimeline()
                    }
                    .buttonStyle(CleraSecondaryButtonStyle())
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(CleraCopy.Timeline.whatChangedTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CleraColor.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(result?.overallMessage ?? "")
                    .font(.system(size: 15))
                    .foregroundStyle(CleraColor.textPrimary)
                    .lineLimit(2)
            }
            Spacer()
        }
    }

    private func changeRow(item: WhatChangedItem, isPrimary: Bool) -> some View {
        HStack(spacing: CleraSpacing.md) {
            changeIcon(for: item.trend)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(changeBackgroundColor(for: item.trend).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CleraColor.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    ConfidencePill(confidence: item.confidence)

                    if isPrimary {
                        Text(CleraCopy.Timeline.primaryInsight)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CleraColor.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(CleraColor.accentSoft)
                            )
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func changeIcon(for trend: ChangeDirection) -> some View {
        Image(systemName: trend == .increasing ? "arrow.up.circle" : trend == .decreasing ? "arrow.down.circle" : "minus.circle")
            .font(.system(size: 18))
            .foregroundStyle(changeColor(for: trend))
    }

    private func changeColor(for trend: ChangeDirection) -> Color {
        switch trend {
        case .increasing: return CleraColor.accent
        case .decreasing: return CleraColor.success
        case .stable: return CleraColor.textSecondary
        }
    }

    private func changeBackgroundColor(for trend: ChangeDirection) -> Color {
        switch trend {
        case .increasing: return CleraColor.accent
        case .decreasing: return CleraColor.success
        case .stable: return CleraColor.textSecondary
        }
    }
}

struct ConfidencePill: View {
    let confidence: InsightConfidence

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(confidenceColor)
                .frame(width: 6, height: 6)
            Text(confidence.displayName)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(confidenceColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous)
                .fill(confidenceColor.opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(confidenceColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var confidenceColor: Color {
        switch confidence {
        case .high: return CleraColor.success
        case .moderate: return CleraColor.accent
        case .low: return CleraColor.textSecondary
        }
    }
}
