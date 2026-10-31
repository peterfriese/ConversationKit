//
// ConversationKitTests.swift
// ConversationKit
//
// Created by Peter Friese on 04.07.25.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import Testing
import SwiftUI
@testable import ConversationKit

struct ConversationKitTests {
  
  // MARK: - Message Tests
  
  @Test("DefaultMessage initialization and properties")
  func defaultMessageInitialization() {
    let message = DefaultMessage(content: "Hello", participant: .user)
    #expect(message.content == "Hello")
    #expect(message.participant == .user)
    #expect(message.imageURL == nil)
    #expect(message.error == nil)
    
    let imageMessage = DefaultMessage(content: "Pic", imageURL: "https://example.com/img.png", participant: .other)
    #expect(imageMessage.content == "Pic")
    #expect(imageMessage.imageURL == "https://example.com/img.png")
    #expect(imageMessage.participant == .other)
    #expect(imageMessage.error == nil)
  }
  
  @Test("DefaultMessage equality and hashing detect error transitions and content changes (AC-8 / MF-3)")
  func defaultMessageEquality() {
    struct TestLocalizedError: LocalizedError {
      let message: String
      var errorDescription: String? { message }
    }
    
    var m1 = DefaultMessage(content: "Hi", participant: .user, error: nil)
    let m2 = m1
    #expect(m1 == m2)
    #expect(m1.hashValue == m2.hashValue)
    
    // Transitioning error from nil to non-nil invalidates equality
    m1.error = TestLocalizedError(message: "Network timeout")
    #expect(m1 != m2)
    
    // Two copies with the same error remain equal
    let m3 = m1
    #expect(m1 == m3)
    #expect(m1.hashValue == m3.hashValue)
    
    // Changing error localizedDescription invalidates equality
    m1.error = TestLocalizedError(message: "Rate limit exceeded")
    #expect(m1 != m3)
    
    // Changing content invalidates equality
    var m4 = m2
    m4.content = "Hello"
    #expect(m4 != m2)
  }

  @Test("MinimalCustomMessage conforms to Message using only v1 properties and gets vNext defaults (AC-19)")
  func minimalCustomMessageBackwardsCompatibility() {
    struct MinimalCustomMessage: Message {
      let id: UUID = UUID()
      var content: String?
      var imageURL: String?
      var participant: Participant
      var error: (any Error)? = nil

      init(content: String?, imageURL: String?, participant: Participant) {
        self.content = content
        self.imageURL = imageURL
        self.participant = participant
      }

      static func == (lhs: MinimalCustomMessage, rhs: MinimalCustomMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.imageURL == rhs.imageURL &&
        lhs.participant == rhs.participant
      }

      func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(content)
        hasher.combine(imageURL)
        hasher.combine(participant)
      }
    }

    let customMessage = MinimalCustomMessage(
      content: "Legacy v1 message",
      imageURL: nil,
      participant: .user
    )

