# Architecture & Directory Boundaries

Tsumugi strictly implements a **Feature-First (Modular)** architecture. Code is partitioned by domain capabilities to ensure high cohesion, clean isolation, and zero third-party UI dependencies.

---

## 1. Directory Structure

Tsumugi/
├── App/
│   ├── TsumugiApp.swift                 // App lifecycle & ModelContainer setup
│   └── ContentView.swift                // Root TabView coordinator (4 main tabs)
│
├── Core/                                // Cross-cutting shared infrastructure
│   ├── Models/                          // Global SwiftData entities & shared types
│   │   ├── CharacterCard.swift          // Kana & N5 Kanji persistent entity
│   │   ├── ReviewLog.swift              // Historical review logs & recall stats
│   │   └── Enums/
│   │       ├── WritingCategory.swift    // .hiragana, .katakana, .kanji
│   │       └── SRSGrade.swift           // .again, .hard, .good, .easy
│   ├── SRS/
│   │   └── SRSEngine.swift              // Pure SM-2 algorithm & interval logic
│   ├── Audio/
│   │   └── AudioService.swift           // AVSpeechSynthesizer wrapper (ja-JP TTS)
│   ├── Storage/
│   │   ├── SeedDataLoader.swift         // JSON preloader into SwiftData
│   │   └── PreviewContainer.swift       // In-memory ModelContainer for Xcode Canvas
│   └── DesignSystem/                    // Reusable presentation components
│       ├── ColorTheme.swift             // Brand palette tokens (#6290C3, #1A1B41, etc.)
│       ├── FuriganaText.swift           // Native Ruby text renderer
│       └── GlassCard.swift              // System material container styling
│
├── Features/                            // Autonomous feature domains
│   ├── Dashboard/                       // Feature 1: Progress, roadmaps, streaks
│   │   ├── DashboardView.swift
│   │   ├── StreakBadgeView.swift
│   │   └── DailyProgressRing.swift
│   │
│   ├── Study/                           // Feature 2: 2D Flashcards & tracing
│   │   ├── StudySessionView.swift
│   │   ├── Flashcard3DView.swift
│   │   ├── StrokeCanvasView.swift       // Canvas / PencilKit stroke validation
│   │   └── ReviewControlBar.swift       // Native grading controls & haptics
│   │
│   ├── SpatialLab/                      // Feature 3: RealityKit & ARKit
│   │   ├── SpatialLabView.swift
│   │   ├── RealityStrokeView.swift      // 3D air-drawing in RealityView
│   │   └── RadicalSnapperView.swift     // 3D radical puzzle assembly
│   │
│   └── Chat/                            // Feature 4: On-device conversational AI
│       ├── ChatView.swift
│       ├── LocalAIEngine.swift          // Foundation Models / local SLM interface
│       ├── ChatBubbleView.swift
│       └── MessageModel.swift
│
└── Resources/
    ├── Data/                            // Bundled seed datasets
    │   ├── hiragana.json
    │   ├── katakana.json
    │   └── n5_kanji.json
    └── Assets.xcassets                  // App icons, colors, native audio assets


## 2. Encapsulation & Dependency Rules

1. **Feature Isolation:**
   - Files within a feature folder (e.g., `Features/Study/`) must never import or directly instantiate views from another feature folder (e.g., `Features/Chat/`).
   - Cross-feature navigation is managed exclusively at the root level via `App/ContentView.swift`.

2. **Core Ingestion:**
   - Features may import and consume models, services, and design system components from `Core/*`.
   - `Core/*` must remain domain-agnostic and never import or reference views inside `Features/*`.

3. **Data Flow & State Isolation:**
   - UI views interact with persistent data via `@Query` or by passing down SwiftData `@Model` references.
   - Database mutations must occur on `@MainActor` or through explicit user actions—never during view body rendering.

## 3. Layer Responsibilities

| Layer | Responsibility | Primary Frameworks |
| :--- | :--- | :--- |
| **`App/`** | Root lifecycle, schema initialization, and TabView routing | `SwiftUI`, `SwiftData` |
| **`Core/Models/`** | Persistent schemas and domain enums | `SwiftData`, `Foundation` |
| **`Core/SRS/`** | Pure mathematical calculations for spaced repetition intervals | `Foundation` |
| **`Core/Audio/`** | Offline Japanese pronunciation and audio feedback | `AVFoundation` |
| **`Core/Storage/`** | Bundled data ingestion and in-memory mock setup | `SwiftData`, `Foundation` |
| **`Features/`** | Domain UI, user interactions, local state, and animations | `SwiftUI`, `RealityKit`, `Charts` |
| **`Resources/`** | Raw static assets and bundled JSON schemas | `JSON`, `xcassets` |
