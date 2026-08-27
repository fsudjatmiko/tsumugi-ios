import Foundation
import SwiftData
import SwiftUI

/// Main coordinator view for the 2D interactive flashcard deck and stroke tracing study session.
struct StudySessionView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<CharacterCard> { card in
            card.isUnlocked
        },
        sort: \CharacterCard.nextReviewDate,
        order: .forward
    )
    private var allUnlockedCards: [CharacterCard]

    private var dueCards: [CharacterCard] {
        let now = Date.now
        return allUnlockedCards.filter { $0.nextReviewDate <= now }
    }

    @State private var audioService = AudioService()
    @State private var srsEngine = SRSEngine()
    @State private var isCardFlipped: Bool = false
    @State private var currentCardIndex: Int = 0

    var body: some View {
        NavigationStack {
            Group {
                if dueCards.isEmpty {
                    emptyQueueView
                } else {
                    activeStudySession
                }
            }
            .navigationTitle("Study Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !dueCards.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(min(currentCardIndex + 1, dueCards.count)) / \(dueCards.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyQueueView: some View {
        ContentUnavailableView(
            "All Caught Up!",
            systemImage: "checkmark.seal.fill",
            description: Text("You have completed all scheduled SRS reviews for now. Great job!")
        )
    }

    // MARK: - Active Session View

    private var activeStudySession: some View {
        let currentCard = dueCards[safe: currentCardIndex] ?? dueCards[0]

        return ScrollView {
            VStack(spacing: 20) {
                // Progress Bar
                progressBar

                // 3D Flip Flashcard
                Flashcard3DView(
                    card: currentCard,
                    isFlipped: isCardFlipped,
                    audioService: audioService,
                    onFlip: {
                        isCardFlipped.toggle()
                    }
                )

                // Tactile Stroke Tracing Canvas
                StrokeCanvasView(
                    character: currentCard.character
                )
                .id(currentCard.id)

                // SRS Review Action Bar
                ReviewControlBar(
                    card: currentCard,
                    srsEngine: srsEngine,
                    onGraded: { _ in
                        advanceToNextCard()
                    }
                )
                .padding(.top, 4)
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let progress = Double(currentCardIndex) / Double(max(1, dueCards.count))

        return VStack(spacing: 6) {
            ProgressView(value: progress)
                .tint(Color.tsumugiDustyDenim)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Navigation / Queue Logic

    private func advanceToNextCard() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isCardFlipped = false
            if currentCardIndex < dueCards.count - 1 {
                currentCardIndex += 1
            } else {
                currentCardIndex = 0
            }
        }
    }
}

// MARK: - Safe Collection Subscript Helper

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    StudySessionView()
        .modelContainer(PreviewContainer.shared)
}
