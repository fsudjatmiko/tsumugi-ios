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
    @Environment(\.dismiss) private var dismiss

    var onExit: (() -> Void)? = nil

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
        if !customQueue.isEmpty {
            return customQueue
        }
        return isCramMode ? allUnlockedCards : dueCards
    }

    @State private var customQueue: [CharacterCard] = []
    @State private var isSessionActive: Bool = false
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

    init(onExit: (() -> Void)? = nil) {
        self.onExit = onExit
    }

    var body: some View {
        NavigationStack {
            Group {
                if !isSessionActive || (activeStudyQueue.isEmpty && !isCramMode) {
                    StudyQueueEmptyHubView(
                        unlockedCards: allUnlockedCards,
                        todayLogs: todayLogs,
                        onStartCramMode: {
                            isCramMode = true
                            customQueue = allUnlockedCards
                            currentCardIndex = 0
                            isSessionActive = true
                        },
                        onUnlockNextTier: {
                            let unlockedCount = SeedDataLoader.shared.unlockNextTier(context: modelContext)
                            if unlockedCount > 0 {
                                unlockConfirmationMessage = "Unlocked \(unlockedCount) new characters!"
                            }
                        },
                        onSelectCharacter: { selectedCard in
                            customQueue = [selectedCard]
                            currentCardIndex = 0
                            isCramMode = true
                            isSessionActive = true
                        }
                    )
                } else {
                    activeStudySession
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isSessionActive && !activeStudyQueue.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Exit") {
                            handleExit()
                        }
                        .fontWeight(.regular)
                    }

                    ToolbarItem(placement: .principal) {
                        Text("\(min(currentCardIndex + 1, activeStudyQueue.count)) of \(activeStudyQueue.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if selectedMode == .writing {
                            Button {
                                showGhostGuide.toggle()
                            } label: {
                                Image(systemName: showGhostGuide ? "eye.fill" : "eye.slash.fill")
                                    .foregroundStyle(Color.tsumugiDustyDenim)
                            }
                            .accessibilityLabel(showGhostGuide ? "Hide stroke guide" : "Show stroke guide")
                        }

                        Button {
                            skipCurrentCard()
                        } label: {
                            Label("Skip", systemImage: "forward.fill")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(Color.tsumugiDustyDenim)
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
            .onAppear {
                // If there are cards due when opening, start the active session automatically
                if !dueCards.isEmpty && !isSessionActive && customQueue.isEmpty {
                    isSessionActive = true
                }
            }
        }
    }

    private var navigationTitleText: String {
        if !isSessionActive {
            return "Practice Hub"
        }
        return isCramMode ? "Free Practice" : "Review"
    }

    // MARK: - Exit Handler

    private func handleExit() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSessionActive = false
            isCramMode = false
            customQueue.removeAll()
            currentCardIndex = 0
            isCardFlipped = false
            isWritingCompleted = false
            suggestedGrade = nil
        }

        // Dismiss modal if presented in sheet / fullScreenCover
        dismiss()

        // Notify parent coordinator if callback was attached
        onExit?()
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

            // Secondary Pass / Reveal Action if writing is not completed yet
            if !isWritingCompleted {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isWritingCompleted = true
                        suggestedGrade = .struggled
                    }
                } label: {
                    Label("Reveal & Continue", systemImage: "eye")
                        .font(.subheadline)
                        .foregroundStyle(Color.tsumugiDustyDenim)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }

            // Show grading buttons once writing is completed or revealed
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
            suggestedGrade = .effortless
        } else if retryCount == 1 {
            suggestedGrade = .remembered
        } else if retryCount <= 3 {
            suggestedGrade = .struggled
        } else {
            suggestedGrade = .forgot
        }
    }

    // MARK: - Navigation / Queue Logic

    private func skipCurrentCard() {
        guard !activeStudyQueue.isEmpty else { return }

        // Ensure customQueue is populated so we can reorder the active items
        if customQueue.isEmpty {
            customQueue = activeStudyQueue
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            // Move current card to the end of the queue
            if currentCardIndex < customQueue.count {
                let skippedCard = customQueue.remove(at: currentCardIndex)
                customQueue.append(skippedCard)
            }

            isCardFlipped = false
            isWritingCompleted = false
            suggestedGrade = nil
            canvasResetID = UUID()

            // Keep currentCardIndex pointing at the new card that took its slot, or reset if at end
            if currentCardIndex >= customQueue.count {
                currentCardIndex = 0
            }
        }
    }

    private func advanceToNextCard() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isCardFlipped = false
            isWritingCompleted = false
            suggestedGrade = nil
            canvasResetID = UUID()

            if !customQueue.isEmpty && currentCardIndex < customQueue.count {
                customQueue.remove(at: currentCardIndex)
            } else {
                currentCardIndex += 1
            }

            if currentCardIndex >= activeStudyQueue.count {
                currentCardIndex = 0
                customQueue.removeAll()
                isSessionActive = false
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
