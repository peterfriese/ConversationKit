# Myers diff mechanics and highlight shift auditing

This reference details how Swift DocC computes syntax highlights between tutorial steps, explains the mechanics of the shifted closing brace defect, and documents remediation rules and automated CI auditing.

---

## 1. How DocC diffing works

When a tutorial transitions from Step $N$ (`fileA.swift`) to Step $N+1$ (`fileB.swift`), the DocC compiler runs a line-by-line Myers difference algorithm:
1. Lines identified as insertions are styled with yellow/green highlight bars in the interactive tutorial viewer.
2. Unchanged lines remain neutral.
3. The tutorial client displays an animated code transition focusing the reader's attention on what changed.

---

## 2. The Myers diff brace shift defect

The Myers diff algorithm operates purely on raw text lines. It possesses no knowledge of Swift syntax, Abstract Syntax Trees (AST), or lexical scoping.

When a tutorial step appends a new scope or method ending with `}` directly after an existing scope ending with `}`:

```swift
// fileA.swift (Step 1)
struct ContentView: View {
    var body: some View {
        Text("Hello")
    }
}
```

```swift
// fileB.swift (Step 2 - adding a helper method)
struct ContentView: View {
    var body: some View {
        Text("Hello")
    }

    func calculateTotal() {
        process()
    }
}
```

### The defect in action
In the Myers edit graph, the algorithm searches for the shortest edit path. When consecutive scopes end with identical `}` lines, the edit graph is ambiguous. In many cases, the algorithm matches the new closing brace to the previous scope's closing brace.

This causes the highlight to **slide upward by one line**:
- The closing brace of `body` (`}`) is highlighted erroneously (even though it was not modified).
- The new closing brace of `calculateTotal()` (`}`) is left unhighlighted.

```swift
// ❌ Shifted Diff Defect as rendered in DocC:
    var body: some View {
        Text("Hello")
    } // <-- DocC highlights this brace erroneously!

    func calculateTotal() {
        process()
    } // <-- DocC leaves this actual new brace unhighlighted!
```

---

## 3. Remediation rules

Apply these three engineering rules when authoring sequential code listings in `Resources/code/`:

### Rule 1: The rule of prefix stability
Never edit, reorder, or delete lines above the insertion point between Step $N$ and Step $N+1$. Modifying lines above the insertion point creates alternate edit paths that confuse the Myers algorithm.

### Rule 2: Intermediate scope anchoring
Always maintain at least one empty blank line between scopes. Blank lines act as unambiguous anchors in the edit graph, preventing the diff engine from conflating consecutive closing braces.

```swift
// ✅ Clean edit path: blank line isolates scope boundaries
    var body: some View {
        Text("Hello")
    }

    func calculateTotal() {
        process()
    }
```

### Rule 3: Use `reset: true` for structural refactors
If a step introduces major structural shifts (such as wrapping a whole view body in a new layout container, or restructuring imports and extensions), do not force Myers diff to compute a complex multi-hunk diff.

Use `@Code(..., reset: true)` to reset the highlight state and present the file cleanly:
```markdown
@Step {
    Wrap the existing view contents in a `NavigationStack` to establish a navigation hierarchy.

    Navigation stacks manage navigation state and push detail views onto the stack.

    The preview refreshes to show the view embedded within a standard navigation bar.

    @Code(name: "ContentView.swift", file: "02-nav-step1.swift", reset: true)
}
```

---

## 4. Running the highlight auditor (`audit-docc-highlights.py`)

The repository includes `scripts/audit-docc-highlights.py` to detect shifted braces in compiled DocC static tutorial output.

### How the auditor detects defects
1. The script inspects the compiled tutorial JSON files located in `.build/docc-static/data/tutorials/`.
2. It extracts the sequential line highlights for each `@Code` transition.
3. If a closing brace (`}`) immediately preceding an inserted block is marked as highlighted, while the terminal closing brace of the inserted block is unhighlighted, the script flags a **shifted brace defect** and prints the surrounding line context with file coordinates.

### CLI usage
```bash
# Compile documentation first
just docc <TargetName>

# Run the audit
python3 scripts/audit-docc-highlights.py .build/docc-static/data/tutorials

# In CI where tutorial data may be conditionally built:
python3 scripts/audit-docc-highlights.py .build/docc-static/data/tutorials --allow-empty
```
