import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            if !appModel.hasCompletedAuth {
                AuthFlowView()
            } else if !appModel.hasCompletedOnboarding {
                OnboardingFlowView()
            } else {
                MainTabView()
            }
        }
    }
}
