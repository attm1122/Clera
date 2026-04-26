import SwiftUI

struct PhotoComparisonView: View {
    let leftSession: ScanSession
    let rightSession: ScanSession
    @Environment(\.dismiss) private var dismiss
    @State private var showRevealMode = false
    @State private var showDiffOverlay = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CleraSpacing.lg) {
                    comparisonHeader
                    comparisonControls

                    if showRevealMode, let before = leftImage, let after = rightImage {
                        BeforeAfterRevealView(beforeImage: before, afterImage: after)
                            .frame(height: 380)
                            .clipShape(RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous))
                    } else {
                        comparisonPhotos
                    }

                    if showDiffOverlay {
                        diffLegend
                    }

                    comparisonDetails
                    Spacer(minLength: CleraSpacing.xl)
                }
                .padding(.horizontal, CleraSpacing.lg)
                .padding(.top, CleraSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(CleraColor.background)
            .navigationTitle(CleraCopy.Progress.compare)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(CleraColor.accent)
                }
            }
        }
    }

    // MARK: - Images

    private var leftImage: UIImage? {
        leftSession.photos.first?.resolvedImage()
    }

    private var rightImage: UIImage? {
        rightSession.photos.first?.resolvedImage()
    }

    // MARK: - Header

    private var comparisonHeader: some View {
        HStack(spacing: CleraSpacing.md) {
            VStack(spacing: 4) {
                Text(CleraCopy.Progress.before)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CleraColor.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text(leftSession.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CleraColor.textPrimary)
            }
            .frame(maxWidth: .infinity)

            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.accent)

            VStack(spacing: 4) {
                Text(CleraCopy.Progress.after)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CleraColor.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text(rightSession.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CleraColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Controls

    private var comparisonControls: some View {
        HStack(spacing: CleraSpacing.md) {
            ToggleButton(
                isOn: $showRevealMode,
                icon: "arrow.left.and.right",
                label: "Reveal"
            )
            ToggleButton(
                isOn: $showDiffOverlay,
                icon: "scope",
                label: "Highlights"
            )
        }
    }

    // MARK: - Photos

    private var comparisonPhotos: some View {
        HStack(spacing: CleraSpacing.md) {
            photoColumn(image: leftImage, label: CleraCopy.Progress.before, session: leftSession)
            photoColumn(image: rightImage, label: CleraCopy.Progress.after, session: rightSession)
        }
    }

    private func photoColumn(image: UIImage?, label: String, session: ScanSession) -> some View {
        VStack(spacing: CleraSpacing.sm) {
            ZStack {
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 340)
                        .clipShape(RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                        .fill(CleraColor.accentSoft)
                        .frame(height: 340)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundStyle(CleraColor.accent)
                                Text(CleraCopy.State.noPhoto)
                                    .font(.system(size: 14))
                                    .foregroundStyle(CleraColor.textSecondary)
                            }
                        )
                }

                if showDiffOverlay {
                    VisualDifferenceOverlay(
                        zones: diffZones(for: session),
                        imageSize: CGSize(width: 300, height: 400)
                    )
                    .frame(height: 340)
                }
            }

            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CleraColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Diff Zones

    private func diffZones(for session: ScanSession) -> [VisualDifferenceOverlay.ZoneHighlight] {
        // Compare this session against the other session's zones
        let other = session.id == leftSession.id ? rightSession : leftSession
        var highlights: [VisualDifferenceOverlay.ZoneHighlight] = []

        for zone in session.skinMap.zones {
            guard let otherZone = other.skinMap.zones.first(where: { $0.zoneType == zone.zoneType }) else { continue }
            let delta = severityDelta(zone.status.overallSeverity, otherZone.status.overallSeverity)
            guard abs(delta) >= 1 else { continue }

            highlights.append(VisualDifferenceOverlay.ZoneHighlight(
                zone: zone.zoneType,
                direction: delta > 0 ? .increasing : .decreasing,
                intensity: min(Double(abs(delta)) / 3.0, 1.0)
            ))
        }

        return highlights.prefix(2).map { $0 }
    }

    private func severityDelta(_ a: ZoneSeverity, _ b: ZoneSeverity) -> Int {
        severityScore(a) - severityScore(b)
    }

    private func severityScore(_ severity: ZoneSeverity) -> Int {
        switch severity {
        case .none: return 0
        case .low: return 1
        case .moderate: return 2
        case .high: return 3
        }
    }

    // MARK: - Diff Legend

    private var diffLegend: some View {
        HStack(spacing: CleraSpacing.md) {
            legendItem(color: Color(hex: 0xC75B39), label: "Increased")
            legendItem(color: Color(hex: 0x4A7C59), label: "Improved")
            legendItem(color: CleraColor.accent.opacity(0.5), label: "Stable")
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(CleraColor.textSecondary)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }

    // MARK: - Comparison Details

    private var comparisonDetails: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                Text(CleraCopy.Progress.skinMapComparison)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)

                ForEach(leftSession.skinMap.zones) { leftZone in
                    if let rightZone = rightSession.skinMap.zones.first(where: { $0.zoneType == leftZone.zoneType }) {
                        zoneComparisonRow(left: leftZone, right: rightZone)
                    }
                }

                if let leftNote = leftSession.note, !leftNote.isEmpty,
                   let rightNote = rightSession.note, !rightNote.isEmpty {
                    Divider().background(CleraColor.border)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(CleraCopy.Progress.notes)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CleraColor.textPrimary)
                        Text("\(CleraCopy.Progress.before): \(leftNote)")
                            .font(.system(size: 13))
                            .foregroundStyle(CleraColor.textSecondary)
                        Text("\(CleraCopy.Progress.after): \(rightNote)")
                            .font(.system(size: 13))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                }
            }
        }
    }

    private func zoneComparisonRow(left: FaceZone, right: FaceZone) -> some View {
        HStack {
            Text(left.zoneType.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CleraColor.textPrimary)
                .frame(width: 90, alignment: .leading)

            Spacer()

            HStack(spacing: 12) {
                Text(left.status.breakouts.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(left.status.breakouts.color)

                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundStyle(CleraColor.textSecondary)

                Text(right.status.breakouts.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(right.status.breakouts.color)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Toggle Button

private struct ToggleButton: View {
    @Binding var isOn: Bool
    let icon: String
    let label: String

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isOn ? CleraColor.accent : CleraColor.elevatedSurface)
            )
            .foregroundStyle(isOn ? .white : CleraColor.textPrimary)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isOn ? Color.clear : CleraColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
