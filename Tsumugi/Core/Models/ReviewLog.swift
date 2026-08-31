import Foundation
import SwiftData

/// Represents an individual review attempt and outcome for a character card.
@Model
public final class ReviewLog {
    public var id: UUID
    public var timestamp: Date
    public var gradeRaw: Int

    @Relationship(inverse: \CharacterCard.reviewLogs)
    public var card: CharacterCard?

    public var grade: SRSGrade {
        get {
            SRSGrade(rawValue: gradeRaw) ?? .forgot
        }
        set {
            gradeRaw = newValue.rawValue
        }
    }

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        grade: SRSGrade,
        card: CharacterCard? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.gradeRaw = grade.rawValue
        self.card = card
    }
}
