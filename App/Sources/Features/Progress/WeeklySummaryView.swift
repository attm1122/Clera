import SwiftUI

struct WeeklySummaryView: View {
    let insight: WeeklyInsight
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    header
                    overallTrendCard
                    zoneHighlightsSection
                    contributorsSection
                    nextStepCard
                    disclaimerCard
                    Spacer(minLength: CleraSpacing.xl)
                }
                .padding(.horizontal, CleraSpacing.lg)
                .padding(.top, CleraSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(CleraColor.background)
            .navigationTitle(CleraCopy.WeeklySummary.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(CleraColor.accent)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(insight.weekEnding.formatted(date: .long, time: .omitted))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CleraColor.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(insight.summaryTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(CleraColor.textPrimary)
            Text(insight.summaryText)
                .font(.system(size: 15))
                .foregroundStyle(CleraColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    private var overallTrendCard: some View {
        let trend = overallTrendFromHighlights()
        return CleraCard {
            HStack(spacing: CleraSpacing.md) {
                Image(systemName: trend.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(trend.color)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(trend.color.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(CleraCopy.WeeklySummary.overallTrend)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CleraColor.textSecondary)
                    Text(trend.displayName)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(trend.color)
                }

                Spacer()

                confidenceBadge(insight.confidenceLevel)
            }
        }
    }

    private var zoneHighlightsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.WeeklySummary.zoneChanges)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            if insight.zoneHighlights.isEmpty {
                Text(CleraCopy.State.noZones)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                ForEach(insight.zoneHighlights) { highlight in
                    zoneHighlightCard(highlight: highlight)
                }
            }
        }
    }

    private func zoneHighlightCard(highlight: ZoneHighlight) -> some View {
        CleraCard {
            HStack(spacing: CleraSpacing.md) {
                Image(systemName: highlight.zone.systemImage)
                    .font(.system(size: 20))
                    .foregroundStyle(highlight.trend.color)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                            .fill(highlight.trend.color.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(highlight.zone.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(CleraColor.textPrimary)
                        Text("· \(highlight.primaryMetric)")
                            .font(.system(size: 13))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                    Text(highlight.description)
                        .font(.system(size: 13))
                        .foregroundStyle(CleraColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                trendMiniBadge(highlight.trend)
            }
        }
    }

    private var contributorsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.WeeklySummary.possibleContributors)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            if insight.possibleContributors.isEmpty {
                Text(CleraCopy.State.noContributors)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                ForEach(insight.possibleContributors) { contributor in
                    contributorCard(contributor: contributor)
                }
            }
        }
    }

    private func contributorCard(contributor: Contributor) -> some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: contributorIcon(contributor.type))
                            .font(.system(size: 12))
                            .foregroundStyle(CleraColor.accent)
                        Text(contributor.type.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CleraColor.accent)
                    }
                    Spacer()
                    confidenceBadge(contributor.confidence)
                }
                Text(contributor.description)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var nextStepCard: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.forward.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(CleraColor.success)
                    Text(CleraCopy.WeeklySummary.nextBestAction)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CleraColor.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                Text(insight.recommendedNextStep)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(CleraColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                .stroke(CleraColor.success.opacity(0.3), lineWidth: 1.5)
        )
    }

    private var disclaimerCard: some View {
        HStack(spacing: CleraSpacing.sm) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundStyle(CleraColor.textSecondary)
            Text(insight.safetyDisclaimer)
                .font(.system(size: 12))
                .foregroundStyle(CleraColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(CleraSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                .fill(CleraColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                .stroke(CleraColor.border, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func overallTrendFromHighlights() -> ZoneTrend {
        let improving = insight.zoneHighlights.filter { $0.trend == .improving }.count
        let worsening = insight.zoneHighlights.filter { $0.trend == .worsening }.count
        if worsening > improving { return .worsening }
        if improving > worsening { return .improving }
        return .stable
    }

    private func trendMiniBadge(_ trend: ZoneTrend) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.system(size: 10, weight: .bold))
            Text(trend.displayName)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(trend.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(trend.color.opacity(0.1))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(trend.color.opacity(0.2), lineWidth: 1)
        )
    }

    private func confidenceBadge(_ confidence: InsightConfidence) -> some View {
        Text(confidence.displayName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(confidenceColor(confidence))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(confidenceColor(confidence).opacity(0.1))
            )
    }

    private func confidenceColor(_ confidence: InsightConfidence) -> Color {
        switch confidence {
        case .high: CleraColor.success
        case .moderate: CleraColor.accent
        case .low: CleraColor.textSecondary
        }
    }

    private func contributorIcon(_ type: ContributorType) -> String {
        switch type {
        case .routine: "checklist"
        case .product: "drop"
        case .environment: "cloud.sun"
        case .habit: "bed.double"
        case .scanQuality: "camera"
        case .unknown: "questionmark.circle"
        }
    }
}
