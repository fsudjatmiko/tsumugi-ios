import Foundation
import SwiftData
import SwiftUI

/// Main coordinator view for the 2D interactive flashcard deck, stroke tracing session, and completion hub.
struct StudySessionView: View {
    enum StudyMode: String, CaseIterable, Identifiable {
        case flashcard = "Quick Flip"
        case writing = "Tactile Writing"

        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<CharacterCard> { card in
            card.isUnlocked
        },
        sort: \CharacterCard.character,
        order: .forward
    )
    private var allUnlockedCards: [CharacterCard]

    @Query(sort: \ReviewLog.timestamp, order: .reverse)
    private var allReviewLogs: [ReviewLog]

    private var dueCards: [CharacterCard] {
        let now = Date.now
        return allUnlockedCards.filter { $0.nextReviewDate <= now }
    }

    private var todayLogs: [ReviewLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        return allReviewLogs.filter { calendar.startOfDay(for: $0.timestamp) == today }
    }

    private var activeStudyQueue: [CharacterCard] {
        isCramMode ? allUnlockedCards : dueCards
    }

    @State private var selectedMode: StudyMode = .flashcard
    @State private var audioService = AudioService()
    @State private var srsEngine = SRSEngine()
    @State private var isCardFlipped: Bool = false
    @State private var currentCardIndex: Int = 0
    @State private var showGhostGuide: Bool = true
    @State private var suggestedGrade: SRSGrade? = nil
    @State private var isWritingCompleted: Bool = false
    @State private var canvasResetID: UUID = UUID()
    @State private var isCramMode: Bool = false
    @State private var unlockConfirmationMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if activeStudyQueue.isEmpty && !isCramMode {
                    StudyQueueEmptyHubView(
                        unlockedCards: allUnlockedCards,
                        todayLogs: todayLogs,
                        onStartCramMode: {
                            isCramMode = true
                            currentCardIndex = 0
                        },
                        onUnlockNextTier: {
                            let unlockedCount = SeedDataLoader.shared.unlockNextTier(context: modelContext)
                            if unlockedCount > 0 {
                                unlockConfirmationMessage = "Unlocked \(unlockedCount) new characters!"
                            }
                        },
                        onSelectCharacter: { _ in }
                    )
                } else {
                    activeStudySession
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(isCramMode ? "Free Practice (Cram)" : "Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !activeStudyQueue.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Exit") {
                            isCramMode = false
                            currentCardIndex = 0
                            isCardFlipped = false
                            isWritingCompleted = false
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        Text("\(min(currentCardIndex + 1, activeStudyQueue.count)) of \(activeStudyQueue.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    if selectedMode == .writing {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showGhostGuide.toggle()
                            } label: {
                                Image(systemName: showGhostGuide ? "eye.fill" : "eye.slash.fill")
                                    .foregroundStyle(Color.tsumugiDustyDenim)
                            }
                            .accessibilityLabel(showGhostGuide ? "Hide stroke guide" : "Show stroke guide")
                        }
                    }
                }
            }
            .alert(
                unlockConfirmationMessage ?? "New Characters Unlocked",
                isPresented: Binding(
                    get: { unlockConfirmationMessage != nil },
                    set: { if !$0 { unlockConfirmationMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    unlockConfirmationMessage = nil
                }
            }
        }
    }

    // MARK: - Active Session View

    private var activeStudySession: some View {
        let currentCard = activeStudyQueue[safe: currentCardIndex] ?? activeStudyQueue[0]

        return ScrollView {
            VStack(spacing: 18) {
                // Mode Switcher Segmented Control
                Picker("Study Mode", selection: $selectedMode) {
                    ForEach(StudyMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                // Progress Bar
                progressBar

                // Main Interaction Area
                if selectedMode == .flashcard {
                    flashcardSessionSection(card: currentCard)
                } else {
                    writingSessionSection(card: currentCard)
                }
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Flashcard Mode (Two-Stage Interaction)

    private func flashcardSessionSection(card: CharacterCard) -> some View {
        VStack(spacing: 20) {
            Flashcard3DView(
                card: card,
                isFlipped: isCardFlipped,
                audioService: audioService,
                onFlip: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isCardFlipped.toggle()
                    }
                }
            )

            if !isCardFlipped {
                // Stage 1: Question / Card Front CTA
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isCardFlipped = true
                    }
                }) {
                    Text("Show Answer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.tsumugiDustyDenim)
                .controlSize(.large)
                .padding(.horizontal, 20)
            } else {
                // Stage 2: Card Back / Answer Revealed Grading Controls
                ReviewControlBar(
                    card: card,
                    srsEngine: srsEngine,
                    suggestedGrade: suggestedGrade,
                    onGraded: { _ in
                        advanceToNextCard()
                    }
                )
            }
        }
    }

    // MARK: - Writing Mode (Drawing -> Completion -> Grading)

    private func writingSessionSection(card: CharacterCard) -> some View {
        VStack(spacing: 16) {
            // Character header preview in writing mode
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trace \(card.character)")
                        .font(.headline)
                        .foregroundStyle(Color.tsumugiTextPrimary)
                    Text("\(card.romaji) • \(card.primaryMeaning)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    canvasResetID = UUID()
                    suggestedGrade = nil
                    isWritingCompleted = false
                } label: {
                    Label("Retry", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(Color.tsumugiDustyDenim)
            }
            .padding(.horizontal, 20)

            // Tactile Stroke Tracing Canvas with Real-Time Validation
            StrokeCanvasView(
                character: card.character,
                strokeCount: card.strokeCount,
                audioService: audioService,
                showGhostGuide: showGhostGuide,
                onCompletion: { retryCount in
                    isWritingCompleted = true
                    calculateSuggestedGrade(retryCount: retryCount)
                }
            )
            .id("\(card.id)_\(canvasResetID)")

            // Show grading buttons only once writing has completed
            if isWritingCompleted {
                ReviewControlBar(
                    card: card,
                    srsEngine: srsEngine,
                    suggestedGrade: suggestedGrade,
                    onGraded: { _ in
                        advanceToNextCard()
                    }
                )
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let progress = Double(currentCardIndex) / Double(max(1, activeStudyQueue.count))

        return VStack(spacing: 6) {
            ProgressView(value: progress)
                .tint(Color.tsumugiDustyDenim)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Grade Suggestion Logic

    private func calculateSuggestedGrade(retryCount: Int) {
        if retryCount == 0 {
            suggestedGrade = .easy
        } else if retryCount == 1 {
            suggestedGrade = .good
        } else if retryCount <= 3 {
            suggestedGrade = .hard
        } else {
            suggestedGrade = .again
        }
    }

    // MARK: - Navigation / Queue Logic

    private func advanceToNextCard() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isCardFlipped = false
            isWritingCompleted = false
            suggestedGrade = nil
            canvasResetID = UUID()
            if currentCardIndex < activeStudyQueue.count - 1 {
                currentCardIndex += 1
            } else {
                currentCardIndex = 0
                if isCramMode {
                    isCramMode = false
                }
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
