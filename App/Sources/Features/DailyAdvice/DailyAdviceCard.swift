import SwiftUI

struct DailyAdviceCard: View {
    let advice: DailySkinAdviceResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            CleraCard {
                VStack(alignment: .leading, spacing: CleraSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Skin Risk Today")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(CleraColor.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.8)
                            HStack(spacing: 6) {
                                Image(systemName: advice.riskLevel.sfSymbol)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(riskColor(advice.riskLevel))
                                Text(advice.riskLevel.displayName)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(riskColor(advice.riskLevel))
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            if let weather = advice.weatherSnapshot {
                                HStack(spacing: 4) {
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(CleraColor.accent)
                                    Text("UV \(Int(weather.uvIndex))")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(CleraColor.textSecondary)
                                }
                                HStack(spacing: 4) {
                                    Image(systemName: "thermometer")
                                        .font(.system(size: 10))
                                        .foregroundStyle(CleraColor.accent)
                                    Text("\(Int(weather.temperatureCelsius))°")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(CleraColor.textSecondary)
                                }
                            }
                            Text(advice.timeOfDay.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CleraColor.accent)
                        }
                    }

                    Text(advice.primaryAdvice)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)
                        .lineLimit(2)

                    Text(advice.secondaryAdvice)
                        .font(.system(size: 13))
                        .foregroundStyle(CleraColor.textSecondary)
                        .lineLimit(2)

                    if !advice.recommendedActions.isEmpty {
                        HStack(spacing: CleraSpacing.md) {
                            ForEach(advice.recommendedActions.prefix(2)) { action in
                                HStack(spacing: 4) {
                                    Image(systemName: action.icon)
                                        .font(.system(size: 12))
                                        .foregroundStyle(action.priority == .essential ? riskColor(.high) : CleraColor.accent)
                                    Text(action.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(CleraColor.textPrimary)
                                }
                            }
                        }
                    }

                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func riskColor(_ level: SkinRiskLevel) -> Color {
        switch level {
        case .low: Color(hex: 0x99A744)
        case .moderate: Color(hex: 0xD4A017)
        case .high: Color(hex: 0xC75B39)
        case .extreme: Color(hex: 0x8B3A3A)
        }
    }
}
