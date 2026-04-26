import Foundation
@testable import Clera

/// Pre-built user scenarios for testing the Skin Session pipeline.
/// Each fixture returns the inputs needed to run `SessionPipeline.process()`.
enum CleraFixtures {

    struct PipelineInputs {
        var scanSession: ScanSession
        var checkIn: SkinMapCheckIn?
        var currentProducts: [Product]
        var routineLogs: [RoutineLogEntry]
        var routineChanges: [RoutineChangeLogEntry]
        var allSessions: [ScanSession]
        var skinMapHistory: [SkinMap]
        var experiments: [Experiment]
        var scanFailures: [SessionFailure]
    }

    // MARK: - 1. New User (no baseline)

    static func newUserNoBaseline() -> PipelineInputs {
        let scan = ScanSession(kind: .baseline, photos: [], skinMap: SampleData.sampleSkinMap, note: "First scan")
        return PipelineInputs(
            scanSession: scan,
            checkIn: SkinMapCheckIn(followedRoutine: false, newProducts: false, hadIrritation: false, hadDryness: false, hadBreakouts: false, notes: nil),
            currentProducts: [],
            routineLogs: [],
            routineChanges: [],
            allSessions: [scan],
            skinMapHistory: [scan.skinMap],
            experiments: [],
            scanFailures: []
        )
    }

    // MARK: - 2. 7 Days Consistent

