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

  // MARK: - Static Showcase Catalog (`F-5`, `F-8`, `F-9`)

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
    NavigationStack {
      ConversationView(messages: $messages, attachments: $attachments, userPrompt: initialUserPrompt)
        .onSendMessage { submission in
          await handleSubmission(submission)
        }
        .suggestionChips(Self.starterSuggestions)
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
            styleAndSamplesMenu
            resetConversationButton
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
    } label: {
      Label("Composer Style", systemImage: "slider.horizontal.3")
    }
    .accessibilityIdentifier("demo.styleMenu")
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

    let lowerPrompt = submission.text.lowercased()
    let hasRefactorOrTools = lowerPrompt.contains("refactor")
      || lowerPrompt.contains("tool")
      || submission.command?.trigger == "code"
      || submission.command?.trigger == "benchmark"

    let responseID = UUID().uuidString
    let startedAt = Date.now

    // 2. Start assistant turn with active ThinkingTrace (collapsed by default per F-7 & AC-11)
    var assistantMessage = DefaultMessage(
      id: responseID,
      content: nil,
      participant: .other,
      selectedModelID: submission.selectedModel?.id,
      thinkingTrace: ThinkingTrace(
        status: .thinking(startedAt: startedAt),
        summary: "Analyzing turn geometry & synthesizing response…",
        transcript: """
        1. Locked activeTurnMinHeight to unoccluded viewport runway.
        2. Verified user bubble top-edge anchor (Delta Y = 0pt).
        3. Preparing block-committed Markdown & fenced code blocks.
        """
      ),
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
      assistantMessage.thinkingTrace = ThinkingTrace(
        id: assistantMessage.thinkingTrace?.id ?? UUID().uuidString,
        status: .completed(duration: 1.2),
        summary: "Evaluated Liquid Glass & scroll runway invariants",
        transcript: """
        1. Locked activeTurnMinHeight to unoccluded viewport runway.
        2. Verified user bubble top-edge anchor (Delta Y = 0pt).
        3. Committed AST paragraphs and syntax-highlighted Swift blocks.
        """
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

      // 3. Stream a rich multi-paragraph + fenced code block Markdown response (>1.5x viewport height)
      let fullMarkdown = buildResponseMarkdown(for: submission)
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

      // 4. Settle streaming state and attach allowlisted citations
      assistantMessage.isStreaming = false
      assistantMessage.citations = [
        Citation(
          index: 1,
          title: "Applying Liquid Glass to custom views",
          domain: "developer.apple.com",
          urlString: "https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views",
          snippet: "Use GlassEffectContainer and .safeAreaBar(edge: .bottom) for floating chrome."
        ),
        Citation(
          index: 2,
          title: "ConversationKit v2 Architecture (ADR-0001)",
          domain: "github.com",
          urlString: "https://github.com/peterfriese/ConversationKit",
          snippet: "Top-floating user turn runway and O(1) incremental Markdown block splitter."
        ),
      ]
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

  private func buildResponseMarkdown(for submission: ConversationSubmission<DefaultMessage>) -> String {
    let modelName = submission.selectedModel?.name ?? "Claude Sonnet 4.6"
    let commandPrefix = submission.command.map { "Executed `\($0.formattedTrigger)` · " } ?? ""
    let mentionsSummary = submission.mentions.isEmpty
      ? ""
      : "Referenced: " + submission.mentions.map { "`\($0.formattedHandle)`" }.joined(separator: ", ") + "\n\n"

    return """
    ### \(commandPrefix)ConversationKit v2 Architecture (\(modelName))

    \(mentionsSummary)When you submit a prompt, **ConversationKit v2** groups messages into deterministic `ConversationTurn` containers and anchors your user bubble at the top of the unoccluded viewport runway (`anchor: .top`, `ΔY = 0pt`).

    #### 1. Top-Floating Turn Physics & Byte's Journey (`F-1`, `F-2`)
    Once upon a time in a 120Hz ProMotion render loop, a tiny packet of tokens named **Byte** traveled from the model stream into `ConversationView`. Instead of triggering per-token `scrollTo` calls that cause layout jitter, Byte flowed smoothly downward inside the active turn's pre-allocated runway while your prompt stayed rock-solid at the top of the screen.

    * **Single-Shot Top Scroll:** `proxy.scrollTo(newTurnID, anchor: .top)` fires *only once* on submission.
    * **Unoccluded Viewport Runway:** `activeTurnMinHeight` locks to the post-keyboard viewport height so keyboard dismissal never shifts your message.
    * **Floating Scroll-to-Bottom Pill (`F-10`):** As this response overflows past `150%` of the screen height, the Liquid Glass scroll-to-bottom button appears at the bottom-trailing corner.

    ```swift
    import ConversationKit
    import SwiftUI

    struct AssistantScreen: View {
      @State private var messages: [DefaultMessage] = []
      @State private var attachments: [ConversationAttachment] = []

      var body: some View {
        ConversationView(messages: $messages, attachments: $attachments)
          .suggestionChips(ContentView.starterSuggestions)
          .messageComposerStyle(.classicGlass)
          .thinkingStateStyle(.collapsibleHeader)
          .userMessageBubbleStyle(.tailedBubble)
          .onSendMessage { submission in
            messages.append(submission.message)
          }
      }
    }
    ```

    #### 2. Strict iOS 26+ Liquid Glass Budget (`F-6`, `AC-10`)
    In accordance with Apple Human Interface Guidelines, **Liquid Glass** (`.glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glassProminent)`) is reserved strictly for floating chrome inside `.safeAreaBar(edge: .bottom)` and the floating `ScrollToBottomButton`.

    1. **Timeline Cells Never Use Glass:** User bubbles (`UserMessageBubbleStyle`), reasoning disclosures (`ThinkingStateView`), tool groups (`ToolCallsGroupView`), and code blocks use opaque/tinted semantic fills (`Color.platformUserBubbleFill`, `Color.platformSecondaryBackground`).
    2. **Incremental Markdown Engine (`F-3`):** Settled paragraphs and fenced code blocks are memoized by structural identity while only the active trailing block re-parses at 60Hz.
    3. **Multimodal & Structured Prompting (`F-4`, `F-5`):** Downsampled off-main-actor thumbnails (`PlatformThumbnailGenerator`), `/command` and `@mention` tokens with `\\u{200B}` two-stage backspace removal, and cooperative task cancellation complete the v2 architecture.
    """
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
