import XCTest
@testable import Clera

@MainActor
final class MigrationTests: XCTestCase {

    func testMigrationDoesNotDuplicateRecords() async throws {
        let mockAuth = MockAuthProvider()
        _ = try await mockAuth.signUp(email: "test@example.com", password: "pw", name: "Test")

        let mockSync = MockCloudSync()
        let mockReporter = MockCrashReporter()
        let migration = LocalToCloudMigration(cloudSync: mockSync, authProvider: mockAuth, crashReporter: mockReporter)

        let localState = PersistedAppState(
            hasCompletedAuth: true,
            userProfile: UserProfile(name: "Test", email: "test@example.com"),
            permissionState: PermissionState(),
            hasCompletedOnboarding: true,
            skinProfile: SkinProfile(),
            baselineSkinMap: nil,
            skinBaseline: nil,
            currentProducts: [],
            routineLogs: [
                RoutineLogEntry(date: .now, followedRoutine: true, productIDs: [], notes: nil)
            ],
            routineChanges: [],
            sessions: [
                ScanSession(kind: .baseline, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
            ],
            skinMapHistory: [],
            experiments: [],
            insights: [],
            weeklyReports: [],
            weeklyInsights: [],
            productIntelligenceReports: [],
            dailyPlans: [],
            skinSessions: [],
            skinSessionResults: [],
            nudges: [],
            reminderSettings: ReminderSettings(),
            privacySettings: PrivacySettings(),
            selectedTab: .today,
            dailyAdvice: nil,
            dailyAdviceHistory: []
        )

        _ = await migration.migrateIfNeeded(localState: localState)
        let result2 = await migration.migrateIfNeeded(localState: localState)

        XCTAssertEqual(result2, .skipped(.alreadyMigrated))

        let scanCount = mockSync.uploadedScans.count
        let logCount = mockSync.uploadedRoutineLogs.count

        XCTAssertEqual(scanCount, 1)
        XCTAssertEqual(logCount, 1)
    }

    func testMigrationSkipsWithoutAuth() async {
        let mockAuth = MockAuthProvider()
        let mockSync = MockCloudSync()
        let mockReporter = MockCrashReporter()
        let migration = LocalToCloudMigration(cloudSync: mockSync, authProvider: mockAuth, crashReporter: mockReporter)

        let localState = PersistedAppState(
            hasCompletedAuth: false,
            userProfile: nil,
            permissionState: PermissionState(),
            hasCompletedOnboarding: false,
            skinProfile: SkinProfile(),
            baselineSkinMap: nil,
            skinBaseline: nil,
            currentProducts: [],
            routineLogs: [],
            routineChanges: [],
            sessions: [],
            skinMapHistory: [],
            experiments: [],
            insights: [],
            weeklyReports: [],
            weeklyInsights: [],
            productIntelligenceReports: [],
            dailyPlans: [],
            skinSessions: [],
            skinSessionResults: [],
            nudges: [],
            reminderSettings: ReminderSettings(),
            privacySettings: PrivacySettings(),
            selectedTab: .today,
            dailyAdvice: nil,
            dailyAdviceHistory: []
        )

        let result = await migration.migrateIfNeeded(localState: localState)
        XCTAssertEqual(result, .skipped(.authRequired))
    }
}
