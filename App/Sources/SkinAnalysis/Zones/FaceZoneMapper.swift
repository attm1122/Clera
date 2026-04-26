import CoreGraphics

/// Maps detected face landmarks into the five dermatological zones used by Clera.
///
/// All returned polygons use **normalized coordinates** (0–1, UIKit top-left origin).
/// The mapping uses geometric heuristics based on the relative positions of
/// Vision framework landmarks. Zones are approximate but sufficient for
/// per-region skin analysis masking.
enum FaceZoneMapper {

    /// Returns a dictionary mapping each `SkinZone` to its polygon path.
    /// If required landmarks are missing, the dictionary may omit zones.
    static func mapZones(from landmarks: FaceLandmarkResult) -> [SkinZone: [CGPoint]] {
        guard landmarks.faceDetected else { return [:] }

        let lm = Dictionary(
            uniqueKeysWithValues: landmarks.landmarks.map { ($0.type, $0.points) }
        )

        guard let faceContour = lm[.faceContour],
              let leftEyebrow = lm[.leftEyebrow],
              let rightEyebrow = lm[.rightEyebrow],
              let leftEye = lm[.leftEye],
              let rightEye = lm[.rightEye],
              let noseCrest = lm[.noseCrest],
              let noseTip = lm[.noseTip],
              let outerLips = lm[.outerLips],
              let medianLine = lm[.medianLine] else {
            return [:]
        }

        var zones: [SkinZone: [CGPoint]] = [:]
        zones[.forehead] = makeForehead(
            contour: faceContour,
            leftBrow: leftEyebrow,
            rightBrow: rightEyebrow
        )
        zones[.nose] = makeNose(
            noseCrest: noseCrest,
            noseTip: noseTip,
            leftEye: leftEye,
            rightEye: rightEye,
            lips: outerLips
        )
        zones[.leftCheek] = makeLeftCheek(
            contour: faceContour,
            leftEye: leftEye,
            leftBrow: leftEyebrow,
            lips: outerLips,
            median: medianLine
        )
        zones[.rightCheek] = makeRightCheek(
            contour: faceContour,
            rightEye: rightEye,
            rightBrow: rightEyebrow,
            lips: outerLips,
            median: medianLine
        )
        zones[.chinJaw] = makeChinJaw(
            contour: faceContour,
            lips: outerLips
        )

        return zones
    }

    // MARK: - Forehead

    /// **Forehead** — from the top of the face contour down to the eyebrow line.
    ///
    /// The polygon is built by:
    /// 1. Taking all face-contour points that lie above the lowest eyebrow point.
    /// 2. Splitting those contour points into left and right halves.
    /// 3. Tracing from the outer left eyebrow **up** the left contour,
    ///    across the top, **down** the right contour to the outer right eyebrow,
    ///    and finally closing across the eyebrow tops.
    private static func makeForehead(
        contour: [CGPoint],
        leftBrow: [CGPoint],
        rightBrow: [CGPoint]
    ) -> [CGPoint] {
        let browBottomY = max(
            leftBrow.map(\.y).max() ?? 0,
            rightBrow.map(\.y).max() ?? 0
        ) + 0.02

        let topContour = contour.filter { $0.y <= browBottomY }
        guard !topContour.isEmpty else { return [] }

        // Split at the horizontal midpoint of the top contour so we can trace
        // the left side bottom-to-top and the right side top-to-bottom.
        let midX = topContour.map(\.x).reduce(0, +) / CGFloat(topContour.count)
        let leftSide = topContour.filter { $0.x <= midX }.sorted(by: { $0.y < $1.y })
        let rightSide = topContour.filter { $0.x > midX }.sorted(by: { $0.y > $1.y })

        let leftSorted = leftBrow.sorted(by: { $0.x < $1.x })
        let rightSorted = rightBrow.sorted(by: { $0.x < $1.x })

        var polygon: [CGPoint] = []

        if let leftOuter = leftSorted.first {
            polygon.append(leftOuter)
        }
        polygon.append(contentsOf: leftSide)
        polygon.append(contentsOf: rightSide)
        if let rightOuter = rightSorted.last {
            polygon.append(rightOuter)
        }
        // Close the bottom edge across the eyebrow tops.
        if let rightInner = rightSorted.first,
           let leftInner = leftSorted.last {
            polygon.append(rightInner)
            polygon.append(leftInner)
        }

        return polygon
    }