    #expect(customMessage.content == "Legacy v1 message")
    #expect(customMessage.thinking == nil)
    #expect(customMessage.toolCalls.isEmpty)
    #expect(customMessage.citations.isEmpty)
    #expect(customMessage.plan == nil)
    #expect(customMessage.approvalRequest == nil)
    #expect(customMessage.isStreaming == false)
    #expect(customMessage.rating == nil)
  }

  // MARK: - Welcome & Greeting Tests (AC-1 / AC-3)

  @Test("WelcomeConfiguration.resolvedGreeting resolves time-of-day greetings, userName, and greetingOverride (AC-1)")
  func welcomeConfigurationGreetingResolution() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))

    func makeDate(hour: Int) throws -> Date {
      let components = DateComponents(
        calendar: calendar,
        timeZone: calendar.timeZone,
        year: 2026,
        month: 10,
        day: 31,
        hour: hour,
        minute: 0
      )
      return try #require(calendar.date(from: components))
    }

    let morningDate = try makeDate(hour: 9)
    let afternoonDate = try makeDate(hour: 14)
    let eveningDate = try makeDate(hour: 20)

    // Without userName
    let anonymousConfig = WelcomeConfiguration()
    #expect(anonymousConfig.resolvedGreeting(for: morningDate, calendar: calendar) == "Good morning")
    #expect(anonymousConfig.resolvedGreeting(for: afternoonDate, calendar: calendar) == "Good afternoon")
    #expect(anonymousConfig.resolvedGreeting(for: eveningDate, calendar: calendar) == "Good evening")

    // With userName
    let namedConfig = WelcomeConfiguration(userName: "Peter")
    #expect(namedConfig.resolvedGreeting(for: morningDate, calendar: calendar) == "Good morning, Peter")
    #expect(namedConfig.resolvedGreeting(for: afternoonDate, calendar: calendar) == "Good afternoon, Peter")
    #expect(namedConfig.resolvedGreeting(for: eveningDate, calendar: calendar) == "Good evening, Peter")

    // With greetingOverride
    let overrideConfig = WelcomeConfiguration(
      greetingOverride: "Welcome back, Builder",
      userName: "Peter"
    )
    #expect(overrideConfig.resolvedGreeting(for: morningDate, calendar: calendar) == "Welcome back, Builder")
    #expect(overrideConfig.resolvedGreeting(for: eveningDate, calendar: calendar) == "Welcome back, Builder")
  }

  @Test("ConversationWelcomeView.shuffledSlice returns 4 unseen items from an 8-item pool without mutating the pool (AC-3)")
  func welcomeViewShuffledSlice() {
    let pool = (1...8).map { index in
      PromptSuggestion(
        id: "prompt-\(index)",
        title: "Prompt \(index)",
        subtitle: "Subtitle \(index)",
        category: "Category"
      )
    }
    let initialSlice = Array(pool.prefix(4))
    let currentIDs = Set(initialSlice.map(\.id))

    let nextSlice = ConversationWelcomeView.shuffledSlice(
      from: pool,
      count: 4,
      currentIDs: currentIDs
    )

    #expect(nextSlice.count == 4)
    #expect(Set(nextSlice.map(\.id)) != currentIDs)
    #expect(Set(nextSlice.map(\.id)) == Set(["prompt-5", "prompt-6", "prompt-7", "prompt-8"]))
    #expect(pool.count == 8)
  }

  // MARK: - ThinkingTrace & ThinkingStateView Tests (AC-5 / MF-2 / MF-3)

  @Test("ThinkingTrace statuses and O(1) fast-path Equatable/Hashable on transcript mutations (AC-5 / MF-2 / MF-3)")
  func thinkingTraceLifecycleAndFastPathEquality() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    var trace = ThinkingTrace(
      id: "trace-1",
      summary: "Analyzing architecture",
      transcript: "Step 1: Inspect models.",
      status: .thinking(startedAt: start)
    )

    #expect(trace.startedAt == start)
    #expect(trace.durationSeconds == nil)
    #expect(trace.status == .thinking(startedAt: start))

    let snapshot = trace
    #expect(trace == snapshot)
    #expect(trace.hashValue == snapshot.hashValue)

    // Streaming token append mutates UTF-8 byte count & last byte -> O(1) equality detects change
    trace.transcript.append(" Step 2: Verify Swift 6 Sendable.")
    #expect(trace != snapshot)

    // Same length but different last character -> O(1) equality detects change
    var sameLengthModified = trace
    sameLengthModified.transcript = String(trace.transcript.dropLast()) + "!"
    #expect(sameLengthModified != trace)

    // Transition to .completed
    let completedTrace = ThinkingTrace(
      id: "trace-1",
      summary: "Analyzed architecture",
      transcript: trace.transcript,
      startedAt: start,
      status: .completed(duration: 3.5)
    )
    #expect(completedTrace.durationSeconds == 3.5)
    #expect(completedTrace.status == .completed(duration: 3.5))
    #expect(completedTrace != trace)

    // Transition to .cancelled
    let cancelledTrace = ThinkingTrace(
      id: "trace-1",
      summary: "Interrupted",
      transcript: trace.transcript,
      startedAt: start,
      status: .cancelled(duration: 1.2)
    )
    #expect(cancelledTrace.durationSeconds == 1.2)
    #expect(cancelledTrace.status == .cancelled(duration: 1.2))
    #expect(cancelledTrace != completedTrace)
  }

  @Test("ThinkingStateView.headerTitle formats active thinking, completed duration, and cancelled states (AC-5)")
  func thinkingStateViewHeaderTitleFormatting() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let now = start.addingTimeInterval(3.2)

    let expectedElapsed = (3.2).formatted(.number.precision(.fractionLength(1)))
    #expect(
      ThinkingStateView.headerTitle(for: .thinking(startedAt: start), now: now)
        == "Thinking · \(expectedElapsed)s"
    )
    #expect(
      ThinkingStateView.headerTitle(for: .completed(duration: 4.1), now: now)
        == "Thought for 4s"
    )
    #expect(
      ThinkingStateView.headerTitle(for: .cancelled(duration: 1.8), now: now)
        == "Thinking stopped"
    )
  }

  // MARK: - ToolCall & ToolCallsGroupView Tests (AC-9 / AC-10 / MF-3)

  @Test("ToolCall statuses and O(1) fast-path Equatable/Hashable on inputJSON and outputJSON (AC-9 / AC-10 / MF-3)")
  func toolCallLifecycleAndFastPathEquality() {
    let allStatuses: [ToolCall.Status] = [.pending, .running, .succeeded, .failed, .cancelled]
    #expect(allStatuses.count == 5)

    var call = ToolCall(
      id: "tool-1",
      name: "search_docs",
      icon: "magnifyingglass",
      argumentsSummary: "query: SwiftUI",
      inputJSON: #"{"query":"SwiftUI"}"#,
      status: .pending
    )
    #expect(call.status == .pending)
    #expect(call.symbolName == "magnifyingglass")
    #expect(call.argumentsJSON == #"{"query":"SwiftUI"}"#)

    let pendingCopy = call
    #expect(call == pendingCopy)
    #expect(call.hashValue == pendingCopy.hashValue)

    // Transition to .running and stream inputJSON
    call.status = .running
    #expect(call != pendingCopy)

    let runningSnapshot = call
    call.inputJSON = #"{"query":"SwiftUI ScrollView"}"#
    #expect(call != runningSnapshot)

    // Transition to .succeeded with outputJSON
    call.status = .succeeded
    call.outputJSON = #"{"results":3}"#
    call.durationSeconds = 0.42
    #expect(call.resultJSON == #"{"results":3}"#)

    let succeededSnapshot = call
    #expect(call == succeededSnapshot)
    #expect(call.hashValue == succeededSnapshot.hashValue)

    // Mutate outputJSON -> O(1) equality detects change
    call.outputJSON = #"{"results":12}"#
    #expect(call != succeededSnapshot)

    // Verify .failed and .cancelled statuses
    call.status = .failed
    call.errorMessage = "Connection reset"
    #expect(call.status == .failed)

    call.status = .cancelled
    #expect(call.status == .cancelled)
  }

  @Test("ToolCallsGroupView auto-expansion rules and summaryTitle formatting (AC-9)")
  func toolCallsGroupViewAutoExpandAndSummaryTitle() {
    let runningCalls = [
      ToolCall(id: "1", name: "fetch", durationSeconds: 0.8, status: .succeeded),
      ToolCall(id: "2", name: "parse", status: .running)
    ]
    #expect(ToolCallsGroupView.shouldAutoExpand(for: runningCalls, userOverrodeExpansion: false) == true)
    #expect(ToolCallsGroupView.summaryTitle(for: runningCalls) == "Running tools…")

    let failedCalls = [
      ToolCall(id: "1", name: "fetch", durationSeconds: 0.8, status: .succeeded),
      ToolCall(id: "2", name: "parse", durationSeconds: 0.4, status: .failed)
    ]
    #expect(ToolCallsGroupView.shouldAutoExpand(for: failedCalls, userOverrodeExpansion: false) == true)
    #expect(ToolCallsGroupView.summaryTitle(for: failedCalls) == "Tool execution failed")

    let succeededCalls = [
      ToolCall(id: "1", name: "tool_a", durationSeconds: 0.8, status: .succeeded),
      ToolCall(id: "2", name: "tool_b", durationSeconds: 0.9, status: .succeeded),
      ToolCall(id: "3", name: "tool_c", durationSeconds: 0.7, status: .succeeded),
      ToolCall(id: "4", name: "tool_d", durationSeconds: 0.8, status: .succeeded)
    ]
    // Auto-folds when all succeeded and user has not overridden expansion
    #expect(ToolCallsGroupView.shouldAutoExpand(for: succeededCalls, userOverrodeExpansion: false) == false)
    // Respects manual user override
    #expect(ToolCallsGroupView.shouldAutoExpand(for: succeededCalls, userOverrodeExpansion: true) == true)

    let expectedDuration = (3.2).formatted(.number.precision(.fractionLength(1)))
    #expect(ToolCallsGroupView.summaryTitle(for: succeededCalls) == "Used 4 tools · \(expectedDuration)s")
  }

  // MARK: - AgentPlan & AgentPlanView Tests (AC-11)

  @Test("AgentPlan and Step statuses with completedCount calculation and AgentPlanView helpers (AC-11)")
  func agentPlanCompletedCountAndViewHelpers() {
    let steps: [AgentPlan.Step] = [
      AgentPlan.Step(id: "1", title: "Parse request", status: .completed),
      AgentPlan.Step(id: "2", title: "Query index", status: .completed),
      AgentPlan.Step(id: "3", title: "Synthesize patch", status: .completed),
      AgentPlan.Step(id: "4", title: "Run regression suite", status: .failed),
      AgentPlan.Step(id: "5", title: "Publish artifact", status: .cancelled)
    ]

    let plan = AgentPlan(id: "plan-1", title: "Implementation Plan", steps: steps)
    #expect(plan.steps.count == 5)
    #expect(plan.completedCount == 3)
    #expect(plan.steps[3].status == .failed)
    #expect(plan.steps[4].status == .cancelled)

    #expect(AgentPlanView.progressSummary(for: plan) == "3 of 5 completed")
    #expect(AgentPlanView.iconName(for: .pending) == "circle")
    #expect(AgentPlanView.iconName(for: .inProgress) == "arrow.triangle.2.circlepath.circle.fill")
    #expect(AgentPlanView.iconName(for: .completed) == "checkmark.circle.fill")
    #expect(AgentPlanView.iconName(for: .failed) == "exclamationmark.triangle.fill")
    #expect(AgentPlanView.iconName(for: .skipped) == "minus.circle")
    #expect(AgentPlanView.iconName(for: .cancelled) == "slash.circle")
  }

  // MARK: - ApprovalRequest & AgentApprovalView Tests (AC-12)

  @Test("ApprovalRequest decisions, scopeIdentifier, and AgentApprovalView.resolutionLabel (AC-12)")
  func approvalRequestDecisionsAndResolutionLabels() {
    var request = ApprovalRequest(
      id: "approval-1",
      title: "Execute shell command",
      detail: "rm -rf build/",
      scopeIdentifier: "shell.exec.workspace"
    )

    #expect(request.decision == .pending)
    #expect(request.scopeIdentifier == "shell.exec.workspace")

    let allDecisions: [ApprovalRequest.Decision] = [
      .pending,
      .allowOnce,
      .alwaysAllow,
      .deny,
      .cancelled
    ]

    for decision in allDecisions {
      request.decision = decision
      #expect(request.decision == decision)
    }

    #expect(AgentApprovalView.resolutionLabel(for: .pending) == "Approval required")
    #expect(AgentApprovalView.resolutionLabel(for: .allowOnce) == "Allowed once")
    #expect(AgentApprovalView.resolutionLabel(for: .alwaysAllow) == "Always allowed")
    #expect(AgentApprovalView.resolutionLabel(for: .deny) == "Denied")
    #expect(AgentApprovalView.resolutionLabel(for: .cancelled) == "Approval cancelled")
  }

  // MARK: - Citation & SourceStackView Tests (AC-13 / SF-2)

  @Test("Citation.safeWebURL allowlists https and http while rejecting unsafe schemes, and SourceStackView.badgeTitle formats counts (AC-13 / SF-2)")
  func citationSafeWebURLAndSourceStackBadgeTitle() {
    let httpsCitation = Citation(
      title: "Swift Documentation",
      url: URL(string: "https://swift.org/documentation")
    )
    #expect(httpsCitation.safeWebURL?.absoluteString == "https://swift.org/documentation")
    #expect(httpsCitation.domain == "swift.org")

    let httpCitation = Citation(
      title: "Local Dev Docs",
      url: URL(string: "http://example.com/docs")
    )
    #expect(httpCitation.safeWebURL?.absoluteString == "http://example.com/docs")

    let javascriptCitation = Citation(
      title: "XSS Payload",
      url: URL(string: "javascript:alert(1)")
    )
    #expect(javascriptCitation.safeWebURL == nil)

    let fileCitation = Citation(
      title: "Local File",
      url: URL(string: "file:///etc/passwd")
    )
    #expect(fileCitation.safeWebURL == nil)

    let shortcutsCitation = Citation(
      title: "Shortcuts URL",
      url: URL(string: "shortcuts://run-shortcut?name=Pwn")
    )
    #expect(shortcutsCitation.safeWebURL == nil)

    #expect(SourceStackView.badgeTitle(for: [httpsCitation]) == "1 source")
    #expect(
      SourceStackView.badgeTitle(for: [httpsCitation, httpCitation, javascriptCitation])
        == "3 sources"
    )
  }

  // MARK: - Composer Slash Commands, Mentions & Submission Tests (AC-14 / AC-15 / AC-16 / AC-17 / AC-18)

  @Test("MessageComposerView matchingSuggestions and applySuggestion handle /slash and @mention triggers (AC-16)")
  func composerSlashAndMentionSuggestions() throws {
    let slashCommands = [
      ComposerTokenChip(
        id: "cmd-summarize",
        kind: .slashCommand,
        trigger: "/summarize",
        title: "Summarize",
        value: "/summarize",
        icon: "text.redaction"
      ),
      ComposerTokenChip(
        id: "cmd-search",
        kind: .slashCommand,
        trigger: "/search",
        title: "Search Web",
        value: "/search",
        icon: "globe"
      )
    ]

    let mentions = [
      ComposerTokenChip(
        id: "mention-readme",
        kind: .mention,
        trigger: "@README.md",
        title: "README.md",
        value: "README.md",
        icon: "doc.text"
      ),
      ComposerTokenChip(
        id: "mention-package",
        kind: .mention,
        trigger: "@Package.swift",
        title: "Package.swift",
        value: "Package.swift",
        icon: "swift"
      )
    ]

    var text = "Please /SUM"
    var activeTokens: [ComposerTokenChip] = []

    let slashMatch = try #require(
      MessageComposerView<EmptyAttachment>.matchingSuggestions(
        for: text,
        slashCommands: slashCommands,
        mentions: mentions
      )
    )
    #expect(slashMatch.triggerQuery == "/SUM")
    #expect(slashMatch.suggestions.count == 1)
    #expect(slashMatch.suggestions.first?.id == "cmd-summarize")

    MessageComposerView<EmptyAttachment>.applySuggestion(
      slashMatch.suggestions[0],
      to: &text,
      triggerQuery: slashMatch.triggerQuery,
      tokens: &activeTokens
    )
    #expect(text == "Please")
    #expect(activeTokens.map(\.id) == ["cmd-summarize"])

    text = "Please inspect @readme"
    let mentionMatch = try #require(
      MessageComposerView<EmptyAttachment>.matchingSuggestions(
        for: text,
        slashCommands: slashCommands,
        mentions: mentions
      )
    )
    #expect(mentionMatch.triggerQuery == "@readme")
    #expect(mentionMatch.suggestions.count == 1)
    #expect(mentionMatch.suggestions.first?.id == "mention-readme")

    MessageComposerView<EmptyAttachment>.applySuggestion(
      mentionMatch.suggestions[0],
      to: &text,
      triggerQuery: mentionMatch.triggerQuery,
      tokens: &activeTokens
    )
    #expect(text == "Please inspect")
    #expect(activeTokens.map(\.id) == ["cmd-summarize", "mention-readme"])
  }

  @Test("MessageSubmission bundles message, model option, capabilities, tokens, and ImageAttachment uploadProgress (AC-14 / AC-15 / AC-17 / AC-18)")
  func messageSubmissionEnrichedPayload() {
    #if canImport(UIKit)
    let nativeImage = UIImage()
    #elseif canImport(AppKit)
    let nativeImage = NSImage()
    #endif

    let modelOption = ComposerModelOption(
      id: "claude-sonnet-4",
      name: "Claude Sonnet 4",
      subtitle: "Fast & capable",
      icon: "sparkles"
    )
    #expect(modelOption.symbolName == "sparkles")

    let capabilities: Set<ComposerCapability> = [
      .think,
      .search,
      .custom(id: "canvas", title: "Canvas", icon: "rectangle.and.pencil.and.ellipsis")
    ]
    #expect(capabilities.count == 3)

    let token = ComposerTokenChip(
      id: "token-1",
      kind: .mention,
      trigger: "@AGENTS.md",
      title: "AGENTS.md",
      value: "AGENTS.md",
      icon: "doc.text"
    )

    var attachment = ImageAttachment(
      image: nativeImage,
      uploadProgress: 0.45
    )
    #expect(attachment.uploadProgress == 0.45)
    #expect(attachment.uploadError == nil)

    // Complete upload before submission
    attachment.uploadProgress = 1.0

    let userMessage = DefaultMessage(content: "Review architecture", participant: .user)
    let submission = MessageSubmission(
      message: userMessage,
      attachments: [attachment],
      activeCapabilities: capabilities,
      tokens: [token],
      selectedModelID: modelOption.id
    )

    #expect(submission.message == userMessage)
    #expect(submission.attachments.count == 1)
    #expect(submission.attachments.first?.uploadProgress == 1.0)
    #expect(submission.activeCapabilities == capabilities)
    #expect(submission.tokens == [token])
    #expect(submission.selectedModelID == "claude-sonnet-4")
  }
  
  // MARK: - Attachment Tests
  
  @Test("ImageAttachment properties and equatable conformance")
  func imageAttachment() {
    #if canImport(UIKit)
    let nativeImage = UIImage()
    #elseif canImport(AppKit)
    let nativeImage = NSImage()
    #endif
    
    let a1 = ImageAttachment(image: nativeImage)
    let a2 = ImageAttachment(image: nativeImage)
    
    #expect(a1.id != a2.id)
    #expect(a1 != a2)
    
    let a3 = a1
    #expect(a1 == a3)
  }
  
  @Test("EmptyAttachment unique identification")
  func emptyAttachment() {
    let e1 = EmptyAttachment()
    let e2 = EmptyAttachment()
    #expect(e1.id != e2.id)
    #expect(e1 != e2)
  }
  
  // MARK: - Error Handling Tests
  
  @Test("ErrorWrapper encapsulates errors correctly")
  func errorWrapper() {
    struct TestError: Error, Equatable {
      let code: Int
    }
    
    let underlyingError = TestError(code: 42)
    let wrapper = ErrorWrapper(error: underlyingError)
    
    #expect(wrapper.error as? TestError == underlyingError)
    #expect(wrapper.id != UUID())
  }
  
  @Test("PresentErrorAction triggers handler closure")
  func presentErrorAction() {
    struct MyError: Error {}
    var triggeredError: Error?
    
    let action = PresentErrorAction { error in
      triggeredError = error
    }
    
    action(MyError())
    #expect(triggeredError is MyError)
  }
  
  // MARK: - Platform Helpers Tests
  
  @Test("PlatformImage resolves system symbols")
  func platformImageSymbolResolution() {
    let symbol = PlatformImage.systemSymbol("star.fill")
    #expect(symbol != nil)
  }

  // MARK: - Adversarial & Boundary Chaos Tests (PRD-0001 AC-1 through AC-19)

  @Test("Adversarial: ThinkingTrace Equatable must not falsely equate distinct strings with identical UTF-8 length and boundary bytes (MF-4)")
  func thinkingTraceEquatableMiddleCollisionAndMultibyteUnicode() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)

    // Same id, status, UTF-8 byte count (12), first byte ('H'), and last byte ('!'), differing in middle
    let traceA = ThinkingTrace(
      id: "trace-collision",
      summary: "Plan A.",
      transcript: "Hello World!",
      startedAt: start,
      status: .thinking(startedAt: start)
    )
    let traceB = ThinkingTrace(
      id: "trace-collision",
      summary: "Plan A.",
      transcript: "Hello_World!",
      startedAt: start,
      status: .thinking(startedAt: start)
    )
    #expect(traceA.transcript.utf8.count == traceB.transcript.utf8.count)
    #expect(traceA.transcript.utf8.first == traceB.transcript.utf8.first)
    #expect(traceA.transcript.utf8.last == traceB.transcript.utf8.last)
    #expect(traceA != traceB)

    // Multi-byte 4-byte emoji replacement in the middle (both 🚀 and 💥 are 4 UTF-8 bytes starting with 0xF0)
    let unicodeA = ThinkingTrace(
      id: "trace-unicode",
      summary: "Status: 🚀!",
      transcript: "Step 1: 🚀 complete",
      startedAt: start,
      status: .completed(duration: 2.0)
    )
    let unicodeB = ThinkingTrace(
      id: "trace-unicode",
      summary: "Status: 💥!",
      transcript: "Step 1: 💥 complete",
      startedAt: start,
      status: .completed(duration: 2.0)
    )
    #expect(unicodeA.transcript.utf8.count == unicodeB.transcript.utf8.count)
    #expect(unicodeA != unicodeB)

    // Summary middle mutation with identical transcript
    let summaryA = ThinkingTrace(
      id: "trace-summary",
      summary: "Analyze [A]",
      transcript: "Same transcript",
      startedAt: start,
      status: .completed(duration: 1.0)
    )
    let summaryB = ThinkingTrace(
      id: "trace-summary",
      summary: "Analyze [B]",
      transcript: "Same transcript",
      startedAt: start,
      status: .completed(duration: 1.0)
    )
    #expect(summaryA != summaryB)
  }

  @Test("Adversarial: ToolCall Equatable must not falsely equate distinct JSON or summaries with identical UTF-8 length and boundary braces (MF-4)")
  func toolCallEquatableMiddleCollisionAndSummaryDiffing() {
    // JSON objects always start with '{' and end with '}', so same-length JSON payloads collide on first/last UTF-8 byte
    let passCall = ToolCall(
      id: "tool-collision",
      name: "verify_suite",
      argumentsSummary: "target: debug",
      resultSummary: "4 passed",
      durationSeconds: 1.0,
      inputJSON: #"{"mode":"fast"}"#,
      outputJSON: #"{"status":"pass"}"#,
      errorMessage: nil,
      status: .succeeded
    )
    var failOutputCall = passCall
    failOutputCall.outputJSON = #"{"status":"fail"}"#

    #expect(passCall.outputJSON?.utf8.count == failOutputCall.outputJSON?.utf8.count)
    #expect(passCall.outputJSON?.utf8.first == failOutputCall.outputJSON?.utf8.first)
    #expect(passCall.outputJSON?.utf8.last == failOutputCall.outputJSON?.utf8.last)
    #expect(passCall != failOutputCall)

    // Same-length inputJSON mutation
    var mutatedInputCall = passCall
    mutatedInputCall.inputJSON = #"{"mode":"slow"}"#
    #expect(passCall != mutatedInputCall)

    // Same-length argumentsSummary mutation
    var mutatedArgsSummaryCall = passCall
    mutatedArgsSummaryCall.argumentsSummary = "source: local"
    #expect(passCall.argumentsSummary?.utf8.count == mutatedArgsSummaryCall.argumentsSummary?.utf8.count)
    #expect(passCall != mutatedArgsSummaryCall)

    // Same-length resultSummary mutation
    var mutatedResultSummaryCall = passCall
    mutatedResultSummaryCall.resultSummary = "4 failed"
    #expect(passCall.resultSummary?.utf8.count == mutatedResultSummaryCall.resultSummary?.utf8.count)
    #expect(passCall != mutatedResultSummaryCall)

    // Same-length errorMessage mutation
    var errorCallA = passCall
    errorCallA.status = .failed
    errorCallA.errorMessage = "HTTP 500"
    var errorCallB = errorCallA
    errorCallB.errorMessage = "HTTP 404"
    #expect(errorCallA.errorMessage?.utf8.count == errorCallB.errorMessage?.utf8.count)
    #expect(errorCallA != errorCallB)
  }

  @Test("Boundary: WelcomeConfiguration and ConversationWelcomeView.shuffledSlice handle empty pool, zero/negative visibleCount, and small pools (AC-1 / AC-3)")
  func welcomeConfigurationAndShuffledSliceBoundaries() throws {
    let emptyPool: [PromptSuggestion] = []
    #expect(
      ConversationWelcomeView.shuffledSlice(from: emptyPool, count: 4, currentIDs: []).isEmpty
    )
    #expect(
      ConversationWelcomeView.shuffledSlice(from: emptyPool, count: 0, currentIDs: []).isEmpty
    )
    #expect(
      ConversationWelcomeView.shuffledSlice(from: emptyPool, count: -3, currentIDs: []).isEmpty
    )

    let smallPool = (1...3).map { index in
      PromptSuggestion(id: "p-\(index)", title: "Prompt \(index)")
    }

    // Zero and negative visibleCount must return an empty slice without trapping
    #expect(
      ConversationWelcomeView.shuffledSlice(from: smallPool, count: 0, currentIDs: ["p-1"]).isEmpty
    )
    #expect(
      ConversationWelcomeView.shuffledSlice(from: smallPool, count: -10, currentIDs: ["p-1"]).isEmpty
    )

    // pool.count <= visibleCount returns all items in the pool without out-of-bounds or duplicates
    let equalCountSlice = ConversationWelcomeView.shuffledSlice(
      from: smallPool,
      count: 3,
      currentIDs: Set(smallPool.map(\.id))
    )
    #expect(equalCountSlice.count == 3)
    #expect(Set(equalCountSlice.map(\.id)) == Set(smallPool.map(\.id)))

    let largerCountSlice = ConversationWelcomeView.shuffledSlice(
      from: smallPool,
      count: 10,
      currentIDs: Set(smallPool.map(\.id))
    )
    #expect(largerCountSlice.count == 3)
    #expect(Set(largerCountSlice.map(\.id)) == Set(smallPool.map(\.id)))

    // Whitespace-only userName and greetingOverride fall back cleanly
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let components = DateComponents(
      calendar: calendar,
      timeZone: calendar.timeZone,
      year: 2026,
      month: 10,
      day: 31,
      hour: 5,
      minute: 0
    )
    let boundaryMorning = try #require(calendar.date(from: components))
    let whitespaceConfig = WelcomeConfiguration(
      greetingOverride: "   \n\t  ",
      userName: "   "
    )
    #expect(whitespaceConfig.resolvedGreeting(for: boundaryMorning, calendar: calendar) == "Good morning")
  }

  @Test("Adversarial: Citation.safeWebURL handles mixed-case schemes and rejects schemes without a valid host or unsafe protocols (AC-13 / SF-2)")
  func citationSafeWebURLSchemeInjectionAndHostValidation() {
    // Mixed-case valid web schemes
    let upperHTTPS = Citation(title: "Upper HTTPS", url: URL(string: "HTTPS://example.com/path"))
    #expect(upperHTTPS.safeWebURL != nil)

    let mixedHTTP = Citation(title: "Mixed HTTP", url: URL(string: "Http://example.com/path"))
    #expect(mixedHTTP.safeWebURL != nil)

    // Mixed-case dangerous schemes
    let mixedJS = Citation(title: "Mixed JS", url: URL(string: "JavaScript:alert(1)"))
    #expect(mixedJS.safeWebURL == nil)

    let dataURL = Citation(
      title: "Data URL",
      url: URL(string: "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==")
    )
    #expect(dataURL.safeWebURL == nil)

    let upperFile = Citation(title: "File URL", url: URL(string: "FILE:///etc/passwd"))
    #expect(upperFile.safeWebURL == nil)

    // Relative URLs without scheme or host
    let relativePath = Citation(title: "Relative Path", url: URL(string: "/etc/passwd"))
    #expect(relativePath.safeWebURL == nil)

    let schemeRelative = Citation(title: "Scheme Relative", url: URL(string: "//evil.example.com/payload"))
    #expect(schemeRelative.safeWebURL == nil)

    // Malformed http/https URLs lacking a non-empty host must be rejected
    let hostlessHTTPFile = Citation(title: "Hostless HTTP Path", url: URL(string: "http:///etc/passwd"))
    #expect(hostlessHTTPFile.safeWebURL == nil)

    let opaqueHTTPS = Citation(title: "Opaque HTTPS", url: URL(string: "https:javascript:alert(1)"))
    #expect(opaqueHTTPS.safeWebURL == nil)
  }

  @Test("Adversarial: MessageComposerView.matchingSuggestions does not falsely trigger on emails, URLs, // comments, or file paths (AC-16)")
  func composerMatchingSuggestionsTriggerBoundaries() {
    let slashCommands = [
      ComposerTokenChip(
        id: "cmd-summarize",
        kind: .slashCommand,
        trigger: "/summarize",
        title: "Summarize",
        value: "/summarize",
        icon: "text.redaction"
      ),
      ComposerTokenChip(
        id: "cmd-search",
        kind: .slashCommand,
        trigger: "/search",
        title: "Search Web",
        value: "/search",
        icon: "globe"
      )
    ]

    let mentions = [
      ComposerTokenChip(
        id: "mention-readme",
        kind: .mention,
        trigger: "@README.md",
        title: "README.md",
        value: "@README.md",
        icon: "doc.text"
      )
    ]

    // Email addresses must NOT trigger @mention popup
    #expect(
      MessageComposerView<EmptyAttachment>.matchingSuggestions(
        for: "Contact user@example.com",
        slashCommands: slashCommands,
        mentions: mentions
      ) == nil
    )
    #expect(
      MessageComposerView<EmptyAttachment>.matchingSuggestions(
        for: "Send to email@readme",
        slashCommands: slashCommands,
        mentions: mentions
      ) == nil
    )

    // Web URLs must NOT trigger /slash command popup
    #expect(
      MessageComposerView<EmptyAttachment>.matchingSuggestions(
        for: "Check https://apple.com/swift",
        slashCommands: slashCommands,
        mentions: mentions
      ) == nil
    )
    #expect(
      MessageComposerView<EmptyAttachment>.matchingSuggestions(
        for: "Open https://example.com/sum",
        slashCommands: slashCommands,
        mentions: mentions
      ) == nil
    )

    // Code comment prefix "//" or repeated "@@" must NOT falsely match slash/mention values containing "/" or "@"
    #expect(
      MessageComposerView<EmptyAttachment>.matchingSuggestions(
        for: "//",
        slashCommands: slashCommands,
        mentions: mentions
      ) == nil
    )
    #expect(
      MessageComposerView<EmptyAttachment>.matchingSuggestions(
        for: "@@",
        slashCommands: slashCommands,
        mentions: mentions
      ) == nil
    )

    // Multi-segment file paths like "/usr/local/sum" must NOT falsely trigger slash commands
    #expect(
      MessageComposerView<EmptyAttachment>.matchingSuggestions(
        for: "/usr/local/sum",
        slashCommands: slashCommands,
        mentions: mentions
      ) == nil
    )
  }
}
