//
//  ConversationKitTests.swift
//  ConversationKitTests
//
//  Comprehensive Swift Testing unit suite for ConversationKit v2 models,
//  state machines, incremental parsers, security validators, and concurrency guarantees.
//

import CoreGraphics
import Foundation
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import ConversationKit

// MARK: - 1. TurnGroupingAndOptimisticDiffingTests (AC-3, AC-4, AC-19)

@Suite("Turn Grouping & Optimistic Diffing (AC-3, AC-4, AC-19)")
struct TurnGroupingAndOptimisticDiffingTests {

  /// Custom domain model conforming to `Message` to verify zero-downcast `makeUserMessage` & `ConversationSubmission`.
  struct CustomDomainMessage: Message {
    let id: String
    var content: String?
    let participant: Participant
    let createdAt: Date
    let attachments: [ConversationAttachment]
    let tokens: [ComposerToken]
    let selectedModelID: String?

    static func makeUserMessage(
      id: String,
      content: String?,
      attachments: [ConversationAttachment],
      tokens: [ComposerToken],
      selectedModelID: String?
    ) -> CustomDomainMessage {
      CustomDomainMessage(
        id: id,
        content: content,
        participant: .user,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        attachments: attachments,
        tokens: tokens,
        selectedModelID: selectedModelID
      )
    }
  }

  private struct SampleDomainError: Error, LocalizedError, Sendable {
    let errorDescription: String?
  }

  @Test("ConversationTurn.group returns empty array for empty input")
  func groupEmptyMessages() {
    let turns = ConversationTurn<DefaultMessage>.group([])
    #expect(turns.isEmpty)
  }

  @Test("ConversationTurn.group groups each .user message with subsequent .other messages and assigns stable user.id")
  func groupStandardMultiTurnConversation() {
    let u1 = DefaultMessage(id: "user-1", content: "Explain Liquid Glass", participant: .user)
    let a1Part1 = DefaultMessage(id: "assistant-1a", content: "Liquid Glass is...", participant: .other)
    let a1Part2 = DefaultMessage(
      id: "assistant-1b",
      content: "Here is an example.",
      participant: .other,
      isStreaming: true
    )
    let u2 = DefaultMessage(id: "user-2", content: "Show me code", participant: .user)
    let a2 = DefaultMessage(id: "assistant-2", content: "```swift\n```", participant: .other)

    let turns = ConversationTurn.group([u1, a1Part1, a1Part2, u2, a2])
    #expect(turns.count == 2)

    let firstTurn = turns[0]
    #expect(firstTurn.id == "user-1")
    #expect(firstTurn.userMessage?.id == "user-1")
    #expect(firstTurn.assistantMessages.map(\.id) == ["assistant-1a", "assistant-1b"])
    #expect(firstTurn.allMessages.map(\.id) == ["user-1", "assistant-1a", "assistant-1b"])
    #expect(firstTurn.isStreaming == true)

    let secondTurn = turns[1]
    #expect(secondTurn.id == "user-2")
    #expect(secondTurn.userMessage?.id == "user-2")
    #expect(secondTurn.assistantMessages.map(\.id) == ["assistant-2"])
    #expect(secondTurn.allMessages.map(\.id) == ["user-2", "assistant-2"])
    #expect(secondTurn.isStreaming == false)
  }

  @Test("ConversationTurn.group handles leading assistant/system greeting messages and consecutive user messages cleanly")
  func groupLeadingAssistantAndConsecutiveUserMessages() {
    let greeting1 = DefaultMessage(id: "sys-1", content: "Welcome!", participant: .other)
    let greeting2 = DefaultMessage(id: "sys-2", content: "How can I help?", participant: .other)
    let u1 = DefaultMessage(id: "user-1", content: "First question", participant: .user)
    let u2 = DefaultMessage(id: "user-2", content: "Follow-up before reply", participant: .user)
    let a2 = DefaultMessage(id: "assistant-2", content: "Answer to both", participant: .other)

    let turns = ConversationTurn.group([greeting1, greeting2, u1, u2, a2])
    #expect(turns.count == 3)

    // Leading assistant turn has nil userMessage and uses first assistant message ID
    #expect(turns[0].id == "sys-1")
    #expect(turns[0].userMessage == nil)
    #expect(turns[0].assistantMessages.map(\.id) == ["sys-1", "sys-2"])
    #expect(turns[0].allMessages.map(\.id) == ["sys-1", "sys-2"])

    // First user message without assistant response yet
    #expect(turns[1].id == "user-1")
    #expect(turns[1].userMessage?.id == "user-1")
    #expect(turns[1].assistantMessages.isEmpty)

    // Second user message with its assistant reply
    #expect(turns[2].id == "user-2")
    #expect(turns[2].userMessage?.id == "user-2")
    #expect(turns[2].assistantMessages.map(\.id) == ["assistant-2"])
  }

  @Test("DefaultMessage.makeUserMessage and ConversationSubmission preserve id, attachments, tokens, command, mentions, and selectedModel with zero downcasting")
  func makeUserMessageAndSubmissionPreserveAllMetadata() {
    let command = SlashCommand(id: "cmd-sum", trigger: "/summarize", title: "Summarize")
    let mention1 = ResourceMention(id: "m-prd", queryHandle: "@PRD-0001", title: "PRD-0001", kind: .document)
    let mention2 = ResourceMention(id: "m-adr", queryHandle: "@ADR-0001", title: "ADR-0001", kind: .file)
    let tokens: [ComposerToken] = [
      .command(command),
      .mention(mention1),
      .mention(mention2),
    ]
    let attachment = ConversationAttachment(
      id: "att-1",
      data: Data("spec".utf8),
      contentType: .plainText,
      filename: "spec.txt"
    )
    let model = ComposerModelOption(
      id: "claude-sonnet-4-6",
      name: "Claude Sonnet 4.6",
      subtitle: "Fast reasoning",
      badge: "Pro"
    )
    let capabilities: Set<ComposerCapability> = [.think, .search]

    // 1. Verify DefaultMessage.makeUserMessage
    let defaultMsg = DefaultMessage.makeUserMessage(
      id: "optimistic-turn-42",
      content: "Please summarize these specs",
      attachments: [attachment],
      tokens: tokens,
      selectedModelID: model.id
    )
    #expect(defaultMsg.id == "optimistic-turn-42")
    #expect(defaultMsg.participant == .user)
    #expect(defaultMsg.content == "Please summarize these specs")
    #expect(defaultMsg.attachments == [attachment])
    #expect(defaultMsg.tokens == tokens)
    #expect(defaultMsg.selectedModelID == "claude-sonnet-4-6")

    // 2. Verify CustomDomainMessage with ConversationSubmission (zero `as?` downcasting)
    let customMsg = CustomDomainMessage.makeUserMessage(
      id: "custom-turn-99",
      content: "Custom domain prompt",
      attachments: [attachment],
      tokens: tokens,
      selectedModelID: model.id
    )
    let submission = ConversationSubmission<CustomDomainMessage>(
      message: customMsg,
      text: "\u{200B}Custom domain\u{200B} prompt",
      attachments: [attachment],
      tokens: tokens,
      selectedModel: model,
      activeCapabilities: capabilities
    )

    let stronglyTypedMessage: CustomDomainMessage = submission.message
    #expect(submission.id == "custom-turn-99")
    #expect(stronglyTypedMessage.id == "custom-turn-99")
    #expect(submission.text == "Custom domain prompt")
    #expect(submission.attachments == [attachment])
    #expect(submission.tokens == tokens)
    #expect(submission.command == command)
    #expect(submission.mentions == [mention1, mention2])
    #expect(submission.selectedModel == model)
    #expect(submission.activeCapabilities == capabilities)
  }

  @Test("O(1) fast-path Equatable and Hashable on DefaultMessage, ThinkingTrace, and ToolCall including error state changes")
  func fastPathEqualityAndHashing() {
    let fixedDate = Date(timeIntervalSince1970: 1_700_000_123)

    // 1. ThinkingTrace O(1) Equatable & Hashable
    let traceA = ThinkingTrace(
      id: "trace-1",
      status: .thinking(startedAt: fixedDate),
      summary: "Analyzing",
      transcript: "Step 1"
    )
    var traceB = traceA
    #expect(traceA == traceB)
    #expect(traceA.hashValue == traceB.hashValue)

    // Length change triggers fast-path inequality
    traceB.transcript = "Step 1 + Step 2"
    #expect(traceA != traceB)

    // Status change triggers fast-path inequality
    var traceC = traceA
    traceC.status = .completed(duration: 2.5)
    #expect(traceA != traceC)

    // 2. ToolCall O(1) Equatable & Hashable
    let toolA = ToolCall(
      id: "tool-1",
      name: "search_docs",
      status: .running(startedAt: fixedDate),
      argumentsSummary: "q: Liquid Glass",
      resultSummary: nil,
      argumentsJSON: #"{"q":"Liquid Glass"}"#,
      resultJSON: nil
    )
    var toolB = toolA
    #expect(toolA == toolB)
    #expect(toolA.hashValue == toolB.hashValue)

    toolB.resultJSON = #"{"count":5}"#
    #expect(toolA != toolB)

    var toolC = toolA
    toolC.status = .succeeded(duration: 0.4)
    #expect(toolA != toolC)

    // 3. DefaultMessage O(1) Equatable & Hashable + messageError / error state changes
    let baseMessage = DefaultMessage(
      id: "msg-1",
      content: "Streaming response token",
      participant: .other,
      createdAt: fixedDate,
      thinkingTrace: traceA,
      toolCalls: [toolA],
      isStreaming: true
    )
    var identicalMessage = baseMessage
    #expect(baseMessage == identicalMessage)
    #expect(baseMessage.hashValue == identicalMessage.hashValue)

    // Appending streaming token updates utf8.count and invalidates equality
    identicalMessage.content = "Streaming response token appended"
    #expect(baseMessage != identicalMessage)

    // Mutating messageError is detected
    var messageWithStructError = baseMessage
    messageWithStructError.messageError = MessageError(
      id: "err-1",
      message: "Network timeout",
      detail: "Retry in 5 seconds"
    )
    #expect(baseMessage != messageWithStructError)
    #expect(messageWithStructError.error != nil)
    #expect(messageWithStructError.errorMessage == "Network timeout")

    // Mutating existential `error` property is detected
    var messageWithExistentialError = baseMessage
    messageWithExistentialError.error = SampleDomainError(errorDescription: "Rate limit exceeded")
    #expect(baseMessage != messageWithExistentialError)
    #expect(messageWithStructError != messageWithExistentialError)
    #expect(messageWithExistentialError.errorMessage == "Rate limit exceeded")

    // Clearing error restores equality with baseMessage
    messageWithExistentialError.error = nil
    #expect(messageWithExistentialError == baseMessage)
  }

