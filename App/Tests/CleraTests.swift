import XCTest
@testable import Clera

final class CleraTests: XCTestCase {
    func testCompletingOnboardingSetsCoreState() {
        let model = AppModel()
        let reminderTime = Date(timeIntervalSince1970: 1234)

        model.completeOnboarding(goal: .texture, cadence: .weekly, reminderTime: reminderTime)

        XCTAssertTrue(model.hasCompletedOnboarding)
        XCTAssertEqual(model.selectedGoal, .texture)
        XCTAssertEqual(model.reminderCadence, .weekly)
        XCTAssertEqual(model.preferredReminderTime, reminderTime)
        XCTAssertEqual(model.selectedTab, .home)
    }
}
