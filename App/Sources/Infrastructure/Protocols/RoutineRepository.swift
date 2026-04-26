import Foundation

/// Repository for routine data in the cloud.
protocol RoutineRepository: Sendable {
    func saveRoutineLog(_ entry: RoutineLogEntry, userId: String) async throws
    func loadRoutineLogs(userId: String) async throws -> [RoutineLogEntry]
    func saveCurrentProducts(_ products: [Product], userId: String) async throws
    func loadCurrentProducts(userId: String) async throws -> [Product]
    func saveRoutineChanges(_ changes: [RoutineChangeLogEntry], userId: String) async throws
    func loadRoutineChanges(userId: String) async throws -> [RoutineChangeLogEntry]
}
