import CoreImage
import CoreVideo

/// Shared image-quality utility used internally by all vision providers.
/// Computes blur, brightness, contrast, sharpness, overexposure, and shadows
/// using only CoreImage / vImage — zero external dependencies.
final class NativeQualityAnalyzer: Sendable {

    private let context = CIContext(options: [.workingColorSpace: NSNull()])

    func analyze(_ pixelBuffer: CVPixelBuffer) -> VisionFrameResult.QualityMetrics {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return VisionFrameResult.QualityMetrics()
        }

        let brightness = computeBrightness(cgImage)
        let contrast = computeContrast(cgImage)
        let blur = computeBlur(cgImage)
        let sharpness = computeSharpness(cgImage)
        let overexposed = isOverexposed(cgImage, brightness: brightness)
        let shadows = hasShadows(cgImage, brightness: brightness)

        let lighting: LightingQuality
        if brightness < 0.25 {
            lighting = .tooDark
        } else if brightness > 0.75 && overexposed {
            lighting = .tooBright
        } else if shadows {
            lighting = .uneven
        } else {
            lighting = .good
        }

        return VisionFrameResult.QualityMetrics(
            blurScore: blur,
            brightnessScore: brightness,
            contrastScore: contrast,
            sharpnessScore: sharpness,
            overexposed: overexposed,
            shadowDetected: shadows,
            lightingQuality: lighting
        )
    }

    // MARK: - Brightness

    private func computeBrightness(_ cgImage: CGImage) -> Double {
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0 }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow
        var sum: UInt64 = 0
        var count = 0

        for y in stride(from: 0, to: height, by: 4) {
            for x in stride(from: 0, to: width, by: 4) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                sum += (UInt64(ptr[offset]) + UInt64(ptr[offset + 1]) + UInt64(ptr[offset + 2])) / 3
                count += 1
            }
        }

        return Double(sum) / Double(max(count, 1)) / 255.0
    }

    // MARK: - Contrast

    private func computeContrast(_ cgImage: CGImage) -> Double {
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0 }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow
        var values: [Double] = []

        for y in stride(from: 0, to: height, by: 4) {
            for x in stride(from: 0, to: width, by: 4) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let avg = Double(ptr[offset] + ptr[offset + 1] + ptr[offset + 2]) / 3.0 / 255.0
                values.append(avg)
            }
        }

        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        return min(sqrt(variance) * 4.0, 1.0)
    }

    // MARK: - Blur (Laplacian variance)

    private func computeBlur(_ cgImage: CGImage) -> Double {
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0 }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow
        var laplacianSum: Double = 0
        var count = 0

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let centerOffset = y * bytesPerRow + x * bytesPerPixel
                let center = Double(ptr[centerOffset])
                let top = Double(ptr[(y - 1) * bytesPerRow + x * bytesPerPixel])
                let bottom = Double(ptr[(y + 1) * bytesPerRow + x * bytesPerPixel])
                let left = Double(ptr[y * bytesPerRow + (x - 1) * bytesPerPixel])
                let right = Double(ptr[y * bytesPerRow + (x + 1) * bytesPerPixel])

                laplacianSum += abs(4 * center - top - bottom - left - right)
                count += 1
            }
        }

        return min(laplacianSum / Double(max(count, 1)) / 500.0, 1.0)
    }

    // MARK: - Sharpness (Sobel edge magnitude)

    private func computeSharpness(_ cgImage: CGImage) -> Double {
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0 }

        let width = cgImage.width
        let height = cgImage.height
        let bpp = 4
        let bpr = cgImage.bytesPerRow
        var edgeSum: Double = 0
        var count = 0

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let off = y * bpr + x * bpp
                let tl = Double(ptr[off - bpr - bpp])
                let tm = Double(ptr[off - bpr])
                let tr = Double(ptr[off - bpr + bpp])
                let ml = Double(ptr[off - bpp])
                let mr = Double(ptr[off + bpp])
                let bl = Double(ptr[off + bpr - bpp])
                let bm = Double(ptr[off + bpr])
                let br = Double(ptr[off + bpr + bpp])

                let gx = (tr + 2 * mr + br) - (tl + 2 * ml + bl)
                let gy = (bl + 2 * bm + br) - (tl + 2 * tm + tr)
                edgeSum += sqrt(gx * gx + gy * gy)
                count += 1
            }
        }

        return min(edgeSum / Double(max(count, 1)) / 1000.0, 1.0)
    }

    // MARK: - Overexposure

    private func isOverexposed(_ cgImage: CGImage, brightness: Double) -> Bool {
        guard brightness > 0.6 else { return false }
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return false }

        let w = cgImage.width
        let h = cgImage.height
        let bpp = 4
        let bpr = cgImage.bytesPerRow
        var bright = 0
        var total = 0

        for y in stride(from: 0, to: h, by: 4) {
            for x in stride(from: 0, to: w, by: 4) {
                let off = y * bpr + x * bpp
                if ptr[off] > 240 && ptr[off + 1] > 240 && ptr[off + 2] > 240 {
                    bright += 1
                }
                total += 1
            }
        }

        return Double(bright) / Double(max(total, 1)) > 0.15
    }

    // MARK: - Shadows

    private func hasShadows(_ cgImage: CGImage, brightness: Double) -> Bool {
        guard brightness < 0.6 else { return false }
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return false }

        let w = cgImage.width
        let h = cgImage.height
        let bpp = 4
        let bpr = cgImage.bytesPerRow
        var dark = 0
        var total = 0

        for y in stride(from: 0, to: h, by: 4) {
            for x in stride(from: 0, to: w, by: 4) {
                let off = y * bpr + x * bpp
                if ptr[off] < 40 && ptr[off + 1] < 40 && ptr[off + 2] < 40 {
                    dark += 1
                }
                total += 1
            }
        }

        return Double(dark) / Double(max(total, 1)) > 0.2
    }
}
