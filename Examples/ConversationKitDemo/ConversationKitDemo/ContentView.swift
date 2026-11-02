//
//  ContentView.swift
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

// MARK: - ContentView

struct ContentView: View {
  // MARK: - Conversation State (Default Empty so SuggestionChipsBar is visible on launch)

  @State private var messages: [DefaultMessage] = []
  @State private var attachments: [ConversationAttachment] = []
  @State private var tokens: [ComposerToken] = []

  // MARK: - Composer Models, Capabilities & Styles

  @State private var selectedModel: ComposerModelOption? = Self.availableModels.first
  @State private var activeCapabilities: Set<ComposerCapability> = [.think, .search]
  @State private var composerStyleOption: DemoComposerStyleOption = {
    if ProcessInfo.processInfo.arguments.contains("-cardGlass") {
      return .cardGlass
    }
    if ProcessInfo.processInfo.arguments.contains("-compactGlass") {
      return .compactGlass
    }
    return .classicGlass
  }()

  private var initialUserPrompt: String {
    if let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-prompt"),
       idx + 1 < ProcessInfo.processInfo.arguments.count {
      return ProcessInfo.processInfo.arguments[idx + 1]
    }
    return ""
  }
  @State private var thinkingStyleOption: DemoThinkingStyleOption = .collapsibleHeader
  @State private var bubbleStyleOption: DemoBubbleStyleOption = .tailedBubble
  @State private var simulateUploadProgress: Bool = false
  @State private var isShowingPrototypeLab: Bool = {
    let args = ProcessInfo.processInfo.arguments
    return args.contains("-prototypeLab") || args.contains("-prototype")
  }()

  // MARK: - Static Showcase Catalog (`F-5`, `F-8`, `F-9`)

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
        || lower.contains("sofia")
      {
        return .liquidGlass
      }

      if lower.contains("tool")
        || lower.contains("refactor")
        || lower.contains("plan")
        || lower.contains("approval")
        || lower.contains("thinking")
        || lower.contains("slash")
        || commandTrigger == "code"
      {
        return .agenticTools
      }

      if lower.contains("scroll")
        || lower.contains("deep dive")
        || lower.contains("long")
        || lower.contains("byte")
        || lower.contains("hysteresis")
        || lower.contains("optimistic")
        || lower.contains("stress")
        || commandTrigger == "benchmark"
      {
        return .scrollPhysics
      }

