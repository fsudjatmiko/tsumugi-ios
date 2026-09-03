import CoreFoundation
import Foundation

/// Represents a piece of text with an optional furigana (ruby) pronunciation annotation.
public struct RubySegment: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let text: String
    public let ruby: String?

    public init(id: UUID = UUID(), text: String, ruby: String? = nil) {
        self.id = id
        self.text = text
        self.ruby = ruby
    }
}

/// Offline linguistic helper utilizing Apple's CoreFoundation / Foundation text engines for deterministic Romaji transliteration and Japanese Kanji furigana tokenization.
public enum JapaneseLinguisticHelper {
    private static let kanjiRegex: NSRegularExpression = {
        (try? NSRegularExpression(pattern: "[一-龯々〆ヵヶ]", options: [])) ?? NSRegularExpression()
    }()

    private static let hiraganaSet = CharacterSet(charactersIn: "ぁ"..."ん")

    // MARK: - Romaji Transliteration

    /// Converts Japanese text into clean, natural Latin Romaji transcription using CFStringTokenizer with locale `ja_JP`.
    ///
    /// - Parameter japaneseText: The original Japanese text.
    /// - Returns: Capitalized, punctuation-cleaned Romaji string.
    public static func toRomaji(from japaneseText: String) -> String {
        let cleanText = japaneseText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return "" }

