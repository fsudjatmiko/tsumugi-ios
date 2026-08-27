import Foundation

/// Represents the script category of a Japanese character or item.
public enum WritingCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case hiragana = "hiragana"
    case katakana = "katakana"
    case kanji = "kanji"

    public var id: String { rawValue }

    /// Localized display name for the category.
    public var displayName: String {
        switch self {
        case .hiragana:
            return "Hiragana"
        case .katakana:
            return "Katakana"
        case .kanji:
            return "Kanji"
        }
    }

    /// Japanese script representation of the category title.
    public var japaneseTitle: String {
        switch self {
        case .hiragana:
            return "ひらがな"
        case .katakana:
            return "カタカナ"
        case .kanji:
            return "漢字"
        }
    }
}
