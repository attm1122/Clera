import UIKit
import CoreGraphics

/// Extracts raw pixel data from a `UIImage` and provides masked pixel enumeration.
/// Eliminates the duplicated `cgImage` / `dataProvider` / `CFDataGetBytePtr` boilerplate
/// found in every `SkinMetricAnalyzer` implementation.
struct PixelBufferSampler {
    let ptr: UnsafePointer<UInt8>
    let width: Int
    let height: Int
    let bytesPerRow: Int
    let bytesPerPixel: Int

    /// Creates a sampler from a `UIImage`, returning `nil` if the buffer cannot be accessed.
    init?(image: UIImage) {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        self.ptr = ptr
        self.width = cgImage.width
        self.height = cgImage.height
        self.bytesPerRow = cgImage.bytesPerRow
        self.bytesPerPixel = 4
    }

    /// Iterates over every `step`th pixel that falls within both masks.
    /// - Parameters:
    ///   - step: Stride increment (e.g. 2 or 4) to skip pixels for performance.
    ///   - skinMask: Optional skin mask. If nil, all pixels pass.
    ///   - zoneMask: Optional zone mask. If nil, all pixels pass.
    ///   - body: Closure receiving the byte offset of each qualifying pixel.
    /// - Returns: The number of pixels that matched the masks and were visited.
    @discardableResult
    func enumerateMaskedPixels(
        step: Int,
        skinMask: CGImage?,
        zoneMask: CGImage?,
        body: (Int) -> Void
    ) -> Int {
        var count = 0
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                if isInMasks(x: x, y: y, width: width, height: height, skinMask: skinMask, zoneMask: zoneMask) {
                    body(y * bytesPerRow + x * bytesPerPixel)
                    count += 1
                }
            }
        }
        return count
    }

    /// Clamps a raw score to the valid 0–100 range.
    static func clampScore(_ score: Int) -> Int {
        max(0, min(100, score))
    }
}