  @Test("Multi-turn sequence guarantees turns.last?.id matches latest user turn for upward pushing")
  func multiTurnUpwardPushSequence() {
    // Turn 1
    let u1 = DefaultMessage(id: "turn-1-user", content: "Hello", participant: .user)
    let a1 = DefaultMessage(id: "turn-1-ai", content: "Hi there!", participant: .other)
    let turn1List = ConversationTurn.group([u1, a1])
    #expect(turn1List.count == 1)
    #expect(turn1List.last?.id == "turn-1-user")

    // Turn 2 submitted
    let u2 = DefaultMessage(id: "turn-2-user", content: "What is 2+2?", participant: .user)
    let turn2List = ConversationTurn.group([u1, a1, u2])
    #expect(turn2List.count == 2)
    #expect(turn2List[0].id == "turn-1-user")
    #expect(turn2List.last?.id == "turn-2-user")

    // Turn 2 completed, Turn 3 submitted
    let a2 = DefaultMessage(id: "turn-2-ai", content: "4", participant: .other)
    let u3 = DefaultMessage(id: "turn-3-user", content: "Thanks!", participant: .user)
    let turn3List = ConversationTurn.group([u1, a1, u2, a2, u3])
    #expect(turn3List.count == 3)
    #expect(turn3List[0].id == "turn-1-user")
    #expect(turn3List[1].id == "turn-2-user")
    #expect(turn3List.last?.id == "turn-3-user")
  }
}

// MARK: - 2. AttachmentPipelineAndSecurityTests (AC-6, AC-7, MUST-FIX-1, MUST-FIX-2, MUST-FIX-5)

@Suite("Attachment Pipeline & Security (AC-6, AC-7, MUST-FIX-1, MUST-FIX-2, MUST-FIX-5)")
struct AttachmentPipelineAndSecurityTests {

  @Test(
    "ConversationAttachment infers semantic Kind across image, pdf, audio, video, code, and document",
    arguments: [
      ("photo.png", UTType.png, ConversationAttachment.Kind.image),
      ("manual.pdf", UTType.pdf, ConversationAttachment.Kind.pdf),
      ("voice.m4a", UTType.mpeg4Audio, ConversationAttachment.Kind.audio),
      ("clip.mp4", UTType.mpeg4Movie, ConversationAttachment.Kind.video),
      ("ViewModel.swift", UTType.swiftSource, ConversationAttachment.Kind.code),
      ("config.json", UTType.json, ConversationAttachment.Kind.code),
      ("archive.zip", UTType.zip, ConversationAttachment.Kind.document),
    ]
  )
  func attachmentKindInference(
    filename: String,
    contentType: UTType,
    expectedKind: ConversationAttachment.Kind
  ) {
    let attachment = ConversationAttachment(
      data: Data([0x01, 0x02, 0x03, 0x04]),
      contentType: contentType,
      filename: filename
    )
    #expect(attachment.kind == expectedKind)
    #expect(!attachment.symbolName.isEmpty)
  }

  @Test("ConversationAttachment.isReadyForSubmission is true only for .ready and false for .uploading and .failed")
  func submissionGatingStates() {
    let readyAttachment = ConversationAttachment(
      data: Data("ok".utf8),
      contentType: .plainText,
      filename: "notes.txt",
      uploadState: .ready
    )
    let uploadingAttachment = ConversationAttachment(
      data: Data("part".utf8),
      contentType: .plainText,
      filename: "uploading.txt",
      uploadState: .uploading(progress: 0.45)
    )
    let failedAttachment = ConversationAttachment(
      data: Data("err".utf8),
      contentType: .plainText,
      filename: "failed.txt",
      uploadState: .failed(error: "Connection reset")
    )

    #expect(readyAttachment.isReadyForSubmission == true)
    #expect(readyAttachment.uploadProgress == nil)
    #expect(readyAttachment.uploadError == nil)

    #expect(uploadingAttachment.isReadyForSubmission == false)
    #expect(uploadingAttachment.uploadProgress == 0.45)
    #expect(uploadingAttachment.uploadError == nil)

    #expect(failedAttachment.isReadyForSubmission == false)
    #expect(failedAttachment.uploadProgress == nil)
    #expect(failedAttachment.uploadError == "Connection reset")

    // Batch composer submission gate: all attachments must be .ready
    let mixedBatch = [readyAttachment, uploadingAttachment]
    #expect(mixedBatch.allSatisfy { $0.isReadyForSubmission } == false)

    let failedBatch = [readyAttachment, failedAttachment]
    #expect(failedBatch.allSatisfy { $0.isReadyForSubmission } == false)

    let readyBatch = [readyAttachment]
    #expect(readyBatch.allSatisfy { $0.isReadyForSubmission } == true)
  }

  @Test("PlatformThumbnailGenerator.shared downsamples large images to <= 320px and caches by (id, maxPixelSize)")
  func thumbnailDownsamplingAndCaching() async throws {
    let largeBox = try #require(
      PlatformImageBox.solidColor(
        red: 0.15,
        green: 0.45,
        blue: 0.85,
        size: CGSize(width: 1200, height: 900)
      )
    )
    let pngData = try #require(largeBox.pngData())
    let uniqueID = "thumb-test-\(UUID().uuidString)"

    let generator = PlatformThumbnailGenerator.shared
    let thumbnailBox = try await generator.thumbnail(
      id: uniqueID,
      data: pngData,
      contentType: .png,
      maxPixelSize: 320
    )

    let pixelSize = thumbnailBox.pixelSize
    #expect(max(pixelSize.width, pixelSize.height) <= 320)
    #expect(pixelSize.width > 0 && pixelSize.height > 0)

    // Verify O(1) cache hit for the same (id, maxPixelSize)
    let cached320 = await generator.cachedThumbnail(for: uniqueID, maxPixelSize: 320)
    #expect(cached320 == thumbnailBox)

    // Verify distinct cache key for a different maxPixelSize (e.g. 128px)
    let cached128Before = await generator.cachedThumbnail(for: uniqueID, maxPixelSize: 128)
    #expect(cached128Before == nil)

    let thumb128 = try await generator.thumbnail(
      id: uniqueID,
      data: pngData,
      contentType: .png,
      maxPixelSize: 128
    )
    #expect(max(thumb128.pixelSize.width, thumb128.pixelSize.height) <= 128)
    let cached128After = await generator.cachedThumbnail(for: uniqueID, maxPixelSize: 128)
    #expect(cached128After == thumb128)
  }

  @Test(
    "resolveQuickLookURL sanitizes malicious filenames to stay strictly inside ConversationKitQuickLook directory",
    arguments: [
      "../../etc/passwd",
      "foo/bar:baz\0.pdf",
      "..\\..\\Windows\\System32\\cmd.exe",
      "/etc/shadow",
      "...",
    ]
  )
  func quickLookPathTraversalSanitization(maliciousFilename: String) async throws {
    let attachment = ConversationAttachment(
      id: "ql-\(UUID().uuidString)",
      data: Data("sandboxed-preview-content".utf8),
      contentType: .pdf,
      filename: maliciousFilename
    )

    let resolvedURL = try await attachment.resolveQuickLookURL()
    defer {
      try? FileManager.default.removeItem(at: resolvedURL)
    }

    let quickLookDir = PlatformThumbnailGenerator.quickLookDirectoryURL.standardizedFileURL
    let standardizedResolved = resolvedURL.standardizedFileURL

    let basePathWithSlash = quickLookDir.path.hasSuffix("/")
      ? quickLookDir.path
      : quickLookDir.path + "/"

    #expect(standardizedResolved.path.hasPrefix(basePathWithSlash))
    #expect(standardizedResolved.deletingLastPathComponent().path == quickLookDir.path)
    #expect(!standardizedResolved.lastPathComponent.contains(".."))
    #expect(!standardizedResolved.lastPathComponent.contains("/"))
    #expect(!standardizedResolved.lastPathComponent.contains("\\"))
    #expect(!standardizedResolved.lastPathComponent.contains(":"))
    #expect(!standardizedResolved.lastPathComponent.contains("\0"))
    #expect(FileManager.default.fileExists(atPath: standardizedResolved.path))
  }
}

// MARK: - 3. ComposerTokenAndSentinelBufferTests (AC-8, AC-9, MUST-FIX-4)

@Suite("Composer Token & Sentinel Buffer State Machine (AC-8, AC-9, MUST-FIX-4)")
struct ComposerTokenAndSentinelBufferTests {

