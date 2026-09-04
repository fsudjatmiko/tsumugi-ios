import SwiftData
import SwiftUI

/// A 3D flippable card component displaying a Japanese character on the front and details on the back, supporting horizontal swipe-to-evaluate gestures.
struct Flashcard3DView: View {
    let card: CharacterCard
    let isFlipped: Bool
    let audioService: AudioService
    let onFlip: () -> Void
    var onSwipeGrade: ((SRSGrade) -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var feedbackTriggered: Bool = false

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        ZStack {
            cardFront
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )

            cardBack
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .offset(x: dragOffset.width, y: dragOffset.height * 0.2)
        .rotationEffect(.degrees(Double(dragOffset.width / 20.0)))
        .overlay(
            // Visual tint overlay during swipe
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(swipeOverlayColor)
                .allowsHitTesting(false)
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard isFlipped else { return }
                    dragOffset = value.translation

                    // Trigger haptic when crossing the 100pt boundary
                    if abs(value.translation.width) > swipeThreshold && !feedbackTriggered {
                        feedbackTriggered = true
                        if value.translation.width > 0 {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } else {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    } else if abs(value.translation.width) <= swipeThreshold {
                        feedbackTriggered = false
                    }
                }
                .onEnded { value in
                    guard isFlipped else {
                        // If not flipped, tap toggles flip
                        return
                    }

                    if value.translation.width > swipeThreshold {
                        // Swipe Right -> Got It / Remembered
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            dragOffset = CGSize(width: 500, height: value.translation.height)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            dragOffset = .zero
                            feedbackTriggered = false
                            onSwipeGrade?(.remembered)
                        }
                    } else if value.translation.width < -swipeThreshold {
                        // Swipe Left -> Forgot
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            dragOffset = CGSize(width: -500, height: value.translation.height)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            dragOffset = .zero
                            feedbackTriggered = false
                            onSwipeGrade?(.forgot)
                        }
                    } else {
                        // Smoothly spring back to center
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            dragOffset = .zero
                            feedbackTriggered = false
                        }
                    }
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                onFlip()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .padding(.horizontal, 20)
    }

    // MARK: - Swipe Tint Helpers

    private var swipeOverlayColor: Color {
        guard isFlipped else { return .clear }
        if dragOffset.width > 30 {
            let opacity = min(0.25, Double(dragOffset.width / swipeThreshold) * 0.25)
            return Color.tsumugiChartreuse.opacity(opacity)
        } else if dragOffset.width < -30 {
            let opacity = min(0.25, Double(-dragOffset.width / swipeThreshold) * 0.25)
            return Color.red.opacity(opacity)
        }
        return .clear
    }

    // MARK: - Front Face

    private var cardFront: some View {
        VStack(spacing: 16) {
            HStack {
                Text(card.category.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.tsumugiFrozenWater.opacity(0.35))
                    .foregroundStyle(Color.tsumugiTextPrimary)
                    .clipShape(Capsule())

                Spacer()

                Button {
                    audioService.speak(card.character)
                } label: {
                    Image(systemName: audioService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(Color.tsumugiDustyDenim)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Listen to pronunciation")
            }

            Spacer()

            Text(card.character)
                .font(.system(size: 84, weight: .medium, design: .serif))
                .foregroundStyle(Color.tsumugiTextPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "hand.tap.fill")
                    .font(.caption2)
                Text("Tap to reveal meaning")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.tsumugiCardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Back Face

    private var cardBack: some View {
        VStack(spacing: 14) {
            HStack {
                Text("DETAILS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    audioService.speak(card.character)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(Color.tsumugiDustyDenim)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Listen to pronunciation")
            }

            Text(card.romaji)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.tsumugiDustyDenim)

            Text(card.primaryMeaning)
                .font(.headline)
                .foregroundStyle(Color.tsumugiTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Divider()
                .overlay(Color.tsumugiCardBorder)
                .padding(.horizontal, 20)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("STROKES")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(card.strokeCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.tsumugiTextPrimary)
                }

                VStack(spacing: 4) {
                    Text("INTERVAL")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(card.interval == 0 ? "New" : "\(card.interval)d")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.tsumugiTextPrimary)
                }

                VStack(spacing: 4) {
                    Text("EASE")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", card.easeFactor))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.tsumugiTextPrimary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                    Text("Forgot")
                }
                .font(.caption2)
                .foregroundStyle(.red.opacity(0.8))

                Text("•")
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text("Got It")
                    Image(systemName: "arrow.right")
                }
                .font(.caption2)
                .foregroundStyle(Color.tsumugiDustyDenim)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.tsumugiCardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                )
        )
    }
}

#Preview {
    let mockCard = CharacterCard(
        id: "hira_a",
        character: "あ",
        romaji: "a",
        primaryMeaning: "a (vowel)",
        category: .hiragana,
        strokeCount: 3
    )

    return Flashcard3DView(
        card: mockCard,
        isFlipped: false,
        audioService: AudioService.shared,
        onFlip: {}
    )
    .padding()
    .modelContainer(PreviewContainer.shared)
}
