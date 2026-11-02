# 💡 Learnings: Canonical Liquid Glass Composer Architecture, Native `.interactive()` Touch-Down Breathing, and `.overlay` Menu Isolation in ConversationKit v2

**Author**: Learnings Agent & ConversationKit v2 Engineering Team  
**Date**: 2026-11-02  
**Tags**: `SwiftUI`, `LiquidGlass`, `MicroInteractions`, `ShaderMetaballs`, `SofiaPattern`, `Menus`, `Performance`, `iOS26`, `macOS26`  

---

## Summary

During the Jony Ive & Craig Federighi architectural review and `Sofia` reference analysis of `ConversationKit` v2 for iOS 26+ and macOS 26+, we replaced fragile layout-driven spacing mutations and `.popover` workarounds with the canonical Apple Liquid Glass composer architecture. We discovered that mutating `HStack(spacing: isFocused ? 3 : 8)` created a permanent "dog-bone" metaball weld for the entire duration of typing, whereas combining static `GlassEffectContainer(spacing: 12)` and `HStack(alignment: .bottom, spacing: 8)` with `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))` delegates transient touch-down inflation directly to SwiftUI's native C++/Metal shader—producing an effortless fluid "kiss" against the `44×44pt` bookend siblings on finger press and separating cleanly on release. Furthermore, we identified why SwiftUI `Menu` previously vanished the composer pill—`UIContextMenuInteraction` captured the entire outer `.interactive()` glass vessel as its targeted preview—and resolved it cleanly using our refined `Sofia`-style **`ComposerMenuSlotAnchorKey: PreferenceKey` + `.overlayPreferenceValue`** pattern (declaring each accessory row only once inside `panelContent` so the visual label breathes with the glass shader, while positioning a zero-opacity interactive `Menu` hit-target via `proxy[anchor]` outside `.glassEffect` with zero duplicate `HStack`s and zero `Color.clear` dummy spacers), alongside `PlatformPasteboard.hasAttachments` for zero-allocation pasteboard metadata checks inside `Menu` bodies, the 3-zone bookend sibling grammar (`Sofia` pattern), true 1:1 circular glass (`Sofia` Part 9), pure `.safeAreaBar(edge: .bottom)` refraction without opaque `LinearGradient` backdrops, and our **Canonical SwiftUI Performance & Ergonomics Refinements (`F-02`, `F-03`, `F-04`, `F-08`)** (`EnvironmentBindingBox: Equatable`, lazy `MessageComposerStyleConfiguration` subview slots, native `TextField` prompt when `tokens.isEmpty`, and unary `MessageView` root + zero-allocation `ForEach` enumeration).

---

## The Problem / Challenge (`## The Problem or Puzzle`)

### 1. Why Dynamic Focus Spacing (`isFocused ? 3 : 8`) & Scale/Timer Hacks Failed
In earlier iterations of `ClassicGlassMessageComposerStyle`, we attempted to simulate Apple's Liquid Glass "kiss" by dynamically mutating layout spacing based on `@FocusState`:
- **Oversized `GlassEffectContainer(spacing: 28)`:** Fused the detached `+` circle and text pill permanently at rest.
- **Focus-driven `HStack(spacing: isFocused ? 3 : 8)` inside `GlassEffectContainer(spacing: 8)`:** While crisp when unfocused, the moment the user tapped the text field to type, `isFocused` became `true` and remained `true` for the entire typing session. Because $d = 3\text{pt} < R_{\text{merge}} = 8\text{pt}$, the leading `+` button and text pill remained **permanently welded into a deformed dog-bone for the entire duration of typing**.
- **Manual `@State` timers or scale hacks:** Attempting to pulse spacing or scale via Swift timers on focus change introduced state churn, conflicted with interactive keyboard dismissal, and failed to respond to actual touch-down physics.

### 2. Why `Menu` Vanished the Entire Composer Pill Earlier
When placing `ComposerModelSelectorMenu` (a native SwiftUI `Menu`) directly inside the `HStack` wrapped by `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))`, tapping the model selector caused the **entire interactive composer vessel to vanish from the screen**. 
- An earlier workaround replaced `Menu` with a custom `.popover(isPresented:arrowEdge: .bottom)` + `.presentationCompactAdaptation(.popover)`. However, a custom popover loses native iOS/macOS menu ergonomics: drag-to-select gesture continuity, native spring scale physics, automatic checkmark alignment, and system material vibrancy. We needed native `Menu` and native `.interactive()` glass to coexist without conflict.

