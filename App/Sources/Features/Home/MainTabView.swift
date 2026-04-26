import SwiftUI

struct MainTabView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var model = appModel
        TabView(selection: $model.selectedTab) {
            TodayView()
                .tabItem { Label(AppTab.today.title, systemImage: AppTab.today.systemImage) }
                .tag(AppTab.today)

            MapView()
                .tabItem { Label(AppTab.map.title, systemImage: AppTab.map.systemImage) }
                .tag(AppTab.map)

            RoutineView()
                .tabItem { Label(AppTab.routine.title, systemImage: AppTab.routine.systemImage) }
                .tag(AppTab.routine)

            ProgressView()
                .tabItem { Label(AppTab.progress.title, systemImage: AppTab.progress.systemImage) }
                .tag(AppTab.progress)

            ProfileView()
                .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage) }
                .tag(AppTab.profile)
        }
        .tint(CleraColor.accent)
    }
}
