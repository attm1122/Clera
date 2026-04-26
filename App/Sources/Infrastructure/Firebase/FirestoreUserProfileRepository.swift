import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

final class FirestoreUserProfileRepository: UserProfileRepository, @unchecked Sendable {

    #if canImport(FirebaseFirestore)
    private let db: Firestore?
    #endif

    init() {
        #if canImport(FirebaseFirestore)
        self.db = FirebaseConfiguration.isConfigured ? Firestore.firestore() : nil
        #endif
    }

    func saveProfile(_ profile: SkinProfile, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        let dto = FirestoreUserProfileDTO(from: profile, userId: userId, name: "", email: nil)
        do {
            let data = try dto.asFirestoreDictionary()
            try await db.collection("users").document(userId).collection("profile").document("main").setData(data)
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }

    func loadProfile(userId: String) async throws -> SkinProfile? {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        do {
            let snapshot = try await db.collection("users").document(userId).collection("profile").document("main").getDocument()
            guard let data = snapshot.data() else { return nil }
            return try decodeProfile(from: data)
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }

    func saveUserMeta(_ user: CleraUser) async throws {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        do {
            try await db.collection("users").document(user.uid).setData([
                "uid": user.uid,
                "email": user.email as Any,
                "displayName": user.displayName as Any,
                "isAnonymous": user.isAnonymous,
                "updatedAt": Timestamp(date: .now)
            ], merge: true)
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }

    #if canImport(FirebaseFirestore)
    private func decodeProfile(from data: [String: Any]) throws -> SkinProfile {
        guard let skinType = data["skinType"] as? String else { throw CloudSyncError.decodingFailed }
        return SkinProfile(
            skinType: SkinType(rawValue: skinType) ?? .combination,
            sensitivity: Sensitivity(rawValue: data["sensitivity"] as? String ?? "") ?? .mild,
            primaryConcerns: (data["primaryConcerns"] as? [String] ?? []).compactMap { SkinConcern(rawValue: $0) },
            primaryGoal: SkinGoal(rawValue: data["primaryGoal"] as? String ?? "") ?? .evenTone,
            ageRange: AgeRange(rawValue: data["ageRange"] as? String ?? "") ?? .range25to34,
            stressLevel: StressLevel(rawValue: data["stressLevel"] as? String ?? "") ?? .moderate
        )
    }
    #endif
}
