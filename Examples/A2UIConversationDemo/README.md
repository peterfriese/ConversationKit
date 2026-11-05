# A2UIConversationDemo

Interactive sample application combining **Google A2UI v1.0** (`A2UICore`, `A2UISwiftUI`, `BasicCatalog`, `BasicCatalogSwiftUI`) with **ConversationKit v2** on iOS 26+ and macOS 26+.

## Highlights

- **Inline Interactive A2UI Surfaces in Chat Turns**: Renders `A2UISwiftUI.Surface` directly inside `ConversationKit` v2's Top-Floating Turn runway alongside `ThinkingStateView`, `ToolCallsGroupView`, and `StreamingMarkdownView`.
- **Two-Way Agentic Action Loop (`ActionHandling`)**: Interacting with any A2UI component (`Button`, `TextField`, `ChoicePicker`, `Slider`, `DateTimeInput`) captures the `ResolvedAction` + live `DataModel` JSON and routes it back into the conversation as the next turn.
- **Live Model Switching via Liquid Glass Composer Pill**:
  1. **Gemini 3 Flash (`gemini-3-flash-preview`) / Gemini 3.1 Pro (`gemini-3.1-pro-preview`) / Gemini 3.1 Flash Lite (`gemini-3.1-flash-lite-preview`)** via **Firebase AI Logic** (`FirebaseAI`) — streams conversational Markdown and `<a2ui-json>` surfaces on the fly with automatic validation retry.
  2. **Local A2UI Agent Server (`a2a-local-agent`)** — connects over A2A JSON-RPC (`http://localhost:10002/a2a/json-rpc`) to `a2ui/samples/agent/node/restaurant_finder` or `a2ui/samples/agent/adk/restaurant_finder`.
- **Slash Commands & 35+ Bundled Catalog Examples**: Type `/coffee`, `/restaurants`, `/invitation`, `/dashboard`, `/workout`, or `/music` in the composer, or open the **Catalog & A2A** sheet from the toolbar to stream any official A2UI v1.0 Basic Catalog surface.
- **Live DataModel & Protocol Inspector**: Tap **Inspect JSON** on any rendered surface card to inspect its live bound `DataModel` JSON and the step-by-step A2UI protocol messages.
