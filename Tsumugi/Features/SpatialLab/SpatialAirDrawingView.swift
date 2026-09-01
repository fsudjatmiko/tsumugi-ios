import ARKit
import RealityKit
import SwiftUI

/// AR air-tracing view placing a 3D character in spatial space and allowing interactive finger tracing.
struct SpatialAirDrawingView: View {
    let character: String
    let onComplete: () -> Void

    @State private var tracedPointsCount: Int = 0
    @State private var isSuccess: Bool = false
    @State private var feedbackTrigger: Int = 0
    @State private var activeAnchor: AnchorEntity?

    var body: some View {
        ZStack {
            #if targetEnvironment(simulator)
            simulatorFallbackView
            #else
            if #available(iOS 18.0, *) {
                arRealityView
            } else {
                simulatorFallbackView
            }
            #endif

            hudOverlay
        }
        .sensoryFeedback(.success, trigger: feedbackTrigger)
    }

    // MARK: - AR RealityView (Device)

    #if !targetEnvironment(simulator)
    @available(iOS 18.0, *)
    @ViewBuilder
    private var arRealityView: some View {
        RealityView { content in
            let anchor = AnchorEntity(.camera)
            // Position 0.5m in front of the camera
            anchor.position = [0, 0, -0.5]

            let kanjiEntity = SpatialKanjiGenerator.shared.createCharacterEntity(
                character: character,
                isHighlighted: isSuccess
            )
            kanjiEntity.name = "TargetKanji"
            anchor.addChild(kanjiEntity)
            content.add(anchor)
            activeAnchor = anchor
        } update: { content in
            if let anchor = activeAnchor,
               let target = anchor.findEntity(named: "TargetKanji") as? ModelEntity {
                target.model?.materials = [
                    SpatialKanjiGenerator.shared.makeMaterial(isHighlighted: isSuccess)
                ]
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleTraceGesture(at: value.location)
                }
                .onEnded { _ in
                    checkCompletion()
                }
        )
    }
    #endif

    // MARK: - Simulator & iOS 17 Fallback View

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

                    Text(character)
                        .font(.system(size: 110, weight: .bold, design: .serif))
                        .foregroundStyle(isSuccess ? Color.tsumugiChartreuse : Color.tsumugiDustyDenim)
                        .shadow(color: isSuccess ? Color.tsumugiChartreuse.opacity(0.8) : .clear, radius: 12)
                }

                Text("Spatial 3D Simulation Canvas")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    tracedPointsCount += 1
                }
                .onEnded { _ in
                    checkCompletion()
                }
        )
    }

    // MARK: - HUD Overlay

    private var hudOverlay: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("3D Air Tracing")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Trace the character path in 3D space")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                if isSuccess {
                    Label("Completed!", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tsumugiChartreuse)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.tsumugiSpaceIndigo.opacity(0.8))
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            if isSuccess {
                Button(action: onComplete) {
                    Text("Continue")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color.tsumugiChartreuse)
                .foregroundStyle(Color.tsumugiSpaceIndigo)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Gesture Handling

    private func handleTraceGesture(at location: CGPoint) {
        tracedPointsCount += 1
        #if !targetEnvironment(simulator)
        if let anchor = activeAnchor, tracedPointsCount % 3 == 0 {
            // Project screen point to local 3D offset
            let normalizedX = Float(location.x / UIScreen.main.bounds.width - 0.5) * 0.3
            let normalizedY = -Float(location.y / UIScreen.main.bounds.height - 0.5) * 0.3
            let trailNode = SpatialKanjiGenerator.shared.createTrailPointEntity(
                position: [normalizedX, normalizedY, 0.02]
            )
            anchor.addChild(trailNode)
        }
        #endif
    }

    private func checkCompletion() {
        if tracedPointsCount >= 10 && !isSuccess {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isSuccess = true
                feedbackTrigger += 1
            }
        }
    }
}

#Preview {
    SpatialAirDrawingView(character: "あ", onComplete: {})
}
