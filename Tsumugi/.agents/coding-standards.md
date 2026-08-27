# Swift, SwiftUI & Concurrency Standards

---

## 1. Modern Observation & State Management (iOS 17+)

* **Pure Swift Observation:** Always use the `@Observable` macro for reference-type state models and services.
* **Strictly Banned Legacy APIs:** 
  * Do NOT use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject`.
  * Do NOT `import Combine` for state management.
* **Property Wrapper Rules in Views:**
  * Use `@State` when instantiating or owning an `@Observable` model inside a view (`@State private var audioService = AudioService()`).
  * Use a simple unadorned property when passing down an `@Observable` object (`var card: CharacterCard`).
  * Use `@Bindable` only when creating two-way bindings to properties on an `@Observable` object (`@Bindable var viewModel = viewModel`).

---

## 2. Concurrency & Actor Isolation

* **UI Thread Safety:** Annotate all services interacting with views, audio, or UI frameworks with `@MainActor`.
* **Async Operations:** Mark heavy operations (JSON decoding, database imports) as `async` functions.
* **Modern Task Usage:** Use `.task { ... }` modifier on views for lifecycle-bound asynchronous work rather than `.onAppear` with manual task management.

---

## 3. Spaced Repetition (SRS) Rules

* Standardize all scheduling calculations on the SM-2 algorithm:
  * Ease Factor floor: `1.3` (starts at `2.5`).
  * Interval progression: `1 day` -> `6 days` -> `Interval * EF`.
  * Failed reviews (`SRSGrade.again`): Reset `repetitions = 0` and `interval = 1`.

---

## 4. View Architecture & Clean Code

* **Body Size Limit:** Break view bodies into private helper views or `@ViewBuilder` computed properties if a body exceeds 40 lines.
* **Layout Stability:** Never allow buttons or cards to jump size during state changes; use `ZStack` overlays for loading indicators.
* **Canvas Previews:** Every view must include a `#Preview` block using `PreviewContainer.shared` for SwiftData dependencies.