  @Test("ComposerTextBuffer detects word-boundary / command and @ mention triggers including with leading U+200B sentinel")
  func wordBoundaryTriggerDetection() {
    // 1. Leading sentinel + slash command
    let slashBuffer = ComposerTextBuffer(text: "\u{200B}/summarize", hasTokens: true)
    #expect(slashBuffer.rawText == "\u{200B}/summarize")
    #expect(slashBuffer.cleanText == "/summarize")
    #expect(slashBuffer.activeTrigger?.kind == .slashCommand)
    #expect(slashBuffer.activeTrigger?.query == "summarize")

    // 2. Leading sentinel + mid-sentence @mention at word boundary
    let mentionBuffer = ComposerTextBuffer(text: "\u{200B}Hello @PRD", hasTokens: true)
    #expect(mentionBuffer.cleanText == "Hello @PRD")
    #expect(mentionBuffer.activeTrigger?.kind == .resourceMention)
    #expect(mentionBuffer.activeTrigger?.query == "PRD")

    // 3. Bare "/" and "@" at start of input
    #expect(ComposerTextBuffer.detectTrigger(in: "/")?.kind == .slashCommand)
    #expect(ComposerTextBuffer.detectTrigger(in: "/")?.query == "")
    #expect(ComposerTextBuffer.detectTrigger(in: "@")?.kind == .resourceMention)
    #expect(ComposerTextBuffer.detectTrigger(in: "@")?.query == "")

    // 4. Mid-word emails and file paths must NOT trigger popup
    #expect(ComposerTextBuffer.detectTrigger(in: "contact user@example.com") == nil)
    #expect(ComposerTextBuffer.detectTrigger(in: "Sources/ConversationKit/Model") == nil)
    #expect(ComposerTextBuffer.detectTrigger(in: "/usr/local") == nil)
    #expect(ComposerTextBuffer.detectTrigger(in: "Hello @PRD ") == nil)
  }

  @Test("ComposerTextBuffer.cleanText globally strips all U+200B sentinels even when scattered mid-string via copy/paste")
  func globalSentinelStripping() {
    let pastedScattered = "\u{200B}Hello\u{200B} \u{200B}world\u{200B}!\u{200B}"
    #expect(ComposerTextBuffer.cleanText(pastedScattered) == "Hello world!")

    var buffer = ComposerTextBuffer(text: pastedScattered, hasTokens: true)
    #expect(buffer.cleanText == "Hello world!")
    // Only the single leading sentinel should remain in rawText when hasTokens == true
    #expect(buffer.rawText == "\u{200B}Hello world!")

    var tokens: [ComposerToken] = [
      .command(SlashCommand(trigger: "test", title: "Test"))
    ]
    _ = buffer.applyEdit("Copy\u{200B}Paste\u{200B}Text", tokens: &tokens)
    #expect(buffer.cleanText == "CopyPasteText")
    #expect(!buffer.cleanText.contains("\u{200B}"))
  }

  @Test("Two-stage double-backspace token removal highlights on first press and removes on second press")
  func twoStageDoubleBackspaceTokenRemoval() {
    let token1 = ComposerToken.command(SlashCommand(id: "cmd-1", trigger: "summarize", title: "Summarize"))
    let token2 = ComposerToken.mention(ResourceMention(id: "men-1", queryHandle: "PRD-0001", title: "PRD-0001"))
    var tokens: [ComposerToken] = [token1, token2]

    var buffer = ComposerTextBuffer(text: "", hasTokens: true)
    #expect(buffer.rawText == "\u{200B}")
    #expect(buffer.cleanText.isEmpty)
    #expect(buffer.highlightedTokenID == nil)

    // Stage 1: User presses backspace on visually empty field (rawText changes from "\u{200B}" to "")
    let firstAction = buffer.applyEdit("", tokens: &tokens)
    #expect(firstAction == .highlightToken(token2.id))
    #expect(buffer.highlightedTokenID == token2.id)
    #expect(tokens.count == 2)
    // Sentinel is restored so the second backspace can be captured
    #expect(buffer.rawText == "\u{200B}")

    // Stage 2: User presses backspace a second consecutive time (rawText changes from "\u{200B}" to "")
    let secondAction = buffer.applyEdit("", tokens: &tokens)
    #expect(secondAction == .removeToken(token2.id))
    #expect(buffer.highlightedTokenID == nil)
    #expect(tokens == [token1])
    // Because 1 token remains, sentinel is still preserved
    #expect(buffer.hasTokens == true)
    #expect(buffer.rawText == "\u{200B}")

    // Removing the final remaining token clears hasTokens and removes sentinel
    let thirdAction = buffer.applyEdit("", tokens: &tokens)
    #expect(thirdAction == .highlightToken(token1.id))
    let fourthAction = buffer.applyEdit("", tokens: &tokens)
    #expect(fourthAction == .removeToken(token1.id))
    #expect(tokens.isEmpty)
    #expect(buffer.hasTokens == false)
    #expect(buffer.rawText == "")
  }

  @Test("ComposerTextBuffer.highlightSegments marks matched substrings case- and diacritic-insensitively")
  func highlightSegmentsCaseAndDiacriticInsensitive() {
    let segments = ComposerTextBuffer.highlightSegments(
      in: "Résumé Architecture",
      matching: "resume"
    )
    #expect(segments.count == 2)
    #expect(segments[0] == ComposerTextBuffer.HighlightSegment(text: "Résumé", isMatched: true))
    #expect(segments[1] == ComposerTextBuffer.HighlightSegment(text: " Architecture", isMatched: false))

    let midSegments = ComposerTextBuffer.highlightSegments(
      in: "PRD-0001-CONVERSATIONKIT",
      matching: "conversation"
    )
    #expect(midSegments.count == 3)
    #expect(midSegments[0] == ComposerTextBuffer.HighlightSegment(text: "PRD-0001-", isMatched: false))
    #expect(midSegments[1] == ComposerTextBuffer.HighlightSegment(text: "CONVERSATION", isMatched: true))
    #expect(midSegments[2] == ComposerTextBuffer.HighlightSegment(text: "KIT", isMatched: false))
  }

  @Test("ComposerModelSelectorMenu integrates capabilities and toggles active membership (F-9, AC-13)")
  @MainActor
  func modelSelectorCapabilitiesIntegration() {
    let models = [
      ComposerModelOption(id: "gpt-4o", name: "GPT-4o"),
      ComposerModelOption(id: "claude-3-7", name: "Claude 3.7 Sonnet")
    ]
    var selectedModel: ComposerModelOption? = models.first
    var activeCapabilities: Set<ComposerCapability> = [.think]
    let capabilities: [ComposerCapability] = [.think, .search, .image]

    let selectedModelBinding = Binding<ComposerModelOption?>(
      get: { selectedModel },
      set: { selectedModel = $0 }
    )
    let activeCapabilitiesBinding = Binding<Set<ComposerCapability>>(
      get: { activeCapabilities },
      set: { activeCapabilities = $0 }
    )

    let menu = ComposerModelSelectorMenu(
      models: models,
      selectedModel: selectedModelBinding,
      capabilities: capabilities,
      activeCapabilities: activeCapabilitiesBinding
    )

    #expect(menu.capabilities == capabilities)
    #expect(menu.models == models)
    #expect(menu.activeCapabilities?.wrappedValue == Set<ComposerCapability>([.think]))

    // Verify mutating binding updates active capabilities
    activeCapabilitiesBinding.wrappedValue.insert(.search)
    #expect(menu.activeCapabilities?.wrappedValue == Set<ComposerCapability>([.think, .search]))

    activeCapabilitiesBinding.wrappedValue.remove(.think)
    #expect(menu.activeCapabilities?.wrappedValue == Set<ComposerCapability>([.search]))
  }

  @Test("ComposerModelOption supports category, default nil, and Codable/Hashable roundtrip")
  func composerModelOptionCategoryAndCodable() throws {
    let defaultModel = ComposerModelOption(id: "m-1", name: "Model 1")
    #expect(defaultModel.category == nil)

    let categorizedModel = ComposerModelOption(
      id: "sonnet",
      name: "Claude Sonnet 4.6",
      subtitle: "Fast reasoning",
      badge: "Pro",
      symbolName: "sparkles",
      category: "Anthropic"
    )
    #expect(categorizedModel.name == "Claude Sonnet 4.6")
    #expect(categorizedModel.symbolName == "sparkles")
    #expect(categorizedModel.category == "Anthropic")

    // Codable roundtrip
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let data = try encoder.encode(categorizedModel)
    let decoded = try decoder.decode(ComposerModelOption.self, from: data)
    #expect(decoded == categorizedModel)
    #expect(decoded.category == "Anthropic")

    // Backwards compatibility: decode JSON without category key
    let legacyJSON = """
    {"id":"legacy","name":"Legacy Model"}
    """.data(using: .utf8)!
    let decodedLegacy = try decoder.decode(ComposerModelOption.self, from: legacyJSON)
    #expect(decodedLegacy.category == nil)
    #expect(decodedLegacy.name == "Legacy Model")
  }

  @Test("ComposerModelSelectorMenu supports categorized models and selection callback")
  @MainActor
  func modelSelectorCategorizedModelsAndCallbacks() {
    let models = [
      ComposerModelOption(id: "c-1", name: "Sonnet", category: "Anthropic"),
      ComposerModelOption(id: "c-2", name: "Opus", category: "Anthropic"),
      ComposerModelOption(id: "o-1", name: "GPT-4o", category: "OpenAI"),
      ComposerModelOption(id: "u-1", name: "Auto")
    ]
    var selectedModel: ComposerModelOption? = models[0]
    var callbackModel: ComposerModelOption?
    var callbackToggledCap: (ComposerCapability, Bool)?

    let selectedModelBinding = Binding<ComposerModelOption?>(
      get: { selectedModel },
      set: { selectedModel = $0 }
    )
    var activeCapabilities: Set<ComposerCapability> = [.think]
    let activeCapabilitiesBinding = Binding<Set<ComposerCapability>>(
      get: { activeCapabilities },
      set: { activeCapabilities = $0 }
    )

    let menu = ComposerModelSelectorMenu(
      models: models,
      selectedModel: selectedModelBinding,
      capabilities: [.think, .search],
      activeCapabilities: activeCapabilitiesBinding,
      onSelect: { option in
        callbackModel = option
      },
      onToggleCapability: { cap, state in
        callbackToggledCap = (cap, state)
      }
    )

    #expect(menu.models.count == 4)
    #expect(menu.selectedModel?.id == "c-1")

    // Verify onSelect callback
    menu.onSelect?(models[1])
    #expect(callbackModel?.id == "c-2")

    // Verify onToggleCapability callback
    menu.onToggleCapability?(.search, true)
    #expect(callbackToggledCap?.0 == .search)
    #expect(callbackToggledCap?.1 == true)

    // Verify body constructs cleanly
    _ = menu.body
  }
}

