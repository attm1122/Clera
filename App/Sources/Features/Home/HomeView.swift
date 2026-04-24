import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    CleraSectionHeader(
                        eyebrow: "Today",
                        title: "Ready for your next check-in?",
                        subtitle: "Stay consistent to make progress easier to trust."
                    )

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            Text("Today's focus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(CleraColor.textSecondary)
                            Text(appModel.selectedGoal?.rawValue ?? "Skin progress")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)
                            Text("Your last check-in was 2 days ago. A quick front, left, and right capture keeps the timeline consistent.")
                                .font(.system(size: 15))
                                .foregroundStyle(CleraColor.textSecondary)
                            Button("Check in") { }
                                .buttonStyle(CleraPrimaryButtonStyle())
                        }
                    }

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                            Text("Weekly summary")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)
                            Text(appModel.homeSummary.body)
                                .font(.system(size: 15))
                                .foregroundStyle(CleraColor.textSecondary)
                        }
                    }

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            Text("Recent progress")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)

                            ForEach(appModel.progressEntries.prefix(3)) { entry in
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(CleraColor.textPrimary)
                                        Text(entry.note)
                                            .font(.system(size: 14))
                                            .foregroundStyle(CleraColor.textSecondary)
                                    }
                                    Spacer()
                                    Text(entry.timeframe)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(CleraColor.textSecondary)
                                }
                                if entry.id != appModel.progressEntries.prefix(3).last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(CleraSpacing.lg)
            }
            .background(CleraColor.background)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

