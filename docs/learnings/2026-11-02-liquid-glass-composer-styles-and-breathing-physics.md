# 💡 Learnings: Canonical Liquid Glass Composer Architecture, Native `.interactive()` Touch-Down Breathing, and `.overlay` Menu Isolation in ConversationKit v2

**Author**: Learnings Agent & ConversationKit v2 Engineering Team  
**Date**: 2026-11-02  
**Tags**: `SwiftUI`, `LiquidGlass`, `MicroInteractions`, `ShaderMetaballs`, `SofiaPattern`, `Menus`, `iOS26`, `macOS26`  

---

## Summary

During the Jony Ive & Craig Federighi architectural review and `Sofia` reference analysis of `ConversationKit` v2 for iOS 26+ and macOS 26+, we replaced fragile layout-driven spacing mutations and `.popover` workarounds with the canonical Apple Liquid Glass composer architecture. We discovered that mutating `HStack(spacing: isFocused ? 3 : 8)` created a permanent "dog-bone" metaball weld for the entire duration of typing, whereas combining static `GlassEffectContainer(spacing: 12)` and `HStack(alignment: .bottom, spacing: 8)` with `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))` delegates transient touch-down inflation directly to SwiftUI's native C++/Metal shader—producing an effortless fluid "kiss" against the `44×44pt` bookend siblings on finger press and separating cleanly on release. Furthermore, we identified why SwiftUI `Menu` previously vanished the composer pill—`UIContextMenuInteraction` captured the entire outer `.interactive()` glass vessel as its targeted preview—and resolved it cleanly by reserving trailing inset width inside `panelContent` while mounting `innerTrailingAccessories` via `.overlay(alignment: .bottomTrailing)` on top of the glass platter, alongside adopting the 3-zone bookend sibling grammar (`Sofia` pattern), true 1:1 circular glass (`Sofia` Part 9), and pure `.safeAreaBar(edge: .bottom)` refraction without opaque `LinearGradient` backdrops.

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

### 2. Why `UIContextMenuInteraction` Lifted the Glass Platter & How `.overlay(alignment: .bottomTrailing)` Solves It
The true root cause of the disappearing pill bug lies in how UIKit's `UIContextMenuInteraction` resolves its `UITargetedPreview` when nested inside an interactive Liquid Glass modifier:
1. When a SwiftUI `Menu` is a child *inside* the view subtree captured by `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))`, the interactive glass container synthesizes a unified compositing group / responder surface for touch-down shader inflation.
2. When the user taps the inner `Menu`, `UIContextMenuInteraction` walks up the responder/compositing tree and captures the **entire outer `.interactive()` glass platter** as the context menu's lift preview—detaching the whole composer pill from its resting coordinate space.
3. **The Architectural Fix:** Separate the **interactive glass vessel** from the **inner trailing `Menu` hit-target tree**:
   - First, compute `innerTrailingReservedWidth` inside `mainInputRow` (`CGFloat(count) * 32 + CGFloat(max(0, count - 1)) * 4 + 10`) so the `TextField` never types underneath the trailing controls.
   - Second, apply `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))` directly to `panelContent` (which contains only the attachments tray, tokens bar, and inset `TextField`).
   - Third, mount `innerTrailingAccessories` (`ComposerModelSelectorMenu`, `dictationButton`, and `dismissKeyboardButton`) via **`.overlay(alignment: .bottomTrailing)`** *outside* and on top of the `.glassEffect` modifier.

Because the `Menu` now lives in a sibling overlay layer above the `.glassEffect(.regular.interactive())` node, `UIContextMenuInteraction` scopes its targeted preview strictly to the `32×32pt` `ComposerModelSelectorMenu` button, while touches on the `TextField` still trigger full C++/Metal `.interactive()` touch-down inflation on the underlying glass pill.

### 3. The 3-Zone Bookend Sibling Grammar (`Sofia` Pattern) & True 1:1 Circular Glass (`Sofia` Part 9)
Following the `Sofia` reference architecture, `ClassicGlassMessageComposerStyle` partitions the composer into a balanced **3-Zone Bookend Sibling Grammar**:

```
[ 44×44 + Sibling ]  | 8pt |  [ 44pt Interactive Vessel + Borderless Inner Overlay ]  | 8pt |  [ 44×44 Tinted Send/Stop Sibling ]
```

