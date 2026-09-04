import SwiftData
import SwiftUI

/// Clean binary (Forgot / Got It) bottom review dock replacing the legacy 4 pastel circles with native haptic feedback.
struct ReviewControlBar: View {
    let card: CharacterCard
    let srsEngine: SRSEngine
    var suggestedGrade: SRSGrade? = nil
    let onGraded: (SRSGrade) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var feedbackTriggerSuccess: Int = 0
    @State private var feedbackTriggerWarning: Int = 0

    var body: some View {
        HStack(spacing: 12) {
            // Left Action: Forgot / Repeat
            Button {
                feedbackTriggerWarning += 1
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                applyGrade(.forgot)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Forgot")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(uiColor: .secondarySystemFill), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(Color.red.opacity(0.85))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Forgot card, repeat review")

            // Right Action: Got It / Remembered
            Button {
                feedbackTriggerSuccess += 1
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                applyGrade(.remembered)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Text("Got It")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.tsumugiDustyDenim, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(.white)
                .shadow(color: Color.tsumugiDustyDenim.opacity(0.3), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Got it, mark remembered")
        }
        .padding(.horizontal, 20)
        .sensoryFeedback(.warning, trigger: feedbackTriggerWarning)
        .sensoryFeedback(.success, trigger: feedbackTriggerSuccess)
    }

    // MARK: - Helpers

    private func applyGrade(_ grade: SRSGrade) {
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
        suggestedGrade: .remembered,
        onGraded: { _ in }
    )
    .padding()
    .modelContainer(PreviewContainer.shared)
}
