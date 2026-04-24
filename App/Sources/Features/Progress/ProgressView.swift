import SwiftUI

struct ProgressView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedFilter = "30D"

    private let filters = ["7D", "30D", "90D", "All"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    CleraSectionHeader(
                        eyebrow: "Progress",
                        title: "Compare change over time",
                        subtitle: "A calm visual timeline, grounded in consistent check-ins."
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(filters, id: \.self) { filter in
                                Button {
                                    selectedFilter = filter
                                } label: {
                                    CleraTag(title: filter, isSelected: selectedFilter == filter)
                                }
                            }
                        }
                    }

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            if appModel.progressEntries.isEmpty {
                                Text("Capture a baseline first and the compare view will come alive here.")
                                    .font(.system(size: 15))
                                    .foregroundStyle(CleraColor.textSecondary)
                            } else {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Baseline")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(CleraColor.textSecondary)
                                        Text(appModel.comparisonTitle)
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Latest")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(CleraColor.textSecondary)
                                        Text(appModel.latestSession.map { RelativeDateTimeFormatter().localizedString(for: $0.createdAt, relativeTo: .now) } ?? "Today")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }

                                ZStack {
                                    RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                                        .fill(LinearGradient(colors: [CleraColor.surface, CleraColor.accentSoft], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(height: 280)

                                    HStack(spacing: 0) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Before")
                                                .font(.system(size: 13, weight: .semibold))
                                            Text("Original baseline")
                                                .font(.system(size: 12))
                                                .foregroundStyle(CleraColor.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                        .padding()
                                        Divider()
                                            .frame(width: 1)
                                            .overlay(Circle().fill(Color.white).frame(width: 32, height: 32).overlay(Image(systemName: "arrow.left.and.right")).offset(x: 0))
                                        VStack(alignment: .trailing, spacing: 8) {
                                            Text("After")
                                                .font(.system(size: 13, weight: .semibold))
                                            Text(appModel.comparisonSubtitle)
                                                .font(.system(size: 12))
                                                .foregroundStyle(CleraColor.textSecondary)
                                                .multilineTextAlignment(.trailing)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                        .padding()
                                    }
                                }
                            }
                        }
                    }

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            Text("Timeline")
                                .font(.system(size: 19, weight: .semibold))
                            if appModel.progressEntries.isEmpty {
                                Text("No sessions yet. Once you save a baseline or check-in, it will appear here with relative dates and notes.")
                                    .font(.system(size: 14))
                                    .foregroundStyle(CleraColor.textSecondary)
                            } else {
                                ForEach(appModel.progressEntries) { entry in
                                    HStack(alignment: .top, spacing: CleraSpacing.md) {
                                        Circle()
                                            .fill(entry.title == "Latest check-in" ? CleraColor.accent : CleraColor.border)
                                            .frame(width: 10, height: 10)
                                            .padding(.top, 6)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.title)
                                                .font(.system(size: 15, weight: .semibold))
                                            Text(entry.note)
                                                .font(.system(size: 14))
                                                .foregroundStyle(CleraColor.textSecondary)
                                        }
                                        Spacer()
                                        Text(entry.timeframe)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(CleraColor.textSecondary)
                                    }
                                }
                            }
                        }
                    }

                    if !appModel.sessions.isEmpty {
                        CleraCard {
                            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                                Text("Saved sessions")
                                    .font(.system(size: 19, weight: .semibold))
                                ForEach(appModel.sortedSessions) { session in
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(session.kind.rawValue)
                                                .font(.system(size: 15, weight: .semibold))
                                            Text("\(session.photos.count) guided angles captured")
                                                .font(.system(size: 14))
                                                .foregroundStyle(CleraColor.textSecondary)
                                        }
                                        Spacer()
                                        Text(session.createdAt.formatted(date: .abbreviated, time: .omitted))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(CleraColor.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(CleraSpacing.lg)
            }
            .background(CleraColor.background)
        }
    }
}
