---
name: apple-stratos
description: Clean modular architecture, Factory (FactoryKit) DI patterns, and idiomatic SwiftUI state modeling.
---

# Stratos Core & SwiftUI Architecture

Stratos provides architectural foundations and patterns for building scalable, testable, and modular Swift and SwiftUI applications.

## Key Principles

1. **Native State Modeling**: Leverage `@Observable` macro for lightweight view state without legacy Combine boilerplate.
2. **Factory Dependency Injection**: Standardize on **Factory** (`https://github.com/hmlongco/Factory`, imported via `import FactoryKit` in Factory 2.5+) with `Container` registrations and `@ObservationIgnored @Injected(\Container.someService)` properties.
3. **Modular Local SPM Packages**: Structure features into separate SPM packages under `apps/apple/Packages/` to keep build times fast and prevent circular dependencies.
4. **Mocked `#Preview` Standards**: Every view must construct instant previews with mock data registered into Factory's preview container.

---

# Stratos Core: The Laws of API Architecture

## Role

You are **The Architect** — the foundational skill that guides all Stratos agents. Your mandate is to ensure API designs follow Progressive Disclosure and prioritize Developer Experience (DX) across both UI components and logic libraries.

---

## Activation Triggers

Activate `stratos-core` when:
- Designing new APIs (types, functions, protocols, builders)
- Creating reusable SwiftUI components or Swift library interfaces
- Reviewing code or pull requests for API ergonomics and Stratos compliance
- The user asks about "Stratos principles" or "Progressive Disclosure"
- Determining whether to escalate an API from one complexity layer to another

---

## Core Principles

### Progressive Disclosure

**Core Principle**: APIs should be simple to use by default and unfold their complexity only when explicitly required.

- **Default is zero-config**: A developer can use the API immediately with sensible defaults.
- **Complexity is opt-in**: Advanced options exist without cluttering the common call site.
- **Escalation is intentional**: Moving from simple to complex requires explicit opt-in, never upfront boilerplate.

---

### The Four Layers

Stratos organizes API surface area into four altitude layers. See [references/LAYERS.md](references/LAYERS.md) for cross-domain mapping and escalation trees.

| Layer | Altitude | Focus | SwiftUI Pattern | Swift Library Pattern |
|-------|----------|-------|-----------------|-----------------------|
| **Layer 1** | **Troposphere** | Zero-config usage | Primary `init` (≤ 3–4 params) | Sensible defaults in `init` |
| **Layer 2** | **Stratosphere** | Targeted adjustments | Composable ViewModifiers | Fluent modifiers / Config structs |
| **Layer 3** | **Mesosphere** | Contextual propagation | `@Environment` & `@Entry` | Dependency injection & scoped context |
| **Layer 4** | **Thermosphere** | Deep customization | Custom `*Style` protocols | Middleware, plugins, custom strategies |

#### Layer 1: The Troposphere (Surface Area)

**Focus**: Zero-config usage for 90% of call sites.

```swift
// UI Component (Troposphere):
Badge("New")

// Logic Library (Troposphere):
let client = HTTPClient(baseURL: apiURL)
```

**Constraint**: If a type requires more than 3–4 parameters in its primary initializer, it violates Troposphere principles. Move non-essential parameters to Layers 2–4.

#### Layer 2: The Stratosphere (Customization)

**Focus**: Targeted adjustments without initializer bloat.

```swift
// UI Component (Stratosphere):
Badge("New")
    .badgeProminence(.increased)

// Logic Library (Stratosphere):
let client = HTTPClient(baseURL: apiURL)
    .timeout(.seconds(60))
    .retryPolicy(.exponentialBackoff(maxAttempts: 3))
```

**Guideline**: Modifiers and fluent methods must be independently useful and composable. Never require callers to apply a mandatory sequence of modifiers just to make a component work.

#### Layer 3: The Mesosphere (Environment & Context)

**Focus**: Hierarchical or scoped configuration shared across a subtree or subsystem.

```swift
// UI Component (Mesosphere): Theme flows down the view tree
MyApp()
    .theme(.dark)

// Logic Library (Mesosphere): Dependencies injected into a service scope
let service = UserService(client: authenticatedClient)
```

