import SwiftUI

struct BaselineScanView: View {
    @State private var isScanning = false
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: CleraSpacing.lg) {
            Spacer()

            CleraSectionHeader(
                eyebrow: "\(CleraCopy.Onboarding.stepPrefix) 2 of 4",
                title: CleraCopy.Onboarding.baselineScanTitle,
                subtitle: CleraCopy.Onboarding.baselineScanBody
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, CleraSpacing.lg)

            ZStack {
                RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                    .fill(CleraColor.surface)
                    .frame(height: 380)
                    .overlay(
                        RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                            .stroke(CleraColor.border, lineWidth: 1)
                    )

                if isScanning {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(CleraColor.accent)
                        Text(CleraCopy.Onboarding.analyzing)
                            .font(.system(size: 14))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                } else {
                    VStack(spacing: CleraSpacing.md) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 64))
                            .foregroundStyle(CleraColor.accent)
                        Text(CleraCopy.Onboarding.tapToCapture)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                }
            }
            .padding(.horizontal, CleraSpacing.lg)
            .onTapGesture {
                guard !isScanning else { return }
                isScanning = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    onComplete()
                }
            }

            Spacer()
        }
        .background(CleraColor.background)
    }
}