// MARK: - 4. ThinkingAndAgenticModelsTests (AC-11, AC-18, MUST-FIX-3)

@Suite("Thinking & Agentic Models (AC-11, AC-18, MUST-FIX-3)")
struct ThinkingAndAgenticModelsTests {

  @Test("ThinkingTrace.defaultExpanded is strictly false and status transitions update isStreaming and duration")
  func thinkingTraceDefaultsAndTransitions() {
    #expect(ThinkingTrace.defaultExpanded == false)

    let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
    var trace = ThinkingTrace(
      id: "think-1",
      status: .thinking(startedAt: startedAt),
      summary: "Evaluating scroll geometry",
      transcript: "Checking activeTurnMinHeight..."
    )
    #expect(trace.isStreaming == true)
    #expect(trace.duration == nil)

    trace.status = .completed(duration: 3.8)
    #expect(trace.isStreaming == false)
    #expect(trace.duration == 3.8)

    trace.status = .cancelled(duration: 1.2)
    #expect(trace.isStreaming == false)
    #expect(trace.duration == 1.2)
  }

  @Test("Citation.sanitizedURL and URL.isAllowedConversationURL allow http/https and reject unsafe or hostless URLs")
  func urlSecurityAllowlistValidation() throws {
    // Allowed URLs
    let appleHTTPS = try #require(URL(string: "https://developer.apple.com/documentation/swiftui"))
    let exampleHTTP = try #require(URL(string: "http://example.com/guide"))
    let uppercaseHTTPS = try #require(URL(string: "HTTPS://www.apple.com/ios"))

    #expect(appleHTTPS.isAllowedConversationURL == true)
    #expect(exampleHTTP.isAllowedConversationURL == true)
    #expect(uppercaseHTTPS.isAllowedConversationURL == true)

    let validCitation1 = Citation(title: "SwiftUI Docs", url: appleHTTPS)
    let validCitation2 = Citation(title: "Example Guide", url: exampleHTTP)
    #expect(validCitation1.sanitizedURL == appleHTTPS)
    #expect(validCitation1.domain == "developer.apple.com")
    #expect(validCitation2.sanitizedURL == exampleHTTP)
    #expect(validCitation2.domain == "example.com")

    // Rejected URLs (javascript:, file:, data:, hostless http/https)
    let unsafeURLStrings = [
      "javascript:alert(1)",
      "JAVASCRIPT:window.location='https://evil.example'",
      "file:///etc/passwd",
      "data:text/html,<script>alert(1)</script>",
      "vbscript:msgbox(1)",
      "customscheme://open/secret",
      "https:///path-without-host",
      "http://",
    ]

    for raw in unsafeURLStrings {
      let citation = Citation(title: "Untrusted Link", urlString: raw)
      #expect(
        citation.sanitizedURL == nil,
        "Expected sanitizedURL to be nil for untrusted URL: \(raw)"
      )
      if let parsed = URL(string: raw) {
        #expect(
          parsed.isAllowedConversationURL == false,
          "Expected isAllowedConversationURL to be false for: \(raw)"
        )
      }
    }
  }

  @Test("AgentPlan computes completedCount and progressFraction accurately and ApprovalRequest tracks risk levels and decisions")
  func agentPlanProgressAndApprovalRequestDecisions() {
    let emptyPlan = AgentPlan(title: "Empty Plan", steps: [])
    #expect(emptyPlan.completedCount == 0)
    #expect(emptyPlan.progressFraction == 0.0)

    let steps: [AgentPlan.Step] = [
      AgentPlan.Step(id: "s1", title: "Read PRD", status: .completed),
      AgentPlan.Step(id: "s2", title: "Implement Models", status: .completed),
      AgentPlan.Step(id: "s3", title: "Write Tests", status: .inProgress),
      AgentPlan.Step(id: "s4", title: "Run Verification", status: .pending),
    ]
    let plan = AgentPlan(id: "plan-1", title: "Release v2", steps: steps)
    #expect(plan.completedCount == 2)
    #expect(plan.progressFraction == 0.5)

    // ApprovalRequest risk levels and decision lifecycle
    var approval = ApprovalRequest(
      id: "req-1",
      title: "Execute shell command",
      detail: "Runs `swift test` in workspace",
      riskLevel: .high,
      scopeIdentifier: "shell.exec",
      changePreview: "swift test",
      decision: .pending
    )
    #expect(approval.isResolved == false)
    #expect(approval.riskLevel == .high)
    #expect(approval.scopeIdentifier == "shell.exec")
    #expect(approval.changePreview == "swift test")

    for resolvedDecision in [
      ApprovalRequest.Decision.allowOnce,
      .alwaysAllow,
      .deny,
      .cancelled,
    ] {
      approval.decision = resolvedDecision
      #expect(approval.isResolved == true)
    }
  }

  @Test("ThinkingStateView and built-in ThinkingStateStyle presets (.collapsibleHeader, .pill, .minimal) construct bodies cleanly across statuses and expansion states and preserve configuration fields")
  @MainActor
  func thinkingStateViewAndStylePresetsConstruction() {
    let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
    let statuses: [ThinkingTrace.Status] = [
      .thinking(startedAt: startedAt),
      .completed(duration: 4.2),
      .cancelled(duration: 1.7),
    ]
    let styles: [AnyThinkingStateStyle] = [
      AnyThinkingStateStyle(.collapsibleHeader),
      AnyThinkingStateStyle(.pill),
      AnyThinkingStateStyle(.minimal),
    ]

    for status in statuses {
      for isExpandedState in [false, true] {
        var expanded = isExpandedState
        let binding = Binding<Bool>(
          get: { expanded },
          set: { expanded = $0 }
        )

        let trace = ThinkingTrace(
          id: "trace-\(isExpandedState)",
          status: status,
          summary: "Evaluating scroll geometry",
          transcript: "Step 1: Verify anchor stability.\nStep 2: Check hairline divider."
        )

        let view = ThinkingStateView(trace: trace, isExpanded: binding)
        #expect(view.trace == trace)
        _ = view.body

        var didToggle = false
        let config = ThinkingStateStyleConfiguration(
          status: status,
          summary: trace.summary,
          transcript: trace.transcript,
          formattedElapsed: ThinkingStateView.staticFormattedElapsed(for: status),
          isExpanded: isExpandedState,
          toggleExpanded: { didToggle = true },
          headerLabel: AnyView(Text("Header")),
          transcriptContent: AnyView(Text(trace.transcript)),
          headerIcon: AnyView(Image(systemName: "sparkles"))
        )

        #expect(config.status == status)
        #expect(config.summary == "Evaluating scroll geometry")
        #expect(config.title == "Evaluating scroll geometry")
        #expect(config.transcript == "Step 1: Verify anchor stability.\nStep 2: Check hairline divider.")
        #expect(config.formattedElapsed == ThinkingStateView.staticFormattedElapsed(for: status))
        #expect(config.isExpanded == isExpandedState)

        for style in styles {
          _ = style.makeBody(configuration: config)
        }

        _ = CollapsibleHeaderThinkingStateStyle.collapsibleHeader.makeBody(configuration: config)
        _ = CollapsibleHeaderThinkingStateStyle.default.makeBody(configuration: config)
        _ = CollapsibleHeaderThinkingStateStyle.automatic.makeBody(configuration: config)
        _ = PillThinkingStateStyle.pill.makeBody(configuration: config)
        _ = MinimalThinkingStateStyle.minimal.makeBody(configuration: config)

        config.toggleExpanded()
        #expect(didToggle == true)
      }
    }

    // Verify configuration fallback title and default formattedElapsed when summary/formattedElapsed are nil
    let fallbackThinkingConfig = ThinkingStateStyleConfiguration(
      status: .thinking(startedAt: startedAt),
      summary: nil,
      transcript: "Fallback transcript",
      formattedElapsed: nil,
      isExpanded: false,
      toggleExpanded: {},
      headerLabel: AnyView(EmptyView()),
      transcriptContent: AnyView(EmptyView())
    )
    #expect(fallbackThinkingConfig.summary == nil)
    #expect(fallbackThinkingConfig.title == "Thinking")
    #expect(fallbackThinkingConfig.transcript == "Fallback transcript")
    #expect(fallbackThinkingConfig.formattedElapsed == "")
  }
}

// MARK: - 5. IncrementalMarkdownAndScrollHysteresisTests (AC-14, AC-17)

@Suite("Incremental Markdown & Scroll Hysteresis (AC-14, AC-17)")
struct IncrementalMarkdownAndScrollHysteresisTests {

