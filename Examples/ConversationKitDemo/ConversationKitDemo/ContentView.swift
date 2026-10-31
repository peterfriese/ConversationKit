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
import PhotosUI
import SwiftUI

struct ContentView: View {
  private static let defaultMessages: [DefaultMessage] = [
    .init(content: "Hello! I'm your AI assistant. How can I help you today?", participant: .other),
    .init(content: "What are the key features of ConversationKit?", participant: .user),
    .init(
      content: "ConversationKit provides a robust set of UI components for building chat interfaces. Key features include Optimistic UI, 'Sticky Top' scrolling, and native cross-platform support.",
      participant: .other
    ),
    .init(content: "How does the 'Sticky Top' scrolling work?", participant: .user),
    .init(
      content: "It anchors the scroll position to the top of the message being streamed, ensuring a stable reading experience as new tokens arrive.",
      participant: .other
    ),
    .init(content: "Can you show me a formatted response with an image?", participant: .user),
    .init(
      content: "Sure! Here is an example of a **formatted message** with an image:\n\n### Key Benefits\n* **Native Performance**: Built entirely in SwiftUI.\n* **Customizable**: Use your own models and views.\n* **Cross-platform**: Works on iOS and macOS.",
      imageURL: "https://picsum.photos/400/300",
      participant: .other
    ),
  ]

  private static let starterPromptPool: [PromptSuggestion] = [
    PromptSuggestion(
      id: "agent-run",
      title: "Run an agent workflow with tools",
      subtitle: "Demonstrate thinking timer, 4 tool calls, plan & citations",
      prompt: "Run an agent workflow with tools to audit our SwiftUI scroll physics",
      icon: "wrench.and.screwdriver",
      category: "Agentic"
    ),
    PromptSuggestion(
      id: "scroll-physics",
      title: "Explain Push & Pin scroll physics",
      subtitle: "How Optimistic UI anchors user prompts seamlessly",
      prompt: "How does the Push and Pin scrolling work in ConversationKit?",
      icon: "arrow.up.and.down.text.horizontal",
      category: "Architecture"
    ),
    PromptSuggestion(
      id: "formatted-image",
      title: "Show a formatted response with image",
      subtitle: "Render rich Markdown and async media cards",
      prompt: "Can you show me a formatted response with an image?",
      icon: "photo.on.rectangle",
      category: "Markdown"
    ),
    PromptSuggestion(
      id: "long-story",
      title: "Stream a long multi-paragraph story",
      subtitle: "Test 120Hz streaming and cooperative Stop cancellation",
      prompt: "Tell me a long story about a packet named Byte",
      icon: "text.alignleft",
      category: "Streaming"
    ),
    PromptSuggestion(
      id: "liquid-glass",
      title: "Adopt iOS 26 Liquid Glass",
      subtitle: "Progressive disclosure with GlassEffectContainer",
      prompt: "How does ConversationKit adopt Liquid Glass on iOS 26?",
      icon: "sparkles",
      category: "Design"
    ),
    PromptSuggestion(
      id: "swift-testing",
      title: "Generate Swift Testing unit tests",
      subtitle: "Verify agentic models with @Test and #expect",
      prompt: "Write a Swift Testing suite for ThinkingTrace and ToolCall",
      icon: "checkmark.seal",
      category: "Testing"
    ),
  ]

  private static let availableModels: [ComposerModelOption] = [
    ComposerModelOption(
      id: "claude-sonnet-4-6",
      name: "Claude 4.6 Sonnet",
      subtitle: "Fast & Capable",
      icon: "sparkles"
    ),
    ComposerModelOption(
      id: "gemini-3-pro",
      name: "Gemini 3 Pro",
      subtitle: "Deep Reasoning",
      icon: "brain"
    ),
    ComposerModelOption(
      id: "apple-foundation",
      name: "On-Device Foundation",
      subtitle: "Private & Local",
      icon: "iphone"
    ),
  ]

