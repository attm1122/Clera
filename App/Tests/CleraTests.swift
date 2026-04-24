import XCTest
@testable import Clera

final class CleraTests: XCTestCase {
    func testCompletingOnboardingSetsCoreState() {
        let persistence = AppPersistence(fileURL: temporaryFileURL())
        let model = AppModel(persistence: persistence)
        let reminderTime = Date(timeIntervalSince1970: 1234)

        model.completeOnboarding(goal: .texture, cadence: .weekly, reminderTime: reminderTime)

        XCTAssertTrue(model.hasCompletedOnboarding)
        XCTAssertEqual(model.selectedGoal, .texture)
        XCTAssertEqual(model.reminderCadence, .weekly)
        XCTAssertEqual(model.preferredReminderTime, reminderTime)
        XCTAssertEqual(model.selectedTab, .home)
    }

    func testRecordingSessionPersistsAcrossReload() {
        let fileURL = temporaryFileURL()
        let persistence = AppPersistence(fileURL: fileURL)
        let model = AppModel(persistence: persistence)

        model.completeOnboarding(goal: .acne, cadence: .daily, reminderTime: .now)
        model.recordSession(kind: .baseline, note: "Steady morning light")

        let reloaded = AppModel(persistence: persistence)

        XCTAssertTrue(reloaded.hasCompletedOnboarding)
        XCTAssertEqual(reloaded.selectedGoal, .acne)
        XCTAssertTrue(reloaded.hasBaseline)
        XCTAssertEqual(reloaded.sessions.count, 1)
        XCTAssertEqual(reloaded.sessions.first?.photos.count, 3)
        XCTAssertEqual(reloaded.sessions.first?.note, "Steady morning light")
    }

    private func temporaryFileURL() -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        return folder.appending(path: "state.json")
    }
}
