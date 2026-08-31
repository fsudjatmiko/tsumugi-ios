import SwiftData
import SwiftUI

/// An interactive stroke tracing canvas that validates directional accuracy while preserving the user's organic hand-drawn stroke signature.
struct StrokeCanvasView: View {
    let character: String
    let strokeCount: Int
    var audioService: AudioService?
    var showGhostGuide: Bool = true
    var onCompletion: ((_ retryCount: Int) -> Void)?

    @State private var validator = StrokeValidator()
    /// Stores the user's actual hand-drawn stroke point arrays (organic signature)
    @State private var completedStrokes: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    @State private var currentStrokeIndex: Int = 0
    @State private var strokeErrorFlash: Bool = false
    @State private var retryCount: Int = 0
    @State private var isCharacterCompleted: Bool = false
    @State private var feedbackTriggerSuccess: Int = 0
    @State private var feedbackTriggerError: Int = 0

    private var strokeGuide: StrokeGuide {
        StrokeGuide.defaultGuide(for: character, strokeCount: strokeCount)
    }

    private var currentExpectedSegment: StrokeSegment? {
        guard currentStrokeIndex < strokeGuide.strokes.count else { return nil }
        return strokeGuide.strokes[currentStrokeIndex]
    }

    var body: some View {
        VStack(spacing: 14) {
            canvasContainer

            if isCharacterCompleted {
                completionBanner
            } else {
                drawingControls
            }
        }
        .padding(.horizontal, 20)
        .sensoryFeedback(.success, trigger: feedbackTriggerSuccess)
        .sensoryFeedback(.error, trigger: feedbackTriggerError)
    }

    // MARK: - Canvas Container

