import SwiftUI

struct ZoneDetailView: View {
    let zone: FaceZone
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    header
                    statusGrid
                    trendSection
                    historySection
                    notesSection
                    Spacer(minLength: CleraSpacing.xl)
                }
                .padding(.horizontal, CleraSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(CleraColor.background)
            .navigationTitle(zone.zoneType.displayName)
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
        CleraCard {
            HStack {
                Image(systemName: zone.zoneType.systemImage)
                    .font(.system(size: 40))
                    .foregroundStyle(zone.status.overallSeverity.color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(CleraCopy.SkinMap.currentStatus)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CleraColor.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text(zone.status.overallSeverity.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(zone.status.overallSeverity.color)
                }
                Spacer()
            }
        }
    }

    private var statusGrid: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.SkinMap.visibleSigns)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            let metrics = zone.status.metrics
            ForEach(metrics.indices, id: \.self) { index in
                let metric = metrics[index]
                metricRow(label: metric.label, severity: metric.severity, trend: metric.trend)
                if index < metrics.count - 1 {
                    Divider()
                        .foregroundStyle(CleraColor.border)
                }
            }
        }
    }

    private func metricRow(label: String, severity: ZoneSeverity, trend: ZoneTrend) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: severity.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(severity.color)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CleraColor.textPrimary)
            }
            Spacer()
            HStack(spacing: 6) {
                if trend != .unknown {
                    HStack(spacing: 2) {
                        Image(systemName: trend.icon)
                            .font(.system(size: 10))
                        Text(trend.displayName)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(trend.color)
                }
                Text(severity.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(severity.color)
            }
        }
        .padding(.vertical, 4)
    }

    private var trendSection: some View {
        let overall = zone.status.overallTrend
        guard overall != .unknown else { return AnyView(EmptyView()) }
        return AnyView(
            CleraCard {
                HStack {
                    Image(systemName: overall.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(overall.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(CleraCopy.SkinMap.overallTrend)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(CleraColor.textSecondary)
                        Text(overall.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(overall.color)
                    }
                    Spacer()
                }
            }
        )
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.SkinMap.history)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            let zoneHistory = appModel.skinMapHistory.compactMap { map -> (Date, ZoneStatus, SkinMapCheckIn?)? in
                guard let z = map.zones.first(where: { $0.zoneType == zone.zoneType }) else { return nil }
                return (map.date, z.status, map.checkIn)
            }

            if zoneHistory.isEmpty {
                Text(CleraCopy.SkinMap.noHistory)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                ForEach(zoneHistory.indices, id: \.self) { index in
                    let item = zoneHistory[index]
                    historyRow(date: item.0, status: item.1, checkIn: item.2)
                    if index < zoneHistory.count - 1 {
                        Divider()
                            .foregroundStyle(CleraColor.border)
                    }
                }
            }
        }
    }

    private func historyRow(date: Date, status: ZoneStatus, checkIn: SkinMapCheckIn?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CleraColor.textPrimary)
                Spacer()
                Text(status.overallSeverity.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(status.overallSeverity.color)
            }

            let activeMetrics = status.metrics.filter { $0.severity != .none }
            if !activeMetrics.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(activeMetrics.indices, id: \.self) { i in
                        let m = activeMetrics[i]
                        Text("\(m.label): \(m.severity.displayName)")
                            .font(.system(size: 11))
                            .foregroundStyle(m.severity.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(m.severity.color.opacity(0.08))
                            )
                    }
                }
            }

            if let checkIn = checkIn, checkIn.notes?.isEmpty == false {
                Text(checkIn.notes!)
                    .font(.system(size: 12))
                    .foregroundStyle(CleraColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.SkinMap.notes)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            if let notes = zone.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(CleraCopy.SkinMap.noNotes)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            }
        }
    }
}


