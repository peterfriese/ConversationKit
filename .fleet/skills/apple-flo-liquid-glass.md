---
id: apple-flo-liquid-glass
name: SwiftUI Liquid Glass
author: Flo writes Code
platform: apple
repository: flowritescode/fwc-swiftui-skills
path: skills/swiftui-liquid-glass
default: true
description: Implement, review, and refactor SwiftUI features using the iOS 26+ Liquid Glass API.
---

# SwiftUI Liquid Glass

Use native Liquid Glass APIs on iOS 26+. Do not recreate the effect with materials, blurs, or shadows.

## Core rules

1. **Don't build custom Liquid Glass** through adding backgrounds, outlines, blurs and shadows.
2. **Buttons — style**: use `.buttonStyle(.glass)` for non-colored buttons, and `.buttonStyle(.glassProminent)` for tinted buttons. `.glassProminent` supports `.tint()`, but this can only be a color (not a gradient).
3. **Buttons — shape**: use `.buttonBorderShape()` instead of applying a shape to the button label by hand.
4. **Buttons — padding**: using this button setup adds roughly 13pt of padding inside the liquid glass shape; keep this in mind when adapting designs.
5. **Custom views**: use `.glassEffect(.regular, in: ...)` to embed custom Views inside liquid glass containers.
6. **Grouped glass**: use `GlassEffectContainer` when multiple liquid glass elements are next to each other. this View / Container adds a liquid merge effect when the elements grow / touch each other.
7. **Scrolling**: avoid using liquid glass inside ScrollView and List (anything that scrolls).
8. **Bottom bars**: when anchoring a liquid glass View to the bottom of the screen, prefer embedding it in `.safeAreaBar(.bottom)` instead of a VStack or `.overlay()`. safeAreaBar adds a subtle blur effect behind its content.
9. **Toolbar items — no glass**: on iOS 26+, navigation bar and window toolbar items get a shared Liquid Glass background by default. For items that should **not** show the glass capsule (plain icons, custom labels, status text, logos), apply `.sharedBackgroundVisibility(.hidden)` on the **`ToolbarItem`**, not on the inner view.

## Decision tree

```
Need a button?
├─ Neutral / secondary → .buttonStyle(.glass)
└─ Tinted / primary    → .buttonStyle(.glassProminent).tint(someColor)

Need a custom non-button surface (chip, badge, card)?
└─ .glassEffect(.regular, in: shape) on the view content

Multiple glass elements nearby?
└─ Wrap in GlassEffectContainer(spacing: ...) { ... }

Fixed bottom toolbar / action bar?
└─ .safeAreaBar(.bottom) { ... }  — not VStack + overlay

Toolbar item without glass background?
└─ ToolbarItem { ... }.sharedBackgroundVisibility(.hidden)

Inside ScrollView, List, or Form rows?
└─ Do not use Liquid Glass — use solid/material fallback
```
