import SwiftData
import SwiftUI

/// Hero banner card highlighting reviews due today, active study streak, and primary study CTA.
struct HeroReviewCard: View {
    let dueCount: Int
    let masteredCount: Int
    let reviewLogs: [ReviewLog]
    let onStartReview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Daily Practice")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.tsumugiDustyDenim)
                        .textCase(.uppercase)

                    Text(dueCount > 0 ? "\(dueCount) Cards Due" : "All Caught Up!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiTextPrimary)

                    Text(dueCount > 0 ? "Review your queue to keep recall fresh." : "Great job staying ahead of your reviews today.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                StreakBadgeView(reviewLogs: reviewLogs)
            }

            Divider()
                .overlay(Color.tsumugiCardBorder)

            HStack(spacing: 12) {
                Button(action: onStartReview) {
                    HStack(spacing: 8) {
                        Image(systemName: dueCount > 0 ? "play.fill" : "arrow.clockwise")
                        Text(dueCount > 0 ? "Start Review Session" : "Practice Extra")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color.tsumugiDustyDenim)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Mastered")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(masteredCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiTextPrimary)
                }
                .padding(.horizontal, 8)
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
    HeroReviewCard(
        dueCount: 8,
        masteredCount: 42,
        reviewLogs: [],
        onStartReview: {}
    )
    .padding()
    .modelContainer(PreviewContainer.shared)
}
