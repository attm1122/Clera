import SwiftUI

@main
struct CleraApp: App {
    @UIApplicationDelegateAdaptor(CleraAppDelegate.self) private var appDelegate
    @State private var appModel = AppModel.makeProductionModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    handleDeepLink(url: url, appModel: appModel)
                }
        }
    }

    private func handleDeepLink(url: URL, appModel: AppModel) {
        guard url.scheme == "clera" else { return }
        switch url.host {
        case "daily-advice":
            appModel.selectedTab = .today
        default:
            break
        }
    }
}
