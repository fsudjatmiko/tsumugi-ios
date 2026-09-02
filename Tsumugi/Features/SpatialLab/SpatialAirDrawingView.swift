import ARKit
import RealityKit
import SwiftUI

/// AR surface-tracing view projecting flat Japanese character stencils onto real-world flat surfaces and elevating them into 3D on mastery.
struct SpatialAirDrawingView: View {
    let character: String
    var onComplete: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var hasDetectedSurface: Bool = false
    @State private var isSurfaceLocked: Bool = false
    @State private var drawnPoints: [SIMD3<Float>] = []
    @State private var isSuccess: Bool = false
    @State private var strokeClearTrigger: Int = 0

    var body: some View {
        ZStack(alignment: .top) {
            #if targetEnvironment(simulator)
            simulatorFallbackView
            #else
            ARAirDrawingCanvas(
                character: character,
                isSurfaceLocked: isSurfaceLocked,
                isSuccess: isSuccess,
                clearTrigger: strokeClearTrigger,
                hasDetectedSurface: $hasDetectedSurface,
                drawnPoints: $drawnPoints,
                onPlaneTapped: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        isSurfaceLocked = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                },
                onTracePoint: { strokePoint in
                    drawnPoints.append(strokePoint)
                    checkCompletion()
                },
                onTraceEnd: {
                    checkCompletion()
                }
            )
            .ignoresSafeArea()
            #endif

            // Dynamic 3-Stage Glassmorphic HUD Overlay
            hudOverlay
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

                    Text(character)
                        .font(.system(size: 110, weight: .bold, design: .serif))
                        .foregroundStyle(isSuccess ? Color.tsumugiChartreuse : Color.tsumugiDustyDenim)
                        .shadow(color: isSuccess ? Color.tsumugiChartreuse.opacity(0.8) : .clear, radius: 12)
                }

                Text("Surface Tracing Simulation (Simulator)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    drawnPoints.append(SIMD3<Float>(0, 0, 0))
                    checkCompletion()
                }
                .onEnded { _ in
                    checkCompletion()
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
                        Text("Tracing Mode")
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
                        Text("Scanning Surface...")
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
                            if let onComplete = onComplete {
                                onComplete()
                            } else {
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Next Kana")
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
                        Text("Place '\(character)' on Surface")
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
            return "Trace '\(character)' on Surface"
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
            return "Follow the stroke guide dots to draw the character on your table."
        } else if hasDetectedSurface {
            return "Tap the green reticle or button below to project the '\(character)' template."
        } else {
            return "Slowly move your iPhone around to find a flat table, desk, or floor."
        }
    }

    // MARK: - Actions & Completion

    private func clearStrokes() {
        drawnPoints.removeAll()
        isSuccess = false
        strokeClearTrigger += 1
    }

    private func checkCompletion() {
        if drawnPoints.count >= 8 && !isSuccess {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isSuccess = true
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                AudioService.shared.speak(character)
            }
        }
    }
}

#Preview {
    SpatialAirDrawingView(character: "あ")
}