### 3. Crammed Single-Pill Controls, Opaque `.safeAreaBar` Gradients, and Oval `.buttonStyle(.glass)` Distortions
Three additional structural flaws degraded the iOS 26 / macOS 26 Liquid Glass fidelity:
- **Asymmetric Single-Sided Sibling Grammar:** Stuffing the primary `Send`/`Stop` submit button inside the text pill alongside the model selector, dictation, and keyboard dismiss controls overcrowded the trailing edge of the text vessel and deprived the primary action of prominent bookend weight.
- **Opaque `LinearGradient` Under `.safeAreaBar(edge: .bottom)`:** Placing a `LinearGradient` backdrop behind the bottom bar killed real-time background refraction—the signature optical property of Liquid Glass—and conflicted with `.scrollEdgeEffectStyle(.soft, for: .bottom)`.
- **Stretched Oval Circles from `.buttonStyle(.glass)` + `.buttonBorderShape(.circle)`:** Relying on `.buttonStyle(.glass)` with `.buttonBorderShape(.circle)` allowed SwiftUI's intrinsic button padding heuristics to stretch `44×44pt` or `40×40pt` buttons into slightly wider horizontal ovals rather than true 1:1 geometric circles.

---

## Root Cause & Discovery (`## The Discovery`)

### 1. How SwiftUI's C++/Metal `.interactive()` Shader Drives Touch-Down Breathing
In iOS 26 and macOS 26, `.glassEffect(.regular.interactive(), ...)` is not merely a static refractive material—it attaches a hardware-accelerated C++/Metal pointer and touch recognizer directly to the glass surface:

$$\text{Effective Gap } d(t) = d_{\text{static}} - \Delta r_{\text{shader}}(t)$$

When configured with **`GlassEffectContainer(spacing: 12)`** ($R_{\text{merge}} = 12\text{pt}$) and a **static `HStack(alignment: .bottom, spacing: 8)`** ($d_{\text{static}} = 8\text{pt}$):
1. **At Rest & While Typing (`touch up`):** $\Delta r_{\text{shader}} = 0\text{pt}$. Because the static gap $8\text{pt}$ sits cleanly outside the active metaball neck threshold, the left `44×44pt` `+` circle, the center `44pt` interactive text vessel, and the right `44×44pt` tinted `Send`/`Stop` circle render as **three crisp, optically separate Liquid Glass shapes**.
2. **During Finger Press (`touch down`):** The moment the user's finger touches the text vessel (or either circular bookend sibling), SwiftUI's native C++/Metal `.interactive()` shader radially inflates the pressed glass platter ($\Delta r_{\text{shader}} > 4\text{pt}$). This transient expansion crosses the `12pt` `GlassEffectContainer` metaball threshold, causing the center vessel to fluidly **kiss** the left `+` and right `↑` siblings during the press.
3. **On Finger Release (`touch up` / Focus Acquired):** As the finger lifts and the `TextField` assumes focus, the Metal shader smoothly deflates the platter back to its resting $8\text{pt}$ separation. No `@FocusState` spacing mutation, no `Task.sleep` timers, and no manual `.scaleEffect` hacks are required.

### 2. Why `UIContextMenuInteraction` Lifted the Glass Platter & How `ComposerMenuSlotAnchorKey` + `.overlayPreferenceValue` Solves It
The true root cause of the disappearing pill bug lies in how UIKit's `UIContextMenuInteraction` resolves its `UITargetedPreview` when nested inside an interactive Liquid Glass modifier:
1. When an active SwiftUI `Menu` is a child *inside* the view subtree captured by `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))`, the interactive glass container synthesizes a unified compositing group / responder surface for touch-down shader inflation.
2. When the user taps the inner `Menu`, `UIContextMenuInteraction` walks up the responder/compositing tree and captures the **entire outer `.interactive()` glass platter** as the context menu's lift preview—detaching the whole composer pill from its resting coordinate space.
3. However, simply moving the entire accessory row into a static `.overlay(alignment: .bottomTrailing)` outside `.glassEffect` creates two undesirable side effects:
   - Either the visual icon/pill inside the glass vessel no longer participates in the C++/Metal `.interactive()` shader's radial breathing distortion when the user presses the glass surface, **or**
   - Attempting to keep visuals inside `panelContent` while duplicating the layout in `.overlay` requires fragile duplicate `HStack`s, hardcoded reserved width math, or `Color.clear` dummy spacers that drift when dynamic model names or focus transitions resize the toolbar.
