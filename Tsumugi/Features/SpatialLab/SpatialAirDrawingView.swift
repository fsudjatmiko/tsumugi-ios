import ARKit
import RealityKit
import SwiftData
import SwiftUI

/// AR surface-tracing view projecting flat Japanese character stencils onto real-world flat surfaces and elevating them into 3D on mastery.
struct SpatialAirDrawingView: View {
    @State private var activeCharacter: String
    var onComplete: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @Query(
        filter: #Predicate<CharacterCard> { card in
            card.isUnlocked
        },
        sort: \CharacterCard.character,
        order: .forward
    )
    private var unlockedCards: [CharacterCard]

    @State private var hasDetectedSurface: Bool = false
    @State private var isSurfaceLocked: Bool = false
    @State private var currentStrokeIndex: Int = 0
    @State private var completedStrokeCount: Int = 0
    @State private var isSuccess: Bool = false
    @State private var strokeClearTrigger: Int = 0
    @State private var showSelectorDrawer: Bool = false
    @State private var selectorFilter: WritingCategory? = nil

    init(
        character: String,
        onComplete: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self._activeCharacter = State(initialValue: character)
        self.onComplete = onComplete
        self.onClose = onClose
    }

    private var activeStrokeCount: Int {
        if let card = unlockedCards.first(where: { $0.character == activeCharacter }) {
            return card.strokeCount
        }
        return StrokeGuide.defaultGuide(for: activeCharacter, strokeCount: 1).strokeCount
    }

    private var filteredUnlockedCards: [CharacterCard] {
        if let filter = selectorFilter {
            let rawFilter = filter.rawValue
            return unlockedCards.filter { $0.categoryRaw == rawFilter }
        }
        return unlockedCards
    }

    var body: some View {
        ZStack(alignment: .top) {
            #if targetEnvironment(simulator)
            simulatorFallbackView
            #else
            ARAirDrawingCanvas(
                character: activeCharacter,
                strokeCount: activeStrokeCount,
                isSurfaceLocked: isSurfaceLocked,
                isSuccess: isSuccess,
                clearTrigger: strokeClearTrigger,
                hasDetectedSurface: $hasDetectedSurface,
                currentStrokeIndex: $currentStrokeIndex,
                completedStrokeCount: $completedStrokeCount,
                onPlaneTapped: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        isSurfaceLocked = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                },
                onStrokeSuccess: { strokeIdx in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                },
                onCharacterCompleted: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isSuccess = true
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        AudioService.shared.speak(activeCharacter)
                    }
                }
            )
            .ignoresSafeArea()
            #endif

            // Dynamic 3-Stage Glassmorphic HUD Overlay
            hudOverlay
        }
        .sheet(isPresented: $showSelectorDrawer) {
            unlockedCharacterSelectorSheet
                .presentationDetents([.medium, .fraction(0.75)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Simulator Fallback View

    private var simulatorFallbackView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.tsumugiSpaceIndigo)
                        .frame(width: 240, height: 240)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(isSuccess ? Color.tsumugiChartreuse : Color.tsumugiDustyDenim, lineWidth: 3)
                        )

                    Text(activeCharacter)
                        .font(.system(size: 110, weight: .bold, design: .serif))
                        .foregroundStyle(isSuccess ? Color.tsumugiChartreuse : Color.tsumugiDustyDenim)
                        .shadow(color: isSuccess ? Color.tsumugiChartreuse.opacity(0.8) : .clear, radius: 12)
                }

                Text("Surface Tracing Simulation (Simulator)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("Strokes: \(completedStrokeCount)/\(activeStrokeCount)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.tsumugiChartreuse)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    completedStrokeCount += 1
                    if completedStrokeCount >= activeStrokeCount && !isSuccess {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            isSuccess = true
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            AudioService.shared.speak(activeCharacter)
                        }
                    }
                }
        )
    }

    // MARK: - HUD Overlay

    private var hudOverlay: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack(spacing: 12) {
                Button {
                    if let onClose = onClose {
                        onClose()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.tsumugiTextPrimary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close AR Canvas")

                // Unlocked Character Selector Button
                Button {
                    showSelectorDrawer = true
                } label: {
                    HStack(spacing: 6) {
                        Text(activeCharacter)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tsumugiTextPrimary)

                        Text("Change")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.tsumugiDustyDenim)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.tsumugiDustyDenim)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                // Stage Status Badge
                HStack(spacing: 6) {
                    if isSuccess {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.tsumugiSpaceIndigo)
                        Text("3D Mastered")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.tsumugiSpaceIndigo)
                    } else if isSurfaceLocked {
                        Image(systemName: "pencil.and.outline")
                            .foregroundStyle(Color.tsumugiDustyDenim)
                        Text("Stroke \(min(currentStrokeIndex + 1, activeStrokeCount))/\(activeStrokeCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.tsumugiTextPrimary)
                    } else if hasDetectedSurface {
                        Image(systemName: "viewfinder")
                            .foregroundStyle(Color.tsumugiChartreuse)
                        Text("Surface Ready")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.tsumugiTextPrimary)
                    } else {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Scanning...")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.tsumugiTextPrimary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSuccess ? Color.tsumugiChartreuse : Color.clear)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Dynamic Stage-Aware Guiding Instruction Card
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: instructionIcon)
                        .font(.subheadline)
                        .foregroundStyle(isSuccess ? Color.tsumugiChartreuse : Color.tsumugiDustyDenim)

                    Text(instructionTitle)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiTextPrimary)
                }

                Text(instructionSubtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.tsumugiCardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Spacer()

            // Bottom Action Controls
            if isSurfaceLocked {
                HStack(spacing: 16) {
                    Button {
                        clearStrokes()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.tsumugiTextPrimary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if isSuccess {
                        Button {
                            if let next = nextUnlockedCharacter() {
                                selectNewCharacter(next)
                            } else if let onComplete = onComplete {
                                onComplete()
                            } else {
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Next Character")
                                Image(systemName: "arrow.right")
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.tsumugiSpaceIndigo)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(Color.tsumugiChartreuse, in: Capsule())
                            .shadow(color: Color.tsumugiChartreuse.opacity(0.4), radius: 8, y: 3)
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            } else if hasDetectedSurface {
                // Prompt to Lock
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        isSurfaceLocked = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Place '\(activeCharacter)' on Surface")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.tsumugiSpaceIndigo)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.tsumugiChartreuse, in: Capsule())
                    .shadow(color: Color.tsumugiChartreuse.opacity(0.4), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Unlocked Character Selector Sheet

    private var unlockedCharacterSelectorSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Category Filter Segmented Control
                Picker("Category", selection: $selectorFilter) {
                    Text("All").tag(WritingCategory?.none)
                    ForEach(WritingCategory.allCases) { cat in
                        Text(cat.displayName).tag(Optional(cat))
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if filteredUnlockedCards.isEmpty {
                    ContentUnavailableView(
                        "No Characters",
                        systemImage: "lock.fill",
                        description: Text("Unlock more characters in the study deck to practice.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 12) {
                            ForEach(filteredUnlockedCards) { card in
                                Button {
                                    selectNewCharacter(card.character)
                                    showSelectorDrawer = false
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(card.character)
                                            .font(.system(size: 24, weight: .bold, design: .serif))
                                            .foregroundStyle(activeCharacter == card.character ? Color.tsumugiSpaceIndigo : Color.tsumugiTextPrimary)

                                        Text(card.romaji)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundStyle(activeCharacter == card.character ? Color.tsumugiSpaceIndigo.opacity(0.8) : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 64)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(activeCharacter == card.character ? Color.tsumugiChartreuse : Color(uiColor: .secondarySystemGroupedBackground))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(activeCharacter == card.character ? Color.tsumugiChartreuse : Color.tsumugiCardBorder, lineWidth: 1.5)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Select Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showSelectorDrawer = false
                    }
                }
            }
        }
    }

    // MARK: - Character Switching & Progression

    private func selectNewCharacter(_ newCharacter: String) {
        activeCharacter = newCharacter
        clearStrokes()
        AudioService.shared.speak(newCharacter)
    }

    private func nextUnlockedCharacter() -> String? {
        guard !unlockedCards.isEmpty else { return nil }
        if let currentIndex = unlockedCards.firstIndex(where: { $0.character == activeCharacter }) {
            let nextIndex = (currentIndex + 1) % unlockedCards.count
            return unlockedCards[nextIndex].character
        }
        return unlockedCards.first?.character
    }

    // MARK: - Instruction State Helpers

    private var instructionIcon: String {
        if isSuccess {
            return "checkmark.circle.fill"
        } else if isSurfaceLocked {
            return "hand.draw.fill"
        } else if hasDetectedSurface {
            return "hand.tap.fill"
        } else {
            return "iphone.radiowaves.left.and.right"
        }
    }

    private var instructionTitle: String {
        if isSuccess {
            return "Mastered in 3D!"
        } else if isSurfaceLocked {
            return "Trace Stroke \(min(currentStrokeIndex + 1, activeStrokeCount)) of \(activeStrokeCount)"
        } else if hasDetectedSurface {
            return "Flat Surface Detected"
        } else {
            return "Scanning for Flat Surface"
        }
    }

    private var instructionSubtitle: String {
        if isSuccess {
            return "The character has lifted into a full 3D sculpture on your desk."
        } else if isSurfaceLocked {
            return "Start at the green dot and draw along the stroke trajectory."
        } else if hasDetectedSurface {
            return "Tap the green reticle or button below to project the '\(activeCharacter)' template."
        } else {
            return "Slowly move your iPhone around to find a flat table, desk, or floor."
        }
    }

    // MARK: - Actions & Completion

    private func clearStrokes() {
        currentStrokeIndex = 0
        completedStrokeCount = 0
        isSuccess = false
        strokeClearTrigger += 1
    }
}

#Preview {
    SpatialAirDrawingView(character: "あ")
        .modelContainer(PreviewContainer.shared)
}
