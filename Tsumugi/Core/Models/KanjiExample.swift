import Foundation

/// Represents a practical compound vocabulary example for a Kanji character.
public struct KanjiExample: Codable, Sendable, Hashable {
    public let text: String
    public let kana: String
    public let english: String

    public init(text: String, kana: String, english: String) {
        self.text = text
        self.kana = kana
        self.english = english
    }
}
