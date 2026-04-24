import SwiftUI

struct CaptureFlowView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let kind: CheckInSessionKind

    @State private var currentIndex = 0
    @State private var capturedAngles: [CaptureAngle] = []
    @State private var note = ""
    @State private var isReviewing = false

    private var currentAngle: CaptureAngle {
        CaptureAngle.allCases[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    CleraSectionHeader(
                        eyebrow: kind.rawValue,
                        title: isReviewing ? "Review your capture" : currentAngle.title,
                        subtitle: isReviewing ? "A calm review step before the session lands in your timeline." : currentAngle.guidance
                    )

                    if isReviewing {
                        reviewContent
                    } else {
                        captureContent
                    }
                }
                .padding(CleraSpacing.lg)
            }
            .background(CleraColor.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(CleraColor.textSecondary)
                }
            }
        }
    }

    private var captureContent: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.lg) {
            CleraCard {
                VStack(spacing: CleraSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [CleraColor.surface, CleraColor.accentSoft.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 380)

                        RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 10]))
                            .foregroundStyle(CleraColor.border)
                            .frame(width: 210, height: 280)

                        VStack(spacing: 10) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 42, weight: .light))
                            Text(currentAngle.title)
                                .font(.system(size: 19, weight: .semibold))
                            Text("Guided camera integration comes next. This scaffold already captures the flow and persists completed sessions.")
                                .font(.system(size: 14))
                                .foregroundStyle(CleraColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 240)
                        }
                        .foregroundStyle(CleraColor.textPrimary)
                    }

                    angleProgress
                }
            }

            CleraCard {
                VStack(alignment: .leading, spacing: CleraSpacing.md) {
                    Text("Capture guidance")
                        .font(.system(size: 18, weight: .semibold))
                    guidanceRow("Eye-level framing")
                    guidanceRow("Steady posture")
                    guidanceRow("Soft, even light")
                }
            }

            Button(capturedAngles.count == CaptureAngle.allCases.count - 1 ? "Capture and review" : "Capture \(currentAngle.title.lowercased())") {
                captureCurrentAngle()
            }
            .buttonStyle(CleraPrimaryButtonStyle())
        }
    }

    private var reviewContent: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.lg) {
            CleraCard {
                VStack(alignment: .leading, spacing: CleraSpacing.md) {
                    Text("Three-angle set")
                        .font(.system(size: 18, weight: .semibold))

                    ForEach(CaptureAngle.allCases) { angle in
                        HStack(spacing: CleraSpacing.md) {
                            RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                                .fill(CleraColor.surface)
                                .frame(width: 74, height: 92)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "face.smiling")
                                        Text(angle.title)
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundStyle(CleraColor.textSecondary)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(angle.title)
                                    .font(.system(size: 15, weight: .semibold))
                                Text(statusText(for: angle))
                                    .font(.system(size: 14))
                                    .foregroundStyle(CleraColor.textSecondary)
                            }

                            Spacer()

                            Button("Retake") {
                                retake(angle: angle)
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(CleraColor.accent)
                        }
                    }
                }
            }

            CleraCard {
                VStack(alignment: .leading, spacing: CleraSpacing.md) {
                    Text("Optional note")
                        .font(.system(size: 18, weight: .semibold))
                    TextField("What changed since last time?", text: $note, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(CleraSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                                .fill(CleraColor.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                                .stroke(CleraColor.border, lineWidth: 1)
                        )
                }
            }

            Button(kind == .baseline ? "Save baseline" : "Save check-in") {
                appModel.recordSession(kind: kind, note: note)
                dismiss()
            }
            .buttonStyle(CleraPrimaryButtonStyle())
        }
    }

    private var angleProgress: some View {
        HStack(spacing: 10) {
            ForEach(CaptureAngle.allCases) { angle in
                HStack(spacing: 6) {
                    Circle()
                        .fill(capturedAngles.contains(angle) ? CleraColor.accent : CleraColor.border)
                        .frame(width: 8, height: 8)
                    Text(angle.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(capturedAngles.contains(angle) ? CleraColor.textPrimary : CleraColor.textSecondary)
                }
            }
        }
    }

    private func captureCurrentAngle() {
        guard !capturedAngles.contains(currentAngle) else { return }
        capturedAngles.append(currentAngle)
        if currentIndex == CaptureAngle.allCases.count - 1 {
            isReviewing = true
        } else {
            currentIndex += 1
        }
    }

    private func retake(angle: CaptureAngle) {
        capturedAngles.removeAll(where: { $0 == angle })
        currentIndex = CaptureAngle.allCases.firstIndex(of: angle) ?? 0
        isReviewing = false
    }

    private func statusText(for angle: CaptureAngle) -> String {
        capturedAngles.contains(angle) ? "Captured with consistent framing" : "Still needed"
    }

    private func guidanceRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(CleraColor.accent)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(CleraColor.textSecondary)
        }
    }
}
