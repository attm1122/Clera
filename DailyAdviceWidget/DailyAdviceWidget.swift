import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct DailyAdviceEntry: TimelineEntry {
    let date: Date
    let payload: DailyAdviceWidgetPayload?
}

// MARK: - Provider

struct DailyAdviceProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyAdviceEntry {
        DailyAdviceEntry(date: .now, payload: placeholderPayload)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyAdviceEntry) -> Void) {
        let payload = DailyAdviceWidgetStore.read()
        let entry = DailyAdviceEntry(date: .now, payload: payload)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyAdviceEntry>) -> Void) {
        let payload = DailyAdviceWidgetStore.read()
        let entry = DailyAdviceEntry(date: .now, payload: payload)

        let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextHour))
        completion(timeline)
    }

    private var placeholderPayload: DailyAdviceWidgetPayload {
        let result = DailySkinAdviceResult(
            id: UUID(),
            generatedAt: .now,
            timeOfDay: .morning,
            riskLevel: .moderate,
            riskScore: 35,
            primaryAdvice: "UV is moderate today — apply SPF 30 before heading out.",
            secondaryAdvice: "Reapply around midday if you are outdoors.",
            recommendedActions: [
                SkinAdviceAction(
                    title: "Apply SPF",
                    detail: "Use SPF 30+ this morning",
                    icon: "sun.max.fill",
                    priority: .essential,
                    timeContext: .morning
                ),
                SkinAdviceAction(
                    title: "Stay hydrated",
                    detail: "Drink water throughout the day",
                    icon: "drop.fill",
                    priority: .recommended,
                    timeContext: .morning
                )
            ],
            affectedZones: [.forehead, .nose, .leftCheek, .rightCheek, .chinJaw],
            confidence: .moderate,
            dataSourcesUsed: ["Weather data", "Skin profile"],
            weatherSnapshot: DailyWeatherSnapshot(
                uvIndex: 5.0,
                temperatureCelsius: 22,
                humidityPercent: 50,
                windSpeedKmh: 10,
                condition: .clear
            ),
            airQualitySnapshot: AirQualitySnapshot(aqi: 45, pm25: nil, dominantPollutant: nil),
            environmentFactors: [],
            scanContext: nil,
            routineContext: nil
        )
        return DailyAdviceWidgetPayload(version: 1, generatedAt: .now, result: result, history: [])
    }
}

// MARK: - Widget Configuration

struct DailyAdviceWidget: Widget {
    let kind: String = "com.attm.clera.DailyAdviceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyAdviceProvider()) { entry in
            DailyAdviceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Skin Advice")
        .description("Personalised skin guidance based on weather, UV, and your skin profile.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
