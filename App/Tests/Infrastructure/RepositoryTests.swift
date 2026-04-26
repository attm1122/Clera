import XCTest
@testable import Clera

final class RepositoryTests: XCTestCase {

    func testDTOToDomainMapping() {
        let profile = SkinProfile(
            skinType: .oily,
            sensitivity: .reactive,
            primaryConcerns: [.breakouts, .redness],
            primaryGoal: .clearerSkin,
            ageRange: .range25to34,
            stressLevel: .high
        )

        let dto = FirestoreUserProfileDTO(from: profile, userId: "u1", name: "Alice", email: "alice@example.com")
        let mapped = dto.toSkinProfile()

        XCTAssertEqual(mapped.skinType, .oily)
        XCTAssertEqual(mapped.sensitivity, .reactive)
        XCTAssertEqual(mapped.primaryConcerns, [.breakouts, .redness])
        XCTAssertEqual(mapped.primaryGoal, .clearerSkin)
        XCTAssertEqual(mapped.ageRange, .range25to34)
        XCTAssertEqual(mapped.stressLevel, .high)
    }

    func testScanSessionRoundTrip() {
        let session = ScanSession(
            kind: .daily,
            photos: [ScanPhoto(zone: .forehead, fileName: "test.jpg")],
            skinMap: SampleData.sampleSkinMap,
            note: "Morning scan"
        )

        let dto = FirestoreScanSessionDTO(from: session, userId: "u1")
        guard let restored = dto.toScanSession() else {
            XCTFail("Failed to restore ScanSession")
            return
        }

        XCTAssertEqual(restored.id, session.id)
        XCTAssertEqual(restored.kind, session.kind)
        XCTAssertEqual(restored.note, session.note)
    }

    func testProductRoundTrip() {
        let product = Product(
            name: "Test Serum",
            category: .serum,
            period: .evening,
            ingredients: ["Niacinamide"],
            ingredientTags: [.niacinamide],
            isActive: true,
            sortOrder: 1
        )

        let dto = FirestoreProductDTO(from: product, userId: "u1")
        let restored = dto.toProduct()

        XCTAssertEqual(restored.name, "Test Serum")
        XCTAssertEqual(restored.category, .serum)
        XCTAssertEqual(restored.period, .evening)
        XCTAssertEqual(restored.ingredientTags, [.niacinamide])
    }

    func testRoutineLogRoundTrip() {
        let entry = RoutineLogEntry(
            date: .now,
            followedRoutine: true,
            productIDs: [UUID()],
            notes: "Felt good"
        )

        let dto = FirestoreRoutineLogDTO(from: entry, userId: "u1")
        let restored = dto.toRoutineLogEntry()

        XCTAssertEqual(restored.followedRoutine, true)
        XCTAssertEqual(restored.notes, "Felt good")
    }
}
