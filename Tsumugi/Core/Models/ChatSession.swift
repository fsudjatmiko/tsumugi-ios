import Foundation
import SwiftData

/// Persistent chat session containing multiple sequential messages.
@Model
public final class ChatSession: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    public var messages: [ChatMessage]

    public init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [ChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }

    /// Sorted messages in chronological order.
    public var sortedMessages: [ChatMessage] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }

    /// The most recent message in this conversation.
    public var lastMessage: ChatMessage? {
        sortedMessages.last
    }

    /// A snippet of the most recent message text for sidebar row previews.
    public var lastMessagePreview: String {
        guard let last = lastMessage else {
            return "No messages yet"
        }
        let clean = last.text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\[JA\]:?"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? "..." : clean
    }
}
