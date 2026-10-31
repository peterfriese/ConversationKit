# ``PackageName``

A concise, high-level summary sentence describing what the package does.

## Overview

Provide an architectural introduction explaining the package's purpose, design philosophy,
and primary integration patterns. Address the core capabilities in direct, pragmatic prose.

```swift
import PackageName

let client = ServiceClient(apiKey: "...")
let result = try await client.performOperation()
```

### Key features

- **Swift 6 strict concurrency**: All core primitives conform to `Sendable` and respect actor isolation.
- **Zero third-party dependencies**: Built exclusively on native Foundation and standard library APIs.
- **Progressive disclosure**: Ergonomic convenience methods for common workflows alongside deep customization hooks.

## Topics

### Essentials

- <doc:GettingStarted>
- ``ServiceClient``
- ``Configuration``

### Core workflows

- ``Operation``
- ``ResultHandler``
- ``BatchProcessor``

### Error handling

- ``ServiceError``
- ``RetryPolicy``
