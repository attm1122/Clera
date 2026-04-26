import SwiftUI

struct WelcomeStepView: View {
    var onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                CleraSectionHeader(
                    eyebrow: CleraCopy.Onboarding.welcomeTitle,
                    title: CleraCopy.Onboarding.welcomeSubtitle,
                    subtitle: CleraCopy.Onboarding.welcomeBody
                )
                .padding(.top, CleraSpacing.xl)

                VStack(alignment: .leading, spacing: CleraSpacing.md) {
                    featureRow(icon: "face.smiling", title: CleraCopy.Onboarding.featureSkinMap, description: CleraCopy.Onboarding.featureSkinMapBody)
                    featureRow(icon: "drop", title: CleraCopy.Onboarding.featureRoutine, description: CleraCopy.Onboarding.featureRoutineBody)
                    featureRow(icon: "flask", title: CleraCopy.Onboarding.featureExperiments, description: CleraCopy.Onboarding.featureExperimentsBody)
                    featureRow(icon: "chart.line.uptrend.xyaxis", title: CleraCopy.Onboarding.featureProgress, description: CleraCopy.Onboarding.featureProgressBody)
                }

                Button(CleraCopy.Onboarding.getStarted) {
                    onStart()
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

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: CleraSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(CleraColor.accent)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                        .fill(CleraColor.accentSoft)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)
                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
