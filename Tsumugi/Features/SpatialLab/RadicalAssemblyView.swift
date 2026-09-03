import SwiftUI

/// Progressive interactive mini-game for fusing Japanese Kanji radicals with snap-to-target physics across 50 campaign stages.
struct RadicalAssemblyView: View {
    let stages: [RadicalFusionPuzzle]
    @Binding var currentStageIndex: Int
    @Binding var highestUnlockedStage: Int
    @Binding var clearedStageIds: Set<Int>
    var onNextStage: (() -> Void)? = nil

    @State private var pieceAOffset: CGSize = .zero
    @State private var pieceBOffset: CGSize = .zero
    @State private var isSnapped: Bool = false
    @State private var feedbackTrigger: Int = 0
    @State private var showStageSelectSheet: Bool = false

    private var activeStage: RadicalFusionPuzzle {
        guard !stages.isEmpty, currentStageIndex < stages.count else {
            return RadicalFusionData.all50[0]
        }
        return stages[currentStageIndex]
    }

    init(
        stages: [RadicalFusionPuzzle] = RadicalFusionData.all50,
        currentStageIndex: Binding<Int>,
        highestUnlockedStage: Binding<Int>,
        clearedStageIds: Binding<Set<Int>>,
        onNextStage: (() -> Void)? = nil
    ) {
        self.stages = stages
        self._currentStageIndex = currentStageIndex
        self._highestUnlockedStage = highestUnlockedStage
        self._clearedStageIds = clearedStageIds
        self.onNextStage = onNextStage
    }

    // Default initializer for standalone or preview usage
    init(stages: [RadicalFusionPuzzle] = RadicalFusionData.all50) {
        self.stages = stages
        self._currentStageIndex = .constant(0)
        self._highestUnlockedStage = .constant(1)
        self._clearedStageIds = .constant([])
        self.onNextStage = nil
    }

    var body: some View {
        VStack(spacing: 20) {
            // Stage Header & Level Selector Bar
            stageHeaderBar

            // Interactive Drag Fusion Stage
            puzzleStage

            // Stage Result Card or Drag Guidance Footer
            if isSnapped {
                successCard
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            } else {
                hintFooter
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .sensoryFeedback(.success, trigger: feedbackTrigger)
        .sheet(isPresented: $showStageSelectSheet) {
            RadicalFusionStageSelectView(
                stages: stages,
                currentStageIndex: $currentStageIndex,
                clearedStageIds: clearedStageIds,
                highestUnlockedStage: highestUnlockedStage,
                onSelectStage: { selectedIdx in
                    loadStage(index: selectedIdx)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: currentStageIndex) { _, _ in
            resetOffsets()
        }
        .onAppear {
            resetOffsets()
        }
    }

    // MARK: - Stage Header Bar

    private var stageHeaderBar: some View {
        HStack(spacing: 12) {
            // Stage Picker Button
            Button {
                showStageSelectSheet = true
            } label: {
                HStack(spacing: 6) {
                    Text(activeStage.stageTitle)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiTextPrimary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.tsumugiDustyDenim)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Spacer()

            // Progress Pill Counter
            Button {
                showStageSelectSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.caption2)
                    Text("\(clearedStageIds.count)/\(stages.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundStyle(Color.tsumugiSpaceIndigo)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.tsumugiChartreuse, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Puzzle Stage

    private var puzzleStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(isSnapped ? Color.tsumugiChartreuse : Color.tsumugiCardBorder, lineWidth: 2)
                )

            if isSnapped {
                // Forged Kanji Presentation
                VStack(spacing: 6) {
                    Text(activeStage.resultKanji)
                        .font(.system(size: 96, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tsumugiTextPrimary)
                        .shadow(color: Color.tsumugiChartreuse.opacity(0.4), radius: 10)

                    Text(activeStage.resultMeaning)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiDustyDenim)

                    HStack(spacing: 12) {
                        Text("On: \(activeStage.onyomi)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Text("Kun: \(activeStage.kunyomi)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 12)
            } else {
                // Unsnapped Floating Radicals
                if activeStage.layout == .vertical {
                    VStack(spacing: 28) {
                        radicalTile(
                            character: activeStage.pieceA,
                            meaning: activeStage.pieceALabel,
                            offset: pieceAOffset,
                            isFirst: true
                        )

                        radicalTile(
                            character: activeStage.pieceB,
                            meaning: activeStage.pieceBLabel,
                            offset: pieceBOffset,
                            isFirst: false
                        )
                    }
                } else {
                    HStack(spacing: 32) {
                        radicalTile(
                            character: activeStage.pieceA,
                            meaning: activeStage.pieceALabel,
                            offset: pieceAOffset,
                            isFirst: true
                        )

                        radicalTile(
                            character: activeStage.pieceB,
                            meaning: activeStage.pieceBLabel,
                            offset: pieceBOffset,
                            isFirst: false
                        )
                    }
                }
            }
        }
        .frame(height: 290)
    }

    // MARK: - Radical Tile

    private func radicalTile(
        character: String,
        meaning: String,
        offset: CGSize,
        isFirst: Bool
    ) -> some View {
        VStack(spacing: 4) {
            Text(character)
                .font(.system(size: 52, weight: .semibold, design: .serif))
                .foregroundStyle(Color.tsumugiTextPrimary)

            Text(meaning)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minWidth: 92, minHeight: 92)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .systemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.tsumugiDustyDenim.opacity(0.4), lineWidth: 1.5)
                )
        )
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard !isSnapped else { return }
                    if isFirst {
                        if activeStage.layout == .vertical {
                            pieceAOffset = CGSize(width: value.translation.width, height: -45 + value.translation.height)
                        } else {
                            pieceAOffset = CGSize(width: -65 + value.translation.width, height: value.translation.height)
                        }
                    } else {
                        if activeStage.layout == .vertical {
                            pieceBOffset = CGSize(width: value.translation.width, height: 45 + value.translation.height)
                        } else {
                            pieceBOffset = CGSize(width: 65 + value.translation.width, height: value.translation.height)
                        }
                    }
                    checkSnapCondition()
                }
                .onEnded { _ in
                    if !isSnapped {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            resetOffsets()
                        }
                    }
                }
        )
    }

    // MARK: - Snapping Logic

    private func checkSnapCondition() {
        let distance: CGFloat
        if activeStage.layout == .vertical {
            distance = abs(pieceBOffset.height - pieceAOffset.height)
        } else {
            distance = abs(pieceBOffset.width - pieceAOffset.width)
        }

        if distance < 50 && !isSnapped {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                isSnapped = true
                feedbackTrigger += 1
                AudioService.shared.speak(activeStage.resultKanji)

                // Persist Progress
                clearedStageIds.insert(activeStage.id)
                if activeStage.id >= highestUnlockedStage && activeStage.id < stages.count {
                    highestUnlockedStage = activeStage.id + 1
                }
            }
        }
    }

