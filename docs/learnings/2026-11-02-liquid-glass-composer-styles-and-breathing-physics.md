# 💡 Learnings: Liquid Glass Composer Styles, Focus Breathing Physics, and Popover Anchoring in ConversationKit v2

**Author**: Learnings Agent & ConversationKit v2 Engineering Team  
**Date**: 2026-11-02  
**Tags**: `SwiftUI`, `LiquidGlass`, `MicroInteractions`, `ShaderMetaballs`, `Popovers`, `iOS26`, `macOS26`  

---

## Summary

During the visual and architectural refinement of `ConversationKit` v2 for iOS 26+ and macOS 26+, we resolved critical micro-interaction, shader rendering, and UIKit/SwiftUI bridging flaws across three distinct composer styles (`Card Glass`, `Classic Glass`, and `Compact Glass`). We diagnosed and eliminated the "permanent dog-bone" anti-pattern—where an inflated `GlassEffectContainer(spacing: 28)` prematurely fused separate shapes at rest—by implementing pure SwiftUI focus breathing (`HStack(spacing: isFocused ? 3 : 8)` inside `GlassEffectContainer(spacing: 8)`) to produce an authentic fluid "kiss" only when active. Additionally, we diagnosed a severe rendering bug where UIKit `Menu` presentation snapshotting inside `.glassEffectID` vanished the entire composer pill, fixed multiline corner-clipping via calibrated text insets (14pt leading, 10pt vertical), and stabilized bottom-baseline alignment across all 32×32pt auxiliary controls.

---

## The Problem / Challenge (`## The Problem or Puzzle`)

### 1. Divergent Ergonomic Needs Across Three Distinct Composer Styles
Modern conversational AI interfaces cannot rely on a single rigid input container. A canvas-oriented workflow (such as Craft Assistant or Claude Cowork) requires a spacious, structured two-row card; a traditional messaging timeline (like iMessage or Sofia) requires a lightweight floating pill with a detached action trigger; and compact contexts (iPad sheets, macOS inspectors, secondary popovers) require an ultra-condensed single-row capsule. 

Prior to this refinement, `ConversationKit` attempted to unify these paradigms into a single monolithic view hierarchy, creating three major layout failures:
- In the two-row card, the leading attachment button (`+`) and trailing send/stop buttons suffered from mismatched optical weights and uneven touch targets.
- In the classic pill, the detached `+` button was either rigidly isolated or unpredictably fused to the text input.
- In the compact capsule, controls floated awkwardly in vertical space as the prompt grew from one line to multiple lines.

### 2. The "Permanent Dog-Bone" Anti-Pattern
To achieve Apple's signature Liquid Glass "melting" effect—where adjacent interactive glass surfaces fluidly bridge together when tapped—initial prototypes increased `GlassEffectContainer(spacing:)` to `28pt` while maintaining an internal `HStack(spacing: 6)`. 

Instead of an organic interaction, this created an immediate visual regression: the signed distance field (SDF) metaball shader merged the detached circular `+` button and the rounded text pill permanently at rest. Rather than two crisp, elegant floating shapes, the composer rendered as an unsightly, deformed "peanut" or "dog-bone" before the user even touched the screen.

### 3. The Disappearing Pill Bug (`UIContextMenuInteraction` vs. Popover)
To house model selection (`GPT-4o`, `Claude 3.7 Sonnet`, `DeepSeek R1`) and agent capabilities (`Thinking`, `Web Search`, `Code Interpreter`), the model selector initially used SwiftUI's standard `Menu { ... } label: { ... }`. 

However, when embedded inside a view hierarchy participating in Liquid Glass container morphing (`.glassEffectID`), tapping the `Menu` caused a catastrophic rendering glitch: **the entire composer pill instantly vanished from the screen**. The user was left staring at a disconnected floating context menu above an empty void.

### 4. Multiline Text Inset Cramping & Floating Center-Aligned Buttons
When text input expands from a single line (~22pt font height) to a 3-line or 5-line prompt:
- Standard padding (`8pt` horizontal) causes glyphs in the top and bottom lines to collide with the 22pt curved corner boundaries of the pill (the "corner clip" trap).
- Default `HStack(alignment: .center)` alignment causes auxiliary buttons (model picker, dictation, keyboard dismiss, send) to drift into the vertical dead-center of the composer box. Instead of remaining anchored where the user's thumb expects them near the keyboard edge, buttons floated mid-air alongside multiline paragraphs.

---

## Root Cause & Discovery (`## The Discovery`)

### 1. The Geometry of the Three Styles: Card, Classic, and Compact
We established strict structural boundaries for each style in `MessageComposerStyle.swift`:

| Style | Layout Structure | Leading Element | Model Selector Location | Resting Height | Target Surface |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`Card Glass`** | 2-row card (`cornerRadius: 24`) | Bordered `32×32pt` circular `+` | Bottom toolbar row (full pill) | ~84pt | Main canvas, Desktop chat, iPad primary |
| **`Classic Glass`** | Single-row pill (`cornerRadius: 22`) | Detached `44×44pt` glass circle | Inside pill (`32×32pt` compact icon) | 44pt | iPhone timelines, iMessage-style chat |
| **`Compact Glass`** | Single-row capsule (`cornerRadius: 22`) | Borderless `32×32pt` `+` inside | Inside capsule (`32×32pt` compact icon) | 44pt | Slide-over sheets, inspectors, popovers |

