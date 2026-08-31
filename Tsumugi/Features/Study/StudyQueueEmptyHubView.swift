import SwiftData
import SwiftUI

/// Rich Apple-native completion and practice hub presented when the daily review queue is empty.
struct StudyQueueEmptyHubView: View {
    let unlockedCards: [CharacterCard]
    let todayLogs: [ReviewLog]
    let onStartCramMode: () -> Void
    let onUnlockNextTier: () -> Void
    let onSelectCharacter: (CharacterCard) -> Void

    @State private var selectedCardForDrill: CharacterCard?
    @State private var selectionTrigger: Int = 0

    // MARK: - Computed Stats

    private var accuracyPercentage: Int {
        guard !todayLogs.isEmpty else { return 100 }
        let successful = todayLogs.filter { $0.grade.isSuccessful }.count
        return Int((Double(successful) / Double(todayLogs.count)) * 100)
    }

    private var nextReviewCountdownText: String {
        guard let earliest = unlockedCards.map(\.nextReviewDate).sorted().first else {
            return "None"
        }
        let diff = earliest.timeIntervalSince(Date.now)
        if diff <= 0 {
            return "Now"
        }
        let hours = max(1, Int(diff / 3600))
        return "\(hours)h"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Native Celebration Header
                celebrationHeader

                // 2. Health/Fitness Style 3-Column Metrics Grid
                metricsGrid

                // 3. Apple Standard Button Hierarchy
                actionButtonsSection

                // 4. Clean Character Tile Grid
                characterGridSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .sensoryFeedback(.selection, trigger: selectionTrigger)
        .sheet(item: $selectedCardForDrill) { card in
            quickDrillSheet(for: card)
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.tsumugiChartreuse)

            VStack(spacing: 4) {
                Text("Session Complete")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.tsumugiTextPrimary)

                Text("All scheduled reviews for today are cleared.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - 3-Column Native Metrics Grid

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            metricTile(
                title: "COMPLETED",
                value: "\(todayLogs.count)",
                icon: "checkmark.circle.fill",
                accentColor: Color.tsumugiDustyDenim
            )

            metricTile(
                title: "RECALL",
                value: "\(accuracyPercentage)%",
                icon: "target",
                accentColor: Color.tsumugiChartreuse
            )

            metricTile(
                title: "NEXT DUE",
                value: nextReviewCountdownText,
                icon: "clock.fill",
                accentColor: Color.tsumugiDustyDenim
            )
        }
    }

    private func metricTile(
        title: String,
        value: String,
        icon: String,
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(accentColor)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.tsumugiTextPrimary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(uiColor: .separator).opacity(0.4), lineWidth: 0.5)
        )
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 10) {
            Button {
                onStartCramMode()
            } label: {
                Label("Free Practice", systemImage: "bolt.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color.tsumugiDustyDenim)

            Button {
                onUnlockNextTier()
            } label: {
                Label("Unlock Next Characters", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(Color.tsumugiDustyDenim)
        }
    }

    // MARK: - Character Grid Section

    private var characterGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("UNLOCKED CHARACTERS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(unlockedCards.count) total")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(unlockedCards) { card in
                    Button {
                        selectionTrigger += 1
                        selectedCardForDrill = card
                    } label: {
                        VStack(spacing: 2) {
                            Text(card.character)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.tsumugiTextPrimary)

                            Text(card.romaji)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color(uiColor: .separator).opacity(0.4), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Quick Drill Sheet

    private func quickDrillSheet(for card: CharacterCard) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Practice Tracing: \(card.character)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.tsumugiTextPrimary)

                        Text("\(card.romaji) • \(card.primaryMeaning)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)

                    StrokeCanvasView(
                        character: card.character,
                        strokeCount: card.strokeCount,
                        audioService: AudioService.shared
                    )

                    Button("Done") {
                        selectedCardForDrill = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Color.tsumugiDustyDenim)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        selectedCardForDrill = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    let mockCards = [
        CharacterCard(id: "1", character: "あ", romaji: "a", primaryMeaning: "a (vowel)", category: .hiragana, strokeCount: 3),
        CharacterCard(id: "2", character: "い", romaji: "i", primaryMeaning: "i (vowel)", category: .hiragana, strokeCount: 2),
        CharacterCard(id: "3", character: "う", romaji: "u", primaryMeaning: "u (vowel)", category: .hiragana, strokeCount: 2),
        CharacterCard(id: "4", character: "え", romaji: "e", primaryMeaning: "e (vowel)", category: .hiragana, strokeCount: 2),
        CharacterCard(id: "5", character: "お", romaji: "o", primaryMeaning: "o (vowel)", category: .hiragana, strokeCount: 3)
    ]

    return NavigationStack {
        StudyQueueEmptyHubView(
            unlockedCards: mockCards,
            todayLogs: [ReviewLog(grade: .good), ReviewLog(grade: .easy)],
            onStartCramMode: {},
            onUnlockNextTier: {},
            onSelectCharacter: { _ in }
        )
        .navigationTitle("Study")
    }
    .modelContainer(PreviewContainer.shared)
}
