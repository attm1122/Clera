import UIKit
import CoreGraphics

/// Generates skin masks from images using YCbCr colour thresholding.
enum SkinMaskGenerator {

    /// Creates a grayscale mask where white = skin, black = non-skin.
    /// Excludes provided regions (eyes, eyebrows, mouth) from the mask.
    static func generateSkinMask(from image: UIImage, excluding regions: [CGRect]?) -> CGImage? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow

        var maskBytes = [UInt8](repeating: 0, count: width * height)

        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = Double(ptr[offset])
                let g = Double(ptr[offset + 1])
                let b = Double(ptr[offset + 2])

                let yVal = 0.299 * r + 0.587 * g + 0.114 * b
                let cb = 128.0 - 0.168736 * r - 0.331264 * g + 0.5 * b
                let cr = 128.0 + 0.5 * r - 0.418688 * g - 0.081312 * b

                let nx = Double(x) / Double(width)
                let ny = Double(y) / Double(height)
                let point = CGPoint(x: nx, y: ny)

                let inExcluded = regions?.contains { $0.contains(point) } ?? false

                let isSkin = !inExcluded
                    && yVal > 40
                    && yVal < 250
                    && cb > 77 && cb < 127
                    && cr > 133 && cr < 173

                maskBytes[y * width + x] = isSkin ? 255 : 0
            }
        }

        // Fill skipped pixels
        for y in 0..<height {
            for x in 0..<width {
                if maskBytes[y * width + x] == 0 && (y % 2 == 1 || x % 2 == 1) {
                    let srcY = (y / 2) * 2
                    let srcX = (x / 2) * 2
                    maskBytes[y * width + x] = maskBytes[srcY * width + srcX]
                }
            }
        }

        guard let provider = CGDataProvider(data: Data(maskBytes) as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    /// Applies a binary mask to an image, returning only masked pixels.
    static func applyMask(_ mask: CGImage, to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        let maskWidth = mask.width
        let maskHeight = mask.height

        guard let imageDataProvider = cgImage.dataProvider,
              let imageData = imageDataProvider.data,
              let imagePtr = CFDataGetBytePtr(imageData),
              let maskDataProvider = mask.dataProvider,
              let maskData = maskDataProvider.data,
              let maskPtr = CFDataGetBytePtr(maskData) else { return nil }

        let bytesPerPixel = 4
        let imageBytesPerRow = cgImage.bytesPerRow
        let maskBytesPerRow = mask.bytesPerRow

        var outputBytes = [UInt8](repeating: 0, count: imageWidth * imageHeight * 4)

        for y in 0..<imageHeight {
            for x in 0..<imageWidth {
                let mx = x * maskWidth / imageWidth
                let my = y * maskHeight / imageHeight
                let maskVal = maskPtr[my * maskBytesPerRow + mx]

                let srcOffset = y * imageBytesPerRow + x * bytesPerPixel
                let dstOffset = y * imageWidth * 4 + x * 4

                if maskVal > 128 {
                    outputBytes[dstOffset] = imagePtr[srcOffset]
                    outputBytes[dstOffset + 1] = imagePtr[srcOffset + 1]
                    outputBytes[dstOffset + 2] = imagePtr[srcOffset + 2]
                    outputBytes[dstOffset + 3] = 255
                } else {
                    outputBytes[dstOffset + 3] = 0
                }
            }
        }

        guard let provider = CGDataProvider(data: Data(outputBytes) as CFData) else { return nil }
        guard let outCG = CGImage(
            width: imageWidth,
            height: imageHeight,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: imageWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else { return nil }

        return UIImage(cgImage: outCG)
    }
}
