import UserNotifications

@MainActor
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized {
            return true
        }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Scan Reminders

    func scheduleReminders(settings: ReminderSettings) {
        guard settings.enabled else {
            cancelAllReminders()
            return
        }
        cancelAllReminders()

        let content = UNMutableNotificationContent()
        content.title = "Clera"
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: settings.preferredTime)

        switch settings.cadence {
        case .daily:
            content.body = "Time for your daily skin check-in."
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "com.attm.clera.daily", content: content, trigger: trigger)
            center.add(request)

        case .alternateDays:
            content.body = "Time for your skin check-in."
            scheduleAlternateDayReminders(timeComponents: dateComponents, content: content)

        case .weekly:
            content.body = "Time for your weekly skin check-in."
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "com.attm.clera.weekly", content: content, trigger: trigger)
            center.add(request)
        }
    }

    /// Schedules 4 weekly repeating triggers that collectively cover alternate days.
    private func scheduleAlternateDayReminders(timeComponents: DateComponents, content: UNMutableNotificationContent) {
        let calendar = Calendar.current
        var alternateWeekdays: [Int] = []
        for offset in [0, 2, 4, 6] {
            if let date = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .now)) {
                alternateWeekdays.append(calendar.component(.weekday, from: date))
            }
        }

        for (index, weekday) in alternateWeekdays.enumerated() {
            var components = timeComponents
            components.weekday = weekday
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "com.attm.clera.alt-\(index)-w\(weekday)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func cancelAllReminders() {
        center.removePendingNotificationRequests(withIdentifiers: [
            "com.attm.clera.daily",
            "com.attm.clera.weekly",
            "com.attm.clera.alt-0-w1", "com.attm.clera.alt-0-w2",
            "com.attm.clera.alt-0-w3", "com.attm.clera.alt-0-w4",
            "com.attm.clera.alt-0-w5", "com.attm.clera.alt-0-w6",
            "com.attm.clera.alt-0-w7", "com.attm.clera.alt-1-w1",
            "com.attm.clera.alt-1-w2", "com.attm.clera.alt-1-w3",
            "com.attm.clera.alt-1-w4", "com.attm.clera.alt-1-w5",
            "com.attm.clera.alt-1-w6", "com.attm.clera.alt-1-w7",
            "com.attm.clera.alt-2-w1", "com.attm.clera.alt-2-w2",
            "com.attm.clera.alt-2-w3", "com.attm.clera.alt-2-w4",
            "com.attm.clera.alt-2-w5", "com.attm.clera.alt-2-w6",
            "com.attm.clera.alt-2-w7", "com.attm.clera.alt-3-w1",
            "com.attm.clera.alt-3-w2", "com.attm.clera.alt-3-w3",
            "com.attm.clera.alt-3-w4", "com.attm.clera.alt-3-w5",
            "com.attm.clera.alt-3-w6", "com.attm.clera.alt-3-w7"
        ])
    }

    // MARK: - Daily Advice Notifications

    /// Schedules morning, midday, and evening advice notifications based on the daily advice result.
    func scheduleDailyAdviceNotifications(advice: DailySkinAdviceResult) {
        cancelDailyAdviceNotifications()

        guard let weather = advice.weatherSnapshot else { return }

        // Morning advice (6:00 AM) — prepare for the day
        let morningContent = UNMutableNotificationContent()
        morningContent.title = "Today's Skin Advice"
        morningContent.body = advice.primaryAdvice
        morningContent.sound = .default
        morningContent.userInfo = ["route": "dailyAdvice"]

        var morningComponents = DateComponents()
        morningComponents.hour = 6
        morningComponents.minute = 0
        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: false)
        let morningRequest = UNNotificationRequest(
            identifier: "com.attm.clera.advice.morning",
            content: morningContent,
            trigger: morningTrigger
        )
        center.add(morningRequest)

        // Midday SPF reminder (12:30 PM) — only if UV is moderate or higher
        if weather.uvIndex >= 3 {
            let middayContent = UNMutableNotificationContent()
            middayContent.title = "Midday Skin Check"
            if weather.uvIndex >= 6 {
                middayContent.body = "UV is strong right now — reapply SPF if you have been outside."
            } else {
                middayContent.body = "Remember to reapply SPF if you have been outdoors."
            }
            middayContent.sound = .default
            middayContent.userInfo = ["route": "dailyAdvice"]

            var middayComponents = DateComponents()
            middayComponents.hour = 12
            middayComponents.minute = 30
            let middayTrigger = UNCalendarNotificationTrigger(dateMatching: middayComponents, repeats: false)
            let middayRequest = UNNotificationRequest(
                identifier: "com.attm.clera.advice.midday",
                content: middayContent,
                trigger: middayTrigger
            )
            center.add(middayRequest)
        }

        // Evening recovery (6:00 PM) — barrier repair focus
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = "Evening Skin Recovery"
        if advice.scanContext?.hasRecentIrritation == true {
            eveningContent.body = "Your skin needs extra care tonight. Focus on soothing and barrier repair."
        } else if advice.routineContext?.recentlyUsedExfoliant == true {
            eveningContent.body = "You used an exfoliant recently — go gentle with your evening routine."
        } else {
            eveningContent.body = "Support your skin's overnight recovery with your evening routine."
        }
        eveningContent.sound = .default
        eveningContent.userInfo = ["route": "dailyAdvice"]

        var eveningComponents = DateComponents()
        eveningComponents.hour = 18
        eveningComponents.minute = 0
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: false)
        let eveningRequest = UNNotificationRequest(
            identifier: "com.attm.clera.advice.evening",
            content: eveningContent,
            trigger: eveningTrigger
        )
        center.add(eveningRequest)
    }

    func cancelDailyAdviceNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: [
            "com.attm.clera.advice.morning",
            "com.attm.clera.advice.midday",
            "com.attm.clera.advice.evening"
        ])
    }

    // MARK: - Smart Nudges

    /// Schedules a one-time local notification from a Nudge.
    func scheduleNudgeNotification(_ nudge: Nudge) {
        let content = UNMutableNotificationContent()
        content.title = nudge.title
        content.body = nudge.body
        content.sound = .default
        content.userInfo = ["nudgeId": nudge.id.uuidString, "route": nudge.actionRoute ?? ""]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "com.attm.clera.nudge.\(nudge.id.uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelNudgeNotification(id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [
            "com.attm.clera.nudge.\(id.uuidString)"
        ])
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let route = userInfo["route"] as? String, route == "dailyAdvice" {
            // Post a notification that the app can observe to navigate to the Today tab
            NotificationCenter.default.post(name: .init("CleraDailyAdviceNotificationTapped"), object: nil)
        }
        completionHandler()
    }
}
