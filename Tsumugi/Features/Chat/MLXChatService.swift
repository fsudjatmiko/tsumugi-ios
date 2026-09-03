import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom
import Observation

/// On-device local AI Japanese tutoring service using MLX Swift with Qwen 2.5 1.5B 4-bit.
@Observable
@MainActor
public final class MLXChatService {
    public static let shared = MLXChatService()

    // MARK: - State Properties

    public var isModelLoading: Bool = false
    public var isModelReady: Bool = false
    public var downloadProgress: Double = 0.0
    public var isGenerating: Bool = false
    public var statusMessage: String = "Ready"
    public var errorMessage: String? = nil

    @ObservationIgnored
    private var modelContainer: ModelContainer?

    // Default configuration for Qwen 2.5 1.5B 4-bit (id: "mlx-community/Qwen2.5-1.5B-Instruct-4bit")
    @ObservationIgnored
    private let modelConfiguration = LLMRegistry.qwen2_5_1_5b

    public init() {}

    // MARK: - Model Preparation

    /// Asynchronously prepares and loads the model into memory.
    public func prepareModel() async {
        guard !isModelReady, !isModelLoading else { return }

        isModelLoading = true
        downloadProgress = 0.0
        statusMessage = "Loading Local AI Tutor..."
        errorMessage = nil

        do {
            // Set random seed for consistent generation behavior
            MLXRandom.seed(UInt64(Date().timeIntervalSince1970))

            // Load LLM container via MLX ModelFactory with progress tracking
            let container = try await LLMModelFactory.shared.loadContainer(
                configuration: modelConfiguration
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = progress.fractionCompleted
                    self?.statusMessage = String(
                        format: "Preparing Model (%.0f%%)...",
                        progress.fractionCompleted * 100
                    )
                }
            }

            self.modelContainer = container
            self.isModelReady = true
            self.isModelLoading = false
            self.downloadProgress = 1.0
            self.statusMessage = "Model Ready"
        } catch {
            self.isModelLoading = false
            self.isModelReady = false
            self.errorMessage = "Failed to load local model: \(error.localizedDescription)"
            self.statusMessage = "Load Error"
            print("⚠️ [MLXChatService] Error loading model: \(error)")
        }
    }

    // MARK: - Inference & Streamed Generation

    /// Streams token responses for the dialogue in real-time.
    public func send(
        prompt: String,
        chatHistory: [ChatMessage]
    ) async -> AsyncStream<String> {
        let systemPrompt = """
        <|im_start|>system
        You are Tsumugi (つむぎ), an encouraging native Japanese tutor.
        When the user talks in English or asks "how do I say X", teach them how to say it in natural, polite Japanese.
        Never refuse benign daily language learning queries.

        Always answer strictly in this exact two-part format:
        [JA]: Natural, polite Japanese sentence without any parentheses or pronunciation guides.
        [EN]: English meaning of the sentence.

        Example User: I want to ask my teacher so i can go to the toilet
        Example Assistant:
        [JA]: トイレに行ってもいいですか？
        [EN]: May I go to the restroom?

        Example User: Good morning! How is the weather today?
        Example Assistant:
        [JA]: おはようございます！今日の天気はいかがですか？
        [EN]: Good morning! How is the weather today?
        <|im_end|>
        """

        var formattedPrompt = systemPrompt + "\n"

        // Append recent conversation context
        let recentHistory = chatHistory.suffix(6)
        for msg in recentHistory {
            let role = msg.isUser ? "user" : "assistant"
            formattedPrompt += "<|im_start|>\(role)\n\(msg.text)<|im_end|>\n"
        }

        // Current user prompt
        formattedPrompt += "<|im_start|>user\n\(prompt)<|im_end|>\n<|im_start|>assistant\n"

        isGenerating = true
        errorMessage = nil

        return AsyncStream { continuation in
            Task.detached(priority: .userInitiated) { [weak self, formattedPrompt] in
                guard let self = self else {
                    continuation.finish()
                    return
                }

                // If container not ready, attempt to load first
                var activeContainer = await self.modelContainer
                if activeContainer == nil {
                    await self.prepareModel()
                    activeContainer = await self.modelContainer
                }

                guard let container = activeContainer else {
                    await MainActor.run {
                        self.isGenerating = false
                        self.errorMessage = "Model container is not loaded."
                    }
                    continuation.yield("[JA]: 申し訳(もうしわけ)ありません。ローカルAIモデルを読(よ)み込(こ)めませんでした。\n[ROMAJI]: Moushiwake arimasen. Rookaru AI moderu o yomikomemasen deshita.\n[EN]: I'm sorry. Could not load the local AI model.")
                    continuation.finish()
                    return
                }

                do {
                    // Execute generation within container context
                    try await container.perform { context in
                        let input = try await context.processor.prepare(input: .init(prompt: formattedPrompt))
                        let generateParameters = GenerateParameters(
                            temperature: 0.6,
                            topP: 0.9
                        )

                        for try await generation in try MLXLMCommon.generate(
                            input: input,
                            parameters: generateParameters,
                            context: context
                        ) {
                            switch generation {
                            case .chunk(let text):
                                // Strip special tokens if yielded
                                let sanitized = text
                                    .replacingOccurrences(of: "<|im_end|>", with: "")
                                    .replacingOccurrences(of: "<|im_start|>", with: "")
                                continuation.yield(sanitized)
                            case .info:
                                break
                            @unknown default:
                                break
                            }
                        }
                    }

                    await MainActor.run {
                        self.isGenerating = false
                    }
                    continuation.finish()
                } catch {
                    await MainActor.run {
                        self.isGenerating = false
                        self.errorMessage = "Generation error: \(error.localizedDescription)"
                    }
                    continuation.yield("\n\n[JA]: エラーが発生(はっせい)しました。\n[ROMAJI]: Eraa ga hassei shimashita.\n[EN]: An error occurred: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }
}
