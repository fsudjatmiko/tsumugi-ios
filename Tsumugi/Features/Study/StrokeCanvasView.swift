import SwiftData
import SwiftUI

/// A tactile drawing surface for practicing Japanese character stroke tracing.
struct StrokeCanvasView: View {
    let character: String

    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []

    var body: some View {
        VStack(spacing: 12) {
            canvasContainer

            controlBar
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Canvas Container

    private var canvasContainer: some View {
        ZStack {
            // Background card styling
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.tsumugiCardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.tsumugiFrozenWater.opacity(0.4), lineWidth: 1)
                )

            // Faint guideline grid
            guidelineGrid

            // Faint character template
            Text(character)
                .font(.system(size: 110, weight: .light, design: .serif))
                .foregroundStyle(Color.secondary.opacity(0.2))
                .allowsHitTesting(false)

            // User drawing canvas
            Canvas { context, _ in
                for line in lines {
                    var path = Path()
                    guard let firstPoint = line.first else { continue }
                    path.move(to: firstPoint)
                    for point in line.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(
                        path,
                        with: .color(Color.tsumugiSpaceIndigo),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
                }

                if !currentLine.isEmpty {
                    var currentPath = Path()
                    guard let firstPoint = currentLine.first else { return }
                    currentPath.move(to: firstPoint)
                    for point in currentLine.dropFirst() {
                        currentPath.addLine(to: point)
                    }
                    context.stroke(
                        currentPath,
                        with: .color(Color.tsumugiSpaceIndigo),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentLine.append(value.location)
                    }
                    .onEnded { _ in
                        if !currentLine.isEmpty {
                            lines.append(currentLine)
                            currentLine = []
                        }
                    }
            )
        }
        .frame(height: 200)
    }

    // MARK: - Guideline Grid

    private var guidelineGrid: some View {
        GeometryReader { geometry in
            Path { path in
                let midX = geometry.size.width / 2
                let midY = geometry.size.height / 2

                // Horizontal dashed center line
                path.move(to: CGPoint(x: 16, y: midY))
                path.addLine(to: CGPoint(x: geometry.size.width - 16, y: midY))

                // Vertical dashed center line
                path.move(to: CGPoint(x: midX, y: 16))
                path.addLine(to: CGPoint(x: midX, y: geometry.size.height - 16))
            }
            .stroke(
                Color.secondary.opacity(0.15),
                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
            )
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack {
            Text("Practice Stroke Tracing")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: clearCanvas) {
                Label("Clear", systemImage: "arrow.counterclockwise")
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .tint(Color.tsumugiDustyDenim)
            .disabled(lines.isEmpty && currentLine.isEmpty)
        }
    }

    private func clearCanvas() {
        lines.removeAll()
        currentLine.removeAll()
    }
}

#Preview {
    StrokeCanvasView(character: "あ")
        .padding()
        .modelContainer(PreviewContainer.shared)
}
