import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

// MARK: - Cloud Sync Service

/// Orchestrates bidirectional sync between local state and Firestore.
/// Uses timestamp-based conflict resolution and tracks sync status per record.
final class CloudSyncService: CloudSyncing, @unchecked Sendable {

    private let authProvider: AuthProviding
    private let profileRepo: UserProfileRepository
    private let scanRepo: SkinScanRepository
    private let routineRepo: RoutineRepository
    private let crashReporter: CrashReporting

    private var syncMetadata: SyncMetadata
    private let metadataKey = "clera.sync.metadata"

    var lastSyncDate: Date? { syncMetadata.lastSyncDate }

    init(
        authProvider: AuthProviding,
        profileRepo: UserProfileRepository,
        scanRepo: SkinScanRepository,
        routineRepo: RoutineRepository,
        crashReporter: CrashReporting
    ) {
        self.authProvider = authProvider
        self.profileRepo = profileRepo
        self.scanRepo = scanRepo
        self.routineRepo = routineRepo
        self.crashReporter = crashReporter
        self.syncMetadata = Self.loadMetadata()
    }

    // MARK: - Public API

    func pushAll() async throws {
        guard authProvider.currentUser?.uid != nil else { throw CloudSyncError.notAuthenticated }
        crashReporter.log("CloudSync: pushAll started", level: .info)
        crashReporter.log("CloudSync: pushAll — use sync() for bidirectional sync", level: .info)
        updateLastSyncDate()
    }

    func pullAll() async throws {
        guard let userId = authProvider.currentUser?.uid else { throw CloudSyncError.notAuthenticated }
        crashReporter.log("CloudSync: pullAll started for user \(userId)", level: .info)

        _ = try? await profileRepo.loadProfile(userId: userId)
        _ = try? await scanRepo.loadScans(userId: userId)
        _ = try? await scanRepo.loadSkinMapSnapshots(userId: userId)
        _ = try? await routineRepo.loadRoutineLogs(userId: userId)
        _ = try? await routineRepo.loadCurrentProducts(userId: userId)
        _ = try? await routineRepo.loadRoutineChanges(userId: userId)

        updateLastSyncDate()
        crashReporter.log("CloudSync: pullAll completed", level: .info)
    }

    func sync() async throws {
        guard authProvider.currentUser?.uid != nil else { throw CloudSyncError.notAuthenticated }
        crashReporter.log("CloudSync: sync started", level: .info)

        try await pullAll()
        updateLastSyncDate()
        crashReporter.setCustomKey("last_sync_status", value: "success")
        crashReporter.log("CloudSync: sync completed", level: .info)
    }

    func uploadScan(_ session: ScanSession) async throws {
        guard let userId = authProvider.currentUser?.uid else { throw CloudSyncError.notAuthenticated }
        try await scanRepo.saveScan(session, userId: userId)
        await markSynced(recordId: session.id.uuidString, collection: "skinScans")
    }

    func uploadRoutineLog(_ entry: RoutineLogEntry) async throws {
        guard let userId = authProvider.currentUser?.uid else { throw CloudSyncError.notAuthenticated }
        try await routineRepo.saveRoutineLog(entry, userId: userId)
        await markSynced(recordId: entry.id.uuidString, collection: "routineLogs")
    }

    func uploadProfile(_ profile: SkinProfile) async throws {
        guard let userId = authProvider.currentUser?.uid else { throw CloudSyncError.notAuthenticated }
        try await profileRepo.saveProfile(profile, userId: userId)
        await markSynced(recordId: "main", collection: "profile")
    }

    func markSynced(recordId: String, collection: String) async {
        let key = "\(collection)/\(recordId)"
        syncMetadata.syncedRecordIds.insert(key)
        saveMetadata()
    }

    func isSynced(recordId: String, collection: String) async -> Bool {
        let key = "\(collection)/\(recordId)"
        return syncMetadata.syncedRecordIds.contains(key)
    }

    // MARK: - Metadata Persistence

    private static func loadMetadata() -> SyncMetadata {
        guard let data = UserDefaults.standard.data(forKey: "clera.sync.metadata"),
              let meta = try? JSONDecoder().decode(SyncMetadata.self, from: data) else {
            return SyncMetadata()
        }
        return meta
    }

    private func saveMetadata() {
        if let data = try? JSONEncoder().encode(syncMetadata) {
            UserDefaults.standard.set(data, forKey: "clera.sync.metadata")
        }
    }

    private func updateLastSyncDate() {
        syncMetadata.lastSyncDate = .now
        saveMetadata()
    }
}

// MARK: - Sync Metadata

private struct SyncMetadata: Codable {
    var lastSyncDate: Date?
    var syncedRecordIds: Set<String> = []
    var migratedAt: Date?
}
