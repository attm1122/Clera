import Foundation

struct Routine: Codable, Equatable {
    var morningSteps: [RoutineStep] = []
    var eveningSteps: [RoutineStep] = []
}

struct RoutineStep: Codable, Identifiable, Equatable {
    var id = UUID()
    var productID: UUID
    var order: Int
}

struct RoutineLogEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var followedRoutine: Bool
    var productIDs: [UUID]
    var notes: String?
    var photo: ScanPhoto?
}

struct RoutineChangeLogEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date = .now
    let productId: UUID
    let changeType: ChangeType
    var notes: String?
}

enum ChangeType: String, Codable {
    case added, removed, switched
}
