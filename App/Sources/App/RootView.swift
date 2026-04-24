import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            if appModel.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlowView()
            }
        }
        .background(CleraColor.background.ignoresSafeArea())
    }
}
