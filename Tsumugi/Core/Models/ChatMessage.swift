import Foundation
import SwiftData

/// Persistent model or value capturing an individual chat message in a conversation.
@Model
public final class ChatMessage: Identifiable {
    @Attribute(.unique) public var id: String
    public var text: String
    public var furiganaMarkup: String
    public var englishTranslation: String
    public var isUser: Bool
    public var timestamp: Date

    public init(
        id: String = UUID().uuidString,
        text: String,
        furiganaMarkup: String = "",
        englishTranslation: String = "",
        isUser: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.furiganaMarkup = furiganaMarkup.isEmpty ? text : furiganaMarkup
        self.englishTranslation = englishTranslation
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
