import Foundation

/// Repository for user profile data in the cloud.
protocol UserProfileRepository: Sendable {
    func saveProfile(_ profile: SkinProfile, userId: String) async throws
    func loadProfile(userId: String) async throws -> SkinProfile?
    func saveUserMeta(_ user: CleraUser) async throws
}
