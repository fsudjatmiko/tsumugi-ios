import SwiftData
import SwiftUI

/// Visual streak counter badge displaying the continuous daily study streak.
struct StreakBadgeView: View {
    let reviewLogs: [ReviewLog]

    var currentStreak: Int {
        calculateStreak(from: reviewLogs)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.subheadline)
                .foregroundStyle(Color.tsumugiSpaceIndigo)

            Text("\(currentStreak) \(currentStreak == 1 ? "day" : "days")")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.tsumugiSpaceIndigo)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.tsumugiChartreuse)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current study streak: \(currentStreak) days")
    }

    // MARK: - Streak Calculation

    private func calculateStreak(from logs: [ReviewLog]) -> Int {
        guard !logs.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Extract distinct days where at least one review happened
        let reviewDays = Set(logs.map { calendar.startOfDay(for: $0.timestamp) })

        // Check if there was activity today or yesterday to consider the streak active
        var checkDate: Date
        if reviewDays.contains(today) {
            checkDate = today
        } else {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  reviewDays.contains(yesterday) else {
                return 0
            }
            checkDate = yesterday
        }

        var streak = 0
        while reviewDays.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }

        return streak
    }
}

#Preview {
    let sampleLogs = [
        ReviewLog(timestamp: Date(), grade: .good),
        ReviewLog(timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, grade: .easy),
        ReviewLog(timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, grade: .good)
    ]

    return StreakBadgeView(reviewLogs: sampleLogs)
        .padding()
        .modelContainer(PreviewContainer.shared)
}
