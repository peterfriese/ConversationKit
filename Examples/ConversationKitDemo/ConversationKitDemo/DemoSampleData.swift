//
//  DemoSampleData.swift
//  ConversationKitDemo
//
//  Created by Peter Friese on 19.02.24.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import ConversationKit
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Demo Style Presets

enum DemoComposerStyleOption: String, CaseIterable, Identifiable, Sendable {
  case classicGlass = "Classic Glass"
  case cardGlass = "Card Glass"
  case compactGlass = "Compact Glass"

  var id: String { rawValue }

  var symbolName: String {
    switch self {
    case .classicGlass:
      return "rectangle.roundedbottom"
    case .cardGlass:
      return "rectangle.split.1x2"
    case .compactGlass:
      return "capsule"
    }
  }

  var anyStyle: AnyMessageComposerStyle {
    switch self {
    case .classicGlass:
      return AnyMessageComposerStyle(.classicGlass)
    case .cardGlass:
      return AnyMessageComposerStyle(.cardGlass)
    case .compactGlass:
      return AnyMessageComposerStyle(.compactGlass)
    }
  }
}

enum DemoWorkingStyleOption: String, CaseIterable, Identifiable, Sendable {
  case inline = "Inline"
  case pill = "Pill"
  case minimal = "Minimal"

  var id: String { rawValue }

  var anyStyle: AnyWorkingStateStyle {
    switch self {
    case .inline:
      return AnyWorkingStateStyle(.inline)
    case .pill:
      return AnyWorkingStateStyle(.pill)
    case .minimal:
      return AnyWorkingStateStyle(.minimal)
    }
  }
}

enum DemoThinkingStyleOption: String, CaseIterable, Identifiable, Sendable {
  case collapsibleHeader = "Collapsible Header"
  case pill = "Pill"
  case minimal = "Minimal"

  var id: String { rawValue }

  var anyStyle: AnyThinkingStateStyle {
    switch self {
    case .collapsibleHeader:
      return AnyThinkingStateStyle(.collapsibleHeader)
    case .pill:
      return AnyThinkingStateStyle(.pill)
    case .minimal:
      return AnyThinkingStateStyle(.minimal)
    }
  }
}

enum DemoBubbleStyleOption: String, CaseIterable, Identifiable, Sendable {
  case tailedBubble = "Tailed Bubble"
  case roundedCard = "Rounded Card"
  case capsule = "Capsule"

  var id: String { rawValue }

  var anyStyle: AnyUserMessageBubbleStyle {
    switch self {
    case .tailedBubble:
      return AnyUserMessageBubbleStyle(.tailedBubble)
    case .roundedCard:
      return AnyUserMessageBubbleStyle(.roundedCard)
    case .capsule:
      return AnyUserMessageBubbleStyle(.capsule)
    }
  }
}

enum DemoStreamingHapticsOption: String, CaseIterable, Identifiable, Sendable {
  case punchy = "Punchy (Default)"
  case typewriter = "Typewriter"
  case subtle = "Subtle"
  case milestonesOnly = "Milestones Only"
  case off = "Off"

  var id: String { rawValue }

  var symbolName: String {
    switch self {
    case .punchy:
      return "waveform.path.ecg"
    case .typewriter:
      return "keyboard"
    case .subtle:
      return "waveform.path"
    case .milestonesOnly:
      return "flag.checkered"
    case .off:
      return "speaker.slash"
    }
  }

  var configuration: StreamingHapticsConfiguration {
    switch self {
    case .punchy:
      return .punchy
    case .typewriter:
      return .typewriter
    case .subtle:
      return .subtle
    case .milestonesOnly:
      return .milestonesOnly
    case .off:
      return .disabled
    }
  }
}

// MARK: - Demo Response Topic

enum DemoResponseTopic: Equatable, Sendable {
  case liquidGlass
  case scrollPhysics
  case multimodal
  case agenticTools
  case general(turnIndex: Int)

  static func resolve(
    from text: String,
    commandTrigger: String? = nil,
    hasAttachments: Bool = false,
    turnCount: Int
  ) -> DemoResponseTopic {
    let lower = text.lowercased()

    if hasAttachments
      || lower.contains("pdf")
      || lower.contains("image")
      || lower.contains("thumbnail")
      || lower.contains("quicklook")
      || lower.contains("collage")
      || lower.contains("attach")
    {
      return .multimodal
    }

    if lower.contains("glass")
      || lower.contains("style")
      || lower.contains("interactive")
      || lower.contains("menu")
      || lower.contains("anchor")
    {
      return .liquidGlass
    }

    if lower.contains("tool")
      || lower.contains("refactor")
      || lower.contains("plan")
      || lower.contains("approval")
      || lower.contains("thinking")
      || lower.contains("slash")
      || lower.contains("mention")
      || commandTrigger == "code"
    {
      return .agenticTools
    }

    if lower.contains("scroll")
      || lower.contains("deep dive")
      || lower.contains("long")
      || lower.contains("byte")
      || lower.contains("story")
      || lower.contains("pinning")
      || lower.contains("hysteresis")
      || lower.contains("optimistic")
      || commandTrigger == "benchmark"
    {
      return .scrollPhysics
    }

    return .general(turnIndex: max(0, turnCount - 1))
  }
}

// MARK: - DemoSampleData

enum DemoSampleData {
  // MARK: Suggestion Chips

