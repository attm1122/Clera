import Foundation

// MARK: - Widget Store

enum DailyAdviceWidgetStore {
    static let appGroupIdentifier = "group.com.attm.clera"
    static let payloadFileName = "daily-advice-widget.json"

    private static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("clera-widget-tests")
    }

    static var payloadURL: URL? {
        sharedContainerURL?.appendingPathComponent(payloadFileName)
    }

    // MARK: - Write

    static func write(result: DailySkinAdviceResult?, history: [DailySkinAdviceResult] = []) {
        guard let url = payloadURL else { return }
        let payload = DailyAdviceWidgetPayload(
            version: 1,
            generatedAt: .now,
            result: result,
            history: history
        )
        do {
            let folder = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(payload)
            try data.write(to: url, options: .atomic)
        } catch {
            // Widget will fallback gracefully if write fails
        }
    }

    // MARK: - Read

    static func read() -> DailyAdviceWidgetPayload? {
        guard let url = payloadURL else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(DailyAdviceWidgetPayload.self, from: data)
            // Reject stale data (> 24 hours)
            let hoursSince = Calendar.current.dateComponents([.hour], from: payload.generatedAt, to: .now).hour ?? 0
            guard hoursSince < 24 else { return nil }
            return payload
        } catch {
            return nil
        }
    }

    // MARK: - Clear

    static func clear() {
        guard let url = payloadURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    #if DEBUG
    static func writeForTest(payload: DailyAdviceWidgetPayload) {
        guard let url = payloadURL else { return }
        do {
            let folder = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(payload)
            try data.write(to: url, options: .atomic)
        } catch {}
    }
    #endif
}
