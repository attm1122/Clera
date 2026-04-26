import Foundation

// MARK: - Local-to-Cloud Migration

/// Migrates existing local JSON data to Firestore after the user authenticates.
/// Marks migrated records to prevent duplicate uploads.
final class LocalToCloudMigration: Sendable {

    private let cloudSync: CloudSyncing
    private let authProvider: AuthProviding
    private let crashReporter: CrashReporting

    init(cloudSync: CloudSyncing, authProvider: AuthProviding, crashReporter: CrashReporting) {
        self.cloudSync = cloudSync
        self.authProvider = authProvider
        self.crashReporter = crashReporter
    }

    /// Migrates local state to the cloud if:
    /// - User is authenticated
    /// - Migration has not already run for this user
    /// - Local data exists
    func migrateIfNeeded(localState: PersistedAppState) async -> MigrationResult {
        guard let user = authProvider.currentUser else {
            crashReporter.log("Migration skipped: no authenticated user", level: .warning)
            return .skipped(.authRequired)
        }

        guard !isAlreadyMigrated(for: user.uid) else {
            crashReporter.log("Migration skipped: already migrated for user \(user.uid)", level: .info)
            return .skipped(.alreadyMigrated)
        }

        crashReporter.log("Migration started for user \(user.uid)", level: .info)

        var successCount = 0
        var failureCount = 0

        do {
            try await cloudSync.uploadProfile(localState.skinProfile)
            successCount += 1
        } catch {
            failureCount += 1
            crashReporter.recordError(error, context: ["migration_step": "profile", "userId": user.uid])
        }

        for session in localState.sessions {
            do {
                let alreadySynced = await cloudSync.isSynced(recordId: session.id.uuidString, collection: "skinScans")
                guard !alreadySynced else { continue }
                try await cloudSync.uploadScan(session)
                successCount += 1
            } catch {
                failureCount += 1
                crashReporter.recordError(error, context: ["migration_step": "scan", "scanId": session.id.uuidString])
            }
        }

        for entry in localState.routineLogs {
            do {
                let alreadySynced = await cloudSync.isSynced(recordId: entry.id.uuidString, collection: "routineLogs")
                guard !alreadySynced else { continue }
                try await cloudSync.uploadRoutineLog(entry)
                successCount += 1
            } catch {
                failureCount += 1
                crashReporter.recordError(error, context: ["migration_step": "routineLog", "logId": entry.id.uuidString])
            }
        }

        let result: MigrationResult
        if failureCount == 0 {
            markMigrated(for: user.uid)
            result = .success(recordCount: successCount)
            crashReporter.log("Migration completed: \(successCount) records", level: .info)
        } else if successCount > 0 {
            markMigrated(for: user.uid)
            result = .partial(successCount: successCount, failureCount: failureCount)
            crashReporter.log("Migration partial: \(successCount) success, \(failureCount) failed", level: .warning)
        } else {
            result = .failed(MigrationError.uploadFailed("All uploads failed"))
            crashReporter.log("Migration failed: all uploads failed", level: .error)
        }

        crashReporter.setCustomKey("last_migration_status", value: result.description)
        return result
    }

    // MARK: - Private

    private func isAlreadyMigrated(for userId: String) -> Bool {
        let key = "clera.migrated.\(userId)"
        return UserDefaults.standard.bool(forKey: key)
    }

    private func markMigrated(for userId: String) {
        let key = "clera.migrated.\(userId)"
        UserDefaults.standard.set(true, forKey: key)
    }
}

// MARK: - Migration Result

enum MigrationResult: Equatable {
    case success(recordCount: Int)
    case partial(successCount: Int, failureCount: Int)
    case skipped(MigrationError)
    case failed(MigrationError)

    var description: String {
        switch self {
        case .success(let count): return "success_\(count)"
        case .partial(let s, let f): return "partial_\(s)_\(f)"
        case .skipped(let e): return "skipped_\(e)"
        case .failed: return "failed"
        }
    }
}
