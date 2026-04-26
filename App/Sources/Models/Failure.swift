import Foundation

enum FailureCode: String, Codable {
    case noFaceDetected
    case multipleFaces
    case faceNotCentred
    case poorLighting
    case harshGlare
    case blurryImage
    case faceTooClose
    case faceTooFar
    case extremeHeadAngle
    case scanConfidenceLow
    case missingCheckIn
    case noRoutine
    case noPreviousSession
    case inconsistentHistory
    case noBaseline
    case uncertainCopilot

    var displayName: String {
        switch self {
        case .noFaceDetected: CleraCopy.DisplayNames.failureNoFace
        case .multipleFaces: CleraCopy.DisplayNames.failureMultipleFaces
        case .faceNotCentred: CleraCopy.DisplayNames.failureOffCentre
        case .poorLighting: CleraCopy.DisplayNames.failurePoorLighting
        case .harshGlare: CleraCopy.DisplayNames.failureGlare
        case .blurryImage: CleraCopy.DisplayNames.failureBlurry
        case .faceTooClose: CleraCopy.DisplayNames.failureTooClose
        case .faceTooFar: CleraCopy.DisplayNames.failureTooFar
        case .extremeHeadAngle: CleraCopy.DisplayNames.failureExtremeAngle
        case .scanConfidenceLow: CleraCopy.DisplayNames.failureLowConfidence
        case .missingCheckIn: CleraCopy.DisplayNames.failureMissingCheckIn
        case .noRoutine: CleraCopy.DisplayNames.failureNoRoutine
        case .noPreviousSession: CleraCopy.DisplayNames.failureFirstScan
        case .inconsistentHistory: CleraCopy.DisplayNames.failureInconsistentHistory
        case .noBaseline: CleraCopy.DisplayNames.failureNoBaseline
        case .uncertainCopilot: CleraCopy.DisplayNames.failureUncertainPlan
        }
    }
}

struct SessionFailure: Codable, Identifiable, Equatable {
    var id = UUID()
    var failureCode: FailureCode
    var userMessage: String
    var recommendedAction: String
    var canContinue: Bool
    var confidenceImpact: Double
    var isResolved: Bool = false
}
