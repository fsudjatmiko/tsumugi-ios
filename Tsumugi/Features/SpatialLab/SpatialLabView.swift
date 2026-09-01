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

    private var activeCard: CharacterCard? {
        guard !unlockedCards.isEmpty, selectedCharacterIndex < unlockedCards.count else {
            return unlockedCards.first
        }
        return unlockedCards[selectedCharacterIndex]
    }

    private var activeCharacter: String {
        activeCard?.character ?? "あ"
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
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Spatial Lab")
            .navigationBarTitleDisplayMode(.large)
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
            if #available(iOS 18.0, *) {
                // Active iOS 18+ RealityView Character Selection & Setup
                characterSelectionCard

                // Launch 3D Spatial Canvas
                Button {
                    showingARSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "cube.transparent")
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
                .disabled(unlockedCards.isEmpty)
            } else {
                // Native iOS 17 Fallback State
                ContentUnavailableView(
                    "Spatial Lab Unavailable",
                    systemImage: "cube.transparent",
                    description: Text("Spatial 3D character interaction requires iOS 18.0 or newer. Please update your device to explore Spatial Lab.")
                )
                .padding(.vertical, 16)

                // 2D Character Details Preview for iOS 17
                if !unlockedCards.isEmpty {
                    characterSelectionCard
                }
            }
        }
    }

    // MARK: - Character Selection Card

    private var characterSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Target Character")
                    .font(.headline)
                    .foregroundStyle(Color.tsumugiTextPrimary)

                Spacer()

                if let card = activeCard {
                    Text("\(card.romaji) • \(card.primaryMeaning)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if unlockedCards.isEmpty {
                ContentUnavailableView(
                    "No Unlocked Characters",
                    systemImage: "lock.fill",
                    description: Text("Unlock characters in your study deck to practice in Spatial Lab.")
                )
            } else {
                characterPickerGrid
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                )
        )
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
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(selectedCharacterIndex == index ? Color.tsumugiTextPrimary : .secondary)

                            Text(card.romaji)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 64, height: 72)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selectedCharacterIndex == index ? Color.tsumugiChartreuse.opacity(0.35) : Color(uiColor: .systemGroupedBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(selectedCharacterIndex == index ? Color.tsumugiChartreuse : Color.tsumugiCardBorder, lineWidth: selectedCharacterIndex == index ? 1.5 : 1)
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