    static func userWith7DaysConsistent() -> PipelineInputs {
        var sessions: [ScanSession] = []
        var maps: [SkinMap] = []
        let calendar = Calendar.current

        for day in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -day, to: .now) ?? .now
            // Slight improvement over time
            let zones: [FaceZone] = [
                FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: .low, redness: .none)),
                FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: .low, redness: day == 0 ? .none : .low)),
                FaceZone(zoneType: .leftCheek, status: ZoneStatus(breakouts: .none, redness: .none)),
                FaceZone(zoneType: .rightCheek, status: ZoneStatus(breakouts: .low, redness: .none)),
                FaceZone(zoneType: .chinJaw, status: ZoneStatus(breakouts: .moderate, redness: .low))
            ]
            let map = SkinMap(date: date, zones: zones)
            var scan = ScanSession(kind: .daily, photos: [], skinMap: map, note: nil)
            scan.createdAt = date
            sessions.append(scan)
            maps.append(map)
        }

        return PipelineInputs(
            scanSession: sessions.first!,
            checkIn: SkinMapCheckIn(followedRoutine: true, newProducts: false, hadIrritation: false, hadDryness: false, hadBreakouts: false, notes: nil),
            currentProducts: SampleData.defaultProducts,
            routineLogs: (0..<14).map { i in
                RoutineLogEntry(date: calendar.date(byAdding: .day, value: -(i/2), to: .now) ?? .now, followedRoutine: true, productIDs: SampleData.defaultProducts.map(\.id), notes: nil)
            },
            routineChanges: [],
            allSessions: sessions,
            skinMapHistory: maps,
            experiments: [],
            scanFailures: []
        )
    }

    // MARK: - 3. Worsening Chin/Jaw Breakouts

    static func userWithWorseningChinJaw() -> PipelineInputs {
        let calendar = Calendar.current
        var maps: [SkinMap] = []
        var sessions: [ScanSession] = []

        for day in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -day, to: .now) ?? .now
            let chinBreakouts: ZoneSeverity = day == 0 ? .high : day == 1 ? .moderate : .low
            let zones: [FaceZone] = [
                FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: .low, redness: .none)),
                FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: .low, redness: .low)),
                FaceZone(zoneType: .leftCheek, status: ZoneStatus(breakouts: .none, redness: .none)),
                FaceZone(zoneType: .rightCheek, status: ZoneStatus(breakouts: .low, redness: .none)),
                FaceZone(zoneType: .chinJaw, status: ZoneStatus(breakouts: chinBreakouts, redness: .low))
            ]
            let map = SkinMap(date: date, zones: zones)
            var scan = ScanSession(kind: .daily, photos: [], skinMap: map, note: nil)
            scan.createdAt = date
            sessions.append(scan)
            maps.append(map)
        }

        let retinolProduct = Product(name: "Strong Retinol", category: .treatment, period: .evening, ingredientTags: [.retinol])

        return PipelineInputs(
            scanSession: sessions.first!,
            checkIn: SkinMapCheckIn(followedRoutine: true, newProducts: true, hadIrritation: false, hadDryness: false, hadBreakouts: true, notes: "New serum added"),
            currentProducts: SampleData.defaultProducts + [retinolProduct],
            routineLogs: [],
            routineChanges: [RoutineChangeLogEntry(productId: retinolProduct.id, changeType: .added, notes: "Added retinol 3 days ago")],
            allSessions: sessions,
            skinMapHistory: maps,
            experiments: [],
            scanFailures: []
        )
    }

    // MARK: - 4. Improving Redness

    static func userWithImprovingRedness() -> PipelineInputs {
        let calendar = Calendar.current
        var maps: [SkinMap] = []
        var sessions: [ScanSession] = []

        for day in 0..<4 {
            let date = calendar.date(byAdding: .day, value: -day, to: .now) ?? .now
            let noseRedness: ZoneSeverity = day == 0 ? .none : day == 1 ? .low : .moderate
            let zones: [FaceZone] = [
                FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: .low, redness: .none)),
                FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: .low, redness: noseRedness)),
                FaceZone(zoneType: .leftCheek, status: ZoneStatus(breakouts: .none, redness: .none)),
                FaceZone(zoneType: .rightCheek, status: ZoneStatus(breakouts: .low, redness: .none)),
                FaceZone(zoneType: .chinJaw, status: ZoneStatus(breakouts: .moderate, redness: .low))
            ]
            let map = SkinMap(date: date, zones: zones)
            var scan = ScanSession(kind: .daily, photos: [], skinMap: map, note: nil)
            scan.createdAt = date
            sessions.append(scan)
            maps.append(map)
        }

        return PipelineInputs(
            scanSession: sessions.first!,
            checkIn: SkinMapCheckIn(followedRoutine: true, newProducts: false, hadIrritation: false, hadDryness: false, hadBreakouts: false, notes: nil),
            currentProducts: SampleData.defaultProducts,
            routineLogs: [],
            routineChanges: [],
            allSessions: sessions,
            skinMapHistory: maps,
            experiments: [],
            scanFailures: []
        )
    }

    // MARK: - 5. Poor Scan Quality

    static func userWithPoorScanQuality() -> PipelineInputs {
        let zones: [FaceZone] = [
            FaceZone(zoneType: .forehead, status: ZoneStatus(breakouts: .low, redness: .none)),
            FaceZone(zoneType: .nose, status: ZoneStatus(breakouts: .low, redness: .low)),
            FaceZone(zoneType: .leftCheek, status: ZoneStatus(breakouts: .none, redness: .none)),
            FaceZone(zoneType: .rightCheek, status: ZoneStatus(breakouts: .low, redness: .none)),
            FaceZone(zoneType: .chinJaw, status: ZoneStatus(breakouts: .moderate, redness: .low))
        ]
        var map = SkinMap(zones: zones)
        map.scanQuality = ScanQualityMetadata(blurScore: 0.05, brightnessScore: 0.3, sharpnessScore: 0.04, overexposed: true, shadowDetected: true, scanReadiness: "poorQuality")
        let scan = ScanSession(kind: .daily, photos: [], skinMap: map, note: nil)

        return PipelineInputs(
            scanSession: scan,
            checkIn: nil,
            currentProducts: SampleData.defaultProducts,
            routineLogs: [],
            routineChanges: [],
            allSessions: [scan],
            skinMapHistory: [map],
            experiments: [],
            scanFailures: []
        )
    }

    // MARK: - 6. No Routine

    static func userWithNoRoutine() -> PipelineInputs {
        let scan = ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        return PipelineInputs(
            scanSession: scan,
            checkIn: SkinMapCheckIn(followedRoutine: false, newProducts: false, hadIrritation: false, hadDryness: false, hadBreakouts: false, notes: nil),
            currentProducts: [],
            routineLogs: [],
            routineChanges: [],
            allSessions: [scan],
            skinMapHistory: [scan.skinMap],
            experiments: [],
            scanFailures: []
        )
    }

    // MARK: - 7. Too Many Actives

    static func userWithTooManyActives() -> PipelineInputs {
        let products: [Product] = [
            Product(name: "Glycolic Acid Toner", category: .toner, period: .evening, ingredientTags: [.aha]),
            Product(name: "Salicylic Acid Cleanser", category: .cleanser, period: .both, ingredientTags: [.bha]),
            Product(name: "Retinol 0.5%", category: .treatment, period: .evening, ingredientTags: [.retinol]),
            Product(name: "Vitamin C Serum", category: .serum, period: .morning, ingredientTags: [.vitaminC]),
            Product(name: "Moisturizer", category: .moisturizer, period: .both, ingredientTags: [.hyaluronicAcid])
        ]
        let scan = ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)

        return PipelineInputs(
            scanSession: scan,
            checkIn: SkinMapCheckIn(followedRoutine: true, newProducts: false, hadIrritation: true, hadDryness: true, hadBreakouts: false, notes: "Skin feels tight"),
            currentProducts: products,
            routineLogs: [],
            routineChanges: [],
            allSessions: [scan],
            skinMapHistory: [scan.skinMap],
            experiments: [],
            scanFailures: []
        )
    }

    // MARK: - 8. Rejected Scan (no face)

    static func rejectedScanNoFace() -> PipelineInputs {
        let scan = ScanSession(kind: .daily, photos: [], skinMap: SampleData.sampleSkinMap, note: nil)
        return PipelineInputs(
            scanSession: scan,
            checkIn: nil,
            currentProducts: SampleData.defaultProducts,
            routineLogs: [],
            routineChanges: [],
            allSessions: [scan],
            skinMapHistory: [scan.skinMap],
            experiments: [],
            scanFailures: [
                SessionFailure(failureCode: .noFaceDetected, userMessage: "No face detected", recommendedAction: "Centre your face", canContinue: false, confidenceImpact: 1.0)
            ]
        )
    }
}
