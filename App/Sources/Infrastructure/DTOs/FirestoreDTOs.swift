import Foundation

// MARK: - User Profile DTO

struct FirestoreUserProfileDTO: Codable, Sendable {
    let userId: String
    let name: String
    let email: String?
    let skinType: String
    let sensitivity: String
    let primaryConcerns: [String]
    let primaryGoal: String
    let ageRange: String
    let stressLevel: String
    let updatedAt: Date
}

// MARK: - Scan Session DTO

struct FirestoreScanSessionDTO: Codable, Sendable {
    let id: String
    let userId: String
    let kind: String
    let createdAt: Date
    let note: String?
    let checkIn: FirestoreCheckInDTO?
    let scanQuality: FirestoreScanQualityDTO?
    let zones: [FirestoreFaceZoneDTO]
    let confidenceLevel: Double
    let imageFileNames: [String]
    let updatedAt: Date
}

struct FirestoreCheckInDTO: Codable, Sendable {
    let followedRoutine: Bool
    let newProducts: Bool
    let hadIrritation: Bool
    let hadDryness: Bool
    let hadBreakouts: Bool
    let notes: String?
}

struct FirestoreScanQualityDTO: Codable, Sendable {
    let blurScore: Double
    let brightnessScore: Double
    let sharpnessScore: Double
    let overexposed: Bool
    let shadowDetected: Bool
    let scanReadiness: String
}

struct FirestoreFaceZoneDTO: Codable, Sendable {
    let zoneType: String
    let breakouts: String
    let redness: String
    let dryness: String
    let texture: String
    let congestion: String
    let irritation: String
    let breakoutsTrend: String
    let rednessTrend: String
    let drynessTrend: String
    let textureTrend: String
    let congestionTrend: String
    let irritationTrend: String
    let overallConfidence: Double
    let notes: String?
}

// MARK: - Skin Map Snapshot DTO

struct FirestoreSkinMapSnapshotDTO: Codable, Sendable {
    let id: String
    let userId: String
    let date: Date
    let scanId: String?
    let zones: [FirestoreFaceZoneDTO]
    let confidenceLevel: Double
    let updatedAt: Date
}

// MARK: - Routine Log DTO

struct FirestoreRoutineLogDTO: Codable, Sendable {
    let id: String
    let userId: String
    let date: Date
    let followedRoutine: Bool
    let productIDs: [String]
    let notes: String?
    let updatedAt: Date
}

// MARK: - Routine Change DTO

struct FirestoreRoutineChangeDTO: Codable, Sendable {
    let id: String
    let userId: String
    let productId: String
    let changeType: String
    let date: Date
    let notes: String?
    let updatedAt: Date
}

// MARK: - Product DTO

struct FirestoreProductDTO: Codable, Sendable {
    let id: String
    let userId: String
    let name: String
    let category: String
    let period: String
    let ingredients: [String]
    let ingredientTags: [String]
    let isActive: Bool
    let addedDate: Date
    let sortOrder: Int
    let updatedAt: Date
}

// MARK: - Experiment DTO

struct FirestoreExperimentDTO: Codable, Sendable {
    let id: String
    let userId: String
    let name: String
    let zone: String
    let hypothesis: String
    let durationDays: Int
    let isActive: Bool
    let startDate: Date
    let endDate: Date?
    let relatedProductIDs: [String]
    let result: FirestoreExperimentResultDTO?
    let updatedAt: Date
}

struct FirestoreExperimentResultDTO: Codable, Sendable {
    let outcome: String
    let notes: String?
    let finalSkinMapID: String?
}

// MARK: - Sync Metadata DTO

struct FirestoreSyncMetadataDTO: Codable, Sendable {
    let userId: String
    let lastSyncDate: Date
    let migratedAt: Date?
    let deviceId: String
    let appVersion: String
    let buildNumber: String
}

// MARK: - Mapping Helpers

extension FirestoreUserProfileDTO {
    init(from profile: SkinProfile, userId: String, name: String, email: String?) {
        self.userId = userId
        self.name = name
        self.email = email
        self.skinType = profile.skinType.rawValue
        self.sensitivity = profile.sensitivity.rawValue
        self.primaryConcerns = profile.primaryConcerns.map(\.rawValue)
        self.primaryGoal = profile.primaryGoal.rawValue
        self.ageRange = profile.ageRange.rawValue
        self.stressLevel = profile.stressLevel.rawValue
        self.updatedAt = .now
    }

