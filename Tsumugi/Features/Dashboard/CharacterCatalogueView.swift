import SwiftData
import SwiftUI

/// Dedicated Gojūon character matrix and cluster catalogue browser for Hiragana, Katakana, and Kanji.
struct CharacterCatalogueView: View {
    let category: WritingCategory

    @Environment(\.modelContext) private var modelContext
    @Query private var allCategoryCards: [CharacterCard]

    @State private var selectedCard: CharacterCard?
    @State private var practiceCard: CharacterCard?
    @State private var filterUnlockedOnly: Bool = false
    @State private var audioService = AudioService()

    // Canonical Kanji cluster ordering
    private static let kanjiClusterOrder = [
        "Numbers & Counters",
        "Quantity, Scale & Position",
        "Nature, Elements & Time",
        "People, Body & Society",
        "Animals & Living Things",
        "Directions & Space",
        "Actions, States & Quality"
    ]

    init(category: WritingCategory) {
        self.category = category
        let rawCategory = category.rawValue
        _allCategoryCards = Query(
            filter: #Predicate<CharacterCard> { card in
                card.categoryRaw == rawCategory
            },
            sort: \CharacterCard.id,
            order: .forward
        )
    }

    private var unlockedCount: Int {
        allCategoryCards.filter { $0.isUnlocked }.count
    }

    private var masteredCount: Int {
        allCategoryCards.filter { $0.interval >= 21 }.count
    }

    private var filteredCards: [CharacterCard] {
        if filterUnlockedOnly {
            return allCategoryCards.filter { $0.isUnlocked }
        }
        return allCategoryCards
    }

    // Grid columns: 5 for Kana matrix, 4 for rich Kanji grid
    private var columns: [GridItem] {
        if category == .kanji {
            return Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        } else {
            return Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Stats Bar
                headerStatsCard

                // Category-specific Layout
                if category == .kanji {
                    kanjiClusterSectionView
                } else {
                    kanaGridView(cards: filteredCards)
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("\(category.displayName) Catalogue")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Show Unlocked Only", isOn: $filterUnlockedOnly)
                } label: {
                    Image(systemName: filterUnlockedOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(Color.tsumugiDustyDenim)
                }
            }
        }
        .sheet(item: $selectedCard) { card in
            CharacterDetailSheet(
                card: card,
                audioService: audioService,
                onStartPractice: {
                    selectedCard = nil
                    practiceCard = card
                }
            )
            .presentationDetents(category == .kanji ? [.fraction(0.85), .large] : [.medium, .fraction(0.65)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $practiceCard) { card in
            NavigationStack {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Practice Stroke Tracing")
                                .font(.headline)
                                .foregroundStyle(Color.tsumugiTextPrimary)
                            Text("\(card.character) • \(card.romaji) (\(card.primaryMeaning))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            audioService.speak(card.character)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title3)
                                .foregroundStyle(Color.tsumugiDustyDenim)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    StrokeCanvasView(
                        character: card.character,
                        strokeCount: card.strokeCount,
                        audioService: audioService,
                        showGhostGuide: true
                    )

                    Spacer()
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle(card.character)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            practiceCard = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header Stats Card

    private var headerStatsCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(unlockedCount)/\(max(1, allCategoryCards.count)) Unlocked")
                    .font(.headline)
                    .foregroundStyle(Color.tsumugiTextPrimary)

                Text("\(masteredCount) Mastered (SRS Level >= 21d)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Visual Progress Pill
            let progress = allCategoryCards.isEmpty ? 0.0 : Double(masteredCount) / Double(allCategoryCards.count)
            Text("\(Int(progress * 100))% Complete")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.tsumugiDustyDenim)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.tsumugiDustyDenim.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Kana Grid View

    private func kanaGridView(cards: [CharacterCard]) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(cards) { card in
                kanaCharacterTile(card: card)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Kanji Cluster Sections

    private var kanjiClusterSectionView: some View {
        LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
            ForEach(Self.kanjiClusterOrder, id: \.self) { clusterName in
                let clusterCards = filteredCards.filter { ($0.clusterCategory ?? "General") == clusterName }
                if !clusterCards.isEmpty {
                    Section {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(clusterCards) { card in
                                kanjiCharacterTile(card: card)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    } header: {
                        clusterHeader(title: clusterName, count: clusterCards.count)
                    }
                }
            }
        }
    }

    private func clusterHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.tsumugiTextPrimary)

            Spacer()

            Text("\(count) Kanji")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemGroupedBackground).opacity(0.95))
    }

    // MARK: - Character Tiles

    private func kanaCharacterTile(card: CharacterCard) -> some View {
        let isMastered = card.interval >= 21
        let isUnlocked = card.isUnlocked

        return Button {
            if isUnlocked {
                selectedCard = card
                audioService.speak(card.character)
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Text(card.character)
                        .font(.system(size: 26, weight: .medium, design: .serif))
                        .foregroundStyle(isUnlocked ? Color.tsumugiTextPrimary : Color.secondary.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)

                    if isMastered {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.tsumugiChartreuse)
                            .offset(x: 4, y: -4)
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.6))
                            .offset(x: 4, y: -4)
                    }
                }

                Text(isUnlocked ? card.romaji : "••")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(isUnlocked ? Color.tsumugiTextSecondary : Color.secondary.opacity(0.3))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isUnlocked ? Color(uiColor: .secondarySystemGroupedBackground) : Color(uiColor: .secondarySystemGroupedBackground).opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isMastered ? Color.tsumugiChartreuse.opacity(0.8) : Color.tsumugiCardBorder.opacity(isUnlocked ? 1.0 : 0.4),
                                lineWidth: isMastered ? 1.5 : 1
                            )
                    )
            )
            .shadow(
                color: isMastered ? Color.tsumugiChartreuse.opacity(0.15) : .clear,
                radius: 4
            )
            .opacity(isUnlocked ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    private func kanjiCharacterTile(card: CharacterCard) -> some View {
        let isMastered = card.interval >= 21
        let isUnlocked = card.isUnlocked

        return Button {
            if isUnlocked {
                selectedCard = card
                audioService.speak(card.character)
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Text(card.character)
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .foregroundStyle(isUnlocked ? Color.tsumugiTextPrimary : Color.secondary.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)

                    if isMastered {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.tsumugiChartreuse)
                            .offset(x: 2, y: -2)
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.6))
                            .offset(x: 2, y: -2)
                    }
                }

                Text(isUnlocked ? card.primaryMeaning : "Locked")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isUnlocked ? Color.tsumugiTextPrimary : Color.secondary.opacity(0.4))
                    .lineLimit(1)

                // Stroke count pill
                Text("\(card.strokeCount) strokes")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.tsumugiFrozenWater.opacity(isUnlocked ? 0.35 : 0.15))
                    .clipShape(Capsule())
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isUnlocked ? Color(uiColor: .secondarySystemGroupedBackground) : Color(uiColor: .secondarySystemGroupedBackground).opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isMastered ? Color.tsumugiChartreuse.opacity(0.8) : Color.tsumugiCardBorder.opacity(isUnlocked ? 1.0 : 0.4),
                                lineWidth: isMastered ? 1.5 : 1
                            )
                    )
            )
            .shadow(
                color: isMastered ? Color.tsumugiChartreuse.opacity(0.15) : .clear,
                radius: 4
            )
            .opacity(isUnlocked ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}