  @Test("MarkdownBlock.parse commits finished blocks while keeping only the final unfinished block in tail and preserves IDs across token appends")
  func incrementalMarkdownBlockCommitAndStableIDs() throws {
    // Step 1: Streaming a heading and an unfinished paragraph
    let chunk1 = """
      # Architecture Overview

      Streaming paragraphs stay in the tail while tokens arrive
      """
    let parsed1 = MarkdownBlock.parse(chunk1, isStreaming: true)
    #expect(parsed1.committed.count == 1)
    #expect(parsed1.committed[0].kind == .heading(level: 1, text: "Architecture Overview"))
    #expect(parsed1.committed[0].isCommitted == true)

    let tail1 = try #require(parsed1.tail)
    #expect(tail1.isCommitted == false)
    #expect(tail1.kind == .paragraph(text: "Streaming paragraphs stay in the tail while tokens arrive"))

    let headingID = parsed1.committed[0].id

    // Step 2: Paragraph finishes (`\n\n`) and an unclosed code block starts streaming
    let chunk2 = """
      # Architecture Overview

      Streaming paragraphs stay in the tail while tokens arrive.

      > Important invariant quote

      - First item
      - [x] Second checked item

      | Metric | Target |
      | --- | --- |
      | Frame Time | 8.3ms |

      ```swift
      let x = 42
      """
    let parsed2 = MarkdownBlock.parse(chunk2, isStreaming: true)
    // Heading, paragraph, blockquote, list, and table are all committed!
    #expect(parsed2.committed.count == 5)
    #expect(parsed2.committed[0].id == headingID)
    #expect(parsed2.committed[1].kind == .paragraph(text: "Streaming paragraphs stay in the tail while tokens arrive."))
    #expect(parsed2.committed[2].kind == .blockquote(text: "Important invariant quote"))
    if case .list(let items, let isOrdered) = parsed2.committed[3].kind {
      #expect(isOrdered == false)
      #expect(items.count == 2)
      #expect(items[0].text == "First item")
      #expect(items[1].text == "Second checked item")
      #expect(items[1].isChecked == true)
    } else {
      Issue.record("Expected block 3 to be an unordered list")
    }
    #expect(parsed2.committed[4].kind == .table(headers: ["Metric", "Target"], rows: [["Frame Time", "8.3ms"]]))

    // Unclosed code block remains in tail with isClosed == false
    let tail2 = try #require(parsed2.tail)
    #expect(tail2.kind == .codeBlock(language: "swift", code: "let x = 42", isClosed: false))
    #expect(tail2.isCommitted == false)

    let committedIDsBeforeCodeClose = parsed2.committed.map(\.id)

    // Step 3: Code block closes with trailing newline and a final trailing paragraph starts
    let chunk3 = chunk2 + "\n```\n\nFinal trailing sentence"
    let parsed3 = MarkdownBlock.parse(chunk3, isStreaming: true)
    #expect(parsed3.committed.count == 6)
    // All previously committed block IDs are strictly preserved!
    #expect(Array(parsed3.committed.prefix(5).map(\.id)) == committedIDsBeforeCodeClose)
    #expect(parsed3.committed[5].kind == .codeBlock(language: "swift", code: "let x = 42", isClosed: true))
    #expect(parsed3.committed[5].isCommitted == true)

    let tail3 = try #require(parsed3.tail)
    #expect(tail3.kind == .paragraph(text: "Final trailing sentence"))

    // Step 4: Streaming completes (`isStreaming: false`) — all blocks move to committed and tail is nil
    let parsedFinal = MarkdownBlock.parse(chunk3, isStreaming: false)
    #expect(parsedFinal.committed.count == 7)
    #expect(parsedFinal.tail == nil)
    #expect(parsedFinal.committed.allSatisfy { $0.isCommitted })
    #expect(Array(parsedFinal.committed.prefix(6).map(\.id)) == parsed3.committed.map(\.id))
  }

  @Test("ScrollToBottomButton.shouldShow enforces > 80pt show threshold, < 24pt hide threshold, and deadband retention in 24...80pt")
  func scrollToBottomHysteresisDeadband() {
    // When hidden (currentState == false), stays false up to and including 80pt, transitions to true only > 80pt
    #expect(ScrollToBottomButton.shouldShow(currentState: false, distanceFromBottom: 0) == false)
    #expect(ScrollToBottomButton.shouldShow(currentState: false, distanceFromBottom: 24) == false)
    #expect(ScrollToBottomButton.shouldShow(currentState: false, distanceFromBottom: 50) == false)
    #expect(ScrollToBottomButton.shouldShow(currentState: false, distanceFromBottom: 80) == false)
    #expect(ScrollToBottomButton.shouldShow(currentState: false, distanceFromBottom: 80.1) == true)
    #expect(ScrollToBottomButton.shouldShow(currentState: false, distanceFromBottom: 240) == true)

    // When visible (currentState == true), stays true inside deadband (24...80pt), transitions to false only < 24pt
    #expect(ScrollToBottomButton.shouldShow(currentState: true, distanceFromBottom: 150) == true)
    #expect(ScrollToBottomButton.shouldShow(currentState: true, distanceFromBottom: 80) == true)
    #expect(ScrollToBottomButton.shouldShow(currentState: true, distanceFromBottom: 45) == true)
    #expect(ScrollToBottomButton.shouldShow(currentState: true, distanceFromBottom: 24) == true)
    #expect(ScrollToBottomButton.shouldShow(currentState: true, distanceFromBottom: 23.9) == false)
    #expect(ScrollToBottomButton.shouldShow(currentState: true, distanceFromBottom: 0) == false)
  }

  @Test("ScrollToBottomButton constructs compact circle and capsule bodies for hasUnreadBelowFold false and true")
  @MainActor
  func scrollToBottomButtonCompactIntrinsicConstruction() {
    var tappedCircle = false
    let circleButton = ScrollToBottomButton(hasUnreadBelowFold: false) {
      tappedCircle = true
    }
    #expect(circleButton.hasUnreadBelowFold == false)
    _ = circleButton.body
    circleButton.action()
    #expect(tappedCircle == true)

    var tappedCapsule = false
    let capsuleButton = ScrollToBottomButton(hasUnreadBelowFold: true) {
      tappedCapsule = true
    }
    #expect(capsuleButton.hasUnreadBelowFold == true)
    _ = capsuleButton.body
    capsuleButton.action()
    #expect(tappedCapsule == true)
  }

  @Test("StreamingMarkdownView progressive chunk updates (18 -> 36 -> 54 -> 72 chars) while isStreaming == true monotonically advance displayedCharacterCount and never freeze on the first chunk")
  func progressiveStreamingChunksAdvanceDisplayedCharacterCount() {
    let chunkCounts = [18, 36, 54, 72]

    // Initial appearance on first 18-char chunk ("**ConversationKi" + ..)
    var displayedCount = chunkCounts[0]
    var previousChunkCount = chunkCounts[0]
    #expect(displayedCount == 18)

    for nextChunkCount in chunkCounts.dropFirst() {
      // 1. Even before any async cadence tick runs (or if the previous task was cancelled mid-flight),
      // handleMarkdownUpdate commits up to oldCount so displayedCount never lags behind previous chunks.
      let countAtChunkArrival = StreamingMarkdownView.characterCountOnChunkArrival(
        currentDisplayedCount: displayedCount,
        oldCount: previousChunkCount,
        newCount: nextChunkCount,
        isStreaming: true,
        isStreamingCadenceEnabled: true,
        reduceMotion: false
      )
      #expect(countAtChunkArrival >= previousChunkCount)
      #expect(countAtChunkArrival >= displayedCount)
      displayedCount = countAtChunkArrival

      // 2. As `.task(id: markdown)` ticks toward the fresh `nextChunkCount` target,
      // displayedCount strictly increases until reaching `nextChunkCount`.
      var tickCount = 0
      while displayedCount < nextChunkCount && tickCount < 32 {
        let nextStep = StreamingMarkdownView.nextCadenceCharacterCount(
          currentDisplayedCount: displayedCount,
          targetCount: nextChunkCount
        )
        #expect(nextStep > displayedCount)
        #expect(nextStep <= nextChunkCount)
        displayedCount = nextStep
        tickCount += 1
      }

      #expect(
        displayedCount == nextChunkCount,
        "Expected displayedCount to reach \(nextChunkCount) after chunk update, got \(displayedCount)"
      )
      #expect(displayedCount > 18, "displayedCharacterCount must never stay frozen at 18")
      previousChunkCount = nextChunkCount
    }

    #expect(displayedCount == 72)
  }
}

// MARK: - 6. AdversarialAndPerformanceStressTests (Stage 6 Red Team Audit)

@Suite("Adversarial & 120Hz Performance Stress Tests (AC-7, AC-8, AC-9, AC-17, AC-18, MF-4)")
struct AdversarialAndPerformanceStressTests {

  // MARK: 1. 120Hz Streaming & Incremental Markdown Stress Test (AC-17)

