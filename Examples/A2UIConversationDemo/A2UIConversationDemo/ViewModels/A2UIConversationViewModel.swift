//
//  A2UIConversationViewModel.swift
//  A2UIConversationDemo
//
//  Coordinates ConversationKit v2 turns, A2UI MessageProcessor surface rendering,
//  Firebase AI Logic (Gemini 3 Flash / 3.1 Pro), Local A2UI Agent Server (A2A),
//  and two-way interactive surface actions.
//

import A2UICore
import A2UISwiftUI
import BasicCatalog
import BasicCatalogSwiftUI
import ConversationKit
import FirebaseAI
import FirebaseAppCheck
import FirebaseCore
import Foundation
import Observation
import OrderedJSON

// MARK: - Nonisolated Action Handling Bridge

final class ConversationA2UIActionBridge: ActionHandling, @unchecked Sendable {
  weak var viewModel: A2UIConversationViewModel?

  func handle(action: ResolvedAction, from surfaceID: String) {
    Task { @MainActor [weak self] in
      await self?.viewModel?.handleDispatchedSurfaceAction(action, from: surfaceID)
    }
  }

  func handle(error: RendererError, from surfaceID: String) {
    if Thread.isMainThread {
      MainActor.assumeIsolated {
        viewModel?.handleDispatchedRendererError(error, from: surfaceID)
      }
    } else {
      Task { @MainActor [weak self] in
        self?.viewModel?.handleDispatchedRendererError(error, from: surfaceID)
      }
    }
  }
}

// MARK: - A2UIConversationViewModel

@MainActor
@Observable
public final class A2UIConversationViewModel {
  // MARK: - ConversationKit State

  public var messages: [A2UIChatMessage] = []
  public var attachments: [ConversationAttachment] = []
  public var selectedModel: ComposerModelOption? = A2UIDemoPresets.availableModels.first
  public var activeCapabilities: Set<ComposerCapability> = []

  // MARK: - A2UI Engine State

  public let catalogs: [Catalog<ComponentImplementation>]
  public private(set) var processor: MessageProcessor
  private let parser = MessageParser()
  private let actionBridge = ConversationA2UIActionBridge()

  /// Incremented whenever a surface is created or updated so SwiftUI rows re-evaluate cleanly.
  public private(set) var surfaceRevision: Int = 0

  /// Bundled A2UI v1.0 Basic Catalog examples for slash commands and catalog browsing.
  public private(set) var bundledExamples: [BundledA2UIExample] = []

  /// Live diagnostic log of A2UI actions, surface updates, and validation events.
  public private(set) var eventLogs: [A2UIEventLog] = []

  /// Latest validation error encountered during a turn (used for Gemini self-correction retry).
  private var lastTurnValidationError: String?

  // MARK: - Model Backends (Firebase AI Logic & Local A2A Server)

  public var a2aServerURL: String = "http://localhost:10002"
  private var a2aContextID: String?
  private var originalSurfaceIDByTurnSurfaceID: [String: String] = [:]

  private var geminiChatsByModelID: [String: Chat] = [:]