4. **The Refined `Sofia`-Style `ComposerMenuSlotAnchorKey: PreferenceKey` + `.overlayPreferenceValue` Pattern (`F-01`):**
   - **Single-Source-of-Truth Layout Inside `panelContent`:** Each accessory row (`innerTrailingAccessories` in `.classicGlass`, `bottomToolbarRow` in `.cardGlass`, and `trailingControls` / leading attachment slot in `.compactGlass`) is declared **only once** inside `panelContent` *before* `.glassEffect(.regular.interactive(), in: ...)`.
   - **Visual-Only Label Inside Glass + `.anchorPreference`:** Inside `panelContent`, each `Menu` slot (`attachmentMenu` and/or `modelSelectorMenu`) receives `.environment(\.isComposerMenuVisualOnly, true)`, `.allowsHitTesting(false)`, `.accessibilityHidden(true)`, and publishes its exact layout bounds via `.anchorPreference(key: ComposerMenuSlotAnchorKey.self, value: .bounds) { [.modelSelectorMenu: $0] }` (or `.attachmentMenu`). Because the visual label (`iconLabel`, `menuIconOnlyLabel`, or `menuPillLabel`) remains inside `panelContent`, it naturally participates in `HStack` layout sizing and breathes/inflates seamlessly with the `.interactive()` C++/Metal shader. Non-menu buttons (`dictationButton`, `dismissKeyboardButton`, `submitButton`) remain directly interactive inside the row with zero duplication.
   - **Zero-Opacity Interactive `Menu` Hit-Target via `.overlayPreferenceValue`:** Immediately *outside* `.glassEffect(.regular.interactive(), ...)`, `.overlayPreferenceValue(ComposerMenuSlotAnchorKey.self)` invokes `composerMenuHitTargetsOverlay(anchors:...)`. A lightweight `GeometryReader` resolves `let rect = proxy[anchor]` for each published slot and positions the actual SwiftUI `Menu` (with `.environment(\.isComposerMenuHitTargetOverlay, true)`, which sets its label `.opacity(0.0)`) at `.frame(width: rect.width, height: rect.height).position(x: rect.midX, y: rect.midY)`.
   - **Result:** Zero duplicate `HStack`s, zero `Color.clear` dummy spacers, and zero manual width-reservation math. `UIContextMenuInteraction` attaches strictly to the post-glass zero-opacity `Menu` hit-target at the exact `Anchor<CGRect>` coordinates while the visible label beneath it refracts and breathes inside the Liquid Glass vessel.
5. **Zero-Allocation Pasteboard Metadata Check Inside `Menu` Bodies (`PlatformPasteboard.hasAttachments`, `F-09`):**
   - Because SwiftUI evaluates `Menu` content closures on the main thread when preparing context menus, calling `PlatformPasteboard.readAttachments().isEmpty` inside `ComposerAttachmentMenuView` previously forced synchronous main-thread decoding and PNG serialization of multi-megabyte clipboard images/files just to decide whether to show the `"Paste from Clipboard"` button.
   - We introduced `@MainActor public static var PlatformPasteboard.hasAttachments: Bool`, which queries lightweight system pasteboard metadata (`UIPasteboard.general.hasImages || hasURLs || contains(pasteboardTypes:)` on iOS, `NSPasteboard.general.canReadObject(forClasses:options:)` / `availableType(from:)` on macOS) in $O(1)$ with zero `Data` or bitmap allocations. Full payload decoding via `PlatformPasteboard.readAttachments()` now runs strictly when the user actually taps `"Paste from Clipboard"`.

### 3. The 3-Zone Bookend Sibling Grammar (`Sofia` Pattern) & True 1:1 Circular Glass (`Sofia` Part 9)
Following the `Sofia` reference architecture, `ClassicGlassMessageComposerStyle` partitions the composer into a balanced **3-Zone Bookend Sibling Grammar**:

```
[ 44×44 + Sibling ]  | 8pt |  [ 44pt Interactive Vessel + Anchor-Isolated Menu Hit Target ]  | 8pt |  [ 44×44 Tinted Send/Stop Sibling ]
```

- **Zone 1 — Outside Left (`44×44pt` Liquid Glass Circle Sibling):** The leading `+` attachment `Menu` button, framed to `44×44pt` with `.glassEffect(.regular.interactive(), in: .circle)`.
- **Zone 2 — Center Interactive Text Vessel (`minHeight: 44pt`, `cornerRadius: 22`):** Houses the growing `TextField` and `innerTrailingAccessories` (`compactModelSelector`, `dictationButton`, `dismissKeyboardButton`) in a single `mainInputRow` inside `panelContent`, while `.overlayPreferenceValue(ComposerMenuSlotAnchorKey.self)` mounts the zero-opacity `Menu` hit-target over `compactModelSelector` outside `.glassEffect`.
- **Zone 3 — Outside Right (`44×44pt` Prominent Tinted Liquid Glass Circle Sibling):** When `canSubmit || isGenerating` is `true`, the trailing `Send`/`Stop` button appears as a detached `44×44pt` sibling with `.glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)`, `.glassEffectTransition(.materialize)`, and `.transition(.scale(scale: 0.85).combined(with: .opacity))` under `.snappy(duration: 0.18)`.
- **True 1:1 Circular Geometry (`Sofia` Part 9):** Across `ClassicGlassComposerBody` (`44×44pt`) and `ScrollToBottomButton` (`40×40pt`), replacing `.buttonStyle(.glass)` + `.buttonBorderShape(.circle)` with `.buttonStyle(.plain)` + explicit `.frame(width: d, height: d)` + `.glassEffect(..., in: .circle)` guarantees mathematically exact 1:1 circular geometry.
- **Pure `.safeAreaBar(edge: .bottom)` Refraction:** Removing the legacy opaque `LinearGradient` from `ConversationView`'s `.safeAreaBar(edge: .bottom)` allows timeline bubbles passing under `.scrollEdgeEffectStyle(.soft, for: .bottom)` to refract naturally through all three Liquid Glass zones.

