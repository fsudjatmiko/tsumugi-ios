import CoreGraphics
import Foundation

/// Provider of canonical stroke guides for all 46 basic Hiragana, 46 basic Katakana, and 80 Grade 1 foundational Kanji.
public final class StrokeGuideData: @unchecked Sendable {
    public static let shared = StrokeGuideData()

    private var cache: [String: StrokeGuide] = [:]
    private let lock = NSLock()

    public init() {
        loadAllCanonicalGuides()
    }

    /// Access all pre-parsed stroke guides.
    public var allGuides: [String: StrokeGuide] {
        lock.lock()
        defer { lock.unlock() }
        return cache
    }

    /// Returns the canonical stroke guide for a character, or dynamically generates an interpolated fallback.
    public func guide(for character: String, strokeCount: Int) -> StrokeGuide {
        lock.lock()
        if let existing = cache[character] {
            lock.unlock()
            return existing
        }
        lock.unlock()

        // Fallback: Generate sequential curved stroke trajectory
        let safeCount = max(1, strokeCount)
        var strokes: [CharacterStroke] = []

        for i in 1...safeCount {
            let yFraction = Double(i) / Double(safeCount + 1)
            let yBase = CGFloat(yFraction)
            let pts: [StrokePoint] = [
                StrokePoint(x: 0.22, y: yBase),
                StrokePoint(x: 0.35, y: yBase + 0.01),
                StrokePoint(x: 0.50, y: yBase),
                StrokePoint(x: 0.65, y: yBase - 0.01),
                StrokePoint(x: 0.78, y: yBase)
            ]
            strokes.append(CharacterStroke(order: i, pathPoints: pts, strokeType: .tome))
        }

        let fallbackGuide = StrokeGuide(character: character, characterStrokes: strokes)
        lock.lock()
        cache[character] = fallbackGuide
        lock.unlock()
        return fallbackGuide
    }

    // MARK: - Private Parser

    private func loadAllCanonicalGuides() {
        let jsonChunks = [
            StrokeDataHiragana.jsonString,
            StrokeDataKatakana.jsonString,
            StrokeDataKanji1.jsonString,
            StrokeDataKanji2.jsonString
        ]

        for chunk in jsonChunks {
            guard let data = chunk.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: [[Any]]] else {
                continue
            }

            for (char, strokeList) in dict {
                var strokes: [CharacterStroke] = []
                for item in strokeList {
                    guard item.count >= 3,
                          let order = item[0] as? Int,
                          let typeRaw = item[1] as? Int,
                          let coords = item[2] as? [Double] else {
                        continue
                    }

                    var pts: [StrokePoint] = []
                    var idx = 0
                    while idx + 1 < coords.count {
                        pts.append(StrokePoint(x: CGFloat(coords[idx]), y: CGFloat(coords[idx + 1])))
                        idx += 2
                    }

                    let strokeType: StrokeType
                    switch typeRaw {
                    case 1: strokeType = .hane
                    case 2: strokeType = .harai
                    default: strokeType = .tome
                    }

                    strokes.append(CharacterStroke(order: order, pathPoints: pts, strokeType: strokeType))
                }

                if !strokes.isEmpty {
                    cache[char] = StrokeGuide(character: char, characterStrokes: strokes)
                }
            }
        }
    }
}
