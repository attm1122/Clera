import Observation
import SwiftUI

@Observable
final class AppModel {
    private let persistence: AppPersistence

    var hasCompletedOnboarding: Bool
    var selectedGoal: SkinGoal?
    var reminderCadence: ReminderCadence
    var preferredReminderTime: Date
    var currentRoutine: [RoutineItem]
    var sessions: [CheckInSession]
    var selectedTab: AppTab = .home

    init(persistence: AppPersistence = AppPersistence()) {
        self.persistence = persistence

        if let state = persistence.load() {
            hasCompletedOnboarding = state.hasCompletedOnboarding
            selectedGoal = state.selectedGoal
            reminderCadence = state.reminderCadence
            preferredReminderTime = state.preferredReminderTime
            currentRoutine = state.currentRoutine
            sessions = state.sessions
        } else {
            hasCompletedOnboarding = false
            selectedGoal = nil
            reminderCadence = .threePerWeek
            preferredReminderTime = .now
            currentRoutine = SampleData.defaultRoutine
            sessions = []
        }
    }

    var hasBaseline: Bool {
        sessions.contains(where: { $0.kind == .baseline })
    }

    var sortedSessions: [CheckInSession] {
        sessions.sorted(by: { $0.createdAt > $1.createdAt })
    }

    var progressEntries: [ProgressEntry] {
        sortedSessions.map { session in
            ProgressEntry(
                title: session.kind == .baseline && session.createdAt == oldestSession?.createdAt ? "Baseline" : (session.kind == .checkIn && session.id == latestSession?.id ? "Latest check-in" : session.kind.rawValue),
                note: session.note.isEmpty ? defaultNote(for: session.kind) : session.note,
                date: session.createdAt,
                timeframe: relativeTime(from: session.createdAt)
            )
        }
    }

    var homeSummary: WeeklySummary {
        guard !sessions.isEmpty else {
            return WeeklySummary(
                title: "Start with a baseline",
                body: "Capture your first front, left, and right set so every future check-in has something trustworthy to compare against."
            )
        }

        let weeklyCount = sessions.filter {
            Calendar.current.dateComponents([.day], from: $0.createdAt, to: .now).day ?? 99 <= 7
        }.count

        let body: String
        if hasBaseline {
            body = "You logged \(weeklyCount) check-ins this week. Your routine is stable, and your latest session is ready to compare against baseline."
        } else {
            body = "You’ve started tracking, but a baseline will make the timeline much more useful. Capture one clean reference set next."
        }

        return WeeklySummary(title: "This week", body: body)
    }

    var latestSession: CheckInSession? {
        sortedSessions.first
    }

    var oldestSession: CheckInSession? {
        sessions.sorted(by: { $0.createdAt < $1.createdAt }).first
    }

    var comparisonTitle: String {
        guard let earliest = oldestSession, let latest = latestSession else { return "No comparison yet" }
        return "\(relativeTime(from: earliest.createdAt)) to \(relativeTime(from: latest.createdAt))"
    }

    var comparisonSubtitle: String {
        guard let latest = latestSession else { return "Start a baseline to unlock comparison." }
        return latest.note.isEmpty ? defaultNote(for: latest.kind) : latest.note
    }

    var nextCaptureKind: CheckInSessionKind {
        hasBaseline ? .checkIn : .baseline
    }

    func completeOnboarding(goal: SkinGoal, cadence: ReminderCadence, reminderTime: Date) {
        selectedGoal = goal
        reminderCadence = cadence
        preferredReminderTime = reminderTime
        hasCompletedOnboarding = true
        selectedTab = .home
        persist()
    }

    func recordSession(kind: CheckInSessionKind, note: String) {
        let qualityNotes = [
            "Centered and steady",
            "Good side-angle alignment",
            "Consistent framing"
        ]
        let photos = zip(CaptureAngle.allCases, qualityNotes).map { angle, quality in
            CheckInPhoto(angle: angle, qualityNote: quality)
        }
        sessions.append(CheckInSession(kind: kind, note: note, photos: photos))
        persist()
    }

    func restartOnboarding() {
        hasCompletedOnboarding = false
        persist()
    }

    private func persist() {
        persistence.save(
            PersistedAppState(
                hasCompletedOnboarding: hasCompletedOnboarding,
                selectedGoal: selectedGoal,
                reminderCadence: reminderCadence,
                preferredReminderTime: preferredReminderTime,
                currentRoutine: currentRoutine,
                sessions: sessions
            )
        )
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    private func defaultNote(for kind: CheckInSessionKind) -> String {
        switch kind {
        case .baseline: "Starting point captured in steady light for future comparisons."
        case .checkIn: "A fresh three-angle check-in to keep your progress honest."
        }
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