In `Card Glass`, optical parity was broken because the attachment button lacked a defined visual frame to balance the prominent primary submit circle. Giving the attachment button an explicit `32×32pt` circle frame with subtle platform tinting (`Color.primary.opacity(0.06)`) and stroke border restored exact optical equilibrium with the trailing `32×32pt` send button.

### 2. Shader Metaball Thresholds & Pure SwiftUI Focus Breathing
The Apple Liquid Glass runtime implements fluid shape blending using a GPU-evaluated Signed Distance Field (SDF). `GlassEffectContainer(spacing:)` defines the interaction radius $R_{\text{merge}}$ within which adjacent geometries influence each other's field equations.

When two shapes with bounding distance $d$ are evaluated:
$$\text{Blend Factor} = \text{clamp}\left(1.0 - \frac{d}{R_{\text{merge}}}, 0.0, 1.0\right)$$

- **Why `spacing: 28` failed:** With $R_{\text{merge}} = 28\text{pt}$ and static layout spacing $d = 6\text{pt}$, the blend factor was $\approx 0.78$ at all times. The shader engine continuously drew a thick liquid bridge across the gap, forming the permanent dog-bone.
- **The Pure SwiftUI Solution:** Liquid morphing should be driven by dynamic layout state, not an oversized static shader radius. By configuring `GlassEffectContainer(spacing: 8)`, the shader merge threshold is set to $8\text{pt}$. At rest, we set `HStack(spacing: 8)` ($d = 8\text{pt}$, blend factor $= 0.0$). The shapes remain 100% crisp and distinct.
- **Focus Breathing Spring:** When the text field gains focus (`isFocused == true`), we dynamically compress the layout spacing:
  ```swift
  HStack(alignment: .bottom, spacing: configuration.isFocused ? 3 : 8)
  ```
  At $d = 3\text{pt}$, $d < R_{\text{merge}}$. The shapes enter the merge envelope smoothly under a physical spring (`.spring(duration: 0.35, bounce: 0.15)`), producing the authentic Sofia/iMessage liquid "kiss" exactly when the keyboard rises, and snapping cleanly apart on dismiss.

### 3. Why `UIContextMenuInteraction` Destroyed the Glass Pill
On iOS, SwiftUI's `Menu` is implemented on top of UIKit's `UIContextMenuInteraction`. When tapped:
1. `UIContextMenuInteraction` captures an offscreen snapshot representation of the presenting view hierarchy (`UITargetedPreview`).
2. It detaches the presenting view's visual layer to perform the system scale-and-morph presentation into the menu container window.
3. Simultaneously, `GlassEffectContainer` and its Metal render pass track elements registered with `.glassEffectID` to compute refractive backbuffers and morph transitions.
4. When UIKit hijacked the layer for the context menu snapshot, the Liquid Glass render pipeline registered a sudden disappearance of the node from the container's spatial graph, concluding that the entire pill had morphed into the menu window. The underlying pill rendered transparent (`alpha = 0`), leaving the user with an orphaned floating menu.

Replacing `Menu` with a native SwiftUI `.popover(isPresented:arrowEdge: .bottom)` and applying `.presentationCompactAdaptation(.popover)` completely bypassed `UIContextMenuInteraction`. The popover attaches as a standard floating window with native arrow pointing, keeping the composer pill fully rendered, interactive, and rock-solid underneath.

### 4. Continuous Curvature Insets & Baseline Anchor Mechanics
A rounded rectangle with `cornerRadius: 22pt` has a horizontal corner inset curvature budget:
$$X_{\text{safe}} = r \cdot (1 - \cos(\theta))$$
Glyphs placed closer than $12\text{pt}$ to the leading edge clip against the rounded corner apex when the text field expands vertically. Expanding `.padding(.leading, 14)` and `.padding(.vertical, 10)` creates a protected bounding box that keeps multiline text inside the strictly rectangular region of the pill.

Simultaneously, changing the row layout from `.center` to `HStack(alignment: .bottom)` ensures that all action buttons stay aligned with the bottom line of text regardless of how high the text field grows.

---

## The Idiomatic Solution & Code Examples (`## Solution & Architecture Pattern`)

### 1. Eliminating the Dog-Bone: Focus Breathing Spring vs. Static Fusion

```swift
// ❌ BEFORE: Oversized merge radius + static spacing caused permanent dog-bone fusion at rest
GlassEffectContainer(spacing: 28) {
  HStack(alignment: .bottom, spacing: 6) {
    detachedPlusButton(plusButton)
    classicPill // Permanently fused with plusButton even when unfocused!
  }
}

// ✅ AFTER: Calibrated merge container + dynamic layout spacing on focus (MessageComposerStyle.swift)
GlassEffectContainer(spacing: 8) {
  HStack(alignment: .bottom, spacing: configuration.isFocused ? 3 : 8) {
    if let plusButton = configuration.attachmentButton {
      detachedPlusButton(plusButton)
    }

    classicPill
  }
  .animation(
    reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.15),
    value: configuration.isFocused
  )
}
```

