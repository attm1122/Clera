import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var activeCapture: CapturePresentation?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    CleraSectionHeader(
                        eyebrow: "Today",
                        title: appModel.hasBaseline ? "Ready for your next check-in?" : "Start with a baseline",
                        subtitle: appModel.hasBaseline ? "Stay consistent to make progress easier to trust." : "Your first three-angle set becomes the anchor for every future comparison."
                    )

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            Text("Today's focus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(CleraColor.textSecondary)
                            Text(appModel.selectedGoal?.rawValue ?? "Skin progress")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)
                            Text(statusCopy)
                                .font(.system(size: 15))
                                .foregroundStyle(CleraColor.textSecondary)
                            Button(appModel.nextCaptureKind.actionTitle) {
                                activeCapture = CapturePresentation(kind: appModel.nextCaptureKind)
                            }
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

                            if appModel.progressEntries.isEmpty {
                                Text("No sessions saved yet. Your first baseline will show up here and in the Progress tab.")
                                    .font(.system(size: 14))
                                    .foregroundStyle(CleraColor.textSecondary)
                            } else {
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
                }
                .padding(CleraSpacing.lg)
            }
            .background(CleraColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $activeCapture) { presentation in
                CaptureFlowView(kind: presentation.kind)
            }
        }
    }

    private var statusCopy: String {
        guard let latest = appModel.latestSession else {
            return "Take one calm front, left, and right set in steady light so Clera can anchor your progress from day one."
        }

        return "Your last \(latest.kind.rawValue.lowercased()) was \(RelativeDateTimeFormatter().localizedString(for: latest.createdAt, relativeTo: .now)). A fresh three-angle capture keeps the timeline trustworthy."
    }
}

private struct CapturePresentation: Identifiable {
    let id = UUID()
    let kind: CheckInSessionKind
}
