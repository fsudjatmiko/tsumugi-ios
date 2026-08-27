import Foundation
import SwiftData

/// Intermediate schema representation for decoding bundled JSON seed items.
public struct SeedCharacterDTO: Codable, Sendable {
    public let id: String
    public let character: String
    public let romaji: String
    public let primaryMeaning: String
    public let category: WritingCategory
    public let strokeCount: Int

    public init(
        id: String,
        character: String,
        romaji: String,
        primaryMeaning: String,
        category: WritingCategory,
        strokeCount: Int
    ) {
        self.id = id
        self.character = character
        self.romaji = romaji
        self.primaryMeaning = primaryMeaning
        self.category = category
        self.strokeCount = strokeCount
    }
}

/// Service responsible for loading bundled JSON datasets and seeding SwiftData models.
public final class SeedDataLoader: Sendable {
    public static let shared = SeedDataLoader()

    public init() {}

    /// Preloads seed data asynchronously from bundled JSON resources if the database table is currently empty.
    ///
    /// - Parameters:
    ///   - context: The active `ModelContext` to check and insert into.
    ///   - bundle: The `Bundle` containing resource JSON files (defaults to `Bundle.main`).
    @MainActor
    public func preloadSeedDataIfNeeded(
        context: ModelContext,
        bundle: Bundle = .main
    ) async {
        let descriptor = FetchDescriptor<CharacterCard>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else {
            return
        }

        let resourceNames = ["hiragana", "katakana", "n5_kanji"]
        var loadedCards: [CharacterCard] = []

        for resource in resourceNames {
            if let url = bundle.url(forResource: resource, withExtension: "json") {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    let items = try decoder.decode([SeedCharacterDTO].self, from: data)

                    for item in items {
                        let card = CharacterCard(
                            id: item.id,
                            character: item.character,
                            romaji: item.romaji,
                            primaryMeaning: item.primaryMeaning,
                            category: item.category,
                            strokeCount: item.strokeCount,
                            interval: 0,
                            repetitions: 0,
                            easeFactor: 2.5,
                            nextReviewDate: Date(),
                            isUnlocked: true
                        )
                        loadedCards.append(card)
                        context.insert(card)
                    }
                } catch {
                    print("⚠️ [SeedDataLoader] Failed to decode \(resource).json: \(error)")
                }
            }
        }

        // Fallback default starter items if no JSON files could be loaded from bundle
        if loadedCards.isEmpty {
            let fallbackStarters: [(id: String, char: String, romaji: String, meaning: String, cat: WritingCategory, strokes: Int)] = [
                ("hira_a", "あ", "a", "a (vowel)", .hiragana, 3),
                ("hira_i", "い", "i", "i (vowel)", .hiragana, 2),
                ("hira_u", "う", "u", "u (vowel)", .hiragana, 2),
                ("hira_e", "え", "e", "e (vowel)", .hiragana, 2),
                ("hira_o", "お", "o", "o (vowel)", .hiragana, 3)
            ]

            for starter in fallbackStarters {
                let card = CharacterCard(
                    id: starter.id,
                    character: starter.char,
                    romaji: starter.romaji,
                    primaryMeaning: starter.meaning,
                    category: starter.cat,
                    strokeCount: starter.strokes,
                    interval: 0,
                    repetitions: 0,
                    easeFactor: 2.5,
                    nextReviewDate: Date(),
                    isUnlocked: true
                )
                context.insert(card)
            }
        }

        do {
            try context.save()
        } catch {
            print("⚠️ [SeedDataLoader] Failed to save preloaded seed items: \(error)")
        }
    }
}
