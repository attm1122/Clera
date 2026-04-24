import Foundation

struct PersistedAppState: Codable {
    var hasCompletedOnboarding: Bool
    var selectedGoal: SkinGoal?
    var reminderCadence: ReminderCadence
    var preferredReminderTime: Date
    var currentRoutine: [RoutineItem]
    var sessions: [CheckInSession]
}

struct AppPersistence {
    let fileURL: URL

    init(fileURL: URL = URL.cleraStateFileURL) {
        self.fileURL = fileURL
    }

    func load() -> PersistedAppState? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(PersistedAppState.self, from: data)
    }

    func save(_ state: PersistedAppState) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let folder = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            assertionFailure("Failed to save Clera state: \(error)")
        }
    }
}

private extension URL {
    static var cleraStateFileURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return root.appending(path: "Clera/state.json")
    }
}
