import SwiftUI

struct InitialSkinMapView: View {
    let skinMap: SkinMap
    var onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                CleraSectionHeader(
                    eyebrow: "\(CleraCopy.Onboarding.stepPrefix) 3 of 4",
                    title: CleraCopy.Onboarding.initialSkinMapTitle,
                    subtitle: CleraCopy.Onboarding.initialSkinMapBody
                )
                .padding(.top, CleraSpacing.xl)

                ForEach(skinMap.zones) { zone in
                    zoneCard(zone: zone)
                }

                Button(CleraCopy.Onboarding.continue) {
                    onComplete()
                }
                .buttonStyle(CleraPrimaryButtonStyle())
                .padding(.top, CleraSpacing.md)

                Spacer(minLength: CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
    }

    private func zoneCard(zone: FaceZone) -> some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                HStack {
                    Text(zone.zoneType.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)
                    Spacer()
                    statusBadge(severity: zone.status.overallConfidence > 0.7 ? zone.status.breakouts : .none)
                }

                HStack(spacing: CleraSpacing.sm) {
                    miniStat(icon: "exclamationmark.circle", label: "Breakouts", value: zone.status.breakouts.displayName)
                    miniStat(icon: "flame", label: "Redness", value: zone.status.redness.displayName)
                    miniStat(icon: "circle.grid.cross", label: "Texture", value: zone.status.texture.displayName)
                }
            }
        }
    }

    private func statusBadge(severity: ZoneSeverity) -> some View {
        HStack(spacing: 4) {
            Image(systemName: severity.icon)
                .font(.system(size: 12))
            Text(severity.displayName)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(severity.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(severity.color.opacity(0.1))
        )
    }

    private func miniStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(CleraColor.textSecondary)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CleraColor.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(CleraColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                .fill(CleraColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                .stroke(CleraColor.border, lineWidth: 1)
        )
    }
}
