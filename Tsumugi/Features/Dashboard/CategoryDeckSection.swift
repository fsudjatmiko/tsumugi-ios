import SwiftData
import SwiftUI

/// Section displaying mastery breakdown cards for Hiragana, Katakana, and Kanji with mini progress rings.
struct CategoryDeckSection: View {
    let cards: [CharacterCard]
    let onSelectCategory: (WritingCategory) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Curriculum Mastery")
                    .font(.headline)
                    .foregroundStyle(Color.tsumugiTextPrimary)

                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(WritingCategory.allCases) { category in
                    categoryRowCard(for: category)
                }
            }
        }
    }

    // MARK: - Category Row Card

    private func categoryRowCard(for category: WritingCategory) -> some View {
        let categoryCards = cards.filter { $0.category == category }
        let totalCount = categoryCards.count
        let unlockedCount = categoryCards.filter { $0.isUnlocked }.count
        let masteredCount = categoryCards.filter { $0.interval >= 21 }.count
        let progress = totalCount > 0 ? Double(masteredCount) / Double(totalCount) : 0.0

        return Button {
            onSelectCategory(category)
        } label: {
            HStack(spacing: 16) {
                // Mini Progress Ring
                ZStack {
                    Circle()
                        .stroke(
                            Color.tsumugiFrozenWater.opacity(0.3),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.tsumugiDustyDenim,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text(category.japaneseTitle.prefix(1))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiTextPrimary)
                }
                .frame(width: 52, height: 52)

                // Text Information
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(category.displayName)
                            .font(.headline)
                            .foregroundStyle(Color.tsumugiTextPrimary)

                        Text("(\(category.japaneseTitle))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        Text("\(unlockedCount)/\(max(1, totalCount)) Unlocked")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("\(masteredCount) Mastered")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.tsumugiDustyDenim)
                    }
                }

                Spacer()

                // Percentage & Chevron
                HStack(spacing: 6) {
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiTextPrimary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.tsumugiCardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let mockCards = [
        CharacterCard(id: "1", character: "あ", romaji: "a", primaryMeaning: "a", category: .hiragana, strokeCount: 3, interval: 25, isUnlocked: true),
        CharacterCard(id: "2", character: "ア", romaji: "a", primaryMeaning: "a", category: .katakana, strokeCount: 2, interval: 5, isUnlocked: true),
        CharacterCard(id: "3", character: "一", romaji: "ichi", primaryMeaning: "one", category: .kanji, strokeCount: 1, interval: 0, isUnlocked: true)
    ]

    return CategoryDeckSection(cards: mockCards, onSelectCategory: { _ in })
        .padding()
        .modelContainer(PreviewContainer.shared)
}
