import Foundation

/// Pure struct implementing SM-2 (SuperMemo-2) Spaced Repetition algorithm calculations.
public struct SRSEngine: Sendable {
    public static let minimumEaseFactor: Double = 1.3
    public static let defaultEaseFactor: Double = 2.5

    /// Holds the calculated resulting SRS state after evaluating a card with a grade.
    public struct CalculationResult: Sendable, Equatable {
        public let interval: Int
        public let repetitions: Int
        public let easeFactor: Double
        public let nextReviewDate: Date

        public init(
            interval: Int,
            repetitions: Int,
            easeFactor: Double,
            nextReviewDate: Date
        ) {
            self.interval = interval
            self.repetitions = repetitions
            self.easeFactor = easeFactor
            self.nextReviewDate = nextReviewDate
        }
    }

    public init() {}

    /// Calculates the next review parameters based on current card state and given grade.
    ///
    /// - Parameters:
    ///   - grade: The user rating (again = 0, hard = 3, good = 4, easy = 5).
    ///   - currentInterval: Days until previous review (0 for new cards).
    ///   - currentRepetitions: Number of consecutive successful reviews.
    ///   - currentEaseFactor: Current SM-2 ease factor (defaults to 2.5, minimum 1.3).
    ///   - currentDate: Reference date for calculation (defaults to current Date).
    ///   - calendar: Calendar used for date component math.
    /// - Returns: `CalculationResult` containing the updated interval, repetitions, easeFactor, and nextReviewDate.
    public func calculateNextReview(
        grade: SRSGrade,
        currentInterval: Int,
        currentRepetitions: Int,
        currentEaseFactor: Double,
        currentDate: Date = Date(),
        calendar: Calendar = .current
    ) -> CalculationResult {
        let q = Double(grade.rawValue)

        // 1. Calculate new Ease Factor using standard SM-2 formula:
        // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        let delta = 0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02)
        let updatedEF = max(Self.minimumEaseFactor, currentEaseFactor + delta)

        // 2. Calculate interval and repetitions
        let nextInterval: Int
        let nextRepetitions: Int

        if grade.isSuccessful {
            // Successful recall (grade >= 3)
            switch currentRepetitions {
            case 0:
                nextInterval = 1
            case 1:
                nextInterval = 6
            default:
                // interval = previous interval * EF (rounded to nearest integer)
                let calculatedInterval = Double(currentInterval) * updatedEF
                nextInterval = max(1, Int(calculatedInterval.rounded()))
            }
            nextRepetitions = currentRepetitions + 1
        } else {
            // Failure (grade < 3, e.g., .again)
            nextInterval = 1
            nextRepetitions = 0
        }

        // 3. Compute next review date
        let nextDate = calendar.date(byAdding: .day, value: nextInterval, to: currentDate) ?? currentDate.addingTimeInterval(Double(nextInterval * 86400))

        return CalculationResult(
            interval: nextInterval,
            repetitions: nextRepetitions,
            easeFactor: updatedEF,
            nextReviewDate: nextDate
        )
    }

    /// Mutates and applies the calculation directly onto a `CharacterCard`.
    ///
    /// - Parameters:
    ///   - card: The `CharacterCard` to update.
    ///   - grade: The review rating to apply.
    ///   - currentDate: Reference timestamp for the review.
    ///   - calendar: Calendar used for date operations.
    /// - Returns: A new `ReviewLog` representing this review event.
    @discardableResult
    public func processReview(
        for card: CharacterCard,
        grade: SRSGrade,
        currentDate: Date = Date(),
        calendar: Calendar = .current
    ) -> ReviewLog {
        let result = calculateNextReview(
            grade: grade,
            currentInterval: card.interval,
            currentRepetitions: card.repetitions,
            currentEaseFactor: card.easeFactor,
            currentDate: currentDate,
            calendar: calendar
        )

        card.interval = result.interval
        card.repetitions = result.repetitions
        card.easeFactor = result.easeFactor
        card.nextReviewDate = result.nextReviewDate

        let log = ReviewLog(
            timestamp: currentDate,
            grade: grade,
            card: card
        )
        card.reviewLogs.append(log)

        return log
    }
}
