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

    // Rich Kanji Metadata (Optional / Defaults for backwards compatibility)
    public var onyxomi: [String] = []
    public var kunyomi: [String] = []
    public var clusterCategory: String? = nil
    public var gradeLevel: Int? = nil
    public var jlptLevel: String? = nil
    public var radicals: [String] = []
    public var examplesJSON: String? = nil

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

    /// Decodes compound vocabulary examples from stored JSON
    public var compoundExamples: [KanjiExample] {
        guard let json = examplesJSON, let data = json.data(using: .utf8) else {
            return []
        }
        return (try? JSONDecoder().decode([KanjiExample].self, from: data)) ?? []
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
        isUnlocked: Bool = true,
        onyomi: [String] = [],
        kunyomi: [String] = [],
        clusterCategory: String? = nil,
        gradeLevel: Int? = nil,
        jlptLevel: String? = nil,
        radicals: [String] = [],
        examples: [KanjiExample] = []
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
        self.onyxomi = onyomi
        self.kunyomi = kunyomi
        self.clusterCategory = clusterCategory
        self.gradeLevel = gradeLevel
        self.jlptLevel = jlptLevel
        self.radicals = radicals

        if !examples.isEmpty, let data = try? JSONEncoder().encode(examples) {
            self.examplesJSON = String(data: data, encoding: .utf8)
        } else {
            self.examplesJSON = nil
        }
        self.reviewLogs = []
    }
}