### 2. Replacing `UIContextMenuInteraction` with Stable `.popover` Anchoring

```swift
// ❌ BEFORE: UIKit Menu snapshotting caused Liquid Glass pill to vanish on tap
Menu {
  menuContent
} label: {
  menuPillLabel
}
.menuIndicator(.hidden) // Entire composer pill disappeared when tapped!

// ✅ AFTER: Native SwiftUI Popover with compact adaptation preserves glass container (ComposerAccessories.swift)
Button {
  isShowingMenu.toggle()
} label: {
  if isCompact {
    menuIconOnlyLabel
  } else {
    menuPillLabel
  }
}
.buttonStyle(.plain)
.popover(isPresented: $isShowingMenu, arrowEdge: .bottom) {
  popoverContent
    .presentationCompactAdaptation(.popover) // Prevents full-screen sheet adaptation on iPhone
}
.accessibilityIdentifier(ConversationAccessibilityID.composerModelSelector)
```

### 3. Card Glass Optical Parity and Breathing Scale

```swift
// ✅ CardGlassComposerBody: 32×32pt optical parity between leading '+' and trailing actions
HStack(alignment: .center, spacing: 8) {
  if let attachmentButton = configuration.borderlessAttachmentButton ?? configuration.attachmentButton {
    attachmentButton
      .frame(width: controlDiameter, height: controlDiameter) // 32×32pt
      .background(Color.primary.opacity(0.06), in: Circle())
      .overlay {
        Circle()
          .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
      }
  }

  if let modelSelector = configuration.modelSelector {
    modelSelector
      .frame(height: controlDiameter) // 32pt height
      .layoutPriority(1)
  }

  Spacer(minLength: 8)

  HStack(alignment: .center, spacing: 8) {
    if showsSubmitButton {
      configuration.submitButton
        .frame(width: controlDiameter, height: controlDiameter) // 32×32pt
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
  }
}
// Subtle tactile card lift on focus
.scaleEffect(configuration.isFocused ? 1.01 : 1.0)
.animation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.15), value: configuration.isFocused)
```

### 4. Multiline Corner Insets & Bottom-Baseline Anchor

```swift
// ❌ BEFORE: Centered buttons floated in mid-air on multiline text; text cramped in corners
HStack(alignment: .center, spacing: 6) {
  configuration.textField
    .padding(.horizontal, 8)
    .padding(.vertical, 4) // Clips against 22pt corner radius on lines 2+!

  actionButtonsGroup // Floated in the vertical center of 3-line prompt!
}

// ✅ AFTER: Bottom-aligned HStack + generous corner-safe insets (Classic & Compact Glass)
HStack(alignment: .bottom, spacing: 0) {
  configuration.textField
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.leading, 14) // Safely clear of 22pt curved corner
    .padding(.trailing, hasTrailingButtons ? 4 : 14)
    .padding(.vertical, 10)

  if hasTrailingButtons {
    trailingButtonsGroup
      .padding(.trailing, 6)
      .padding(.bottom, 6) // Anchored securely along bottom baseline
  }
}
```

---

## Key Takeaways (`## Takeaways for the Team`)

- **Never Inflate `GlassEffectContainer(spacing:)` to Force Merging:** `GlassEffectContainer` sets the shader's spatial metaball threshold. Setting spacing larger than your resting element gap causes permanent, deformed liquid fusion at rest ("the dog-bone"). Set container spacing tightly (`8pt`) and animate the layout spacing (`8pt -> 3pt`) on focus.
- **Avoid UIKit `Menu` Inside `.glassEffectID` Hierarchies:** UIKit's `UIContextMenuInteraction` takes snapshot previews and detaches view layers, conflicting with Liquid Glass container shader state and making parent glass shapes vanish. Use `.popover(isPresented:arrowEdge: .bottom)` with `.presentationCompactAdaptation(.popover)` for stable, in-place popover menus.
- **Maintain Strict Optical Parity Across Controls:** In card-style composers, leading attachment triggers and trailing submit actions must share identical frame budgets (`32×32pt`). Balance naked icon buttons with a subtle background (`Color.primary.opacity(0.06)`) and hair-thin stroke border (`0.5pt`) to achieve visual equilibrium against filled action buttons.
- **Anchor Multiline Action Bars to `.bottom`, Never `.center`:** As text grows vertically, action buttons must remain grounded near the keyboard edge where the user's thumb expects them. Always wrap multiline composer rows in `HStack(alignment: .bottom)` with consistent bottom insets.
- **Respect Continuous Corner Curvature on Text Insets:** A rounded capsule (`cornerRadius: 22pt`) requires at least `14pt` leading and `10pt` vertical padding to ensure multiline text never enters the corner clip zone.