        let string = cleanText as CFString
        let locale = CFLocaleCreate(kCFAllocatorDefault, CFLocaleIdentifier("ja_JP" as CFString))
        guard let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            string,
            CFRangeMake(0, CFStringGetLength(string)),
            kCFStringTokenizerUnitWord,
            locale
        ) else {
            // Fallback to basic CFStringTransform
            let mutable = NSMutableString(string: cleanText) as CFMutableString
            CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
            CFStringTransform(mutable, nil, kCFStringTransformStripDiacritics, false)
            return (mutable as String).capitalized
        }

        let ns = cleanText as NSString
        var result = ""
        var currentIndex = 0

        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        while tokenType != [] {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            if range.location > currentIndex {
                let gap = ns.substring(with: NSRange(location: currentIndex, length: range.location - currentIndex))
                result += gap
            }

            let token = ns.substring(with: NSRange(location: range.location, length: range.length))
            if let latinAttr = CFStringTokenizerCopyCurrentTokenAttribute(
                tokenizer,
                kCFStringTokenizerAttributeLatinTranscription
            ) as? String {
                if !result.isEmpty && shouldInsertSpace(before: latinAttr, currentResult: result) {
                    result += " "
                }
                result += latinAttr.replacingOccurrences(of: "'", with: "")
            } else {
                result += token
            }

            currentIndex = range.location + range.length
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }

        if currentIndex < ns.length {
            let trailing = ns.substring(from: currentIndex)
            result += trailing
        }

        // Format punctuation
        result = result
            .replacingOccurrences(of: "！", with: "! ")
            .replacingOccurrences(of: "？", with: "? ")
            .replacingOccurrences(of: "。", with: ". ")
            .replacingOccurrences(of: "、", with: ", ")
            .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Capitalize leading letter
        if let first = result.first {
            result = String(first).uppercased() + String(result.dropFirst())
        }

        return result
    }

    private static func shouldInsertSpace(before nextToken: String, currentResult: String) -> Bool {
        guard let lastChar = currentResult.last else { return false }
        let noSpaceTrailing: [Character] = [" ", "\n", "！", "？", "!", "?", ",", "、", "。", "(", "[", "{", "\"", "'"]
        return !noSpaceTrailing.contains(lastChar)
    }

    // MARK: - Native Furigana Extraction

    /// Tokenizes Japanese text using CFStringTokenizer with locale `ja_JP` and generates `RubySegment` entries for each word/morpheme.
    ///
    /// Tokens containing Kanji receive a hiragana reading perched above the kanji root, while kana, particles, and punctuation have `ruby: nil`.
    ///
    /// - Parameter japaneseText: Pure Japanese text (free of artificial brackets).
    /// - Returns: Ordered array of `RubySegment` tokens.
    public static func extractRubySegments(from japaneseText: String) -> [RubySegment] {
        let cleanText = japaneseText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return [] }

        let string = cleanText as CFString
        let locale = CFLocaleCreate(kCFAllocatorDefault, CFLocaleIdentifier("ja_JP" as CFString))
        guard let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            string,
            CFRangeMake(0, CFStringGetLength(string)),
            kCFStringTokenizerUnitWord,
            locale
        ) else {
            return [RubySegment(text: cleanText, ruby: nil)]
        }

        let ns = cleanText as NSString
        var segments: [RubySegment] = []
        var currentIndex = 0

        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        while tokenType != [] {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            // Capture any intermediate symbols or whitespace
            if range.location > currentIndex {
                let gap = ns.substring(with: NSRange(location: currentIndex, length: range.location - currentIndex))
                if !gap.isEmpty {
                    segments.append(RubySegment(text: gap, ruby: nil))
                }
            }

            let token = ns.substring(with: NSRange(location: range.location, length: range.length))
            let tokenNs = token as NSString
            let containsKanji = kanjiRegex.firstMatch(
                in: token,
                options: [],
                range: NSRange(location: 0, length: tokenNs.length)
            ) != nil

            if containsKanji, let latinAttr = CFStringTokenizerCopyCurrentTokenAttribute(
                tokenizer,
                kCFStringTokenizerAttributeLatinTranscription
            ) as? String {
                let mutable = NSMutableString(string: latinAttr) as CFMutableString
                CFStringTransform(mutable, nil, kCFStringTransformLatinHiragana, false)
                let hiragana = mutable as String

                let splitSegments = splitOkurigana(token: token, fullReading: hiragana)
                segments.append(contentsOf: splitSegments)
            } else {
                segments.append(RubySegment(text: token, ruby: nil))
            }

            currentIndex = range.location + range.length
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }

        if currentIndex < ns.length {
            let trailing = ns.substring(from: currentIndex)
            if !trailing.isEmpty {
                segments.append(RubySegment(text: trailing, ruby: nil))
            }
        }

        return segments
    }

    /// Accurately isolates Kanji roots from trailing/leading kana inflections (okurigana)
    /// so that furigana is placed strictly above the Kanji characters.
    ///
    /// Example: `食べ` with reading `たべ` -> `[食(た), べ]`
    private static func splitOkurigana(token: String, fullReading: String) -> [RubySegment] {
        var base = token
        var trailingHiragana = ""

        while let last = base.last, String(last).rangeOfCharacter(from: hiraganaSet) != nil {
            trailingHiragana = String(last) + trailingHiragana
            base.removeLast()
        }

        var leadingHiragana = ""
        while let first = base.first, String(first).rangeOfCharacter(from: hiraganaSet) != nil {
            leadingHiragana += String(first)
            base.removeFirst()
        }

        var currentReading = fullReading

        if !leadingHiragana.isEmpty && currentReading.hasPrefix(leadingHiragana) {
            currentReading = String(currentReading.dropFirst(leadingHiragana.count))
        } else {
            base = leadingHiragana + base
            leadingHiragana = ""
        }

        if !trailingHiragana.isEmpty && currentReading.hasSuffix(trailingHiragana) {
            currentReading = String(currentReading.dropLast(trailingHiragana.count))
        } else {
            base = base + trailingHiragana
            trailingHiragana = ""
        }

        var results: [RubySegment] = []
        if !leadingHiragana.isEmpty {
            results.append(RubySegment(text: leadingHiragana, ruby: nil))
        }
        if !base.isEmpty {
            results.append(RubySegment(text: base, ruby: currentReading.isEmpty ? nil : currentReading))
        }
        if !trailingHiragana.isEmpty {
            results.append(RubySegment(text: trailingHiragana, ruby: nil))
        }

        return results.isEmpty ? [RubySegment(text: token, ruby: fullReading)] : results
    }
}
