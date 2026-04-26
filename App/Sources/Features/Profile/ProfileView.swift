import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showReminderSettings = false
    @State private var showPrivacySettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                profileHeader
                settingsSection
                dataSection
                Spacer(minLength: CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
        .sheet(isPresented: $showReminderSettings) {
            RemindersSettingsView()
        }
        .sheet(isPresented: $showPrivacySettings) {
            PrivacySettingsView()
        }
    }

    private var profileHeader: some View {
        CleraCard {
            HStack(spacing: CleraSpacing.md) {
                Circle()
                    .fill(CleraColor.accentSoft)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text(initials)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(CleraColor.accent)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(appModel.userProfile?.name ?? "User")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)
                    Text(appModel.userProfile?.email ?? "")
                        .font(.system(size: 14))
                        .foregroundStyle(CleraColor.textSecondary)
                }

                Spacer()
            }
        }
        .padding(.top, CleraSpacing.xl)
    }

    private var initials: String {
        guard let name = appModel.userProfile?.name else { return "U" }
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
        return String(first + last).uppercased()
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.Profile.settings)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            settingsButton(icon: "bell", title: CleraCopy.Profile.reminders) {
                showReminderSettings = true
            }
            settingsButton(icon: "lock.shield", title: CleraCopy.Profile.privacy) {
                showPrivacySettings = true
            }
        }
    }

    private func settingsButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: CleraSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(CleraColor.accent)
                    .frame(width: 32)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(CleraColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CleraColor.textSecondary)
            }
            .padding(CleraSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                    .fill(CleraColor.elevatedSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                    .stroke(CleraColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.Profile.account)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            Button {
                appModel.restartOnboarding()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18))
                        .foregroundStyle(CleraColor.accent)
                        .frame(width: 32)
                    Text(CleraCopy.Profile.restartOnboarding)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(CleraColor.accent)
                    Spacer()
                }
                .padding(CleraSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                        .fill(CleraColor.elevatedSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                        .stroke(CleraColor.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                appModel.logout()
            } label: {
                HStack {
                    Image(systemName: "arrow.left.square")
                        .font(.system(size: 18))
                        .foregroundStyle(.red)
                        .frame(width: 32)
                    Text(CleraCopy.Profile.logOut)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(CleraSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                        .fill(CleraColor.elevatedSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                        .stroke(CleraColor.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}