      return .general(turnIndex: max(0, turnCount - 1))
    }
  }

  static let starterSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "liquid-glass",
      title: "Liquid Glass Design",
      prompt: "Explain how ConversationKit v2 uses iOS 26+ Liquid Glass only on floating chrome.",
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
      id: "analyze-pdf",
      title: "Analyze PDF & Spec",
      prompt: "Analyze our PDF specification, citations, and multimodal thumbnail pipeline.",
      symbolName: "doc.richtext",
      category: "Multimodal"
    ),
    PromptSuggestion(
      id: "refactor-tools",
      title: "Run Agent Tool Calls",
      prompt: "Refactor the timeline engine using agentic tool calls, an execution plan, and an approval check.",
      symbolName: "wrench.and.screwdriver",
      category: "Agentic UI"
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
      title: "Show AnchorPreference Menu Fix",
      prompt: "Show how ComposerMenuSlotAnchorKey and .overlayPreferenceValue isolate UIContextMenuInteraction from glass pills.",
      symbolName: "scope",
      category: "Zero-Demotion"
    ),
    PromptSuggestion(
      id: "followup-glass-scroll",
      title: "Explore Scroll Physics",
      prompt: "How does Top-Floating Turn Physics keep ΔY = 0pt while Byte streams downward at 120Hz?",
      symbolName: "arrow.up.and.down.text.horizontal",
      category: "Scroll Physics"
    ),
    PromptSuggestion(
      id: "followup-glass-tools",
      title: "Run Agent Tool Calls",
      prompt: "Refactor the timeline engine using agentic tool calls, an execution plan, and an approval check.",
      symbolName: "wrench.and.screwdriver",
      category: "Agentic UI"
    ),
  ]

  static let scrollPhysicsFollowUpSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "followup-scroll-hysteresis",
      title: "ScrollToBottom Hysteresis",
      prompt: "How does the >80pt / <24pt ScrollToBottom hysteresis deadband prevent button oscillation during streaming?",
      symbolName: "arrow.down.circle",
      category: "Scroll Physics"
    ),
    PromptSuggestion(
      id: "followup-scroll-optimistic",
      title: "Explain Optimistic Turn ID",
      prompt: "Explain how optimisticUserMessage deduplicates by ID in O(1) without frame jumps on keyboard dismissal.",
      symbolName: "bolt.horizontal.circle",
      category: "Concurrency"
    ),
    PromptSuggestion(
      id: "followup-scroll-glass",
      title: "Inspect Liquid Glass Chrome",
      prompt: "Explain how ConversationKit v2 uses iOS 26+ Liquid Glass only on floating chrome.",
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
      title: "QuickLook Path Sanitization",
      prompt: "How does resolveQuickLookURL sanitize path traversal vectors and isolate previews in ConversationKitQuickLook?",
      symbolName: "lock.shield",
      category: "Security"
    ),
    PromptSuggestion(
      id: "followup-multimodal-collage",
      title: "Show Image Collage Layout",
      prompt: "How does MessageAttachmentsView lay out 1 to 4 photo attachments and downsample thumbnails to <= 320px?",
      symbolName: "photo.on.rectangle.angled",
      category: "Multimodal"
    ),
    PromptSuggestion(
      id: "followup-multimodal-tools",
      title: "Run Agent Tool Calls",
      prompt: "Refactor the timeline engine using agentic tool calls, an execution plan, and an approval check.",
      symbolName: "wrench.and.screwdriver",
      category: "Agentic UI"
    ),
    PromptSuggestion(
      id: "followup-multimodal-scroll",
      title: "Test Top-Floating Scroll",
      prompt: "Give me a long architecture deep dive into Top-Floating User Bubbles, Zero-Jitter Streaming, and Byte's packet journey.",
      symbolName: "arrow.up.and.down.text.horizontal",
      category: "Scroll Physics"
    ),
  ]

  static let agenticToolsFollowUpSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "followup-agentic-thinking",
      title: "Explain ThinkingTrace Cadence",
      prompt: "How do ThinkingStateStyle (.collapsibleHeader, .pill, .minimal) and collapsed-by-default reasoning traces work?",
      symbolName: "brain",
      category: "Reasoning"
    ),
    PromptSuggestion(
      id: "followup-agentic-slash",
      title: "Token Sentinel Mechanics",
      prompt: "Explain how ComposerTextBuffer uses U+200B zero-width sentinels for two-stage /command and @mention backspace removal.",
      symbolName: "command",
      category: "Structured Input"
    ),
    PromptSuggestion(
      id: "followup-agentic-glass",
      title: "Compare Composer Glass Styles",
      prompt: "Compare ClassicGlass, CardGlass, and CompactGlass composer styles and how .interactive() breathes on touch-down.",
      symbolName: "sparkles",
      category: "Liquid Glass"
    ),
    PromptSuggestion(
      id: "followup-agentic-pdf",
      title: "Inspect Multimodal Security",
      prompt: "Analyze our PDF specification, citations, and multimodal thumbnail pipeline.",
      symbolName: "doc.richtext",
      category: "Multimodal"
    ),
  ]

  static let generalFollowUpSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "followup-general-stratos",
      title: "Progressive Disclosure API",
      prompt: "Walk through ConversationKit v2's 4-layer Progressive Disclosure API from zero-config to custom Style protocols.",
      symbolName: "layers.3.down.forward",
      category: "SDK Design"
    ),
    PromptSuggestion(
      id: "followup-general-glass",
      title: "Liquid Glass Design",
      prompt: "Explain how ConversationKit v2 uses iOS 26+ Liquid Glass only on floating chrome.",
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
      title: "Run Agent Tool Calls",
      prompt: "Refactor the timeline engine using agentic tool calls, an execution plan, and an approval check.",
      symbolName: "wrench.and.screwdriver",
      category: "Agentic UI"
    ),
  ]

  private var currentSuggestionChips: [PromptSuggestion] {
    guard let lastUserMessage = messages.last(where: { $0.participant == .user }) else {
      return Self.starterSuggestions
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
      return Self.liquidGlassFollowUpSuggestions
    case .scrollPhysics:
      return Self.scrollPhysicsFollowUpSuggestions
    case .multimodal:
      return Self.multimodalFollowUpSuggestions
    case .agenticTools:
      return Self.agenticToolsFollowUpSuggestions
    case .general:
      return Self.generalFollowUpSuggestions
    }
  }

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
      description: "Verify 120Hz ProMotion frame pacing and Delta Y = 0pt",
      symbolName: "gauge.with.dots.needle.67percent",
      category: "Performance"
    ),
    SlashCommand(
      id: "explain",
      trigger: "explain",
      title: "Explain architecture",
      description: "Walk through Stratos Progressive Disclosure layers",
      symbolName: "sparkles",
      category: "Architecture"
    ),
  ]

  static let availableMentions: [ResourceMention] = [
    ResourceMention(
      id: "PRD-0001.md",
      queryHandle: "PRD-0001.md",
      title: "PRD-0001.md",
      subtitle: "docs/specs/PRD-0001-conversationkit-v2.md",
      symbolName: "doc.text",
      kind: .document
    ),
    ResourceMention(
      id: "ADR-0001.md",
      queryHandle: "ADR-0001.md",
      title: "ADR-0001.md",
      subtitle: "docs/architecture/ADR-0001-conversationkit-v2-architecture.md",
      symbolName: "building.columns",
      kind: .document
    ),
    ResourceMention(
      id: "ConversationView.swift",
      queryHandle: "ConversationView.swift",
      title: "ConversationView.swift",
      subtitle: "Sources/ConversationKit/Views/Timeline/ConversationView.swift",
      symbolName: "swift",
      kind: .file
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

  // MARK: - Body

  var body: some View {
    if isShowingPrototypeLab {
      LiquidGlassPrototypeLabView {
        withAnimation(.snappy(duration: 0.25)) {
          isShowingPrototypeLab = false
        }
      }
    } else {
      NavigationStack {
        ConversationView(messages: $messages, attachments: $attachments, userPrompt: initialUserPrompt)
          .onSendMessage { submission in
            await handleSubmission(submission)
          }
          .suggestionChips(currentSuggestionChips)
          .slashCommands(Self.availableCommands)
          .resourceMentions(Self.availableMentions)
          .composerModels(Self.availableModels, selection: $selectedModel)
          .composerCapabilities([.think, .search, .image], active: $activeCapabilities)
          .composerTokens($tokens)
          .messageComposerStyle(composerStyleOption.anyStyle)
          .thinkingStateStyle(thinkingStyleOption.anyStyle)
          .userMessageBubbleStyle(bubbleStyleOption.anyStyle)
          .emptyConversationView {
            emptyShowcasePlaceholder
          }
          .attachmentActions {
            Button("Sample Diagram Image", systemImage: "photo") {
              attachSampleImage()
            }
            Button("Sample Architecture PDF", systemImage: "doc.richtext") {
              attachSamplePDF()
            }
            Button("Sample Swift Source File", systemImage: "chevron.left.forwardslash.chevron.right") {
              attachSampleSwiftFile()
            }
            Button("Simulate Uploading Attachment", systemImage: "arrow.up.doc") {
              attachSimulatedUploadingFile()
            }
          }
          .onApprovalDecision { request, decision in
            resolveApproval(request: request, decision: decision)
          }
          .onToolCallRetry { failedToolCall in
            await retryToolCall(failedToolCall)
          }
          .onMessageFeedback { messageID, feedback in
            updateFeedback(for: messageID, feedback: feedback)
          }
          .onRegenerateMessage { messageID in
            await regenerateMessage(id: messageID)
          }
          .onRetryMessage { messageID in
            await regenerateMessage(id: messageID)
          }
          .navigationTitle("ConversationKit v2")
          #if os(iOS)
          .navigationBarTitleDisplayMode(.inline)
          #endif
          .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
              prototypeLabButton
              styleAndSamplesMenu
              resetConversationButton
            }
          }
      }
    }
  }

  // MARK: - Empty State & Toolbar Controls

  private var emptyShowcasePlaceholder: some View {
    VStack(spacing: 14) {
      Image(systemName: "bubble.left.and.text.bubble.right")
        .font(.system(size: 40, weight: .semibold))
        .foregroundStyle(.tint)
        .padding(16)
        .background(Color.accentColor.opacity(0.12), in: Circle())

      Text("What would you like to explore?")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)

      Text("Pick a suggestion below, or type / for commands and @ to mention files.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 420)
    }
    .padding(.vertical, 24)
  }

  private var styleAndSamplesMenu: some View {
    Menu {
      Section("Composer Style (F-6)") {
        Picker("Composer Style", selection: $composerStyleOption) {
          ForEach(DemoComposerStyleOption.allCases) { option in
            Label(option.rawValue, systemImage: option.symbolName)
              .tag(option)
          }
        }
      }

      Section("Thinking Style (F-7)") {
        Picker("Thinking Style", selection: $thinkingStyleOption) {
          ForEach(DemoThinkingStyleOption.allCases) { option in
            Text(option.rawValue).tag(option)
          }
        }
      }

      Section("User Bubble Style (F-3)") {
        Picker("User Bubble Style", selection: $bubbleStyleOption) {
          ForEach(DemoBubbleStyleOption.allCases) { option in
            Text(option.rawValue).tag(option)
          }
        }
      }

      Section("Quick Sample Attachments (F-4)") {
        Button("Attach Sample Image", systemImage: "photo") {
          attachSampleImage()
        }
        Button("Attach Sample PDF", systemImage: "doc.richtext") {
          attachSamplePDF()
        }
        Button("Attach Sample Swift Code", systemImage: "chevron.left.forwardslash.chevron.right") {
          attachSampleSwiftFile()
        }
        Button("Simulate Upload Progress Ring", systemImage: "clock.arrow.2.circlepath") {
          attachSimulatedUploadingFile()
        }
      }

      Section("Liquid Glass Review Lab") {
        Button("Liquid Glass Prototype Lab", systemImage: "flask.fill") {
          withAnimation(.snappy(duration: 0.25)) {
            isShowingPrototypeLab = true
          }
        }
      }
    } label: {
      Label("Composer Style", systemImage: "slider.horizontal.3")
    }
    .accessibilityIdentifier("demo.styleMenu")
  }

  private var prototypeLabButton: some View {
    Button {
      withAnimation(.snappy(duration: 0.25)) {
        isShowingPrototypeLab = true
      }
    } label: {
      Label("Liquid Glass Prototype Lab", systemImage: "flask")
    }
    .accessibilityIdentifier("demo.prototypeLabButton")
  }

  private var resetConversationButton: some View {
    Button {
      withAnimation(.snappy(duration: 0.25)) {
        messages.removeAll()
        attachments.removeAll()
        tokens.removeAll()
      }
    } label: {
      Label("New Chat", systemImage: "square.and.pencil")
    }
    .accessibilityIdentifier("demo.resetButton")
  }

  // MARK: - Sample Attachment Builders (`F-4`, `AC-6`, `AC-7`)

  private func attachSampleImage() {
    guard let imageBox = PlatformImageBox.solidColor(
      red: 0.16,
      green: 0.48,
      blue: 0.92,
      size: CGSize(width: 480, height: 320)
    ) else { return }

    let attachment = ConversationAttachment(
      imageBox: imageBox,
      filename: "LiquidGlass-Architecture.png",
      uploadState: .ready
    )
    attachments.append(attachment)
  }

  private func attachSamplePDF() {
    let pdfData = Self.makeSamplePDFData()
    let attachment = ConversationAttachment(
      data: pdfData,
      contentType: .pdf,
      filename: "ADR-0001-Architecture.pdf",
      uploadState: .ready
    )
    attachments.append(attachment)
  }

  private func attachSampleSwiftFile() {
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
    let attachment = ConversationAttachment(
      data: Data(swiftSource.utf8),
      contentType: .swiftSource,
      filename: "ChatScreen.swift",
      uploadState: .ready
    )
    attachments.append(attachment)
  }

  private func attachSimulatedUploadingFile() {
    let id = UUID().uuidString
    let pdfData = Self.makeSamplePDFData()
    let uploading = ConversationAttachment(
      id: id,
      data: pdfData,
      contentType: .pdf,
      filename: "Spec-Upload-Demo.pdf",
      uploadState: .uploading(progress: 0.1)
    )
    attachments.append(uploading)

    Task { @MainActor in
      for step in 2...10 {
        try? await Task.sleep(for: .milliseconds(180))
        guard let index = attachments.firstIndex(where: { $0.id == id }) else { return }
        if step < 10 {
          attachments[index].uploadState = .uploading(progress: Double(step) / 10.0)
        } else {
          attachments[index].uploadState = .ready
        }
      }
    }
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

  // MARK: - Turn Submission & Cooperative Streaming (`F-1`, `F-2`, `F-7`, `F-10`)

  @MainActor
  private func handleSubmission(_ submission: ConversationSubmission<DefaultMessage>) async {
    // 1. Immediately append the exact user message (preserving submission.message.id for Optimistic UI deduplication)
    messages.append(submission.message)

    let turnCount = messages.filter { $0.participant == .user }.count
    let topic = DemoResponseTopic.resolve(
      from: submission.text,
      commandTrigger: submission.command?.trigger,
      hasAttachments: !submission.attachments.isEmpty,
      turnCount: turnCount
    )

    let lowerPrompt = submission.text.lowercased()
    let hasRefactorOrTools = topic == .agenticTools
      || lowerPrompt.contains("refactor")
      || lowerPrompt.contains("tool")
      || submission.command?.trigger == "code"
      || submission.command?.trigger == "benchmark"

    let responseID = UUID().uuidString
    let startedAt = Date.now
    let initialTrace = makeInitialThinkingTrace(for: topic, startedAt: startedAt)

    // 2. Start assistant turn with active ThinkingTrace (collapsed by default per F-7 & AC-11)
    var assistantMessage = DefaultMessage(
      id: responseID,
      content: nil,
      participant: .other,
      selectedModelID: submission.selectedModel?.id,
      thinkingTrace: initialTrace,
      toolCalls: hasRefactorOrTools
        ? [
          ToolCall(
            id: "tool-search-\(responseID)",
            name: "search_workspace_symbols",
            symbolName: "magnifyingglass",
            status: .running(startedAt: startedAt),
            argumentsSummary: "query: \"ConversationView activeTurnMinHeight\"",
            argumentsJSON: "{\n  \"query\": \"ConversationView activeTurnMinHeight\",\n  \"scope\": \"Sources/ConversationKit\"\n}"
          )
        ]
        : [],
      isStreaming: true
    )
    messages.append(assistantMessage)

    do {
      try await Task.sleep(for: .milliseconds(320))
      try Task.checkCancellation()

      // Complete thinking trace and update tool calls / plan if active
      assistantMessage.thinkingTrace = makeCompletedThinkingTrace(
        id: assistantMessage.thinkingTrace?.id ?? UUID().uuidString,
        for: topic
      )

      if hasRefactorOrTools {
        assistantMessage.toolCalls = [
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
            resultSummary: "0 glass violations inside scrolling cells (AC-10)"
          ),
        ]

        assistantMessage.plan = AgentPlan(
          title: "ConversationKit v2 Verification Plan",
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

        assistantMessage.approvalRequest = ApprovalRequest(
          title: "Export 120Hz Scroll Benchmark Trace",
          detail: "Allow the agent to write the frame-pacing benchmark report to the temporary workspace directory?",
          riskLevel: .low,
          scopeIdentifier: "benchmark.export",
          changePreview: "swift test --filter ConversationTurnPhysicsTests",
          decision: .pending
        )
      }

      updateMessage(assistantMessage)

      // 3. Stream a rich topic-specific multi-paragraph + fenced code block Markdown response (>1.5x viewport height)
      let fullMarkdown = buildResponseMarkdown(
        for: submission,
        topic: topic,
        turnCount: turnCount
      )
      var accumulated = ""
      let characters = Array(fullMarkdown)
      let chunkSize = 18

      for chunkStart in stride(from: 0, to: characters.count, by: chunkSize) {
        try Task.checkCancellation()
        let chunkEnd = min(chunkStart + chunkSize, characters.count)
        accumulated.append(contentsOf: characters[chunkStart..<chunkEnd])
        assistantMessage.content = accumulated
        updateMessage(assistantMessage)
        try await Task.sleep(for: .milliseconds(28))
      }

      // 4. Settle streaming state and attach topic-specific allowlisted citations
      assistantMessage.isStreaming = false
      assistantMessage.citations = makeCitations(for: topic)
      updateMessage(assistantMessage)
    } catch is CancellationError {
      // Cooperative cancellation when user taps the Stop button
      assistantMessage.isStreaming = false
      if case .thinking = assistantMessage.thinkingTrace?.status {
        assistantMessage.thinkingTrace?.status = .cancelled(
          duration: max(0.1, Date.now.timeIntervalSince(startedAt))
        )
      }
      updateMessage(assistantMessage)
    } catch {
      assistantMessage.isStreaming = false
      assistantMessage.messageError = MessageError(
        message: error.localizedDescription,
        isRetryable: true
      )
      updateMessage(assistantMessage)
    }
  }

  private func makeInitialThinkingTrace(
    for topic: DemoResponseTopic,
    startedAt: Date
  ) -> ThinkingTrace {
    switch topic {
    case .liquidGlass:
      return ThinkingTrace(
        status: .thinking(startedAt: startedAt),
        summary: "Inspecting iOS 26+ Liquid Glass chrome & AnchorPreference slots…",
        transcript: """
        1. Auditing .safeAreaBar(edge: .bottom) floating chrome budget.
        2. Checking 3-zone bookend sibling hierarchy inside GlassEffectContainer.
        3. Verifying ComposerMenuSlotAnchorKey overlay isolation for Menu hit-testing.
        """
      )
    case .scrollPhysics:
      return ThinkingTrace(
        status: .thinking(startedAt: startedAt),
        summary: "Computing unoccluded viewport runway & 120Hz frame pacing…",
        transcript: """
        1. Locked activeTurnMinHeight to unoccluded viewport runway.
        2. Verified user bubble top-edge anchor (Delta Y = 0pt).
        3. Simulating Byte's downward token stream without per-token scrollTo calls.
        """
      )
    case .multimodal:
      return ThinkingTrace(
        status: .thinking(startedAt: startedAt),
        summary: "Inspecting thumbnail downsampling & QuickLook sandbox…",
        transcript: """
        1. Verifying CGImageSource / QLThumbnailGenerator off-main-actor pipeline (<= 320px).
        2. Auditing path-traversal sanitization inside ConversationKitQuickLook.
        3. Preparing 1–4 photo collage layout and attachment upload state machine.
        """
      )
    case .agenticTools:
      return ThinkingTrace(
        status: .thinking(startedAt: startedAt),
        summary: "Coordinating agentic tool calls, execution plan & approval gates…",
        transcript: """
        1. Dispatching workspace symbol search & Liquid Glass budget audit tools.
        2. Constructing multi-step AgentPlan progress tracker.
        3. Preparing human-in-the-loop ApprovalRequest card.
        """
      )
    case .general(let turnIndex):
      return ThinkingTrace(
        status: .thinking(startedAt: startedAt),
        summary: "Synthesizing turn #\(turnIndex + 1) architectural response…",
        transcript: """
        1. Evaluating Stratos 4-layer Progressive Disclosure API surface.
        2. Checking Swift 6 strict concurrency & @MainActor isolation invariants.
        3. Formatting incremental Markdown blocks and syntax-highlighted Swift code.
        """
      )
    }
  }

  private func makeCompletedThinkingTrace(
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
        1. Confirmed Liquid Glass is restricted strictly to floating chrome (AC-10).
        2. Verified .glassEffect(..., in:).interactive() touch-down inflation in C++/Metal.
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
        2. Confirmed single-shot proxy.scrollTo(newTurnID, anchor: .top) with Delta Y = 0pt.
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
        2. Sanitized QuickLook preview paths against .., /, \\, :, and NUL bytes.
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
        summary: "Synthesized turn #\(turnIndex + 1) Swift 6 & Stratos SDK overview",
        transcript: """
        1. Mapped Troposphere -> Stratosphere -> Mesosphere -> Exosphere API layers.
        2. Verified O(1) DefaultMessage equality diffing and U+200B token sentinels.
        3. Committed AST Markdown blocks for 120Hz ProMotion rendering.
        """
      )
    }
  }

  private func makeCitations(for topic: DemoResponseTopic) -> [Citation] {
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
          title: "ConversationView Top-Floating Turn Physics (ADR-0001)",
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
          title: "ConversationKit v2 Progressive Disclosure Guide",
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

  private func buildResponseMarkdown(
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

        \(mentionsSummary)\(attachmentsNote)**ConversationKit v2** ships three interchangeable `MessageComposerStyle` presets inside `.safeAreaBar(edge: .bottom)` so your app can match Apple Messages, multi-row AI workspaces, or ultra-dense utility sheets while **Byte** streams tokens above.

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
              .composerModels(ContentView.availableModels, selection: $selectedModel)
              .messageComposerStyle(.cardGlass) // or .classicGlass / .compactGlass
              .thinkingStateStyle(.collapsibleHeader)
              .userMessageBubbleStyle(.tailedBubble)
          }
        }
        ```

        #### Why `.interactive()` Never Uses Manual Scale Hacks
        1. **Native Shader Refraction:** Calling `.glassEffect(.regular.interactive(), in: shape)` activates hardware-accelerated specular edge catch and elastic inflation on finger-down.
        2. **Zero Custom Gesture Interference:** Avoiding custom `DragGesture(minimumDistance: 0)` wrappers ensures `TextField` cursor placement, text selection loupe, and `Menu` presentation work without responder conflicts.
        """
      } else if lower.contains("anchor") || lower.contains("overlay") || lower.contains("demotion") {
        return """
        ### \(commandPrefix)Zero-Demotion `Menu` Isolation via `ComposerMenuSlotAnchorKey` (\(modelName))

        \(mentionsSummary)\(attachmentsNote)When a UIKit-backed `Menu` (`UIContextMenuInteraction`) is placed *inside* a view subtree that also has `.glassEffect(..., in:)`, UIKit's targeted preview snapshotter temporarily hides the source view during menu morphing—which would cause the entire glass pill to vanish while the menu is open while **Byte** is streaming.

        #### How `ConversationKit` Solves This Canonically
        1. **Visual Glass Pill Stays Pure:** The visible `32×32pt` circular slot inside `ClassicGlass` renders a decorative `Image(systemName: "sparkles")` with `.allowsHitTesting(false)` and reports its bounds via `.anchorPreference(key: ComposerMenuSlotAnchorKey.self, value: .bounds)`.
        2. **Overlay Hosts the Interactive `Menu`:** `.overlayPreferenceValue(ComposerMenuSlotAnchorKey.self)` resolves the exact `CGRect` via `GeometryReader` *outside* the `.glassEffect` view hierarchy and positions the interactive `Menu` right over the icon slot.

        ```swift
        // Visual slot inside the .glassEffect(.regular.interactive(), in: shape) pill:
        Image(systemName: "sparkles")
          .font(.system(size: 14, weight: .semibold))
          .frame(width: 32, height: 32)
          .allowsHitTesting(false)
          .anchorPreference(key: ComposerMenuSlotAnchorKey.self, value: .bounds) {
            [ComposerMenuSlotID.compactModel: $0]
          }

        // Interactive Menu mounted outside the .glassEffect subtree:
        .overlayPreferenceValue(ComposerMenuSlotAnchorKey.self) { anchors in
          GeometryReader { proxy in
            if let anchor = anchors[.compactModel] {
              let rect = proxy[anchor]
              configuration.compactModelSelector
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
            }
          }
        }
        ```

        * **Result:** Tapping the model selector opens the native iOS 26 `Menu` while the Liquid Glass composer pill stays `100%` visible and refractive underneath!
        """
      } else {
        return """
        ### \(commandPrefix)iOS 26+ Liquid Glass Chrome Architecture (\(modelName))

        \(mentionsSummary)\(attachmentsNote)**ConversationKit v2** enforces Apple's Human Interface Guidelines for **Liquid Glass**: glass materials are used exclusively on floating chrome over scrolling content—never on scrolling timeline cells where **Byte** renders Markdown paragraphs.

        > **Golden Rule (`AC-10`):** Content lives in opaque/tinted semantic surfaces (`Color.platformUserBubbleFill`, `Color.platformSecondaryBackground`); floating controls live inside `GlassEffectContainer` within `.safeAreaBar(edge: .bottom)`.

        #### 1. Canonical 3-Zone Bookend Grammar (`ClassicGlass`)
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
      if lower.contains("hysteresis") || lower.contains("scrolltobottom") {
        return """
        ### \(commandPrefix)`ScrollToBottomButton` Deadband Hysteresis (`F-10`, `AC-14`) (\(modelName))

        \(mentionsSummary)\(attachmentsNote)A naive `distanceFromBottom > threshold` check oscillates rapidly when **Byte** streams tokens near the fold or when rubber-banding at the bottom edge. **ConversationKit v2** solves this with a deterministic two-threshold hysteresis state machine.

        > **Hysteresis Invariant:** Show only when `distanceFromBottom > 80pt`; hide only when `distanceFromBottom < 24pt`; retain the current state inside the `24pt...80pt` deadband.

        | Current State | `distanceFromBottom` | Next State | Reason |
        | --- | --- | --- | --- |
        | `false` (Hidden) | `0pt ... 80pt` | `false` | Suppresses micro-scroll flicker |
        | `false` (Hidden) | `> 80pt` | `true` | User scrolled away or stream overflowed |
        | `true` (Visible) | `24pt ... 80pt` | `true` | Deadband prevents edge chattering |
        | `true` (Visible) | `< 24pt` | `false` | Reached bottom anchor cleanly |

        ```swift
        public enum ScrollToBottomButton {
          public static func shouldShow(
            currentState: Bool,
            distanceFromBottom: CGFloat
          ) -> Bool {
            if currentState {
              return distanceFromBottom >= 24
            } else {
              return distanceFromBottom > 80
            }
          }
        }
        ```

        #### Zero-Whitespace Bottom Anchor (`F-06`)
        Instead of appending a standalone `1pt` view inside `LazyVStack(spacing: 24)` (which would inject `25pt` of dead space at the bottom of the timeline), `ConversationView` attaches `Self.bottomAnchorID` via `.background(alignment: .bottom)` directly on the `LazyVStack`.
        """
      } else if lower.contains("optimistic") {
        return """
        ### \(commandPrefix)Optimistic Turn ID Deduplication & Zero-Jump Submission (\(modelName))

        \(mentionsSummary)\(attachmentsNote)Because `ConversationView` does not own your `messages` array, waiting for an `async` `.onSendMessage` closure to append the user's message would introduce a 1-frame layout gap after keyboard dismissal—breaking top-edge scroll anchoring while **Byte** prepares to stream.

        #### How the Optimistic Turn Engine Works (`[MF-3]`, `AC-19`)
        1. **Synchronous Minting:** When you tap Send, `ConversationView` synchronously constructs `MessageType.makeUserMessage(id: newTurnID, ...)` and stores it in `@State private var optimisticUserMessage`.
        2. **Same-Frame Top Scroll:** `displayedMessages` combines `messages` + `optimisticUserMessage` in $O(1)$ using a `Set<String>` of message IDs, allowing `proxy.scrollTo(newTurnID, anchor: .top)` to anchor in the exact same transaction as keyboard dismissal.
        3. **Seamless Handoff:** Once your `.onSendMessage` handler appends `submission.message` (preserving `submission.message.id`), `ConversationView` clears `optimisticUserMessage` with zero duplicate rows or layout jumps.

        ```swift
        ConversationView(messages: $messages)
          .onSendMessage { submission in
            // Preserves submission.message.id so O(1) deduplication is seamless:
            messages.append(submission.message)
            await streamAssistantReply(for: submission)
          }
        ```
        """
      } else {
        return """
        ### \(commandPrefix)Top-Floating Turn Physics & Byte's 120Hz Journey (\(modelName))

        \(mentionsSummary)\(attachmentsNote)When you submit a prompt, **ConversationKit v2** groups messages into deterministic `ConversationTurn` containers and anchors your user bubble at the top of the unoccluded viewport runway (`anchor: .top`, `ΔY = 0pt`).

        #### 1. Byte's Journey Through the Unoccluded Runway (`F-1`, `F-2`)
        Once upon a time in a 120Hz ProMotion render loop, a tiny packet of tokens named **Byte** traveled from the model stream into `ConversationView`. Instead of triggering per-token `scrollTo` calls that cause layout jitter, Byte flowed smoothly downward inside the active turn's pre-allocated runway while your prompt stayed rock-solid at the top of the screen.

        * **Single-Shot Top Scroll (`AC-3`):** `proxy.scrollTo(newTurnID, anchor: .top)` fires *only once* when a turn is submitted—never during token streaming.
        * **Locked Unoccluded Height (`[MF-3]`):** `activeTurnMinHeight` locks to `max(lockedUnoccludedHeight, 320)` so software keyboard dismissal never shrinks the active turn's runway.
        * **O(1) Incremental Markdown (`F-3`, `AC-17`):** Settled paragraphs, tables, and fenced code blocks lock their `MarkdownBlock.id` while only the trailing unfinished block re-parses.

        | Benchmark Metric | Target Budget | Measured (`ConversationKit` v2) |
        | --- | --- | --- |
        | User Bubble Drift (`ΔY`) | `0.0 pt` | `0.0 pt` across 220 blocks |
        | 100-Step Incremental Parse | `< 8.33 ms / step` | `~0.42 ms / step` |
        | 10,000 `DefaultMessage` Diffs | `< 50.0 ms` | `~4.8 ms` ($O(1)$ fast-path) |

        ```swift
        @ViewBuilder
        private func turnContainerView(
          for turn: ConversationTurn<MessageType>,
          isLastTurn: Bool
        ) -> some View {
          let turnStack = VStack(alignment: .leading, spacing: 16) {
            if let userMessage = turn.userMessage {
              content(userMessage)
            }
            ForEach(turn.assistantMessages) { assistantMessage in
              content(assistantMessage)
            }
          }
          .frame(maxWidth: .infinity, alignment: .topLeading)

          if isLastTurn {
            turnStack.frame(minHeight: activeTurnMinHeight, alignment: .top)
          } else {
            turnStack
          }
        }
        ```
        """
      }

    case .multimodal:
      if lower.contains("quicklook") || lower.contains("sanitize") || lower.contains("security") {
        return """
        ### \(commandPrefix)Sandboxed QuickLook Path Sanitization (`AC-7`, `[MF-2]`) (\(modelName))

        \(mentionsSummary)\(attachmentsNote)When previewing PDFs, images, or source files with `.quickLookPreview`, untrusted filenames from remote APIs or drag-and-drop payloads must never escape the temporary preview directory while **Byte** renders the timeline.

        > **Security Invariant:** `PlatformThumbnailGenerator.sanitizeFilename(_:)` strips directory components, `..` traversal sequences, `/`, `\\`, `:`, and `\0` bytes before materializing files inside `FileManager.default.temporaryDirectory/ConversationKitQuickLook/`.

        | Adversarial Input | Sanitized Component | Contained Inside QuickLook Dir? |
        | --- | --- | --- |
        | `../../etc/passwd` | `passwd` | Yes (`100%` confined) |
        | `foo/bar:baz\0.pdf` | `bar_baz.pdf` | Yes (`100%` confined) |
        | `...` or `""` | `attachment.bin` | Yes (`100%` confined) |

        ```swift
        let resolvedURL = try await attachment.resolveQuickLookURL()
        // Guaranteed to reside strictly inside temporaryDirectory/ConversationKitQuickLook/
        ```

        #### URL Scheme Allowlist (`AC-18`)
         Similarly, `Citation.sanitizedURL` and `URL.isAllowedConversationURL` allow only `http` and `https` URLs with a non-empty `.host`, rejecting `javascript:`, `data:`, and `file:` schemes case-insensitively.
        """
      } else {
        return """
        ### \(commandPrefix)Multimodal Attachment Pipeline & Off-Main-Actor Thumbnails (\(modelName))

        \(mentionsSummary)\(attachmentsNote)**ConversationKit v2** provides a complete multimodal pipeline (`ConversationAttachment`) supporting photos, PDFs, code files, audio, and documents—all while keeping the `@MainActor` UI thread free for **Byte**'s 120Hz streaming.

        #### 1. Off-Main-Actor Downsampling (`PlatformThumbnailGenerator`)
        * **Memory-Safe `<= 320px` Thumbnails:** Large 12MP photos and multi-page PDFs are downsampled off the main actor via `CGImageSourceCreateThumbnailAtIndex` and `QLThumbnailGenerator`, then cached in an actor-isolated LRU cache keyed by `(id, maxPixelSize)`.
        * **Adaptive `1–4` Photo Collage (`MessageAttachmentsView`):** User bubbles automatically arrange 1, 2, 3, or 4 image attachments into a proportional grid and group PDFs/code files into tappable QuickLook document cards.
        * **Submission Gating (`AC-6`):** Composer submission stays disabled while any attachment is in `.uploading(progress:)` or `.failed(error:)`.

        ```swift
        let pdfAttachment = ConversationAttachment(
          data: pdfData,
          contentType: .pdf,
          filename: "ADR-0001-Architecture.pdf",
          uploadState: .uploading(progress: 0.45)
        )
        // Composer submit button automatically waits until uploadState == .ready
        ```

        > Tip: Open the **`+`** menu in the composer or the toolbar slider menu to attach a sample image, PDF, Swift file, or simulated upload progress ring!
        """
      }

    case .agenticTools:
      if lower.contains("thinking") || lower.contains("cadence") {
        return """
        ### \(commandPrefix)`ThinkingStateStyle` & Collapsed-by-Default Reasoning (`F-7`, `AC-11`) (\(modelName))

        \(mentionsSummary)\(attachmentsNote)Reasoning models emit multi-step chain-of-thought traces before **Byte** streams the final answer. **ConversationKit v2** renders `ThinkingTrace` collapsed by default (`ThinkingTrace.defaultExpanded == false`) so reasoning never pushes the answer off-screen.

        | `ThinkingStateStyle` | Visual Presentation | Ideal Use Case |
        | --- | --- | --- |
        | `.collapsibleHeader` | Expandable disclosure row with live timer & transcript | Coding & research assistants |
        | `.pill` | Compact tinted capsule with status badge | Consumer chat interfaces |
        | `.minimal` | Single-line subtle status label | High-density multi-turn threads |

        ```swift
        ConversationView(messages: $messages)
          .thinkingStateStyle(.collapsibleHeader) // or .pill / .minimal
        ```

        * **Interactive Disclosure:** Tap the **Thought for 1.4s** header above this message to expand or collapse the step-by-step reasoning transcript!
        """
      } else if lower.contains("sentinel") || lower.contains("u+200b") || lower.contains("slash") || lower.contains("token") {
        return """
        ### \(commandPrefix)Zero-Width Sentinel (`\\u{200B}`) Token Mechanics (`F-5`, `AC-8`, `AC-9`) (\(modelName))

        \(mentionsSummary)\(attachmentsNote)Native SwiftUI `TextField` does not emit a key event when the user presses Backspace on an empty string. To support two-stage backspace removal of `/command` and `@mention` tokens without dropping down to `UITextView`, `ComposerTextBuffer` maintains a single leading `\u{200B}` zero-width space sentinel whenever `hasTokens == true` while **Byte** awaits submission.

        1. **First Backspace on Empty Draft:** Deletes the leading `\u{200B}` sentinel -> `ComposerTextBuffer.applyEdit` detects the transition from `"\u{200B}"` to `""`, highlights the last `ComposerToken`, and immediately restores `"\u{200B}"`.
        2. **Second Consecutive Backspace:** Deletes the restored `"\u{200B}"` while a token is highlighted -> removes the token cleanly!
        3. **Zero Sentinel Leakage (`[MF-4]`):** `ComposerTextBuffer.cleanText(_:)` strips `\u{200B}` globally across the entire string so pasted text and submitted prompts never contain zero-width characters.

        ```swift
        var buffer = ComposerTextBuffer(text: "", hasTokens: true)
        // Stage 1 backspace -> .highlightToken(lastToken.id)
        // Stage 2 backspace -> .removeToken(lastToken.id)
        ```
        """
      } else {
        return """
        ### \(commandPrefix)Agentic Execution: Tool Calls, Plans & Human-in-the-Loop Approvals (\(modelName))

        \(mentionsSummary)\(attachmentsNote)Above this Markdown stream, **ConversationKit v2** rendered four first-class agentic primitives inside the active turn while **Byte** kept your user prompt anchored at `ΔY = 0pt`:

        1. **`ThinkingStateView` (`F-7`):** Collapsed-by-default reasoning disclosure showing elapsed duration and expandable chain-of-thought transcript.
        2. **`ToolCallsGroupView` (`F-7`):** Expandable group of `ToolCall` invocations (`search_workspace_symbols`, `verify_liquid_glass_budget`) with JSON argument/result inspection and `.onToolCallRetry` support.
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

        > Try tapping **Allow Once** on the approval card above—watch the 3rd step in `ConversationKit v2 Verification Plan` transition from in-progress to completed!
        """
      }

    case .general(let turnIndex):
      let variant = turnIndex % 3
      switch variant {
      case 0:
        return """
        ### \(commandPrefix)Stratos 4-Layer Progressive Disclosure API (\(modelName))

        \(mentionsSummary)\(attachmentsNote) You sent: *"\(submission.text)"*. **ConversationKit v2** is architected around **Progressive Disclosure** so you can start with 5 lines of code and scale up to full agentic workflows while **Byte** streams tokens at 120Hz.

        | Layer | Name | Entry Point |
        | --- | --- | --- |
        | **Layer 1** | Troposphere | `ConversationView(messages: $messages)` + `.onSendMessage` |
        | **Layer 2** | Stratosphere | `.suggestionChips`, `.slashCommands`, `.resourceMentions`, `.composerModels` |
        | **Layer 3** | Mesosphere | `.messageComposerStyle`, `.thinkingStateStyle`, `.userMessageBubbleStyle` |
        | **Layer 4** | Exosphere | Custom `Message` domain structs & custom `Style` protocol conformances |

        ```swift
        // Layer 1 (Troposphere): Zero-configuration chat in 5 lines of Swift
        ConversationView(messages: $messages)
          .onSendMessage { submission in
            messages.append(submission.message)
            await generateReply(for: submission)
          }
        ```

        * **Follow-up Chips:** Notice how the suggestion chips below the timeline automatically updated to contextual follow-up prompts once streaming completed!
        """
      case 1:
        return """
        ### \(commandPrefix)Swift 6 Strict Concurrency & $O(1)$ Equality Diffing (\(modelName))

        \(mentionsSummary)\(attachmentsNote)In response to *"\(submission.text)"*: every model and view in **ConversationKit v2** compiles under **Swift 6 strict concurrency** (`Sendable` value types + `@MainActor`-isolated views) so **Byte** can stream tokens at 120Hz without data races or frame drops.

        #### Fast-Path $O(1)$ `Equatable` on `DefaultMessage` (`[MF-4]`)
        * Naive synthesized `Equatable` on a message containing a `5 MB` attachment `Data` buffer and a `100 KB` Markdown string would perform megabytes of byte-by-byte comparisons on every 60Hz token tick.
        * `DefaultMessage`, `ThinkingTrace`, and `ToolCall` compare `id`, `utf8.count`, status discriminants, and precomputed content fingerprints first—completing **10,000 equality checks in `< 5 ms`**.

        ```swift
        // Cooperative cancellation works out of the box when tapping Stop:
        for chunk in tokenStream {
          try Task.checkCancellation()
          assistantMessage.content = (assistantMessage.content ?? "") + chunk
          updateMessage(assistantMessage)
        }
        ```
        """
      default:
        return """
        ### \(commandPrefix)Cross-Platform Chameleon Architecture: iOS 26, iPadOS 26 & macOS 26 (\(modelName))

        \(mentionsSummary)\(attachmentsNote)Exploring *"\(submission.text)"*: **ConversationKit v2** shares a single declarative SwiftUI codebase across iOS 26+, iPadOS 26+, and macOS 26+ while **Byte** keeps your active turn pinned at the top of the viewport.

        * **`PlatformTypes.swift` Chameleon Layer:** Centralizes `UIImage` / `NSImage` (`PlatformImageBox`), pasteboard access (`PlatformPasteboard`), haptics (`PlatformHaptics`), and dynamic semantic colors without scattering `#if os(iOS)` across view bodies.
        * **Incremental Block-Committed Markdown (`MarkdownBlock.parse`):** Headings, blockquotes, task lists, tables, and syntax-highlighted code blocks commit with stable IDs as soon as a double-newline or closing fence arrives.

        ```swift
        // Custom UserMessageBubbleStyle conformance:
        struct BrandedBubbleStyle: UserMessageBubbleStyle {
          func makeBody(configuration: Configuration) -> some View {
            configuration.content
              .padding(.horizontal, 14)
              .padding(.vertical, 10)
              .background(Color.accentColor.opacity(0.15), in: .capsule)
          }
        }
        ```
        """
      }
    }
  }

  // MARK: - Timeline Interactive Callbacks

  private func updateMessage(_ updated: DefaultMessage) {
    if let index = messages.firstIndex(where: { $0.id == updated.id }) {
      messages[index] = updated
    }
  }

  private func resolveApproval(
    request: ApprovalRequest,
    decision: ApprovalRequest.Decision
  ) {
    guard let index = messages.firstIndex(where: { $0.approvalRequest?.id == request.id }) else {
      return
    }
    messages[index].approvalRequest?.decision = decision
    if decision == .allowOnce || decision == .alwaysAllow {
      if var plan = messages[index].plan, !plan.steps.isEmpty {
        plan.steps[plan.steps.count - 1].status = .completed
        messages[index].plan = plan
      }
    }
  }

  private func retryToolCall(_ failedCall: ToolCall) async {
    guard let msgIndex = messages.firstIndex(where: {
      $0.toolCalls.contains(where: { $0.id == failedCall.id })
    }),
      let toolIndex = messages[msgIndex].toolCalls.firstIndex(where: { $0.id == failedCall.id })
    else {
      return
    }

    messages[msgIndex].toolCalls[toolIndex].status = .running(startedAt: .now)
    try? await Task.sleep(for: .milliseconds(350))
    messages[msgIndex].toolCalls[toolIndex].status = .succeeded(duration: 0.35)
  }

  private func updateFeedback(for messageID: String, feedback: MessageFeedback?) {
    guard let index = messages.firstIndex(where: { $0.id == messageID }) else { return }
    messages[index].feedback = feedback
  }

  private func regenerateMessage(id messageID: String) async {
    guard let index = messages.firstIndex(where: { $0.id == messageID }) else { return }
    messages[index].messageError = nil
    messages[index].isStreaming = true
    try? await Task.sleep(for: .milliseconds(250))
    messages[index].isStreaming = false
  }
}

#Preview {
  ContentView()
}