- **Zone 1 — Outside Left (`44×44pt` Liquid Glass Circle Sibling):** The leading `+` attachment `Menu` button, framed to `44×44pt` with `.glassEffect(.regular.interactive(), in: .circle)`.
- **Zone 2 — Center Interactive Text Vessel (`minHeight: 44pt`, `cornerRadius: 22`):** Houses the growing `TextField` (inset by `14pt` leading, `10pt` vertical, and `innerTrailingReservedWidth` trailing) with borderless `32×32pt` inner trailing accessories (`compactModelSelector`, `dictationButton`, `dismissKeyboardButton`) mounted via `.overlay(alignment: .bottomTrailing)`.
- **Zone 3 — Outside Right (`44×44pt` Prominent Tinted Liquid Glass Circle Sibling):** When `canSubmit || isGenerating` is `true`, the trailing `Send`/`Stop` button appears as a detached `44×44pt` sibling with `.glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)` and `.glassEffectTransition(.matchedGeometry)`.
- **True 1:1 Circular Geometry (`Sofia` Part 9):** Across `ClassicGlassComposerBody` (`44×44pt`) and `ScrollToBottomButton` (`40×40pt`), replacing `.buttonStyle(.glass)` + `.buttonBorderShape(.circle)` with `.buttonStyle(.plain)` + explicit `.frame(width: d, height: d)` + `.glassEffect(..., in: .circle)` guarantees mathematically exact 1:1 circular geometry.
- **Pure `.safeAreaBar(edge: .bottom)` Refraction:** Removing the legacy opaque `LinearGradient` from `ConversationView`'s `.safeAreaBar(edge: .bottom)` allows timeline bubbles passing under `.scrollEdgeEffectStyle(.soft, for: .bottom)` to refract naturally through all three Liquid Glass zones.

| Style | Layout Grammar | Leading Control | Inner Vessel Accessories | Trailing Primary Action |
| :--- | :--- | :--- | :--- | :--- |
| **`Classic Glass`** (`.classicGlass`) | 3-Zone Bookend Siblings (`GlassEffectContainer(spacing: 12)`, `HStack(spacing: 8)`) | Outside Left `44×44pt` `.glassEffect(.regular.interactive(), in: .circle)` | `.overlay(alignment: .bottomTrailing)` `32×32pt` borderless (`compactModelSelector`, `dictation`, `dismissKeyboard`) | Outside Right `44×44pt` `.glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)` |
| **`Card Glass`** (`.cardGlass`) | 2-Row Assistant Card (`cornerRadius: 24`) | Bottom row `32×32pt` bordered circle | Bottom row full `modelSelector` pill + trailing `dictation` & `dismissKeyboard` | Bottom row `32×32pt` accent circle |
| **`Compact Glass`** (`.compactGlass`) | Single-Row Capsule (`cornerRadius: 22`) | Inside leading `32×32pt` borderless `+` | Inside `32×32pt` `compactModelSelector`, `dictation`, `dismissKeyboard` | Inside trailing `32×32pt` accent circle |

---

## The Idiomatic Solution (`## Solution & Architecture Pattern`)

1. **Delegate Breathing Physics to `.interactive()` Inside Static `GlassEffectContainer(spacing: 12)`:** Keep `HStack(alignment: .bottom, spacing: 8)` static. Let the C++/Metal `.interactive()` shader expand the glass platter on `touch down` to bridge the gap and deflate on `touch up`.
2. **Isolate Inner `Menu` Controls in `.overlay(alignment: .bottomTrailing)`:** Apply `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))` to `panelContent` first, reserve trailing width in the `TextField` row, and overlay `innerTrailingAccessories` on top so native SwiftUI `Menu` never hijacks the glass platter's layer preview.
3. **Enforce 1:1 Circular Glass via Explicit Square Frames + `in: .circle`:** Use `.buttonStyle(.plain)` + `.frame(width: diameter, height: diameter)` + `.glassEffect(..., in: .circle)` rather than `.buttonStyle(.glass)`.
4. **Keep `.safeAreaBar(edge: .bottom)` Transparent:** Never place an opaque or gradient background behind `.safeAreaBar`; combine `.scrollEdgeEffectStyle(.soft, for: .bottom)` on the `ScrollView` with native Liquid Glass vessels in the bar.

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
  .animation(reduceMotion ? nil : .snappy(duration: 0.24), value: showsSubmitButton)
}
```

### 2. True 1:1 Circular Glass Siblings (`Sofia` Part 9)

```swift
// ❌ BEFORE: .buttonStyle(.glass) + .buttonBorderShape(.circle) applied horizontal padding heuristics, creating ovals
button
  .buttonStyle(.glass)
  .buttonBorderShape(.circle)

