import Observation
import SwiftUI

@Observable
final class AppModel {
    var hasCompletedOnboarding = false
    var selectedGoal: SkinGoal?
    var reminderCadence: ReminderCadence = .threePerWeek
    var preferredReminderTime = Date.now
    var currentRoutine = SampleData.defaultRoutine
    var progressEntries = SampleData.progressEntries
    var selectedTab: AppTab = .home

    var homeSummary: WeeklySummary {
        WeeklySummary(
            title: "This week",
            body: "You checked in 4 times. Your routine has been stable for 12 days. Compare today with your baseline to see gradual changes more clearly."
        )
    }

    var latestEntry: ProgressEntry? {
        progressEntries.sorted { $0.date > $1.date }.first
    }

    func completeOnboarding(goal: SkinGoal, cadence: ReminderCadence, reminderTime: Date) {
        selectedGoal = goal
        reminderCadence = cadence
        preferredReminderTime = reminderTime
        hasCompletedOnboarding = true
        selectedTab = .home
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case progress
    case routine
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .progress: "Progress"
        case .routine: "Routine"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .progress: "square.stack.3d.forward.dottedline"
        case .routine: "drop"
        case .profile: "person"
        }
    }
}

