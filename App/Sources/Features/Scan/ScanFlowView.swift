import SwiftUI

struct ScanFlowView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let onComplete: (([ScanPhoto], SkinMap, String, SkinMapCheckIn?, ScanQualityMetadata?) -> Void)?

    @State private var cameraManager = CameraManager()
    @State private var currentIndex = 0
    @State private var capturedAngles: [CaptureAngle] = []
    @State private var capturedImages: [CaptureAngle: UIImage] = [:]
    @State private var note = ""
    @State private var isReviewing = false
    @State private var isCheckIn = false
    @State private var isProcessing = false
    @State private var showResults = false
    @State private var cameraError: Error?
    @State private var checkIn: SkinMapCheckIn?

    // Animation state
    @State private var animationStateMachine = ScanAnimationStateMachine()
    @State private var isCapturingWithAnimation = false
    @State private var showZoneAnimation = false
    @State private var zoneAnimationComplete = false

    private var currentAngle: CaptureAngle {
        CaptureAngle.allCases[currentIndex]
    }

    private var latestResult: ScanReadinessResult {
        cameraManager.scanEngine.latestResult
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CleraColor.background.ignoresSafeArea()

                if showResults {
                    ScanResultsView(note: note, onDone: {
                        dismiss()
                    })
                } else if isProcessing {
                    ScanProcessingView()
                } else if isCheckIn {
                    PostScanCheckInView { completedCheckIn in
                        self.checkIn = completedCheckIn
                        proceedToProcessing()
                    } onSkip: {
                        proceedToProcessing()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                            CleraSectionHeader(
                                eyebrow: CleraCopy.ScanFlow.dailyScanTitle,
                                title: isReviewing ? CleraCopy.ScanFlow.reviewTitle : currentAngle.title,
                                subtitle: isReviewing
                                    ? CleraCopy.ScanFlow.reviewBody
                                    : currentAngle.guidance
                            )

                            if isReviewing {
                                reviewContent
                            } else {
                                captureContent
                            }
                        }
                        .padding(CleraSpacing.lg)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(CleraCopy.ScanFlow.close) {
                        cameraManager.stopSession()
                        dismiss()
                    }
                    .foregroundStyle(CleraColor.textSecondary)
                }
            }
        }
        .onAppear {
            cameraManager.configure()
            ScanHapticManager.shared.prepare()
            ScanHapticManager.shared.reset()
        }
        .onChange(of: cameraManager.status) { _, newStatus in
            if case .ready = newStatus {
                cameraManager.startSession()
            }
            if case .failed(let error) = newStatus {
                cameraError = error
            }
        }
        .onChange(of: latestResult) { _, newResult in
            // Feed scan engine results into the animation state machine
            if !isCapturingWithAnimation && !showZoneAnimation {
                animationStateMachine.update(from: newResult)
            }
        }
        .onDisappear {
            cameraManager.stopSession()
            ScanHapticManager.shared.reset()
        }
    }

    // MARK: - Capture Content

    private var captureContent: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.lg) {
            cameraPreviewCard
            guidanceSection
            angleProgress

            captureButton
        }
    }

    // MARK: - Camera Preview Card

    private var cameraPreviewCard: some View {
        CleraCard {
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                    .fill(CleraColor.surface)
                    .frame(height: 420)

                // Live camera feed
                if isCameraReady {
                    CameraPreviewView(session: cameraManager.session)
                        .frame(height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous))
                } else {
                    cameraPlaceholder
                }

                // Face positioning guide overlay
                if isCameraReady && !showZoneAnimation {
                    FacePositioningGuideView(
                        state: animationStateMachine.state,
                        faceBounds: latestResult.faceBounds
                    )
                    .frame(height: 420)
                }

                // Scanning line animation
                if isCapturingWithAnimation {
                    ScanProgressContainer(duration: 2.5) {
                        finishScanAnimationCapture()
                    }
                    .frame(height: 420)
                }

                // Zone detection animation
                if showZoneAnimation {
                    ZoneDetectionAnimationView(
                        currentZone: currentZoneIndex,
                        totalZones: 5,
                        onZoneComplete: advanceZoneAnimation
                    )
                    .frame(height: 420)
                }

                // Camera error overlay
                if let error = cameraError {
                    cameraErrorOverlay(error: error)
                }
            }
        }
    }

    private var cameraPlaceholder: some View {
        VStack(spacing: CleraSpacing.md) {
            if let error = cameraError {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 42))
                    .foregroundStyle(.red)
                Text(CleraCopy.ScanFlow.cameraError)
                    .font(.system(size: 17, weight: .semibold))
                Text(error.localizedDescription)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 240)
            } else {
                ProgressView()
                    .tint(CleraColor.accent)
                Text(CleraCopy.ScanFlow.startingCamera)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            }
        }
    }

    private func cameraErrorOverlay(error: Error) -> some View {
        RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
            .fill(CleraColor.background.opacity(0.85))
            .frame(height: 420)
            .overlay(
                VStack(spacing: CleraSpacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 42))
                        .foregroundStyle(Color(hex: 0xD4A017))
                    Text(CleraCopy.ScanFlow.cameraError)
                        .font(.system(size: 17, weight: .semibold))
                    Text(error.localizedDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(CleraColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 240)
                }
            )
    }

    // MARK: - Guidance Section

    private var guidanceSection: some View {
        VStack(spacing: CleraSpacing.sm) {
            QualityFeedbackOverlay(
                state: animationStateMachine.state,
                result: latestResult
            )

            ScanMiniIndicators(result: latestResult)
                .padding(CleraSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                        .fill(CleraColor.elevatedSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                        .stroke(CleraColor.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Capture Button

    private var captureButton: some View {
        Button(action: beginCaptureWithAnimation) {
            HStack(spacing: 8) {
                Image(systemName: isCapturingWithAnimation ? "viewfinder" : "camera.fill")
                    .symbolEffect(.pulse, options: .repeating, value: isCapturingWithAnimation)
                Text(buttonTitle)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(CleraPrimaryButtonStyle())
        .disabled(!canCapture)
        .opacity(canCapture ? 1 : 0.6)
    }

    private var buttonTitle: String {
        if isCapturingWithAnimation {
            return CleraCopy.ScanGuidance.scanning
        }
        if capturedAngles.count == CaptureAngle.allCases.count - 1 {
            return CleraCopy.ScanFlow.captureAndReview
        }
        return "Capture \(currentAngle.title.lowercased())"
    }

    private var canCapture: Bool {
        if isCapturingWithAnimation || showZoneAnimation { return false }
        return isCameraReady && isScanReady
    }

    // MARK: - Review Content

    private var reviewContent: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.lg) {
            CleraCard {
                VStack(alignment: .leading, spacing: CleraSpacing.md) {
                    Text(CleraCopy.ScanFlow.threeAngleSet)
                        .font(.system(size: 18, weight: .semibold))

                    ForEach(CaptureAngle.allCases) { angle in
                        HStack(spacing: CleraSpacing.md) {
                            if let image = capturedImages[angle] {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 74, height: 92)
                                    .clipShape(RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous))
                            } else {
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
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(angle.title)
                                    .font(.system(size: 15, weight: .semibold))
                                Text(CleraCopy.ScanFlow.capturedWithConsistentFraming)
                                    .font(.system(size: 14))
                                    .foregroundStyle(CleraColor.textSecondary)
                            }

                            Spacer()

                            Button(CleraCopy.ScanFlow.retake) {
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
                    Text(CleraCopy.ScanFlow.optionalNoteLabel)
                        .font(.system(size: 18, weight: .semibold))
                    TextField(CleraCopy.ScanFlow.optionalNotePlaceholder, text: $note, axis: .vertical)
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

            Button(CleraCopy.ScanFlow.continueToCheckIn) {
                isCheckIn = true
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

    // MARK: - Capture & Animation Flow

    private func beginCaptureWithAnimation() {
        guard !capturedAngles.contains(currentAngle), isCameraReady, isScanReady else { return }
        ScanHapticManager.shared.captureButtonPressed()
        isCapturingWithAnimation = true
        animationStateMachine.beginScanning()
    }

    private func finishScanAnimationCapture() {
        Task {
            do {
                let image = try await cameraManager.capturePhoto()
                capturedImages[currentAngle] = image

                // Show zone detection animation
                await MainActor.run {
                    isCapturingWithAnimation = false
                    showZoneAnimation = true
                    animationStateMachine.beginZoneAnalysis(zoneCount: 5)
                }
            } catch {
                await MainActor.run {
                    cameraError = error
                    isCapturingWithAnimation = false
                    animationStateMachine.failScan(guidance: CleraCopy.ScanFailure.scanConfidenceLowMessage)
                }
            }
        }
    }

    @State private var currentZoneIndex: Int = 0

    private func advanceZoneAnimation() {
        if currentZoneIndex < 4 {
            currentZoneIndex += 1
            ScanHapticManager.shared.zoneAdvanceHaptic(zoneIndex: currentZoneIndex)
            // The ZoneDetectionAnimationView will call this again after its animation
        } else {
            // All zones complete
            currentZoneIndex = 0
            showZoneAnimation = false
            capturedAngles.append(currentAngle)

            if currentIndex == CaptureAngle.allCases.count - 1 {
                isReviewing = true
            } else {
                currentIndex += 1
            }

            // Reset animation state for next angle
            animationStateMachine.reset()
        }
    }

    private func retake(angle: CaptureAngle) {
        capturedAngles.removeAll(where: { $0 == angle })
        capturedImages.removeValue(forKey: angle)
        currentIndex = CaptureAngle.allCases.firstIndex(of: angle) ?? 0
        isReviewing = false
        animationStateMachine.reset()
        currentZoneIndex = 0
        isCapturingWithAnimation = false
        showZoneAnimation = false
    }

    // MARK: - Processing

    private func proceedToProcessing() {
        isProcessing = true
        Task {
            let scanId = UUID()

            let photos = capturedAngles.map { angle -> ScanPhoto in
                let fileName = ImageStore.generateFileName(angle: angle, scanId: scanId)
                return ScanPhoto(zone: nil, fileName: fileName)
            }

            let result = cameraManager.scanEngine.latestResult
            let scanQuality = ScanQualityMetadata(
                blurScore: result.blurScore,
                brightnessScore: result.brightnessScore,
                sharpnessScore: result.sharpnessScore,
                overexposed: result.overexposed,
                shadowDetected: result.shadowDetected,
                scanReadiness: String(describing: result.scanReadiness)
            )

            // Save images to disk
            for (angle, image) in capturedImages {
                let fileName = ImageStore.generateFileName(angle: angle, scanId: scanId)
                ImageStore.save(image, fileName: fileName)
            }

            // Run real skin analysis on front image
            let frontImage = capturedImages[.front] ?? capturedImages.values.first
            guard let frontImage else {
                await MainActor.run {
                    isProcessing = false
                    showResults = false
                }
                return
            }

            let analysisResult = await SkinAnalysisPipeline.analyzeForUser(
                userId: appModel.userProfile?.email ?? "anonymous",
                frontImage: frontImage,
                leftImage: capturedImages[.left],
                rightImage: capturedImages[.right]
            )
            let skinMap = analysisResult.toSkinMap(checkIn: checkIn, scanQuality: scanQuality)

            // Create baseline if this is the first scan
            if appModel.sessions.isEmpty {
                let scan = SkinScan(
                    id: scanId,
                    userId: appModel.userProfile?.email ?? "anonymous",
                    images: [],
                    quality: analysisResult.quality,
                    zoneAnalyses: analysisResult.zones,
                    summary: analysisResult.summary
                )
                let baselineManager = BaselineManager()
                _ = baselineManager.createBaseline(from: scan, userId: appModel.userProfile?.email ?? "anonymous")
                appModel.skinBaseline = baselineManager.currentBaseline
            }

            await MainActor.run {
                onComplete?(photos, skinMap, note, checkIn, scanQuality)
                isProcessing = false
                showResults = true
            }
        }
    }

    // MARK: - Readiness

    private var isCameraReady: Bool {
        if case .ready = cameraManager.status { return true }
        return false
    }

    private var isScanReady: Bool {
        let result = cameraManager.scanEngine.latestResult
        return result.faceDetected && result.faceCentered
            && result.scanReadiness != .notReady && result.scanReadiness != .poorQuality
    }
}
