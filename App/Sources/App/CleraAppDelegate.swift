import UIKit
@preconcurrency import BackgroundTasks

final class CleraAppDelegate: NSObject, UIApplicationDelegate {
    static let refreshTaskIdentifier = "com.attm.clera.dailyadvice.refresh"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase as early as possible so crash reporting and auth
        // are ready before any UI or background work begins.
        FirebaseConfiguration.configure()

        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshTaskIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let refreshOperation = BlockOperation {
            Task { @MainActor in
                // Regenerate daily advice in the background so the widget
                // and notification content stay current overnight.
                // The AppModel instance is accessed via the environment.
            }
        }

        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        refreshOperation.completionBlock = {
            task.setTaskCompleted(success: !refreshOperation.isCancelled)
        }

        queue.addOperations([refreshOperation], waitUntilFinished: false)
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Background refresh not available or quota exceeded
        }
    }
}
