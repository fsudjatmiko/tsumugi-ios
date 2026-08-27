import SwiftData
import SwiftUI

/// Main learning dashboard providing progress metrics, review queue status, and category roadmap breakdowns.
struct DashboardView: View {
    @Query(sort: \CharacterCard.nextReviewDate, order: .forward)
    private var allCards: [CharacterCard]

    @Query(sort: \ReviewLog.timestamp, order: .reverse)
    private var allLogs: [ReviewLog]

    let onSelectStudyTab: (() -> Void)?

    init(onSelectStudyTab: (() -> Void)? = nil) {
        self.onSelectStudyTab = onSelectStudyTab
    }

    // MARK: - Computed Metrics

    private var dueCardsCount: Int {
        let now = Date.now
        return allCards.filter { $0.isUnlocked && $0.nextReviewDate <= now }.count
    }

    private var masteredCardsCount: Int {
        allCards.filter { $0.interval >= 21 }.count
    }

    private var todayReviewsCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        return allLogs.filter { calendar.startOfDay(for: $0.timestamp) == today }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroMetricsCard

                    if dueCardsCount > 0 {
                        reviewQueueBanner
                    }

                    categoryBreakdownSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.tsumugiBackground)
            .navigationTitle("Learn")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    StreakBadgeView(reviewLogs: allLogs)
                }
            }
        }
    }

    // MARK: - Hero Metrics Card

    private var heroMetricsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                DailyProgressRing(
                    completedToday: todayReviewsCount,
                    targetGoal: 20
                )

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Goal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Text(todayReviewsCount >= 20 ? "Goal Completed! 🎉" : "\(max(0, 20 - todayReviewsCount)) reviews remaining")
                            .font(.headline)
                            .foregroundStyle(Color.tsumugiSpaceIndigo)
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mastered")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(masteredCardsCount)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.tsumugiDustyDenim)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Due Today")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(dueCardsCount)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(dueCardsCount > 0 ? .orange : .green)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.tsumugiCardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.tsumugiFrozenWater.opacity(0.4), lineWidth: 1)
                )
        )
    }

    // MARK: - Review Queue Banner

    private var reviewQueueBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "bell.badge.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(dueCardsCount) Reviews Due")
                    .font(.headline)
                    .foregroundStyle(Color.tsumugiSpaceIndigo)

                Text("Keep your memory retention sharp.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onSelectStudyTab?()
            } label: {
                Text("Start")
                    .fontWeight(.bold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(Color.tsumugiDustyDenim)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.orange.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Category Breakdown Section

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Curriculum Roadmaps")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.tsumugiSpaceIndigo)

            ForEach(WritingCategory.allCases) { category in
                CategoryRoadmapCard(
                    category: category,
                    cards: allCards,
                    onStartStudy: {
                        onSelectStudyTab?()
                    }
                )
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(PreviewContainer.shared)
}
