import Foundation
import UIKit

// MARK: - Skin Scan

/// A complete skin scan session with captured images and analysis results.
struct SkinScan: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: String
    let createdAt: Date
    var images: [SkinScanImage]
    var quality: ScanQualityResult
    var landmarkResult: FaceLandmarkResult?
    var zoneAnalyses: [SkinZoneAnalysis]
    var summary: SkinAnalysisSummary
    var baselineComparison: BaselineComparison?
    
    init(
        id: UUID = UUID(),
        userId: String,
        createdAt: Date = .now,
        images: [SkinScanImage] = [],
        quality: ScanQualityResult = ScanQualityResult(),
        landmarkResult: FaceLandmarkResult? = nil,
        zoneAnalyses: [SkinZoneAnalysis] = [],
        summary: SkinAnalysisSummary = SkinAnalysisSummary(),
        baselineComparison: BaselineComparison? = nil
    ) {
        self.id = id
        self.userId = userId
        self.createdAt = createdAt
        self.images = images
        self.quality = quality
        self.landmarkResult = landmarkResult
        self.zoneAnalyses = zoneAnalyses
        self.summary = summary
        self.baselineComparison = baselineComparison
    }
}

// MARK: - Scan Image

/// A single captured image from a scan session.
struct SkinScanImage: Codable, Identifiable, Sendable {
    let id: UUID
    let angle: CaptureAngle
    let fileName: String
    let timestamp: Date
    var qualityScore: Double
    
    init(
        id: UUID = UUID(),
        angle: CaptureAngle,
        fileName: String,
        timestamp: Date = .now,
        qualityScore: Double = 0
    ) {
        self.id = id
        self.angle = angle
        self.fileName = fileName
        self.timestamp = timestamp
        self.qualityScore = qualityScore
    }
}

// MARK: - Scan Quality

/// Quality validation result for a captured scan.
struct ScanQualityResult: Codable, Sendable {
    var accepted: Bool = false
    var lighting: LightingQuality = .unknown
    var blur: BlurLevel = .unknown
    var pose: PoseValidity = .unknown
    var distance: DistanceValidity = .unknown
    var obstruction: ObstructionLevel = .none
    var resolution: ResolutionValidity = .unknown
    var confidence: QualityConfidence = .low
    var issues: [String] = []
    
    enum BlurLevel: String, Codable, Sendable {
        case unknown, low, moderate, high
    }
    
    enum PoseValidity: String, Codable, Sendable {
        case unknown, valid, invalid
    }
    
    enum DistanceValidity: String, Codable, Sendable {
        case unknown, valid, tooClose, tooFar
    }
    
    enum ObstructionLevel: String, Codable, Sendable {
        case none, minor, major
    }
    
    enum ResolutionValidity: String, Codable, Sendable {
        case unknown, valid, tooLow
    }
    
    enum QualityConfidence: String, Codable, Sendable {
        case low, medium, high
    }
}

// MARK: - Face Landmarks

/// Detected face landmarks from a vision provider.
struct FaceLandmarkResult: Codable, Sendable {
    var faceDetected: Bool = false
    var boundingBox: CGRect = .zero
    var landmarks: [FaceLandmark] = []
    var headPose: HeadPose = HeadPose()
    var confidence: Double = 0
    
    struct FaceLandmark: Codable, Sendable {
        let type: LandmarkType
        let points: [CGPoint]
        
        enum LandmarkType: String, Codable, Sendable {
            case faceContour
            case leftEyebrow
            case rightEyebrow
            case leftEye
            case rightEye
            case noseCrest
            case noseTip
            case outerLips
            case innerLips
            case leftPupil
            case rightPupil
            case medianLine
        }
    }
}

// MARK: - Skin Zone

/// A facial zone with its mask and analysis.
struct SkinZoneAnalysis: Codable, Identifiable, Sendable {
    let id: UUID
    let zone: SkinZone
    var metrics: [SkinMetricKey: SkinMetricScore]
    var topInsight: String
    var confidence: ScanQualityResult.QualityConfidence
    var maskPath: [CGPoint]?
    var croppedImageFileName: String?
    
    init(
        id: UUID = UUID(),
        zone: SkinZone,
        metrics: [SkinMetricKey: SkinMetricScore] = [:],
        topInsight: String = "",
        confidence: ScanQualityResult.QualityConfidence = .low,
        maskPath: [CGPoint]? = nil,
        croppedImageFileName: String? = nil
    ) {
        self.id = id
        self.zone = zone
        self.metrics = metrics
        self.topInsight = topInsight
        self.confidence = confidence
        self.maskPath = maskPath
        self.croppedImageFileName = croppedImageFileName
    }
}

/// The five facial zones for MVP analysis.
enum SkinZone: String, Codable, CaseIterable, Sendable {
    case forehead
    case nose
    case leftCheek
    case rightCheek
    case chinJaw
    