// MARK: - Character Detail Sheet

struct CharacterDetailSheet: View {
    let card: CharacterCard
    let audioService: AudioService
    let onStartPractice: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Header: Glyphs & Pronunciation
                HStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.tsumugiDustyDenim.opacity(0.12))
                            .frame(width: 80, height: 80)

                        Text(card.character)
                            .font(.system(size: 46, weight: .medium, design: .serif))
                            .foregroundStyle(Color.tsumugiTextPrimary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(card.romaji.isEmpty ? card.primaryMeaning : card.romaji)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.tsumugiTextPrimary)

                            Button {
                                audioService.speak(card.character)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.headline)
                                    .foregroundStyle(Color.tsumugiDustyDenim)
                            }
                            .buttonStyle(.plain)
                        }

                        Text(card.primaryMeaning)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Onyomi & Kunyomi Section (for Kanji)
                if card.category == .kanji {
                    readingsSection
                }

                // Compound Vocabulary Examples Section (for Kanji)
                if card.category == .kanji && !card.compoundExamples.isEmpty {
                    examplesSection
                }

                // Metadata Grid
                HStack(spacing: 12) {
                    metadataPill(title: "Strokes", value: "\(card.strokeCount)")
                    metadataPill(title: "SRS Interval", value: "\(card.interval)d")
                    metadataPill(title: "Repetitions", value: "\(card.repetitions)")
                    metadataPill(title: "Status", value: card.interval >= 21 ? "Mastered" : (card.isUnlocked ? "Learning" : "Locked"))
                }
                .padding(.horizontal, 20)

                // Practice Button
                Button(action: onStartPractice) {
                    Label("Practice Strokes", systemImage: "pencil.tip.crop.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.tsumugiDustyDenim)
                .controlSize(.large)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Readings Section

    private var readingsSection: some View {
        HStack(alignment: .top, spacing: 14) {
            // Onyomi
            VStack(alignment: .leading, spacing: 6) {
                Text("音読み (Onyomi)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                if card.onyxomi.isEmpty {
                    Text("—")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    WrapHStack(items: card.onyxomi) { reading in
                        Text(reading)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.tsumugiSpaceIndigo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.tsumugiFrozenWater.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                    )
            )

            // Kunyomi
            VStack(alignment: .leading, spacing: 6) {
                Text("訓読み (Kunyomi)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                if card.kunyomi.isEmpty {
                    Text("—")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    WrapHStack(items: card.kunyomi) { reading in
                        Text(reading)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.tsumugiTextPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.tsumugiDustyDenim.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Vocabulary Examples Section

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Compound Vocabulary")
                .font(.headline)
                .foregroundStyle(Color.tsumugiTextPrimary)

            VStack(spacing: 8) {
                ForEach(card.compoundExamples, id: \.text) { example in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(example.text)
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundStyle(Color.tsumugiTextPrimary)

                                Text("【\(example.kana)】")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(example.english)
                                .font(.caption)
                                .foregroundStyle(Color.tsumugiTextSecondary)
                        }

                        Spacer()

                        Button {
                            audioService.speak(example.text)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.tsumugiDustyDenim)
                                .padding(8)
                                .background(Color.tsumugiDustyDenim.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func metadataPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.tsumugiTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Flow / Wrapping HStack Helper

private struct WrapHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    @ViewBuilder let content: (Data.Element) -> Content

    var body: some View {
        // Horizontal layout with wrapping fallback
        HStack(spacing: 6) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CharacterCatalogueView(category: .kanji)
            .modelContainer(PreviewContainer.shared)
    }
}
