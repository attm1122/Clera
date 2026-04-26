import Foundation
import UIKit

/// Stores scan images on disk and returns file references.
/// Images are never stored in the JSON state file — only file names are.
enum ImageStore {
    
    private static var baseDirectory: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return root.appending(path: "Clera/Images", directoryHint: .isDirectory)
    }
    
    @discardableResult
    static func save(_ image: UIImage, fileName: String) -> URL? {
        do {
            try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
            let url = baseDirectory.appending(path: fileName)
            if let data = image.jpegData(compressionQuality: 0.85) {
                try data.write(to: url)
                return url
            }
        } catch {
            #if DEBUG
            print("[ImageStore] Failed to save image: \(error)")
            #endif
        }
        return nil
    }
    
    static func load(fileName: String) -> UIImage? {
        let url = baseDirectory.appending(path: fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    static func delete(fileName: String) {
        let url = baseDirectory.appending(path: fileName)
        try? FileManager.default.removeItem(at: url)
    }
    
    static func deleteAll() {
        try? FileManager.default.removeItem(at: baseDirectory)
    }
    
    static func generateFileName(angle: CaptureAngle, scanId: UUID) -> String {
        "\(scanId.uuidString)_\(angle.rawValue).jpg"
    }
}