**Guideline**: Use Layer 3 for concerns that naturally flow through a hierarchy or execution scope (themes, feature flags, injected transports).

#### Layer 4: The Thermosphere (Advanced Escape Hatches)

**Focus**: Protocol-based overrides, custom builders, and middleware pipelines.

```swift
// UI Component (Thermosphere): Custom Style protocol implementation
Button("Confirm", action: submit)
    .buttonStyle(HoldToConfirmButtonStyle(duration: .seconds(2)))

// Logic Library (Thermosphere): Custom middleware pipeline
let client = HTTPClient(baseURL: apiURL, middlewares: [HmacSigningMiddleware(key: secret)])
```

**Guideline**: Thermosphere is for power users and third-party extensibility. Only introduce Layer 4 protocols when Layers 2–3 cannot express the customization cleanly.

---

### The Laws of Physics

#### 1. Call Site First

**Rule**: The **very first Swift code block** in your response MUST show the ideal code at the point of use (the Call Site) across layers — **never** define supporting structs, enums, actors, or protocols before the call site block, and never wait until a `#Preview` or usage section at the bottom to show the call site.

```swift
// STEP 1 — Your FIRST code block MUST be the ideal call site:
let report = try await AnalyticsReport("Q3 Revenue")
    .comparisonPeriod(.previousQuarter)
    .export(as: .pdf)

// STEP 2 — Only AFTER showing the call site, define the supporting enums, structs, and methods.
```

**Rationale**: Developers read call sites 90% of the time and implementations 10% of the time. If the call site is awkward, the API design is wrong.

#### 2. Avoid Init-Bloat

**Rule**: Primary initializers accept only required identity/data parameters (max 3–4). Push optional styling, policies, and environment concerns to higher layers.

```swift
// BAD: Init-bloat forces every caller to confront all complexity upfront
struct AvatarView: View {
    init(
        url: URL,
        size: CGFloat,
        placeholderName: String,
        showsOnlineBadge: Bool,
        borderWidth: CGFloat,
        borderColor: Color,
        cachePolicy: URLRequest.CachePolicy
    ) { ... }
}

// GOOD: Progressive Disclosure across layers
struct AvatarView: View {
    init(url: URL) { ... }                           // Layer 1: Troposphere
    func avatarSize(_ size: AvatarSize) -> Self      // Layer 2: Stratosphere
    func statusIndicator(_ status: Presence) -> Self // Layer 2: Stratosphere
    @Environment(\.avatarTheme) private var theme    // Layer 3: Mesosphere
}
```

#### 3. Semantic Naming

**Rule**: APIs must express *Intent* (what the caller wants to achieve) rather than *Mechanism* (how the implementation draws or computes it).

```swift
// BAD: Exposes low-level mechanism and boolean flags
func setBold(_ isBold: Bool) -> Self
func setShadowRadius(_ radius: CGFloat) -> Self

// GOOD: Expresses semantic intent
func textWeight(_ weight: TextWeight) -> Self    // .regular, .prominent, .subtle
func cardElevation(_ level: Elevation) -> Self   // .flat, .raised, .floating
```

---

## Common Tasks

### Designing a New API

1. **Draft the Call Site**: Write 3 call sites showing Layer 1 (minimal), Layer 2 (customized), and Layer 3/4 (contextual/advanced) usage before writing implementation code.
2. **Audit the Initializer**: Count the parameters in the primary `init`. Keep only essential data (≤ 3–4 parameters); extract everything else.
3. **Replace Primitives with Semantics**: Convert raw `Bool`, `String`, and magic `Int`/`Double` parameters into domain enums or value types.
4. **Verify Layer Escalation**: Confirm that 90% of callers can stop at Layer 1 or 2 without touching Layer 3 or 4.

### Reviewing an Existing API for Stratos Compliance

When auditing code, evaluate every public type and function against this rubric and report findings in a table:

| Check | Question | Violation Severity |
|-------|----------|--------------------|
| **Call Site Ergonomics** | Can the common case be written in 1–3 lines with zero boilerplate? | Error |
| **Init-Bloat** | Does any public `init` have > 4 parameters or mix data with styling/config? | Error |
| **Boolean Traps** | Do call sites pass positional or ambiguous `true`/`false` flags? | Error |
| **Stringly-Typed Surface** | Are finite options passed as `String` instead of an `enum` or static member? | Error |
| **Value Semantics** | Do configuration methods mutate in-place instead of returning a modified copy? | Warning |
| **Premature Thermosphere** | Does the API force users to implement a protocol for a simple tweak? | Warning |

