# Article layout, metadata, and redirect directives

This reference provides syntax specifications and examples for DocC metadata blocks, responsive article grid layouts, tab navigators, and URL redirection directives.

---

## 1. Page metadata directives (`@Metadata`)

The `@Metadata` directive allows you to configure page presentation, SEO metadata, technology root behavior, and symbol merge strategies within `.md` or `.article` files.

```markdown
# Building a responsive map view

@Metadata {
    @TitleHeading("Spatial Interface Guide")
    @DisplayName("Building a Responsive Map View")
    @PageKind(article)
    @PageImage(purpose: card, source: "hero-map-card.png", alt: "A map view displaying pin annotations.")
    @PageColor(blue)
}

An in-depth guide to composing interactive map components using modern Swift 6 concurrency.
```

### Supported `@Metadata` child directives

| Directive | Supported values | Purpose |
| :--- | :--- | :--- |
| `@TitleHeading("...")` | Text string | Overrides the browser tab and search index title prefix (e.g., `"Spatial Interface Guide"`). |
| `@DisplayName("...")` | Text string | Customizes the displayed symbol name on documentation landing pages. |
| `@PageKind(...)` | `article`, `sampleCode` | Declares whether the page represents a conceptual guide or downloadable sample code. |
| `@PageImage(...)` | `purpose: card` or `icon`, `source: String` | Sets custom preview cards for topic listings and social media embeds. |
| `@PageColor(...)` | `blue`, `orange`, `purple`, `green`, `red`, `yellow`, `gray` | Sets the accent color theme applied to the article title bar and highlights. |
| `@TechnologyRoot` | None | Elevates this article to appear as a top-level framework bundle in the navigation sidebar. |
| `@DocumentationExtension(...)` | `mergeBehavior: append` or `override` | Determines whether extension markdown appends to or replaces in-source comments. |

---

## 2. URL redirection (`@Redirected`)

When renaming files, restructuring directories, or deprecating older symbols, configure client-side redirects to preserve external links without broken bookmarks:

```markdown
# ``MyFramework/SpatialEngine``

@Metadata {
    @Redirected(from: "documentation/myframework/legacyengine")
    @Redirected(from: "documentation/myframework/enginev1")
}

The modern spatial calculation engine replacing legacy v1 interfaces.
```

- When compiled with `--transform-for-static-hosting`, DocC automatically generates client-side HTML redirect stubs for all `@Redirected` paths.

---

## 3. Responsive article grid layouts (`@Row` & `@Column`)

DocC articles support multi-column responsive grid layouts using `@Row` and `@Column`:

```markdown
## Architectural tiers

@Row {
    @Column(size: 2) {
        ### Presentation layer
        
        SwiftUI views declare the visual structure reactively, observing state changes
        without holding strong references to mutable persistent contexts.
    }
    
    @Column(size: 1) {
        ### State store
        
        Observable models hold transient user interactions and validate invariants.
    }
}
```

### Column sizing rules
- DocC uses a **3-column grid system**.
- Total column sizes within a single `@Row` should sum to **3** (e.g., `size: 1` + `size: 2`, or three `size: 1` columns).
- On mobile screens, columns automatically collapse vertically into single-column cards.

---

## 4. Multi-language tab navigators (`@TabNavigator`)

When documenting multi-paradigm libraries or presenting alternative implementations (e.g., Swift vs. Objective-C, or SwiftData vs. Core Data):

```markdown
@TabNavigator {
    @Tab("SwiftData") {
        ```swift
        @Model
        final class Landmark {
            var name: String
            init(name: String) { self.name = name }
        }
        ```
    }
    
    @Tab("Core Data") {
        ```swift
        @objc(Landmark)
        public class Landmark: NSManagedObject {
            @NSManaged public var name: String?
        }
        ```
    }
}
```
