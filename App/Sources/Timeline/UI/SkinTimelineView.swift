import SwiftUI

/// The unified Skin Timeline experience.
/// Combines scan history, insights, routine markers, confidence indicators, and visual diff.
struct SkinTimelineView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedSession: ScanSession?
    @State private var leftSession: ScanSession?
    @State private var rightSession: ScanSession?
    @State private var showWeeklySummary = false

    private var sessions: [ScanSession] {
        appModel.sessions.sorted(by: { $0.createdAt > $1.createdAt })
    }

    private var results: [SkinSessionResult] {
        appModel.skinSessionResults.sorted(by: { $0.createdAt > $1.createdAt })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                header
                dataDensitySection
                weeklySummaryCard
                nudgesSection
                timelineList
                Spacer(minLength: CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session)
        }
        .sheet(isPresented: .init(
            get: { leftSession != nil && rightSession != nil },
            set: { if !$0 { leftSession = nil; rightSession = nil } }
        )) {
            if let left = leftSession, let right = rightSession {
                PhotoComparisonView(leftSession: left, rightSession: right)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        CleraSectionHeader(
            eyebrow: CleraCopy.Timeline.title,
            title: CleraCopy.Timeline.subtitle,
            subtitle: CleraCopy.Timeline.body
        )
        .padding(.top, CleraSpacing.xl)
    }

    // MARK: - Data Density

    private var dataDensitySection: some View {
        DataDensityBadge(density: DataDensity(scanCount: sessions.count))
    }

    // MARK: - Weekly Summary

    @ViewBuilder
    private var weeklySummaryCard: some View {
        if let insight = appModel.weeklyInsights.first {
            Button {
                showWeeklySummary = true
            } label: {
                CleraCard {
                    VStack(alignment: .leading, spacing: CleraSpacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(CleraCopy.Progress.thisWeeksInsight)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(CleraColor.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(0.8)
                                Text(insight.summaryTitle)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(CleraColor.textPrimary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(CleraColor.textSecondary)
                        }

                        HStack(spacing: CleraSpacing.md) {
                            if let topZone = insight.zoneHighlights.first {
                                HStack(spacing: 4) {
                                    Image(systemName: topZone.zone.systemImage)
                                        .font(.system(size: 12))
                                    Text("\(topZone.zone.displayName): \(topZone.trend.displayName)")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(topZone.trend.color)
                            }
                            if let topContributor = insight.possibleContributors.first {
                                HStack(spacing: 4) {
                                    Image(systemName: "lightbulb")
                                        .font(.system(size: 12))
                                    Text(topContributor.type.displayName)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(CleraColor.accent)
                            }
                        }

                        Text(insight.recommendedNextStep)
                            .font(.system(size: 13))
                            .foregroundStyle(CleraColor.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showWeeklySummary) {
                WeeklySummaryView(insight: insight)
            }
        }
    }

    // MARK: - Nudges

    private var nudgesSection: some View {
        let activeNudges = appModel.nudges.filter { !$0.isDismissed && ($0.expiresAt == nil || $0.expiresAt! > Date()) }
        return ForEach(activeNudges.prefix(2)) { nudge in
            nudgeCard(nudge: nudge)
        }
    }

    private func nudgeCard(nudge: Nudge) -> some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                HStack {
                    Text(nudge.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)
                    Spacer()
                    Button {
                        appModel.dismissNudge(id: nudge.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                }

                Text(nudge.body)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionLabel = nudge.actionLabel {
                    Button(actionLabel) {
                        handleNudgeAction(route: nudge.actionRoute)
                    }
                    .buttonStyle(CleraSecondaryButtonStyle())
                }
            }
        }
    }

    private func handleNudgeAction(route: String?) {
        guard let route = route else { return }
        switch route {
        case "scan":
            appModel.selectedTab = .today
        case "timeline":
            // Already on timeline — no action needed
            break
        case "routine":
            appModel.selectedTab = .routine
        default:
            break
        }
    }

    // MARK: - Timeline List

    private var timelineList: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            if sessions.isEmpty {
                emptyState
            } else {
                ForEach(sessions) { session in
                    timelineItem(session: session)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: CleraSpacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 42))
                .foregroundStyle(CleraColor.border)
            Text(CleraCopy.Timeline.noScansYet)
                .font(.system(size: 15))
                .foregroundStyle(CleraColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CleraSpacing.xl)
    }

    private func timelineItem(session: ScanSession) -> some View {
        let result = results.first(where: { $0.sessionId == session.id })
        let enrichment = result?.timelineEnrichment

        return Button {
            selectedSession = session
        } label: {
            CleraCard {
                VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(CleraColor.textSecondary)

                            if let whatChanged = enrichment?.whatChanged,
                               let primary = whatChanged.primaryChange {
                                Text(primary.message)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(CleraColor.textPrimary)
                                    .lineLimit(2)
                            } else {
                                Text(session.kind == .baseline ? "Baseline scan" : "Daily scan")
                                    .font(.system(size: 14))
                                    .foregroundStyle(CleraColor.textPrimary)
                            }
                        }

                        Spacer()

                        TimelineConfidenceBar(
                            confidence: result?.confidenceSummary.overall ?? 0.5,
                            consistency: enrichment?.scanConsistency
                        )
                    }

                    if let markers = enrichment?.markers, !markers.isEmpty {
                        TimelineMarkerRow(markers: markers)
                    }

                    if let consistency = enrichment?.scanConsistency, !consistency.isAcceptable {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: 0xD4A017))
                            Text(CleraCopy.Timeline.consistencyWarning)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: 0xB8860B))
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