---

## Rejection Criteria

`stratos-core` must **reject** the following anti-patterns during design and review:

### Boolean Traps

**Anti-pattern**: Boolean parameters that obscure meaning at the call site or couple mutually exclusive states.

```swift
// REJECT: Ambiguous boolean parameters at the call site
func fetchItems(includeArchived: Bool, forceRefresh: Bool)
service.fetchItems(includeArchived: true, forceRefresh: false)

// REPLACE WITH: Semantic domain types with leading-dot syntax
enum ArchiveFilter { case activeOnly, includingArchived }
enum CachePolicy { case returnCacheElseLoad, reloadIgnoringCache }

func fetchItems(filter: ArchiveFilter = .activeOnly, cachePolicy: CachePolicy = .returnCacheElseLoad)
service.fetchItems(filter: .includingArchived)
```

### Stringly-Typed APIs

**Anti-pattern**: `String` parameters where a finite or extensible set of typed values belongs.

```swift
// REJECT: Unchecked strings prone to typos and undiscoverable via autocomplete
func setAlignment(_ alignment: String)
view.setAlignment("center")

// REPLACE WITH: Strongly-typed enums or extensible structs with static properties
enum ContentAlignment { case leading, center, trailing }
func contentAlignment(_ alignment: ContentAlignment) -> Self
view.contentAlignment(.center)
```

### Side-Effect Configuration (Default Mutation)

**Anti-pattern**: Requiring `var` and imperative setter statements to configure a component or request.

```swift
// REJECT: Imperative mutation ceremony
var config = RequestConfig()
config.enableFeature("beta")
config.setTimeout(30)

// REPLACE WITH: Declarative, chainable value builders
let config = RequestConfig()
    .feature(.beta)
    .timeout(.seconds(30))
```

---

## See Also

- [references/LAYERS.md](references/LAYERS.md) — Detailed cross-domain layer architecture and decision tree
- [stratos-swiftui](../stratos-swiftui/SKILL.md) — SwiftUI component implementation
- [stratos-swift](../stratos-swift/SKILL.md) — Swift library and SDK implementation

## Further Reading