### 4. When to Use `.matchedGeometry` vs `.materialize` Inside `GlassEffectContainer` & Stationary `emptyStateContainer` Cross-Fade
Two additional transition physics traps surfaced in `ClassicGlass` and `ConversationView` when typing the first character of a draft:
1. **`.glassEffectTransition(.materialize)` vs `.glassEffectTransition(.matchedGeometry)` for Unpaired Conditional Siblings (`ClassicGlass`):**
   - Applying `.glassEffectID("classic.submit", in: glassNamespace)` + `.glassEffectTransition(.matchedGeometry)` to a conditionally inserted sibling (`if showsSubmitButton`) that has **no prior source view** sharing that ID causes the Liquid Glass SDF shader to synthesize a slow, viscous metaball extrusion from the neighboring glass sibling (`classic.textPill`) while the text pill simultaneously compresses its width by `52pt` (`44pt` button + `8pt` gap).
   - Replacing `.glassEffectID` + `.glassEffectTransition(.matchedGeometry)` with `.glassEffectTransition(.materialize)` paired with `.transition(.scale(scale: 0.85).combined(with: .opacity))` and `.snappy(duration: 0.18)` materializes the detached `Send` button crisply in place without unpaired SDF extrusion lag. Reserve `.matchedGeometry` strictly for true 1-to-1 morphs between two views that share a `.glassEffectID` across states.
2. **Stationary `emptyStateContainer` Cross-Fade Rule (`ConversationView`):**
   - Never bind an empty-state placeholder's `minHeight` (with `.center` alignment) to dynamic `ScrollGeometry.containerSize.height` (`currentVisibleHeight`). Because software keyboard appearance and `.safeAreaBar(edge: .bottom)` accessory transitions (such as `SuggestionChipsBar` hiding when typing starts) mutate `containerSize.height`, binding `minHeight` to `currentVisibleHeight` causes the `.center`-aligned placeholder to jump vertically while cross-fading out. Using a static `minHeight: 300` with `.opacity(shouldShowEmptyState ? 1 : 0)` keeps the placeholder completely stationary during keyboard and bottom-bar transitions.

| Style | Layout Grammar | Leading Control | Inner Vessel Accessories | Trailing Primary Action |
| :--- | :--- | :--- | :--- | :--- |
| **`Classic Glass`** (`.classicGlass`) | 3-Zone Bookend Siblings (`GlassEffectContainer(spacing: 12)`, `HStack(spacing: 8)`) | Outside Left `44×44pt` `.glassEffect(.regular.interactive(), in: .circle)` | Single `innerTrailingAccessories` inside `panelContent` + `.overlayPreferenceValue(ComposerMenuSlotAnchorKey.self)` for `compactModelSelector` | Outside Right `44×44pt` `.glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)` |
| **`Card Glass`** (`.cardGlass`) | 2-Row Assistant Card (`cornerRadius: 24`) | Bottom row `32×32pt` bordered circle (`anchorPreference` -> `.attachmentMenu`) | Bottom row full `modelSelector` pill (`anchorPreference` -> `.modelSelectorMenu`) + `dictation` & `dismissKeyboard` | Bottom row `32×32pt` accent circle |
| **`Compact Glass`** (`.compactGlass`) | Single-Row Capsule (`cornerRadius: 22`) | Inside leading `32×32pt` borderless `+` (`anchorPreference` -> `.attachmentMenu`) | Single `trailingControls` inside `panelContent` (`anchorPreference` -> `.modelSelectorMenu`), `dictation`, `dismissKeyboard` | Inside trailing `32×32pt` accent circle |

