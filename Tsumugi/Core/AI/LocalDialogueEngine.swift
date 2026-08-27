import Foundation
import Observation

/// Offline dialogue scenario and local AI conversation generator tailored for JLPT N5 beginners.
@Observable
@MainActor
public final class LocalDialogueEngine {
    public struct Scenario: Identifiable, Sendable {
        public let id: String
        public let title: String
        public let japaneseTitle: String
        public let systemPrompt: String
        public let initialAIMessage: DialogueTurn
        public let starterSuggestions: [String]

        public init(
            id: String,
            title: String,
            japaneseTitle: String,
            systemPrompt: String,
            initialAIMessage: DialogueTurn,
            starterSuggestions: [String]
        ) {
            self.id = id
            self.title = title
            self.japaneseTitle = japaneseTitle
            self.systemPrompt = systemPrompt
            self.initialAIMessage = initialAIMessage
            self.starterSuggestions = starterSuggestions
        }
    }

    public struct DialogueTurn: Sendable {
        public let plainJapanese: String
        public let furiganaMarkup: String
        public let englishTranslation: String
        public let followUpSuggestions: [String]

        public init(
            plainJapanese: String,
            furiganaMarkup: String,
            englishTranslation: String,
            followUpSuggestions: [String] = []
        ) {
            self.plainJapanese = plainJapanese
            self.furiganaMarkup = furiganaMarkup
            self.englishTranslation = englishTranslation
            self.followUpSuggestions = followUpSuggestions
        }
    }

    public private(set) var availableScenarios: [Scenario] = []
    public private(set) var activeScenario: Scenario?
    public private(set) var isThinking: Bool = false

    public init() {
        self.availableScenarios = Self.loadDefaultScenarios()
        self.activeScenario = availableScenarios.first
    }

    public func selectScenario(_ scenario: Scenario) {
        self.activeScenario = scenario
    }

    /// Simulates offline local AI generation with N5 vocabulary matching and rule-based heuristics.
    public func respond(to userInput: String) async -> DialogueTurn {
        isThinking = true
        // Simulate short on-device inference latency
        try? await Task.sleep(nanoseconds: 600_000_000)
        isThinking = false

        let lower = userInput.lowercased()

        if lower.contains("これ") || lower.contains("コーヒー") || lower.contains("おねがい") {
            return DialogueTurn(
                plainJapanese: "かしこまりました！ホットですか？アイスですか？",
                furiganaMarkup: "かしこまりました！[温|あたた]かいのですか？[冷|つめ]たいのですか？",
                englishTranslation: "Certainly! Would you like it hot or iced?",
                followUpSuggestions: ["ホットをおねがいします", "アイスをおねがいします", "いくらですか？"]
            )
        } else if lower.contains("いくら") {
            return DialogueTurn(
                plainJapanese: "全部で四百円になります。",
                furiganaMarkup: "[全|ぜん][部|ぶ]で[四|よん][百|ひゃく][円|えん]になります。",
                englishTranslation: "That will be 400 yen in total.",
                followUpSuggestions: ["カードで払えますか？", "はい、どうぞ", "ありがとう！"]
            )
        } else if lower.contains("駅") || lower.contains("どこ") || lower.contains("えき") {
            return DialogueTurn(
                plainJapanese: "駅はあの角を右に曲がったところにありますよ。",
                furiganaMarkup: "[駅|えき]はあの[角|かど]を[右|みぎ]に[曲|ま]がったところにありますよ。",
                englishTranslation: "The station is just around that corner to the right.",
                followUpSuggestions: ["ありがとうございます！", "遠いですか？", "歩いて何分ですか？"]
            )
        } else if lower.contains("はじめまして") || lower.contains("名前") || lower.contains("なまえ") {
            return DialogueTurn(
                plainJapanese: "はじめまして！つむぎです。日本語の勉強を一緒に頑張りましょう！",
                furiganaMarkup: "はじめまして！つむぎです。[日|に][本|ほん][語|ご]の[勉|べん][強|きょう]を[一|いっ][緒|しょ]に[頑|がん][張|ば]りましょう！",
                englishTranslation: "Nice to meet you! I'm Tsumugi. Let's do our best studying Japanese together!",
                followUpSuggestions: ["よろしくお願いします！", "つむぎさん、こんにちは！", "趣味は何ですか？"]
            )
        } else {
            return DialogueTurn(
                plainJapanese: "よく分かりました！もっと詳しく教えてくれますか？",
                furiganaMarkup: "よく[分|わ]かりました！もっと[詳|くわ]しく[教|おし]えてくれますか？",
                englishTranslation: "I understand! Could you tell me more?",
                followUpSuggestions: ["はい、いいですよ", "すみません、もう一度言ってください", "大丈夫です"]
            )
        }
    }

    private static func loadDefaultScenarios() -> [Scenario] {
        [
            Scenario(
                id: "cafe",
                title: "Ordering at a Café",
                japaneseTitle: "カフェでの注文",
                systemPrompt: "You are a friendly café barista in Shibuya.",
                initialAIMessage: DialogueTurn(
                    plainJapanese: "いらっしゃいませ！何をご注文されますか？",
                    furiganaMarkup: "いらっしゃいませ！[何|なに]をご[注|ちゅう][文|もん]されますか？",
                    englishTranslation: "Welcome! What would you like to order?",
                    followUpSuggestions: ["コーヒーをおねがいします", "これをおねがいします", "おすすめは何ですか？"]
                ),
                starterSuggestions: ["コーヒーをおねがいします", "これをおねがいします", "おすすめは何ですか？"]
            ),
            Scenario(
                id: "directions",
                title: "Asking Directions",
                japaneseTitle: "道案内をたずねる",
                systemPrompt: "You are a polite local resident near Tokyo Station.",
                initialAIMessage: DialogueTurn(
                    plainJapanese: "こんにちは！何かお困りですか？",
                    furiganaMarkup: "こんにちは！[何|なに]かお[困|こま]りですか？",
                    englishTranslation: "Hello! Is there something I can help you find?",
                    followUpSuggestions: ["駅はどこですか？", "トイレはどこですか？", "新宿に行きたいです"]
                ),
                starterSuggestions: ["駅はどこですか？", "トイレはどこですか？", "新宿に行きたいです"]
            ),
            Scenario(
                id: "intro",
                title: "Self-Introduction",
                japaneseTitle: "自己紹介",
                systemPrompt: "You are a friendly Japanese language exchange partner.",
                initialAIMessage: DialogueTurn(
                    plainJapanese: "はじめまして！お名前は何ですか？",
                    furiganaMarkup: "はじめまして！お[名|な][前|まえ]は[何|なん]ですか？",
                    englishTranslation: "Nice to meet you! What is your name?",
                    followUpSuggestions: ["はじめまして！", "私は学生です", "アメリカから来ました"]
                ),
                starterSuggestions: ["はじめまして！", "私は学生です", "アメリカから来ました"]
            )
        ]
    }
}
