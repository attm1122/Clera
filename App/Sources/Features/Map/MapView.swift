import SwiftUI

struct MapView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedZone: ZoneType? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                CleraSectionHeader(
                    eyebrow: CleraCopy.SkinMap.title,
                    title: CleraCopy.SkinMap.subtitle,
                    subtitle: CleraCopy.SkinMap.body
                )
                .padding(.top, CleraSpacing.xl)

                faceMapHero

                Text(CleraCopy.SkinMap.zoneDetailsTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)

                ForEach(appModel.currentSkinMap.zones) { zone in
                    Button {
                        selectedZone = zone.zoneType
                    } label: {
                        zoneRow(zone: zone)
                    }
                    .buttonStyle(.plain)
                }

                if let checkIn = appModel.currentSkinMap.checkIn {
                    checkInSummary(checkIn: checkIn)
                }

                Spacer(minLength: CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
        .sheet(item: $selectedZone) { zone in
            if let faceZone = appModel.currentSkinMap.zones.first(where: { $0.zoneType == zone }) {
                ZoneDetailView(zone: faceZone)
            }
        }
    }

    private var faceMapHero: some View {
        CleraCard {
            VStack(spacing: CleraSpacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                        .fill(CleraColor.surface)
                        .frame(height: 320)

                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            zoneHeroButton(.leftCheek)
                            VStack(spacing: 12) {
                                zoneHeroButton(.forehead)
                                zoneHeroButton(.nose)
                            }
                            zoneHeroButton(.rightCheek)
                        }
                        zoneHeroButton(.chinJaw)
                    }
                    .padding(.vertical, 20)
                }

                HStack(spacing: 16) {
                    legendItem(color: .green, label: CleraCopy.DisplayNames.zoneSeverityClear)
                    legendItem(color: .yellow, label: CleraCopy.DisplayNames.zoneSeverityLow)
                    legendItem(color: .orange, label: CleraCopy.DisplayNames.zoneSeverityModerate)
                    legendItem(color: .red, label: CleraCopy.DisplayNames.zoneSeverityHigh)
                }
            }
        }
    }

    private func zoneHeroButton(_ zone: ZoneType) -> some View {
        let faceZone = appModel.currentSkinMap.zones.first(where: { $0.zoneType == zone })
        let severity = faceZone?.status.overallSeverity ?? .none
        let trend = faceZone?.status.overallTrend

        return Button {
            selectedZone = zone
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: zone.systemImage)
                        .font(.system(size: zone == .chinJaw ? 32 : 28))
                        .foregroundStyle(severity.color)
                        .frame(width: zoneSize(for: zone), height: zoneSize(for: zone))
                        .background(
                            RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                                .fill(severity.color.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                                .stroke(severity.color.opacity(0.3), lineWidth: 1.5)
                        )

                    if let trend, trend != .unknown {
                        Image(systemName: trend.icon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(trend.color))
                            .offset(x: 4, y: -4)
                    }
                }

                Text(zone.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(CleraColor.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    private func zoneSize(for zone: ZoneType) -> CGFloat {
        switch zone {
        case .forehead, .chinJaw: return 80
        case .nose: return 64
        case .leftCheek, .rightCheek: return 72
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(CleraColor.textSecondary)
        }
    }

    private func zoneRow(zone: FaceZone) -> some View {
        let topMetrics = zone.status.metrics
            .filter { $0.severity != .none }
            .sorted { severityScore($0.severity) > severityScore($1.severity) }
            .prefix(2)
        let severity = zone.status.overallSeverity

        return CleraCard {
            HStack(spacing: CleraSpacing.md) {
                Image(systemName: zone.zoneType.systemImage)
                    .font(.system(size: 24))
                    .foregroundStyle(severity.color)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                            .fill(severity.color.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(zone.zoneType.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)

                    if topMetrics.isEmpty {
                        Text(CleraCopy.SkinMap.lookingClear)
                            .font(.system(size: 12))
                            .foregroundStyle(CleraColor.textSecondary)
                    } else {
                        HStack(spacing: 8) {
                            ForEach(Array(topMetrics.enumerated()), id: \.offset) { _, metric in
                                metricPill(
                                    label: metric.label,
                                    value: metric.severity.displayName,
                                    color: metric.severity.color,
                                    trend: metric.trend
                                )
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CleraColor.textSecondary)
            }
        }
    }

    private func metricPill(label: String, value: String, color: Color, trend: ZoneTrend? = nil) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(CleraColor.textSecondary)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            if let trend, trend != .unknown {
                Image(systemName: trend.icon)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(trend.color)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    private func checkInSummary(checkIn: SkinMapCheckIn) -> some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                Text("Check-in Notes")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)

                HStack(spacing: 12) {
                    checkInBadge(icon: checkIn.followedRoutine ? "checkmark.circle.fill" : "xmark.circle.fill", label: CleraCopy.SkinMap.routineLabel, active: checkIn.followedRoutine)
                    checkInBadge(icon: checkIn.newProducts ? "exclamationmark.circle.fill" : "minus.circle.fill", label: CleraCopy.SkinMap.newProductsLabel, active: checkIn.newProducts)
                }

                if checkIn.hadIrritation || checkIn.hadDryness || checkIn.hadBreakouts {
                    HStack(spacing: 8) {
                        if checkIn.hadIrritation {
                            checkInBadge(icon: "exclamationmark.triangle.fill", label: "Irritation", active: true)
                        }
                        if checkIn.hadDryness {
                            checkInBadge(icon: "drop.triangle.fill", label: "Dryness", active: true)
                        }
                        if checkIn.hadBreakouts {
                            checkInBadge(icon: "burst.fill", label: "Breakouts", active: true)
                        }
                    }
                }

                if let notes = checkIn.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundStyle(CleraColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func checkInBadge(icon: String, label: String, active: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(active ? CleraColor.accent : CleraColor.textSecondary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(active ? CleraColor.textPrimary : CleraColor.textSecondary)
        }
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

extension ZoneType: Identifiable {
    public var id: String { rawValue }
}
