---
id: apple-avanderlee-swiftui
name: Antoine van der Lee — SwiftUI Performance & State
author: Antoine van der Lee
platform: apple
repository: AvdLee/SwiftUI-Agent-Skill
path: skills/swiftui-expert-skill
default: false
description: SwiftUI optimization, avoiding view hitches, and fine-grained state management.
---

# Antoine van der Lee — SwiftUI Agent Skill

Focuses on building lightning-fast SwiftUI apps with optimal render cycles and memory profiles.

## Key Guidance

- **Avoid View Hitches**: Prevent expensive calculations or disk/network I/O inside view body execution.
- **Granular Observation**: Structure `@Observable` models with focused scopes so only views reading mutated properties invalidate and re-render.
- **View Identity**: Maintain stable explicit identities for collection rows using persistent IDs rather than array offsets or indices.
