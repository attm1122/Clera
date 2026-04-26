import Foundation

struct UserProfile: Codable, Equatable {
    var name: String
    var email: String
}

struct PermissionState: Codable, Equatable {
    var cameraGranted: Bool = false
    var photoLibraryGranted: Bool = false
    var notificationsGranted: Bool = false
}
