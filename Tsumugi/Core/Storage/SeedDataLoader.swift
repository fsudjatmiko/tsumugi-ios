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

    /// Unlocks the next tier/row of characters into the user's active study deck.
    @MainActor
    public func unlockNextTier(context: ModelContext) -> Int {
        // Find locked cards in the database first
        let lockedDescriptor = FetchDescriptor<CharacterCard>(
            predicate: #Predicate<CharacterCard> { card in
                !card.isUnlocked
            }
        )

        if let lockedCards = try? context.fetch(lockedDescriptor), !lockedCards.isEmpty {
            let batch = Array(lockedCards.prefix(5))
            for card in batch {
                card.isUnlocked = true
                card.nextReviewDate = Date.now
            }
            try? context.save()
            return batch.count
        }

        // If no locked cards exist, insert the next canonical Hiragana row (K-Row: か, き, く, け, こ)
        let kRowCards: [(id: String, char: String, romaji: String, meaning: String, cat: WritingCategory, strokes: Int)] = [
            ("hira_ka", "か", "ka", "ka (syllable)", .hiragana, 3),
            ("hira_ki", "き", "ki", "ki (syllable)", .hiragana, 4),
            ("hira_ku", "く", "ku", "ku (syllable)", .hiragana, 1),
            ("hira_ke", "け", "ke", "ke (syllable)", .hiragana, 3),
            ("hira_ko", "こ", "ko", "ko (syllable)", .hiragana, 2)
        ]

        var newCount = 0
        for item in kRowCards {
            let targetId = item.id
            let existingDescriptor = FetchDescriptor<CharacterCard>(
                predicate: #Predicate<CharacterCard> { card in
                    card.id == targetId
                }
            )
            let exists = ((try? context.fetchCount(existingDescriptor)) ?? 0) > 0

            if !exists {
                let newCard = CharacterCard(
                    id: item.id,
                    character: item.char,
                    romaji: item.romaji,
                    primaryMeaning: item.meaning,
                    category: item.cat,
                    strokeCount: item.strokes,
                    interval: 0,
                    repetitions: 0,
                    easeFactor: 2.5,
                    nextReviewDate: Date.now,
                    isUnlocked: true
                )
                context.insert(newCard)
                newCount += 1
            }
        }

        try? context.save()
        return newCount
    }
}
