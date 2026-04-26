import Foundation

/// Repository for scan session metadata in the cloud.
/// Images are stored locally; only metadata and analysis outputs sync.
protocol SkinScanRepository: Sendable {
    func saveScan(_ session: ScanSession, userId: String) async throws
    func loadScans(userId: String) async throws -> [ScanSession]
    func saveSkinMapSnapshot(_ map: SkinMap, userId: String) async throws
    func loadSkinMapSnapshots(userId: String) async throws -> [SkinMap]
}
