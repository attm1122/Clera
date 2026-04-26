import Foundation
import SwiftUI

struct ScanSession: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: ScanType
    var createdAt: Date = .now
    var photos: [ScanPhoto]
    var skinMap: SkinMap
    var note: String?
}

enum ScanType: String, Codable {
    case baseline, daily, weekly, checkIn, experimentStart, experimentEnd
}

struct ScanPhoto: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var zone: ZoneType?
    var date: Date = .now
    var imageData: Data?
    var fileName: String?

    enum CodingKeys: String, CodingKey {
        case id, zone, date, fileName
    }

    init(zone: ZoneType?, imageData: Data? = nil, fileName: String? = nil) {
        self.zone = zone
        self.imageData = imageData
        self.fileName = fileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.zone = try container.decodeIfPresent(ZoneType.self, forKey: .zone)
        self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? .now
        self.fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(zone, forKey: .zone)
        try container.encode(date, forKey: .date)
        try container.encode(fileName, forKey: .fileName)
    }

    func resolvedImage() -> UIImage? {
        if let fileName = fileName {
            return ImageStore.load(fileName: fileName)
        }
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        return nil
    }
}

enum CaptureAngle: String, CaseIterable, Identifiable, Codable {
    case front, left, right
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var guidance: String {
        switch self {
        case .front: "Face the camera directly, relax your expression."
        case .left: "Turn your head slightly to show your left profile."
        case .right: "Turn your head slightly to show your right profile."
        }
    }
}
