import SwiftUI

/// Stage selection sheet and 5-column progression grid for the 50-stage Radical Fusion campaign.
struct RadicalFusionStageSelectView: View {
    let stages: [RadicalFusionPuzzle]
    @Binding var currentStageIndex: Int
    let clearedStageIds: Set<Int>
    let highestUnlockedStage: Int
    var onSelectStage: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Header progress summary
                headerProgressSummary

                // 5-Column Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(stages) { stage in
                            stageTile(for: stage)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Radical Fusion Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
            }
        }
    }

    // MARK: - Header Progress Summary

    private var headerProgressSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Campaign Progress")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.tsumugiChartreuse)

                    Text("\(clearedStageIds.count) of \(stages.count) Completed")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiTextPrimary)
                }
            }

            Spacer()

            // Completion percentage badge
            let percent = stages.isEmpty ? 0 : Int((Double(clearedStageIds.count) / Double(stages.count)) * 100)
            Text("\(percent)%")
                .font(.title3)
                .fontWeight(.heavy)
                .foregroundStyle(Color.tsumugiDustyDenim)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.tsumugiDustyDenim.opacity(0.12), in: Capsule())
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
        .padding(.top, 8)
    }

    // MARK: - Stage Tile

    private func stageTile(for stage: RadicalFusionPuzzle) -> some View {
        let isCleared = clearedStageIds.contains(stage.id)
        let isUnlocked = stage.id <= highestUnlockedStage
        let isCurrent = (currentStageIndex + 1) == stage.id

        return Button {
            if isUnlocked {
                onSelectStage(stage.id - 1)
                dismiss()
            }
        } label: {
            VStack(spacing: 2) {
                // Top Indicator (Checkmark, Stage Number, or Padlock)
                HStack {
                    Text("\(stage.id)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isCurrent ? Color.white : (isUnlocked ? Color.secondary : Color.secondary.opacity(0.5)))

                    Spacer()

                    if isCleared {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.tsumugiChartreuse)
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary.opacity(0.6))
                    }
                }

                Spacer()

                // Result Kanji or Lock
                if isUnlocked {
                    Text(stage.resultKanji)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(isCurrent ? Color.white : Color.tsumugiTextPrimary)
                } else {
                    Image(systemName: "questionmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(0.4))
                }

                Spacer()
            }
            .padding(8)
            .frame(height: 72)
            .background(tileBackground(isCurrent: isCurrent, isUnlocked: isUnlocked, isCleared: isCleared))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(tileBorderColor(isCurrent: isCurrent, isUnlocked: isUnlocked, isCleared: isCleared), lineWidth: isCurrent ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    // MARK: - Visual Helpers

    private func tileBackground(isCurrent: Bool, isUnlocked: Bool, isCleared: Bool) -> Color {
        if isCurrent {
            return Color.tsumugiDustyDenim
        } else if isCleared {
            return Color(uiColor: .secondarySystemGroupedBackground)
        } else if isUnlocked {
            return Color(uiColor: .secondarySystemGroupedBackground)
        } else {
            return Color(uiColor: .tertiarySystemGroupedBackground).opacity(0.5)
        }
    }

    private func tileBorderColor(isCurrent: Bool, isUnlocked: Bool, isCleared: Bool) -> Color {
        if isCurrent {
            return Color.tsumugiChartreuse
        } else if isCleared {
            return Color.tsumugiChartreuse.opacity(0.6)
        } else if isUnlocked {
            return Color.tsumugiCardBorder
        } else {
            return Color.clear
        }
    }
}

#Preview {
    RadicalFusionStageSelectView(
        stages: RadicalFusionData.all50,
        currentStageIndex: .constant(0),
        clearedStageIds: [1, 2, 3],
        highestUnlockedStage: 4,
        onSelectStage: { _ in }
    )
}
