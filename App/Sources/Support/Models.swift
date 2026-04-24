import Foundation

enum SkinGoal: String, CaseIterable, Identifiable, Codable {
    case acne = "Acne"
    case darkMarks = "Dark marks"
    case redness = "Redness"
    case texture = "Texture"
    case oiliness = "Oiliness"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .acne: "Track breakouts and inflammation over time."
        case .darkMarks: "Watch post-acne marks fade more clearly."
        case .redness: "Notice stability and flare patterns."
        case .texture: "Compare smoothness and unevenness gradually."
        case .oiliness: "Monitor shine, congestion, and routine shifts."
        }
    }
}

enum ReminderCadence: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case threePerWeek = "3 times a week"
    case weekly = "Weekly"

    var id: String { rawValue }
}

struct RoutineItem: Identifiable, Hashable, Codable {
    let id: UUID
    let period: RoutinePeriod
    let category: String
    let productName: String

    init(id: UUID = UUID(), period: RoutinePeriod, category: String, productName: String) {
        self.id = id
        self.period = period
        self.category = category
        self.productName = productName
    }
}

enum RoutinePeriod: String, CaseIterable, Identifiable, Codable {
    case am = "AM"
    case pm = "PM"

    var id: String { rawValue }
}

enum CheckInSessionKind: String, CaseIterable, Identifiable, Codable {
    case baseline = "Baseline"
    case checkIn = "Check-in"

    var id: String { rawValue }

    var actionTitle: String {
        switch self {
        case .baseline: "Start baseline"
        case .checkIn: "Check in"
        }
    }

    var description: String {
        switch self {
        case .baseline: "Capture your first front, left, and right reference set."
        case .checkIn: "Keep your timeline consistent with a fresh three-angle check-in."
        }
    }
}

enum CaptureAngle: String, CaseIterable, Identifiable, Codable {
    case front
    case left
    case right

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var guidance: String {
        switch self {
        case .front: "Hold the phone at eye level and keep your face centered."
        case .left: "Turn slightly left so the cheek and temple stay visible."
        case .right: "Turn slightly right and keep the frame steady."
        }
    }
}

struct CheckInPhoto: Identifiable, Hashable, Codable {
    let id: UUID
    let angle: CaptureAngle
    let capturedAt: Date
    let qualityNote: String

    init(id: UUID = UUID(), angle: CaptureAngle, capturedAt: Date = .now, qualityNote: String) {
        self.id = id
        self.angle = angle
        self.capturedAt = capturedAt
        self.qualityNote = qualityNote
    }
}

struct CheckInSession: Identifiable, Hashable, Codable {
    let id: UUID
    let kind: CheckInSessionKind
    let createdAt: Date
    let note: String
    let photos: [CheckInPhoto]

    init(
        id: UUID = UUID(),
        kind: CheckInSessionKind,
        createdAt: Date = .now,
        note: String,
        photos: [CheckInPhoto]
    ) {
        self.id = id
        self.kind = kind
        self.createdAt = createdAt
        self.note = note
        self.photos = photos
    }
}

struct ProgressEntry: Identifiable, Hashable {
    let id: UUID
    let title: String
    let note: String
    let date: Date
    let timeframe: String

    init(id: UUID = UUID(), title: String, note: String, date: Date, timeframe: String) {
        self.id = id
        self.title = title
        self.note = note
        self.date = date
        self.timeframe = timeframe
    }
}

struct WeeklySummary {
    let title: String
    let body: String
}

enum SampleData {
    static let defaultRoutine: [RoutineItem] = [
        RoutineItem(period: .am, category: "Cleanser", productName: "CeraVe Hydrating Cleanser"),
        RoutineItem(period: .am, category: "Treatment", productName: "Vitamin C Serum"),
        RoutineItem(period: .am, category: "Moisturizer", productName: "Vanicream Daily Facial Moisturizer"),
        RoutineItem(period: .am, category: "SPF", productName: "EltaMD UV Clear"),
        RoutineItem(period: .pm, category: "Cleanser", productName: "CeraVe Hydrating Cleanser"),
        RoutineItem(period: .pm, category: "Treatment", productName: "Adapalene"),
        RoutineItem(period: .pm, category: "Moisturizer", productName: "Vanicream Daily Facial Moisturizer")
    ]
}
