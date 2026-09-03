import CoreGraphics
import Foundation

/// Mathematical vector and proximity validator for normalized stroke paths in spatial AR.
public struct ARStrokeValidator: Sendable {
    public init() {}

    /// Validates an array of normalized 2D points (0.0...1.0) captured during an AR surface pan gesture against an expected StrokeSegment.
    ///
    /// - Parameters:
    ///   - normalizedPoints: Array of points mapped to the character's bounding frame (0.0 to 1.0).
    ///   - expectedSegment: The target StrokeSegment for the active stroke index.
    ///   - tolerance: Distance tolerance (defaults to generous 0.32 for AR finger tracking).
    /// - Returns: Boolean indicating whether the stroke gesture accurately completed the expected segment.
    public func validate(
        normalizedPoints: [CGPoint],
        expectedSegment: StrokeSegment,
        tolerance: CGFloat = 0.32
    ) -> Bool {
        guard normalizedPoints.count >= 4 else {
            return false
        }

        guard let first = normalizedPoints.first, let last = normalizedPoints.last else {
            return false
        }

        // 1. Check start point proximity
        let startDist = distance(from: first, to: expectedSegment.startPoint)
        guard startDist <= tolerance else {
            return false
        }

        // 2. Check end point proximity
        let endDist = distance(from: last, to: expectedSegment.endPoint)
        guard endDist <= tolerance else {
            return false
        }

        // 3. Multi-point / corner knee check
        if !expectedSegment.midPoints.isEmpty {
            var lastIdx = 0
            for mid in expectedSegment.midPoints {
                var found = false
                let midTolerance = tolerance * 1.2
                for i in lastIdx..<normalizedPoints.count {
                    if distance(from: normalizedPoints[i], to: mid) <= midTolerance {
                        found = true
                        lastIdx = i
                        break
                    }
                }
                if !found {
                    return false
                }
            }
        }

        // 4. Directional vector consistency
        let userDx = last.x - first.x
        let userDy = last.y - first.y
        let expectedDx = expectedSegment.endPoint.x - expectedSegment.startPoint.x
        let expectedDy = expectedSegment.endPoint.y - expectedSegment.startPoint.y

        let dot = userDx * expectedDx + userDy * expectedDy
        guard dot > 0 else {
            return false
        }

        return true
    }

    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
}
