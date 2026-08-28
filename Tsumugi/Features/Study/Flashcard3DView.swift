import SwiftData
import SwiftUI

/// A 3D flippable card component displaying a Japanese character on the front and details on the back.
struct Flashcard3DView: View {
    let card: CharacterCard
    let isFlipped: Bool
    let audioService: AudioService
    let onFlip: () -> Void

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
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                onFlip()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .padding(.horizontal, 20)
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

            HStack(spacing: 4) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.caption2)
                Text("Tap to flip back")
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