  static let starterSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "liquid-glass",
      title: "Liquid Glass Design",
      prompt: "Explain how ConversationKit uses iOS 26+ Liquid Glass only on floating chrome.",
      symbolName: "sparkles",
      category: "Design & HIG"
    ),
    PromptSuggestion(
      id: "long-deep-dive",
      title: "Long Architecture Dive",
      prompt: "Give me a long architecture deep dive into Top-Floating User Bubbles, Zero-Jitter Streaming, and Byte's packet journey.",
      symbolName: "arrow.up.and.down.text.horizontal",
      category: "Scroll Physics"
    ),
    PromptSuggestion(
      id: "scroll-physics",
      title: "Scroll Physics & Pinning",
      prompt: "How does top-floating scroll pinning work during streaming?",
      symbolName: "pin",
      category: "Scroll Physics"
    ),
    PromptSuggestion(
      id: "slash-mentions",
      title: "Slash & @Mentions",
      prompt: "How do /slash commands and @resource mentions work in the composer?",
      symbolName: "command",
      category: "Structured Input"
    ),
    PromptSuggestion(
      id: "agentic-tools",
      title: "Agentic Tool & Plan",
      prompt: "Refactor the timeline engine using agentic tool calls, an execution plan, and an approval check.",
      symbolName: "wrench.and.screwdriver",
      category: "Agentic UI"
    ),
    PromptSuggestion(
      id: "tell-story",
      title: "Tell me a story",
      prompt: "Tell me a story about Byte, a packet of tokens streaming smoothly at 120Hz.",
      symbolName: "book.pages",
      category: "Story"
    ),
  ]

  static let liquidGlassFollowUpSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "followup-glass-compare",
      title: "Compare Classic vs Card Glass",
      prompt: "Compare ClassicGlass, CardGlass, and CompactGlass composer styles and how .interactive() breathes on touch-down.",
      symbolName: "rectangle.split.1x2",
      category: "Liquid Glass"
    ),
    PromptSuggestion(
      id: "followup-glass-anchor",
      title: "Menu Anchor Isolation",
      prompt: "Show how ComposerMenuSlotAnchorKey and .overlayPreferenceValue isolate Menus from glass pills.",
      symbolName: "scope",
      category: "Liquid Glass"
    ),
    PromptSuggestion(
      id: "followup-glass-scroll",
      title: "Explore Scroll Physics",
      prompt: "How does Top-Floating Turn Physics keep the user prompt pinned while Byte streams downward at 120Hz?",
      symbolName: "arrow.up.and.down.text.horizontal",
      category: "Scroll Physics"
    ),
    PromptSuggestion(
      id: "followup-glass-tools",
      title: "Agentic Tool & Plan",
      prompt: "Refactor the timeline engine using agentic tool calls, an execution plan, and an approval check.",
      symbolName: "wrench.and.screwdriver",
      category: "Agentic UI"
    ),
  ]

  static let scrollPhysicsFollowUpSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "followup-scroll-hysteresis",
      title: "ScrollToBottom Hysteresis",
      prompt: "How does the ScrollToBottom hysteresis deadband prevent button oscillation during streaming?",
      symbolName: "arrow.down.circle",
      category: "Scroll Physics"
    ),
    PromptSuggestion(
      id: "followup-scroll-optimistic",
      title: "Optimistic Turn ID",
      prompt: "Explain how optimisticUserMessage deduplicates by ID in O(1) without frame jumps on keyboard dismissal.",
      symbolName: "bolt.horizontal.circle",
      category: "Concurrency"
    ),
    PromptSuggestion(
      id: "followup-scroll-glass",
      title: "Liquid Glass Design",
      prompt: "Explain how ConversationKit uses iOS 26+ Liquid Glass only on floating chrome.",
      symbolName: "sparkles",
      category: "Design & HIG"
    ),
    PromptSuggestion(
      id: "followup-scroll-pdf",
      title: "Analyze Multimodal Pipeline",
      prompt: "Analyze our PDF specification, citations, and multimodal thumbnail pipeline.",
      symbolName: "doc.richtext",
      category: "Multimodal"
    ),
  ]

  static let multimodalFollowUpSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "followup-multimodal-quicklook",
      title: "QuickLook Sanitization",
      prompt: "How does resolveQuickLookURL sanitize filenames and isolate previews in temporary storage?",
      symbolName: "lock.shield",
      category: "Security"
    ),
    PromptSuggestion(
      id: "followup-multimodal-collage",
      title: "Image Collage Layout",
      prompt: "How does MessageAttachmentsView lay out 1 to 4 photo attachments and downsample thumbnails?",
      symbolName: "photo.on.rectangle.angled",
      category: "Multimodal"
    ),
    PromptSuggestion(
      id: "followup-multimodal-tools",
      title: "Agentic Tool & Plan",
      prompt: "Refactor the timeline engine using agentic tool calls, an execution plan, and an approval check.",
      symbolName: "wrench.and.screwdriver",
      category: "Agentic UI"
    ),
    PromptSuggestion(
      id: "followup-multimodal-scroll",
      title: "Long Architecture Dive",
      prompt: "Give me a long architecture deep dive into Top-Floating User Bubbles, Zero-Jitter Streaming, and Byte's packet journey.",
      symbolName: "arrow.up.and.down.text.horizontal",
      category: "Scroll Physics"
    ),
  ]

  static let agenticToolsFollowUpSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "followup-agentic-thinking",
      title: "ThinkingState Styles",
      prompt: "How do ThinkingStateStyle (.collapsibleHeader, .pill, .minimal) and collapsed-by-default reasoning traces work?",
      symbolName: "brain",
      category: "Reasoning"
    ),
    PromptSuggestion(
      id: "followup-agentic-slash",
      title: "Slash & @Mentions",
      prompt: "Explain how ComposerTextBuffer uses zero-width sentinels for two-stage /command and @mention backspace removal.",
      symbolName: "command",
      category: "Structured Input"
    ),
    PromptSuggestion(
      id: "followup-agentic-glass",
      title: "Compare Classic vs Card Glass",
      prompt: "Compare ClassicGlass, CardGlass, and CompactGlass composer styles and how .interactive() breathes on touch-down.",
      symbolName: "sparkles",
      category: "Liquid Glass"
    ),
    PromptSuggestion(
      id: "followup-agentic-pdf",
      title: "Multimodal Attachments",
      prompt: "Analyze our PDF specification, citations, and multimodal thumbnail pipeline.",
      symbolName: "doc.richtext",
      category: "Multimodal"
    ),
  ]

  static let generalFollowUpSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "followup-general-stratos",
      title: "Progressive Disclosure API",
      prompt: "Walk through ConversationKit's 4-layer Progressive Disclosure API from zero-config to custom Style protocols.",
      symbolName: "layers.3.down.forward",
      category: "SDK Design"
    ),
    PromptSuggestion(
      id: "followup-general-glass",
      title: "Liquid Glass Design",
      prompt: "Explain how ConversationKit uses iOS 26+ Liquid Glass only on floating chrome.",
      symbolName: "sparkles",
      category: "Design & HIG"
    ),
    PromptSuggestion(
      id: "followup-general-scroll",
      title: "Long Architecture Dive",
      prompt: "Give me a long architecture deep dive into Top-Floating User Bubbles, Zero-Jitter Streaming, and Byte's packet journey.",
      symbolName: "arrow.up.and.down.text.horizontal",
      category: "Scroll Physics"
    ),
    PromptSuggestion(
      id: "followup-general-tools",
      title: "Agentic Tool & Plan",
      prompt: "Refactor the timeline engine using agentic tool calls, an execution plan, and an approval check.",
      symbolName: "wrench.and.screwdriver",
      category: "Agentic UI"
    ),
  ]

  static func suggestions(for messages: [DefaultMessage]) -> [PromptSuggestion] {
    guard let lastUserMessage = messages.last(where: { $0.participant == .user }) else {
      return starterSuggestions
    }
    let userTurnCount = messages.filter { $0.participant == .user }.count
    let commandTrigger: String? = lastUserMessage.tokens.compactMap { token in
      if case .command(let cmd) = token.kind { return cmd.trigger }
      return nil
    }.first

    let topic = DemoResponseTopic.resolve(
      from: lastUserMessage.content ?? "",
      commandTrigger: commandTrigger,
      hasAttachments: !lastUserMessage.attachments.isEmpty,
      turnCount: userTurnCount
    )

    switch topic {
    case .liquidGlass:
      return liquidGlassFollowUpSuggestions
    case .scrollPhysics:
      return scrollPhysicsFollowUpSuggestions
    case .multimodal:
      return multimodalFollowUpSuggestions
    case .agenticTools:
      return agenticToolsFollowUpSuggestions
    case .general:
      return generalFollowUpSuggestions
    }
  }

  // MARK: Slash Commands, Mentions & Models

  static let availableCommands: [SlashCommand] = [
    SlashCommand(
      id: "summarize",
      trigger: "summarize",
      title: "Summarize thread",
      description: "Condense key architectural decisions and action items",
      symbolName: "text.quote",
      category: "Workflow"
    ),
    SlashCommand(
      id: "code",
      trigger: "code",
      title: "Generate Swift code",
      description: "Emit Swift 6 strict-concurrency & SwiftUI implementations",
      symbolName: "chevron.left.forwardslash.chevron.right",
      category: "Engineering"
    ),
    SlashCommand(
      id: "benchmark",
      trigger: "benchmark",
      title: "Benchmark scroll physics",
      description: "Verify 120Hz ProMotion frame pacing and top-anchor stability",
      symbolName: "gauge.with.dots.needle.67percent",
      category: "Performance"
    ),
    SlashCommand(
      id: "explain",
      trigger: "explain",
      title: "Explain architecture",
      description: "Walk through Progressive Disclosure customization layers",
      symbolName: "sparkles",
      category: "Architecture"
    ),
  ]

  static let availableMentions: [ResourceMention] = [
    ResourceMention(
      id: "ConversationView.swift",
      queryHandle: "ConversationView.swift",
      title: "ConversationView.swift",
      subtitle: "Sources/ConversationKit/Views/Timeline/ConversationView.swift",
      symbolName: "swift",
      kind: .file
    ),
    ResourceMention(
      id: "MessageComposerView.swift",
      queryHandle: "MessageComposerView.swift",
      title: "MessageComposerView.swift",
      subtitle: "Sources/ConversationKit/Views/Composer/MessageComposerView.swift",
      symbolName: "swift",
      kind: .file
    ),
    ResourceMention(
      id: "ArchitectureGuide.md",
      queryHandle: "ArchitectureGuide.md",
      title: "ArchitectureGuide.md",
      subtitle: "docs/ArchitectureGuide.md",
      symbolName: "building.columns",
      kind: .document
    ),
    ResourceMention(
      id: "DesignSystem.pdf",
      queryHandle: "DesignSystem.pdf",
      title: "DesignSystem.pdf",
      subtitle: "docs/design/LiquidGlass-HIG.pdf",
      symbolName: "doc.richtext",
      kind: .document
    ),
  ]

  static let availableModels: [ComposerModelOption] = [
    ComposerModelOption(
      id: "claude-4-6-sonnet",
      name: "Claude Sonnet 4.6",
      subtitle: "Fast & balanced reasoning",
      badge: "Default",
      symbolName: "sparkles",
      category: "Anthropic"
    ),
    ComposerModelOption(
      id: "claude-4-5-haiku",
      name: "Claude Haiku 4.5",
      subtitle: "Ultra fast lightweight model",
      badge: "Fast",
      symbolName: "bolt.fill",
      category: "Anthropic"
    ),
    ComposerModelOption(
      id: "gemini-3-pro",
      name: "Gemini 3 Pro",
      subtitle: "Deep multimodal & code analysis",
      badge: "Pro",
      symbolName: "wand.and.stars",
      category: "Google"
    ),
    ComposerModelOption(
      id: "gemini-3-flash",
      name: "Gemini 3 Flash",
      subtitle: "High speed multimodal",
      badge: "Fast",
      symbolName: "bolt.fill",
      category: "Google"
    ),
    ComposerModelOption(
      id: "foundation-model-local",
      name: "Apple Intelligence",
      subtitle: "On-device Apple Intelligence",
      badge: "Local",
      symbolName: "cpu",
      category: "On-Device"
    ),
  ]

  // MARK: Sample Attachments

  static func makeSampleImageAttachment() -> ConversationAttachment? {
    guard let imageBox = PlatformImageBox.solidColor(
      red: 0.16,
      green: 0.48,
      blue: 0.92,
      size: CGSize(width: 480, height: 320)
    ) else { return nil }

    return ConversationAttachment(
      imageBox: imageBox,
      filename: "LiquidGlass-Architecture.png",
      uploadState: .ready
    )
  }

  static func makeSamplePDFAttachment() -> ConversationAttachment {
    ConversationAttachment(
      data: makeSamplePDFData(),
      contentType: .pdf,
      filename: "Architecture-Overview.pdf",
      uploadState: .ready
    )
  }

  static func makeSampleSwiftAttachment() -> ConversationAttachment {
    let swiftSource = """
    import ConversationKit
    import SwiftUI

    struct ChatScreen: View {
      @State private var messages: [DefaultMessage] = []

      var body: some View {
        ConversationView(messages: $messages)
          .messageComposerStyle(.cardGlass)
          .thinkingStateStyle(.collapsibleHeader)
      }
    }
    """
    return ConversationAttachment(
      data: Data(swiftSource.utf8),
      contentType: .swiftSource,
      filename: "ChatScreen.swift",
      uploadState: .ready
    )
  }

  static func makeUploadingPDFAttachment(id: String) -> ConversationAttachment {
    ConversationAttachment(
      id: id,
      data: makeSamplePDFData(),
      contentType: .pdf,
      filename: "Spec-Upload-Demo.pdf",
      uploadState: .uploading(progress: 0.1)
    )
  }

  private static func makeSamplePDFData() -> Data {
    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
    let mutableData = NSMutableData()
    guard
      let consumer = CGDataConsumer(data: mutableData as CFMutableData),
      var mediaBox = Optional(pageRect),
      let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
    else {
      return Data("%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF".utf8)
    }

    context.beginPDFPage(nil)
    context.setFillColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0)
    context.fill(pageRect)
    context.setFillColor(red: 0.18, green: 0.45, blue: 0.88, alpha: 1.0)
    context.fill(CGRect(x: 48, y: 660, width: 516, height: 72))
    context.endPDFPage()
    context.closePDF()
    return mutableData as Data
  }

  // MARK: Simulated Agentic Primitives

  static func makeInitialThinkingTrace(
    for topic: DemoResponseTopic,
    startedAt: Date
  ) -> ThinkingTrace {
    switch topic {
    case .liquidGlass:
      return ThinkingTrace(
        status: .thinking(startedAt: startedAt),
        summary: "Inspecting iOS 26+ Liquid Glass chrome & menu anchor slots…",
        transcript: """
        1. Auditing .safeAreaBar(edge: .bottom) floating chrome hierarchy.
        2. Checking 3-zone bookend layout inside GlassEffectContainer.
        3. Verifying ComposerMenuSlotAnchorKey overlay isolation for Menu hit-testing.
        """
      )
    case .scrollPhysics:
      return ThinkingTrace(
        status: .thinking(startedAt: startedAt),
        summary: "Computing unoccluded viewport runway & 120Hz frame pacing…",
        transcript: """
        1. Locked activeTurnMinHeight to unoccluded viewport runway.
        2. Verified user bubble top-edge anchor stability.
        3. Simulating Byte's downward token stream without per-token scrollTo calls.
        """
      )
    case .multimodal:
      return ThinkingTrace(
        status: .thinking(startedAt: startedAt),
        summary: "Inspecting thumbnail downsampling & QuickLook sandbox…",
        transcript: """
        1. Verifying CGImageSource / QLThumbnailGenerator off-main-actor pipeline.
        2. Auditing filename sanitization inside temporary QuickLook storage.
        3. Preparing 1–4 photo collage layout and attachment upload state machine.
        """
      )
    case .agenticTools:
      return ThinkingTrace(
        status: .thinking(startedAt: startedAt),
        summary: "Coordinating agentic tool calls, execution plan & approval gates…",
        transcript: """
        1. Dispatching workspace symbol search & Liquid Glass audit tools.
        2. Constructing multi-step AgentPlan progress tracker.
        3. Preparing human-in-the-loop ApprovalRequest card.
        """
      )
    case .general(let turnIndex):
      return ThinkingTrace(
        status: .thinking(startedAt: startedAt),
        summary: "Synthesizing turn #\(turnIndex + 1) architectural response…",
        transcript: """
        1. Evaluating 4-layer Progressive Disclosure API surface.
        2. Checking Swift 6 strict concurrency & @MainActor isolation invariants.
        3. Formatting incremental Markdown blocks and syntax-highlighted Swift code.
        """
      )
    }
  }

  static func makeCompletedThinkingTrace(
    id: String,
    for topic: DemoResponseTopic
  ) -> ThinkingTrace {
    switch topic {
    case .liquidGlass:
      return ThinkingTrace(
        id: id,
        status: .completed(duration: 1.1),
        summary: "Verified iOS 26+ Liquid Glass chrome & zero-demotion Menu overlay",
        transcript: """
        1. Confirmed Liquid Glass is restricted strictly to floating chrome.
        2. Verified .glassEffect(..., in:).interactive() touch-down inflation in Metal.
        3. Isolated UIContextMenuInteraction in .overlayPreferenceValue(ComposerMenuSlotAnchorKey.self).
        """
      )
    case .scrollPhysics:
      return ThinkingTrace(
        id: id,
        status: .completed(duration: 1.3),
        summary: "Evaluated Top-Floating Turn Physics & 120Hz streaming invariants",
        transcript: """
        1. Locked activeTurnMinHeight to max(lockedUnoccludedHeight, 320).
        2. Confirmed single-shot proxy.scrollTo(newTurnID, anchor: .top).
        3. Verified ScrollToBottomButton >80pt / <24pt hysteresis deadband.
        """
      )
    case .multimodal:
      return ThinkingTrace(
        id: id,
        status: .completed(duration: 0.9),
        summary: "Audited off-main-actor thumbnails & QuickLook path sanitization",
        transcript: """
        1. Downsampled image & PDF attachments to <= 320px via PlatformThumbnailGenerator.
        2. Sanitized QuickLook preview paths against path traversal characters.
        3. Validated deterministic .uploading(progress:) -> .ready submission gate.
        """
      )
    case .agenticTools:
      return ThinkingTrace(
        id: id,
        status: .completed(duration: 1.4),
        summary: "Executed 2 workspace tools and prepared approval checkpoint",
        transcript: """
        1. search_workspace_symbols matched 4 symbols in 0.42s.
        2. verify_liquid_glass_budget confirmed 0 glass violations in 0.31s.
        3. Staged interactive AgentPlanView and ApprovalRequest confirmation.
        """
      )
    case .general(let turnIndex):
      return ThinkingTrace(
        id: id,
        status: .completed(duration: 1.0),
        summary: "Synthesized turn #\(turnIndex + 1) Swift 6 & SDK overview",
        transcript: """
        1. Mapped Progressive Disclosure API customization layers.
        2. Verified O(1) DefaultMessage equality diffing and token sentinels.
        3. Committed Markdown blocks for 120Hz ProMotion rendering.
        """
      )
    }
  }

  static func makeInitialToolCalls(responseID: String, startedAt: Date) -> [ToolCall] {
    [
      ToolCall(
        id: "tool-search-\(responseID)",
        name: "search_workspace_symbols",
        symbolName: "magnifyingglass",
        status: .running(startedAt: startedAt),
        argumentsSummary: "query: \"ConversationView activeTurnMinHeight\"",
        argumentsJSON: "{\n  \"query\": \"ConversationView activeTurnMinHeight\",\n  \"scope\": \"Sources/ConversationKit\"\n}"
      )
    ]
  }

  static func makeCompletedToolCalls(responseID: String) -> [ToolCall] {
    [
      ToolCall(
        id: "tool-search-\(responseID)",
        name: "search_workspace_symbols",
        symbolName: "magnifyingglass",
        status: .succeeded(duration: 0.42),
        argumentsSummary: "query: \"ConversationView activeTurnMinHeight\"",
        resultSummary: "Matched 4 symbols in ConversationView.swift",
        argumentsJSON: "{\n  \"query\": \"ConversationView activeTurnMinHeight\",\n  \"scope\": \"Sources/ConversationKit\"\n}",
        resultJSON: "{\n  \"matches\": [\n    \"ConversationView.activeTurnMinHeight\",\n    \"ConversationTurn.group(_:)\"\n  ]\n}"
      ),
      ToolCall(
        id: "tool-audit-\(responseID)",
        name: "verify_liquid_glass_budget",
        symbolName: "checkmark.shield",
        status: .succeeded(duration: 0.31),
        argumentsSummary: "target: \"Sources/ConversationKit/Views\"",
        resultSummary: "0 glass violations inside scrolling cells"
      ),
    ]
  }

  static func makeAgentPlan() -> AgentPlan {
    AgentPlan(
      title: "ConversationKit Verification Plan",
      steps: [
        AgentPlan.Step(
          title: "Lock unoccluded viewport runway",
          detail: "Maintain activeTurnMinHeight across keyboard dismissal",
          status: .completed
        ),
        AgentPlan.Step(
          title: "Stream block-committed Markdown",
          detail: "O(1) settled prefix + active tail parser",
          status: .completed
        ),
        AgentPlan.Step(
          title: "Verify human-in-the-loop approval",
          detail: "Awaiting developer confirmation for benchmark export",
          status: .inProgress
        ),
      ]
    )
  }

  static func makeApprovalRequest() -> ApprovalRequest {
    ApprovalRequest(
      title: "Export 120Hz Scroll Benchmark Trace",
      detail: "Allow the agent to write the frame-pacing benchmark report to the temporary workspace directory?",
      riskLevel: .low,
      scopeIdentifier: "benchmark.export",
      changePreview: "swift test --filter ConversationTurnPhysicsTests",
      decision: .pending
    )
  }

  static func makeCitations(for topic: DemoResponseTopic) -> [Citation] {
    switch topic {
    case .liquidGlass:
      return [
        Citation(
          index: 1,
          title: "Applying Liquid Glass to custom views",
          domain: "developer.apple.com",
          urlString: "https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views",
          snippet: "Use GlassEffectContainer and .glassEffect(.regular.interactive(), in:) for floating controls."
        ),
        Citation(
          index: 2,
          title: "MessageComposerStyle & ComposerMenuSlotAnchorKey",
          domain: "github.com",
          urlString: "https://github.com/peterfriese/ConversationKit",
          snippet: "Isolate UIContextMenuInteraction outside .glassEffect subtrees using Anchor<CGRect> preferences."
        ),
      ]
    case .scrollPhysics:
      return [
        Citation(
          index: 1,
          title: "ConversationView Top-Floating Turn Physics",
          domain: "github.com",
          urlString: "https://github.com/peterfriese/ConversationKit",
          snippet: "Lock activeTurnMinHeight to unoccluded viewport height and scroll once on submission."
        ),
        Citation(
          index: 2,
          title: "SwiftUI ScrollView & onScrollGeometryChange",
          domain: "developer.apple.com",
          urlString: "https://developer.apple.com/documentation/swiftui/scrollview",
          snippet: "Extract lightweight Equatable geometry snapshots to drive hysteresis state machines."
        ),
      ]
    case .multimodal:
      return [
        Citation(
          index: 1,
          title: "QLThumbnailGenerator & QuickLook Security",
          domain: "developer.apple.com",
          urlString: "https://developer.apple.com/documentation/quicklookthumbnailing/qlthumbnailgenerator",
          snippet: "Generate downsampled thumbnails off the main actor and sanitize temporary preview URLs."
        ),
        Citation(
          index: 2,
          title: "PlatformThumbnailGenerator.swift",
          domain: "github.com",
          urlString: "https://github.com/peterfriese/ConversationKit",
          snippet: "Strict filename sanitization and <= 320px thumbnail caching by (id, maxPixelSize)."
        ),
      ]
    case .agenticTools:
      return [
        Citation(
          index: 1,
          title: "Agentic Primitives: Thinking, Tool Calls, Plans & Approvals",
          domain: "github.com",
          urlString: "https://github.com/peterfriese/ConversationKit",
          snippet: "First-class SwiftUI views for ThinkingTrace, ToolCall, AgentPlan, and ApprovalRequest."
        ),
        Citation(
          index: 2,
          title: "Swift Structured Concurrency & Task Cancellation",
          domain: "developer.apple.com",
          urlString: "https://developer.apple.com/documentation/swift/task",
          snippet: "Check Task.checkCancellation() cooperatively during token streaming and tool execution."
        ),
      ]
    case .general:
      return [
        Citation(
          index: 1,
          title: "ConversationKit Progressive Disclosure Guide",
          domain: "github.com",
          urlString: "https://github.com/peterfriese/ConversationKit",
          snippet: "Four concentric API layers from zero-config ConversationView to custom SwiftUI Style protocols."
        ),
        Citation(
          index: 2,
          title: "Human Interface Guidelines — Materials & Liquid Glass",
          domain: "developer.apple.com",
          urlString: "https://developer.apple.com/design/human-interface-guidelines",
          snippet: "Reserve Liquid Glass for floating navigation and chrome; keep scrolling content opaque."
        ),
      ]
    }
  }

  // MARK: Simulated Streaming Markdown Builder

  static func buildResponseMarkdown(
    for submission: ConversationSubmission<DefaultMessage>,
    topic: DemoResponseTopic,
    turnCount: Int
  ) -> String {
    let modelName = submission.selectedModel?.name ?? "Claude Sonnet 4.6"
    let commandPrefix = submission.command.map { "Executed `\($0.formattedTrigger)` · " } ?? ""
    let mentionsSummary = submission.mentions.isEmpty
      ? ""
      : "Referenced: " + submission.mentions.map { "`\($0.formattedHandle)`" }.joined(separator: ", ") + "\n\n"
    let attachmentsNote = submission.attachments.isEmpty
      ? ""
      : "Attached **\(submission.attachments.count)** item(s): "
        + submission.attachments.map { "`\($0.filename)`" }.joined(separator: ", ") + "\n\n"
    let lower = submission.text.lowercased()

    switch topic {
    case .liquidGlass:
      if lower.contains("compare") || lower.contains("card") || lower.contains("compact") {
        return """
        ### \(commandPrefix)Comparing `ClassicGlass`, `CardGlass`, and `CompactGlass` (\(modelName))

        \(mentionsSummary)\(attachmentsNote)**ConversationKit** ships three interchangeable `MessageComposerStyle` presets inside `.safeAreaBar(edge: .bottom)` so your app can match Apple Messages, multi-row AI workspaces, or compact utility sheets while **Byte** streams tokens above.

        > Every preset uses `GlassEffectContainer(spacing: 8)` and `.glassEffect(.regular.interactive(), in:)` so touch-down inflation is driven by iOS 26's native C++/Metal shader.

        | Style Preset | Geometry & Shape | Best For |
        | --- | --- | --- |
        | `.classicGlass` | `44pt` circular `+` / `↑` bookends flanking a concentric text pill | iMessage-style chat & consumer assistants |
        | `.cardGlass` | Unified `RoundedRectangle(cornerRadius: 24)` two-row card | Multi-model AI IDEs with capabilities & dictation |
        | `.compactGlass` | Single-row capsule with inline `32×32pt` circular actions | Compact sheets, popovers & inspector sidebars |

        #### Switching Composer Styles Declaratively
        ```swift
        import ConversationKit
        import SwiftUI

        struct StyledConversationScreen: View {
          @State private var messages: [DefaultMessage] = []
          @State private var selectedModel: ComposerModelOption?

          var body: some View {
            ConversationView(messages: $messages)
              .composerModels(DemoSampleData.availableModels, selection: $selectedModel)
              .messageComposerStyle(.cardGlass) // or .classicGlass / .compactGlass
              .thinkingStateStyle(.collapsibleHeader)
              .userMessageBubbleStyle(.tailedBubble)
          }
        }
        ```

        #### Why `.interactive()` Never Uses Manual Scale Hacks
        1. **Native Shader Refraction:** Calling `.glassEffect(.regular.interactive(), in: shape)` activates hardware-accelerated specular edge catch and elastic inflation on finger-down.
        2. **Zero Custom Gesture Interference:** Avoiding custom gesture wrappers ensures `TextField` cursor placement, text selection, and `Menu` presentation work without responder conflicts.
        """
      } else {
        return """
        ### \(commandPrefix)iOS 26+ Liquid Glass Chrome Architecture (\(modelName))

        \(mentionsSummary)\(attachmentsNote)**ConversationKit** follows Apple's Human Interface Guidelines for **Liquid Glass**: glass materials are used exclusively on floating chrome over scrolling content—never on scrolling timeline cells where **Byte** renders Markdown paragraphs.

        > **Design Principle:** Content lives in opaque or subtly tinted semantic surfaces (`Color.platformUserBubbleFill`, `Color.platformSecondaryBackground`); floating controls live inside `GlassEffectContainer` within `.safeAreaBar(edge: .bottom)`.

        #### Canonical 3-Zone Bookend Grammar (`ClassicGlass`)
        * **Leading Bookend (`44×44pt` Circle):** Standalone `+` attachment `Menu` with `.glassEffect(.regular.interactive(), in: .circle)`.
        * **Center Interactive Vessel:** Concentric `RoundedRectangle(cornerRadius: 22, style: .continuous)` hosting the growing `TextField`, attachment preview tray, `/command` tokens, and inner trailing accessories (`32×32pt`).
        * **Trailing Bookend (`44×44pt` Circle):** Morphing Submit (`arrow.up`) / Stop (`stop.fill`) button using `.buttonStyle(.glassProminent)` that smoothly reveals when `canSubmit || isGenerating`.

        | Surface | Material / Fill | Interactive Shader |
        | --- | --- | --- |
        | Bottom Composer Bar | `GlassEffectContainer` + `.glassEffect` | `.regular.interactive()` |
        | Scroll-to-Bottom Pill | `.buttonStyle(.glass)` | Native button glass morph |
        | Suggestion Chips | `.buttonStyle(.glass)` | Native capsule press |
        | Timeline Cells & Code | Semantic `Color.platformSecondaryBackground` | None (120Hz scroll budget) |

        ```swift
        GlassEffectContainer(spacing: 8) {
          HStack(alignment: .bottom, spacing: 8) {
            attachmentBookendButton // 44x44pt .glassEffect(.regular.interactive(), in: .circle)
            centerTextVessel        // Concentric rounded rect with .glassEffect(.regular.interactive())
            if showTrailingSlot {
              trailingSubmitButton  // 44x44pt .buttonStyle(.glassProminent)
            }
          }
        }
        ```
        """
      }

    case .scrollPhysics:
      return """
      ### \(commandPrefix)Top-Floating Turn Physics & Byte's 120Hz Journey (\(modelName))

      \(mentionsSummary)\(attachmentsNote)When you submit a prompt, **ConversationKit** groups messages into deterministic `ConversationTurn` containers and anchors your user bubble at the top of the unoccluded viewport runway (`anchor: .top`, `ΔY = 0pt`).

      #### Byte's Journey Through the Unoccluded Runway
      Once upon a time in a 120Hz ProMotion render loop, a tiny packet of tokens named **Byte** traveled from the model stream into `ConversationView`. Instead of triggering per-token `scrollTo` calls that cause layout jitter, Byte flowed smoothly downward inside the active turn's pre-allocated runway while your prompt stayed rock-solid at the top of the screen.

      * **Single-Shot Top Scroll:** `proxy.scrollTo(newTurnID, anchor: .top)` fires *only once* when a turn is submitted—never during token streaming.
      * **Locked Unoccluded Height:** `activeTurnMinHeight` locks to `max(lockedUnoccludedHeight, 320)` so software keyboard dismissal never shrinks the active turn's runway.
      * **O(1) Incremental Markdown:** Settled paragraphs, tables, and fenced code blocks lock their `MarkdownBlock.id` while only the trailing unfinished block re-parses.

      | Benchmark Metric | Target Budget | Measured (`ConversationKit`) |
      | --- | --- | --- |
      | User Bubble Drift (`ΔY`) | `0.0 pt` | `0.0 pt` across 220 blocks |
      | 100-Step Incremental Parse | `< 8.33 ms / step` | `~0.42 ms / step` |
      | 10,000 `DefaultMessage` Diffs | `< 50.0 ms` | `~4.8 ms` ($O(1)$ fast-path) |

      ```swift
      ConversationView(messages: $messages)
        .onSendMessage { submission in
          // Preserves submission.message.id so O(1) deduplication is seamless:
          messages.append(submission.message)
          await streamAssistantReply(for: submission)
        }
      ```
      """

    case .multimodal:
      return """
      ### \(commandPrefix)Multimodal Attachment Pipeline & Off-Main-Actor Thumbnails (\(modelName))

      \(mentionsSummary)\(attachmentsNote)**ConversationKit** provides a complete multimodal pipeline (`ConversationAttachment`) supporting photos, PDFs, code files, audio, and documents—all while keeping the `@MainActor` UI thread free for **Byte**'s 120Hz streaming.

      #### Off-Main-Actor Downsampling (`PlatformThumbnailGenerator`)
      * **Memory-Safe `<= 320px` Thumbnails:** Large photos and multi-page PDFs are downsampled off the main actor via `CGImageSourceCreateThumbnailAtIndex` and `QLThumbnailGenerator`, then cached in an actor-isolated LRU cache keyed by `(id, maxPixelSize)`.
      * **Adaptive `1–4` Photo Collage (`MessageAttachmentsView`):** User bubbles automatically arrange 1, 2, 3, or 4 image attachments into a proportional grid and group PDFs/code files into tappable QuickLook document cards.
      * **Submission Gating:** Composer submission stays disabled while any attachment is in `.uploading(progress:)` or `.failed(error:)`.

      ```swift
      let pdfAttachment = ConversationAttachment(
        data: pdfData,
        contentType: .pdf,
        filename: "Architecture-Overview.pdf",
        uploadState: .uploading(progress: 0.45)
      )
      // Composer submit button automatically waits until uploadState == .ready
      ```
      """

    case .agenticTools:
      return """
      ### \(commandPrefix)Agentic Execution: Tool Calls, Plans & Approvals (\(modelName))

      \(mentionsSummary)\(attachmentsNote)Above this Markdown stream, **ConversationKit** rendered four first-class agentic primitives inside the active turn while **Byte** kept your user prompt anchored at the top:

      1. **`ThinkingStateView`:** Collapsed-by-default reasoning disclosure showing elapsed duration and expandable chain-of-thought transcript.
      2. **`ToolCallsGroupView`:** Expandable group of `ToolCall` invocations (`search_workspace_symbols`, `verify_liquid_glass_budget`) with JSON argument/result inspection and `.onToolCallRetry` support.
      3. **`AgentPlanView`:** Live step-by-step progress card computing `completedCount` and `progressFraction`.
      4. **`AgentApprovalView`:** Interactive human-in-the-loop confirmation card (`Allow Once`, `Always Allow`, `Deny`) wired to `.onApprovalDecision`.

      ```swift
      ConversationView(messages: $messages)
        .onApprovalDecision { request, decision in
          resolveApproval(request: request, decision: decision)
        }
        .onToolCallRetry { failedToolCall in
          await retryToolCall(failedToolCall)
        }
      ```

      > Try tapping **Allow Once** on the approval card above—watch the final step in `ConversationKit Verification Plan` transition from in-progress to completed!
      """

    case .general:
      return """
      ### \(commandPrefix)Progressive Disclosure API Overview (\(modelName))

      \(mentionsSummary)\(attachmentsNote)You sent: *"\(submission.text)"*. **ConversationKit** is architected around **Progressive Disclosure** so you can start with 5 lines of code and scale up to full agentic workflows while **Byte** streams tokens at 120Hz.

      | Layer | Focus | Entry Point |
      | --- | --- | --- |
      | **Layer 1** | Zero-Config Chat | `ConversationView(messages: $messages)` + `.onSendMessage` |
      | **Layer 2** | Structured Input | `.suggestionChips`, `.slashCommands`, `.resourceMentions`, `.composerModels` |
      | **Layer 3** | Style Presets | `.messageComposerStyle`, `.thinkingStateStyle`, `.userMessageBubbleStyle` |
      | **Layer 4** | Custom Domain & Styles | Custom `Message` models & custom `Style` protocol conformances |

      ```swift
      ConversationView(messages: $messages)
        .onSendMessage { submission in
          messages.append(submission.message)
          await generateReply(for: submission)
        }
      ```
      """
    }
  }
}
