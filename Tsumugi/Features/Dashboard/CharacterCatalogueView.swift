import SwiftData
import SwiftUI

/// Dedicated Gojūon 5-column character matrix and catalogue browser for Hiragana, Katakana, and Kanji.
struct CharacterCatalogueView: View {
    let category: WritingCategory

    @Environment(\.modelContext) private var modelContext
    @Query private var allCategoryCards: [CharacterCard]

    @State private var selectedCard: CharacterCard?
    @State private var practiceCard: CharacterCard?
    @State private var filterUnlockedOnly: Bool = false
    @State private var audioService = AudioService()

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

    // Gojūon 5-column grid layout
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Stats Bar
                headerStatsCard

                // 5-Column Grid Matrix
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredCards) { card in
                        characterTile(card: card)
                    }
                }
                .padding(.horizontal, 16)
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
            .presentationDetents([.medium, .fraction(0.65)])
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

    // MARK: - Character Tile

    private func characterTile(card: CharacterCard) -> some View {
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
}

// MARK: - Character Detail Sheet

struct CharacterDetailSheet: View {
    let card: CharacterCard
    let audioService: AudioService
    let onStartPractice: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
                        Text(card.romaji)
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

            // Metadata Grid
            HStack(spacing: 12) {
                metadataPill(title: "Strokes", value: "\(card.strokeCount)")
                metadataPill(title: "SRS Interval", value: "\(card.interval)d")
                metadataPill(title: "Repetitions", value: "\(card.repetitions)")
                metadataPill(title: "Status", value: card.interval >= 21 ? "Mastered" : (card.isUnlocked ? "Learning" : "Locked"))
            }
            .padding(.horizontal, 20)

            Spacer()

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
        .background(Color(uiColor: .systemGroupedBackground))
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

#Preview {
    NavigationStack {
        CharacterCatalogueView(category: .hiragana)
            .modelContainer(PreviewContainer.shared)
    }
}
