import Foundation

/// Lightweight analytics event logger for the Skin Session pipeline.
/// Events are stored in-memory and can be forwarded to analytics backends.
final class AnalyticsLogger: @unchecked Sendable {
    static let shared = AnalyticsLogger()
    
    private(set) var events: [AnalyticsLogEntry] = []
    
    func log(_ event: AnalyticsEvent, metadata: [String: String] = [:]) {
        let entry = AnalyticsLogEntry(
            event: event,
            timestamp: .now,
            metadata: metadata
        )
        events.append(entry)
        #if DEBUG
        print("[Analytics] \(event.rawValue) \(metadata)")
        #endif
    }
    
    func clear() {
        events.removeAll()
    }
}

struct AnalyticsLogEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var event: AnalyticsEvent
    var timestamp: Date
    var metadata: [String: String]
}
