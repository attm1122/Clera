import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

final class FirestoreRoutineRepository: RoutineRepository, @unchecked Sendable {

    #if canImport(FirebaseFirestore)
    private let db: Firestore?
    #endif

    init() {
        #if canImport(FirebaseFirestore)
        self.db = FirebaseConfiguration.isConfigured ? Firestore.firestore() : nil
        #endif
    }

    func saveRoutineLog(_ entry: RoutineLogEntry, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        let dto = FirestoreRoutineLogDTO(from: entry, userId: userId)
        do {
            let data = try dto.asFirestoreDictionary()
            try await db.collection("users").document(userId).collection("routineLogs").document(dto.id).setData(data)
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }

    func loadRoutineLogs(userId: String) async throws -> [RoutineLogEntry] {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        do {
            let snapshot = try await db.collection("users").document(userId).collection("routineLogs").order(by: "date", descending: true).getDocuments()
            return snapshot.documents.compactMap { doc -> RoutineLogEntry? in
                guard let data = try? JSONSerialization.data(withJSONObject: doc.data()),
                      let dto = try? JSONDecoder().decode(FirestoreRoutineLogDTO.self, from: data) else { return nil }
                return dto.toRoutineLogEntry()
            }
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }

    func saveCurrentProducts(_ products: [Product], userId: String) async throws {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        do {
            let batch = db.batch()
            let collection = db.collection("users").document(userId).collection("currentProducts")
            for product in products {
                let dto = FirestoreProductDTO(from: product, userId: userId)
                let data = try dto.asFirestoreDictionary()
                batch.setData(data, forDocument: collection.document(dto.id))
            }
            try await batch.commit()
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }

    func loadCurrentProducts(userId: String) async throws -> [Product] {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        do {
            let snapshot = try await db.collection("users").document(userId).collection("currentProducts").getDocuments()
            return snapshot.documents.compactMap { doc -> Product? in
                guard let data = try? JSONSerialization.data(withJSONObject: doc.data()),
                      let dto = try? JSONDecoder().decode(FirestoreProductDTO.self, from: data) else { return nil }
                return dto.toProduct()
            }
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }

    func saveRoutineChanges(_ changes: [RoutineChangeLogEntry], userId: String) async throws {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        do {
            let batch = db.batch()
            let collection = db.collection("users").document(userId).collection("routineChanges")
            for change in changes {
                let dto = FirestoreRoutineChangeDTO(from: change, userId: userId)
                let data = try dto.asFirestoreDictionary()
                batch.setData(data, forDocument: collection.document(dto.id))
            }
            try await batch.commit()
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }

    func loadRoutineChanges(userId: String) async throws -> [RoutineChangeLogEntry] {
        #if canImport(FirebaseFirestore)
        guard let db = db else { throw CloudSyncError.notAuthenticated }
        do {
            let snapshot = try await db.collection("users").document(userId).collection("routineChanges").order(by: "date", descending: true).getDocuments()
            return snapshot.documents.compactMap { doc -> RoutineChangeLogEntry? in
                guard let data = try? JSONSerialization.data(withJSONObject: doc.data()),
                      let dto = try? JSONDecoder().decode(FirestoreRoutineChangeDTO.self, from: data) else { return nil }
                return dto.toRoutineChangeLogEntry()
            }
        } catch {
            throw CloudSyncError.unknown(error.localizedDescription)
        }
        #else
        throw CloudSyncError.notAuthenticated
        #endif
    }
}
