import Foundation

/// Abstract cloud sync orchestrator.
protocol CloudSyncing: Sendable {
    /// Push all local data to the cloud for the current user.
    func pushAll() async throws

    /// Pull remote data and merge into local state.
    func pullAll() async throws

    /// Incremental sync: push local changes and pull remote changes.
    func sync() async throws

    /// Upload a single scan session.
    func uploadScan(_ session: ScanSession) async throws

    /// Upload a routine log entry.
    func uploadRoutineLog(_ entry: RoutineLogEntry) async throws

    /// Upload the current profile.
    func uploadProfile(_ profile: SkinProfile) async throws

    /// Mark a local record as synced.
    func markSynced(recordId: String, collection: String) async

    /// Whether a record has been synced.
    func isSynced(recordId: String, collection: String) async -> Bool

    /// Last successful sync date.
    var lastSyncDate: Date? { get }
}
