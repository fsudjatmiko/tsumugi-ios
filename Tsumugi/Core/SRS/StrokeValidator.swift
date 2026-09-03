import CoreGraphics
import Foundation

/// Pure Swift validator for calculating gesture accuracy against canonical character stroke trajectories.
public struct StrokeValidator: Sendable {
    public enum ValidationResult: Sendable, Equatable {
        case perfect
        case acceptable
        case wrongDirection
        case missedPath
        case tooShort

        public var isSuccess: Bool {
            self == .perfect || self == .acceptable
        }
    }

    public init() {}

    /// Validates a user-drawn stroke against an expected CharacterStroke.
    ///
    /// - Parameters:
    ///   - userPoints: Raw points captured from the canvas drag gesture.
    ///   - canvasSize: Size of the drawing canvas in points.
    ///   - expectedStroke: The ideal canonical stroke trajectory.
    ///   - tolerance: Normalized distance tolerance (defaults to 0.26 for finger drawing).
    /// - Returns: `ValidationResult` indicating accuracy.
    public func validateStroke(
        userPoints: [CGPoint],
        canvasSize: CGSize,
        expectedStroke: CharacterStroke,
        tolerance: CGFloat = 0.26
    ) -> ValidationResult {
        guard userPoints.count >= 3 else {
            return .tooShort
        }
        guard canvasSize.width > 0, canvasSize.height > 0 else {
            return .missedPath
        }

        // Normalize user points into 0.0...1.0 coordinate space
        let normalizedUserPoints = userPoints.map { pt in
            CGPoint(
                x: max(0.0, min(1.0, pt.x / canvasSize.width)),
                y: max(0.0, min(1.0, pt.y / canvasSize.height))
            )
        }

        guard let firstUserPoint = normalizedUserPoints.first,
              let lastUserPoint = normalizedUserPoints.last else {
            return .missedPath
        }

        let effectiveTolerance = max(tolerance, 0.25)
        let startRadius = max(0.18, effectiveTolerance * 0.70)

        // 1. Start Proximity Check (15-18% radius)
        let startDistance = expectedStroke.distanceToStart(from: firstUserPoint)
        guard startDistance <= startRadius else {
            // Check if user drew backwards (started near the end point)
            let reversedStartDistance = expectedStroke.distanceToEnd(from: firstUserPoint)
            if reversedStartDistance <= startRadius {
                return .wrongDirection
            }
            return .missedPath
        }

        // 2. End Proximity Check
        let endDistance = expectedStroke.distanceToEnd(from: lastUserPoint)
        guard endDistance <= effectiveTolerance else {
            return .missedPath
        }

        // 3. Directional Flow Check
        // If the user's end point is closer to the start than the end, it's backwards
        let reversedEndDistance = expectedStroke.distanceToStart(from: lastUserPoint)
        if reversedEndDistance < endDistance {
            return .wrongDirection
        }

        // 4. Intermediate Checkpoint Traversal in Sequential Order
        let midPoints = expectedStroke.midPoints
        if !midPoints.isEmpty {
            var lastFoundIndex = 0
            for checkpoint in midPoints {
                var found = false
                let checkpointTolerance = effectiveTolerance * 1.25
                for i in lastFoundIndex..<normalizedUserPoints.count {
                    if distance(from: normalizedUserPoints[i], to: checkpoint) <= checkpointTolerance {
                        found = true
                        lastFoundIndex = i
                        break
                    }
                }
                if !found {
                    return .missedPath
                }
            }
        }

        // 5. Corridor Compliance Check (at least 70% in trajectory corridor)
        var pointsInCorridor = 0
        for pt in normalizedUserPoints {
            if expectedStroke.isPointNearTrajectory(pt, threshold: effectiveTolerance) {
                pointsInCorridor += 1
            }
        }

        let corridorRatio = Double(pointsInCorridor) / Double(normalizedUserPoints.count)
        guard corridorRatio >= 0.70 else {
            return .missedPath
        }

        // Grade precision
        if startDistance < (startRadius * 0.6) && endDistance < (effectiveTolerance * 0.6) && corridorRatio >= 0.85 {
            return .perfect
        } else {
            return .acceptable
        }
    }

    /// Backward-compatible overload for StrokeSegment
    public func validateStroke(
        userPoints: [CGPoint],
        canvasSize: CGSize,
        expectedSegment: StrokeSegment,
        tolerance: CGFloat = 0.26
    ) -> ValidationResult {
        validateStroke(
            userPoints: userPoints,
            canvasSize: canvasSize,
            expectedStroke: expectedSegment.characterStroke,
            tolerance: tolerance
        )
    }

    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
}
