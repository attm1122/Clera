@preconcurrency import AVFoundation
import CoreMedia
import SwiftUI

/// Thread-safe box for storing a checked continuation across actor boundaries.
/// AVCapturePhotoCaptureDelegate methods are called on an arbitrary queue,
/// so the continuation must be accessible from `nonisolated` context.
private final class ContinuationBox: @unchecked Sendable {
    var value: CheckedContinuation<UIImage, Error>?
}

@MainActor
@Observable
final class CameraManager: NSObject {
    enum Status: Equatable {
        case configuring
        case ready
        case unauthorized
        case failed(CameraError)
    }

    private(set) var status: Status = .configuring
    nonisolated let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var videoDataOutput: AVCaptureVideoDataOutput?

    /// Use a thread-safe box for the continuation so `nonisolated` delegate
    /// callbacks can resume it without crossing actor isolation boundaries.
    private let continuationBox = ContinuationBox()

    /// Real-time scan analysis engine.
    let scanEngine = ScanEngine()

    override init() {
        super.init()
    }

    nonisolated func configure() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor [weak self] in
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.status = .unauthorized
                    }
                }
            }
        case .authorized:
            Task { @MainActor in
                self.setupSession()
            }
        case .denied, .restricted:
            Task { @MainActor in
                self.status = .unauthorized
            }
        @unknown default:
            Task { @MainActor in
                self.status = .unauthorized
            }
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo

        do {
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(for: .video)
            guard let device else {
                status = .failed(CameraError.noDevice)
                return
            }

            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                videoDeviceInput = input
            }

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                if #available(iOS 16.0, *) {
                    photoOutput.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
                } else {
                    photoOutput.isHighResolutionCaptureEnabled = true
                }
            }

            // Add video data output for real-time frame analysis
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "clera.video", qos: .userInitiated))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
                videoDataOutput = videoOutput
            }

            status = .ready
        } catch {
            status = .failed(CameraError.captureSetup(error))
        }
    }

    nonisolated func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
        }
    }

    nonisolated func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.stopRunning()
        }
    }

    func capturePhoto() async throws -> UIImage {
        guard status == .ready else {
            throw CameraError.notReady
        }
        return try await withCheckedThrowingContinuation { continuation in
            continuationBox.value = continuation
            let settings = AVCapturePhotoSettings()
            if #available(iOS 16.0, *) {
                settings.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
            } else {
                settings.isHighResolutionPhotoEnabled = true
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    enum CameraError: Error, Equatable, LocalizedError {
        case noDevice
        case notReady
        case captureSetup(Error)

        static func == (lhs: CameraError, rhs: CameraError) -> Bool {
            switch (lhs, rhs) {
            case (.noDevice, .noDevice), (.notReady, .notReady):
                return true
            case (.captureSetup, .captureSetup):
                return true
            default:
                return false
            }
        }

        var errorDescription: String? {
            switch self {
            case .noDevice: "No camera device found."
            case .notReady: "Camera is not ready."
            case .captureSetup(let error): "Setup failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Photo Capture Delegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            continuationBox.value?.resume(throwing: error)
            continuationBox.value = nil
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            continuationBox.value?.resume(throwing: CameraError.notReady)
            continuationBox.value = nil
            return
        }
        continuationBox.value?.resume(returning: image)
        continuationBox.value = nil
    }
}

// MARK: - Video Frame Delegate for Scan Engine

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // CVPixelBuffer is not Sendable, but it is reference-counted and thread-safe
        // for read-only access. We pass it to the MainActor task via an unchecked box.
        let box = PixelBufferBox(pixelBuffer: pixelBuffer)
        Task { @MainActor in
            await scanEngine.analyze(box.pixelBuffer)
        }
    }
}

// MARK: - Preview View

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Sendable Box for CVPixelBuffer

/// Unchecked Sendable wrapper for CVPixelBuffer.
/// CVPixelBuffer is reference-counted and safe for read-only cross-thread access.
private final class PixelBufferBox: @unchecked Sendable {
    let pixelBuffer: CVPixelBuffer
    init(pixelBuffer: CVPixelBuffer) {
        self.pixelBuffer = pixelBuffer
    }
}
