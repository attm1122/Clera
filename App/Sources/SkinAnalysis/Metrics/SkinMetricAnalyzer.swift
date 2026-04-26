import UIKit
import CoreGraphics

/// Protocol for all skin metric analyzers.
protocol SkinMetricAnalyzer: Sendable {
    var metricKey: SkinMetricKey { get }
    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore
}

// MARK: - Shared Helpers

/// Checks if a pixel coordinate falls within both the skin mask and zone mask.
func isInMasks(x: Int, y: Int, width: Int, height: Int, skinMask: CGImage?, zoneMask: CGImage?) -> Bool {
    if let skinMask = skinMask {
        guard pixelInMask(x: x, y: y, imageWidth: width, imageHeight: height, mask: skinMask) else {
            return false
        }
    }
    if let zoneMask = zoneMask {
        guard pixelInMask(x: x, y: y, imageWidth: width, imageHeight: height, mask: zoneMask) else {
            return false
        }
    }
    return true
}

private func pixelInMask(x: Int, y: Int, imageWidth: Int, imageHeight: Int, mask: CGImage) -> Bool {
    let maskWidth = mask.width
    let maskHeight = mask.height
    let mx = x * maskWidth / imageWidth
    let my = y * maskHeight / imageHeight

    guard let dataProvider = mask.dataProvider,
          let data = dataProvider.data,
          let ptr = CFDataGetBytePtr(data) else { return true }

    let bytesPerRow = mask.bytesPerRow
    guard mx >= 0 && mx < maskWidth && my >= 0 && my < maskHeight else { return false }
    return ptr[my * bytesPerRow + mx] > 128
}
