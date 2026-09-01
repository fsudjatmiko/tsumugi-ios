import CoreGraphics
import Foundation

/// Pure Swift validator for calculating gesture accuracy against normalized StrokeGuides.
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

    /// Validates a user-drawn stroke against an expected StrokeSegment.
    ///
    /// - Parameters:
    ///   - userPoints: Raw points captured from the canvas drag gesture.
    ///   - canvasSize: Size of the drawing canvas in points.
    ///   - expectedSegment: The ideal normalized stroke segment.
    ///   - tolerance: Normalized distance tolerance (defaults to 0.28 for finger drawing).
    /// - Returns: `ValidationResult` indicating accuracy.
    public func validateStroke(
        userPoints: [CGPoint],
        canvasSize: CGSize,
        expectedSegment: StrokeSegment,
        tolerance: CGFloat = 0.28
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

        // Expanded start/end bounding box tolerance for comfortable touch drawing (0.28 standard, up to 0.32)
        let effectiveTolerance = max(tolerance, 0.28)

        // 1. Check start point proximity
        let startDistance = distance(from: firstUserPoint, to: expectedSegment.startPoint)
        guard startDistance <= effectiveTolerance else {
            // Check if user drew backwards (started at end point)
            let reversedStartDistance = distance(from: firstUserPoint, to: expectedSegment.endPoint)
            if reversedStartDistance <= effectiveTolerance {
                return .wrongDirection
            }
            return .missedPath
        }

        // 2. Check end point proximity
        let endDistance = distance(from: lastUserPoint, to: expectedSegment.endPoint)
        guard endDistance <= effectiveTolerance else {
            return .missedPath
        }

        // 3. Multi-segment / Angled / Knee Validation
        // If the stroke has intermediate corner / mid points (e.g., Katakana 'ア', 'フ', 'マ', 'ワ')
        if !expectedSegment.midPoints.isEmpty {
            // User path must pass near each intermediate vertex in sequence
            var lastFoundIndex = 0
            for midPoint in expectedSegment.midPoints {
                // Find if any user point from lastFoundIndex onward is within tolerance of this corner vertex
                var vertexFound = false
                let vertexTolerance = effectiveTolerance * 1.15 // slightly more generous around sharp bends

                for i in lastFoundIndex..<normalizedUserPoints.count {
                    if distance(from: normalizedUserPoints[i], to: midPoint) <= vertexTolerance {
                        vertexFound = true
                        lastFoundIndex = i
                        break
                    }
                }

                // If user completely skipped the knee/corner of an angled stroke (e.g. cutting straight across diagonally)
                if !vertexFound {
                    return .missedPath
                }
            }

            // Grade precision for multi-segment
            if startDistance < (effectiveTolerance * 0.6) && endDistance < (effectiveTolerance * 0.6) {
                return .perfect
            } else {
                return .acceptable
            }
        }

        // 4. Directional vector validation for single straight/curved segments
        let userVector = CGVector(
            dx: lastUserPoint.x - firstUserPoint.x,
            dy: lastUserPoint.y - firstUserPoint.y
        )
        let expectedVector = CGVector(
            dx: expectedSegment.endPoint.x - expectedSegment.startPoint.x,
            dy: expectedSegment.endPoint.y - expectedSegment.startPoint.y
        )

        let dotProduct = userVector.dx * expectedVector.dx + userVector.dy * expectedVector.dy
        // Angular tolerance (cos(theta) > 0 covers up to 90 degrees; ensures general stroke progression direction)
        guard dotProduct > 0 else {
            return .wrongDirection
        }

        // 5. Grade precision (Perfect vs Acceptable)
        if startDistance < (effectiveTolerance * 0.55) && endDistance < (effectiveTolerance * 0.55) {
            return .perfect
        } else {
            return .acceptable
        }
    }

    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
}
