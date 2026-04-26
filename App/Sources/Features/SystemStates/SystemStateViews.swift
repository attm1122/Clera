import SwiftUI

// MARK: - Empty States

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: CleraSpacing.lg) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(CleraColor.accent)
            VStack(spacing: CleraSpacing.sm) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(CleraColor.textPrimary)
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(CleraColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle) {
                    action()
                }
                .buttonStyle(CleraPrimaryButtonStyle())
                .padding(.horizontal, CleraSpacing.lg)
            }
            Spacer()
        }
        .padding(CleraSpacing.lg)
        .background(CleraColor.background)
    }
}

// MARK: - Loading States

struct LoadingStateView: View {
    let title: String
    let subtitle: String

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: CleraSpacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(CleraColor.border, lineWidth: 4)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(CleraColor.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
            VStack(spacing: CleraSpacing.sm) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(CleraColor.textPrimary)
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(CleraColor.textSecondary)
            }
            Spacer()
        }
        .padding(CleraSpacing.lg)
        .background(CleraColor.background)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Error States

struct ErrorStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: CleraSpacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(CleraColor.accentSoft.opacity(0.5))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(CleraColor.accent)
            }
            VStack(spacing: CleraSpacing.sm) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(CleraColor.textPrimary)
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(CleraColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle) {
                    action()
                }
                .buttonStyle(CleraPrimaryButtonStyle())
                .padding(.horizontal, CleraSpacing.lg)
            }
            Spacer()
        }
        .padding(CleraSpacing.lg)
        .background(CleraColor.background)
    }
}

// MARK: - Permission States

struct PermissionStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: CleraSpacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(CleraColor.accentSoft)
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(CleraColor.accent)
            }
            VStack(spacing: CleraSpacing.sm) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(CleraColor.textPrimary)
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(CleraColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button(actionTitle) {
                action()
            }
            .buttonStyle(CleraPrimaryButtonStyle())
            .padding(.horizontal, CleraSpacing.lg)
            Spacer()
        }
        .padding(CleraSpacing.lg)
        .background(CleraColor.background)
    }
}