    func toSkinProfile() -> SkinProfile {
        SkinProfile(
            skinType: SkinType(rawValue: skinType) ?? .combination,
            sensitivity: Sensitivity(rawValue: sensitivity) ?? .mild,
            primaryConcerns: primaryConcerns.compactMap { SkinConcern(rawValue: $0) },
            primaryGoal: SkinGoal(rawValue: primaryGoal) ?? .evenTone,
            ageRange: AgeRange(rawValue: ageRange) ?? .range25to34,
            stressLevel: StressLevel(rawValue: stressLevel) ?? .moderate
        )
    }
}

extension FirestoreScanSessionDTO {
    init(from session: ScanSession, userId: String) {
        self.id = session.id.uuidString
        self.userId = userId
        self.kind = session.kind.rawValue
        self.createdAt = session.createdAt
        self.note = session.note
        self.checkIn = session.skinMap.checkIn.map { FirestoreCheckInDTO(from: $0) }
        self.scanQuality = session.skinMap.scanQuality.map { FirestoreScanQualityDTO(from: $0) }
        self.zones = session.skinMap.zones.map { FirestoreFaceZoneDTO(from: $0) }
        self.confidenceLevel = session.skinMap.confidenceLevel
        self.imageFileNames = session.photos.compactMap(\.fileName)
        self.updatedAt = .now
    }

    func toScanSession() -> ScanSession? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return ScanSession(
            id: uuid,
            kind: ScanType(rawValue: kind) ?? .daily,
            createdAt: createdAt,
            photos: [],
            skinMap: SkinMap(
                id: UUID(),
                date: createdAt,
                scanId: uuid,
                zones: zones.map { $0.toFaceZone() },
                checkIn: checkIn?.toCheckIn(),
                scanQuality: scanQuality?.toScanQualityMetadata(),
                confidenceLevel: confidenceLevel
            ),
            note: note
        )
    }
}

extension FirestoreCheckInDTO {
    init(from checkIn: SkinMapCheckIn) {
        self.followedRoutine = checkIn.followedRoutine
        self.newProducts = checkIn.newProducts
        self.hadIrritation = checkIn.hadIrritation
        self.hadDryness = checkIn.hadDryness
        self.hadBreakouts = checkIn.hadBreakouts
        self.notes = checkIn.notes
    }

    func toCheckIn() -> SkinMapCheckIn {
        SkinMapCheckIn(
            followedRoutine: followedRoutine,
            newProducts: newProducts,
            hadIrritation: hadIrritation,
            hadDryness: hadDryness,
            hadBreakouts: hadBreakouts,
            notes: notes
        )
    }
}

extension FirestoreScanQualityDTO {
    init(from quality: ScanQualityMetadata) {
        self.blurScore = quality.blurScore
        self.brightnessScore = quality.brightnessScore
        self.sharpnessScore = quality.sharpnessScore
        self.overexposed = quality.overexposed
        self.shadowDetected = quality.shadowDetected
        self.scanReadiness = quality.scanReadiness
    }

    func toScanQualityMetadata() -> ScanQualityMetadata {
        ScanQualityMetadata(
            blurScore: blurScore,
            brightnessScore: brightnessScore,
            sharpnessScore: sharpnessScore,
            overexposed: overexposed,
            shadowDetected: shadowDetected,
            scanReadiness: scanReadiness
        )
    }
}

extension FirestoreFaceZoneDTO {
    init(from zone: FaceZone) {
        self.zoneType = zone.zoneType.rawValue
        self.breakouts = zone.status.breakouts.rawValue
        self.redness = zone.status.redness.rawValue
        self.dryness = zone.status.dryness.rawValue
        self.texture = zone.status.texture.rawValue
        self.congestion = zone.status.congestion.rawValue
        self.irritation = zone.status.irritation.rawValue
        self.breakoutsTrend = zone.status.breakoutsTrend.rawValue
        self.rednessTrend = zone.status.rednessTrend.rawValue
        self.drynessTrend = zone.status.drynessTrend.rawValue
        self.textureTrend = zone.status.textureTrend.rawValue
        self.congestionTrend = zone.status.congestionTrend.rawValue
        self.irritationTrend = zone.status.irritationTrend.rawValue
        self.overallConfidence = zone.status.overallConfidence
        self.notes = zone.notes
    }

