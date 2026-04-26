import SwiftUI

struct OnboardingFlowView: View {
    @Environment(AppModel.self) private var appModel
    @State private var skinProfile = SkinProfile()
    @State private var baselineMap: SkinMap?
    @State private var showScanFlow = false

    var body: some View {
        NavigationStack {
            switch appModel.onboardingStep {
            case .welcome:
                WelcomeStepView {
                    withAnimation(.easeInOut) {
                        appModel.onboardingStep = .skinConsultation
                    }
                }

            case .skinConsultation:
                SkinConsultationView(profile: $skinProfile) {
                    withAnimation(.easeInOut) {
                        appModel.onboardingStep = .baselineScan
                    }
                }

            case .baselineScan:
                BaselineScanView {
                    showScanFlow = true
                }
                .sheet(isPresented: $showScanFlow) {
                    ScanFlowView { photos, skinMap, note, checkIn, scanQuality in
                        baselineMap = skinMap
                        showScanFlow = false
                        withAnimation(.easeInOut) {
                            appModel.onboardingStep = .initialSkinMap
                        }
                    }
                }

            case .initialSkinMap:
                if let map = baselineMap {
                    InitialSkinMapView(skinMap: map) {
                        withAnimation(.easeInOut) {
                            appModel.onboardingStep = .complete
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(CleraColor.accent)
                        Text(CleraCopy.Onboarding.processing)
                            .font(.system(size: 14))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                }

            case .complete:
                BaselineCompleteView {
                    if let map = baselineMap {
                        appModel.completeOnboarding(skinProfile: skinProfile, baselineMap: map)
                    }
                }
            }
        }
    }
}