    var displayName: String {
        switch self {
        case .forehead: "Forehead"
        case .nose: "Nose"
        case .leftCheek: "Left Cheek"
        case .rightCheek: "Right Cheek"
        case .chinJaw: "Chin / Jaw"
        }
    }
}

// MARK: - Skin Metrics

/// Cosmetic skin metrics tracked per zone.
enum SkinMetricKey: String, Codable, CaseIterable, Sendable {
    case redness
    case pigmentation
    case texture
    case breakoutLikeSpots
    case shine
    case dryness
    case evenness
    
    var displayName: String {
        switch self {
        case .redness: "Redness"
        case .pigmentation: "Pigmentation"
        case .texture: "Texture"
        case .breakoutLikeSpots: "Breakout-like spots"
        case .shine: "Shine"
        case .dryness: "Dryness"
        case .evenness: "Evenness"
        }
    }
}

/// Score for a single skin metric.
struct SkinMetricScore: Codable, Sendable {
    var score: Int        // 0–100
    var confidence: ScanQualityResult.QualityConfidence
    var trend: SkinTrend
    var reason: String
    
    init(
        score: Int = 0,
        confidence: ScanQualityResult.QualityConfidence = .low,
        trend: SkinTrend = .insufficientData,
        reason: String = ""
    ) {
        self.score = max(0, min(100, score))
        self.confidence = confidence
        self.trend = trend
        self.reason = reason
    }
}

// MARK: - Trends

/// Trend direction for a metric compared to baseline.
enum SkinTrend: String, Codable, Sendable {
    case improved
    case stable
    case slightlyIncreased
    case increased
    case slightlyReduced
    case reduced
    case insufficientData
    
    var displayName: String {
        switch self {
        case .improved: "Improved"
        case .stable: "Stable"
        case .slightlyIncreased: "Slightly increased"
        case .increased: "Increased"
        case .slightlyReduced: "Slightly reduced"
        case .reduced: "Reduced"
        case .insufficientData: "Insufficient data"
        }
    }
}

// MARK: - Baseline

/// A user's baseline scan for comparison.
struct SkinBaseline: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: String
    let createdAt: Date
    let scanId: UUID
    var zoneScores: [SkinZone: [SkinMetricKey: Int]]
    var lightingMetadata: LightingMetadata
    var deviceMetadata: DeviceMetadata
    
    struct LightingMetadata: Codable, Sendable {
        var brightness: Double
        var contrast: Double
        var colorTemperature: Double?
    }
    
    struct DeviceMetadata: Codable, Sendable {
        var deviceModel: String
        var cameraPosition: String
        var resolution: String
    }
}

/// Comparison of a scan against the user's baseline.
struct BaselineComparison: Codable, Sendable {
    var baselineId: UUID
    var daysSinceBaseline: Int
    var zoneComparisons: [SkinZone: [SkinMetricKey: SkinTrend]]
    var overallChangePercentage: Double
}

// MARK: - Analysis Summary

/// Top-level summary of a skin analysis.
struct SkinAnalysisSummary: Codable, Sendable {
    var overallStatus: OverallStatus = .insufficientData
    var primaryChange: String = ""
    var confidence: ScanQualityResult.QualityConfidence = .low
    var disclaimer: String = "Clera provides cosmetic skin tracking insights only and does not provide medical advice, diagnosis, or treatment."
    
    enum OverallStatus: String, Codable, Sendable {
        case stable
        case stableWithMinorChanges
        case noticeableChanges
        case significantChanges
        case insufficientData
        
        var displayName: String {
            switch self {
            case .stable: "Stable"
            case .stableWithMinorChanges: "Stable with minor changes"
            case .noticeableChanges: "Noticeable changes"
            case .significantChanges: "Significant changes"
            case .insufficientData: "Insufficient data"
            }
        }
    }
}

// MARK: - Skin Insight

/// A plain-English insight about a zone or metric.
struct SkinInsight: Codable, Identifiable, Sendable {
    let id: UUID
    let zone: SkinZone
    let metric: SkinMetricKey
    let message: String
    let nextStep: String
    let confidence: ScanQualityResult.QualityConfidence
    
    init(
        id: UUID = UUID(),
        zone: SkinZone,
        metric: SkinMetricKey,
        message: String,
        nextStep: String,
        confidence: ScanQualityResult.QualityConfidence
    ) {
        self.id = id
        self.zone = zone
        self.metric = metric
        self.message = message
        self.nextStep = nextStep
        self.confidence = confidence
    }
}

// MARK: - Analysis Result

/// Complete structured output from the skin analysis engine.
struct SkinAnalysisResult: Codable, Sendable {
    let scanId: UUID
    let userId: String
    let createdAt: Date
    let quality: ScanQualityResult
    let zones: [SkinZoneAnalysis]
    let summary: SkinAnalysisSummary
}

// MARK: - CGRect / CGPoint Codable
// CoreGraphics provides Codable conformance on iOS 17+; no custom extensions needed.