    func toFaceZone() -> FaceZone {
        FaceZone(
            zoneType: ZoneType(rawValue: zoneType) ?? .forehead,
            status: ZoneStatus(
                breakouts: ZoneSeverity(rawValue: breakouts) ?? .none,
                redness: ZoneSeverity(rawValue: redness) ?? .none,
                dryness: ZoneSeverity(rawValue: dryness) ?? .none,
                texture: ZoneSeverity(rawValue: texture) ?? .none,
                congestion: ZoneSeverity(rawValue: congestion) ?? .none,
                irritation: ZoneSeverity(rawValue: irritation) ?? .none,
                breakoutsTrend: ZoneTrend(rawValue: breakoutsTrend) ?? .unknown,
                rednessTrend: ZoneTrend(rawValue: rednessTrend) ?? .unknown,
                drynessTrend: ZoneTrend(rawValue: drynessTrend) ?? .unknown,
                textureTrend: ZoneTrend(rawValue: textureTrend) ?? .unknown,
                congestionTrend: ZoneTrend(rawValue: congestionTrend) ?? .unknown,
                irritationTrend: ZoneTrend(rawValue: irritationTrend) ?? .unknown,
                overallConfidence: overallConfidence
            ),
            notes: notes
        )
    }
}

extension FirestoreRoutineLogDTO {
    init(from entry: RoutineLogEntry, userId: String) {
        self.id = entry.id.uuidString
        self.userId = userId
        self.date = entry.date
        self.followedRoutine = entry.followedRoutine
        self.productIDs = entry.productIDs.map(\.uuidString)
        self.notes = entry.notes
        self.updatedAt = .now
    }

    func toRoutineLogEntry() -> RoutineLogEntry {
        RoutineLogEntry(
            id: UUID(uuidString: id) ?? UUID(),
            date: date,
            followedRoutine: followedRoutine,
            productIDs: productIDs.compactMap { UUID(uuidString: $0) },
            notes: notes
        )
    }
}

extension FirestoreRoutineChangeDTO {
    init(from change: RoutineChangeLogEntry, userId: String) {
        self.id = change.id.uuidString
        self.userId = userId
        self.productId = change.productId.uuidString
        self.changeType = change.changeType.rawValue
        self.date = change.date
        self.notes = change.notes
        self.updatedAt = .now
    }

    func toRoutineChangeLogEntry() -> RoutineChangeLogEntry {
        RoutineChangeLogEntry(
            id: UUID(uuidString: id) ?? UUID(),
            productId: UUID(uuidString: productId) ?? UUID(),
            changeType: ChangeType(rawValue: changeType) ?? .added,
            notes: notes
        )
    }
}

extension FirestoreProductDTO {
    init(from product: Product, userId: String) {
        self.id = product.id.uuidString
        self.userId = userId
        self.name = product.name
        self.category = product.category.rawValue
        self.period = product.period.rawValue
        self.ingredients = product.ingredients
        self.ingredientTags = product.ingredientTags.map(\.rawValue)
        self.isActive = product.isActive
        self.addedDate = product.addedDate
        self.sortOrder = product.sortOrder
        self.updatedAt = .now
    }

    func toProduct() -> Product {
        Product(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            category: ProductCategory(rawValue: category) ?? .cleanser,
            period: Period(rawValue: period) ?? .both,
            ingredients: ingredients,
            ingredientTags: ingredientTags.compactMap { IngredientTag(rawValue: $0) },
            isActive: isActive,
            addedDate: addedDate,
            sortOrder: sortOrder
        )
    }
}

extension FirestoreExperimentDTO {
    init(from experiment: Experiment, userId: String) {
        self.id = experiment.id.uuidString
        self.userId = userId
        self.name = experiment.name
        self.zone = experiment.zone.rawValue
        self.hypothesis = experiment.hypothesis
        self.durationDays = experiment.durationDays
        self.isActive = experiment.isActive
        self.startDate = experiment.startDate
        self.endDate = experiment.endDate
        self.relatedProductIDs = experiment.relatedProductIDs.map(\.uuidString)
        self.result = experiment.result.map { FirestoreExperimentResultDTO(from: $0) }
        self.updatedAt = .now
    }

    func toExperiment() -> Experiment {
        Experiment(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            zone: ZoneType(rawValue: zone) ?? .forehead,
            hypothesis: hypothesis,
            durationDays: durationDays,
            isActive: isActive,
            startDate: startDate,
            endDate: endDate,
            relatedProductIDs: relatedProductIDs.compactMap { UUID(uuidString: $0) },
            result: result?.toExperimentResult(),
            dailyCheckIns: []
        )
    }
}

extension FirestoreExperimentResultDTO {
    init(from result: ExperimentResult) {
        self.outcome = result.outcome.rawValue
        self.notes = result.notes
        self.finalSkinMapID = result.finalSkinMapID?.uuidString
    }

    func toExperimentResult() -> ExperimentResult {
        ExperimentResult(
            outcome: ExperimentOutcome(rawValue: outcome) ?? .noChange,
            notes: notes,
            finalSkinMapID: finalSkinMapID.flatMap { UUID(uuidString: $0) }
        )
    }
}
