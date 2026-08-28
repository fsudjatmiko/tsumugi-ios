import SwiftData
import SwiftUI

/// Card showing mastery breakdown and progress bar for a specific WritingCategory.
struct CategoryRoadmapCard: View {
    let category: WritingCategory
    let cards: [CharacterCard]
    let onStartStudy: () -> Void

    private var categoryCards: [CharacterCard] {
        cards.filter { $0.category == category }
    }

    private var unlockedCount: Int {
        categoryCards.filter { $0.isUnlocked }.count
    }

    private var masteredCount: Int {
        categoryCards.filter { $0.interval >= 21 }.count
    }

    private var totalCount: Int {
        categoryCards.count
    }

    private var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(masteredCount) / Double(totalCount)
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                headerRow

                progressSection

                actionRow
            }
            .padding(.vertical, 4)
        } label: {
            Label(category.displayName, systemImage: iconName)
                .font(.headline)
                .foregroundStyle(Color.tsumugiTextPrimary)
        }
        .groupBoxStyle(.automatic)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            Text(category.japaneseTitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(masteredCount)/\(totalCount) Mastered")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.tsumugiDustyDenim)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: progressFraction)
                .tint(Color.tsumugiDustyDenim)

            HStack {
                Text("\(unlockedCount) Unlocked")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(progressFraction * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.tsumugiTextPrimary)
            }
        }
    }

    private var actionRow: some View {
        Button(action: onStartStudy) {
            HStack {
                Text("Study \(category.displayName)")
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .tint(Color.tsumugiDustyDenim)
    }

    private var iconName: String {
        switch category {
        case .hiragana:
            return "character.textbox"
        case .katakana:
            return "character"
        case .kanji:
            return "character.book.closed.fill"
        }
    }
}

#Preview {
    let mockCards = [
        CharacterCard(id: "1", character: "あ", romaji: "a", primaryMeaning: "a", category: .hiragana, strokeCount: 3, interval: 25, repetitions: 4, isUnlocked: true),
        CharacterCard(id: "2", character: "い", romaji: "i", primaryMeaning: "i", category: .hiragana, strokeCount: 2, interval: 10, repetitions: 2, isUnlocked: true),
        CharacterCard(id: "3", character: "う", romaji: "u", primaryMeaning: "u", category: .hiragana, strokeCount: 2, interval: 0, repetitions: 0, isUnlocked: false)
    ]

    return CategoryRoadmapCard(
        category: .hiragana,
        cards: mockCards,
        onStartStudy: {}
    )
    .padding()
    .modelContainer(PreviewContainer.shared)
}