### 5. Canonical SwiftUI Performance & Ergonomics Refinements (`F-02`, `F-03`, `F-04`, `F-08`)
To ensure 60Hz–120Hz token streaming and keystroke responsiveness remain free of redundant SwiftUI attribute-graph invalidations and heap allocations, we completed four companion refinements:
1. **`EnvironmentBindingBox: Equatable` (`F-02`):** Because `EnvironmentBindingBox<Value>` wraps `@MainActor @Sendable` getter and setter closures to carry two-way bindings inside `@Entry EnvironmentValues` (`selectedComposerModelBox`, `activeComposerCapabilitiesBox`, `composerTokensBox`), Swift cannot auto-synthesize `Equatable`. Without `Equatable`, every 60Hz token tick in `ConversationView` recreated fresh `EnvironmentBindingBox` instances that compared as unequal by closure identity, invalidating downstream composer views even when the selected model, capabilities, and tokens were unchanged. Capturing `public let snapshot: Value = binding.wrappedValue` at initialization and conforming `EnvironmentBindingBox: Equatable where Value: Equatable` (checking `lhs.snapshot == rhs.snapshot` and `MainActor.assumeIsolated { lhs.wrappedValue == rhs.wrappedValue }`) makes `@Entry` diffing $O(1)$ and suppresses false subtree invalidations during streaming.
2. **Lazy Subview Slot Evaluation in `MessageComposerStyleConfiguration` (`F-03`):** Each concrete `MessageComposerStyle` (`ClassicGlassMessageComposerStyle`, `CardGlassMessageComposerStyle`, `CompactGlassMessageComposerStyle`) renders only one attachment button variant (`attachmentButton` or `borderlessAttachmentButton`) and one model selector variant (`compactModelSelector` or `modelSelector`). Backing `MessageComposerStyleConfiguration`'s subview properties (`textField`, `attachmentButton`, `borderlessAttachmentButton`, `attachmentsTray`, `tokensBar`, `modelSelector`, `compactModelSelector`, `capabilitiesBar`, `dictationButton`, `submitButton`, `dismissKeyboardButton`) with lazy `@MainActor` closure builders (`() -> AnyView`) via `internal init(lazyTextField:...)` ensures unused style variants are never constructed or wrapped in `AnyView` on keystrokes, while preserving 100% public API source compatibility.
3. **Native `TextField` Prompt When `tokens.isEmpty` (`F-04`):** `ComposerTextBuffer` injects the `\u{200B}` (`zeroWidthSpace`) backspace sentinel only when `!tokens.isEmpty` so a single backspace on a visually empty input selects/deletes the trailing `/command` or `@mention` token. When `tokens.isEmpty`, the bound text is genuinely `""`. Passing `prompt: hasTokens ? Text("") : Text(placeholder).foregroundStyle(.secondary)` directly to `TextField("", text: textFieldRawBinding, prompt: ..., axis: .vertical)` and scoping the fallback `.overlay(alignment: .leading)` strictly to `if hasTokens && isVisuallyEmpty` restores native SwiftUI placeholder baseline metrics, Dynamic Type scaling, and VoiceOver placeholder traits whenever no tokens are attached.
4. **Unary `MessageView` Root & Zero-Allocation `ForEach` Enumeration (`F-08`):** Wrapping `MessageView.body`'s `switch message.participant` inside a single unary `VStack` root eliminates top-level `_ConditionalContent` structural identity churn inside `ForEach`, while replacing `ForEach(Array(...enumerated()))` with direct `ForEach(toolCalls)` or SE-0459 lazy `EnumeratedSequence` (`collection.enumerated()`) eliminates per-render temporary `Array` heap allocations across timeline and agentic subviews.

---

## The Idiomatic Solution (`## Solution & Architecture Pattern`)

1. **Delegate Breathing Physics to `.interactive()` Inside Static `GlassEffectContainer(spacing: 12)`:** Keep `HStack(alignment: .bottom, spacing: 8)` static. Let the C++/Metal `.interactive()` shader expand the glass platter on `touch down` to bridge the gap and deflate on `touch up`.
2. **Isolate Inner `Menu` Hit Targets via `ComposerMenuSlotAnchorKey` + `.overlayPreferenceValue`:** Declare each accessory row (`innerTrailingAccessories`, `bottomToolbarRow`, `trailingControls`) **only once** inside `panelContent` with `.environment(\.isComposerMenuVisualOnly, true)` and `.anchorPreference(key: ComposerMenuSlotAnchorKey.self, value: .bounds)` on each `Menu` slot, then resolve `proxy[anchor]` in `.overlayPreferenceValue(ComposerMenuSlotAnchorKey.self)` outside `.glassEffect` to position the zero-opacity interactive `Menu` hit-target (`isComposerMenuHitTargetOverlay = true`) with zero duplicate `HStack`s and zero `Color.clear` dummy spacers.
3. **Use `PlatformPasteboard.hasAttachments` Inside `Menu` Builders:** Query pasteboard metadata in $O(1)$ without decoding image/file `Data` blobs on the main thread when rendering `Menu` items.
4. **Enforce 1:1 Circular Glass via Explicit Square Frames + `in: .circle`:** Use `.buttonStyle(.plain)` + `.frame(width: diameter, height: diameter)` + `.glassEffect(..., in: .circle)` rather than `.buttonStyle(.glass)`.
5. **Keep `.safeAreaBar(edge: .bottom)` Transparent:** Never place an opaque or gradient background behind `.safeAreaBar`; combine `.scrollEdgeEffectStyle(.soft, for: .bottom)` on the `ScrollView` with native Liquid Glass vessels in the bar.
6. **Eliminate Streaming & Keystroke Churn (`F-02`, `F-03`, `F-04`, `F-08`):** Conform `EnvironmentBindingBox` to `Equatable where Value: Equatable` via a captured `snapshot: Value`, back `MessageComposerStyleConfiguration` subview slots with lazy `@MainActor` builders, use `TextField`'s native `prompt:` whenever `tokens.isEmpty`, and prefer unary `VStack` roots + direct/lazy `ForEach` collections.

---

## Code Examples

### 1. Native `.interactive()` Touch-Down Breathing & 3-Zone Bookend Siblings (`MessageComposerStyle.swift`)

