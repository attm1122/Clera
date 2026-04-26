import SwiftUI

struct SplashScreenView: View {
    @State private var opacity = 0.0
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            CleraColor.background.ignoresSafeArea()
            VStack(spacing: CleraSpacing.md) {
                Spacer()
                Text(CleraCopy.Onboarding.welcomeTitle)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(CleraColor.textPrimary)
                Text(CleraCopy.Onboarding.welcomeSubtitle)
                    .font(.system(size: 17))
                    .foregroundStyle(CleraColor.textSecondary)
                Spacer()
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.6)) {
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    onComplete()
                }
            }
        }
    }
}
