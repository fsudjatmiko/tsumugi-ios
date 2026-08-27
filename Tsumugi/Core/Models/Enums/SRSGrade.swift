import Foundation

/// Represents the user evaluation rating for an SRS flashcard review according to the SM-2 algorithm.
public enum SRSGrade: Int, Codable, Sendable, CaseIterable, Identifiable {
    case again = 0
    case hard = 3
    case good = 4
    case easy = 5

    public var id: Int { rawValue }

    /// Human-readable label for the review action.
    public var label: String {
        switch self {
        case .again:
            return "Again"
        case .hard:
            return "Hard"
        case .good:
            return "Good"
        case .easy:
            return "Easy"
        }
    }

    /// Whether this grade represents a successful recall attempt (grades >= 3).
    public var isSuccessful: Bool {
        rawValue >= 3
    }
}
