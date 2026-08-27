import SwiftUI

/// Mini-game puzzle for decomposing and assembling Kanji radicals with snap-to-target physics.
struct RadicalAssemblyView: View {
    struct PuzzleScenario: Identifiable, Sendable {
        let id: String
        let targetKanji: String
        let targetMeaning: String
        let radicalLeft: String
        let radicalRight: String
        let leftMeaning: String
        let rightMeaning: String
    }

    let scenario: PuzzleScenario

    @State private var leftOffset: CGSize = CGSize(width: -80, height: 0)
    @State private var rightOffset: CGSize = CGSize(width: 80, height: 0)
    @State private var isSnapped: Bool = false
    @State private var feedbackTrigger: Int = 0

    init(scenario: PuzzleScenario = PuzzleScenario(
        id: "sun_moon",
        targetKanji: "明",
        targetMeaning: "Bright / Clear",
        radicalLeft: "日",
        radicalRight: "月",
        leftMeaning: "Sun / Day",
        rightMeaning: "Moon / Month"
    )) {
        self.scenario = scenario
    }

    var body: some View {
        VStack(spacing: 24) {
            instructionHeader

            puzzleStage

            if isSnapped {
                successCard
            } else {
                hintFooter
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .sensoryFeedback(.success, trigger: feedbackTrigger)
    }

    // MARK: - Instruction Header

    private var instructionHeader: some View {
        VStack(spacing: 6) {
            Text("Radical Fusion")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.tsumugiSpaceIndigo)

            Text("Drag the radicals together to forge the Kanji")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Puzzle Stage

    private var puzzleStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.tsumugiCardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(isSnapped ? Color.tsumugiChartreuse : Color.tsumugiFrozenWater.opacity(0.5), lineWidth: 2)
                )

            if isSnapped {
                VStack(spacing: 8) {
                    Text(scenario.targetKanji)
                        .font(.system(size: 100, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tsumugiSpaceIndigo)
                        .transition(.scale.combined(with: .opacity))

                    Text(scenario.targetMeaning)
                        .font(.headline)
                        .foregroundStyle(Color.tsumugiDustyDenim)
                }
            } else {
                HStack(spacing: 30) {
                    radicalTile(
                        character: scenario.radicalLeft,
                        meaning: scenario.leftMeaning,
                        offset: leftOffset,
                        isLeft: true
                    )

                    radicalTile(
                        character: scenario.radicalRight,
                        meaning: scenario.rightMeaning,
                        offset: rightOffset,
                        isLeft: false
                    )
                }
            }
        }
        .frame(height: 280)
    }

    // MARK: - Radical Tile

    private func radicalTile(
        character: String,
        meaning: String,
        offset: CGSize,
        isLeft: Bool
    ) -> some View {
        VStack(spacing: 6) {
            Text(character)
                .font(.system(size: 64, weight: .semibold, design: .serif))
                .foregroundStyle(Color.tsumugiSpaceIndigo)

            Text(meaning)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.tsumugiFrozenWater.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.tsumugiDustyDenim.opacity(0.5), lineWidth: 1)
                )
        )
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if isLeft {
                        leftOffset = CGSize(width: -80 + value.translation.width, height: value.translation.height)
                    } else {
                        rightOffset = CGSize(width: 80 + value.translation.width, height: value.translation.height)
                    }
                    checkSnapCondition()
                }
                .onEnded { _ in
                    if !isSnapped {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            leftOffset = CGSize(width: -80, height: 0)
                            rightOffset = CGSize(width: 80, height: 0)
                        }
                    }
                }
        )
    }

    // MARK: - Snapping Logic

    private func checkSnapCondition() {
        let distance = abs(rightOffset.width - leftOffset.width)
        if distance < 60 && !isSnapped {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isSnapped = true
                feedbackTrigger += 1
            }
        }
    }

    // MARK: - Success Card & Footer

    private var successCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(scenario.radicalLeft) (\(scenario.leftMeaning)) + \(scenario.radicalRight) (\(scenario.rightMeaning)) = \(scenario.targetKanji)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.tsumugiSpaceIndigo)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.tsumugiChartreuse.opacity(0.2))
            .clipShape(Capsule())

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isSnapped = false
                    leftOffset = CGSize(width: -80, height: 0)
                    rightOffset = CGSize(width: 80, height: 0)
                }
            } label: {
                Label("Reset Puzzle", systemImage: "arrow.counterclockwise")
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .tint(Color.tsumugiDustyDenim)
        }
    }

    private var hintFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.draw.fill")
                .font(.caption)
            Text("Drag left and right radical pieces together")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

#Preview {
    RadicalAssemblyView()
}