  private static let availableSlashCommands: [ComposerTokenChip] = [
    ComposerTokenChip(
      id: "cmd-summarize",
      kind: .slashCommand,
      trigger: "/summarize",
      title: "Summarize thread",
      value: "/summarize",
      icon: "doc.text.magnifyingglass"
    ),
    ComposerTokenChip(
      id: "cmd-plan",
      kind: .slashCommand,
      trigger: "/plan",
      title: "Create step-by-step agent plan",
      value: "/plan",
      icon: "checklist"
    ),
    ComposerTokenChip(
      id: "cmd-test",
      kind: .slashCommand,
      trigger: "/test",
      title: "Run verification suite",
      value: "/test",
      icon: "hammer"
    ),
  ]

  private static let availableMentions: [ComposerTokenChip] = [
    ComposerTokenChip(
      id: "mention-conversation-view",
      kind: .mention,
      trigger: "@ConversationView.swift",
      title: "ConversationView.swift",
      value: "Sources/ConversationKit/Views/Timeline/ConversationView.swift",
      icon: "doc.text"
    ),
    ComposerTokenChip(
      id: "mention-readme",
      kind: .mention,
      trigger: "@README.md",
      title: "README.md",
      value: "README.md",
      icon: "book"
    ),
    ComposerTokenChip(
      id: "mention-adr",
      kind: .mention,
      trigger: "@ADR-0001",
      title: "ADR-0001 Architecture",
      value: "docs/architecture/ADR-0001-VNEXT-MODULAR-AGENTIC-ARCHITECTURE.md",
      icon: "building.columns"
    ),
  ]

  @State var messages: [DefaultMessage] = ContentView.defaultMessages
  @State var attachments = [ImageAttachment]()
  @State private var selectedItems = [PhotosPickerItem]()
  @State private var showingPhotoPicker = false
  @State private var selectedModelID: String? = "claude-sonnet-4-6"
  @State private var activeCapabilities: Set<ComposerCapability> = []
  @State private var activeTokens: [ComposerTokenChip] = []