    private func resetOffsets() {
        isSnapped = false
        if activeStage.layout == .vertical {
            pieceAOffset = CGSize(width: 0, height: -45)
            pieceBOffset = CGSize(width: 0, height: 45)
        } else {
            pieceAOffset = CGSize(width: -65, height: 0)
            pieceBOffset = CGSize(width: 65, height: 0)
        }
    }

    private func loadStage(index: Int) {
        guard index >= 0 && index < stages.count else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentStageIndex = index
            resetOffsets()
        }
    }

    // MARK: - Success Card

    private var successCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Mnemonic Explanation
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(Color.tsumugiChartreuse)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Etymology & Mnemonic")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(activeStage.explanation)
                        .font(.subheadline)
                        .foregroundStyle(Color.tsumugiTextPrimary)
                }
            }

            Divider()

            // Compound Word Example & Audio
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compound Word")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(activeStage.compoundExample)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.tsumugiTextPrimary)
                }

                Spacer()

                Button {
                    AudioService.shared.speak(activeStage.resultKanji)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.tsumugiDustyDenim)
                        .frame(width: 36, height: 36)
                        .background(Color(uiColor: .systemGroupedBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pronounce forged Kanji")
            }

            // Next Stage or Completion Button
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        resetOffsets()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.tsumugiTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .systemGroupedBackground), in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                if currentStageIndex + 1 < stages.count {
                    Button {
                        loadStage(index: currentStageIndex + 1)
                        onNextStage?()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Next Stage")
                            Image(systemName: "arrow.right")
                        }
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiSpaceIndigo)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.tsumugiChartreuse, in: Capsule())
                        .shadow(color: Color.tsumugiChartreuse.opacity(0.35), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Campaign Completed Trophy Badge
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color.yellow)
                        Text("Campaign Completed! 🏆")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.tsumugiSpaceIndigo)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.tsumugiChartreuse, in: Capsule())
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.tsumugiChartreuse.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private var hintFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.draw.fill")
                .font(.caption)
            Text(activeStage.layout == .vertical ? "Drag top and bottom radicals together" : "Drag left and right radicals together")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

#Preview {
    RadicalAssemblyView()
}
