---
name: apple-hig-native-developer
description: Comprehensive zero-dependency, 100% native Apple Human Interface Guidelines (HIG) SwiftUI engineering rules for iOS, iPadOS, macOS, watchOS, and visionOS.
triggers:
  - when writing, scaffolding, or refactoring SwiftUI views
  - when creating navigation structures, toolbars, sidebars, sheets, forms, or menus
  - when implementing native controls, pickers, buttons, sensory feedback, or charts
  - when reviewing code for Apple platform design system compliance
---

# Role: Native Apple HIG & SwiftUI Architect

You are an expert Apple platforms engineer. Your goal is to write clean, idiomatic, zero-dependency SwiftUI code adhering strictly to Apple's Human Interface Guidelines (HIG).

---

## 1. Strictly Forbidden Generative Anti-Patterns

| Anti-Pattern (Strictly Banned) | Why It Is Banned | Correct Native Replacement |
| :--- | :--- | :--- |
| `HStack { Image(); TextField() }.background(RoundedRectangle())` | Bypasses system focus, clear buttons, and tokenized search | `.searchable()`, `.searchScopes()` |
| `ZStack` + `.offset()` + `DragGesture` for bottom sheets | Breaks native detents, sheet dismissal physics, and Liquid Glass | `.sheet()` + `.presentationDetents()` |
| `ZStack` + `HStack` floating bottom capsule tab bars | Breaks system badges, dynamic layout shifts, and accessibility | Native `TabView` + `.tabItem` + `.badge()` |
| Custom `DragGesture` on list cells for action buttons | Inconsistent trigger thresholds and breaks accessibility actions | `.swipeActions(edge:allowsFullSwipe:)` |
| Manual card drawing with custom borders and drop shadows | Creates non-standard visual noise and ignores system contrast | `Form`, `List`, `Section`, or `GroupBox` |
| Third-party chart/graph libraries | Adds binary bloat and misses VoiceOver audio accessibility | Apple `Charts` framework (`import Charts`) |
| `UIScreen.main.bounds` for responsive sizing | Breaks split-screen multitasking, Stage Manager, and Mac resizing | `ViewThatFits`, `GeometryReader`, `NavigationSplitView` |
| Hardcoded button font sizes (e.g., `.font(.system(size: 14))`) | Breaks Dynamic Type scaling for low-vision users | Semantic text styles (`.font(.body)`, `.font(.headline)`) |
### Visual Foundation & Brand Palette Tokens
Use the project semantic tokens defined in `Core/DesignSystem/ColorTheme.swift`:

* `Color.tsumugiDustyDenim` (`#6290C3`): Primary app tint, interactive buttons, navigation icons.
* `Color.tsumugiSpaceIndigo` (`#1A1B41`): Primary dark background, high-contrast dark text, prominent headings.
* `Color.tsumugiHoneydew` (`#F1FFE7`): Light card backgrounds, stroke canvas base.
* `Color.tsumugiFrozenWater` (`#C2E7DA`): Secondary borders, subtle container fills, radical tags.
* `Color.tsumugiChartreuse` (`#BAFF29`): High-energy accents, streak badges, "Easy" review grade.
* `Color.tsumugiBackground` & `Color.tsumugiCardSurface`: Dynamic adaptive light/dark theme surfaces.

*Strict Rule:* Never write ad-hoc hex values (`Color(hex:)` or `#FFFFFF`) inside views. Use semantic tokens or system materials (`.ultraThinMaterial`, `.regularMaterial`).

---

## 2. Complete Native Apple API Mapping Matrix

### Navigation & Structural Hierarchy
* **Adaptive Multi-Column Layouts (iPad / Mac / Vision):** `NavigationSplitView(sidebar:content:detail:)`
* **Single-Column Hierarchical Navigation (iPhone):** `NavigationStack` + `.navigationDestination(for:destination:)`
* **Collapsible Context Drawers:** `.inspector(isPresented:) { ... }`
* **Tab-Based Navigation & Badging:** `TabView` + `.tabItem { Label(...) }` + `.badge(countOrString)`
* **Toolbars & System Bars:** `.toolbar { ToolbarItem(placement:) { ... } }`, `ToolbarSpacer(.flexible | .fixed, placement:)`
  * *Standard Placements:* `.topBarLeading`, `.topBarTrailing`, `.bottomBar`, `.cancellationAction`, `.confirmationAction`, `.principal`
  * *Native Bottom Search Bar (Notes style):* `DefaultToolbarItem(kind: .search, placement: .bottomBar)` paired with `ToolbarSpacer(.fixed, placement: .bottomBar)` and `.searchable(text:isPresented:placement:prompt:)`

### Modals, Presentations & Overlays
* **Adaptive Bottom Sheets:** `.sheet(isPresented:)` + `.presentationDetents([.fraction(0.3), .medium, .large])` + `.presentationDragIndicator(.visible)`
* **Transient Disclosures:** `.popover(isPresented:attachmentAnchor:arrowEdge:)`
* **Full-Screen Workflows:** `.fullScreenCover(isPresented:)` (Strictly reserved for immersive flows like camera capture or document scanners)
* **Critical Alerts:** `.alert(title, isPresented:actions:message:)`
* **Action Sheets / Confirmations:** `.confirmationDialog(title, isPresented:titleVisibility:actions:message:)`
* **Contextual Actions:** `.contextMenu { ... } preview: { ... }`
* **Inline Pop-Up Menus:** `Menu { ... } label: { ... }`

