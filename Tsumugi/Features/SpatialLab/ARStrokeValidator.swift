import CoreGraphics
import Foundation

/// Mathematical vector and path-conforming corridor validator for normalized stroke paths in spatial AR.
public struct ARStrokeValidator: Sendable {
    public init() {}

    /// Validates an array of normalized 2D points (0.0...1.0) captured during an AR surface pan gesture against an expected CharacterStroke.
    ///
    /// - Parameters:
    ///   - normalizedPoints: Array of points mapped to the character's bounding frame (0.0 to 1.0).
    ///   - expectedStroke: The target CharacterStroke with canonical checkpoints and termination type.
    ///   - startRadius: Origin zone tolerance (15% by default).
    ///   - corridorTolerance: Polyline corridor tolerance (generous 0.28 for AR finger raycasting).
    ///   - minCorridorCompliance: Minimum fraction of points that must align with the target path corridor (70% standard).
    /// - Returns: Boolean indicating whether the gesture conformed to the target trajectory.
    public func validate(
        normalizedPoints: [CGPoint],
        expectedStroke: CharacterStroke,
        startRadius: CGFloat = 0.18,
        corridorTolerance: CGFloat = 0.28,
        minCorridorCompliance: Double = 0.65
    ) -> Bool {
        guard normalizedPoints.count >= 4 else {
            return false
        }

        guard let first = normalizedPoints.first, let last = normalizedPoints.last else {
            return false
        }

        // 1. Start Proximity Check: Touch must originate near designated origin (15-18% radius)
        let startDist = expectedStroke.distanceToStart(from: first)
        guard startDist <= startRadius else {
            return false
        }

        // 2. End Proximity Check: Touch-up must occur within end-zone
        let endDist = expectedStroke.distanceToEnd(from: last)
        guard endDist <= corridorTolerance else {
            return false
        }

        // 3. Directional Flow & Sequential Checkpoints:
        // Reject reverse strokes by checking distance from start to end vs end to start
        let reverseStartDist = expectedStroke.distanceToEnd(from: first)
        let reverseEndDist = expectedStroke.distanceToStart(from: last)
        if reverseStartDist < startDist && reverseEndDist < endDist {
            return false
        }

        // Must traverse intermediate checkpoints in forward order
        let midPoints = expectedStroke.midPoints
        if !midPoints.isEmpty {
            var lastMatchedIndex = 0
            for checkpoint in midPoints {
                var checkpointFound = false
                for i in lastMatchedIndex..<normalizedPoints.count {
                    let d = distance(from: normalizedPoints[i], to: checkpoint)
                    if d <= corridorTolerance * 1.25 {
                        checkpointFound = true
                        lastMatchedIndex = i
                        break
                    }
                }
                if !checkpointFound {
                    return false
                }
            }
        }

        // 4. Path Corridor Compliance: At least 65-70% of drawn points must be within corridor
        var pointsInCorridor = 0
        for pt in normalizedPoints {
            if expectedStroke.isPointNearTrajectory(pt, threshold: corridorTolerance) {
                pointsInCorridor += 1
            }
        }

        let complianceRatio = Double(pointsInCorridor) / Double(normalizedPoints.count)
        guard complianceRatio >= minCorridorCompliance else {
            return false
        }

        return true
    }

    /// Backward-compatible overload for StrokeSegment
    public func validate(
        normalizedPoints: [CGPoint],
        expectedSegment: StrokeSegment,
        tolerance: CGFloat = 0.28
    ) -> Bool {
        validate(
            normalizedPoints: normalizedPoints,
            expectedStroke: expectedSegment.characterStroke,
            startRadius: max(0.18, tolerance * 0.6),
            corridorTolerance: tolerance,
            minCorridorCompliance: 0.65
        )
    }

    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
}
