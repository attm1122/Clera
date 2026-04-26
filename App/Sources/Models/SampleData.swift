import Foundation

enum SampleData {
    static let defaultProducts: [Product] = [
        Product(name: "Gentle Cleanser", category: .cleanser, period: .both, ingredientTags: []),
        Product(name: "Vitamin C Serum", category: .serum, period: .morning, ingredientTags: [.vitaminC]),
        Product(name: "Niacinamide Serum", category: .serum, period: .evening, ingredientTags: [.niacinamide]),
        Product(name: "Moisturizer", category: .moisturizer, period: .both, ingredientTags: [.hyaluronicAcid, .ceramides]),
        Product(name: "Sunscreen SPF 50", category: .sunscreen, period: .morning, ingredientTags: [.spf])
    ]

    static var sampleSkinMap: SkinMap {
        SkinMap(zones: [
            FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: .low, redness: .none, texture: .low)),
            FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: .low, redness: .low, texture: .moderate)),
            FaceZone(zoneType: .leftCheek, status: ZoneStatus(breakouts: .none, redness: .none, texture: .low)),
            FaceZone(zoneType: .rightCheek, status: ZoneStatus(breakouts: .low, redness: .none, texture: .low)),
            FaceZone(zoneType: .chinJaw, status: ZoneStatus(breakouts: .moderate, redness: .low, texture: .moderate))
        ])
    }

    static let sampleInsights: [Insight] = [
        Insight(title: "Redness improving", body: "Nose redness down 40% since last week. Keep using niacinamide.", type: .improvement, zone: .nose, priority: .high),
        Insight(title: "Breakout pattern detected", body: "Jaw breakouts correlate with late nights. Sleep earlier this week.", type: .habit, zone: .chinJaw, priority: .medium),
        Insight(title: "Texture looking smoother", body: "Left cheek texture improved significantly after adding vitamin C.", type: .productEffect, zone: .leftCheek, priority: .medium)
    ]

    static var sampleWeeklyReport: WeeklyReport {
        WeeklyReport(weekEnding: .now, summary: "Great week! Overall skin condition improved by 25%.", topImprovement: "Nose texture smoother after consistent niacinamide use.", watchArea: "Chin & jaw still breaking out — review evening routine.", photoComparisons: [])
    }

    static let sampleExperiments: [Experiment] = [
        Experiment(name: "Niacinamide Test", zone: .nose, hypothesis: "Niacinamide will reduce nose redness over 2 weeks.", durationDays: 14, isActive: true, relatedProductIDs: [defaultProducts[2].id], dailyCheckIns: [])
    ]
}
