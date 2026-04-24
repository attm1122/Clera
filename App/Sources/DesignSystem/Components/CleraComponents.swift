import SwiftUI

struct CleraPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: CleraRadius.pill, style: .continuous)
                    .fill(CleraColor.textPrimary.opacity(configuration.isPressed ? 0.8 : 1))
            )
    }
}

struct CleraCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(CleraSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                    .fill(CleraColor.elevatedSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                            .stroke(LinearGradient(colors: [CleraColor.border, CleraColor.border.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 20, x: 0, y: 10)
            )
    }
}

struct CleraSectionHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(CleraColor.textSecondary)
            }

            Text(title)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(CleraColor.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(CleraColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct CleraTag: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(isSelected ? CleraColor.accent : CleraColor.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? CleraColor.accentSoft : CleraColor.surface)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? CleraColor.accent.opacity(0.18) : CleraColor.border, lineWidth: 1)
            )
    }
}

