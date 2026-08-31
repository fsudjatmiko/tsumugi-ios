import Foundation
import SwiftUI

/// Represents the user evaluation rating for an SRS flashcard review according to the SM-2 algorithm.
public enum SRSGrade: Int, Codable, Sendable, CaseIterable, Identifiable {
    case forgot = 0
    case struggled = 3
    case remembered = 4
    case effortless = 5

    // Legacy aliases for backward compatibility
    public static var again: SRSGrade { .forgot }
    public static var hard: SRSGrade { .struggled }
    public static var good: SRSGrade { .remembered }
    public static var easy: SRSGrade { .effortless }

    public var id: Int { rawValue }

    /// Human-readable intuitive label for the review action.
    public var label: String {
        switch self {
        case .forgot:
            return "Forgot"
        case .struggled:
            return "Struggled"
        case .remembered:
            return "Remembered"
        case .effortless:
            return "Instant"
        }
    }

    /// Action subtitle description indicating the scheduling effect.
    public var subtitle: String {
        switch self {
        case .forgot:
            return "Reset"
        case .struggled:
            return "+1d"
        case .remembered:
            return "+3d"
        case .effortless:
            return "+7d"
        }
    }

    /// System SF Symbol name representing this grade.
    public var iconName: String {
        switch self {
        case .forgot:
            return "xmark"
        case .struggled:
            return "exclamationmark"
        case .remembered:
            return "checkmark"
        case .effortless:
            return "sparkles"
        }
    }

    /// Semantic Apple tint color for this grade.
    public var tint: Color {
        switch self {
        case .forgot:
            return .red
        case .struggled:
            return .orange
        case .remembered:
            return .blue
        case .effortless:
            return .green
        }
    }

    /// Whether this grade represents a successful recall attempt (grades >= 3).
    public var isSuccessful: Bool {
        rawValue >= 3
    }
}
