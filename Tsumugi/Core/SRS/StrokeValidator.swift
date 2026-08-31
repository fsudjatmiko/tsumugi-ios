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

        // 1. Check start point proximity
        let startDistance = distance(from: firstUserPoint, to: expectedSegment.startPoint)
        guard startDistance <= tolerance else {
            // Check if user drew backwards (started at end point)
            let reversedStartDistance = distance(from: firstUserPoint, to: expectedSegment.endPoint)
            if reversedStartDistance <= tolerance {
                return .wrongDirection
            }
            return .missedPath
        }

        // 2. Check end point proximity
        let endDistance = distance(from: lastUserPoint, to: expectedSegment.endPoint)
        guard endDistance <= tolerance else {
            return .missedPath
        }

        // 3. Directional vector validation
        let userVector = CGVector(
            dx: lastUserPoint.x - firstUserPoint.x,
            dy: lastUserPoint.y - firstUserPoint.y
        )
        let expectedVector = CGVector(
            dx: expectedSegment.endPoint.x - expectedSegment.startPoint.x,
            dy: expectedSegment.endPoint.y - expectedSegment.startPoint.y
        )

        let dotProduct = userVector.dx * expectedVector.dx + userVector.dy * expectedVector.dy
        guard dotProduct > 0 else {
            return .wrongDirection
        }

        // 4. Grade precision (Perfect vs Acceptable)
        if startDistance < (tolerance * 0.55) && endDistance < (tolerance * 0.55) {
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
