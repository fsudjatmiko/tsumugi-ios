import SwiftData
import SwiftUI

/// Conversational practice interface offering offline dialogue, ruby furigana hints, translation toggles, and TTS audio.
struct ChatPracticeView: View {
    @State private var dialogueEngine = LocalDialogueEngine()
    @State private var audioService = AudioService()

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var showFurigana: Bool = true
    @State private var showTranslations: Bool = true
    @State private var currentSuggestions: [String] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                scenarioHeader

                messageList

                if !currentSuggestions.isEmpty {
                    suggestionChips
                }

                inputBar
            }
            .background(Color.tsumugiBackground)
            .navigationTitle("AI Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle(isOn: $showFurigana) {
                            Label("Show Furigana", systemImage: "character.textbox")
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
                if messages.isEmpty {
                    loadInitialScenario()
                }
            }
        }
    }

    // MARK: - Scenario Header

    private var scenarioHeader: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.tsumugiDustyDenim)

            Text(dialogueEngine.activeScenario?.title ?? "Conversation Practice")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(Color.tsumugiSpaceIndigo)

            Spacer()

            Menu {
                ForEach(dialogueEngine.availableScenarios) { scenario in
                    Button(scenario.title) {
                        dialogueEngine.selectScenario(scenario)
                        loadInitialScenario()
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Change")
                        .font(.caption)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(Color.tsumugiDustyDenim)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.tsumugiCardSurface)
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

                    if dialogueEngine.isThinking {
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
        }
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                if message.isUser {
                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(.white)
                } else {
                    FuriganaText(
                        markup: message.furiganaMarkup,
                        showFurigana: showFurigana,
                        baseFontSize: 18
                    )
                }

                if showTranslations && !message.englishTranslation.isEmpty {
                    Text(message.englishTranslation)
                        .font(.caption)
                        .foregroundStyle(message.isUser ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(message.isUser ? Color.tsumugiDustyDenim : Color.tsumugiCardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(message.isUser ? Color.clear : Color.tsumugiFrozenWater.opacity(0.4), lineWidth: 1)
                    )
            )

            if !message.isUser {
                Button {
                    audioService.speak(message.text)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(Color.tsumugiDustyDenim)
                        .frame(width: 32, height: 32)
                        .background(Color.tsumugiFrozenWater.opacity(0.4))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Tsumugi is thinking...")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Suggestion Chips

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(currentSuggestions, id: \.self) { suggestion in
                    Button {
                        sendUserMessage(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.tsumugiSpaceIndigo)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.tsumugiFrozenWater.opacity(0.4))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Type in Japanese or Romaji...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.tsumugiCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.tsumugiFrozenWater.opacity(0.5), lineWidth: 1)
                )

            Button {
                sendUserMessage(inputText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary.opacity(0.4) : Color.tsumugiDustyDenim)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.tsumugiBackground)
    }

    // MARK: - Logic & Turn Execution

    private func loadInitialScenario() {
        guard let scenario = dialogueEngine.activeScenario else { return }
        messages.removeAll()

        let initial = ChatMessage(
            text: scenario.initialAIMessage.plainJapanese,
            furiganaMarkup: scenario.initialAIMessage.furiganaMarkup,
            englishTranslation: scenario.initialAIMessage.englishTranslation,
            isUser: false
        )
        messages.append(initial)
        currentSuggestions = scenario.starterSuggestions
    }

    private func sendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMsg = ChatMessage(
            text: trimmed,
            englishTranslation: "",
            isUser: true
        )
        messages.append(userMsg)
        inputText = ""
        currentSuggestions = []

        Task {
            let response = await dialogueEngine.respond(to: trimmed)
            let aiMsg = ChatMessage(
                text: response.plainJapanese,
                furiganaMarkup: response.furiganaMarkup,
                englishTranslation: response.englishTranslation,
                isUser: false
            )
            messages.append(aiMsg)
            currentSuggestions = response.followUpSuggestions
        }
    }
}

#Preview {
    ChatPracticeView()
        .modelContainer(PreviewContainer.shared)
}
