import SwiftUI

struct MainTabView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        TabView(selection: Bindable(appModel).selectedTab) {
            HomeView()
                .tag(AppTab.home)
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.systemImage) }

            ProgressView()
                .tag(AppTab.progress)
                .tabItem { Label(AppTab.progress.title, systemImage: AppTab.progress.systemImage) }

            RoutineView()
                .tag(AppTab.routine)
                .tabItem { Label(AppTab.routine.title, systemImage: AppTab.routine.systemImage) }

            ProfileView()
                .tag(AppTab.profile)
                .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage) }
        }
        .tint(CleraColor.accent)
    }
}

