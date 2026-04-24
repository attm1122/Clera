import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    CleraSectionHeader(
                        eyebrow: "Profile",
                        title: "Quiet control, private by default",
                        subtitle: "Everything here should feel transparent, useful, and low-pressure."
                    )

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            settingsRow(title: "Primary goal", value: appModel.selectedGoal?.rawValue ?? "Not set")
                            settingsRow(title: "Reminder cadence", value: appModel.reminderCadence.rawValue)
                            settingsRow(title: "Preferred time", value: appModel.preferredReminderTime.formatted(date: .omitted, time: .shortened))
                        }
                    }

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            settingsRow(title: "Subscription", value: "Free")
                            settingsRow(title: "Privacy", value: "Photos are private by default")
                            settingsRow(title: "Export", value: "Coming soon")
                        }
                    }

                    Button("Restart onboarding") {
                        appModel.hasCompletedOnboarding = false
                    }
                    .buttonStyle(CleraPrimaryButtonStyle())
                }
                .padding(CleraSpacing.lg)
            }
            .background(CleraColor.background)
        }
    }

    private func settingsRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(CleraColor.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(CleraColor.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

