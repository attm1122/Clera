import Foundation

// MARK: - Product Rule Engine

enum ProductRuleEngine {

    static func evaluate(context: SkinContext, trends: [ZoneType: [EngineSkinTrend]]) -> [SkinRecommendation] {
        var recommendations: [SkinRecommendation] = []
        let now = Date()

        guard !context.products.isEmpty else { return recommendations }

        // Retinol without SPF in morning routine
        let hasRetinol = context.products.contains { $0.isActive && $0.ingredientTags.contains(.retinol) }
        let hasMorningSPF = context.products.contains { $0.isActive && ($0.period == .morning || $0.period == .both) && $0.ingredientTags.contains(.spf) }

        if hasRetinol && !hasMorningSPF {
            recommendations.append(SkinRecommendation(
                title: "Add SPF to your morning routine",
                body: "Retinoids can make skin more sensitive to sunlight. A morning SPF helps protect your skin while using retinol products.",
                action: "Add SPF product",
                category: .product,
                priority: .high,
                confidence: .high,
                zones: ZoneType.allCases,
                durationDays: nil,
                createdAt: now
            ))
        }

        // Photosensitizing actives without SPF
        let hasPhotosensitizing = context.products.contains { $0.isActive && $0.ingredientTags.contains(where: { $0.isPhotosensitizing }) }
        if hasPhotosensitizing && !hasMorningSPF {
            recommendations.append(SkinRecommendation(
                title: "SPF recommended with active treatments",
                body: "Exfoliating acids or vitamin C in your routine work best when paired with daily sun protection.",
                action: "Add SPF",
                category: .product,
                priority: .high,
                confidence: .high,
                zones: ZoneType.allCases,
                durationDays: nil,
                createdAt: now
            ))
        }

        // Duplicate actives (e.g., multiple exfoliants)
        let exfoliantCount = context.products.filter { $0.isActive && $0.ingredientTags.contains(where: { $0.isExfoliant }) }.count
        if exfoliantCount > 2 {
            recommendations.append(SkinRecommendation(
                title: "Multiple exfoliants detected",
                body: "You have more than two exfoliating products active. Using fewer at a time reduces the chance of over-exfoliation and barrier stress.",
                action: "Review active products",
                category: .product,
                priority: .medium,
                confidence: .medium,
                zones: ZoneType.allCases,
                durationDays: nil,
                createdAt: now
            ))
        }

        // Benzoyl peroxide + retinol conflict
        let hasBenzoyl = context.products.contains { $0.isActive && $0.ingredientTags.contains(.benzoylPeroxide) }
        if hasBenzoyl && hasRetinol {
            recommendations.append(SkinRecommendation(
                title: "Benzoyl peroxide and retinol together",
                body: "Using benzoyl peroxide and retinol in the same routine may reduce effectiveness and increase irritation. Consider using them on alternate nights.",
                action: "Alternate these actives",
                category: .product,
                priority: .high,
                confidence: .medium,
                zones: [.leftCheek, .rightCheek, .chinJaw],
                durationDays: nil,
                createdAt: now
            ))
        }

        // Vitamin C + exfoliant same routine
        let hasVitaminC = context.products.contains { $0.isActive && $0.ingredientTags.contains(.vitaminC) }
        if hasVitaminC && hasPhotosensitizing {
            recommendations.append(SkinRecommendation(
                title: "Vitamin C with exfoliants — consider timing",
                body: "Vitamin C and exfoliating acids can be used together, but separating them (morning vs evening) may improve tolerance.",
                action: "Separate by time of day",
                category: .product,
                priority: .medium,
                confidence: .low,
                zones: ZoneType.allCases,
                durationDays: nil,
                createdAt: now
            ))
        }

        // New product added recently + worsening trend
        let recentChanges = context.routineChanges.filter {
            guard let days = Calendar.current.dateComponents([.day], from: $0.date, to: now).day else { return false }
            return days <= 14 && $0.changeType == .added
        }
        let allTrends = trends.values.flatMap { $0 }
        let worseningMetrics = allTrends.filter { $0.direction == .worsening }
        let hasWorseningTrend = worseningMetrics.contains { trend in
            let metric = trend.metric
            return metric == .redness || metric == .breakoutLikeSpots || metric == .dryness
        }

        if !recentChanges.isEmpty && hasWorseningTrend {
            let productNames = recentChanges.compactMap { change in
                context.products.first { $0.id == change.productId }?.name
            }
            if !productNames.isEmpty {
                let names = productNames.joined(separator: ", ")
                let bodyText = names + " was added recently and some metrics look more pronounced. New products can take 2–4 weeks to settle. If irritation continues, consider pausing."
                recommendations.append(SkinRecommendation(
                    title: "New product adjustment period",
                    body: bodyText,
                    action: "Monitor for 2 weeks",
                    category: .product,
                    priority: .medium,
                    confidence: .low,
                    zones: ZoneType.allCases,
                    durationDays: 14,
                    createdAt: now
                ))
            }
        }

        // Missing moisturiser
        let hasMoisturiser = context.products.contains { $0.isActive && ($0.category == .moisturizer || $0.category == .serum) }
        if !hasMoisturiser && !context.products.isEmpty {
            recommendations.append(SkinRecommendation(
                title: "Consider adding a moisturiser",
                body: "A moisturiser helps support your skin barrier, which is the foundation of any routine. Even oily skin benefits from light hydration.",
                action: "Add moisturiser",
                category: .product,
                priority: .medium,
                confidence: .high,
                zones: ZoneType.allCases,
                durationDays: nil,
                createdAt: now
            ))
        }

        // Too many actives overall
        let activeCount = context.products.filter { $0.isActive && $0.ingredientTags.contains(where: { $0.isActiveTreatment }) }.count
        if activeCount > 4 {
            let bodyText = "You have " + String(activeCount) + " active treatment products. Simplifying to 2–3 core actives often gives better results with less risk of irritation."
            recommendations.append(SkinRecommendation(
                title: "Many active treatments active",
                body: bodyText,
                action: "Review active products",
                category: .product,
                priority: .medium,
                confidence: .medium,
                zones: ZoneType.allCases,
                durationDays: nil,
                createdAt: now
            ))
        }

        return recommendations
    }
}