  public init() {
    Self.configureFirebaseIfNeeded()

    let swiftUICatalogs = BasicCatalogImplementation.allCatalogs
    self.catalogs = swiftUICatalogs
    self.processor = MessageProcessor(
      catalogs: BasicCatalog.allCatalogs,
      actionHandler: actionBridge
    )
    self.actionBridge.viewModel = self
    self.bundledExamples = CatalogExamplesStore.loadV10Examples()

    seedInitialWelcomeTurn()

    let launchArgs = ProcessInfo.processInfo.arguments
    let autoPromptFromArg: String? = {
      if let idx = launchArgs.firstIndex(of: "-autoPrompt"), idx + 1 < launchArgs.count {
        return launchArgs[idx + 1]
      }
      return ProcessInfo.processInfo.environment["A2UI_AUTO_PROMPT"]
    }()

    if let autoPrompt = autoPromptFromArg, !autoPrompt.isEmpty {
      if launchArgs.contains("-clearWelcomeForAutoPrompt") {
        self.messages.removeAll()
      }
      Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(500))
        let userMessage = A2UIChatMessage(content: autoPrompt, participant: .user)
        let submission = ConversationSubmission(
          id: userMessage.id,
          message: userMessage,
          text: autoPrompt,
          selectedModel: self.selectedModel
        )
        await self.sendSubmission(submission)
      }
    }
  }

  // MARK: - Firebase Configuration

  public static var isFirebaseConfigured: Bool {
    FirebaseApp.app() != nil
  }

  public static func configureFirebaseIfNeeded() {
    guard FirebaseApp.app() == nil else { return }

    // Only configure Firebase if a valid GoogleService-Info.plist is present in the app bundle.
    // This allows the sample app to run its bundled A2UI v1.0 catalog and Local A2A Agent modes
    // out-of-the-box without requiring Firebase credentials in source control.
    guard
      let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
      let options = FirebaseOptions(contentsOfFile: plistPath)
    else {
      return
    }

    // Optional App Check debug token from environment or Info.plist (never hardcoded in source control).
    if let envDebugToken = ProcessInfo.processInfo.environment["FIRAAppCheckDebugToken"],
      !envDebugToken.isEmpty
    {
      UserDefaults.standard.set(envDebugToken, forKey: "GACAppCheckDebugToken")
      setenv("FIRAAppCheckDebugToken", envDebugToken, 1)
    } else if let plistDict = NSDictionary(contentsOfFile: plistPath) as? [String: Any],
      let customDebugToken = plistDict["AppCheckDebugToken"] as? String,
      !customDebugToken.isEmpty
    {
      UserDefaults.standard.set(customDebugToken, forKey: "GACAppCheckDebugToken")
      setenv("FIRAAppCheckDebugToken", customDebugToken, 1)
    }

    #if DEBUG
    AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
    #endif

    FirebaseApp.configure(options: options)
  }

  private func chatSession(for modelID: String) -> Chat {
    if let existing = geminiChatsByModelID[modelID] {
      return existing
    }
    let systemInstruction = ModelContent(
      role: "system",
      parts: A2UISystemPrompt.instructionText
    )
    let model = FirebaseAI
      .firebaseAI(backend: .googleAI())
      .generativeModel(
        modelName: modelID,
        systemInstruction: systemInstruction
      )
    let chat = model.startChat()
    geminiChatsByModelID[modelID] = chat
    return chat
  }

  // MARK: - Initial Welcome Surface

  public func seedInitialWelcomeTurn() {
    let welcomeSurfaceID = "welcome-coffee-order"
    var surfaceIDs: [String] = []
    var rawMessages: [String] = []

    if let match = CatalogExamplesStore.messagesForExample(
      matching: "13_coffee-order",
      targetSurfaceID: welcomeSurfaceID,
      in: bundledExamples
    ) {
      rawMessages = match.messages
      surfaceIDs = ingestA2UIMessages(match.messages)
    }

    let welcomeMessage = A2UIChatMessage(
      content: """
        Welcome to **A2UI × ConversationKit v2**!

        Below is a live **A2UI v1.0 Basic Catalog** surface rendered directly inside this conversation turn. Try tapping **Purchase** on the card, typing `/invitation` or `/dashboard`, or asking **Gemini 3 Flash** to design any interactive UI on the fly.
        """,
      participant: .other,
      surfaceIDs: surfaceIDs,
      rawA2UIMessages: rawMessages
    )
    self.messages = [welcomeMessage]
  }

  public func resetConversation() {
    processor = MessageProcessor(
      catalogs: BasicCatalog.allCatalogs,
      actionHandler: actionBridge
    )
    geminiChatsByModelID.removeAll()
    a2aContextID = nil
    originalSurfaceIDByTurnSurfaceID.removeAll()
    eventLogs.removeAll()
    surfaceRevision += 1
    seedInitialWelcomeTurn()
  }

  // MARK: - Surface Lookup & Data Model Inspection

  public func surfaceViewModel(for surfaceID: String) -> SurfaceViewModel? {
    _ = surfaceRevision
    return processor.surfaceGroupModel[surfaceID]
  }

  public func formattedDataModelJSON(for surfaceID: String) -> String {
    guard let vm = processor.surfaceGroupModel[surfaceID] else {
      return "{}"
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard
      let data = try? encoder.encode(vm.dataModel.data),
      let string = String(data: data, encoding: .utf8)
    else {
      return "{}"
    }
    return string
  }

  // MARK: - Turn Submission (`.onSendMessage`)

  public func sendSubmission(_ submission: ConversationSubmission<A2UIChatMessage>) async {
    // 1. Append the user's message preserving `submission.message.id` for zero-jitter Optimistic UI deduplication.
    messages.append(submission.message)

    let activeModelID = submission.selectedModel?.id ?? selectedModel?.id ?? "gemini-3-flash-preview"
    let commandTrigger = submission.command?.trigger ?? detectLeadingCommandTrigger(in: submission.text)

    // 2. Check if the user triggered a deterministic catalog slash command (/coffee, /invitation, /dashboard, /workout, /music)
    if let commandTrigger, commandTrigger != "restaurants" {
      if await runCatalogCommandTurn(trigger: commandTrigger, promptText: submission.text, modelID: activeModelID) {
        return
      }
    }

    // 3. Route to Local A2A Agent Server if selected
    if activeModelID == "a2a-local-agent" {
      await runLocalA2AAgentTurn(queryText: submission.text, action: nil)
      return
    }

    // 4. Route to live Gemini 3 via Firebase AI Logic
    await runGeminiTurn(promptText: submission.text, modelID: activeModelID)
  }

  /// Appends and streams a specific bundled catalog example directly into the conversation.
  public func sendBundledExample(_ example: BundledA2UIExample) async {
    let userMsg = A2UIChatMessage(
      content: "Render the **\(example.title)** (`\(example.slug).json`) A2UI v1.0 surface.",
      participant: .user
    )
    messages.append(userMsg)

    let assistantID = UUID().uuidString
    let targetSurfaceID = "surface-\(example.slug)-\(assistantID.prefix(6))"
    let rewrittenMessages = CatalogExamplesStore.rewriteSurfaceID(
      in: example.rawMessages,
      to: targetSurfaceID
    )

    await streamCatalogMessagesTurn(
      assistantID: assistantID,
      title: example.title,
      markdownIntro: "Here is the live **\(example.title)** surface (`\(example.slug).json`) rendered with `BasicCatalogSwiftUI`:",
      rawMessages: rewrittenMessages
    )
  }

  // MARK: - Live Gemini 3 Turn (Firebase AI Logic)

  private func runGeminiTurn(promptText: String, modelID: String) async {
    let assistantID = UUID().uuidString
    let traceID = "trace-\(assistantID)"
    let toolID = "tool-\(assistantID)"

    guard Self.isFirebaseConfigured else {
      let missingConfigMsg = A2UIChatMessage(
        id: assistantID,
        content: """
          **Firebase AI Logic is not configured yet.**

          To use live **\(modelID)** generative UI turns, drop your project's `GoogleService-Info.plist` into `A2UIConversationDemo/A2UIConversationDemo/` (it is automatically git-ignored so your credentials are never committed).

          In the meantime, you can immediately test:
          - **Bundled A2UI v1.0 Catalog `/commands`**: Try `/coffee`, `/invitation`, `/dashboard`, `/workout`, or `/music` (or open the **Catalog & A2A** browser in the toolbar).
          - **Local A2UI Agent Server (A2A)**: Switch the model pill to **Local A2UI Agent (A2A)** to connect to `http://localhost:10002`.
          """,
        participant: .other,
        isStreaming: false,
        selectedModelID: modelID,
        messageError: MessageError(
          message: "Missing GoogleService-Info.plist",
          detail: "Add GoogleService-Info.plist to enable live Firebase AI Logic (Gemini 3) turns.",
          isRetryable: false
        )
      )
      messages.append(missingConfigMsg)
      return
    }

    let assistantMsg = A2UIChatMessage(
      id: assistantID,
      content: "",
      participant: .other,
      isStreaming: true,
      selectedModelID: modelID,
      thinkingTrace: ThinkingTrace(
        id: traceID,
        status: .thinking(startedAt: .now),
        summary: "Designing A2UI v1.0 surface with \(modelID)...",
        transcript: "Selecting Basic Catalog v1.0 components, layout hierarchy, and `@path` data model bindings."
      )
    )
    messages.append(assistantMsg)

    let chat = chatSession(for: modelID)
    lastTurnValidationError = nil

    do {
      let (visibleText, rawA2UIMessages) = try await streamFromGeminiChat(
        chat: chat,
        prompt: promptText,
        assistantID: assistantID,
        traceID: traceID,
        toolID: toolID
      )

      var finalVisibleText = visibleText
      var finalRawMessages = rawA2UIMessages
      var createdSurfaceIDs: [String] = []

      if !finalRawMessages.isEmpty {
        let turnSurfaceID = "gemini-\(assistantID.prefix(6))"
        finalRawMessages = CatalogExamplesStore.rewriteSurfaceID(
          in: finalRawMessages,
          to: turnSurfaceID
        )
        createdSurfaceIDs = ingestA2UIMessages(finalRawMessages)
      }

      // Single self-correction retry if validation failed or root component was missing
      let hasEmptyRoot = !finalRawMessages.isEmpty
        && (createdSurfaceIDs.isEmpty || createdSurfaceIDs.allSatisfy { processor.surfaceGroupModel[$0]?.rootNode == nil })

      if (lastTurnValidationError != nil && !(lastTurnValidationError?.isEmpty ?? true)) || hasEmptyRoot {
        let validationErr = lastTurnValidationError ?? "Surface root component failed to render or failed schema validation."
        updateAssistantMessage(id: assistantID) { msg in
          msg.toolCalls = [
            ToolCall(
              id: toolID,
              name: "validate_and_repair_a2ui",
              symbolName: "wrench.and.screwdriver",
              status: .running(startedAt: .now),
              argumentsSummary: "Repairing schema validation issue",
              argumentsJSON: "{\"error\": \"\(validationErr.replacingOccurrences(of: "\"", with: "'"))\"}"
            )
          ]
        }
        let retryPrompt = """
          Your previous A2UI JSON had a validation error: \(validationErr).
          Please output a corrected response with `<a2ui-json>[...]</a2ui-json>` following the A2UI v1.0 Basic Catalog rules:
          1) On `Text`, `"variant"` MUST ONLY be `"body"` or `"caption"` (NEVER `"h1"`, `"h2"`, `"h3"`, `"h4"`, `"h5"` — use Markdown `#`, `##`, `###`, `####` inside `"text"` for headings!).
          2) On `Button`, use `"child": "<text_component_id>"` (never `"text"` directly on `Button`).
          3) On `ChoicePicker`, the bound value in `updateDataModel` must be an array of strings (e.g. `["optionA"]`).
          4) Include `"id": "root"` in `updateComponents`.
          """
        lastTurnValidationError = nil
        let (retryText, retryRawMessages) = try await streamFromGeminiChat(
          chat: chat,
          prompt: retryPrompt,
          assistantID: assistantID,
          traceID: traceID,
          toolID: toolID
        )
        if !retryRawMessages.isEmpty {
          let retrySurfaceID = "gemini-retry-\(assistantID.prefix(6))"
          let rewritten = CatalogExamplesStore.rewriteSurfaceID(
            in: retryRawMessages,
            to: retrySurfaceID
          )
          createdSurfaceIDs = ingestA2UIMessages(rewritten)
          finalRawMessages = rewritten
          if !retryText.isEmpty {
            finalVisibleText = retryText
          }
        }
      }

      updateAssistantMessage(id: assistantID) { msg in
        msg.content = finalVisibleText.isEmpty
          ? "Here is your interactive surface:"
          : finalVisibleText
        msg.surfaceIDs = createdSurfaceIDs
        msg.rawA2UIMessages = finalRawMessages
        msg.isStreaming = false
        msg.thinkingTrace?.status = .completed(duration: 1.1)
        if !createdSurfaceIDs.isEmpty {
          msg.toolCalls = [
            ToolCall(
              id: toolID,
              name: "render_a2ui_surface",
              symbolName: "rectangle.3.group.bubble",
              status: .succeeded(duration: 0.4),
              argumentsSummary: "surfaceId: \(createdSurfaceIDs.first ?? "")",
              resultSummary: "Rendered \(createdSurfaceIDs.count) interactive A2UI v1.0 surface(s)",
              argumentsJSON: "{\"surfaceId\": \"\(createdSurfaceIDs.first ?? "")\", \"messages\": \(finalRawMessages.count)}"
            )
          ]
        } else {
          msg.toolCalls = []
        }
      }
    } catch {
      updateAssistantMessage(id: assistantID) { msg in
        msg.isStreaming = false
        msg.thinkingTrace?.status = .completed(duration: 0.5)
        msg.toolCalls = []
        msg.messageError = MessageError(
          message: "Gemini (\(modelID)) request failed",
          detail: error.localizedDescription,
          isRetryable: true
        )
      }
    }
  }

  private func streamFromGeminiChat(
    chat: Chat,
    prompt: String,
    assistantID: String,
    traceID: String,
    toolID: String
  ) async throws -> (visibleText: String, a2uiMessages: [String]) {
    var accumulatedRaw = ""
    var didShowToolCall = false

    let stream = try chat.sendMessageStream(prompt)
    for try await chunk in stream {
      guard let text = chunk.text, !text.isEmpty else { continue }
      accumulatedRaw += text

      let parsed = A2UISystemPrompt.parseAccumulatedText(accumulatedRaw)

      if parsed.isStreamingA2UIBlock && !didShowToolCall {
        didShowToolCall = true
        updateAssistantMessage(id: assistantID) { msg in
          msg.thinkingTrace?.status = .completed(duration: 0.6)
          msg.toolCalls = [
            ToolCall(
              id: toolID,
              name: "render_a2ui_surface",
              symbolName: "rectangle.3.group.bubble",
              status: .running(startedAt: .now),
              argumentsSummary: "A2UI v1.0 Basic Catalog",
              argumentsJSON: "{\"protocol\": \"A2UI v1.0\", \"catalog\": \"basic\"}"
            )
          ]
        }
      }

      updateAssistantMessage(id: assistantID) { msg in
        if !parsed.visibleMarkdown.isEmpty {
          msg.content = parsed.visibleMarkdown
        }
      }
    }

    let finalParsed = A2UISystemPrompt.parseAccumulatedText(accumulatedRaw)
    return (finalParsed.visibleMarkdown, finalParsed.a2uiJSONMessages)
  }

  // MARK: - Local A2A Agent Server Turn (`http://localhost:10002/a2a/json-rpc`)

  private func runLocalA2AAgentTurn(
    queryText: String?,
    action: A2AActionPayload?
  ) async {
    let assistantID = UUID().uuidString
    let toolID = "tool-a2a-\(assistantID)"

    let assistantMsg = A2UIChatMessage(
      id: assistantID,
      content: "",
      participant: .other,
      isStreaming: true,
      selectedModelID: "a2a-local-agent",
      toolCalls: [
        ToolCall(
          id: toolID,
          name: "a2a_message_stream",
          symbolName: "network",
          status: .running(startedAt: .now),
          argumentsSummary: "\(a2aServerURL)/a2a/json-rpc",
          argumentsJSON: "{\"endpoint\": \"\(a2aServerURL)/a2a/json-rpc\", \"action\": \"\(action?.name ?? "query")\"}"
        )
      ]
    )
    messages.append(assistantMsg)

    do {
      let response = try await A2AClient.sendTurn(
        endpointURLString: a2aServerURL,
        contextID: a2aContextID,
        text: queryText,
        action: action
      )
      if let cid = response.contextID {
        self.a2aContextID = cid
      }

      // Rewrite each surfaceId in the A2A response with a turn suffix so earlier turns stay intact,
      // while recording the mapping back to the server's surfaceId for subsequent button actions.
      let suffix = String(assistantID.prefix(6))
      let rewrittenMessages = rewriteA2ASurfaceIDs(response.a2uiJSONMessages, turnSuffix: suffix)
      let renderedSurfaceIDs = ingestA2UIMessages(rewrittenMessages)

      let combinedText = response.textParts.joined(separator: "\n\n")
      let markdownText: String
      if !combinedText.isEmpty {
        markdownText = combinedText
      } else if let action {
        markdownText = "Received A2UI response from local A2A agent for action **`\(action.name)`**:"
      } else {
        markdownText = "Here is the A2UI v1.0 response from your local A2A agent (`\(a2aServerURL)`):"
      }

      updateAssistantMessage(id: assistantID) { msg in
        msg.content = markdownText
        msg.surfaceIDs = renderedSurfaceIDs
        msg.rawA2UIMessages = rewrittenMessages
        msg.isStreaming = false
        msg.toolCalls = [
          ToolCall(
            id: toolID,
            name: "a2a_message_stream",
            symbolName: "network",
            status: .succeeded(duration: 0.35),
            argumentsSummary: "contextId: \(a2aContextID ?? "new")",
            resultSummary: "Received \(rewrittenMessages.count) A2UI messages (\(renderedSurfaceIDs.joined(separator: ", ")))"
          )
        ]
      }
    } catch {
      updateAssistantMessage(id: assistantID) { msg in
        msg.isStreaming = false
        msg.toolCalls = [
          ToolCall(
            id: toolID,
            name: "a2a_message_stream",
            symbolName: "network",
            status: .failed(error: error.localizedDescription, duration: 0.2),
            argumentsSummary: "\(a2aServerURL)/a2a/json-rpc"
          )
        ]
        msg.messageError = MessageError(
          message: "Local A2UI Agent server unreachable",
          detail: error.localizedDescription,
          isRetryable: true
        )
      }
    }
  }

  // MARK: - Deterministic Catalog Slash Commands

  private func runCatalogCommandTurn(
    trigger: String,
    promptText: String,
    modelID: String
  ) async -> Bool {
    let mapping: [String: (query: String, intro: String)] = [
      "coffee": (
        "13_coffee-order",
        "Here is your interactive **Sunrise Coffee** order card (`13_coffee-order.json`). Tap **Purchase** to trigger the two-way A2UI action loop!"
      ),
      "invitation": (
        "30_live-invitation-builder",
        "Here is the **Live Invitation Builder** (`30_live-invitation-builder.json`). Edit the event fields on the left to watch the bound invitation preview update in real time!"
      ),
      "dashboard": (
        "31_incremental-dashboard",
        "Streaming the **Incremental System Dashboard** (`31_incremental-dashboard.json`) step-by-step into the active turn runway:"
      ),
      "workout": (
        "16_workout-summary",
        "Here is your **Workout Summary** surface (`16_workout-summary.json`) rendered with `BasicCatalogSwiftUI`:"
      ),
      "music": (
        "06_music-player",
        "Here is the **A2UI Music Player** surface (`06_music-player.json`):"
      ),
    ]

    guard let spec = mapping[trigger] else { return false }
    let assistantID = UUID().uuidString
    let targetSurfaceID = "catalog-\(trigger)-\(assistantID.prefix(6))"

    guard
      let match = CatalogExamplesStore.messagesForExample(
        matching: spec.query,
        targetSurfaceID: targetSurfaceID,
        in: bundledExamples
      )
    else {
      return false
    }

    await streamCatalogMessagesTurn(
      assistantID: assistantID,
      title: match.example.title,
      markdownIntro: spec.intro,
      rawMessages: match.messages
    )
    return true
  }

  private func streamCatalogMessagesTurn(
    assistantID: String,
    title: String,
    markdownIntro: String,
    rawMessages: [String]
  ) async {
    let traceID = "trace-\(assistantID)"
    let toolID = "tool-\(assistantID)"

    let initialMsg = A2UIChatMessage(
      id: assistantID,
      content: "",
      participant: .other,
      isStreaming: true,
      thinkingTrace: ThinkingTrace(
        id: traceID,
        status: .thinking(startedAt: .now),
        summary: "Streaming \(title) A2UI surface...",
        transcript: "Evaluating \(rawMessages.count) A2UI protocol messages (`createSurface` → `updateComponents` → `updateDataModel`)."
      ),
      toolCalls: [
        ToolCall(
          id: toolID,
          name: "stream_a2ui_surface",
          symbolName: "rectangle.3.group.bubble",
          status: .running(startedAt: .now),
          argumentsSummary: "\(title) (\(rawMessages.count) steps)"
        )
      ]
    )
    messages.append(initialMsg)

    try? await Task.sleep(for: .milliseconds(220))

    updateAssistantMessage(id: assistantID) { msg in
      msg.thinkingTrace?.status = .completed(duration: 0.22)
      msg.content = markdownIntro
    }

    var activeSurfaceIDs: [String] = []
    var appliedMessages: [String] = []

    for rawMessage in rawMessages {
      try? await Task.sleep(for: .milliseconds(260))
      let newlyTouched = ingestA2UIMessages([rawMessage])
      for sid in newlyTouched where !activeSurfaceIDs.contains(sid) {
        activeSurfaceIDs.append(sid)
      }
      appliedMessages.append(rawMessage)

      updateAssistantMessage(id: assistantID) { msg in
        msg.surfaceIDs = activeSurfaceIDs
        msg.rawA2UIMessages = appliedMessages
      }
    }

    updateAssistantMessage(id: assistantID) { msg in
      msg.isStreaming = false
      msg.toolCalls = [
        ToolCall(
          id: toolID,
          name: "stream_a2ui_surface",
          symbolName: "rectangle.3.group.bubble",
          status: .succeeded(duration: Double(rawMessages.count) * 0.26),
          argumentsSummary: "\(title)",
          resultSummary: "Streamed \(rawMessages.count) messages into surface '\(activeSurfaceIDs.first ?? "")'"
        )
      ]
    }
  }

  // MARK: - Two-Way A2UI Surface Action Handling (`ActionHandling`)

  fileprivate func handleDispatchedSurfaceAction(_ action: ResolvedAction, from surfaceID: String) async {
    let actionName: String
    let contextDict: [String: OrderedJSON.JSONValue]

    switch action.identity {
    case .event(let name, let context, _):
      actionName = name
      contextDict = context ?? [:]
    case .function(let call, let args):
      actionName = call
      contextDict = args ?? [:]
    }

    let contextJSON = encodeJSONDictionary(contextDict)
    let dataModelJSON = formattedDataModelJSON(for: surfaceID)

    eventLogs.insert(
      A2UIEventLog(
        kind: .action,
        surfaceID: surfaceID,
        summary: "Action '\(actionName)' from component '\(action.sourceComponentID ?? "unknown")'",
        payloadJSON: "Context: \(contextJSON)\n\nSurface DataModel:\n\(dataModelJSON)"
      ),
      at: 0
    )

    // Synthesize a user turn representing the UI interaction so the timeline stays naturally conversational
    let userSummaryMessage = A2UIChatMessage(
      content: "Triggered **`\(actionName)`** on surface `\(surfaceID)`.",
      participant: .user,
      actionBadge: "⚡ A2UI Action: \(actionName)"
    )
    messages.append(userSummaryMessage)

    // 1. If the user is on the Local A2A Agent Server (or if this surface came from A2A), forward the action over A2A JSON-RPC
    if selectedModel?.id == "a2a-local-agent" || originalSurfaceIDByTurnSurfaceID[surfaceID] != nil {
      let originalSurfaceID = originalSurfaceIDByTurnSurfaceID[surfaceID] ?? surfaceID
      let rawContextObject = decodeToFoundationDictionary(contextJSON)
      let a2aAction = A2AActionPayload(
        name: actionName,
        surfaceID: originalSurfaceID,
        sourceComponentID: action.sourceComponentID ?? "button",
        contextJSONObject: rawContextObject
      )
      await runLocalA2AAgentTurn(queryText: nil, action: a2aAction)
      return
    }

    // 2. If the user tapped "purchase" on the bundled Coffee Order card, immediately stream the Purchase Complete receipt card
    if actionName == "purchase",
      let receiptMatch = CatalogExamplesStore.messagesForExample(
        matching: "11_purchase-complete",
        targetSurfaceID: "receipt-\(UUID().uuidString.prefix(6))",
        in: bundledExamples
      )
    {
      await streamCatalogMessagesTurn(
        assistantID: UUID().uuidString,
        title: "Purchase Complete",
        markdownIntro: "Your **Sunrise Coffee** order has been confirmed! Here is your live A2UI receipt card (`11_purchase-complete.json`):",
        rawMessages: receiptMatch.messages
      )
      return
    }

    // 3. Forward any other A2UI surface action + live DataModel snapshot to Gemini 3 Flash / 3.1 Pro
    let activeModelID = selectedModel?.id ?? "gemini-3-flash-preview"
    let followUpPrompt = """
      The user just triggered the A2UI action "\(actionName)" (sourceComponentId: "\(action.sourceComponentID ?? "button")") on surface "\(surfaceID)".
      Action context: \(contextJSON)
      Current surface DataModel JSON: \(dataModelJSON)

      Respond to their action in 1–2 friendly sentences and emit an updated or confirmation A2UI v1.0 surface inside `<a2ui-json>[...]</a2ui-json>` reflecting the data they submitted.
      """
    await runGeminiTurn(promptText: followUpPrompt, modelID: activeModelID)
  }

  fileprivate func handleDispatchedRendererError(_ error: RendererError, from surfaceID: String) {
    let detail: String
    switch error {
    case .validationFailed(let err):
      detail = "[Validation] path=\(err.path): \(err.message)"
    case .generic(let err):
      detail = "[\(err.code)] \(err.message)"
    }

    lastTurnValidationError = detail
    eventLogs.insert(
      A2UIEventLog(
        kind: .error,
        surfaceID: surfaceID,
        summary: detail,
        payloadJSON: nil
      ),
      at: 0
    )
  }

  // MARK: - A2UI Message Ingestion

  @discardableResult
  private func ingestA2UIMessages(_ rawMessages: [String]) -> [String] {
    var touchedSurfaceIDs: [String] = []

    for raw in rawMessages {
      do {
        let parsedMessage = try parser.parse(jsonString: raw)
        let sid = extractSurfaceID(from: raw)
        processor.process(message: parsedMessage)
        if let sid {
          if !touchedSurfaceIDs.contains(sid) {
            touchedSurfaceIDs.append(sid)
          }
          if let surfaceVM = processor.surfaceGroupModel[sid] {
            surfaceVM.actionHandler = actionBridge
          }
        }
      } catch {
        eventLogs.insert(
          A2UIEventLog(
            kind: .error,
            surfaceID: "parser",
            summary: "JSON Parse Error: \(error.localizedDescription)",
            payloadJSON: raw
          ),
          at: 0
        )
      }
    }

    surfaceRevision += 1
    return touchedSurfaceIDs
  }

  // MARK: - Helpers

  private func updateAssistantMessage(id: String, mutate: (inout A2UIChatMessage) -> Void) {
    guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
    mutate(&messages[index])
  }

  private func detectLeadingCommandTrigger(in text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.hasPrefix("/") else { return nil }
    let firstToken = trimmed.dropFirst().split(whereSeparator: \.isWhitespace).first.map(String.init)
    return firstToken?.lowercased()
  }

  private func extractSurfaceID(from rawJSON: String) -> String? {
    guard
      let data = rawJSON.data(using: .utf8),
      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return nil
    }
    for key in ["createSurface", "updateComponents", "updateDataModel", "beginRendering", "surfaceUpdate", "dataModelUpdate"] {
      if let inner = obj[key] as? [String: Any],
        let sid = inner["surfaceId"] as? String
      {
        return sid
      }
    }
    return nil
  }

  private func rewriteA2ASurfaceIDs(_ rawMessages: [String], turnSuffix: String) -> [String] {
    var discoveredIDs: [String] = []
    for msg in rawMessages {
      if let sid = extractSurfaceID(from: msg), !discoveredIDs.contains(sid) {
        discoveredIDs.append(sid)
      }
    }
    var result = rawMessages
    for originalID in discoveredIDs {
      let turnID = "\(originalID)-\(turnSuffix)"
      originalSurfaceIDByTurnSurfaceID[turnID] = originalID
      result = result.map {
        $0.replacingOccurrences(of: "\"surfaceId\":\"\(originalID)\"", with: "\"surfaceId\":\"\(turnID)\"")
          .replacingOccurrences(of: "\"surfaceId\": \"\(originalID)\"", with: "\"surfaceId\": \"\(turnID)\"")
      }
    }
    return result
  }

  private func encodeJSONDictionary(_ dict: [String: OrderedJSON.JSONValue]) -> String {
    guard
      let data = try? JSONEncoder().encode(dict),
      let str = String(data: data, encoding: .utf8)
    else {
      return "{}"
    }
    return str
  }

  private func decodeToFoundationDictionary(_ jsonString: String) -> [String: Any] {
    guard
      let data = jsonString.data(using: .utf8),
      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return [:]
    }
    return obj
  }
}
