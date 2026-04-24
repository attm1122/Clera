import Foundation

enum SkinGoal: String, CaseIterable, Identifiable {
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

enum ReminderCadence: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case threePerWeek = "3 times a week"
    case weekly = "Weekly"

    var id: String { rawValue }
}

struct RoutineItem: Identifiable, Hashable {
    let id = UUID()
    let period: RoutinePeriod
    let category: String
    let productName: String
}

enum RoutinePeriod: String, CaseIterable, Identifiable {
    case am = "AM"
    case pm = "PM"

    var id: String { rawValue }
}

struct ProgressEntry: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let note: String
    let date: Date
    let timeframe: String
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

    static let progressEntries: [ProgressEntry] = [
        ProgressEntry(title: "Baseline", note: "Starting point captured in steady bathroom light.", date: .now.addingTimeInterval(-60 * 60 * 24 * 28), timeframe: "28 days ago"),
        ProgressEntry(title: "Routine stabilized", note: "No product changes in the last 12 days.", date: .now.addingTimeInterval(-60 * 60 * 24 * 12), timeframe: "12 days ago"),
        ProgressEntry(title: "This week", note: "Checked in 4 times and kept your evening routine consistent.", date: .now.addingTimeInterval(-60 * 60 * 24 * 2), timeframe: "2 days ago"),
        ProgressEntry(title: "Latest check-in", note: "Best front-angle capture so far. Compare with baseline.", date: .now, timeframe: "Today")
    ]
}
