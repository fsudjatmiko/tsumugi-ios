import SwiftData
import SwiftUI

/// Control bar providing SM-2 review rating actions with native haptic sensory feedback.
struct ReviewControlBar: View {
    let card: CharacterCard
    let srsEngine: SRSEngine
    let onGraded: (SRSGrade) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var feedbackTrigger: Int = 0

    var body: some View {
        HStack(spacing: 10) {
            gradeButton(grade: .again, tint: .red)
            gradeButton(grade: .hard, tint: .orange)
            gradeButton(grade: .good, tint: Color.tsumugiDustyDenim)
            gradeButton(grade: .easy, tint: .green)
        }
        .padding(.horizontal, 20)
        .sensoryFeedback(.impact, trigger: feedbackTrigger)
    }

    // MARK: - Button ViewBuilder

    @ViewBuilder
    private func gradeButton(grade: SRSGrade, tint: Color) -> some View {
        Button {
            applyGrade(grade)
        } label: {
            VStack(spacing: 2) {
                Text(grade.label)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(previewInterval(for: grade))
                    .font(.caption2)
                    .opacity(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(tint)
    }

    // MARK: - Helpers

    private func previewInterval(for grade: SRSGrade) -> String {
        let result = srsEngine.calculateNextReview(
            grade: grade,
            currentInterval: card.interval,
            currentRepetitions: card.repetitions,
            currentEaseFactor: card.easeFactor
        )
        return result.interval == 1 ? "1d" : "\(result.interval)d"
    }

    private func applyGrade(_ grade: SRSGrade) {
        feedbackTrigger += 1
        let log = srsEngine.processReview(for: card, grade: grade)
        modelContext.insert(log)
        try? modelContext.save()
        onGraded(grade)
    }
}

#Preview {
    let mockCard = CharacterCard(
        id: "hira_a",
        character: "あ",
        romaji: "a",
        primaryMeaning: "a (vowel)",
        category: .hiragana,
        strokeCount: 3
    )

    return ReviewControlBar(
        card: mockCard,
        srsEngine: SRSEngine(),
        onGraded: { _ in }
    )
    .padding()
    .modelContainer(PreviewContainer.shared)
}
