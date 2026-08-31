import CoreGraphics
import Foundation

/// Represents a single normalized stroke path for character tracing.
public struct StrokeSegment: Sendable, Equatable {
    public let strokeNumber: Int
    /// Normalized start point (0.0 to 1.0)
    public let startPoint: CGPoint
    /// Normalized intermediate guide points
    public let midPoints: [CGPoint]
    /// Normalized end point (0.0 to 1.0)
    public let endPoint: CGPoint

    public init(
        strokeNumber: Int,
        startPoint: CGPoint,
        midPoints: [CGPoint] = [],
        endPoint: CGPoint
    ) {
        self.strokeNumber = strokeNumber
        self.startPoint = startPoint
        self.midPoints = midPoints
        self.endPoint = endPoint
    }

    /// Full sequence of points along the ideal stroke guide
    public var allPoints: [CGPoint] {
        [startPoint] + midPoints + [endPoint]
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

    public var strokeCount: Int {
        strokes.count
    }

    // MARK: - Pre-configured Starter Hiragana Vowels & K-Row Guides

    public static let guides: [String: StrokeGuide] = [
        // Vowels
        "あ": StrokeGuide(
            character: "あ",
            strokes: [
                StrokeSegment(strokeNumber: 1, startPoint: CGPoint(x: 0.25, y: 0.32), midPoints: [CGPoint(x: 0.50, y: 0.32)], endPoint: CGPoint(x: 0.75, y: 0.32)),
                StrokeSegment(strokeNumber: 2, startPoint: CGPoint(x: 0.50, y: 0.18), midPoints: [CGPoint(x: 0.49, y: 0.50)], endPoint: CGPoint(x: 0.46, y: 0.82)),
                StrokeSegment(strokeNumber: 3, startPoint: CGPoint(x: 0.65, y: 0.45), midPoints: [CGPoint(x: 0.32, y: 0.65), CGPoint(x: 0.48, y: 0.85), CGPoint(x: 0.78, y: 0.65)], endPoint: CGPoint(x: 0.35, y: 0.60))
            ]
        ),
        "い": StrokeGuide(
            character: "い",
            strokes: [
                StrokeSegment(strokeNumber: 1, startPoint: CGPoint(x: 0.32, y: 0.28), midPoints: [CGPoint(x: 0.30, y: 0.55)], endPoint: CGPoint(x: 0.38, y: 0.75)),
                StrokeSegment(strokeNumber: 2, startPoint: CGPoint(x: 0.70, y: 0.35), midPoints: [CGPoint(x: 0.72, y: 0.50)], endPoint: CGPoint(x: 0.68, y: 0.65))
            ]
        ),
        "う": StrokeGuide(
            character: "う",
            strokes: [
                StrokeSegment(strokeNumber: 1, startPoint: CGPoint(x: 0.46, y: 0.22), midPoints: [CGPoint(x: 0.52, y: 0.26)], endPoint: CGPoint(x: 0.58, y: 0.30)),
                StrokeSegment(strokeNumber: 2, startPoint: CGPoint(x: 0.38, y: 0.42), midPoints: [CGPoint(x: 0.68, y: 0.45), CGPoint(x: 0.65, y: 0.70)], endPoint: CGPoint(x: 0.38, y: 0.82))
            ]
        ),
        "え": StrokeGuide(
            character: "え",
            strokes: [
                StrokeSegment(strokeNumber: 1, startPoint: CGPoint(x: 0.48, y: 0.20), midPoints: [CGPoint(x: 0.52, y: 0.24)], endPoint: CGPoint(x: 0.56, y: 0.28)),
                StrokeSegment(strokeNumber: 2, startPoint: CGPoint(x: 0.35, y: 0.40), midPoints: [CGPoint(x: 0.65, y: 0.38), CGPoint(x: 0.38, y: 0.65), CGPoint(x: 0.68, y: 0.62)], endPoint: CGPoint(x: 0.68, y: 0.80))
            ]
        ),
        "お": StrokeGuide(
            character: "お",
            strokes: [
                StrokeSegment(strokeNumber: 1, startPoint: CGPoint(x: 0.25, y: 0.30), midPoints: [CGPoint(x: 0.48, y: 0.30)], endPoint: CGPoint(x: 0.70, y: 0.30)),
                StrokeSegment(strokeNumber: 2, startPoint: CGPoint(x: 0.48, y: 0.18), midPoints: [CGPoint(x: 0.48, y: 0.55), CGPoint(x: 0.30, y: 0.68), CGPoint(x: 0.65, y: 0.75)], endPoint: CGPoint(x: 0.62, y: 0.58)),
                StrokeSegment(strokeNumber: 3, startPoint: CGPoint(x: 0.72, y: 0.36), midPoints: [CGPoint(x: 0.76, y: 0.42)], endPoint: CGPoint(x: 0.80, y: 0.48))
            ]
        ),
        // K-Row
        "か": StrokeGuide(
            character: "か",
            strokes: [
                StrokeSegment(strokeNumber: 1, startPoint: CGPoint(x: 0.30, y: 0.28), midPoints: [CGPoint(x: 0.52, y: 0.28), CGPoint(x: 0.45, y: 0.75)], endPoint: CGPoint(x: 0.38, y: 0.70)),
                StrokeSegment(strokeNumber: 2, startPoint: CGPoint(x: 0.42, y: 0.18), midPoints: [CGPoint(x: 0.30, y: 0.55)], endPoint: CGPoint(x: 0.22, y: 0.75)),
                StrokeSegment(strokeNumber: 3, startPoint: CGPoint(x: 0.65, y: 0.30), midPoints: [CGPoint(x: 0.72, y: 0.38)], endPoint: CGPoint(x: 0.76, y: 0.45))
            ]
        ),
        "き": StrokeGuide(
            character: "き",
            strokes: [
                StrokeSegment(strokeNumber: 1, startPoint: CGPoint(x: 0.30, y: 0.30), midPoints: [CGPoint(x: 0.50, y: 0.30)], endPoint: CGPoint(x: 0.70, y: 0.30)),
                StrokeSegment(strokeNumber: 2, startPoint: CGPoint(x: 0.28, y: 0.45), midPoints: [CGPoint(x: 0.50, y: 0.45)], endPoint: CGPoint(x: 0.72, y: 0.45)),
                StrokeSegment(strokeNumber: 3, startPoint: CGPoint(x: 0.55, y: 0.18), midPoints: [CGPoint(x: 0.45, y: 0.60)], endPoint: CGPoint(x: 0.35, y: 0.65)),
                StrokeSegment(strokeNumber: 4, startPoint: CGPoint(x: 0.35, y: 0.72), midPoints: [CGPoint(x: 0.55, y: 0.82)], endPoint: CGPoint(x: 0.65, y: 0.75))
            ]
        ),
        "く": StrokeGuide(
            character: "く",
            strokes: [
                StrokeSegment(strokeNumber: 1, startPoint: CGPoint(x: 0.65, y: 0.25), midPoints: [CGPoint(x: 0.32, y: 0.50)], endPoint: CGPoint(x: 0.68, y: 0.78))
            ]
        ),
        "け": StrokeGuide(
            character: "け",
            strokes: [
                StrokeSegment(strokeNumber: 1, startPoint: CGPoint(x: 0.28, y: 0.20), midPoints: [CGPoint(x: 0.26, y: 0.55)], endPoint: CGPoint(x: 0.32, y: 0.80)),
                StrokeSegment(strokeNumber: 2, startPoint: CGPoint(x: 0.48, y: 0.35), midPoints: [CGPoint(x: 0.68, y: 0.35)], endPoint: CGPoint(x: 0.80, y: 0.35)),
                StrokeSegment(strokeNumber: 3, startPoint: CGPoint(x: 0.62, y: 0.18), midPoints: [CGPoint(x: 0.62, y: 0.55)], endPoint: CGPoint(x: 0.58, y: 0.82))
            ]
        ),
        "こ": StrokeGuide(
            character: "こ",
            strokes: [
                StrokeSegment(strokeNumber: 1, startPoint: CGPoint(x: 0.32, y: 0.32), midPoints: [CGPoint(x: 0.55, y: 0.32)], endPoint: CGPoint(x: 0.70, y: 0.36)),
                StrokeSegment(strokeNumber: 2, startPoint: CGPoint(x: 0.30, y: 0.68), midPoints: [CGPoint(x: 0.55, y: 0.70)], endPoint: CGPoint(x: 0.72, y: 0.65))
            ]
        )
    ]

    /// Default fallback generator for unmapped characters
    public static func defaultGuide(for character: String, strokeCount: Int) -> StrokeGuide {
        if let guide = guides[character] {
            return guide
        }

        var strokes: [StrokeSegment] = []
        let safeCount = max(1, strokeCount)
        for i in 1...safeCount {
            let yFraction = Double(i) / Double(safeCount + 1)
            strokes.append(
                StrokeSegment(
                    strokeNumber: i,
                    startPoint: CGPoint(x: 0.25, y: yFraction),
                    midPoints: [CGPoint(x: 0.50, y: yFraction)],
                    endPoint: CGPoint(x: 0.75, y: yFraction)
                )
            )
        }
        return StrokeGuide(character: character, strokes: strokes)
    }
}
