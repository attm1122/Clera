import WidgetKit
import SwiftUI

// MARK: - Widget Colors

private enum WidgetColor {
    static let background = Color(hex: 0xF4F2EC)
    static let surface = Color.white
    static let textPrimary = Color(hex: 0x1C1917)
    static let textSecondary = Color(hex: 0x635F5A)
    static let accent = Color(hex: 0x996C48)
    static let success = Color(hex: 0x99A744)
    static let border = Color(hex: 0xD4D0C8)
    static let lowRisk = Color(hex: 0x99A744)
    static let moderateRisk = Color(hex: 0xD4A017)
    static let highRisk = Color(hex: 0xC75B39)
    static let extremeRisk = Color(hex: 0x8B3A3A)
}

// MARK: - Entry View

struct DailyAdviceWidgetEntryView: View {
    var entry: DailyAdviceProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: DailyAdviceProvider.Entry

    var body: some View {
        if let result = entry.payload?.result {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: result.riskLevel.sfSymbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(riskColor(result.riskLevel))
                    Text(result.riskLevel.displayName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(riskColor(result.riskLevel))
                    Spacer()
                }

                Text(result.primaryAdvice)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WidgetColor.textPrimary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Image(systemName: timeIcon(result.timeOfDay))
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetColor.accent)
                    Text(result.timeOfDay.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(WidgetColor.textSecondary)
                    Spacer()
                    Text("Clera")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetColor.accent.opacity(0.7))
                }
            }
            .padding(12)
            .background(WidgetColor.background)
            .widgetURL(URL(string: "clera://daily-advice"))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(WidgetColor.accent)
                    Text("Skin Advice")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WidgetColor.textPrimary)
                    Spacer()
                }

                Text("Open Clera to refresh today's skin advice.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WidgetColor.textSecondary)
                    .lineLimit(4)

                Spacer(minLength: 0)

                Text("Clera")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetColor.accent.opacity(0.7))
            }
            .padding(12)
            .background(WidgetColor.background)
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: DailyAdviceProvider.Entry

    var body: some View {
        if let result = entry.payload?.result {
            HStack(spacing: 12) {
                // Left: Risk + Weather
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: result.riskLevel.sfSymbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(riskColor(result.riskLevel))
                        Text(result.riskLevel.displayName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(riskColor(result.riskLevel))
                    }

                    if let weather = result.weatherSnapshot {
                        HStack(spacing: 8) {
                            weatherBadge(
                                icon: "sun.max.fill",
                                value: "\(Int(weather.uvIndex))"
                            )
                            weatherBadge(
                                icon: "thermometer",
                                value: "\(Int(weather.temperatureCelsius))°"
                            )
                            weatherBadge(
                                icon: "drop.fill",
                                value: "\(Int(weather.humidityPercent))%"
                            )
                        }
                    }

                    Text(result.primaryAdvice)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WidgetColor.textPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: Actions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetColor.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    ForEach(result.recommendedActions.prefix(2)) { action in
                        HStack(spacing: 6) {
                            Image(systemName: action.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(action.priority == .essential ? WidgetColor.highRisk : WidgetColor.accent)
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(action.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(WidgetColor.textPrimary)
                                    .lineLimit(1)
                                Text(action.detail)
                                    .font(.system(size: 10))
                                    .foregroundStyle(WidgetColor.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(WidgetColor.background)
            .widgetURL(URL(string: "clera://daily-advice"))
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Skin Advice")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WidgetColor.textPrimary)
                    Text("Open Clera to refresh today's personalised guidance.")
                        .font(.system(size: 12))
                        .foregroundStyle(WidgetColor.textSecondary)
                        .lineLimit(3)
                    Spacer(minLength: 0)
                    Text("Clera")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetColor.accent.opacity(0.7))
                }
                Spacer()
            }
            .padding(12)
            .background(WidgetColor.background)
            .widgetURL(URL(string: "clera://daily-advice"))
        }
    }

    private func weatherBadge(icon: String, value: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(WidgetColor.accent)
            Text(value)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(WidgetColor.textSecondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(WidgetColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: DailyAdviceProvider.Entry

    var body: some View {
        if let result = entry.payload?.result {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Skin Risk Today")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(WidgetColor.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                        HStack(spacing: 6) {
                            Image(systemName: result.riskLevel.sfSymbol)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(riskColor(result.riskLevel))
                            Text(result.riskLevel.displayName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(riskColor(result.riskLevel))
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if let weather = result.weatherSnapshot {
                            HStack(spacing: 6) {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(WidgetColor.accent)
                                Text("UV \(Int(weather.uvIndex))")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(WidgetColor.textSecondary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "thermometer")
                                    .font(.system(size: 10))
                                    .foregroundStyle(WidgetColor.accent)
                                Text("\(Int(weather.temperatureCelsius))°C")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(WidgetColor.textSecondary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(WidgetColor.accent)
                                Text("\(Int(weather.humidityPercent))%")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(WidgetColor.textSecondary)
                            }
                        }
                    }
                }

                // Advice
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.primaryAdvice)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WidgetColor.textPrimary)
                        .lineLimit(2)
                    Text(result.secondaryAdvice)
                        .font(.system(size: 12))
                        .foregroundStyle(WidgetColor.textSecondary)
                        .lineLimit(2)
                }

                Divider()
                    .background(WidgetColor.border)

                // Affected Zones
                if !result.affectedZones.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Affected Areas")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WidgetColor.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(result.affectedZones.prefix(5), id: \.self) { zone in
                                Text(zone.displayName)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(WidgetColor.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(WidgetColor.accent.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Divider()
                    .background(WidgetColor.border)

                // 7-Day Risk Trend
                let history = entry.payload?.history ?? []
                if history.count >= 2 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("7-Day Risk")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WidgetColor.textSecondary)
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(history.reversed().prefix(7).enumerated().map { $0 }, id: \.offset) { index, item in
                                VStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(riskColor(item.riskLevel).opacity(0.8))
                                        .frame(width: 12, height: max(4, CGFloat(item.riskScore) / 100.0 * 32))
                                    Text(dayLabel(for: item.generatedAt, index: index, total: min(history.count, 7)))
                                        .font(.system(size: 8))
                                        .foregroundStyle(WidgetColor.textSecondary)
                                }
                            }
                        }
                    }
                }

                Divider()
                    .background(WidgetColor.border)

                // Time-aware advice
                VStack(alignment: .leading, spacing: 8) {
                    timeRow(
                        icon: "sunrise.fill",
                        label: "Morning",
                        advice: morningAdvice(from: result)
                    )
                    timeRow(
                        icon: "sun.max.fill",
                        label: "Midday",
                        advice: middayAdvice(from: result)
                    )
                    timeRow(
                        icon: "sunset.fill",
                        label: "Evening",
                        advice: eveningAdvice(from: result)
                    )
                }

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Text("Clera")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetColor.accent.opacity(0.7))
                }
            }
            .padding(16)
            .background(WidgetColor.background)
            .widgetURL(URL(string: "clera://daily-advice"))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily Skin Advice")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(WidgetColor.textPrimary)
                Text("Open Clera to refresh today's personalised skin guidance based on weather, UV, and your skin profile.")
                    .font(.system(size: 13))
                    .foregroundStyle(WidgetColor.textSecondary)
                    .lineLimit(4)
                Spacer(minLength: 0)
                HStack {
                    Spacer()
                    Text("Clera")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetColor.accent.opacity(0.7))
                }
            }
            .padding(16)
            .background(WidgetColor.background)
            .widgetURL(URL(string: "clera://daily-advice"))
        }
    }

    private func timeRow(icon: String, label: String, advice: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(WidgetColor.accent)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetColor.textSecondary)
                Text(advice)
                    .font(.system(size: 12))
                    .foregroundStyle(WidgetColor.textPrimary)
                    .lineLimit(2)
            }
        }
    }

    private func dayLabel(for date: Date, index: Int, total: Int) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Y" }
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }

    private func morningAdvice(from result: DailySkinAdviceResult) -> String {
        if result.riskLevel == .low {
            return "Apply SPF and follow your usual morning routine."
        }
        if result.riskScore > 50 {
            return "High risk today — use SPF 50+, layer moisturiser, and avoid new products."
        }
        let action = result.recommendedActions.first { $0.timeContext == .morning }
        return action?.detail ?? "Apply SPF and prepare your skin for the day."
    }

    private func middayAdvice(from result: DailySkinAdviceResult) -> String {
        if result.weatherSnapshot?.uvIndex ?? 0 > 5 {
            return "Reapply SPF if you have been outside or sweating."
        }
        return "Stay hydrated and avoid touching your face."
    }

    private func eveningAdvice(from result: DailySkinAdviceResult) -> String {
        if result.scanContext?.hasRecentIrritation == true {
            return "Focus on soothing and barrier repair tonight."
        }
        if result.environmentFactors.contains(where: { $0.kind == .airQuality && $0.severity.rawValue >= FactorSeverity.moderate.rawValue }) {
            return "Cleanse thoroughly to remove pollution particles."
        }
        return "Support recovery with your evening routine."
    }
}

// MARK: - Helpers

private func riskColor(_ level: SkinRiskLevel) -> Color {
    switch level {
    case .low: WidgetColor.lowRisk
    case .moderate: WidgetColor.moderateRisk
    case .high: WidgetColor.highRisk
    case .extreme: WidgetColor.extremeRisk
    }
}

private func timeIcon(_ timeOfDay: TimeOfDay) -> String {
    switch timeOfDay {
    case .morning: "sunrise.fill"
    case .midday: "sun.max.fill"
    case .evening: "sunset.fill"
    case .night: "moon.fill"
    }
}

// MARK: - Color Extension

private extension Color {
    init(hex: UInt64, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, opacity: alpha)
    }
}
