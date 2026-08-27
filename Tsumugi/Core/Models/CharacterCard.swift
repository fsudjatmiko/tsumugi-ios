import Foundation
import SwiftData

/// Represents a Japanese character (Kana or Kanji) study item with SM-2 spaced repetition state.
@Model
public final class CharacterCard {
    @Attribute(.unique) public var id: String
    public var character: String
    public var romaji: String
    public var primaryMeaning: String
    public var categoryRaw: String
    public var strokeCount: Int
    public var interval: Int
    public var repetitions: Int
    public var easeFactor: Double
    public var nextReviewDate: Date
    public var isUnlocked: Bool

    @Relationship(deleteRule: .cascade)
    public var reviewLogs: [ReviewLog] = []

    public var category: WritingCategory {
        get {
            WritingCategory(rawValue: categoryRaw) ?? .hiragana
        }
        set {
            categoryRaw = newValue.rawValue
        }
    }

    public init(
        id: String,
        character: String,
        romaji: String,
        primaryMeaning: String,
        category: WritingCategory,
        strokeCount: Int,
        interval: Int = 0,
        repetitions: Int = 0,
        easeFactor: Double = 2.5,
        nextReviewDate: Date = Date(),
        isUnlocked: Bool = true
    ) {
        self.id = id
        self.character = character
        self.romaji = romaji
        self.primaryMeaning = primaryMeaning
        self.categoryRaw = category.rawValue
        self.strokeCount = strokeCount
        self.interval = interval
        self.repetitions = repetitions
        self.easeFactor = easeFactor
        self.nextReviewDate = nextReviewDate
        self.isUnlocked = isUnlocked
        self.reviewLogs = []
    }
}
