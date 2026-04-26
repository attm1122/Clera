import XCTest
@testable import Clera

@MainActor
final class CleraTests: XCTestCase {
    func testCompletingAuthSetsUserProfile() async {
        let persistence = AppPersistence(fileURL: temporaryFileURL())
        let model = AppModel(persistence: persistence)

        await model.completeAuth(name: "Aubrey", email: "aubrey@example.com")

        XCTAssertTrue(model.hasCompletedAuth)
        XCTAssertEqual(model.userProfile?.name, "Aubrey")
        XCTAssertEqual(model.userProfile?.email, "aubrey@example.com")
    }

    func testCompletingOnboardingSetsCoreState() async {
        let persistence = AppPersistence(fileURL: temporaryFileURL())
        let model = AppModel(persistence: persistence)
        await model.completeAuth(name: "Test", email: "test@example.com")

        var profile = SkinProfile()
        profile.primaryGoal = .smootherTexture
        let baseline = SampleData.sampleSkinMap
        model.completeOnboarding(skinProfile: profile, baselineMap: baseline)

        XCTAssertTrue(model.hasCompletedOnboarding)
        XCTAssertEqual(model.skinProfile.primaryGoal, .smootherTexture)
        XCTAssertEqual(model.selectedTab, .today)
    }

    func testRecordingSessionPersistsAcrossReload() async {
        let fileURL = temporaryFileURL()
        let persistence = AppPersistence(fileURL: fileURL)
        let model = AppModel(persistence: persistence)

        await model.completeAuth(name: "Test", email: "test@example.com")
        var profile = SkinProfile()
        profile.primaryGoal = .fewerBreakouts
        model.completeOnboarding(skinProfile: profile, baselineMap: SampleData.sampleSkinMap)

        let skinMap = SampleData.sampleSkinMap
        model.recordSession(kind: .baseline, photos: [], skinMap: skinMap, note: "Steady morning light")

        let reloaded = AppModel(persistence: persistence)

        XCTAssertTrue(reloaded.hasCompletedAuth)
        XCTAssertTrue(reloaded.hasCompletedOnboarding)
        XCTAssertEqual(reloaded.skinProfile.primaryGoal, .fewerBreakouts)
        XCTAssertTrue(reloaded.hasBaseline)
        XCTAssertEqual(reloaded.sessions.count, 1)
        XCTAssertEqual(reloaded.sessions.first?.note, "Steady morning light")
    }

    func testAddingAndRemovingProducts() {
        let persistence = AppPersistence(fileURL: temporaryFileURL())
        let model = AppModel(persistence: persistence)

        let product = Product(name: "Test Toner", category: .toner, period: .morning)
        model.addProduct(product)

        XCTAssertEqual(model.currentProducts.count, 6) // 5 default + 1 new
        XCTAssertTrue(model.currentProducts.contains(where: { $0.name == "Test Toner" }))

        model.removeProduct(id: product.id)
        XCTAssertEqual(model.currentProducts.count, 5)
    }

    func testRoutineLogging() {
        let persistence = AppPersistence(fileURL: temporaryFileURL())
        let model = AppModel(persistence: persistence)

        let entry = RoutineLogEntry(date: .now, followedRoutine: true, productIDs: [UUID()], notes: "Felt good")
        model.logRoutine(entry)

        XCTAssertEqual(model.routineLogs.count, 1)
        XCTAssertEqual(model.todayRoutineLogs.count, 1)
    }

    private func temporaryFileURL() -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        return folder.appending(path: "state.json")
    }
}
