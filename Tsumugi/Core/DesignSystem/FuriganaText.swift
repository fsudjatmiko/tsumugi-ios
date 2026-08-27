import SwiftUI

/// Component that parses and renders Japanese Kanji with ruby/furigana annotations above characters.
public struct FuriganaText: View {
    public struct RubySegment: Identifiable, Hashable {
        public let id = UUID()
        public let text: String
        public let reading: String?

        public init(text: String, reading: String? = nil) {
            self.text = text
            self.reading = reading
        }
    }

    public let markup: String
    public let showFurigana: Bool
    public let baseFontSize: CGFloat

    public init(
        markup: String,
        showFurigana: Bool = true,
        baseFontSize: CGFloat = 18
    ) {
        self.markup = markup
        self.showFurigana = showFurigana
        self.baseFontSize = baseFontSize
    }

    private var segments: [RubySegment] {
        parseMarkup(markup)
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(segments) { segment in
                VStack(spacing: 1) {
                    if showFurigana, let reading = segment.reading, !reading.isEmpty {
                        Text(reading)
                            .font(.system(size: max(9, baseFontSize * 0.55), weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        // Invisible placeholder spacer to keep horizontal baseline aligned
                        Text(" ")
                            .font(.system(size: max(9, baseFontSize * 0.55), weight: .regular))
                            .opacity(0)
                    }

                    Text(segment.text)
                        .font(.system(size: baseFontSize, weight: .medium))
                        .foregroundStyle(Color.tsumugiSpaceIndigo)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibleString)
    }

    private var accessibleString: String {
        segments.map { segment in
            if let reading = segment.reading {
                return "\(segment.text) (\(reading))"
            }
            return segment.text
        }.joined()
    }

    // MARK: - Parsing

    /// Parses lightweight bracket markup like `[漢|かん][字|じ]の[勉|べん][強|きょう]`
    private func parseMarkup(_ input: String) -> [RubySegment] {
        var results: [RubySegment] = []
        var currentIndex = input.startIndex

        while currentIndex < input.endIndex {
            if input[currentIndex] == "[" {
                if let closeBracketIndex = input[currentIndex...].firstIndex(of: "]") {
                    let inside = String(input[input.index(after: currentIndex)..<closeBracketIndex])
                    let parts = inside.split(separator: "|", maxSplits: 1).map(String.init)
                    if parts.count == 2 {
                        results.append(RubySegment(text: parts[0], reading: parts[1]))
                    } else {
                        results.append(RubySegment(text: inside))
                    }
                    currentIndex = input.index(after: closeBracketIndex)
                    continue
                }
            }

            // Normal text until next '['
            let nextBracketIndex = input[currentIndex...].firstIndex(of: "[") ?? input.endIndex
            let normalText = String(input[currentIndex..<nextBracketIndex])
            if !normalText.isEmpty {
                results.append(RubySegment(text: normalText))
            }
            currentIndex = nextBracketIndex
        }

        return results
    }
}

#Preview {
    VStack(spacing: 20) {
        FuriganaText(
            markup: "[私|わたし]は[日|に][本|ほん][語|ご]を[勉|べん][強|きょう]しています。",
            showFurigana: true,
            baseFontSize: 22
        )

        FuriganaText(
            markup: "[明|あか]るい[日|ひ]です。",
            showFurigana: false,
            baseFontSize: 20
        )
    }
    .padding()
}
