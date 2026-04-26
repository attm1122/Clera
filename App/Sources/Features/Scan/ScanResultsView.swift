import SwiftUI

struct ScanResultsView: View {
    @Environment(AppModel.self) private var appModel
    let note: String
    let onDone: () -> Void

    private var result: SkinSessionResult? {
        appModel.latestSkinSessionResult
    }

    private var skinMap: SkinMap {
        result?.skinMap ?? appModel.currentSkinMap
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                CleraSectionHeader(
                    eyebrow: CleraCopy.ScanFlow.scanCompleteTitle,
                    title: CleraCopy.ScanFlow.scanResultsTitle,
                    subtitle: CleraCopy.ScanFlow.scanResultsBody
                )
                .padding(.top, CleraSpacing.xl)

                qualityCard

                zoneResultsCard

                if !note.isEmpty {
                    noteCard
                }

                disclaimerCard

                HStack(spacing: CleraSpacing.md) {
                    Button(CleraCopy.Timeline.viewTimeline) {
                        appModel.selectedTab = .progress
                        onDone()
                    }
                    .buttonStyle(CleraSecondaryButtonStyle())

                    Button(CleraCopy.ScanFlow.done) {
                        onDone()
                    }
                    .buttonStyle(CleraPrimaryButtonStyle())
                }
                .padding(.bottom, CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
    }

    private var qualityCard: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                HStack {
                    Text("Scan Quality")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)
                    Spacer()
                    qualityBadge
                }

                if let issues = result?.userMessages, !issues.isEmpty {
                    ForEach(issues, id: \.self) { issue in
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                                .foregroundStyle(CleraColor.textSecondary)
                            Text(issue)
                                .font(.system(size: 13))
                                .foregroundStyle(CleraColor.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var qualityBadge: some View {
        let status = result?.scanStatus ?? .accepted
        return HStack(spacing: 4) {
            Image(systemName: status == .accepted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 12))
            Text(status.displayName)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(status == .accepted ? CleraColor.success : Color(hex: 0xD4A017))
    }

    private var zoneResultsCard: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                Text("Zone Analysis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)

                ForEach(skinMap.zones) { zone in
                    zoneRow(zone: zone)
                    if zone.id != skinMap.zones.last?.id {
                        Divider()
                            .foregroundStyle(CleraColor.border)
                    }
                }
            }
        }
    }

    private func zoneRow(zone: FaceZone) -> some View {
        let topMetrics = zone.status.metrics
            .filter { $0.severity != .none }
            .sorted { severityScore($0.severity) > severityScore($1.severity) }
            .prefix(2)

        return HStack(spacing: CleraSpacing.md) {
            Image(systemName: zone.zoneType.systemImage)
                .font(.system(size: 22))
                .foregroundStyle(zone.status.overallSeverity.color)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                        .fill(zone.status.overallSeverity.color.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(zone.zoneType.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)

                if topMetrics.isEmpty {
                    Text("Looking clear")
                        .font(.system(size: 13))
                        .foregroundStyle(CleraColor.textSecondary)
                } else {
                    HStack(spacing: 8) {
                        ForEach(Array(topMetrics.enumerated()), id: \.offset) { _, metric in
                            metricPill(label: metric.label, value: metric.severity.displayName, color: metric.severity.color)
                        }
                    }
                }
            }

            Spacer()

            if zone.status.overallTrend != .unknown {
                HStack(spacing: 4) {
                    Image(systemName: zone.status.overallTrend.icon)
                        .font(.system(size: 10))
                    Text(zone.status.overallTrend.displayName)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(zone.status.overallTrend.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(zone.status.overallTrend.color.opacity(0.1))
                )
            }
        }
        .padding(.vertical, 4)
    }

    private func metricPill(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(CleraColor.textSecondary)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    private var noteCard: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                Text(CleraCopy.ScanFlow.yourNote)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CleraColor.textSecondary)
                Text(note)
                    .font(.system(size: 15))
                    .foregroundStyle(CleraColor.textPrimary)
            }
        }
    }

    private var disclaimerCard: some View {
        HStack(spacing: CleraSpacing.sm) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundStyle(CleraColor.textSecondary)
            Text(SkinInsightGenerator.disclaimer)
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

    private func severityScore(_ severity: ZoneSeverity) -> Int {
        switch severity {
        case .none: return 0
        case .low: return 1
        case .moderate: return 2
        case .high: return 3
        }
    }
}