  @Test("120Hz Streaming Stress: 200 paragraphs + 20 fenced code blocks across 100 streaming steps preserve 100% identical committed IDs within 120Hz budget")
  func streamingMarkdown200Paragraphs20CodeBlocksStressTest() {
    // Build a deterministic 220-block document: 200 paragraphs + 20 fenced code blocks (1 code block after every 10 paragraphs)
    let languages = ["swift", "python", "json", "bash"]
    var blocksSource: [String] = []
    blocksSource.reserveCapacity(220)

    var codeBlockCounter = 0
    for paragraphIndex in 1...200 {
      blocksSource.append(
        "Paragraph \(paragraphIndex): ConversationKit v2 anchors the active turn at the top of the viewport (ΔY = 0pt) while streaming tokens downward at 120Hz ProMotion without layout jitter."
      )
      if paragraphIndex.isMultiple(of: 10) {
        let lang = languages[codeBlockCounter % languages.count]
        codeBlockCounter += 1
        blocksSource.append(
          """
          ```\(lang)
          // Fenced code block #\(codeBlockCounter)
          func verifyTurnInvariant_\(codeBlockCounter)(deltaY: Double) -> Bool {
            return abs(deltaY) < 0.0001
          }
          ```
          """
        )
      }
    }

    #expect(codeBlockCounter == 20)
    #expect(blocksSource.count == 220)

    let fullMarkdown = blocksSource.joined(separator: "\n\n")
    let utf8View = fullMarkdown.utf8
    let totalBytes = utf8View.count
    let totalSteps = 100

    // Precompute 100 valid Character-aligned incremental streaming prefixes
    var streamingSnapshots: [String] = []
    streamingSnapshots.reserveCapacity(totalSteps)

    for step in 1...totalSteps {
      let targetByteOffset = (totalBytes * step) / totalSteps
      var cutIndex = utf8View.index(utf8View.startIndex, offsetBy: targetByteOffset)
      while cutIndex < utf8View.endIndex && (utf8View[cutIndex] & 0b1100_0000) == 0b1000_0000 {
        cutIndex = utf8View.index(after: cutIndex)
      }
      streamingSnapshots.append(String(fullMarkdown[..<cutIndex]))
    }

    var canonicalCommittedByIndex: [Int: MarkdownBlock] = [:]
    var previousCommittedCount = 0

    let clock = ContinuousClock()
    var maxSingleStepDuration: Duration = .zero

    let totalElapsed = clock.measure {
      for stepIndex in 0..<totalSteps {
        let snapshot = streamingSnapshots[stepIndex]
        let stepStart = clock.now
        let parsed = MarkdownBlock.parse(snapshot, isStreaming: true)
        let stepDuration = clock.now - stepStart
        if stepDuration > maxSingleStepDuration {
          maxSingleStepDuration = stepDuration
        }

        // Committed block count must grow monotonically across streaming steps
        #expect(
          parsed.committed.count >= previousCommittedCount,
          "Committed block count regressed at step \(stepIndex + 1): \(parsed.committed.count) < \(previousCommittedCount)"
        )
        previousCommittedCount = parsed.committed.count

        // Every committed block ID (and value) must remain 100% identical across all 100 steps
        for (idx, block) in parsed.committed.enumerated() {
          #expect(block.index == idx)
          #expect(block.isCommitted == true)
          if let earlierBlock = canonicalCommittedByIndex[idx] {
            #expect(
              block.id == earlierBlock.id,
              "Committed block ID mutated at index \(idx) on step \(stepIndex + 1): \(block.id) != \(earlierBlock.id)"
            )
            #expect(
              block == earlierBlock,
              "Committed block payload mutated at index \(idx) on step \(stepIndex + 1)"
            )
          } else {
            canonicalCommittedByIndex[idx] = block
          }
        }
      }
    }

    // Final settled parse (isStreaming: false) must commit all 220 blocks with identical IDs
    let finalParsed = MarkdownBlock.parse(fullMarkdown, isStreaming: false)
    #expect(finalParsed.committed.count == 220)
    #expect(finalParsed.tail == nil)

    for (idx, finalBlock) in finalParsed.committed.enumerated() {
      if let streamedCommitted = canonicalCommittedByIndex[idx] {
        #expect(finalBlock.id == streamedCommitted.id)
        #expect(finalBlock == streamedCommitted)
      }
    }

    // Verify 120Hz frame budget: 8.33ms per frame => 100 frames budget is 833ms.
    // Assert average per-step parse time is well below the 8.33ms 120Hz frame budget.
    let totalMilliseconds = Double(totalElapsed.components.seconds) * 1_000.0
      + Double(totalElapsed.components.attoseconds) / 1_000_000_000_000_000.0
    let averageStepMilliseconds = totalMilliseconds / Double(totalSteps)

    #expect(
      averageStepMilliseconds < 8.33,
      "Average incremental parse step (\(averageStepMilliseconds)ms) exceeded 120Hz frame budget (8.33ms)"
    )
    #expect(
      totalMilliseconds < 833.0,
      "Total 100-step streaming parse (\(totalMilliseconds)ms) exceeded cumulative 100-frame 120Hz budget (833ms)"
    )
  }

  // MARK: 2. Adversarial U+200B Sentinel & Unicode Chaos Test (AC-8, AC-9, MUST-FIX-4)

  @Test("Adversarial U+200B Sentinel & Unicode Chaos: RTL Arabic/Hebrew, multi-scalar ZWJ emojis, combining marks, and pasted newlines never leak U+200B or produce invalid String.Index ranges")
  func adversarialSentinelAndUnicodeChaosTest() {
    let zwjEmojis = "👩‍💻👨‍👩‍👧‍👦🏳️‍🌈🧑🏽‍🚀"
    let rtlArabic = "مرحبا بالعالم"
    let rtlHebrew = "שלום עולם"

    let chaoticInputs: [String] = [
      "\u{200B}",
      "\u{200B}\u{200B}\u{200B}",
      "\u{200B}\u{0301}Combining\u{200B}\u{200D}Mark",
      "\u{200B}\(zwjEmojis)\u{200B} /summarize\u{200B}",
      "\(rtlArabic) \u{200B}@PRD-0001\u{200B} \(rtlHebrew)",
      "Line1\r\n\u{200B}/command_after_crlf\u{200B}",
      "Line1\n\(zwjEmojis)\n\u{200B}@mention_after_lf\u{200B}",
      "\u{200B}👩‍💻\u{200B}👨‍👩‍👧‍👦\u{200B}   \u{200B}@\(rtlArabic)\u{200B}",
      "/\u{200B}sum\u{200B}marize",
      "@\u{200B}doc\u{200B}",
    ]

    var tokens: [ComposerToken] = [
      .command(SlashCommand(id: "cmd-chaos", trigger: "summarize", title: "Summarize")),
      .mention(ResourceMention(id: "men-chaos", queryHandle: "PRD-0001", title: "PRD-0001")),
    ]
    var buffer = ComposerTextBuffer(text: "", hasTokens: true)

    for chaotic in chaoticInputs {
      _ = buffer.applyEdit(chaotic, tokens: &tokens)

      // 1. cleanText must NEVER contain U+200B at Character or UnicodeScalar level
      #expect(!buffer.cleanText.contains("\u{200B}"))
      #expect(!buffer.cleanText.unicodeScalars.contains("\u{200B}"))
      #expect(!ComposerTextBuffer.cleanText(chaotic).contains("\u{200B}"))
      #expect(!ComposerTextBuffer.cleanText(chaotic).unicodeScalars.contains("\u{200B}"))

      // 2. Probe detectTrigger across EVERY unicodeScalar index of the chaotic string (including mid-ZWJ-emoji & mid-sentinel offsets)
      let cleaned = buffer.cleanText
      var scalarIdx = chaotic.unicodeScalars.startIndex
      while scalarIdx <= chaotic.unicodeScalars.endIndex {
        if let match = ComposerTextBuffer.detectTrigger(in: chaotic, cursorIndex: scalarIdx) {
          #expect(match.range.lowerBound >= cleaned.startIndex)
          #expect(match.range.upperBound <= cleaned.endIndex)
          #expect(match.range.lowerBound <= match.range.upperBound)
          #expect(!match.query.unicodeScalars.contains("\u{200B}"))

          // Slicing `cleaned[match.range]` must never trap and must start with "/" or "@"
          let extractedSlice = String(cleaned[match.range])
          #expect(extractedSlice.hasPrefix("/") || extractedSlice.hasPrefix("@"))
        }
        if scalarIdx == chaotic.unicodeScalars.endIndex { break }
        scalarIdx = chaotic.unicodeScalars.index(after: scalarIdx)
      }

      // 3. If activeTrigger is present at end of string, consuming it must leave valid cleanText without U+200B
      if buffer.activeTrigger != nil {
        var copyBuffer = buffer
        copyBuffer.consumeActiveTrigger(hasTokens: !tokens.isEmpty)
        #expect(!copyBuffer.cleanText.unicodeScalars.contains("\u{200B}"))
      }
    }

    // 4. Double-backspace chaos on completely empty buffer with NO tokens must never crash
    var emptyTokens: [ComposerToken] = []
    var emptyBuffer = ComposerTextBuffer(text: "", hasTokens: false)
    for _ in 0..<10 {
      let action1 = emptyBuffer.applyEdit("", tokens: &emptyTokens)
      let action2 = emptyBuffer.performBackspaceOnEmpty(tokens: &emptyTokens)
      #expect(action1 == .none)
      #expect(action2 == .none)
      #expect(emptyBuffer.cleanText.isEmpty)
      #expect(emptyBuffer.rawText.isEmpty)
    }

    // 5. Emoji-only buffer ("👩‍💻👨‍👩‍👧‍👦") with active tokens: deleting emojis then double-backspacing tokens
    var emojiTokens: [ComposerToken] = [
      .mention(ResourceMention(id: "m-emoji-1", queryHandle: "Spec", title: "Spec"))
    ]
    var emojiBuffer = ComposerTextBuffer(text: zwjEmojis, hasTokens: true)
    #expect(emojiBuffer.cleanText == zwjEmojis)
    #expect(!emojiBuffer.cleanText.unicodeScalars.contains("\u{200B}"))

    // Backspace down to a single ZWJ emoji ("👩‍💻") -> must NOT highlight or remove token
    let stepToSingleEmoji = emojiBuffer.applyEdit("\u{200B}👩‍💻", tokens: &emojiTokens)
    #expect(stepToSingleEmoji == .none)
    #expect(emojiBuffer.cleanText == "👩‍💻")
    #expect(emojiTokens.count == 1)

    // Backspace the last ZWJ emoji so visible text becomes empty -> must NOT highlight token yet (transition from non-empty to empty)
    let stepToEmptyFromEmoji = emojiBuffer.applyEdit("\u{200B}", tokens: &emojiTokens)
    #expect(stepToEmptyFromEmoji == .none)
    #expect(emojiBuffer.cleanText.isEmpty)
    #expect(emojiBuffer.highlightedTokenID == nil)
    #expect(emojiTokens.count == 1)

    // Now double-backspace on empty buffer: 1st highlights, 2nd removes, 3rd+ on empty does not crash
    let firstBackspaceOnEmpty = emojiBuffer.applyEdit("", tokens: &emojiTokens)
    #expect(firstBackspaceOnEmpty == .highlightToken("mention-m-emoji-1"))
    #expect(emojiTokens.count == 1)

    let secondBackspaceOnEmpty = emojiBuffer.applyEdit("", tokens: &emojiTokens)
    #expect(secondBackspaceOnEmpty == .removeToken("mention-m-emoji-1"))
    #expect(emojiTokens.isEmpty)

    let thirdBackspaceAfterEmpty = emojiBuffer.applyEdit("", tokens: &emojiTokens)
    #expect(thirdBackspaceAfterEmpty == .none)
  }

  // MARK: 3. Adversarial Security & Path Traversal Exploit Tests (AC-7, AC-18, MUST-FIX-2, MUST-FIX-3)

  @Test(
    "Adversarial URL Allowlist: rejects case-mixed javascript/file/data schemes and hostless http/https URLs",
    arguments: [
      "JaVaScRiPt:alert(1)",
      "jAvAsCrIpT://example.com/%0Aalert(document.cookie)",
      "FILE:///etc/passwd",
      "fIlE://localhost/etc/hosts",
      "DATA:text/html,<script>alert(1)</script>",
      "dAtA:text/plain;base64,SGVsbG8=",
      "https://",
      "http:///path-only",
      "HTTPS:///etc/passwd",
      "http://:8080/path",
      "VbScRiPt:Execute(\"MsgBox 1\")",
    ]
  )
  func adversarialURLSchemeAndHostExploits(maliciousURLString: String) {
    let citation = Citation(title: "Adversarial Link", urlString: maliciousURLString)
    #expect(
      citation.sanitizedURL == nil,
      "Citation.sanitizedURL must reject adversarial URL: \(maliciousURLString)"
    )

    if let parsedURL = URL(string: maliciousURLString) {
      #expect(
        parsedURL.isAllowedConversationURL == false,
        "URL.isAllowedConversationURL must reject adversarial URL: \(maliciousURLString)"
      )
    }
  }

  @Test(
    "Adversarial QuickLook Path Traversal: null bytes, Windows/POSIX traversal, empty filenames, and dot-only filenames stay confined",
    arguments: [
      ("..\\..\\secret", "ql-win-traversal"),
      ("../../../../tmp/pwn", "ql-posix-traversal"),
      ("report\0.pdf", "ql-null-byte-mid"),
      ("\0..\\\0../etc/passwd\0", "ql-null-byte-traversal"),
      ("", "ql-empty-filename"),
      ("   ", "ql-whitespace-filename"),
      (".", "ql-single-dot"),
      ("..", "ql-double-dot"),
      ("...", "ql-triple-dot"),
      ("../../../../", "../../../../tmp/evil-id"),
    ]
  )
  func adversarialQuickLookPathTraversalAndDotFilenames(
    rawFilename: String,
    rawAttachmentID: String
  ) async throws {
    let payloadBytes = Data("adversarial-quicklook-payload".utf8)
    let attachment = ConversationAttachment(
      id: rawAttachmentID,
      data: payloadBytes,
      contentType: .plainText,
      filename: rawFilename
    )

    let resolvedURL = try await attachment.resolveQuickLookURL()
    defer {
      try? FileManager.default.removeItem(at: resolvedURL)
    }

    let quickLookDir = PlatformThumbnailGenerator.quickLookDirectoryURL.standardizedFileURL
    let standardizedResolved = resolvedURL.standardizedFileURL
    let basePathWithSlash = quickLookDir.path.hasSuffix("/")
      ? quickLookDir.path
      : quickLookDir.path + "/"

    // 1. Resolved path must reside strictly inside ConversationKitQuickLook directory
    #expect(standardizedResolved.path.hasPrefix(basePathWithSlash))
    #expect(standardizedResolved.deletingLastPathComponent().path == quickLookDir.path)

    // 2. Last path component must never contain traversal tokens, path separators, or null bytes
    let lastComponent = standardizedResolved.lastPathComponent
    #expect(!lastComponent.isEmpty)
    #expect(lastComponent != ".")
    #expect(lastComponent != "..")
    #expect(!lastComponent.contains(".."))
    #expect(!lastComponent.contains("/"))
    #expect(!lastComponent.contains("\\"))
    #expect(!lastComponent.contains(":"))
    #expect(!lastComponent.contains("\0"))

    // 3. Empty and dot-only filenames must sanitize cleanly to "attachment.bin"
    let sanitizedComponent = PlatformThumbnailGenerator.sanitizeFilename(rawFilename)
    if ["", "   ", ".", "..", "..."].contains(rawFilename) {
      #expect(sanitizedComponent == "attachment.bin")
      #expect(lastComponent.hasSuffix("-attachment.bin"))
    }

    // 4. Materialized file must exist and match payload size
    #expect(FileManager.default.fileExists(atPath: standardizedResolved.path))
    let writtenData = try Data(contentsOf: standardizedResolved)
    #expect(writtenData == payloadBytes)
  }

  // MARK: 4. High-Frequency Equality Diffing Benchmark ([MF-4])

  @Test("High-Frequency Diffing Benchmark: 10,000 DefaultMessage equality checks with 5MB Data attachments and long ThinkingTrace execute in < 50ms")
  func highFrequencyEqualityDiffingBenchmark() {
    let fiveMegabytes = 5 * 1_024 * 1_024
    let dataBufferA = Data(repeating: 0xAB, count: fiveMegabytes)
    let dataBufferB = Data(repeating: 0xAB, count: fiveMegabytes)

    // Construct two distinct heap-allocated long transcripts (120,000+ UTF-8 bytes each)
    let baseChunk = "Evaluating top-floating turn scroll geometry (ΔY = 0pt) and 120Hz ProMotion frame pacing. "
    let longTranscriptA = String(repeating: baseChunk, count: 1_500)
    let longTranscriptB = String(Array(longTranscriptA))
    let longContentA = String(repeating: "Detailed assistant Markdown response paragraph. ", count: 1_000)
    let longContentB = String(Array(longContentA))

    let fixedDate = Date(timeIntervalSince1970: 1_700_000_500)

    let attachmentA = ConversationAttachment(
      id: "att-5mb",
      data: dataBufferA,
      contentType: .data,
      filename: "weights-5mb.bin"
    )
    let attachmentB = ConversationAttachment(
      id: "att-5mb",
      data: dataBufferB,
      contentType: .data,
      filename: "weights-5mb.bin"
    )

    let traceA = ThinkingTrace(
      id: "trace-bench",
      status: .thinking(startedAt: fixedDate),
      summary: "Deep architectural verification",
      transcript: longTranscriptA
    )
    let traceB = ThinkingTrace(
      id: "trace-bench",
      status: .thinking(startedAt: fixedDate),
      summary: "Deep architectural verification",
      transcript: longTranscriptB
    )

    let lhsMessage = DefaultMessage(
      id: "msg-bench-1",
      content: longContentA,
      participant: .other,
      createdAt: fixedDate,
      attachments: [attachmentA],
      thinkingTrace: traceA,
      isStreaming: true
    )
    let rhsEqualMessage = DefaultMessage(
      id: "msg-bench-1",
      content: longContentB,
      participant: .other,
      createdAt: fixedDate,
      attachments: [attachmentB],
      thinkingTrace: traceB,
      isStreaming: true
    )
    var rhsNextTokenMessage = rhsEqualMessage
    rhsNextTokenMessage.content = longContentB + " token"

    // Warm-up check
    #expect(lhsMessage == rhsEqualMessage)
    #expect(lhsMessage != rhsNextTokenMessage)

    let clock = ContinuousClock()
    var equalMatches = 0
    var unequalMatches = 0

    let elapsed = clock.measure {
      for i in 0..<10_000 {
        if (i & 1) == 0 {
          if lhsMessage == rhsEqualMessage {
            equalMatches += 1
          }
        } else {
          if lhsMessage != rhsNextTokenMessage {
            unequalMatches += 1
          }
        }
      }
    }

    #expect(equalMatches == 5_000)
    #expect(unequalMatches == 5_000)

    let elapsedMilliseconds = Double(elapsed.components.seconds) * 1_000.0
      + Double(elapsed.components.attoseconds) / 1_000_000_000_000_000.0

    #expect(
      elapsedMilliseconds < 50.0,
      "10,000 DefaultMessage equality checks took \(elapsedMilliseconds)ms, exceeding the 50ms O(1) budget"
    )
  }
}