  var body: some View {
    NavigationStack {
      ConversationView(messages: $messages, attachments: $attachments)
        .onSendMessage { userMessage in
          messages.append(userMessage)
          withAnimation {
            self.attachments.removeAll()
          }

          let content = userMessage.content ?? ""
          if content.localizedCaseInsensitiveContains("long") {
            await generateLongResponse()
          } else if content.localizedCaseInsensitiveContains("agent")
            || content.localizedCaseInsensitiveContains("tools")
            || activeCapabilities.contains(.think)
            || activeCapabilities.contains(.search)
          {
            await simulateLiveAgentRun(prompt: content)
          } else {
            await generateResponse(for: userMessage)
          }
        }
        .starterPrompts(
          Self.starterPromptPool,
          userName: "Peter",
          subtitle: "Explore vNext agentic chat surfaces, tool calls, and composer modes.",
          visibleCount: 4,
          allowsShuffle: true,
          handoff: .immediateSend
        )
        .composerModels(Self.availableModels, selection: $selectedModelID)
        .composerCapabilities([.think, .search, .image], active: $activeCapabilities)
        .slashCommands(Self.availableSlashCommands, activeTokens: $activeTokens)
        .mentionSuggestions(Self.availableMentions, activeTokens: $activeTokens)
        .onRegenerateMessage { target in
          await generateResponse(for: target)
        }
        .onRateMessage { target, newRating in
          guard let targetID = target.id as? UUID,
                let index = messages.firstIndex(where: { $0.id == targetID })
          else { return }
          messages[index].rating = newRating
        }
        .onRetryMessage { failedMessage in
          guard let targetID = failedMessage.id as? UUID,
                let index = messages.firstIndex(where: { $0.id == targetID })
          else { return }
          messages.remove(at: index)
          await generateResponse(for: failedMessage)
        }
        .onRetryToolCall { failedTool in
          for msgIndex in messages.indices {
            if let toolIndex = messages[msgIndex].toolCalls.firstIndex(where: { $0.id == failedTool.id }) {
              messages[msgIndex].toolCalls[toolIndex].status = .running
              try? await Task.sleep(for: .milliseconds(400))
              messages[msgIndex].toolCalls[toolIndex].status = .succeeded
              messages[msgIndex].toolCalls[toolIndex].durationSeconds = 0.4
              messages[msgIndex].toolCalls[toolIndex].errorMessage = nil
              break
            }
          }
        }
        .onAgentApproval { request, decision in
          for msgIndex in messages.indices {
            if messages[msgIndex].approvalRequest?.id == request.id {
              messages[msgIndex].approvalRequest?.decision = decision
              break
            }
          }
        }
        .attachmentActions {
          Button("Photos", systemImage: "photo.on.rectangle.angled") {
            showingPhotoPicker = true
          }
        }
        .navigationTitle("Chat")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Menu("Patterns", systemImage: "sparkles.rectangle.stack") {
              Button("Welcome & Starter Chips", systemImage: "hand.wave") {
                withAnimation {
                  messages.removeAll()
                }
              }

              Button("Agentic Turn (Thinking + Tools + Plan)", systemImage: "cpu") {
                loadStaticAgenticShowcaseTurn()
              }

              Button("Simulate Live Agent Run", systemImage: "bolt.horizontal.circle") {
                Task { @MainActor in
                  let prompt = DefaultMessage(
                    content: "Run an agent workflow with tools to audit our SwiftUI scroll physics",
                    participant: .user
                  )
                  messages.append(prompt)
                  await simulateLiveAgentRun(prompt: prompt.content ?? "")
                }
              }

              Divider()

              Button("Reset Default Thread", systemImage: "arrow.counterclockwise") {
                withAnimation {
                  messages = Self.defaultMessages
                }
              }
            }
            .accessibilityIdentifier("patterns_menu_button")
          }
        }
        .photosPicker(
          isPresented: $showingPhotoPicker,
          selection: $selectedItems,
          maxSelectionCount: 5,
          matching: .images
        )
        .onChange(of: selectedItems) {
          Task {
            for item in selectedItems {
              do {
                if let data = try await item.loadTransferable(type: Data.self) {
                  if let platformImage = PlatformImage(data: data) {
                    attachments.append(
                      ImageAttachment(image: platformImage)
                    )
                  }
                }
              } catch {
                print("Failed to load image attachment: \(error.localizedDescription)")
              }
            }
            selectedItems.removeAll()
          }
        }
    }
  }

  @MainActor
  private func loadStaticAgenticShowcaseTurn() {
    let userTurn = DefaultMessage(
      content: "Audit ConversationKit's scroll physics and prepare a release plan.",
      participant: .user
    )
    let assistantTurn = DefaultMessage(
      content: "I've completed the architectural audit of **ConversationKit**. All four sub-surfaces (`Timeline`, `Welcome`, `Agentic`, and `Composer`) preserve a single outer `ConversationScrollID` per turn so **Push and Pin** scroll clamping remains 100% stable.",
      participant: .other,
      thinking: ThinkingTrace(
        summary: "Verified scroll anchor and optimistic deduplication invariants",
        transcript: "1. Checked `ConversationScrollID.message(message.id)` uniqueness.\n2. Confirmed `.safeAreaInset(edge: .bottom)` adapts dynamically to composer height.\n3. Verified $O(1)$ fast-path `Equatable` on `ThinkingTrace` and `ToolCall`.",
        durationSeconds: 4.2,
        status: .completed(duration: 4.2)
      ),
      toolCalls: [
        ToolCall(
          name: "read_architecture_doc",
          icon: "doc.text.magnifyingglass",
          argumentsSummary: "ADR-0001-VNEXT-MODULAR-AGENTIC-ARCHITECTURE.md",
          resultSummary: "Loaded 7 sections",
          durationSeconds: 0.6,
          inputJSON: "{\"path\": \"docs/architecture/ADR-0001.md\"}",
          outputJSON: "{\"status\": \"accepted\", \"sections\": 7}",
          status: .succeeded
        ),
        ToolCall(
          name: "search_scroll_anchors",
          icon: "magnifyingglass",
          argumentsSummary: "pattern: \"ConversationScrollID\"",
          resultSummary: "1 outer ID per message row",
          durationSeconds: 0.8,
          inputJSON: "{\"pattern\": \"ConversationScrollID\"}",
          outputJSON: "{\"matches\": 1}",
          status: .succeeded
        ),
        ToolCall(
          name: "run_swift_tests",
          icon: "hammer",
          argumentsSummary: "target: ConversationKitTests",
          resultSummary: "14 passed, 0 failed",
          durationSeconds: 1.1,
          inputJSON: "{\"suite\": \"ConversationKitTests\"}",
          outputJSON: "{\"passed\": 14, \"failed\": 0}",
          status: .succeeded
        ),
        ToolCall(
          name: "check_public_api",
          icon: "checkmark.shield",
          argumentsSummary: "module: ConversationKit",
          resultSummary: "Zero breaking changes",
          durationSeconds: 0.7,
          inputJSON: "{\"module\": \"ConversationKit\"}",
          outputJSON: "{\"compatible\": true}",
          status: .succeeded
        ),
      ],
      citations: [
        Citation(
          id: "cit-1",
          title: "SwiftUI ScrollViewReader Documentation",
          url: URL(string: "https://developer.apple.com/documentation/swiftui/scrollviewreader"),
          snippet: "Programmatic scroll positioning with view-aligned scroll target behavior."
        ),
        Citation(
          id: "cit-2",
          title: "ConversationKit ADR-0001 Architecture",
          url: URL(string: "https://github.com/peterfriese/ConversationKit"),
          snippet: "Single outer scroll identity and token-guarded turn coordinator."
        ),
      ],
      plan: AgentPlan(
        title: "vNext Verification Checklist",
        steps: [
          AgentPlan.Step(title: "Verify Welcome & Starter Chips", status: .completed),
          AgentPlan.Step(title: "Verify Thinking Timer & Auto-Fold", status: .completed),
          AgentPlan.Step(title: "Verify Tool Call Group & Plan Progress", status: .completed),
          AgentPlan.Step(title: "Authorize workspace snapshot export", status: .inProgress),
        ]
      ),
      approvalRequest: ApprovalRequest(
        title: "Export verification report",
        detail: "Allow the agent to write the audit summary to docs/verification-report.md?",
        scopeIdentifier: "mcp:filesystem/write",
        decision: .pending
      ),
      isStreaming: false
    )

    withAnimation(.snappy(duration: 0.25)) {
      messages = [userTurn, assistantTurn]
    }
  }

  @MainActor
  func simulateLiveAgentRun(prompt: String) async {
    let startDate = Date()
    var agentMessage = DefaultMessage(
      content: nil,
      participant: .other,
      thinking: ThinkingTrace(
        summary: "Planning tool invocations for \"\(prompt)\"",
        transcript: "Evaluating workspace structure and selecting inspection tools...",
        startedAt: startDate,
        status: .thinking(startedAt: startDate)
      ),
      isStreaming: true
    )
    messages.append(agentMessage)

    func syncAgentMessage() {
      if let index = messages.firstIndex(where: { $0.id == agentMessage.id }) {
        messages[index] = agentMessage
      }
    }

    do {
      try await Task.sleep(for: .milliseconds(900))
      try Task.checkCancellation()

      // Complete thinking & begin tool execution + plan
      let thoughtDuration = max(0.9, Date().timeIntervalSince(startDate))
      agentMessage.thinking = ThinkingTrace(
        id: agentMessage.thinking?.id ?? UUID().uuidString,
        summary: "Planned 2 verification steps",
        transcript: "Selected `inspect_views` and `verify_scroll_physics` tools.",
        startedAt: startDate,
        durationSeconds: thoughtDuration,
        status: .completed(duration: thoughtDuration)
      )
      agentMessage.plan = AgentPlan(
        title: "Live Agent Execution",
        steps: [
          AgentPlan.Step(id: "s1", title: "Inspect Timeline & Agentic views", status: .inProgress),
          AgentPlan.Step(id: "s2", title: "Synthesize grounded response", status: .pending),
        ]
      )
      agentMessage.toolCalls = [
        ToolCall(
          id: "t1",
          name: "inspect_views",
          icon: "magnifyingglass",
          argumentsSummary: "path: Sources/ConversationKit/Views",
          inputJSON: "{\"path\": \"Sources/ConversationKit/Views\"}",
          status: .running
        ),
        ToolCall(
          id: "t2",
          name: "verify_scroll_physics",
          icon: "arrow.up.and.down.text.horizontal",
          argumentsSummary: "anchor: .top",
          inputJSON: "{\"anchor\": \"top\"}",
          status: .pending
        ),
      ]
      syncAgentMessage()

      try await Task.sleep(for: .milliseconds(600))
      try Task.checkCancellation()

      agentMessage.toolCalls[0].status = .succeeded
      agentMessage.toolCalls[0].durationSeconds = 0.6
      agentMessage.toolCalls[0].outputJSON = "{\"subsurfaces\": [\"Timeline\", \"Welcome\", \"Agentic\", \"Composer\"]}"
      agentMessage.toolCalls[1].status = .running
      syncAgentMessage()

      try await Task.sleep(for: .milliseconds(500))
      try Task.checkCancellation()

      agentMessage.toolCalls[1].status = .succeeded
      agentMessage.toolCalls[1].durationSeconds = 0.5
      agentMessage.toolCalls[1].outputJSON = "{\"stickyTop\": \"verified\"}"
      agentMessage.plan?.steps[0].status = .completed
      agentMessage.plan?.steps[1].status = .inProgress
      syncAgentMessage()

      let fullReply = "### Agent Run Complete\n\nI inspected the `ConversationKit` sub-surfaces and verified that **Push and Pin** scroll clamping, live thinking timers, and grouped tool invocations work seamlessly together."
      var streamed = ""
      let chunkSize = 8
      for chunkStart in stride(from: 0, to: fullReply.count, by: chunkSize) {
        let chunkEnd = min(chunkStart + chunkSize, fullReply.count)
        let chunk = fullReply[
          fullReply.index(fullReply.startIndex, offsetBy: chunkStart)..<fullReply.index(fullReply.startIndex, offsetBy: chunkEnd)
        ]
        streamed.append(String(chunk))
        agentMessage.content = streamed
        syncAgentMessage()
        try await Task.sleep(for: .milliseconds(45))
        try Task.checkCancellation()
      }

      agentMessage.plan?.steps[1].status = .completed
      agentMessage.citations = [
        Citation(
          title: "ConversationKit vNext Architecture",
          url: URL(string: "https://developer.apple.com/documentation/swiftui"),
          snippet: "Modular Timeline, Welcome, Agentic, and Composer sub-surfaces."
        )
      ]
      agentMessage.isStreaming = false
      syncAgentMessage()
    } catch {
      let elapsed = max(0.1, Date().timeIntervalSince(startDate))
      if case .thinking = agentMessage.thinking?.status {
        agentMessage.thinking?.status = .cancelled(duration: elapsed)
      }
      for index in agentMessage.toolCalls.indices where agentMessage.toolCalls[index].status == .running {
        agentMessage.toolCalls[index].status = .cancelled
      }
      agentMessage.isStreaming = false
      syncAgentMessage()
    }
  }

  @MainActor
  func generateResponse(for message: any Message) async {
    let userText = message.content ?? ""

    let responses: [(text: String, imageURL: String?)] = [
      (
        text: "ConversationKit provides a **smooth** and **native** chat experience. It handles complex UI logic like message deduplication and scroll management so you can focus on your AI logic. The library is fully compatible with **SwiftUI** and supports both iOS and macOS.",
        imageURL: nil
      ),
      (
        text: "Sure! Here is an example of a **formatted message** with an image:\n\n### Key Benefits\n*   **Native Performance**: Built entirely in SwiftUI.\n*   **Customizable**: Use your own models and views.\n*   **Cross-platform**: Works on iOS and macOS.\n\n```swift\nConversationView(messages: $messages)\n```",
        imageURL: "https://picsum.photos/400/300"
      ),
      (
        text: "I can definitely help with that. Did you know that *Sticky Top* scrolling is one of the most requested features for chat apps? We've made it a first-class citizen in this library.",
        imageURL: nil
      ),
      (
        text: "That's a great question! Integrating AI can be complex, but your UI shouldn't be. That's why we built **ConversationKit**.",
        imageURL: nil
      ),
    ]

    let selectedResponse: (text: String, imageURL: String?)
    if userText.localizedCaseInsensitiveContains("formatted") || userText.localizedCaseInsensitiveContains("image") {
      selectedResponse = responses[1]
    } else {
      selectedResponse = responses.randomElement() ?? responses[0]
    }

    var generatedText = ""
    var responseMessage = DefaultMessage(
      content: generatedText,
      imageURL: selectedResponse.imageURL,
      participant: .other,
      isStreaming: true
    )
    messages.append(responseMessage)

    let chunkSize = 5

    do {
      let text = selectedResponse.text
      for chunkStart in stride(from: 0, to: text.count, by: chunkSize) {
        let chunkEnd = min(chunkStart + chunkSize, text.count)
        let chunk = text[
          text.index(
            text.startIndex,
            offsetBy: chunkStart
          )..<text.index(text.startIndex, offsetBy: chunkEnd)
        ]

        generatedText.append(String(chunk))
        responseMessage.content = generatedText
        if let index = messages.firstIndex(where: { $0.id == responseMessage.id }) {
          messages[index] = responseMessage
        }

        let randomDelay = Double.random(in: 0.1...0.2)
        try await Task.sleep(nanoseconds: UInt64(randomDelay * 100_000_000))

        try Task.checkCancellation()
      }
      responseMessage.isStreaming = false
      if let index = messages.firstIndex(where: { $0.id == responseMessage.id }) {
        messages[index] = responseMessage
      }
    } catch {
      responseMessage.isStreaming = false
      if let index = messages.firstIndex(where: { $0.id == responseMessage.id }) {
        messages[index] = responseMessage
      }
    }
  }

  @MainActor
  func generateLongResponse() async {
    let paragraphs = [
      "Here is a very long story just for you.",
      "Once upon a time in a digital realm far, far away, there lived a small bit of data named Byte. Byte was curious and always wanted to travel across the vast networks of the internet.",
      "One day, Byte found a packet header that was perfectly sized and hopped aboard. The journey was perilous, traversing through numerous routers, switches, and firewalls.",
      "At one point, Byte encountered a massive traffic jam at a transatlantic cable node. Packets were dropping left and right. It was a chaotic scene, but Byte managed to reroute through a satellite link.",
      "Floating through space, Byte saw the earth below—a beautiful blue marble interconnected by invisible threads of communication.",
      "Eventually, Byte landed safely in a cozy little server rack in Iceland, surrounded by humming cooling fans and the gentle blinking of LED lights.",
      "But the adventure didn't stop there. Byte was soon requested by a client application on a mobile device.",
      "Zipping back through fiber optic cables at the speed of light, Byte finally arrived on the screen of a user, bringing a tiny pixel to life to form part of a beautiful image.",
      "And so, Byte's journey came to an end, having successfully delivered the payload. It was a fulfilling existence, being part of the grand tapestry of human connection and information exchange.",
      "The end. I hope you enjoyed this incredibly long and detailed story about a single byte of data traversing the global internet infrastructure.",
    ]

    var generatedText = ""
    var message = DefaultMessage(content: nil, participant: .other, isStreaming: true) // Start with loading state
    messages.append(message)

    // Simulate loading delay
    try? await Task.sleep(for: .seconds(1))

    let chunkSize = 5

    for paragraph in paragraphs {
      let textToStream = (generatedText.isEmpty ? "" : "\n\n") + paragraph
      for chunkStart in stride(from: 0, to: textToStream.count, by: chunkSize) {
        let chunkEnd = min(chunkStart + chunkSize, textToStream.count)
        let chunk = textToStream[
          textToStream.index(textToStream.startIndex, offsetBy: chunkStart)..<textToStream.index(textToStream.startIndex, offsetBy: chunkEnd)
        ]

        generatedText.append(String(chunk))
        message.content = generatedText
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
          messages[index] = message
        }

        let randomDelay = Double.random(in: 0.05...0.1)
        try? await Task.sleep(for: .seconds(randomDelay))

        // This is strictly required for the new "Stop" button feature to work cooperatively
        do {
          try Task.checkCancellation()
        } catch {
          message.isStreaming = false
          if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
          }
          return // Stop streaming if cancelled
        }
      }
    }

    message.isStreaming = false
    if let index = messages.firstIndex(where: { $0.id == message.id }) {
      messages[index] = message
    }
  }
}

#Preview {
  ContentView()
}
