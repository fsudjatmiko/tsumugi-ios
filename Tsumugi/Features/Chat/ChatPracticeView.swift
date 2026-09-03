import SwiftData
import SwiftUI

/// Structured breakdown of a tutor message with deterministic, offline linguistic processing for Romaji and Furigana.
struct ParsedTutorMessage {
    let rawText: String
    let japanese: String
    let romaji: String?
    let english: String?
    let rubySegments: [RubySegment]

    init(from raw: String) {
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
    var spokenJapanese: String {
        japanese
    }
}

/// Conversational practice interface powered by on-device MLX Local AI (Qwen 2.5 1.5B 4-bit) with structured 3-tier parsing and Japanese-only TTS.
struct ChatPracticeView: View {
    @State private var chatService = MLXChatService.shared
    @State private var audioService = AudioService()

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var showFurigana: Bool = true
    @State private var showTranslations: Bool = true

    // Pre-set scenario starters (Horizontal Scroll Chips)
    private let scenarioStarters: [(title: String, prompt: String)] = [
        ("Order at a Cafe ☕️", "カフェで注文したいです。(I would like to order at a cafe.)"),
        ("Ask for Directions 🗺️", "すみません、駅はどこですか？ (Excuse me, where is the station?)"),
        ("Introduce Yourself 👋", "はじめまして！自己紹介をしましょう。(Nice to meet you! Let's introduce ourselves.)"),
        ("Explain JLPT N5 Grammar 📖", "JLPT N5の「〜てください」の使い方を教えてください。(Please teach me how to use '~te kudasai' in N5.)")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Model Loading / Preparation Banner
                if chatService.isModelLoading || !chatService.isModelReady {
                    modelStatusBanner
                }

                // Chat Message Stream
                messageList

                // Pre-set Scenario Starter Chips
                scenarioChipsSection

                // Bottom Input Bar
                inputBar
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Dialogue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle(isOn: $showFurigana) {
                            Label("Show Romaji / Furigana", systemImage: "character.textbox")
                        }
                        Toggle(isOn: $showTranslations) {
                            Label("Show English", systemImage: "globe")
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(Color.tsumugiDustyDenim)
                    }
                }
            }
            .task {
                if !chatService.isModelReady && !chatService.isModelLoading {
                    await chatService.prepareModel()
                }

                if messages.isEmpty {
                    loadInitialGreeting()
                }
            }
        }
    }

    // MARK: - Model Status Banner

    private var modelStatusBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if chatService.isModelLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.tsumugiDustyDenim)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(chatService.statusMessage)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.tsumugiTextPrimary)

                    if chatService.isModelLoading {
                        ProgressView(value: max(0.05, chatService.downloadProgress))
                            .tint(Color.tsumugiDustyDenim)
                    }
                }

                Spacer()

                if !chatService.isModelReady && !chatService.isModelLoading {
                    Button("Retry") {
                        Task {
                            await chatService.prepareModel()
                        }
                    }
                    .font(.caption2)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .tint(Color.tsumugiDustyDenim)
                }
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tsumugiCardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    if chatService.isGenerating && (messages.last?.isUser ?? false) {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: messages.last?.text) { _, _ in
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                if message.isUser {
                    // Learner Bubble
                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(.white)
                } else {
                    // Tutor 3-Tier Bubble
                    let parsed = ParsedTutorMessage(from: message.text)

                    // 1. Japanese Primary Text with Native Ruby Typography
                    RubyTextView(
                        segments: parsed.rubySegments,
                        showFurigana: showFurigana,
                        font: .systemFont(ofSize: 17, weight: .semibold),
                        textColor: UIColor(Color.tsumugiTextPrimary),
                        rubyFont: .systemFont(ofSize: 10, weight: .regular),
                        rubyColor: .secondaryLabel,
                        lineSpacing: 6
                    )
                    .fixedSize(horizontal: false, vertical: true)

                    // 2. Romaji Sub-line (deterministic CoreFoundation transliteration)
                    if showFurigana, let romaji = parsed.romaji, !romaji.isEmpty {
                        Text(romaji)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // 3. English Meaning Box (multiline without truncation)
                    if showTranslations, let english = parsed.english, !english.isEmpty {
                        Text(english)
                            .font(.subheadline)
                            .foregroundStyle(Color.tsumugiTextPrimary.opacity(0.85))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(message.isUser ? Color.tsumugiDustyDenim : Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(message.isUser ? Color.clear : Color.tsumugiCardBorder, lineWidth: 1)
                    )
            )

            if !message.isUser {
                let parsed = ParsedTutorMessage(from: message.text)
                let textToSpeak = parsed.spokenJapanese.isEmpty ? parsed.japanese : parsed.spokenJapanese

                Button {
                    audioService.speak(textToSpeak)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(Color.tsumugiDustyDenim)
                        .frame(width: 32, height: 32)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pronounce Japanese text only")

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.75)
            Text("Tsumugi is typing...")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Scenario Chips

    private var scenarioChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(scenarioStarters, id: \.title) { item in
                    Button {
                        sendMessage(item.prompt)
                    } label: {
                        Text(item.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.tsumugiTextPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(chatService.isGenerating)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                TextField("Message Tsumugi in Japanese or Romaji...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                    )
                    .disabled(chatService.isGenerating)
                    .onSubmit {
                        sendMessage(inputText)
                    }

                Button {
                    sendMessage(inputText)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty || chatService.isGenerating
                                ? Color.secondary.opacity(0.3)
                                : Color.tsumugiDustyDenim
                        )
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || chatService.isGenerating)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    // MARK: - Actions & Dialogue Flow

    private func loadInitialGreeting() {
        let greeting = ChatMessage(
            text: """
            [JA]: こんにちは！つむぎです。日本語の練習をはじめましょう！何について話しますか？
            [EN]: Hello! I'm Tsumugi. Let's start practicing Japanese! What would you like to talk about?
            """,
            furiganaMarkup: "",
            englishTranslation: "",
            isUser: false
        )
        messages.append(greeting)
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !chatService.isGenerating else { return }

        let userMsg = ChatMessage(
            text: trimmed,
            englishTranslation: "",
            isUser: true
        )
        messages.append(userMsg)
        inputText = ""

        Task {
            // Prepare placeholder for streaming response
            let aiMessageId = UUID().uuidString
            let aiMsg = ChatMessage(
                id: aiMessageId,
                text: "",
                furiganaMarkup: "",
                englishTranslation: "",
                isUser: false
            )
            messages.append(aiMsg)

            let stream = await chatService.send(prompt: trimmed, chatHistory: messages)
            for await token in stream {
                if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                    messages[index].text += token
                }
            }
        }
    }
}

#Preview {
    ChatPracticeView()
        .modelContainer(PreviewContainer.shared)
}