```swift
// ❌ BEFORE: Dynamic focus spacing welded the '+' button and pill into a permanent dog-bone while typing
GlassEffectContainer(spacing: 8) {
  HStack(alignment: .bottom, spacing: configuration.isFocused ? 3 : 8) {
    if let plusButton = configuration.attachmentButton {
      detachedPlusButton(plusButton)
    }
    classicPill // Stayed fused at 3pt for the entire typing session!
  }
}

// ✅ AFTER: Static 8pt spacing inside 12pt container; C++/Metal .interactive() shader inflates on touch-down and deflates on touch-up
GlassEffectContainer(spacing: 12) {
  HStack(alignment: .bottom, spacing: 8) {
    // Zone 1 (Outside Left): 44×44pt Liquid Glass Circle Sibling (+ Attachment Menu)
    if let plusButton = configuration.attachmentButton {
      detachedPlusButton(plusButton)
    }

    // Zone 2 (Center): Interactive Text Vessel + Borderless Inner Trailing Overlay
    classicPill

    // Zone 3 (Outside Right): 44×44pt Prominent Tinted Liquid Glass Circle Sibling (Send / Stop)
    if showsSubmitButton {
      detachedSubmitButton(configuration.submitButton)
    }
  }
  .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: showsSubmitButton)
}
```

### 2. True 1:1 Circular Glass Siblings & `.glassEffectTransition(.materialize)` (`Sofia` Part 9)

```swift
// ❌ BEFORE: .buttonStyle(.glass) + .buttonBorderShape(.circle) applied horizontal padding heuristics, creating ovals;
// and unpaired .glassEffectID("classic.submit") + .glassEffectTransition(.matchedGeometry) caused viscous SDF extrusion lag
button
  .buttonStyle(.glass)
  .buttonBorderShape(.circle)

// ✅ AFTER: Explicit 44×44pt square frame + .glassEffect(..., in: .circle) guarantees a 1:1 circle,
// and .glassEffectTransition(.materialize) materializes the unpaired conditional sibling crisply in place
private func detachedPlusButton(_ button: AnyView) -> some View {
  button
    .frame(width: 44, height: 44)
    .glassEffect(.regular.interactive(), in: .circle)
    .glassEffectID("classic.leadingPlus", in: glassNamespace)
}

private func detachedSubmitButton(_ button: AnyView) -> some View {
  button
    .frame(width: 44, height: 44)
    .glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)
    .glassEffectTransition(.materialize)
    .transition(.scale(scale: 0.85).combined(with: .opacity))
}
```

### 3. `ComposerMenuSlotAnchorKey: PreferenceKey` + `.overlayPreferenceValue` Isolation & `PlatformPasteboard.hasAttachments` (`MessageComposerStyle.swift`, `ComposerAccessories.swift`, `MessageComposerView.swift`)

```swift
// ❌ BEFORE: Placing an active Menu inside the subtree captured by .glassEffect(.regular.interactive())
// caused UIContextMenuInteraction to lift the entire composer pill as the context menu preview,
// OR duplicating the toolbar HStack with Color.clear dummy spacers caused layout drift.
HStack(alignment: .bottom, spacing: 0) {
  configuration.textField
  innerTrailingAccessories // Active SwiftUI Menu inside .glassEffect lifted the whole pill!
}
.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))

// ✅ AFTER: Single-source-of-truth layout inside panelContent publishes each Menu slot's .bounds
// via ComposerMenuSlotAnchorKey, while .overlayPreferenceValue mounts the zero-opacity interactive Menu outside .glassEffect
private enum ComposerMenuSlotID: Hashable, Sendable {
  case attachmentMenu
  case modelSelectorMenu
}

private struct ComposerMenuSlotAnchorKey: PreferenceKey {
  static let defaultValue: [ComposerMenuSlotID: Anchor<CGRect>] = [:]

  static func reduce(
    value: inout [ComposerMenuSlotID: Anchor<CGRect>],
    nextValue: () -> [ComposerMenuSlotID: Anchor<CGRect>]
  ) {
    value.merge(nextValue(), uniquingKeysWith: { _, new in new })
  }
}

@MainActor
@ViewBuilder
private func composerMenuHitTargetsOverlay(
  anchors: [ComposerMenuSlotID: Anchor<CGRect>],
  attachmentMenu: AnyView? = nil,
  modelSelectorMenu: AnyView? = nil
) -> some View {
  if !anchors.isEmpty {
    GeometryReader { proxy in
      if let anchor = anchors[.attachmentMenu], let attachmentMenu {
        let rect = proxy[anchor]
        attachmentMenu
          .environment(\.isComposerMenuHitTargetOverlay, true)
          .frame(width: rect.width, height: rect.height)
          .position(x: rect.midX, y: rect.midY)
      }

      if let anchor = anchors[.modelSelectorMenu], let modelSelectorMenu {
        let rect = proxy[anchor]
        modelSelectorMenu
          .environment(\.isComposerMenuHitTargetOverlay, true)
          .frame(width: rect.width, height: rect.height)
          .position(x: rect.midX, y: rect.midY)
      }
    }
  }
}

// Each accessory row (innerTrailingAccessories, bottomToolbarRow, trailingControls) is declared ONLY ONCE inside panelContent:
private var innerTrailingAccessories: some View {
  HStack(alignment: .bottom, spacing: 4) {
    if (configuration.hasModels || configuration.hasCapabilities),
       let modelSelector = configuration.compactModelSelector ?? configuration.modelSelector {
      modelSelector
        .environment(\.isComposerMenuVisualOnly, true)
        .frame(width: buttonDiameter, height: buttonDiameter)
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .anchorPreference(key: ComposerMenuSlotAnchorKey.self, value: .bounds) {
          [.modelSelectorMenu: $0]
        }
    }

    if let dictationButton = configuration.dictationButton {
      dictationButton.frame(width: buttonDiameter, height: buttonDiameter)
    }

    if configuration.isFocused, let dismissKeyboardButton = configuration.dismissKeyboardButton {
      dismissKeyboardButton
        .frame(width: buttonDiameter, height: buttonDiameter)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
  }
}

// Inside classicPill (and analogously in CardGlassComposerBody.cardPanel & CompactGlassComposerBody.capsulePill):
panelContent
  .glassEffect(.regular.interactive(), in: .rect(cornerRadius: pillCornerRadius))
  .glassEffectID("classic.textPill", in: glassNamespace)
  .overlayPreferenceValue(ComposerMenuSlotAnchorKey.self) { anchors in
    composerMenuHitTargetsOverlay(
      anchors: anchors,
      modelSelectorMenu: (configuration.hasModels || configuration.hasCapabilities)
        ? (configuration.compactModelSelector ?? configuration.modelSelector)
        : nil
    )
  }
```