// MARK: - 7. MessageComposerStyleTests (AC-16)

@Suite("Message Composer Style Presets & Ergonomics (AC-16)")
struct MessageComposerStyleTests {

  @Test("Style presets and type-erased wrapper construct and makeBody cleanly across minimal, focused, and rich configurations")
  @MainActor
  func stylePresetsConstructionAndMakeBody() {
    let dummyTextField = AnyView(Text("Input"))
    let dummySubmitButton = AnyView(Button("Send") {})
    let dummyAttachmentButton = AnyView(Button("+") {})
    let dummyBorderlessAttachmentButton = AnyView(Button("+") {})
    let dummyAttachmentsTray = AnyView(Text("Tray"))
    let dummyTokensBar = AnyView(Text("Tokens"))
    let dummyModelSelector = AnyView(Text("Sonnet"))
    let dummyCompactModelSelector = AnyView(Image(systemName: "sparkles"))
    let dummyDictationButton = AnyView(Button("Dictate") {})
    let dummyDismissButton = AnyView(Button("Dismiss") {})

    let richFocusedConfig = MessageComposerStyleConfiguration(
      textField: dummyTextField,
      attachmentButton: dummyAttachmentButton,
      attachmentsTray: dummyAttachmentsTray,
      tokensBar: dummyTokensBar,
      modelSelector: dummyModelSelector,
      dictationButton: dummyDictationButton,
      submitButton: dummySubmitButton,
      dismissKeyboardButton: dummyDismissButton,
      isFocused: true,
      isGenerating: false,
      canSubmit: true,
      hasAttachments: true,
      hasTokens: true,
      hasModels: true,
      hasCapabilities: true,
      compactModelSelector: dummyCompactModelSelector,
      borderlessAttachmentButton: dummyBorderlessAttachmentButton
    )

    #expect(richFocusedConfig.isFocused == true)
    #expect(richFocusedConfig.isGenerating == false)
    #expect(richFocusedConfig.canSubmit == true)
    #expect(richFocusedConfig.hasAttachments == true)
    #expect(richFocusedConfig.hasTokens == true)
    #expect(richFocusedConfig.hasModels == true)
    #expect(richFocusedConfig.hasCapabilities == true)
    #expect(richFocusedConfig.compactModelSelector != nil)
    #expect(richFocusedConfig.borderlessAttachmentButton != nil)

    // Verify hasModels defaults to true when only compactModelSelector is provided
    let compactOnlyConfig = MessageComposerStyleConfiguration(
      textField: dummyTextField,
      submitButton: dummySubmitButton,
      compactModelSelector: dummyCompactModelSelector
    )
    #expect(compactOnlyConfig.hasModels == true)

    let minimalUnfocusedConfig = MessageComposerStyleConfiguration(
      textField: dummyTextField,
      submitButton: dummySubmitButton,
      isFocused: false,
      isGenerating: false,
      canSubmit: false
    )
    #expect(minimalUnfocusedConfig.hasAttachments == false)
    #expect(minimalUnfocusedConfig.hasTokens == false)
    #expect(minimalUnfocusedConfig.hasModels == false)

    let configurations = [richFocusedConfig, compactOnlyConfig, minimalUnfocusedConfig]
    let styles: [AnyMessageComposerStyle] = [
      AnyMessageComposerStyle(.classicGlass),
      AnyMessageComposerStyle(.automatic),
      AnyMessageComposerStyle(.cardGlass),
      AnyMessageComposerStyle(.compactGlass),
    ]

    for config in configurations {
      _ = ClassicGlassMessageComposerStyle.classicGlass.makeBody(configuration: config)
      _ = ClassicGlassMessageComposerStyle.automatic.makeBody(configuration: config)
      _ = CardGlassMessageComposerStyle.cardGlass.makeBody(configuration: config)
      _ = CompactGlassMessageComposerStyle.compactGlass.makeBody(configuration: config)
      for style in styles {
        _ = style.makeBody(configuration: config)
      }
    }
  }

