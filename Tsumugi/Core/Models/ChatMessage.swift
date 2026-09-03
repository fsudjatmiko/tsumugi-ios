import Foundation
import SwiftData

/// Persistent model capturing an individual chat message in a conversation.
@Model
public final class ChatMessage: Identifiable {
    @Attribute(.unique) public var id: String
    public var text: String
    public var furiganaMarkup: String
    public var englishTranslation: String
    public var isUser: Bool
    public var timestamp: Date

    public var session: ChatSession?

    public init(
        id: String = UUID().uuidString,
        text: String,
        furiganaMarkup: String = "",
        englishTranslation: String = "",
        isUser: Bool,
        timestamp: Date = Date(),
        session: ChatSession? = nil
    ) {
        self.id = id
        self.text = text
        self.furiganaMarkup = furiganaMarkup.isEmpty ? text : furiganaMarkup
        self.englishTranslation = englishTranslation
        self.isUser = isUser
        self.timestamp = timestamp
        self.session = session
    }
}
