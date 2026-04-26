import SwiftUI

struct ScanProcessingView: View {
    @State private var progress: Double = 0

    var body: some View {
        VStack(spacing: CleraSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(CleraColor.border, lineWidth: 6)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(CleraColor.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 2), value: progress)
                Image(systemName: "viewfinder")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(CleraColor.accent)
            }

            VStack(spacing: CleraSpacing.sm) {
                Text(CleraCopy.Loading.puttingScanTogether)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(CleraColor.textPrimary)
                Text(CleraCopy.Loading.checkingQuality)
                    .font(.system(size: 15))
                    .foregroundStyle(CleraColor.textSecondary)
            }

            Spacer()
        }
        .padding(CleraSpacing.lg)
        .onAppear {
            progress = 1.0
        }
    }
}