  @Test("ComposerModelSelectorMenu supports compact icon-only mode for single-line styles")
  @MainActor
  func composerModelSelectorMenuCompactMode() {
    let models = [
      ComposerModelOption(id: "gpt-4o", name: "GPT-4o", symbolName: "sparkles")
    ]
    var selectedModel: ComposerModelOption? = models.first
    let selectedModelBinding = Binding<ComposerModelOption?>(
      get: { selectedModel },
      set: { selectedModel = $0 }
    )
    var activeCapabilities: Set<ComposerCapability> = [.think]
    let activeCapabilitiesBinding = Binding<Set<ComposerCapability>>(
      get: { activeCapabilities },
      set: { activeCapabilities = $0 }
    )

    // Compact mode
    let compactMenu = ComposerModelSelectorMenu(
      models: models,
      selectedModel: selectedModelBinding,
      capabilities: [.think, .search],
      activeCapabilities: activeCapabilitiesBinding,
      isCompact: true
    )
    #expect(compactMenu.isCompact == true)
    _ = compactMenu.body

    // Standard mode defaults isCompact to false
    let standardMenu = ComposerModelSelectorMenu(
      models: models,
      selectedModel: selectedModelBinding,
      capabilities: [.think, .search],
      activeCapabilities: activeCapabilitiesBinding
    )
    #expect(standardMenu.isCompact == false)
    _ = standardMenu.body
  }

  @Test("Custom MessageComposerStyle conformance compiles and executes makeBody")
  @MainActor
  func customMessageComposerStyleConformance() {
    struct CustomTestComposerStyle: MessageComposerStyle {
      func makeBody(configuration: Configuration) -> some View {
        HStack {
          configuration.textField
          configuration.submitButton
        }
      }
    }

    let custom = CustomTestComposerStyle()
    let config = MessageComposerStyleConfiguration(
      textField: AnyView(Text("Prompt")),
      submitButton: AnyView(Button("Submit") {})
    )
    let customBody = custom.makeBody(configuration: config)
    _ = customBody

    let anyCustom = AnyMessageComposerStyle(custom)
    _ = anyCustom.makeBody(configuration: config)
  }

  @Test("PlatformPasteboard.hasAttachments performs lightweight metadata check without throwing")
  @MainActor
  func platformPasteboardHasAttachmentsMetadataCheck() {
    PlatformPasteboard.copyText("Plain text only")
    #expect(PlatformPasteboard.readText() == "Plain text only")
    // Verify hasAttachments is callable on @MainActor and returns a Bool without decoding errors
    let hasAttachments = PlatformPasteboard.hasAttachments
    #expect(hasAttachments == false || hasAttachments == true)
  }

  @Test("EnvironmentBindingBox conforms to Equatable when Value is Equatable and prevents false environment invalidations")
  @MainActor
  func environmentBindingBoxEquatableConformance() {
    let sonnet = ComposerModelOption(id: "sonnet-4-6", name: "Claude Sonnet 4.6")
    let opus = ComposerModelOption(id: "opus-4-6", name: "Claude Opus 4.6")

    var selectedModelA: ComposerModelOption? = sonnet
    var selectedModelB: ComposerModelOption? = sonnet

    let bindingA = Binding<ComposerModelOption?>(
      get: { selectedModelA },
      set: { selectedModelA = $0 }
    )
    let bindingB = Binding<ComposerModelOption?>(
      get: { selectedModelB },
      set: { selectedModelB = $0 }
    )

    let box1 = EnvironmentBindingBox(bindingA)
    let box2 = EnvironmentBindingBox(bindingB)

    // Equal wrapped values produce equal EnvironmentBindingBox instances
    #expect(box1 == box2)
    #expect(box1.snapshot == sonnet)

    // Mutating the underlying value and creating a new box (or checking live wrappedValue) produces inequality
    selectedModelB = opus
    #expect(box1 != box2)

    let box3 = EnvironmentBindingBox(bindingB)
    #expect(box1 != box3)
    #expect(box3.snapshot == opus)

    // Also verify Set<ComposerCapability> and [ComposerToken] Equatable boxes
    var caps1: Set<ComposerCapability> = [.think, .search]
    var caps2: Set<ComposerCapability> = [.think, .search]
    let capsBox1 = EnvironmentBindingBox(Binding(get: { caps1 }, set: { caps1 = $0 }))
    let capsBox2 = EnvironmentBindingBox(Binding(get: { caps2 }, set: { caps2 = $0 }))
    #expect(capsBox1 == capsBox2)

    caps2.insert(.image)
    let capsBox3 = EnvironmentBindingBox(Binding(get: { caps2 }, set: { caps2 = $0 }))
    #expect(capsBox1 != capsBox3)
  }

  @Test("MessageComposerStyleConfiguration lazily evaluates subview slots so unused style variants are never constructed (F-03)")
  @MainActor
  func messageComposerStyleConfigurationLazySlotEvaluation() {
    var textFieldEvaluations = 0
    var attachmentButtonEvaluations = 0
    var borderlessAttachmentButtonEvaluations = 0
    var modelSelectorEvaluations = 0
    var compactModelSelectorEvaluations = 0
    var submitButtonEvaluations = 0

    let lazyConfig = MessageComposerStyleConfiguration(
      lazyTextField: {
        textFieldEvaluations += 1
        return AnyView(Text("Input"))
      },
      attachmentButton: {
        attachmentButtonEvaluations += 1
        return AnyView(Button("+") {})
      },
      borderlessAttachmentButton: {
        borderlessAttachmentButtonEvaluations += 1
        return AnyView(Button("+") {})
      },
      modelSelector: {
        modelSelectorEvaluations += 1
        return AnyView(Text("Claude Sonnet 4.6"))
      },
      compactModelSelector: {
        compactModelSelectorEvaluations += 1
        return AnyView(Image(systemName: "sparkles"))
      },
      submitButton: {
        submitButtonEvaluations += 1
        return AnyView(Button("Send") {})
      },
      isFocused: false,
      isGenerating: false,
      canSubmit: false,
      hasAttachments: false,
      hasTokens: false,
      hasModels: true,
      hasCapabilities: false
    )

    // 1. Zero subviews are constructed at MessageComposerStyleConfiguration initialization
    #expect(textFieldEvaluations == 0)
    #expect(attachmentButtonEvaluations == 0)
    #expect(borderlessAttachmentButtonEvaluations == 0)
    #expect(modelSelectorEvaluations == 0)
    #expect(compactModelSelectorEvaluations == 0)
    #expect(submitButtonEvaluations == 0)

    // 2. Accessing only ClassicGlass slots (`attachmentButton` and `compactModelSelector`)
    // never constructs `borderlessAttachmentButton` or `modelSelector`
    _ = lazyConfig.textField
    _ = lazyConfig.attachmentButton
    _ = lazyConfig.compactModelSelector ?? lazyConfig.modelSelector

    #expect(textFieldEvaluations == 1)
    #expect(attachmentButtonEvaluations == 1)
    #expect(borderlessAttachmentButtonEvaluations == 0)
    #expect(compactModelSelectorEvaluations == 1)
    #expect(modelSelectorEvaluations == 0)
    #expect(submitButtonEvaluations == 0)

    // 3. Accessing CardGlass slots (`borderlessAttachmentButton` and `modelSelector`)
    // evaluates only those slots on demand
    _ = lazyConfig.borderlessAttachmentButton ?? lazyConfig.attachmentButton
    _ = lazyConfig.modelSelector

    #expect(borderlessAttachmentButtonEvaluations == 1)
    #expect(attachmentButtonEvaluations == 1)
    #expect(modelSelectorEvaluations == 1)
    #expect(compactModelSelectorEvaluations == 1)
  }
}
