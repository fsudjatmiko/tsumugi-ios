import Foundation
import SwiftData

/// In-memory ModelContainer configured with sample mock cards for SwiftUI Previews and testing.
@MainActor
public struct PreviewContainer {
    public static let shared: ModelContainer = {
        let schema = Schema([
            CharacterCard.self,
            ReviewLog.self,
            ChatMessage.self
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
                    isUnlocked: true,
                    onyomi: ["イチ", "イツ"],
                    kunyomi: ["ひと", "ひとつ"],
                    clusterCategory: "Numbers & Counters",
                    gradeLevel: 1,
                    jlptLevel: "N5",
                    radicals: ["一"],
                    examples: [
                        KanjiExample(text: "一つ", kana: "ひとつ", english: "one thing"),
                        KanjiExample(text: "一人", kana: "ひとり", english: "one person")
                    ]
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
                    isUnlocked: false,
                    onyomi: ["ニチ", "ジツ"],
                    kunyomi: ["ひ", "か"],
                    clusterCategory: "Nature, Elements & Time",
                    gradeLevel: 1,
                    jlptLevel: "N5",
                    radicals: ["日"],
                    examples: [
                        KanjiExample(text: "日曜日", kana: "にちようび", english: "Sunday"),
                        KanjiExample(text: "今日", kana: "きょう", english: "today")
                    ]
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

            // Add sample chat message
            let sampleChat = ChatMessage(
                text: "いらっしゃいませ！何をご注文されますか？",
                furiganaMarkup: "いらっしゃいませ！[何|なに]をご[注|ちゅう][文|もん]されますか？",
                englishTranslation: "Welcome! What would you like to order?",
                isUser: false
            )
            context.insert(sampleChat)

            try? context.save()
            return container
        } catch {
            fatalError("Failed to initialize preview container: \(error)")
        }
    }()
}
