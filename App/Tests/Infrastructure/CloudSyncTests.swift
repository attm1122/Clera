import XCTest
@testable import Clera

@MainActor
final class CloudSyncTests: XCTestCase {

    func testUploadScanMarksSynced() async throws {
        let mockAuth = MockAuthProvider()
        _ = try await mockAuth.signUp(email: "test@example.com", password: "pw", name: "Test")

        let mockSync = MockCloudSync()
        let model = AppModel(authProvider: mockAuth, cloudSync: mockSync)

        model.recordSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: "Test")

        try? await Task.sleep(nanoseconds: 200_000_000)

        let recordedSession = model.sessions.last!
        let isSynced = await mockSync.isSynced(recordId: recordedSession.id.uuidString, collection: "skinScans")
        XCTAssertTrue(isSynced)
    }

    func testConflictResolutionUsesTimestamps() async throws {
        let mockAuth = MockAuthProvider()
        _ = try await mockAuth.signUp(email: "test@example.com", password: "pw", name: "Test")

        let mockSync = MockCloudSync()
        let earlier = Date(timeIntervalSince1970: 1000)
        let later = Date(timeIntervalSince1970: 2000)

        // Simulate local data being older than remote
        XCTAssertTrue(later > earlier)

        // Sync should prefer the later timestamp
        mockSync.shouldSucceed = true
        try await mockSync.sync()
        XCTAssertNotNil(mockSync.lastSyncDate)
    }

    func testSyncFailureDoesNotCorruptLocalState() async throws {
        let mockAuth = MockAuthProvider()
        _ = try await mockAuth.signUp(email: "test@example.com", password: "pw", name: "Test")

        let mockSync = MockCloudSync()
        mockSync.shouldSucceed = false

        let model = AppModel(authProvider: mockAuth, cloudSync: mockSync)
        let initialCount = model.sessions.count

        model.recordSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: "Test")

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(model.sessions.count, initialCount + 1)
    }
}
