import Foundation
@testable import Clera

// MARK: - Mock Cloud Sync

final class MockCloudSync: CloudSyncing, @unchecked Sendable {
    var lastSyncDate: Date?
    var uploadedScans: [ScanSession] = []
    var uploadedRoutineLogs: [RoutineLogEntry] = []
    var uploadedProfiles: [SkinProfile] = []
    var syncedRecordIds: Set<String> = []
    var shouldSucceed = true
    var simulatedError: CloudSyncError = .unknown("mock sync error")

    func pushAll() async throws {
        guard shouldSucceed else { throw simulatedError }
        lastSyncDate = .now
    }

    func pullAll() async throws {
        guard shouldSucceed else { throw simulatedError }
        lastSyncDate = .now
    }

    func sync() async throws {
        guard shouldSucceed else { throw simulatedError }
        lastSyncDate = .now
    }

    func uploadScan(_ session: ScanSession) async throws {
        guard shouldSucceed else { throw simulatedError }
        uploadedScans.append(session)
        await markSynced(recordId: session.id.uuidString, collection: "skinScans")
    }

    func uploadRoutineLog(_ entry: RoutineLogEntry) async throws {
        guard shouldSucceed else { throw simulatedError }
        uploadedRoutineLogs.append(entry)
        await markSynced(recordId: entry.id.uuidString, collection: "routineLogs")
    }

    func uploadProfile(_ profile: SkinProfile) async throws {
        guard shouldSucceed else { throw simulatedError }
        uploadedProfiles.append(profile)
        await markSynced(recordId: "main", collection: "profile")
    }

    func markSynced(recordId: String, collection: String) async {
        syncedRecordIds.insert("\(collection)/\(recordId)")
    }

    func isSynced(recordId: String, collection: String) async -> Bool {
        syncedRecordIds.contains("\(collection)/\(recordId)")
    }
}
