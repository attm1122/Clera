import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

final class FirestoreSkinScanRepository: SkinScanRepository, @unchecked Sendable {

    #if canImport(FirebaseFirestore)
    private let db: Firestore?
    #endif

    init() {
        #if canImport(FirebaseFirestore)
        self.db = FirebaseConfiguration.isConfigured ? Firestore.firestore() : nil
        #endif
    }

    func saveScan(_ session: ScanSession, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        let dto = FirestoreScanSessionDTO(from: session, userId: userId)
        do {
            let data = try dto.asFirestoreDictionary()
            try await db.collection("users").document(userId).collection("skinScans").document(dto.id).setData(data)
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }

    func loadScans(userId: String) async throws -> [ScanSession] {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        do {
            let snapshot = try await db.collection("users").document(userId).collection("skinScans").order(by: "createdAt", descending: true).getDocuments()
            return snapshot.documents.compactMap { doc -> ScanSession? in
                guard let data = try? JSONSerialization.data(withJSONObject: doc.data()),
                      let dto = try? JSONDecoder().decode(FirestoreScanSessionDTO.self, from: data) else { return nil }
                return dto.toScanSession()
            }
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }

    func saveSkinMapSnapshot(_ map: SkinMap, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        let dto = FirestoreSkinMapSnapshotDTO(
            id: map.id.uuidString,
            userId: userId,
            date: map.date,
            scanId: map.scanId?.uuidString,
            zones: map.zones.map { FirestoreFaceZoneDTO(from: $0) },
            confidenceLevel: map.confidenceLevel,
            updatedAt: .now
        )
        do {
            let data = try dto.asFirestoreDictionary()
            try await db.collection("users").document(userId).collection("skinMapSnapshots").document(dto.id).setData(data)
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }

    func loadSkinMapSnapshots(userId: String) async throws -> [SkinMap] {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        do {
            let snapshot = try await db.collection("users").document(userId).collection("skinMapSnapshots").order(by: "date", descending: true).getDocuments()
            return snapshot.documents.compactMap { doc -> SkinMap? in
                guard let data = try? JSONSerialization.data(withJSONObject: doc.data()),
                      let dto = try? JSONDecoder().decode(FirestoreSkinMapSnapshotDTO.self, from: data) else { return nil }
                return SkinMap(
                    id: UUID(uuidString: dto.id) ?? UUID(),
                    date: dto.date,
                    scanId: dto.scanId.flatMap { UUID(uuidString: $0) },
                    zones: dto.zones.map { $0.toFaceZone() },
                    confidenceLevel: dto.confidenceLevel
                )
            }
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }
}