Inside `ComposerModelSelectorMenu` (`ComposerAccessories.swift`) and `ComposerAttachmentMenuView` (`MessageComposerView.swift`), the view switches cleanly between its visual-only glass child and its post-glass zero-opacity `Menu` hit-target, using `PlatformPasteboard.hasAttachments` for zero-allocation clipboard checks:

```swift
// ✅ Dual-mode Menu rendering + O(1) PlatformPasteboard.hasAttachments check
if isMenuVisualOnly {
  iconLabel
    .frame(width: effectiveDiameter, height: effectiveDiameter)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
} else {
  Menu {
    Button("Photos", systemImage: "photo.on.rectangle.angled") { onSelectPhotos() }
    Button("Files", systemImage: "doc.badge.plus") { onSelectFiles() }

    // O(1) metadata check without decoding Data blobs on @MainActor (F-09)
    if PlatformPasteboard.hasAttachments {
      Button("Paste from Clipboard", systemImage: "doc.on.clipboard") {
        onPasteFromClipboard()
      }
    }
  } label: {
    iconLabel
      .opacity(isMenuHitTargetOverlay ? 0.0 : 1.0)
  }
  .frame(width: effectiveDiameter, height: effectiveDiameter)
  .menuStyle(.button)
  .buttonStyle(.plain)
}
```

### 4. Canonical SwiftUI Performance & Ergonomics Refinements (`F-02`, `F-03`, `F-04`)

```swift
// ✅ F-02: Snapshot-backed Equatable conformance on EnvironmentBindingBox (ConversationEnvironment.swift)
@MainActor
public struct EnvironmentBindingBox<Value: Sendable>: Sendable {
  public let snapshot: Value
  private let getter: @MainActor @Sendable () -> Value
  private let setter: @MainActor @Sendable (Value) -> Void

  public init(_ binding: Binding<Value>) {
    self.snapshot = binding.wrappedValue
    self.getter = { @MainActor in binding.wrappedValue }
    self.setter = { @MainActor newValue in binding.wrappedValue = newValue }
  }
}

extension EnvironmentBindingBox: Equatable where Value: Equatable {
  public nonisolated static func == (
    lhs: EnvironmentBindingBox<Value>,
    rhs: EnvironmentBindingBox<Value>
  ) -> Bool {
    guard lhs.snapshot == rhs.snapshot else { return false }
    return MainActor.assumeIsolated {
      lhs.wrappedValue == rhs.wrappedValue
    }
  }
}

// ✅ F-03: Lazy @MainActor subview builders in MessageComposerStyleConfiguration (MessageComposerStyle.swift)
@MainActor
public struct MessageComposerStyleConfiguration {
  private let attachmentButtonBuilder: (() -> AnyView)?
  private let borderlessAttachmentButtonBuilder: (() -> AnyView)?
  private let modelSelectorBuilder: (() -> AnyView)?
  private let compactModelSelectorBuilder: (() -> AnyView)?

  public var attachmentButton: AnyView? { attachmentButtonBuilder?() }
  public var borderlessAttachmentButton: AnyView? { borderlessAttachmentButtonBuilder?() }
  public var modelSelector: AnyView? { modelSelectorBuilder?() }
  public var compactModelSelector: AnyView? { compactModelSelectorBuilder?() }
}

// ✅ F-04: Native TextField prompt when tokens.isEmpty + conditional \u{200B} overlay fallback (MessageComposerView.swift)
@ViewBuilder
private var promptTextField: some View {
  let hasTokens = !tokensBinding.wrappedValue.isEmpty
  let isVisuallyEmpty = ComposerTextBuffer.cleanText(text).isEmpty

  TextField(
    "",
    text: textFieldRawBinding,
    prompt: hasTokens ? Text("") : Text(placeholder).foregroundStyle(.secondary),
    axis: .vertical
  )
  .lineLimit(1...8)
  .textFieldStyle(.plain)
  .overlay(alignment: .leading) {
    if hasTokens && isVisuallyEmpty {
      Text(placeholder)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }
}
```

