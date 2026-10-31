# In-source doc comments and API reference standards

This reference specifies formatting, structure, parameter tagging, and callout directives for Swift triple-slash (`///`) documentation comments parsed by DocC.

---

## 1. Comment syntax and placement

- **Always prefer triple slashes (`///`)** over block comments (`/** ... */`). Triple slashes blend cleanly with standard Swift source code formatting.
- Attach the doc comment immediately preceding the declaration with no blank line in between.

```swift
/// An immutable representation of a geographic coordinate.
///
/// A coordinate encapsulates latitude and longitude measured in degrees according
/// to the World Geodetic System 1984 (WGS 84) reference frame.
public struct Coordinate: Sendable, Hashable {
    /// The latitude in degrees.
    public let latitude: Double

    /// The longitude in degrees.
    public let longitude: Double
}
```

---

## 2. The single-sentence summary rule

The first paragraph of a doc comment serves as the **summary sentence**:
- It appears in Xcode Quick Help tooltips, code completion popovers, and DocC topic listings.
- Write it in the present tense, third person (e.g., *"Creates a new session"*, *"Calculates the distance"*), or as a clear noun phrase (*"An immutable representation..."*).
- Keep it concise (1 sentence, under 120 characters).
- Separate the summary from the extended discussion with an empty `///` line.

---

## 3. Documenting parameters, returns, and errors

Use standard Markdown list syntax with dedicated parameter tags:

```swift
/// Computes the great-circle distance between this coordinate and another coordinate.
///
/// Uses the Haversine formula to determine distance across a spherical Earth model.
/// For highly accurate geodetic calculations over long distances, use an ellipsoidal model instead.
///
/// - Parameter destination: The target coordinate to measure distance toward.
/// - Parameter unit: The unit of length for the result. Defaults to `.meters`.
/// - Returns: The distance between the two points expressed in the requested unit.
/// - Throws: `NavigationError.invalidCoordinates` if either coordinate contains NaN or infinite values.
public func distance(
    to destination: Coordinate,
    unit: DistanceUnit = .meters
) throws -> Double {
    // Implementation
}
```

### Grouped parameters syntax
When documenting methods with numerous parameters, you may group them under a `- Parameters:` header:

```swift
/// Configures the geocoding service with caching and network retry policies.
///
/// - Parameters:
///   - cachePolicy: The caching strategy applied to reverse geocoding lookups.
///   - timeoutInterval: Maximum duration in seconds to wait for network responses.
///   - retries: Number of automatic retry attempts before throwing a service error.
```

---

## 4. Callout directives

DocC parses GitHub-style blockquote callouts to highlight important notes, warnings, and experiments:

```swift
/// > Note:
/// > Coordinates use the standard WGS 84 datum.

/// > Important:
/// > Always check network reachability before initiating batch geocoding.

/// > Warning:
/// > Calling this method from a background thread while the view is animating may cause dropped frames.

/// > Tip:
/// > Cache the computed bounding box if performing repeated hit tests.

/// > Experiment:
/// > Try adjusting the convergence threshold to observe performance differences.
```

### Supported callout heads
- `> Note:`
- `> Important:`
- `> Warning:`
- `> Tip:`
- `> Experiment:`

---

## 5. Code examples in doc comments

Provide realistic, compilable Swift code snippets using triple-backtick ```swift blocks:

```swift
/// Encapsulates spatial indexing for low-latency bounding box queries.
///
/// ```swift
/// var index = SpatialIndex<POI>()
/// index.insert(landmark, at: landmark.coordinate)
///
/// let nearby = index.query(within: searchRegion)
/// ```
```
