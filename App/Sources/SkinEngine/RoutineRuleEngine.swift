import Foundation

// MARK: - Routine Rule Engine

enum RoutineRuleEngine {

    static func evaluate(context: SkinContext, trends: [ZoneType: [EngineSkinTrend]]) -> [SkinRecommendation] {
        var recommendations: [SkinRecommendation] = []
        let calendar = Calendar.current
        let now = Date()

        // Check 7-day adherence
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let weekLogs = context.routineLogs.filter { $0.date >= weekAgo && $0.followedRoutine }
        let expectedLogs = 14
        let adherenceRate = Double(weekLogs.count) / Double(expectedLogs)

        // Missed PM routine + worsening congestion
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let yesterdayLogs = context.routineLogs.filter { calendar.isDate($0.date, inSameDayAs: yesterday) }
        let hadPMYesterday = yesterdayLogs.contains { calendar.component(.hour, from: $0.date) >= 12 }
        let hasWorseningCongestion = trends.values.flatMap { $0 }.contains { $0.metric == .evenness && $0.direction == .worsening }

        if !hadPMYesterday && hasWorseningCongestion {
            recommendations.append(SkinRecommendation(
                title: "Simple PM reset tonight",
                body: "Your PM routine was missed recently and congestion looks a little more pronounced. Tonight, keep it simple: cleanse and moisturise.",
                action: "Log PM routine",
                category: .routine,
                priority: .medium,
                confidence: .medium,
                zones: [.chinJaw, .forehead],
                durationDays: 1,
                createdAt: .now
            ))
        }

        // Missed sunscreen on UV day
        if let weather = context.weatherSnapshot, weather.uvIndex >= 3 {
            let todayLogs = context.routineLogs.filter { calendar.isDate($0.date, inSameDayAs: now) }
            let hasSPF = context.products.contains { $0.isActive && ($0.period == .morning || $0.period == .both) && $0.ingredientTags.contains(.spf) }
            let loggedMorning = todayLogs.contains { calendar.component(.hour, from: $0.date) < 12 }

            if hasSPF && loggedMorning {
                let todayProductIDs = todayLogs.flatMap { $0.productIDs }
                let usedSPF = context.products.contains { todayProductIDs.contains($0.id) && $0.ingredientTags.contains(.spf) }
                if !usedSPF {
                    recommendations.append(SkinRecommendation(
                        title: "SPF is your priority today",
                        body: "UV is moderate or higher and sunscreen was not in your logged routine. Apply SPF before going outside.",
                        action: "Apply SPF",
                        category: .routine,
                        priority: .high,
                        confidence: .high,
                        zones: [.forehead, .nose],
                        durationDays: 1,
                        createdAt: .now
                    ))
                }
            }
        }

        // Over-exfoliation check
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        let recentLogs = context.routineLogs.filter { $0.date >= twoWeeksAgo && $0.followedRoutine }
        let exfoliantProducts = context.products.filter { $0.isActive && $0.ingredientTags.contains(where: { $0.isExfoliant }) }
        let exfoliantUsageCount = recentLogs.filter { log in
            let exfoliantIDs = exfoliantProducts.map { $0.id }
            return log.productIDs.contains(where: { exfoliantIDs.contains($0) })
        }.count

        if exfoliantUsageCount > 6 {
            recommendations.append(SkinRecommendation(
                title: "Reduce exfoliation frequency",
                body: "Exfoliating acids have been used frequently over the past two weeks. Giving your skin more recovery time between active nights may help.",
                action: "Skip actives tonight",
                category: .routine,
                priority: .medium,
                confidence: .medium,
                zones: [.leftCheek, .rightCheek, .forehead],
                durationDays: 7,
                createdAt: .now
            ))
        }

        // Retinoid + exfoliant same night
        let retinolProducts = context.products.filter { $0.isActive && $0.ingredientTags.contains(.retinol) }
        let recentRetinolAndExfoliant = recentLogs.filter { log in
            let retinolIDs = retinolProducts.map { $0.id }
            let exfoliantIDs = exfoliantProducts.map { $0.id }
            let hasRetinol = log.productIDs.contains(where: { retinolIDs.contains($0) })
            let hasExfoliant = log.productIDs.contains(where: { exfoliantIDs.contains($0) })
            return hasRetinol && hasExfoliant
        }.count

        if recentRetinolAndExfoliant > 0 {
            recommendations.append(SkinRecommendation(
                title: "Avoid retinoid and exfoliant on the same night",
                body: "Using retinoids and exfoliating acids together may increase irritation risk. Consider alternating them on different nights.",
                action: "Alternate actives",
                category: .routine,
                priority: .high,
                confidence: .medium,
                zones: [.leftCheek, .rightCheek, .forehead],
                durationDays: 14,
                createdAt: .now
            ))
        }

        // Dryness worsening + frequent actives
        let hasWorseningDryness = trends.values.flatMap { $0 }.contains { $0.metric == .dryness && $0.direction == .worsening }
        let frequentActives = exfoliantUsageCount > 3 || recentRetinolAndExfoliant > 0
        if hasWorseningDryness && frequentActives {
            recommendations.append(SkinRecommendation(
                title: "Focus on barrier support",
                body: "Dryness looks more pronounced and actives have been frequent. This week, prioritise moisturiser and reduce strong actives to give your barrier time to recover.",
                action: "Simplify routine",
                category: .routine,
                priority: .high,
                confidence: .medium,
                zones: [.leftCheek, .rightCheek, .forehead],
                durationDays: 7,
                createdAt: .now
            ))
        }

        // Low adherence
        if adherenceRate < 0.6 && !context.routineLogs.isEmpty {
            recommendations.append(SkinRecommendation(
                title: "Build routine consistency",
                body: "Routine adherence has been below 60% this week. A simple routine done regularly helps skin stay balanced more than a complex one done occasionally.",
                action: "Simplify routine",
                category: .routine,
                priority: .medium,
                confidence: .high,
                zones: ZoneType.allCases,
                durationDays: 7,
                createdAt: .now
            ))
        }

        // High adherence + improving
        let hasImprovingTrend = trends.values.flatMap { $0 }.contains { $0.direction == .improving }
        if adherenceRate >= 0.8 && hasImprovingTrend {
            recommendations.append(SkinRecommendation(
                title: "Great consistency — keep it up",
                body: "Your routine has been consistent and your skin is responding well. Staying on track is the best thing you can do right now.",
                action: nil,
                category: .progress,
                priority: .low,
                confidence: .high,
                zones: ZoneType.allCases,
                durationDays: nil,
                createdAt: .now
            ))
        }

        return recommendations
    }
}