---

## Key Takeaways (`## Takeaways for the Team`)

- **Let `.glassEffect(.regular.interactive())` Drive Breathing Physics—Never Mutate Focus Spacing:** Mutating `HStack(spacing: isFocused ? 3 : 8)` welds adjacent glass shapes into a permanent dog-bone while the user types. Keep `GlassEffectContainer(spacing: 12)` and `HStack(alignment: .bottom, spacing: 8)` static so the native C++/Metal `.interactive()` shader inflates the platter on `touch down` (kissing the `44×44pt` siblings) and deflates it back to `8pt` separation on `touch up`.
- **Isolate Inner `Menu` Controls via `ComposerMenuSlotAnchorKey: PreferenceKey` + `.overlayPreferenceValue`:** Declaring each accessory row (`innerTrailingAccessories`, `bottomToolbarRow`, `trailingControls`) **only once** inside `panelContent` with `.environment(\.isComposerMenuVisualOnly, true)` and `.anchorPreference(key: ComposerMenuSlotAnchorKey.self, value: .bounds)` keeps the visible label inside the `.interactive()` glass shader while `.overlayPreferenceValue` resolves `proxy[anchor]` outside `.glassEffect` to position the zero-opacity interactive `Menu` hit-target—requiring zero duplicate `HStack`s and zero `Color.clear` dummy spacers.
- **Check `PlatformPasteboard.hasAttachments` Inside `Menu` Builders:** Never call `PlatformPasteboard.readAttachments()` inside a SwiftUI `Menu` builder just to check `.isEmpty`. Use `PlatformPasteboard.hasAttachments` to inspect pasteboard type metadata in $O(1)$ with zero `Data` or image allocations on `@MainActor`.
- **Use the 3-Zone Bookend Sibling Grammar (`Sofia` Pattern):** Structure `.classicGlass` as `[ 44×44 + Sibling ] | 8pt | [ 44pt Interactive Vessel + Anchor-Isolated Menu Hit Target ] | 8pt | [ 44×44 Tinted Send/Stop Sibling ]`. This keeps secondary utilities (`32×32pt` borderless icons) inside the text vessel while giving the attachment trigger and primary submit/stop action balanced `44×44pt` bookend weight.
- **Construct Circular Glass with Explicit Square Frames (`Sofia` Part 9):** Avoid `.buttonStyle(.glass)` + `.buttonBorderShape(.circle)`, which stretches buttons into horizontal ovals. Always pair `.buttonStyle(.plain)` + `.frame(width: d, height: d)` + `.glassEffect(..., in: .circle)` for true 1:1 circular geometry.
- **Use `.glassEffectTransition(.materialize)` for Unpaired Conditional Glass Siblings & Keep `emptyStateContainer` `minHeight` Static:** Applying `.glassEffectID("classic.submit", in: glassNamespace)` + `.glassEffectTransition(.matchedGeometry)` to a conditionally inserted sibling (`if showsSubmitButton`) with no prior source view sharing that ID causes the Liquid Glass SDF shader to synthesize a slow, viscous metaball extrusion from the neighboring `classic.textPill` while the pill simultaneously compresses by `52pt`. Use `.glassEffectTransition(.materialize)` with `.transition(.scale(scale: 0.85).combined(with: .opacity))` and `.snappy(duration: 0.18)` so the detached Send button materializes crisply in place. Similarly, never bind `emptyStateContainer`'s `minHeight` (with `.center` alignment) to dynamic `ScrollGeometry.containerSize.height` (`currentVisibleHeight`), as keyboard and `.safeAreaBar(edge: .bottom)` accessory transitions (`SuggestionChipsBar`) mutate `containerSize.height` and make the placeholder jump vertically while fading.
- **Keep `.safeAreaBar(edge: .bottom)` Free of Opaque Gradients:** Never add a `LinearGradient` background to `.safeAreaBar(edge: .bottom)`. Pair `.scrollEdgeEffectStyle(.soft, for: .bottom)` on the timeline `ScrollView` with transparent safe-area chrome so content refracts directly through the floating Liquid Glass siblings.
- **Conform `@Entry` Binding Boxes to `Equatable`, Use Lazy Style Configuration Builders, and Prefer Native `TextField(..., prompt:)` (`F-02`, `F-03`, `F-04`, `F-08`):** Capture `snapshot: Value` on `EnvironmentBindingBox` so `@Entry` environment diffing skips composer invalidation during 60Hz token streaming (`F-02`); back `MessageComposerStyleConfiguration` subview slots with lazy `@MainActor` closures so unused style variants (`borderlessAttachmentButton` vs. `attachmentButton`, `compactModelSelector` vs. `modelSelector`) are never built on keystrokes (`F-03`); pass `prompt: hasTokens ? Text("") : Text(placeholder).foregroundStyle(.secondary)` to `TextField` so native baseline metrics and VoiceOver traits apply whenever `tokens.isEmpty` (`F-04`); and maintain unary `VStack` roots and direct/lazy `ForEach` collections (`F-08`).
