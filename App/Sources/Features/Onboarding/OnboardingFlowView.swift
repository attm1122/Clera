import SwiftUI

struct OnboardingFlowView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedGoal: SkinGoal = .acne
    @State private var cadence: ReminderCadence = .threePerWeek
    @State private var reminderTime = Date.now

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    CleraSectionHeader(
                        eyebrow: "Clera",
                        title: "See your skin clearly",
                        subtitle: "Track progress with consistent photos, lightweight routine logging, and calm weekly summaries."
                    )
                    .padding(.top, CleraSpacing.xl)

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            Text("Choose your primary goal")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)

                            ForEach(SkinGoal.allCases) { goal in
                                Button {
                                    selectedGoal = goal
                                } label: {
                                    HStack(alignment: .top, spacing: CleraSpacing.md) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(goal.rawValue)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(CleraColor.textPrimary)
                                            Text(goal.subtitle)
                                                .font(.system(size: 14))
                                                .foregroundStyle(CleraColor.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: selectedGoal == goal ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedGoal == goal ? CleraColor.accent : CleraColor.border)
                                    }
                                    .padding(.vertical, 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            Text("Set a reminder rhythm")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)

                            HStack(spacing: 10) {
                                ForEach(ReminderCadence.allCases) { option in
                                    Button {
                                        cadence = option
                                    } label: {
                                        CleraTag(title: option.rawValue, isSelected: cadence == option)
                                    }
                                }
                            }

                            DatePicker("Preferred time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .tint(CleraColor.accent)
                        }
                    }

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            Text("What you’ll get")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)
                            benefitRow("Guided baseline photos for front, left, and right angles")
                            benefitRow("A calm home screen with one clear next step")
                            benefitRow("Weekly summaries framed as observation, not diagnosis")
                        }
                    }

                    Button("Get started") {
                        appModel.completeOnboarding(goal: selectedGoal, cadence: cadence, reminderTime: reminderTime)
                    }
                    .buttonStyle(CleraPrimaryButtonStyle())
                    .padding(.bottom, CleraSpacing.xl)
                }
                .padding(.horizontal, CleraSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(CleraColor.background)
        }
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(CleraColor.accent)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(CleraColor.textSecondary)
        }
    }
}