    private var canvasContainer: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // Background card container
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.tsumugiCardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                strokeErrorFlash
                                    ? Color.red.opacity(0.6)
                                    : (isCharacterCompleted ? Color.tsumugiChartreuse : Color.tsumugiCardBorder),
                                lineWidth: strokeErrorFlash || isCharacterCompleted ? 2.5 : 1
                            )
                    )

                // Faint center crosshair guidelines
                guidelineGrid(size: size)

                // Faint background character template (subtle 0.1 opacity)
                Text(character)
                    .font(.system(size: min(size.width, size.height) * 0.58, weight: .light, design: .serif))
                    .foregroundStyle(Color.tsumugiTextSecondary.opacity(0.10))
                    .allowsHitTesting(false)

                // Next expected stroke start indicator (green dot & number)
                if showGhostGuide && !isCharacterCompleted, let currentSeg = currentExpectedSegment {
                    currentStrokeStartMarker(segment: currentSeg, canvasSize: size)
                }

                // Drawing Canvas: Renders the user's organic hand-drawn strokes with tint & glow
                Canvas { context, _ in
                    // 1. Draw validated strokes using user's actual drawn points with glow
                    for stroke in completedStrokes {
                        var path = Path()
                        guard let first = stroke.first else { continue }
                        path.move(to: first)
                        for pt in stroke.dropFirst() {
                            path.addLine(to: pt)
                        }

                        // Subtle outer glow
                        context.stroke(
                            path,
                            with: .color(Color.tsumugiChartreuse.opacity(0.4)),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                        )

                        // Core crisp hand-drawn stroke
                        context.stroke(
                            path,
                            with: .color(Color.tsumugiChartreuse),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                        )
                    }

                    // 2. Draw current in-progress drag stroke
                    if !currentLine.isEmpty {
                        var currentPath = Path()
                        guard let first = currentLine.first else { return }
                        currentPath.move(to: first)
                        for pt in currentLine.dropFirst() {
                            currentPath.addLine(to: pt)
                        }
                        context.stroke(
                            currentPath,
                            with: .color(strokeErrorFlash ? Color.red : Color.tsumugiTextPrimary),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
                .shadow(
                    color: !completedStrokes.isEmpty ? Color.tsumugiChartreuse.opacity(0.35) : .clear,
                    radius: 6
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard !isCharacterCompleted else { return }
                            currentLine.append(value.location)
                        }
                        .onEnded { _ in
                            guard !isCharacterCompleted else { return }
                            validateUserStroke(canvasSize: size)
                        }
                )
            }
        }
        .frame(height: 240)
    }

    // MARK: - Stroke Validation (Preserving Organic Path)

    private func validateUserStroke(canvasSize: CGSize) {
        guard let expected = currentExpectedSegment else {
            currentLine.removeAll()
            return
        }

        let result = validator.validateStroke(
            userPoints: currentLine,
            canvasSize: canvasSize,
            expectedSegment: expected
        )

        if result.isSuccess {
            // PRESERVE USER'S RAW SIGNATURE: Store the actual points drawn by the user
            completedStrokes.append(currentLine)
            currentLine.removeAll()
            currentStrokeIndex += 1
            feedbackTriggerSuccess += 1

            if currentStrokeIndex >= strokeGuide.strokes.count {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isCharacterCompleted = true
                }
                audioService?.speak(character)
                onCompletion?(retryCount)
            }
        } else {
            // Miss / Wrong Direction
            retryCount += 1
            feedbackTriggerError += 1
            strokeErrorFlash = true

            withAnimation(.easeOut(duration: 0.35)) {
                currentLine.removeAll()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                strokeErrorFlash = false
            }
        }
    }

    // MARK: - Next Stroke Start Marker

    private func currentStrokeStartMarker(segment: StrokeSegment, canvasSize: CGSize) -> some View {
        let startX = segment.startPoint.x * canvasSize.width
        let startY = segment.startPoint.y * canvasSize.height

        return ZStack {
            // Faint pulse ring
            Circle()
                .stroke(Color.tsumugiChartreuse.opacity(0.6), lineWidth: 2)
                .frame(width: 26, height: 26)
                .position(x: startX, y: startY)

            // Numbered start badge
            ZStack {
                Circle()
                    .fill(Color.tsumugiChartreuse)
                Text("\(segment.strokeNumber)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.tsumugiSpaceIndigo)
            }
            .frame(width: 18, height: 18)
            .position(x: startX, y: startY)
        }
    }

    // MARK: - Guideline Grid

    private func guidelineGrid(size: CGSize) -> some View {
        Path { path in
            let midX = size.width / 2
            let midY = size.height / 2

            path.move(to: CGPoint(x: 16, y: midY))
            path.addLine(to: CGPoint(x: size.width - 16, y: midY))

            path.move(to: CGPoint(x: midX, y: 16))
            path.addLine(to: CGPoint(x: midX, y: size.height - 16))
        }
        .stroke(
            Color.secondary.opacity(0.10),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )
    }

    // MARK: - Drawing Controls & Completion Banner

    private var drawingControls: some View {
        HStack {
            HStack(spacing: 6) {
                Text("Stroke \(min(currentStrokeIndex + 1, max(1, strokeGuide.strokes.count))) of \(strokeGuide.strokes.count)")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.tsumugiTextSecondary)

                if retryCount > 0 {
                    Text("(\(retryCount) \(retryCount == 1 ? "retry" : "retries"))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: undoLastStroke) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.footnote)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(Color.tsumugiDustyDenim)
                .disabled(completedStrokes.isEmpty)

                Button(action: resetStrokes) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.footnote)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(Color.tsumugiDustyDenim)
                .disabled(completedStrokes.isEmpty && currentLine.isEmpty)
            }
        }
    }

    private var completionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Stroke Complete")
                    .font(.headline)
                    .foregroundStyle(Color.tsumugiTextPrimary)

                Text(retryCount == 0 ? "Perfect accuracy on first try!" : "Traced accurately after \(retryCount) \(retryCount == 1 ? "retry" : "retries")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                audioService?.speak(character)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(Color.tsumugiDustyDenim)
                    .frame(width: 36, height: 36)
                    .background(Color.tsumugiDustyDenim.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Listen to character pronunciation")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.green.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.green.opacity(0.35), lineWidth: 1)
                )
        )
    }

    public func undoLastStroke() {
        guard !completedStrokes.isEmpty else { return }
        completedStrokes.removeLast()
        if currentStrokeIndex > 0 {
            currentStrokeIndex -= 1
        }
        isCharacterCompleted = false
    }

    public func resetStrokes() {
        completedStrokes.removeAll()
        currentLine.removeAll()
        currentStrokeIndex = 0
        retryCount = 0
        isCharacterCompleted = false
    }
}

#Preview {
    StrokeCanvasView(
        character: "あ",
        strokeCount: 3,
        audioService: AudioService.shared
    )
    .padding()
    .modelContainer(PreviewContainer.shared)
}
