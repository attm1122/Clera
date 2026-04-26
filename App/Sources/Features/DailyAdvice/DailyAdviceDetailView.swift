import SwiftUI

struct DailyAdviceDetailView: View {
    let advice: DailySkinAdviceResult
    let onScanTapped: () -> Void
    let onRoutineTapped: () -> Void
    let onProfileTapped: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                headerSection
                riskScoreSection
                adviceSection
                actionsSection
                if !advice.environmentFactors.isEmpty {
                    factorsSection
                }
                dataSourcesSection
                ctaSection
                Spacer(minLength: CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Daily Skin Advice")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(CleraColor.textPrimary)
            Text(advice.generatedAt.formatted(date: .long, time: .shortened))
                .font(.system(size: 15))
                .foregroundStyle(CleraColor.textSecondary)
        }
        .padding(.top, CleraSpacing.xl)
    }

    // MARK: - Risk Score

    private var riskScoreSection: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Risk Level")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CleraColor.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                        HStack(spacing: 8) {
                            Image(systemName: advice.riskLevel.sfSymbol)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(riskColor(advice.riskLevel))
                            Text(advice.riskLevel.displayName)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(riskColor(advice.riskLevel))
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(advice.riskScore)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(riskColor(advice.riskLevel))
                        Text("/ 100")
                            .font(.system(size: 14))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                }

                RiskScoreBar(score: advice.riskScore, level: advice.riskLevel)

                Text(advice.timeOfDay.adviceContext)
                    .font(.system(size: 13))
                    .foregroundStyle(CleraColor.textSecondary)
            }
        }
    }

    // MARK: - Advice

    private var adviceSection: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                Text("Today's Guidance")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CleraColor.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(advice.primaryAdvice)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)

                Text(advice.secondaryAdvice)
                    .font(.system(size: 15))
                    .foregroundStyle(CleraColor.textSecondary)

                if !advice.affectedZones.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(advice.affectedZones.prefix(5), id: \.self) { zone in
                            Text(zone.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(CleraColor.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(CleraColor.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 11))
                        .foregroundStyle(CleraColor.textSecondary)
                    Text("Confidence: \(advice.confidence.displayName)")
                        .font(.system(size: 12))
                        .foregroundStyle(CleraColor.textSecondary)
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text("Recommended Actions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            ForEach(advice.recommendedActions) { action in
                CleraCard {
                    HStack(spacing: CleraSpacing.md) {
                        Image(systemName: action.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(action.priority == .essential ? riskColor(.high) : CleraColor.accent)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(action.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(CleraColor.textPrimary)
                                PriorityBadge(priority: action.priority)
                            }
                            Text(action.detail)
                                .font(.system(size: 13))
                                .foregroundStyle(CleraColor.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Factors

    private var factorsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text("Environmental Factors")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            ForEach(advice.environmentFactors) { factor in
                CleraCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: factorIcon(factor.kind))
                                .font(.system(size: 14))
                                .foregroundStyle(CleraColor.accent)
                            Text(factor.kind.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)
                            Spacer()
                            SeverityBadge(severity: factor.severity)
                        }

                        Text(factor.description)
                            .font(.system(size: 13))
                            .foregroundStyle(CleraColor.textSecondary)

                        Text(factor.recommendation)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CleraColor.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Data Sources

    private var dataSourcesSection: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                Text("How This Was Calculated")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CleraColor.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(advice.dataSourcesUsed, id: \.self) { source in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(CleraColor.success)
                            Text(source)
                                .font(.system(size: 13))
                                .foregroundStyle(CleraColor.textPrimary)
                        }
                    }
                }

                if let scan = advice.scanContext {
                    HStack(spacing: 8) {
                        Image(systemName: scan.daysSinceLastScan <= 3 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(scan.daysSinceLastScan <= 3 ? CleraColor.success : Color(hex: 0xD4A017))
                        Text(scan.daysSinceLastScan <= 3 ? "Recent scan data available" : "No recent scan — advice based on profile only")
                            .font(.system(size: 13))
                            .foregroundStyle(CleraColor.textPrimary)
                    }
                }

                if let routine = advice.routineContext {
                    HStack(spacing: 8) {
                        Image(systemName: routine.adherenceThisWeek >= 0.5 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(routine.adherenceThisWeek >= 0.5 ? CleraColor.success : Color(hex: 0xD4A017))
                        Text("Routine adherence: \(Int(routine.adherenceThisWeek * 100))% this week")
                            .font(.system(size: 13))
                            .foregroundStyle(CleraColor.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - CTAs

    private var ctaSection: some View {
        VStack(spacing: CleraSpacing.md) {
            Button("Scan Your Skin") {
                onScanTapped()
            }
            .buttonStyle(CleraPrimaryButtonStyle())

            Button("Log Routine") {
                onRoutineTapped()
            }
            .buttonStyle(CleraSecondaryButtonStyle())

            Button("Update Skin Profile") {
                onProfileTapped()
            }
            .buttonStyle(CleraSecondaryButtonStyle())
        }
    }

    // MARK: - Helpers

    private func riskColor(_ level: SkinRiskLevel) -> Color {
        switch level {
        case .low: Color(hex: 0x99A744)
        case .moderate: Color(hex: 0xD4A017)
        case .high: Color(hex: 0xC75B39)
        case .extreme: Color(hex: 0x8B3A3A)
        }
    }

    private func factorIcon(_ kind: EnvironmentFactorKind) -> String {
        switch kind {
        case .uv: "sun.max.fill"
        case .humidity: "drop.fill"
        case .temperature: "thermometer"
        case .wind: "wind"
        case .airQuality: "aqi.medium"
        }
    }
}

// MARK: - Subviews

private struct RiskScoreBar: View {
    let score: Int
    let level: SkinRiskLevel

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(hex: 0xE8E6E0))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(barColor)
                    .frame(width: max(4, CGFloat(score) / 100.0 * geo.size.width), height: 8)
            }
        }
        .frame(height: 8)
    }

    private var barColor: Color {
        switch level {
        case .low: Color(hex: 0x99A744)
        case .moderate: Color(hex: 0xD4A017)
        case .high: Color(hex: 0xC75B39)
        case .extreme: Color(hex: 0x8B3A3A)
        }
    }
}

private struct PriorityBadge: View {
    let priority: ActionPriority

    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var priorityColor: Color {
        switch priority {
        case .essential: Color(hex: 0xC75B39)
        case .recommended: Color(hex: 0x996C48)
        case .optional: Color(hex: 0x635F5A)
        }
    }
}

private struct SeverityBadge: View {
    let severity: FactorSeverity

    var body: some View {
        Text(severity.rawValue.capitalized)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severityColor)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var severityColor: Color {
        switch severity {
        case .mild: Color(hex: 0x99A744)
        case .moderate: Color(hex: 0xD4A017)
        case .significant: Color(hex: 0xC75B39)
        case .severe: Color(hex: 0x8B3A3A)
        }
    }
}

private extension EnvironmentFactorKind {
    var displayName: String {
        switch self {
        case .uv: "UV Index"
        case .humidity: "Humidity"
        case .temperature: "Temperature"
        case .wind: "Wind"
        case .airQuality: "Air Quality"
        }
    }
}