    // MARK: - Nose

    /// **Nose** — between the inner eye corners and above the upper lip.
    ///
    /// The polygon uses the nose crest (bridge) and nose-tip landmarks for the
    /// lateral boundaries, capped by a line between the inner eye corners at the
    /// top and the upper-lip line at the bottom.
    private static func makeNose(
        noseCrest: [CGPoint],
        noseTip: [CGPoint],
        leftEye: [CGPoint],
        rightEye: [CGPoint],
        lips: [CGPoint]
    ) -> [CGPoint] {
        let leftInner = leftEye.max(by: { $0.x < $1.x }) ?? .zero
        let rightInner = rightEye.min(by: { $0.x < $1.x }) ?? .zero
        let lipTopY = lips.map(\.y).min() ?? 0

        var nosePoints = (noseCrest + noseTip)
            .filter { $0.y <= lipTopY + 0.02 }
        nosePoints.sort(by: { $0.x < $1.x })

        return [leftInner] + nosePoints + [rightInner]
    }

    // MARK: - Left Cheek

    /// **Left Cheek** — left side of the face bounded by the eye/eyebrow level
    /// at the top, the jaw/chin at the bottom, the face contour on the left,
    /// and the median line on the right.
    ///
    /// The polygon traces down the left face contour and then back up the
    /// median-line segment. The implicit top edge (closed by Core Graphics)
    /// connects the highest median point to the highest contour point,
    /// forming a boundary just below the eye.
    private static func makeLeftCheek(
        contour: [CGPoint],
        leftEye: [CGPoint],
        leftBrow: [CGPoint],
        lips: [CGPoint],
        median: [CGPoint]
    ) -> [CGPoint] {
        let eyeBottomY = leftEye.map(\.y).max() ?? 0
        let browBottomY = leftBrow.map(\.y).max() ?? 0
        let topY = min(eyeBottomY, browBottomY) + 0.01
        let bottomY = (lips.map(\.y).max() ?? 0) + 0.03

        let leftContour = contour
            .filter { $0.x <= 0.5 && $0.y >= topY && $0.y <= bottomY }
            .sorted(by: { $0.y < $1.y })

        let medianSegment = median
            .filter { $0.y >= topY && $0.y <= bottomY }
            .sorted(by: { $0.y > $1.y })

        return leftContour + medianSegment
    }

    // MARK: - Right Cheek

    /// **Right Cheek** — mirror of the left cheek.
    private static func makeRightCheek(
        contour: [CGPoint],
        rightEye: [CGPoint],
        rightBrow: [CGPoint],
        lips: [CGPoint],
        median: [CGPoint]
    ) -> [CGPoint] {
        let eyeBottomY = rightEye.map(\.y).max() ?? 0
        let browBottomY = rightBrow.map(\.y).max() ?? 0
        let topY = min(eyeBottomY, browBottomY) + 0.01
        let bottomY = (lips.map(\.y).max() ?? 0) + 0.03

        let rightContour = contour
            .filter { $0.x >= 0.5 && $0.y >= topY && $0.y <= bottomY }
            .sorted(by: { $0.y < $1.y })

        let medianSegment = median
            .filter { $0.y >= topY && $0.y <= bottomY }
            .sorted(by: { $0.y > $1.y })

        return rightContour + medianSegment
    }

    // MARK: - Chin / Jaw

    /// **Chin / Jaw** — below the lower lip to the bottom of the face contour.
    ///
    /// The polygon uses the lower-lip landmark points as its top edge and the
    /// bottom arc of the face contour for the sides and bottom.
    private static func makeChinJaw(
        contour: [CGPoint],
        lips: [CGPoint]
    ) -> [CGPoint] {
        let lipBottomY = lips.map(\.y).max() ?? 0

        // Lower-lip points form the top boundary.
        let lipPoints = lips
            .filter { $0.y >= lipBottomY - 0.01 }
            .sorted(by: { $0.x < $1.x })

        // Bottom contour split by center so we trace down the left side
        // and back up the right side in a continuous loop.
        let bottomPoints = contour.filter { $0.y >= lipBottomY }
        let leftSide = bottomPoints
            .filter { $0.x <= 0.5 }
            .sorted(by: { $0.y < $1.y })
        let rightSide = bottomPoints
            .filter { $0.x > 0.5 }
            .sorted(by: { $0.y > $1.y })

        return lipPoints + leftSide + rightSide
    }
}
