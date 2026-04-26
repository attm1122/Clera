import SwiftUI

struct BaselineCompleteView: View {
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: CleraSpacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(CleraColor.success)

            CleraSectionHeader(
                eyebrow: "Step 4 of 4",
                title: "You're all set",
                subtitle: "Your baseline is recorded. Start logging your routine and check in daily to build your skin history."
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, CleraSpacing.lg)

            Spacer()

            Button(CleraCopy.Onboarding.goToToday) {
                onComplete()
            }
            .buttonStyle(CleraPrimaryButtonStyle())
            .padding(.horizontal, CleraSpacing.lg)
            .padding(.bottom, CleraSpacing.xl)
        }
        .background(CleraColor.background)
    }
}
