import CoreGraphics
import Foundation

/// Represents a single normalized point in standard unit space (0.0 to 1.0).
public struct StrokePoint: Codable, Sendable, Equatable, Hashable {
    public let x: CGFloat
    public let y: CGFloat

    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    public init(_ cgPoint: CGPoint) {
        self.x = cgPoint.x
        self.y = cgPoint.y
    }

    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

/// Calligraphic termination type for Japanese stroke endings.
public enum StrokeType: String, Codable, Sendable {
    case tome   // Firm stop / hold
    case hane   // Hook / upward flick
    case harai  // Graceful release / sweeping taper
}

/// A structured character stroke with high-fidelity checkpoint trajectory coordinates and stroke styling.
public struct CharacterStroke: Codable, Sendable, Equatable {
    public let order: Int
    public let pathPoints: [StrokePoint]
    public let strokeType: StrokeType

    public init(order: Int, pathPoints: [StrokePoint], strokeType: StrokeType = .tome) {
        self.order = order
        self.pathPoints = pathPoints
        self.strokeType = strokeType
    }

    public var startPoint: CGPoint {
        pathPoints.first?.cgPoint ?? .zero
    }

    public var endPoint: CGPoint {
        pathPoints.last?.cgPoint ?? .zero
    }

    public var midPoints: [CGPoint] {
        guard pathPoints.count > 2 else { return [] }
        return pathPoints.dropFirst().dropLast().map(\.cgPoint)
    }

    public var allPoints: [CGPoint] {
        pathPoints.map(\.cgPoint)
    }

    // MARK: - Geometric Tolerance Helpers

    /// Distance from a test point to the start of this stroke.
    public func distanceToStart(from point: CGPoint) -> CGFloat {
        let start = startPoint
        let dx = point.x - start.x
        let dy = point.y - start.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Distance from a test point to the end of this stroke.
    public func distanceToEnd(from point: CGPoint) -> CGFloat {
        let end = endPoint
        let dx = point.x - end.x
        let dy = point.y - end.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Determines if a test point lies within a distance threshold of the stroke path polyline corridor.
    public func isPointNearTrajectory(_ point: CGPoint, threshold: CGFloat) -> Bool {
        guard pathPoints.count >= 2 else {
            return distanceToStart(from: point) <= threshold
        }

        let pts = allPoints
        for i in 0..<(pts.count - 1) {
            let dist = distanceToSegment(p: point, v: pts[i], w: pts[i + 1])
            if dist <= threshold {
                return true
            }
        }
        return false
    }

    private func distanceToSegment(p: CGPoint, v: CGPoint, w: CGPoint) -> CGFloat {
        let l2 = (v.x - w.x) * (v.x - w.x) + (v.y - w.y) * (v.y - w.y)
        if l2 == 0 {
            let dx = p.x - v.x
            let dy = p.y - v.y
            return sqrt(dx * dx + dy * dy)
        }
        var t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2
        t = max(0, min(1, t))
        let projX = v.x + t * (w.x - v.x)
        let projY = v.y + t * (w.y - v.y)
        let dx = p.x - projX
        let dy = p.y - projY
        return sqrt(dx * dx + dy * dy)
    }
}

/// Backward-compatible bridge structure for StrokeSegment representing a single stroke path.
public struct StrokeSegment: Sendable, Equatable {
    public let strokeNumber: Int
    public let startPoint: CGPoint
    public let midPoints: [CGPoint]
    public let endPoint: CGPoint
    public let strokeType: StrokeType

    public init(
        strokeNumber: Int,
        startPoint: CGPoint,
        midPoints: [CGPoint] = [],
        endPoint: CGPoint,
        strokeType: StrokeType = .tome
    ) {
        self.strokeNumber = strokeNumber
        self.startPoint = startPoint
        self.midPoints = midPoints
        self.endPoint = endPoint
        self.strokeType = strokeType
    }

    public init(_ characterStroke: CharacterStroke) {
        self.strokeNumber = characterStroke.order
        self.startPoint = characterStroke.startPoint
        self.midPoints = characterStroke.midPoints
        self.endPoint = characterStroke.endPoint
        self.strokeType = characterStroke.strokeType
    }

    public var allPoints: [CGPoint] {
        [startPoint] + midPoints + [endPoint]
    }

    public var characterStroke: CharacterStroke {
        CharacterStroke(
            order: strokeNumber,
            pathPoints: allPoints.map { StrokePoint($0) },
            strokeType: strokeType
        )
    }
}

/// Stroke guide containing all ordered strokes for a Japanese character.
public struct StrokeGuide: Sendable {
    public let character: String
    public let strokes: [StrokeSegment]

    public init(character: String, strokes: [StrokeSegment]) {
        self.character = character
        self.strokes = strokes
    }

    public init(character: String, characterStrokes: [CharacterStroke]) {
        self.character = character
        self.strokes = characterStrokes.map { StrokeSegment($0) }
    }

    public var strokeCount: Int {
        strokes.count
    }

    public var characterStrokes: [CharacterStroke] {
        strokes.map(\.characterStroke)
    }

    /// Access the pre-registered stroke guides or compute fallback
    public static var guides: [String: StrokeGuide] {
        StrokeGuideData.shared.allGuides
    }

    /// Default generator resolving curated curves for Kana and foundational Kanji
    public static func defaultGuide(for character: String, strokeCount: Int) -> StrokeGuide {
        StrokeGuideData.shared.guide(for: character, strokeCount: strokeCount)
    }
}
