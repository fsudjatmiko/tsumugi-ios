import SwiftData
import SwiftUI

/// Circular progress ring indicator displaying daily completed reviews against a target goal.
struct DailyProgressRing: View {
    let completedToday: Int
    let targetGoal: Int

    private var progress: Double {
        guard targetGoal > 0 else { return 0 }
        return min(1.0, Double(completedToday) / Double(targetGoal))
    }

    var body: some View {
        ZStack {
            // Track circle
            Circle()
                .stroke(
                    Color.tsumugiFrozenWater.opacity(0.4),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )

            // Progress fill circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.tsumugiDustyDenim,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            // Inner label
            VStack(spacing: 2) {
                Text("\(completedToday)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.tsumugiSpaceIndigo)

                Text("/ \(targetGoal)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 88, height: 88)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily progress: \(completedToday) of \(targetGoal) reviews completed")
    }
}

#Preview {
    DailyProgressRing(completedToday: 14, targetGoal: 20)
        .padding()
        .modelContainer(PreviewContainer.shared)
}
