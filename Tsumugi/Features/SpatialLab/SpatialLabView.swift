import SwiftData
import SwiftUI

/// Main coordinator and hub view for the Spatial Lab domain (AR 3D air-drawing and radical puzzles).
struct SpatialLabView: View {
    enum LabMode: String, CaseIterable, Identifiable {
        case airDrawing = "3D Air Tracing"
        case radicalFusion = "Radical Fusion"

        var id: String { rawValue }
    }

    @Query(
        filter: #Predicate<CharacterCard> { card in
            card.isUnlocked
        },
        sort: \CharacterCard.character,
        order: .forward
    )
    private var unlockedCards: [CharacterCard]

    @State private var selectedMode: LabMode = .airDrawing
    @State private var selectedCharacterIndex: Int = 0
    @State private var showingARSheet: Bool = false

    private var activeCharacter: String {
        guard !unlockedCards.isEmpty, selectedCharacterIndex < unlockedCards.count else {
            return "あ"
        }
        return unlockedCards[selectedCharacterIndex].character
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    modePickerSection

                    if selectedMode == .airDrawing {
                        airDrawingSetupSection
                    } else {
                        RadicalAssemblyView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.tsumugiBackground)
            .navigationTitle("Spatial Lab")
            .fullScreenCover(isPresented: $showingARSheet) {
                NavigationStack {
                    SpatialAirDrawingView(
                        character: activeCharacter,
                        onComplete: {
                            showingARSheet = false
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") {
                                showingARSheet = false
                            }
                            .tint(.white)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mode Picker Section

    private var modePickerSection: some View {
        Picker("Spatial Lab Mode", selection: $selectedMode) {
            ForEach(LabMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 4)
    }

    // MARK: - Air Drawing Setup Section

    private var airDrawingSetupSection: some View {
        VStack(spacing: 20) {
            // Character Selection Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Target Character")
                    .font(.headline)
                    .foregroundStyle(Color.tsumugiSpaceIndigo)

                if unlockedCards.isEmpty {
                    ContentUnavailableView(
                        "No Unlocked Characters",
                        systemImage: "lock.fill",
                        description: Text("Unlock characters in your study deck to practice in 3D AR.")
                    )
                } else {
                    characterPickerGrid
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.tsumugiCardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.tsumugiFrozenWater.opacity(0.4), lineWidth: 1)
                    )
            )

            // Launch AR Button
            Button {
                showingARSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arkit")
                        .font(.title3)
                    Text("Launch 3D Spatial Canvas")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color.tsumugiDustyDenim)
        }
    }

    // MARK: - Character Picker Grid

    private var characterPickerGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(unlockedCards.enumerated()), id: \.element.id) { index, card in
                    Button {
                        selectedCharacterIndex = index
                    } label: {
                        VStack(spacing: 4) {
                            Text(card.character)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(selectedCharacterIndex == index ? Color.tsumugiSpaceIndigo : .secondary)

                            Text(card.romaji)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 64, height: 72)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selectedCharacterIndex == index ? Color.tsumugiChartreuse.opacity(0.5) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(selectedCharacterIndex == index ? Color.tsumugiChartreuse : Color.secondary.opacity(0.2), lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    SpatialLabView()
        .modelContainer(PreviewContainer.shared)
}
