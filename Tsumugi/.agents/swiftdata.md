# SwiftData & Persistence Guidelines

You are adhering to modern, thread-safe, and production-grade SwiftData practices for iOS 17+.

---

## 1. Schema & Model Definition Rules

* **Explicit Primary Keys:** Always annotate unique identifiers with `@Attribute(.unique)` to ensure clean upserts during JSON seed preloading.
* **Primitive & Codable Attributes:** Use Swift standard types (`String`, `Int`, `Double`, `Date`, `Bool`) or primitive-backed Enums conforming to `Codable, Sendable`.
* **Explicit Relationships:** Always define inverse relationships explicitly using `@Relationship(inverse: \Type.property)` to prevent orphaned records.
* **Cascade Deletes:** Use `@Relationship(deleteRule: .cascade)` when child entities (like review logs) must be cleared with their parent character card.

## 2. Strictly Forbidden SwiftData Anti-Patterns

| Anti-Pattern (Forbidden) | Why It Is Banned | Correct Modern Replacement |
| :--- | :--- | :--- |
| Injecting `@Environment(\.modelContext)` inside non-view helper classes | `ModelContext` is tied to SwiftUI view hierarchy and `@MainActor` lifecycle | Pass `ModelContext` explicitly into methods or use a dedicated background actor with `ModelContainer` |
| Manual in-memory array filtering for large sets | Bypasses SQLite indexing and exhausts device memory | Use `@Query(filter:sort:)` with `#Predicate` macros |
| Mutating models across different concurrent threads | SwiftData models are not thread-safe across different tasks | Confine UI model operations to `@MainActor`, or pass model identifiers (`PersistentIdentifier`) across actors |
| Hardcoding non-isolated database mutations in SwiftUI body | Triggers re-renders and risks database race conditions | Wrap mutations in explicit user actions or async tasks |

## 3. Query & Predicate Patterns

* **Predicate Composition:** Write type-safe queries using `#Predicate<T>`. Keep predicates simple and evaluatable at compile time:
  ```swift
  // Fetch due cards for SRS review
  @Query(
      filter: #Predicate<CharacterCard> { card in
          card.isUnlocked == true && card.nextReviewDate <= Date.now
      },
      sort: \CharacterCard.nextReviewDate,
      order: .forward
  )
  private var dueCards: [CharacterCard]
  ```

* category filtering:
@Query(filter: #Predicate<CharacterCard> { $0.categoryRaw == "hiragana" })
private var hiraganaCards: [CharacterCard]

### Section 4: In-Memory Preview Container Standard

```markdown
## 4. In-Memory Preview Container Standard

Every SwiftUI view that depends on SwiftData MUST use an in-memory `ModelContainer` inside `#Preview` blocks to prevent polluting the physical SQLite database during development:

```swift
@MainActor
struct PreviewContainer {
    static let shared: ModelContainer = {
        let schema = Schema([CharacterCard.self, ReviewLog.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return container
        } catch {
            fatalError("Failed to initialize preview container: \(error)")
        }
    }()
}

// In your view's #Preview block:
#Preview {
    StudySessionView()
        .modelContainer(PreviewContainer.shared)
}

### Section 5: Seed Preloading Protocol

```markdown
## 5. Seed Preloading Protocol

* Check if the database is already populated before reading JSON from the main bundle:
  ```swift
  @MainActor
  func preloadSeedDataIfNeeded(context: ModelContext) {
      let descriptor = FetchDescriptor<CharacterCard>()
      let existingCount = (try? context.fetchCount(descriptor)) ?? 0
      guard existingCount == 0 else { return }
      
      // Parse JSON from Bundle.main and insert
  }