import Foundation
import SwiftData

/// In-memory ModelContainer configured with sample mock cards for SwiftUI Previews and testing.
@MainActor
public struct PreviewContainer {
    public static let shared: ModelContainer = {
        let schema = Schema([
            CharacterCard.self,
            ReviewLog.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = container.mainContext

            // Seed mock items for previews
            let mockCards = [
                CharacterCard(
                    id: "hira_a",
                    character: "あ",
                    romaji: "a",
                    primaryMeaning: "a (vowel)",
                    category: .hiragana,
                    strokeCount: 3,
                    interval: 1,
                    repetitions: 1,
                    easeFactor: 2.5,
                    nextReviewDate: Date(),
                    isUnlocked: true
                ),
                CharacterCard(
                    id: "hira_i",
                    character: "い",
                    romaji: "i",
                    primaryMeaning: "i (vowel)",
                    category: .hiragana,
                    strokeCount: 2,
                    interval: 6,
                    repetitions: 2,
                    easeFactor: 2.6,
                    nextReviewDate: Date().addingTimeInterval(86400 * 2),
                    isUnlocked: true
                ),
                CharacterCard(
                    id: "kata_a",
                    character: "ア",
                    romaji: "a",
                    primaryMeaning: "a (vowel)",
                    category: .katakana,
                    strokeCount: 2,
                    interval: 0,
                    repetitions: 0,
                    easeFactor: 2.5,
                    nextReviewDate: Date(),
                    isUnlocked: true
                ),
                CharacterCard(
                    id: "kanji_one",
                    character: "一",
                    romaji: "ichi",
                    primaryMeaning: "One",
                    category: .kanji,
                    strokeCount: 1,
                    interval: 0,
                    repetitions: 0,
                    easeFactor: 2.5,
                    nextReviewDate: Date(),
                    isUnlocked: true
                ),
                CharacterCard(
                    id: "kanji_sun",
                    character: "日",
                    romaji: "hi / nichi",
                    primaryMeaning: "Sun, Day",
                    category: .kanji,
                    strokeCount: 4,
                    interval: 0,
                    repetitions: 0,
                    easeFactor: 2.5,
                    nextReviewDate: Date(),
                    isUnlocked: false
                )
            ]

            for card in mockCards {
                context.insert(card)
            }

            // Add sample review log
            if let firstCard = mockCards.first {
                let sampleLog = ReviewLog(
                    timestamp: Date().addingTimeInterval(-86400),
                    grade: .good,
                    card: firstCard
                )
                context.insert(sampleLog)
                firstCard.reviewLogs.append(sampleLog)
            }

            try? context.save()
            return container
        } catch {
            fatalError("Failed to initialize preview container: \(error)")
        }
    }()
}
