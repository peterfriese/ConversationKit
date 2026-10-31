---
id: stratos-swift-api
name: Swift API Design & Progressive Disclosure
author: Peter Friese / Stratos
platform: apple
repository: peterfriese/Stratos
path: stratos-swift
default: true
description: Progressive disclosure, public API evolution, minimal binary footprint, @inlinable boundaries, SPI design (@_spi).
---

# Swift API Design & Progressive Disclosure

Authoritative standards for crafting idiomatic, resilient Swift libraries and public SDK interfaces following the Stratos design philosophy.

## Key Principles

1. **Progressive Disclosure**: Make simple tasks trivial at the call-site with sensible default arguments, while revealing advanced configuration options only when needed.
2. **Library Evolution & ABI Stability**:
   - Define clear `@frozen` vs non-frozen struct boundaries.
   - Design extensible interfaces using protocol composition rather than deep class hierarchies.
3. **SPI Encapsulation**: Use `@_spi(Internal)` for inter-module communication between internal sibling packages without exposing private implementation details to public package consumers.
4. **Performance & `@inlinable` Boundaries**: Reserve `@inlinable` for small, critical arithmetic or accessors where cross-module inlining outweighs library evolution overhead.
5. **Sendable & Concurrency Correctness**: Audit all public protocols and types for strict Swift 6 Sendable conformance. Never leak non-Sendable mutable state across module boundaries.
