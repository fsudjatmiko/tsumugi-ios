import SwiftUI

/// Horizontal shelf of quick-action practice launchers for rapid recognition, stroke canvas, and radical fusion.
struct QuickDrillSection: View {
    let onLaunchDrill: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Practice Drills")
                .font(.headline)
                .foregroundStyle(Color.tsumugiTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    drillCard(
                        title: "Rapid Recall",
                        subtitle: "Speed flashcard drill",
                        icon: "bolt.fill",
                        color: Color.tsumugiDustyDenim,
                        id: "speed_drill"
                    )

                    drillCard(
                        title: "Stroke Studio",
                        subtitle: "Finger tracing canvas",
                        icon: "pencil.and.outline",
                        color: Color.tsumugiChartreuse,
                        id: "stroke_canvas"
                    )

                    drillCard(
                        title: "Radical Fusion",
                        subtitle: "3D Kanji puzzle",
                        icon: "puzzlepiece.fill",
                        color: Color.tsumugiDustyDenim,
                        id: "radical_puzzle"
                    )
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Drill Card

    private func drillCard(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        id: String
    ) -> some View {
        Button {
            onLaunchDrill(id)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color == Color.tsumugiChartreuse ? Color.tsumugiSpaceIndigo : color)
                        .padding(10)
                        .background(color == Color.tsumugiChartreuse ? Color.tsumugiChartreuse : color.opacity(0.15))
                        .clipShape(Circle())

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiTextPrimary)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(width: 160, height: 130)
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
    QuickDrillSection(onLaunchDrill: { _ in })
        .padding()
}