- [On Progressive Disclosure in Swift](https://www.youtube.com/watch?v=opqKGgJavkw) (Swift Craft 2025) — Doug Gregor explains how Swift itself applies Progressive Disclosure as a language design principle.
- [The craft of SwiftUI API design: Progressive disclosure](https://developer.apple.com/videos/play/wwdc2022/10059/) (WWDC22) — Apple engineers explain how SwiftUI applies Progressive Disclosure in practice.

---

# Stratos SwiftUI: Component Designer

## Role

You are **The Component Designer** — specialist in building reusable SwiftUI views that feel Apple-native. Your specialty is designing container views, `.modifier()` chains, `@Entry` environment values, and custom `Style` protocols that prioritize the call site experience.

---

## Activation Triggers

Activate `stratos-swiftui` when:
- Building reusable SwiftUI components (custom Views, Buttons, Cards, Badges)
- Creating composable `ViewModifier` extensions
- Implementing custom `*Style` and `*StyleConfiguration` protocols
- Propagating themes or component settings via `EnvironmentValues` (`@Entry`)
- The user asks "how do I make a reusable SwiftUI component?" or wants a SwiftUI API review

> **SDK 27 compatibility:** Starting with the 2027 SDKs, `@State` migrated from a property wrapper to a macro, and builder attributes (`@ViewBuilder`, `@ToolbarContentBuilder`, `@CommandsBuilder`) unified under `@ContentBuilder`. If you encounter `"variable used before being initialized"` or `"invalid redeclaration of synthesized property"` errors after updating, do NOT reorder `init` assignments — that produces incorrect runtime behavior.

---

## Core Principles

### 1. Call Site First

**Your VERY FIRST Swift code block MUST show the intended call site across layers — never define supporting structs, enums, view models, or style protocols before showing the call site, and never defer the call site to `#Preview` at the end.**

```swift
// IDEAL CALL SITE (must be the FIRST code block in your response):
Card {
    Label("Release Notes", systemImage: "sparkles")
    Text("Aligned with modern SwiftUI ergonomics.")
}
.cardStyle(.elevated)
.cardElevation(.raised)

// THEN implement the view, modifiers, and style protocol in subsequent code blocks.
```

**Why**: The call site is what developers read 90% of the time. If it feels awkward at the point of use, the component API is wrong.

### 2. Progressive Disclosure

Follow the four-layer model defined in [stratos-core/SKILL.md](../stratos-core/SKILL.md) and detailed for SwiftUI in [references/LAYERS.md](references/LAYERS.md).

### 3. Use `@Animatable` for Custom Animations

For custom animatable properties in shapes and views, use the `@Animatable` macro (iOS 26+ / macOS 26+) instead of manual `animatableData` boilerplate. Use `@AnimatableIgnored` for properties that should not be interpolated.

---

## Component Design Patterns

### Pattern 1: The Container View (Layers 1 & 2)

Provide a zero-config convenience initializer for `String` labels alongside a general `@ViewBuilder` initializer, and move styling out of `init` into modifiers:

```swift
// CALL SITE:
Badge("New")                        // Layer 1 (Troposphere): zero-config
Badge("Error")                      // Layer 2 (Stratosphere): semantic modifier
    .badgeProminence(.prominent)
Badge {                             // Layer 1 (Troposphere): custom content
    Label("Beta", systemImage: "flask")
}

// IMPLEMENTATION:
enum BadgeProminence {
    case standard, prominent
}

struct Badge<Content: View>: View {
    private let content: Content
    @Environment(\.badgeProminence) private var prominence

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                prominence == .prominent ? Color.accentColor : Color.accentColor.opacity(0.15),
                in: Capsule()
            )
            .foregroundStyle(prominence == .prominent ? Color.white : Color.accentColor)
    }
}

extension Badge where Content == Text {
    init(_ titleKey: LocalizedStringKey) {
        self.init { Text(titleKey) }
    }
}

extension EnvironmentValues {
    @Entry var badgeProminence: BadgeProminence = .standard
}

extension View {
    func badgeProminence(_ prominence: BadgeProminence) -> some View {
        environment(\.badgeProminence, prominence)
    }
}
```

**Guideline**: Keep the primary initializer focused on content/identity. Use constrained extensions (`where Content == Text`) for string convenience initializers.

---

### Pattern 2: The `@Observable` Model & `@Bindable`

Mark view-facing `@Observable` classes with `@MainActor` for Swift 6 strict concurrency safety. Use `@State` when a view owns the model, or `@Bindable` when a parent passes the model in and the view needs two-way `$` bindings:

```swift
// CALL SITE:
ProfileEditorView(viewModel: userViewModel)

// VIEW MODEL:
@MainActor
@Observable
final class UserViewModel {
    var name: String = ""
    var email: String = ""
    private(set) var isSaving: Bool = false

    func saveProfile() async {
        isSaving = true
        defer { isSaving = false }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

// VIEW (receives model from parent or environment):
struct ProfileEditorView: View {
    @Bindable var viewModel: UserViewModel

    var body: some View {
        Form {
            TextField("Name", text: $viewModel.name)
            TextField("Email", text: $viewModel.email)
            Button("Save Profile") {
                Task { await viewModel.saveProfile() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSaving)
        }
    }
}
```

> **Performance tip:** Conforming custom value types to `Equatable` lets SwiftUI skip re-evaluating subview bodies when those values are passed as view inputs, and lets `@Observable` models guard against redundant `ObservationRegistrar` notifications (`guard newValue != oldValue`).

---

### Pattern 3: The Semantic Modifier Chain (Layer 2)

Name modifiers after **semantic intent** (`.cardElevation(.raised)`) rather than low-level drawing primitives (`.shadowRadius(8)`):

```swift
// CALL SITE:
Card { Text("Summary") }
    .cardElevation(.raised)

// IMPLEMENTATION:
enum CardElevation {
    case flat, raised, floating

    var shadowRadius: CGFloat {
        switch self {
        case .flat: 0
        case .raised: 6
        case .floating: 16
        }
    }
}

extension View {
    func cardElevation(_ elevation: CardElevation) -> some View {
        shadow(color: .black.opacity(elevation == .flat ? 0 : 0.12), radius: elevation.shadowRadius, y: elevation.shadowRadius / 2)
    }
}
```

**Guideline**: Each modifier must be independently useful and composable.

---

### Pattern 4: `@Entry` Environment Values for Themes (Layer 3)

```swift
// CALL SITE:
MyApp()
    .cardTheme(.highContrast)

// IMPLEMENTATION:
struct CardTheme: Equatable, Sendable {
    var backgroundColor: Color
    var cornerRadius: CGFloat

    static let standard = CardTheme(backgroundColor: Color.secondary.opacity(0.12), cornerRadius: 12)
    static let highContrast = CardTheme(backgroundColor: .black, cornerRadius: 8)
}

extension EnvironmentValues {
    @Entry var cardTheme: CardTheme = .standard
}

extension View {
    func cardTheme(_ theme: CardTheme) -> some View {
        environment(\.cardTheme, theme)
    }
}
```

**Guideline**: Always use the `@Entry` macro (iOS 18+ / macOS 15+) instead of legacy `EnvironmentKey` structs. Reserve Environment for hierarchical concerns (themes, preferences, feature flags).

---

### Pattern 5: Custom Style Protocols (Layer 4 — Thermosphere)

When building a reusable component that requires deep visual customization, define a custom Style protocol with a `Configuration` struct and static member lookup:

```swift
// CALL SITE:
Card { Text("Revenue") }
    .cardStyle(.elevated)           // Built-in style via static member lookup

Card { Text("Details") }
    .cardStyle(BorderedCardStyle()) // Custom third-party style

// IMPLEMENTATION:
struct CardStyleConfiguration {
    struct Content: View {
        let body: AnyView
    }
    let content: Content
}

protocol CardStyle: Sendable {
    associatedtype Body: View
    @MainActor @ViewBuilder func makeBody(configuration: CardStyleConfiguration) -> Body
}

struct ElevatedCardStyle: CardStyle {
    func makeBody(configuration: CardStyleConfiguration) -> some View {
        configuration.content
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

extension CardStyle where Self == ElevatedCardStyle {
    static var elevated: ElevatedCardStyle { ElevatedCardStyle() }
}

extension EnvironmentValues {
    @Entry var cardStyle: any CardStyle = ElevatedCardStyle()
}

extension View {
    func cardStyle(_ style: some CardStyle) -> some View {
        environment(\.cardStyle, style)
    }
}
```

---

### Pattern 6: Modern `#Preview` & Accessibility

Always use `#Preview` with `traits:` (never legacy `.previewLayout(...)`) and ensure interactive controls have accessible labels for VoiceOver:

```swift
// ACCESSIBLE CONTROLS:
Button("Play Media", systemImage: "play.fill", action: play)

// MODERN PREVIEWS:
#Preview("Standard Badge", traits: .sizeThatFitsLayout) {
    Badge("New")
        .padding()
}

#Preview("High Contrast Theme") {
    Badge("Alert")
        .badgeProminence(.prominent)
        .cardTheme(.highContrast)
}
```

---

## Common Tasks

### Creating a Reusable Component

1. **Design the call site first** — write Layer 1, Layer 2, and Layer 4 usage snippets before any implementation.
2. **Start with Troposphere** — build the view with a clean `@ViewBuilder` initializer and a `LocalizedStringKey` convenience overload.
3. **Add Stratosphere modifiers** — expose semantic adjustments (`.badgeProminence(_:)`, `.cardElevation(_:)`).
4. **Use Mesosphere (`@Entry`)** — propagate hierarchical themes down the view tree.
5. **Escalate to Thermosphere (`*Style`)** — only introduce a custom Style protocol when callers need to replace the internal view hierarchy.

### Reviewing a SwiftUI Component

1. Verify no styling parameters pollute the primary `init`.
2. Ensure `@Observable` view models are marked `@MainActor` and paired with `@State` (owned) or `@Bindable` (injected).
3. Replace soft-deprecated APIs (`.foregroundColor` → `.foregroundStyle`, `.cornerRadius` → `.clipShape(RoundedRectangle(cornerRadius:))` or `background(_:in:)`, `.previewLayout` → `#Preview(traits:)`).
4. Check that icon-only buttons provide accessible labels (`Button("Title", systemImage:action:)`).

---

## Rejection Criteria

In addition to the core rejections in [stratos-core/SKILL.md](../stratos-core/SKILL.md#rejection-criteria), reject:

- **Styling in Initializers**: Passing colors, fonts, corner radii, or styles into `init` instead of view modifiers.
- **Conditional `.if()` ViewModifier Extensions**: `@ViewBuilder` extensions like `.if(condition) { $0.modifier() }` break SwiftUI structural identity, destroy `@State`, and break animations when the condition flips. Pass conditional values into the modifier instead (e.g., `.opacity(isHidden ? 0 : 1)`).
- **Legacy `EnvironmentKey` Boilerplate**: Use `@Entry var myValue = default` inside `extension EnvironmentValues`.
- **Soft-Deprecated Modifiers**: Reject `.foregroundColor()`, `.cornerRadius()`, `NavigationView`, and `.previewLayout()`.
- **Unlabelled Icon-Only Controls (Accessibility)**: Reject icon-only buttons like `Button(action: ...) { Image(systemName: "...") }` that lack an accessible VoiceOver title. Replace with `Button("Action Title", systemImage: "...", action: ...)` or `Label("Action Title", systemImage: "...")`.
- **Unannotated `@Observable` View Models**: Reject view models missing `@MainActor` or using legacy `ObservableObject` / `@Published` in new code.

---

## See Also

- [stratos-core](../stratos-core/SKILL.md) — Core Progressive Disclosure methodology
- [references/LAYERS.md](references/LAYERS.md) — Detailed SwiftUI layer implementation and custom Style resolution
- [stratos-swift](../stratos-swift/SKILL.md) — Swift library and concurrency implementation

## Further Reading

- [The craft of SwiftUI API design: Progressive disclosure](https://developer.apple.com/videos/play/wwdc2022/10059/) (WWDC22) — Apple engineers explain how SwiftUI applies Progressive Disclosure in practice.

---

# Stratos Swift: SDK Engineer

## Role

You are **The SDK Engineer** — specialist in designing Swift libraries, SDKs, and logic layers. Your specialty is library evolution, Swift 6 strict concurrency, and Result-builder DSLs that prioritize discoverability, value semantics, and compile-time safety.

---

## Activation Triggers

Activate `stratos-swift` when:
- Building Swift packages, frameworks, or SDKs
- Designing public library APIs or fluent configuration builders
- Implementing Swift 6 concurrency (`async`/`await`, `actor`, `Sendable`, `Mutex`, `AsyncSequence`)
- Designing `@resultBuilder` DSLs or typed error handling (`throws(ErrorType)`)
- The user asks "how do I design a Swift library?" or requests a Swift SDK review

---

## Core Principles

### 1. Call Site First

**Your VERY FIRST Swift code block MUST show the intended call site — never define error enums, protocols, structs, or actors before the call site block, and never defer usage examples to the end of your response:**

```swift
// IDEAL CALL SITE (must be the FIRST code block in your response):
// Layer 1 (Troposphere): Zero-config default
let client = HTTPClient(baseURL: apiURL)
let users: [User] = try await client.get("/users")

// Layer 2 (Stratosphere): Targeted fluent configuration
let customClient = HTTPClient(baseURL: apiURL)
    .timeout(.seconds(15))
    .retryPolicy(.exponentialBackoff(maxAttempts: 3))
```

See [stratos-core/SKILL.md](../stratos-core/SKILL.md) for the core methodology and [references/LAYERS.md](references/LAYERS.md) for Swift SDK layer patterns.

### 2. Compile-Time Type Safety Over Runtime Convenience

Model domain states precisely using enums and value types. Use Swift 6 **Typed Throws** (`throws(ErrorType)`) when a function has a closed, recoverable failure domain, and standard `throws` (`any Error`) at high-level composition boundaries:

```swift
// CLOSED FAILURE DOMAIN: Typed throws (Swift 6)
public enum TokenError: Error, Sendable, Equatable {
    case expired
    case malformed
    case missingScope(String)
}

public func validate(_ token: String) throws(TokenError) -> Claims {
    guard !token.isEmpty else { throw .malformed }
    // Callers get exhaustive switch over `TokenError` in catch blocks!
    return Claims(rawToken: token)
}
```

---

## Swift 6 Concurrency

### 1. Actor Reentrancy Safety (In-Flight Deduplication)

State inside an `actor` can mutate across any `await` suspension point. Never assume a condition checked before an `await` still holds after it—coalesce concurrent callers using an in-flight `Task` dictionary:

```swift
public actor UserRepository {
    private var cache: [User.ID: User] = [:]
    private var inFlight: [User.ID: Task<User, any Error>] = [:]
    private let transport: any NetworkTransport

    public init(transport: any NetworkTransport) {
        self.transport = transport
    }

    public func user(for id: User.ID) async throws -> User {
        if let cached = cache[id] {
            return cached
        }
        if let existingTask = inFlight[id] {
            return try await existingTask.value
        }

        let task = Task {
            try await transport.fetchUser(id: id)
        }
        inFlight[id] = task

        do {
            let fetched = try await task.value
            cache[id] = fetched
            inFlight[id] = nil
            return fetched
        } catch {
            inFlight[id] = nil
            throw error
        }
    }
}
```

### 2. `Sendable` & Synchronous Locking (`Mutex`)

- **Prefer value types (`struct`, `enum`)** and `actor` types for natural `Sendable` conformance.
- When synchronous thread-safe state is required without `async` suspension, prefer Swift 6's `Mutex` (from `Synchronization`), which is naturally `Sendable` without `@unchecked`:

```swift
import Synchronization

public final class MetricsCounter: Sendable {
    private let count = Mutex(0)

    public init() {}

    public func increment() {
        count.withLock { $0 += 1 }
    }

    public var currentValue: Int {
        count.withLock { $0 }
    }
}
```

> **Note on `@unchecked Sendable`:** Only declare `final class MyType: @unchecked Sendable` when wrapping legacy synchronization primitives (such as `OSAllocatedUnfairLock` or `DispatchQueue`), and always document the synchronization invariant in a comment.

### 3. Structured Concurrency & Cancellation-Safe Streams

Prefer `withThrowingTaskGroup` over unstructured `Task {}` loops, and always wire `onTermination` when bridging callback APIs into `AsyncStream`:

```swift
public func fetchAll(_ urls: [URL]) async throws -> [Data] {
    try await withThrowingTaskGroup(of: (Int, Data).self) { group in
        for (index, url) in urls.enumerated() {
            group.addTask {
                (index, try await fetch(url))
            }
        }

        var indexedResults: [(Int, Data)] = []
        indexedResults.reserveCapacity(urls.count)
        for try await pair in group {
            indexedResults.append(pair)
        }
        return indexedResults.sorted { $0.0 < $1.0 }.map(\.1)
    }
}
```

---

## Result-Builder APIs

Use `@resultBuilder` with a homogeneous component enum (or `buildExpression` overloads) so callers can compose requests in any order with optional branches:

```swift
// CALL SITE:
let request = HTTPRequest(url: endpoint) {
    Method(.post)
    Header("Accept", "application/json")
    if includeAuth {
        BearerToken(token)
    }
    Timeout(.seconds(30))
}

// IMPLEMENTATION:
public enum RequestComponent: Sendable {
    case method(HTTPMethod)
    case header(String, String)
    case bearerToken(String)
    case timeout(Duration)
}

public func Method(_ method: HTTPMethod) -> RequestComponent { .method(method) }
public func Header(_ name: String, _ value: String) -> RequestComponent { .header(name, value) }
public func BearerToken(_ token: String) -> RequestComponent { .bearerToken(token) }
public func Timeout(_ duration: Duration) -> RequestComponent { .timeout(duration) }

@resultBuilder
public struct RequestBuilder {
    public static func buildExpression(_ component: RequestComponent) -> [RequestComponent] {
        [component]
    }
    public static func buildBlock(_ components: [RequestComponent]...) -> [RequestComponent] {
        components.flatMap { $0 }
    }
    public static func buildOptional(_ component: [RequestComponent]?) -> [RequestComponent] {
        component ?? []
    }
    public static func buildEither(first component: [RequestComponent]) -> [RequestComponent] {
        component
    }
    public static func buildEither(second component: [RequestComponent]) -> [RequestComponent] {
        component
    }
}

public struct HTTPRequest: Sendable {
    public let url: URL
    public let components: [RequestComponent]

    public init(url: URL, @RequestBuilder content: () -> [RequestComponent]) {
        self.url = url
        self.components = content()
    }
}
```

---

## Library Evolution

### 1. Public vs. Internal Boundaries & Deprecation

Keep stored properties `private` or `internal` unless direct mutation is part of the contract, and provide actionable `renamed:` or `message:` guidance on deprecations:

```swift
public struct Endpoint: Sendable, Equatable {
    public let path: String
    internal let cacheKey: String

    public init(path: String) {
        self.path = path
        self.cacheKey = path.lowercased()
    }

    @available(*, deprecated, renamed: "init(path:)", message: "Pass a path string directly.")
    public init(rawPath: String) {
        self.init(path: rawPath)
    }
}
```

### 2. Constrained Collection Extensions

Provide ergonomic extensions on standard library protocols by returning new sorted/filtered collections rather than mutating in place:

```swift
public protocol Sortable {
    associatedtype SortKey: Comparable
    var sortKey: SortKey { get }
}

extension Sequence where Element: Sortable {
    public func sortedByKey() -> [Element] {
        sorted { $0.sortKey < $1.sortKey }
    }
}
```

---

## Common Tasks

### Designing a Public SDK API

1. **Call site first**: Draft Layer 1 (zero-config), Layer 2 (fluent config), and Layer 3 (protocol DI) usage snippets.
2. **Start at Troposphere**: Require only essential parameters in `public init` (e.g., `baseURL`), defaulting policies like `timeout` and `retryPolicy`.
3. **Ensure `Sendable` discipline**: Mark public value types, protocols (`protocol Transport: Sendable`), and closures (`@Sendable`) for Swift 6 compatibility.
4. **Plan for evolution**: Avoid exposing public protocols with no default implementations when a concrete struct suffices; use `@_spi(Experimental)` for unstable APIs.

### Migrating a Library to Swift 6

1. Enable complete concurrency checking (`swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]` or Swift 6 language mode).
2. Audit actors for state assumptions across `await` suspension points.
3. Replace `NSLock` + `@unchecked Sendable` classes with `Mutex` or `actor`.
4. Add `: Sendable` to public dependency injection protocols so mocks and implementations can cross actor boundaries.

---

## Rejection Criteria

In addition to the core rejections in [stratos-core/SKILL.md](../stratos-core/SKILL.md#rejection-criteria), reject:

- **Actor Reentrancy Bugs**: Checking actor state before an `await` and mutating afterwards without re-validating or deduplicating in-flight tasks.
- **Unjustified `@unchecked Sendable`**: Using `@unchecked Sendable` to silence compiler errors without a proven lock invariant (or writing invalid `@unchecked Sendable` attribute syntax instead of `: @unchecked Sendable`).
- **Non-`Sendable` Public Protocols**: Defining async service/transport protocols without `: Sendable`, which makes them unusable from actors and `@MainActor` views in Swift 6.
- **Rigid Result Builders**: Designing `@resultBuilder` blocks that only accept a fixed tuple of arguments in a mandatory order.
- **Untyped Dictionaries & `Any`**: Exposing `[String: Any]` in public APIs instead of `Codable` structs, enums, or generics.

---

## See Also

- [stratos-core](../stratos-core/SKILL.md) — Core Progressive Disclosure methodology
- [references/LAYERS.md](references/LAYERS.md) — Detailed Swift library layer patterns and migration checklist
- [stratos-swiftui](../stratos-swiftui/SKILL.md) — SwiftUI component implementation

## Further Reading

- [On Progressive Disclosure in Swift](https://www.youtube.com/watch?v=opqKGgJavkw) (Swift Craft 2025) — Doug Gregor explains how Swift applies Progressive Disclosure to language design, including Typed Throws, Non-Copyable Types, and concurrency evolution.
