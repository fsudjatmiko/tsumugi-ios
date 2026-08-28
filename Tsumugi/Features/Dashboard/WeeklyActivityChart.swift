import Charts
import SwiftData
import SwiftUI

/// Chart visualizing completed reviews over the past 7 days using Apple's native Charts framework.
struct WeeklyActivityChart: View {
    struct DailyActivity: Identifiable {
        let id = UUID()
        let dayLabel: String
        let date: Date
        let count: Int
    }

    let reviewLogs: [ReviewLog]

    private var activityData: [DailyActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE" // e.g. Mon, Tue

        var items: [DailyActivity] = []

        for offset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                let start = calendar.startOfDay(for: date)
                let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date

                let count = reviewLogs.filter { log in
                    log.timestamp >= start && log.timestamp < end
                }.count

                let label = offset == 0 ? "Today" : formatter.string(from: date)
                items.append(DailyActivity(dayLabel: label, date: date, count: count))
            }
        }

        return items
    }

    private var totalWeeklyReviews: Int {
        activityData.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Activity")
                        .font(.headline)
                        .foregroundStyle(Color.tsumugiTextPrimary)

                    Text("\(totalWeeklyReviews) reviews in the last 7 days")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chart.bar.xaxis")
                    .font(.title3)
                    .foregroundStyle(Color.tsumugiDustyDenim)
            }

            Chart(activityData) { item in
                BarMark(
                    x: .value("Day", item.dayLabel),
                    y: .value("Reviews", item.count)
                )
                .foregroundStyle(
                    item.dayLabel == "Today"
                        ? Color.tsumugiDustyDenim
                        : Color.tsumugiDustyDenim.opacity(0.6)
                )
                .cornerRadius(6)
            }
            .frame(height: 140)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(Color.tsumugiTextSecondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.tsumugiCardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                )
        )
    }
}

#Preview {
    let mockLogs = [
        ReviewLog(timestamp: Date.now, grade: .good),
        ReviewLog(timestamp: Date.now, grade: .easy),
        ReviewLog(timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!, grade: .good),
        ReviewLog(timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date.now)!, grade: .hard),
        ReviewLog(timestamp: Calendar.current.date(byAdding: .day, value: -3, to: Date.now)!, grade: .again)
    ]

    return WeeklyActivityChart(reviewLogs: mockLogs)
        .padding()
        .modelContainer(PreviewContainer.shared)
}
