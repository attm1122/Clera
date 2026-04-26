import Foundation

enum DailyAdviceWidgetStore {
    static let appGroupIdentifier = "group.com.attm.clera"
    static let payloadFileName = "daily-advice-widget.json"

    private static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    private static var payloadURL: URL? {
        sharedContainerURL?.appendingPathComponent(payloadFileName)
    }

    static func read() -> DailyAdviceWidgetPayload? {
        guard let url = payloadURL else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(DailyAdviceWidgetPayload.self, from: data)
            let hoursSince = Calendar.current.dateComponents([.hour], from: payload.generatedAt, to: .now).hour ?? 0
            guard hoursSince < 24 else { return nil }
            return payload
        } catch {
            return nil
        }
    }
}
