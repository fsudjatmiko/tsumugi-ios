import SwiftData
import SwiftUI

/// Control bar providing SM-2 review rating actions with recommended badge indicator and native haptic feedback.
struct ReviewControlBar: View {
    let card: CharacterCard
    let srsEngine: SRSEngine
    var suggestedGrade: SRSGrade? = nil
    let onGraded: (SRSGrade) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var feedbackTrigger: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            if let suggested = suggestedGrade {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("Suggested Grade: \(suggested.label)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.tsumugiDustyDenim)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.tsumugiDustyDenim.opacity(0.12))
                .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                ForEach(SRSGrade.allCases) { grade in
                    gradeButton(grade: grade)
                }
            }
        }
        .padding(.horizontal, 16)
        .sensoryFeedback(.impact, trigger: feedbackTrigger)
    }

    // MARK: - Button ViewBuilder

    @ViewBuilder
    private func gradeButton(grade: SRSGrade) -> some View {
        let isSuggested = suggestedGrade == grade

        Button {
            applyGrade(grade)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: grade.iconName)
                    .font(.footnote)
                    .fontWeight(.bold)

                Text(grade.label)
                    .font(.caption)
                    .fontWeight(isSuggested ? .bold : .semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(previewInterval(for: grade))
                    .font(.caption2)
                    .opacity(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .tint(grade.tint)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSuggested ? grade.tint : Color.clear, lineWidth: 2)
        )
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
        suggestedGrade: .good,
        onGraded: { _ in }
    )
    .padding()
    .modelContainer(PreviewContainer.shared)
}
