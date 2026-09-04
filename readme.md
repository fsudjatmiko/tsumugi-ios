# Tsumugi (つむぎ) — iOS Spatial Japanese Learning

An iOS spatial language-learning app for beginner Japanese learners and JLPT N5 candidates, where players trace surface-projected characters, assemble radical puzzles, and practice interactive conversation with an AI tutor to achieve foundational literacy in Hiragana, Katakana, and core Kanji, while managing stroke order accuracy, spaced-repetition retention intervals, and daily study queues.

The app delivers an intuitive, tactile, and conversational learning experience and is built using ARKit, RealityKit, SwiftData, and MLX Swift alongside Apple’s native linguistic frameworks to enable plane-detected spatial writing, persistent study progress, and on-device Japanese dialogue with synchronized Ruby furigana annotations.

---

### Core Pillars

* **Spatial Lab (Surface Tracing & AR Guidance)**: Scans flat horizontal surfaces (tables, desks) using ARKit raycasting, projects semi-transparent stencils of kana and kanji, validates multi-point stroke trajectory in order, and elevates completed characters into full 3D metallic models.
* **Radical Fusion (50-Stage Campaign)**: An interactive tactile puzzle system where learners drag individual kanji radicals together, triggering magnetic snapping and visual reveals of compound kanji with mnemonics, readings, and audio pronunciation.
* **Spaced Repetition System (SRS Review)**: An SM-2 inspired flashcard engine supporting rapid binary card flips (Forgot / Got It) and tactile writing modes with directional stroke checks.
* **Conversational AI Tutor (Tsumugi)**: An on-device dialogue partner powered by MLX Swift. Employs Apple's native CoreFoundation linguistic tokenization (`CFStringTransform`, `CFStringTokenizer`) to render verified Ruby furigana perched above kanji, with synchronized Romaji phonetics and multiline English translations.
* **Curriculum Mastery**: Complete character libraries covering all 46 Hiragana, 46 Katakana, and the 80 foundational Elementary Grade 1 (JLPT N5) Kanji organized into thematic clusters.

---

### Tech Stack & Architecture

| Layer | Technologies |
| --- | --- |
| **Platform** | iOS 17.0+ (Universal iPhone / iPad) |
| **Frameworks** | SwiftUI, Swift 5.9+, Observation (`@Observable`) |
| **Spatial & 3D** | ARKit, RealityKit, `ARWorldTrackingConfiguration`, Raycasting |
| **Persistence** | SwiftData (`UserProfile`, `CharacterCard`, `ChatSession`, `ChatMessage`) |
| **On-Device AI** | MLX Swift, Qwen 1.5B Instruct |
| **Linguistics & Audio** | CoreText, `CoreFoundation`, `NaturalLanguage`, `AVFoundation` (`AVSpeechSynthesizer`) |
| **Design** | Apple Human Interface Guidelines (HIG), Dynamic Type, Native System Toolbars |

---

### Requirements & Setup

* **Xcode**: 15.0 or later
* **macOS**: Sonoma 14.0 or later
* **Hardware**: Physical iPhone/iPad running iOS 17+ with an A12 Bionic chip or newer (recommended for ARKit camera passthrough and on-device MLX neural inference).
