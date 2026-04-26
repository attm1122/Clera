import SwiftUI

/// A soft confidence indicator shown per scan in the timeline.
struct TimelineConfidenceBar: View {
    let confidence: Double // 0.0 ... 1.0
    let consistency: ScanConsistency?

    var body: some View {
        HStack(spacing: 6) {
            confidenceDots

            Text(confidenceLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(confidenceColor)

            if let consistency = consistency, !consistency.isAcceptable {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: 0xD4A017))
            }
        }
    }

    private var confidenceDots: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(dotFilled(at: index) ? confidenceColor : CleraColor.border)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func dotFilled(at index: Int) -> Bool {
        let filledCount: Int
        switch confidenceLevel {
        case .high: filledCount = 3
        case .moderate: filledCount = 2
        case .low: filledCount = 1
        }
        return index < filledCount
    }

    private var confidenceLevel: InsightConfidence {
        if confidence >= 0.7 { return .high }
        if confidence >= 0.5 { return .moderate }
        return .low
    }

    private var confidenceLabel: String {
        switch confidenceLevel {
        case .high: return CleraCopy.Timeline.confidenceHigh
        case .moderate: return CleraCopy.Timeline.confidenceModerate
        case .low: return CleraCopy.Timeline.confidenceLow
        }
    }

    private var confidenceColor: Color {
        switch confidenceLevel {
        case .high: return CleraColor.success
        case .moderate: return CleraColor.accent
        case .low: return CleraColor.textSecondary
        }
    }
}
