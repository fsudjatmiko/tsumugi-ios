import AVFoundation
import Foundation
import Observation

/// MainActor isolated service managing offline Japanese speech synthesis via AVSpeechSynthesizer.
@Observable
@MainActor
public final class AudioService: NSObject, AVSpeechSynthesizerDelegate {
    public static let shared = AudioService()

    public private(set) var isSpeaking: Bool = false

    @ObservationIgnored
    private let synthesizer: AVSpeechSynthesizer

    @ObservationIgnored
    private let japaneseVoice: AVSpeechSynthesisVoice?

    public override init() {
        self.synthesizer = AVSpeechSynthesizer()
        // Locate offline Japanese voice
        self.japaneseVoice = AVSpeechSynthesisVoice(language: "ja-JP")
            ?? AVSpeechSynthesisVoice.speechVoices().first { $0.language.starts(with: "ja") }
        super.init()
        self.synthesizer.delegate = self
    }

    /// Speaks the given Japanese text or kana using offline ja-JP voice synthesis.
    ///
    /// - Parameters:
    ///   - text: The Japanese string to pronounce.
    ///   - rate: Speech rate modifier (defaults to slightly slower 0.45 for clarity).
    ///   - pitchMultiplier: Pitch modifier between 0.5 and 2.0 (defaults to 1.0).
    public func speak(_ text: String, rate: Float = 0.45, pitchMultiplier: Float = 1.0) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Stop any currently running speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = japaneseVoice
        utterance.rate = rate
        utterance.pitchMultiplier = pitchMultiplier
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.05

        // Configure audio session for playback
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // Audio session configuration warning (non-fatal)
        }
        #endif

        synthesizer.speak(utterance)
    }

    /// Stops any active speech synthesis immediately.
    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
