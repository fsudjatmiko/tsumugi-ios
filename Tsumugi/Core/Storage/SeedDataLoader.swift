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
    public let rowCategory: String?
    public let isUnlocked: Bool?

    public init(
        id: String,
        character: String,
        romaji: String,
        primaryMeaning: String,
        category: WritingCategory,
        strokeCount: Int,
        rowCategory: String? = nil,
        isUnlocked: Bool? = nil
    ) {
        self.id = id
        self.character = character
        self.romaji = romaji
        self.primaryMeaning = primaryMeaning
        self.category = category
        self.strokeCount = strokeCount
        self.rowCategory = rowCategory
        self.isUnlocked = isUnlocked
    }
}

/// Service responsible for loading bundled datasets, seeding the 80 Grade 1 Kanji, and managing progressive tier unlocks.
public final class SeedDataLoader: Sendable {
    public static let shared = SeedDataLoader()

    public init() {}

    /// Preloads or backfills seed data (Hiragana, Katakana, and all 80 Grade 1 Kanji) without duplicating existing records.
    @MainActor
    public func preloadSeedDataIfNeeded(
        context: ModelContext,
        bundle: Bundle = .main
    ) async {
        // Fetch all existing cards from the database
        let existingDescriptor = FetchDescriptor<CharacterCard>()
        let existingCards = (try? context.fetch(existingDescriptor)) ?? []
        let existingIDs = Set(existingCards.map(\.id))
        let existingChars = Set(existingCards.map(\.character))
        let cardMapByID = Dictionary(uniqueKeysWithValues: existingCards.map { ($0.id, $0) })

        var insertedCount = 0
        var updatedCount = 0

        // 1. Seed Hiragana and Katakana from JSON resources
        let resourceNames = ["hiragana", "katakana"]
        for resource in resourceNames {
            if let url = bundle.url(forResource: resource, withExtension: "json") {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    let items = try decoder.decode([SeedCharacterDTO].self, from: data)

                    for item in items {
                        guard !existingIDs.contains(item.id) && !existingChars.contains(item.character) else {
                            continue
                        }

                        let unlocked = item.isUnlocked ?? (item.rowCategory == "A-row" || item.rowCategory == "K-row" || item.id.hasPrefix("hira_a") || item.id.hasPrefix("hira_i") || item.id.hasPrefix("hira_u") || item.id.hasPrefix("hira_e") || item.id.hasPrefix("hira_o") || item.id.hasPrefix("hira_k") || item.id.hasPrefix("kata_a") || item.id.hasPrefix("kata_i") || item.id.hasPrefix("kata_u") || item.id.hasPrefix("kata_e") || item.id.hasPrefix("kata_o") || item.id.hasPrefix("kata_k"))

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
                            nextReviewDate: Date.now,
                            isUnlocked: unlocked
                        )
                        context.insert(card)
                        insertedCount += 1
                    }
                } catch {
                    print("⚠️ [SeedDataLoader] Failed to decode \(resource).json: \(error)")
                }
            }
        }

        // 2. Seed / Backfill Complete 80 Grade 1 Kanji
        for rawKanji in KanjiGrade1Dataset.all80 {
            if let existingCard = cardMapByID[rawKanji.id] ?? existingCards.first(where: { $0.character == rawKanji.character && $0.category == .kanji }) {
                // Enrich existing card with rich Kanji metadata if not present
                if existingCard.onyxomi.isEmpty || existingCard.clusterCategory == nil {
                    existingCard.onyxomi = rawKanji.onyomi
                    existingCard.kunyomi = rawKanji.kunyomi
                    existingCard.clusterCategory = rawKanji.category
                    existingCard.gradeLevel = rawKanji.gradeLevel
                    existingCard.jlptLevel = rawKanji.jlptLevel
                    existingCard.radicals = rawKanji.radicals
                    if let data = try? JSONEncoder().encode(rawKanji.examples) {
                        existingCard.examplesJSON = String(data: data, encoding: .utf8)
                    }
                    updatedCount += 1
                }
            } else {
                // Primary romaji representation from first kunyomi or onyomi
                let primaryRomaji = rawKanji.kunyomi.first ?? rawKanji.onyomi.first ?? ""

                let card = CharacterCard(
                    id: rawKanji.id,
                    character: rawKanji.character,
                    romaji: primaryRomaji,
                    primaryMeaning: rawKanji.meaning,
                    category: .kanji,
                    strokeCount: rawKanji.strokeCount,
                    interval: 0,
                    repetitions: 0,
                    easeFactor: 2.5,
                    nextReviewDate: Date.now,
                    isUnlocked: rawKanji.isUnlocked,
                    onyomi: rawKanji.onyomi,
                    kunyomi: rawKanji.kunyomi,
                    clusterCategory: rawKanji.category,
                    gradeLevel: rawKanji.gradeLevel,
                    jlptLevel: rawKanji.jlptLevel,
                    radicals: rawKanji.radicals,
                    examples: rawKanji.examples
                )
                context.insert(card)
                insertedCount += 1
            }
        }

        // Fallback default starter kana items if database was completely empty and no JSON was bundled
        if existingIDs.isEmpty && insertedCount == 0 {
            let fallbackStarters: [(id: String, char: String, romaji: String, meaning: String, cat: WritingCategory, strokes: Int)] = [
                ("hira_a", "あ", "a", "a (vowel sound)", .hiragana, 3),
                ("hira_i", "い", "i", "i (vowel sound)", .hiragana, 2),
                ("hira_u", "う", "u", "u (vowel sound)", .hiragana, 2),
                ("hira_e", "え", "e", "e (vowel sound)", .hiragana, 2),
                ("hira_o", "お", "o", "o (vowel sound)", .hiragana, 3),
                ("hira_ka", "か", "ka", "ka (K-row sound)", .hiragana, 3),
                ("hira_ki", "き", "ki", "ki (K-row sound)", .hiragana, 4),
                ("hira_ku", "く", "ku", "ku (K-row sound)", .hiragana, 1),
                ("hira_ke", "け", "ke", "ke (K-row sound)", .hiragana, 3),
                ("hira_ko", "こ", "ko", "ko (K-row sound)", .hiragana, 2)
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
                    nextReviewDate: Date.now,
                    isUnlocked: true
                )
                context.insert(card)
                insertedCount += 1
            }
        }

        if insertedCount > 0 || updatedCount > 0 {
            do {
                try context.save()
            } catch {
                print("⚠️ [SeedDataLoader] Failed to save preloaded seed items: \(error)")
            }
        }
    }

    /// Unlocks the next tier/row of locked characters into the user's active study deck.
    @MainActor
    public func unlockNextTier(context: ModelContext) -> Int {
        // Fetch all locked cards
        let lockedDescriptor = FetchDescriptor<CharacterCard>(
            predicate: #Predicate<CharacterCard> { card in
                !card.isUnlocked
            },
            sortBy: [SortDescriptor(\CharacterCard.id, order: .forward)]
        )

        guard let lockedCards = try? context.fetch(lockedDescriptor), !lockedCards.isEmpty else {
            return 0
        }

        // Unlock the next batch of up to 5 characters
        let batch = Array(lockedCards.prefix(5))
        for card in batch {
            card.isUnlocked = true
            card.nextReviewDate = Date.now
        }

        try? context.save()
        return batch.count
    }
}
