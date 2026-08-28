import SwiftData
import SwiftUI

/// Main learning dashboard providing progress metrics, review queue status, weekly activity, and category roadmaps.
struct DashboardView: View {
    @Query(sort: \CharacterCard.nextReviewDate, order: .forward)
    private var allCards: [CharacterCard]

    @Query(sort: \ReviewLog.timestamp, order: .reverse)
    private var allLogs: [ReviewLog]

    let onSelectStudyTab: (() -> Void)?
    let onSelectSpatialTab: (() -> Void)?

    init(
        onSelectStudyTab: (() -> Void)? = nil,
        onSelectSpatialTab: (() -> Void)? = nil
    ) {
        self.onSelectStudyTab = onSelectStudyTab
        self.onSelectSpatialTab = onSelectSpatialTab
    }

    // MARK: - Computed Metrics

    private var dueCardsCount: Int {
        let now = Date.now
        return allCards.filter { $0.isUnlocked && $0.nextReviewDate <= now }.count
    }

    private var masteredCardsCount: Int {
        allCards.filter { $0.interval >= 21 }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Hero Review Card
                    HeroReviewCard(
                        dueCount: dueCardsCount,
                        masteredCount: masteredCardsCount,
                        reviewLogs: allLogs,
                        onStartReview: {
                            onSelectStudyTab?()
                        }
                    )

                    // 2. Quick Practice Drills Shelf
                    QuickDrillSection(onLaunchDrill: handleQuickDrill)

                    // 3. Weekly Review Activity Chart
                    WeeklyActivityChart(reviewLogs: allLogs)

                    // 4. Curriculum Category Mastery Breakdown
                    CategoryDeckSection(
                        cards: allCards,
                        onSelectCategory: { _ in
                            onSelectStudyTab?()
                        }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Learn")
            .refreshable {
                // SwiftData @Query updates automatically; triggers smooth haptic refresh
            }
        }
    }

    // MARK: - Quick Drill Router

    private func handleQuickDrill(_ id: String) {
        switch id {
        case "speed_drill", "stroke_canvas":
            onSelectStudyTab?()
        case "radical_puzzle":
            onSelectSpatialTab?()
        default:
            onSelectStudyTab?()
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(PreviewContainer.shared)
}