// ✅ AFTER: Explicit 44×44pt square frame + .glassEffect(..., in: .circle) guarantees a 1:1 circle
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
    .glassEffectID("classic.submit", in: glassNamespace)
    .glassEffectTransition(.matchedGeometry)
}
```

### 3. `.overlay(alignment: .bottomTrailing)` Isolation for Native SwiftUI `Menu` (`MessageComposerStyle.swift` & `ComposerAccessories.swift`)

```swift
// ❌ BEFORE: Placing Menu inside the subtree captured by .glassEffect(.regular.interactive())
// caused UIContextMenuInteraction to lift the entire composer pill as the context menu preview.
HStack(alignment: .bottom, spacing: 0) {
  configuration.textField
  innerTrailingAccessories // Contains ComposerModelSelectorMenu (SwiftUI Menu)
}
.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))

// ✅ AFTER: Reserve trailing width inside panelContent, apply .glassEffect(.regular.interactive())
// to panelContent, and mount innerTrailingAccessories via .overlay(alignment: .bottomTrailing)
private var innerTrailingReservedWidth: CGFloat {
  let count = innerTrailingAccessoryCount
  guard count > 0 else { return 14 }
  return CGFloat(count) * buttonDiameter + CGFloat(max(0, count - 1)) * 4 + 10
}

private var mainInputRow: some View {
  HStack(alignment: .bottom, spacing: 0) {
    configuration.textField
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 14)
      .padding(.trailing, innerTrailingReservedWidth)
      .padding(.vertical, 10)
  }
}

// Inside classicPill:
panelContent
  .glassEffect(.regular.interactive(), in: .rect(cornerRadius: pillCornerRadius))
  .glassEffectID("classic.textPill", in: glassNamespace)
  .overlay(alignment: .bottomTrailing) {
    if hasInnerTrailingAccessories {
      innerTrailingAccessories
        .padding(.trailing, 6)
        .padding(.bottom, 6)
    }
  }
```

And inside `ComposerModelSelectorMenu` (`ComposerAccessories.swift`), native `Menu` works directly without `.popover` workarounds:

```swift
// ✅ Native SwiftUI Menu in ComposerModelSelectorMenu (ComposerAccessories.swift)
Menu {
  if !capabilities.isEmpty {
    capabilitiesMenuSection
  }
  if !models.isEmpty {
    modelsMenuSection
  }
} label: {
  if isCompact {
    menuIconOnlyLabel
  } else {
    menuPillLabel
  }
}
.menuStyle(.button)
.buttonStyle(.plain)
```

---

## Key Takeaways (`## Takeaways for the Team`)

- **Let `.glassEffect(.regular.interactive())` Drive Breathing Physics—Never Mutate Focus Spacing:** Mutating `HStack(spacing: isFocused ? 3 : 8)` welds adjacent glass shapes into a permanent dog-bone while the user types. Keep `GlassEffectContainer(spacing: 12)` and `HStack(alignment: .bottom, spacing: 8)` static so the native C++/Metal `.interactive()` shader inflates the platter on `touch down` (kissing the `44×44pt` siblings) and deflates it back to `8pt` separation on `touch up`.
- **Mount Inner `Menu` Controls in an `.overlay` Above `.glassEffect(.regular.interactive())`:** A SwiftUI `Menu` placed *inside* a view tree captured by `.glassEffect(.regular.interactive())` causes `UIContextMenuInteraction` to lift the entire glass vessel as its preview. Reserve trailing inset width on the `TextField`, apply `.glassEffect(.regular.interactive())` to `panelContent`, and attach `innerTrailingAccessories` via `.overlay(alignment: .bottomTrailing)` so native `Menu` and `.interactive()` glass coexist with zero `.popover` workarounds.
- **Use the 3-Zone Bookend Sibling Grammar (`Sofia` Pattern):** Structure `.classicGlass` as `[ 44×44 + Sibling ] | 8pt | [ 44pt Interactive Vessel + Borderless Inner Overlay ] | 8pt | [ 44×44 Tinted Send/Stop Sibling ]`. This keeps secondary utilities (`32×32pt` borderless icons) inside the text vessel while giving the attachment trigger and primary submit/stop action balanced `44×44pt` bookend weight.
- **Construct Circular Glass with Explicit Square Frames (`Sofia` Part 9):** Avoid `.buttonStyle(.glass)` + `.buttonBorderShape(.circle)`, which stretches buttons into horizontal ovals. Always pair `.buttonStyle(.plain)` + `.frame(width: d, height: d)` + `.glassEffect(..., in: .circle)` for true 1:1 circular geometry.
- **Keep `.safeAreaBar(edge: .bottom)` Free of Opaque Gradients:** Never add a `LinearGradient` background to `.safeAreaBar(edge: .bottom)`. Pair `.scrollEdgeEffectStyle(.soft, for: .bottom)` on the timeline `ScrollView` with transparent safe-area chrome so content refracts directly through the floating Liquid Glass siblings.
