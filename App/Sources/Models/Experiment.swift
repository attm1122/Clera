import Foundation

struct Experiment: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var zone: ZoneType
    var hypothesis: String
    var durationDays: Int
    var isActive: Bool
    var startDate: Date = .now
    var endDate: Date?
    var relatedProductIDs: [UUID]
    var result: ExperimentResult?
    var dailyCheckIns: [DailyCheckIn]
}

struct ExperimentResult: Codable, Equatable, Hashable {
    var outcome: ExperimentOutcome
    var notes: String?
    var finalSkinMapID: UUID?
}

enum ExperimentOutcome: String, Codable, Hashable {
    case improvement, noChange, worsened
}

struct DailyCheckIn: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var date: Date
    var skinCondition: String
    var notes: String?
    var photo: ScanPhoto?
}
