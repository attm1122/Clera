import SwiftUI

struct RoutineView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    CleraSectionHeader(
                        eyebrow: "Routine",
                        title: "Keep changes visible",
                        subtitle: "A lightweight routine log helps you connect product shifts to timeline events."
                    )

                    ForEach(RoutinePeriod.allCases) { period in
                        CleraCard {
                            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                                Text(period.rawValue)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(CleraColor.textPrimary)

                                ForEach(appModel.currentRoutine.filter { $0.period == period }) { item in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.category)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(CleraColor.textSecondary)
                                        Text(item.productName)
                                            .font(.system(size: 16))
                                            .foregroundStyle(CleraColor.textPrimary)
                                    }
                                }

                                Button("Add product") { }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(CleraColor.accent)
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