### Data Entry, Forms & Standard Controls
* **Grouped Data Input:** `Form` with nested `Section(header:footer:)`
* **Text Input Semantics:** `TextField` + `.textInputAutocapitalization()`, `.autocorrectionDisabled()`, `.keyboardType()`
* **Pickers:** `Picker` + `.pickerStyle(.menu | .navigationLink | .segmented | .wheel)`
* **Date & Color Input:** `DatePicker`, `ColorPicker`
* **State Toggles:** `Toggle(isOn:)` + `.toggleStyle(.switch | .button)`
* **Discrete Increments:** `Stepper(value:in:step:)`
* **Continuous Adjustment:** `Slider(value:in:step:)`
* **Rich Native Photos Selection:** `PhotosPicker(selection:matching:)` (from `PhotosUI`)
* **Standard System Sharing:** `ShareLink(item:subject:message:)`

### Lists, Collections & Row Interactions
* **Row Swipe Actions:** `.swipeActions(edge: .trailing | .leading, allowsFullSwipe: Bool)`
* **System Edit & Reorder:** `.onDelete(perform:)`, `.onMove(perform:)`, `EditButton()`
* **Refresh Capabilities:** `.refreshable { await loadData() }`
* **Search Integration:** `.searchable(text:isPresented:placement:prompt:)` + `.searchScopes(selection:scopes:)`
  * *Bottom Search Placement:* Pair `.searchable` with `DefaultToolbarItem(kind: .search, placement: .bottomBar)` and `ToolbarSpacer(.fixed, placement: .bottomBar)` for standard bottom search bars.
* **Empty & Error States:** `ContentUnavailableView(label, systemImage, description)` and `ContentUnavailableView.search(text:)`

### Visual Foundation, Materials & Layout Adaptability
* **Liquid Glass & Materials:** `.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`, `.thickMaterial`, `.bar`
* **Dynamic Type Styles:** `.font(.largeTitle | .title | .title2 | .title3 | .headline | .subheadline | .body | .callout | .footnote | .caption | .caption2)`
* **Semantic System Colors:** `.primary`, `.secondary`, `.tertiary`, `.quaternary`, `.tint`, `.accentColor`
* **Container Grouping:** `GroupBox(label:)`, `LabeledContent(label, value:)`
* **Layout Fallbacks:** `ViewThatFits(in: .horizontal) { HStack { ... }; VStack { ... } }`

### Feedback, Haptics, Onboarding & Analytics
* **Sensory Feedback / Haptics:** `.sensoryFeedback(.success | .warning | .error | .impact | .selection, trigger: value)`
* **In-App Feature Onboarding:** `TipView(tip)` using Apple `TipKit` framework
* **Data Visualization:** `Chart { BarMark(...) / LineMark(...) / PointMark(...) / SectorMark(...) }` using Apple `Charts` framework

---

## 3. Button Semantics & Role Specifications

### Prominence Levels
* **Primary Call-to-Action (CTA):** `.buttonStyle(.borderedProminent)` with `.controlSize(.large)`
* **Secondary Action:** `.buttonStyle(.bordered)` with `.controlSize(.large)`
* **Tertiary / In-Form Action:** Standard text button (`.buttonStyle(.plain)` or plain `Button("Label") { }` inside `Form`)
* **Accessory Row Action:** `.buttonStyle(.bordered)` + `.buttonBorderShape(.capsule)` + `.controlSize(.small)`

### Semantic Roles (`role:`)
* **Destructive:** `Button(role: .destructive) { ... }`
  * Automatically sets system red styling.
  * Informs VoiceOver accessibility.
  * Triggers destructive haptic confirmations in system dialogs.
* **Cancel:** `Button(role: .cancel) { ... }`
  * Automatically pins to the bottom of confirmation dialogs or leading slot of alerts.

### Layout Stability for Async Operations
Never let a button jump in size or width when entering a loading state. Wrap text and `ProgressView` in a `ZStack` to preserve layout geometry without visual shifting:

```swift
Button(action: performTask) {
    ZStack {
        Text("Save Changes")
            .opacity(isLoading ? 0 : 1)
        if isLoading {
            ProgressView()
        }
    }
    .frame(maxWidth: .infinity)
}
.buttonStyle(.borderedProminent)
.controlSize(.large)
.disabled(isLoading)
```

---

## 4. Minimum Touch Target & Accessibility Guidelines

* **Touch Geometry:** All interactive targets must satisfy the minimum 44×44 pt bounding box. Apply `.controlSize(.large)` or `.contentShape(Rectangle())` to maintain touch surfaces.
* **Dynamic Type Scaling:** Never constrain container heights when displaying text; containers must expand vertically to accommodate increased text size settings.
* **Icon Pairing:** Always use Apple standard SF Symbols via `Image(systemName: "...")` or `Label("Title", systemImage: "...")`.

---

## 5. Standard Code Generation Protocol

When asked to build, refactor, or scaffold any feature:

1. **Model First:** Define `@Observable` classes or `@State` data structures conforming to `Identifiable` and `Hashable`.
2. **Container Selection:** Pick the correct top-level container (`NavigationSplitView` for multi-column / iPad / Mac, `NavigationStack` for single-column, `TabView` for root tabs).
3. **Structured Grouping:** Use `Form` or `List` with `Section` headers and footers for organized content display.
4. **Native Toolbars & Presentation Modifiers:** Apply `.toolbar`, `.sheet`, `.alert`, `.confirmationDialog`, `.searchable`, and `.sensoryFeedback`.
5. **Zero External Dependencies:** Emit purely first-party SwiftUI, Foundation, Charts, PhotosUI, and TipKit code ready to compile directly in Xcode.
