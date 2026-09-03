import SwiftData
import SwiftUI

/// Active dialogue detail view bound to a selected ChatSession, with message stream and scenario chips.
struct ChatDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: ChatSession
    var onToggleSidebar: () -> Void
    var onNewChat: () -> Void

    @State private var chatService = MLXChatService.shared
    @State private var audioService = AudioService()

    @State private var inputText: String = ""
    @State private var showFurigana: Bool = true
    @State private var showTranslations: Bool = true

    // Scenario starters for kicking off empty or fresh sessions
    private let scenarioStarters: [(title: String, prompt: String)] = [
        ("Order at a Cafe ☕️", "カフェで注文したいです。(I would like to order at a cafe.)"),
        ("Ask for Directions 🗺️", "すみません、駅はどこですか？ (Excuse me, where is the station?)"),
        ("Introduce Yourself 👋", "はじめまして！自己紹介をしましょう。(Nice to meet you! Let's introduce ourselves.)"),
        ("Explain JLPT N5 Grammar 📖", "JLPT N5の「〜てください」の使い方を教えてください。(Please teach me how to use '~te kudasai' in N5.)")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Model Loading / Preparation Banner
            if chatService.isModelLoading || !chatService.isModelReady {
                modelStatusBanner
            }

            // Chat Message Stream
            messageList

            // Pre-set Scenario Starter Chips
            if session.sortedMessages.count <= 1 {
                scenarioChipsSection
            }

            // Bottom Input Bar
            inputBar
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onToggleSidebar) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.tsumugiDustyDenim)
                }
                .accessibilityLabel("Toggle Chat History")
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: onNewChat) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.tsumugiDustyDenim)
                    }
                    .accessibilityLabel("New Chat")

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
        }
        .task {
            if !chatService.isModelReady && !chatService.isModelLoading {
                await chatService.prepareModel()
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
                    ForEach(session.sortedMessages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    if chatService.isGenerating && (session.sortedMessages.last?.isUser ?? false) {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: session.messages.count) { _, _ in
                if let last = session.sortedMessages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: session.sortedMessages.last?.text) { _, _ in
                if let last = session.sortedMessages.last {
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
                message.isUser
                    ? Color.tsumugiDustyDenim
                    : Color(uiColor: .secondarySystemGroupedBackground)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        message.isUser ? Color.clear : Color.tsumugiCardBorder,
                        lineWidth: 1
                    )
            )

            if !message.isUser {
                // Audio pronunciation button
                Button {
                    let parsed = ParsedTutorMessage(from: message.text)
                    audioService.speak(parsed.spokenJapanese)
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.footnote)
                        .foregroundStyle(Color.tsumugiDustyDenim)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Listen to Japanese sentence")

                Spacer(minLength: 30)
            }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.tsumugiDustyDenim.opacity(0.6))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer()
        }
    }

    // MARK: - Scenario Chips

    private var scenarioChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(scenarioStarters, id: \.title) { starter in
                    Button {
                        sendMessage(starter.prompt)
                    } label: {
                        Text(starter.title)
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
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Bottom Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                TextField("Ask Tsumugi in Japanese or English...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.tsumugiCardBorder, lineWidth: 1)
                    )
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

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !chatService.isGenerating else { return }

        // Dynamic Title Generation if first user message or untitled
        if session.title == "New Conversation" || session.title.isEmpty {
            let promptHeadline = trimmed
                .replacingOccurrences(of: #"\([^\)]*\)"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let maxLen = min(30, promptHeadline.count)
            let generatedTitle = String(promptHeadline.prefix(maxLen))
            session.title = generatedTitle.isEmpty ? "Conversation" : generatedTitle
        }

        let userMsg = ChatMessage(
            text: trimmed,
            englishTranslation: "",
            isUser: true,
            timestamp: Date(),
            session: session
        )
        modelContext.insert(userMsg)
        session.messages.append(userMsg)
        session.updatedAt = Date()
        try? modelContext.save()

        inputText = ""

        Task {
            // Prepare placeholder for streaming response
            let aiMessageId = UUID().uuidString
            let aiMsg = ChatMessage(
                id: aiMessageId,
                text: "",
                furiganaMarkup: "",
                englishTranslation: "",
                isUser: false,
                timestamp: Date(),
                session: session
            )
            modelContext.insert(aiMsg)
            session.messages.append(aiMsg)
            session.updatedAt = Date()

            let stream = await chatService.send(prompt: trimmed, chatHistory: session.sortedMessages)
            for await token in stream {
                if let index = session.messages.firstIndex(where: { $0.id == aiMessageId }) {
                    session.messages[index].text += token
                }
            }
            session.updatedAt = Date()
            try? modelContext.save()
        }
    }
}

#Preview {
    let mockSession = ChatSession(title: "Preview Chat")
    NavigationStack {
        ChatDetailView(
            session: mockSession,
            onToggleSidebar: {},
            onNewChat: {}
        )
    }
    .modelContainer(PreviewContainer.shared)
}
