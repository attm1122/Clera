import Foundation

// MARK: - Safety Rule Engine

enum SafetyRuleEngine {

    static func evaluate(context: SkinContext, trends: [ZoneType: [EngineSkinTrend]], scores: [ZoneSkinScore]) -> SafetyAssessment {
        var reasons: [String] = []
        var level: SafetyLevel = .normal

        // Check for severe metrics across zones
        let allTrends = trends.values.flatMap { $0 }
        let severeRedness = scores.contains { $0.redness >= 80 }
        let severeSensitivity = scores.contains { $0.sensitivity >= 80 }
        let severeBreakouts = scores.contains { $0.breakout >= 80 }
        let worseningRedness = allTrends.contains { $0.metric == .redness && $0.direction == .worsening && $0.severity == .significant }
        let worseningSensitivity = allTrends.contains { $0.metric == .redness && $0.direction == .worsening && $0.severity == .significant }

        // Urgent: severe redness/sensitivity + worsening
        if (severeRedness && worseningRedness) || (severeSensitivity && worseningSensitivity) {
            level = .urgentReview
            reasons.append("Severe redness or sensitivity is worsening significantly.")
        }

        // Recommend professional review: severe metrics without clear improvement
        if severeRedness || severeSensitivity || severeBreakouts {
            if level != .urgentReview {
                level = .recommendProfessionalReview
            }
            if severeRedness { reasons.append("Redness is very pronounced in one or more zones.") }
            if severeSensitivity { reasons.append("Sensitivity is very high in one or more zones.") }
            if severeBreakouts { reasons.append("Breakout activity is very high in one or more zones.") }
        }

        // Check-in reported concerns
        if let checkIn = context.latestCheckIn {
            if checkIn.hadIrritation {
                level = .urgentReview
                reasons.append("You reported irritation in your latest check-in.")
            }
        }

        // Caution: multiple moderate concerns
        let moderateConcernCount = scores.filter {
            ($0.redness > 50 && $0.redness <= 80) ||
            ($0.sensitivity > 50 && $0.sensitivity <= 80) ||
            ($0.breakout > 50 && $0.breakout <= 80)
        }.count
        if moderateConcernCount >= 3 && level == .normal {
            level = .caution
            reasons.append("Multiple zones show moderate concern levels.")
        }

        // Caution: rapid worsening in multiple metrics
        let rapidWorseningCount = allTrends.filter { $0.direction == .worsening && $0.severity == .significant }.count
        if rapidWorseningCount >= 3 && level == .normal {
            level = .caution
            reasons.append("Several metrics are worsening rapidly.")
        }

        // Build message
        let message: String
        switch level {
        case .normal:
            message = "Your skin looks stable. No immediate concerns detected."
        case .caution:
            message = "Some changes are worth monitoring. Consider simplifying your routine and tracking how your skin responds over the next few days."
        case .recommendProfessionalReview:
            message = "One or more metrics are elevated. If these levels persist for more than two weeks, consider speaking with a dermatologist or skincare professional."
        case .urgentReview:
            message = "Signs of significant irritation or discomfort were detected. If symptoms are severe or worsening, consider seeking professional advice promptly."
        }

        return SafetyAssessment(level: level, reasons: reasons, message: message)
    }
}
