import Foundation

/// Structured breakdown of a tutor message with deterministic, offline linguistic processing for Romaji and Furigana.
public struct ParsedTutorMessage: Sendable {
    public let rawText: String
    public let japanese: String
    public let romaji: String?
    public let english: String?
    public let rubySegments: [RubySegment]

    public init(from raw: String) {
        self.rawText = raw

        var ja = ""
        var en: String? = nil

        let lines = raw.components(separatedBy: .newlines)
        var currentSection: String? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[JA]:") || trimmed.hasPrefix("1. [JA]:") || trimmed.hasPrefix("[JA]") {
                currentSection = "JA"
                let content = trimmed.replacingOccurrences(of: #"^(?:1\.\s*)?\[JA\]:?\s*"#, with: "", options: .regularExpression)
                if !content.isEmpty {
                    ja += (ja.isEmpty ? "" : "\n") + content
                }
            } else if trimmed.hasPrefix("[EN]:") || trimmed.hasPrefix("2. [EN]:") || trimmed.hasPrefix("3. [EN]:") || trimmed.hasPrefix("[EN]") {
                currentSection = "EN"
                let content = trimmed.replacingOccurrences(of: #"^(?:[23]\.\s*)?\[EN\]:?\s*"#, with: "", options: .regularExpression)
                if !content.isEmpty {
                    en = (en ?? "") + ((en == nil || en?.isEmpty == true) ? "" : "\n") + content
                }
            } else if trimmed.hasPrefix("[ROMAJI]:") || trimmed.hasPrefix("2. [ROMAJI]:") {
                // Ignore any LLM-hallucinated romaji section to ensure deterministic CoreFoundation transliteration
                currentSection = nil
            } else if let section = currentSection, !trimmed.isEmpty {
                switch section {
                case "JA":
                    ja += (ja.isEmpty ? "" : "\n") + trimmed
                case "EN":
                    en = (en ?? "") + ((en == nil || en?.isEmpty == true) ? "" : "\n") + trimmed
                default:
                    break
                }
            }
        }

        // Clean any residual accidental brackets from the Japanese sentence
        let extractedJa = ja.isEmpty ? raw.trimmingCharacters(in: .whitespacesAndNewlines) : ja.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedJa = extractedJa
            .replacingOccurrences(of: #"\([ぁ-んァ-ンーa-zA-Z\s]+\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"（[ぁ-んァ-ンーa-zA-Z\s]+）"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        self.japanese = cleanedJa
        self.english = en?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? en?.trimmingCharacters(in: .whitespacesAndNewlines) : nil

        // Deterministic, offline Romaji generation via CoreFoundation tokenizer
        if !cleanedJa.isEmpty {
            self.romaji = JapaneseLinguisticHelper.toRomaji(from: cleanedJa)
            self.rubySegments = JapaneseLinguisticHelper.extractRubySegments(from: cleanedJa)
        } else {
            self.romaji = nil
            self.rubySegments = []
        }
    }

    /// Pure clean Japanese string for speech synthesis
    public var spokenJapanese: String {
        japanese
    }
}
