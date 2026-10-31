//
// AgenticModels.swift
// ConversationKit
//
// Created by Peter Friese on 31.10.26.
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

// MARK: - Message Rating

/// User feedback rating associated with an assistant message turn.
public enum MessageRating: String, Hashable, Sendable {
  case up
  case down
}

// MARK: - Thinking Trace

/// Represents an intermediate reasoning or chain-of-thought trace emitted during an assistant turn.
///
/// Implements $O(1)$ fast-path `Equatable` and `Hashable` conformances (`[MF-3]`) so high-frequency
/// streaming token updates do not re-hash multi-kilobyte reasoning strings on every display frame.
public struct ThinkingTrace: Identifiable, Hashable, Sendable {
  /// Lifecycle status of a reasoning trace.
  public enum Status: Hashable, Sendable {
    case thinking(startedAt: Date)
    case completed(duration: TimeInterval)
    case cancelled(duration: TimeInterval? = nil)
  }

  public let id: String
  public var summary: String?
  public var transcript: String
  public var startedAt: Date?
  public var durationSeconds: TimeInterval?
  public var status: Status

  public init(
    id: String = UUID().uuidString,
    summary: String? = nil,
    transcript: String = "",
    startedAt: Date? = nil,
    durationSeconds: TimeInterval? = nil,
    status: Status = .thinking(startedAt: Date())
  ) {
    self.id = id
    self.summary = summary
    self.transcript = transcript
    switch status {
    case .thinking(let start):
      self.startedAt = startedAt ?? start
      self.durationSeconds = durationSeconds
    case .completed(let duration):
      self.startedAt = startedAt
      self.durationSeconds = durationSeconds ?? duration
    case .cancelled(let duration):
      self.startedAt = startedAt
      self.durationSeconds = durationSeconds ?? duration
    }
    self.status = status
  }

  public static func == (lhs: ThinkingTrace, rhs: ThinkingTrace) -> Bool {
    lhs.id == rhs.id &&
    lhs.status == rhs.status &&
    lhs.startedAt == rhs.startedAt &&
    lhs.durationSeconds == rhs.durationSeconds &&
    lhs.summary?.utf8.count == rhs.summary?.utf8.count &&
    lhs.transcript.utf8.count == rhs.transcript.utf8.count &&
    lhs.summary == rhs.summary &&
    lhs.transcript == rhs.transcript
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(status)
    hasher.combine(startedAt)
    hasher.combine(durationSeconds)
    hasher.combine(summary?.utf8.count)
    hasher.combine(transcript.utf8.count)
    hasher.combine(summary)
    hasher.combine(transcript)
  }
}

// MARK: - Tool Call

/// Represents a single tool or function invocation within an assistant turn.
///
/// Implements $O(1)$ fast-path `Equatable` and `Hashable` conformances (`[MF-3]`) using UTF-8 byte counts
/// for JSON and summary payloads.
public struct ToolCall: Identifiable, Hashable, Sendable {
  /// Execution status of a tool call.
  public enum Status: String, Hashable, Sendable {
    case pending
    case running
    case succeeded
    case failed
    case cancelled
  }

  public let id: String
  public var name: String
  public var icon: String?
  public var argumentsSummary: String?
  public var resultSummary: String?
  public var durationSeconds: TimeInterval?
  public var inputJSON: String?
  public var outputJSON: String?
  public var errorMessage: String?
  public var isSensitive: Bool
  public var status: Status

  /// Alias for `icon` supporting SF Symbol naming conventions.
  public var symbolName: String? {
    get { icon }
    set { icon = newValue }
  }

  /// Alias for `inputJSON`.
  public var argumentsJSON: String? {
    get { inputJSON }
    set { inputJSON = newValue }
  }

  /// Alias for `outputJSON`.
  public var resultJSON: String? {
    get { outputJSON }
    set { outputJSON = newValue }
  }

  public init(
    id: String = UUID().uuidString,
    name: String,
    icon: String? = nil,
    argumentsSummary: String? = nil,
    resultSummary: String? = nil,
    durationSeconds: TimeInterval? = nil,
    inputJSON: String? = nil,
    outputJSON: String? = nil,
    errorMessage: String? = nil,
    isSensitive: Bool = false,
    status: Status = .running
  ) {
    self.id = id
    self.name = name
    self.icon = icon
    self.argumentsSummary = argumentsSummary
    self.resultSummary = resultSummary
    self.durationSeconds = durationSeconds
    self.inputJSON = inputJSON
    self.outputJSON = outputJSON
    self.errorMessage = errorMessage
    self.isSensitive = isSensitive
    self.status = status
  }

  public static func == (lhs: ToolCall, rhs: ToolCall) -> Bool {
    lhs.id == rhs.id &&
    lhs.name == rhs.name &&
    lhs.icon == rhs.icon &&
    lhs.status == rhs.status &&
    lhs.durationSeconds == rhs.durationSeconds &&
    lhs.isSensitive == rhs.isSensitive &&
    lhs.argumentsSummary?.utf8.count == rhs.argumentsSummary?.utf8.count &&
    lhs.resultSummary?.utf8.count == rhs.resultSummary?.utf8.count &&
    lhs.inputJSON?.utf8.count == rhs.inputJSON?.utf8.count &&
    lhs.outputJSON?.utf8.count == rhs.outputJSON?.utf8.count &&
    lhs.errorMessage?.utf8.count == rhs.errorMessage?.utf8.count &&
    lhs.argumentsSummary == rhs.argumentsSummary &&
    lhs.resultSummary == rhs.resultSummary &&
    lhs.inputJSON == rhs.inputJSON &&
    lhs.outputJSON == rhs.outputJSON &&
    lhs.errorMessage == rhs.errorMessage
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(icon)
    hasher.combine(status)
    hasher.combine(durationSeconds)
    hasher.combine(isSensitive)
    hasher.combine(argumentsSummary?.utf8.count)
    hasher.combine(resultSummary?.utf8.count)
    hasher.combine(inputJSON?.utf8.count)
    hasher.combine(outputJSON?.utf8.count)
    hasher.combine(errorMessage?.utf8.count)
    hasher.combine(argumentsSummary)
    hasher.combine(resultSummary)
    hasher.combine(inputJSON)
    hasher.combine(outputJSON)
    hasher.combine(errorMessage)
  }
}

public typealias ToolCallItem = ToolCall

// MARK: - Citation

/// Represents a grounded source citation attached to an assistant turn.
public struct Citation: Identifiable, Hashable, Sendable {
  public let id: String
  public var title: String
  public var url: URL?
  public var snippet: String?
  public var domain: String?

  public init(
    id: String = UUID().uuidString,
    title: String,
    url: URL? = nil,
    snippet: String? = nil,
    domain: String? = nil
  ) {
    self.id = id
    self.title = title
    self.url = url
    self.snippet = snippet
    self.domain = domain ?? url?.host()
  }

  /// Returns `url` only when its scheme is `"https"` or `"http"` and it has a non-empty host (`[SF-2]`).
  /// Non-web schemes such as `javascript:`, `file:`, or `data:`, and hostless URLs return `nil`.
  public var safeWebURL: URL? {
    guard let url,
          let scheme = url.scheme?.lowercased(),
          (scheme == "http" || scheme == "https"),
          let host = url.host,
          !host.isEmpty
    else {
      return nil
    }
    return url
  }
}

public typealias SourceCitation = Citation

// MARK: - Agent Plan

/// Represents a structured multi-step execution plan proposed or executed by an agent.
public struct AgentPlan: Identifiable, Hashable, Sendable {
  /// A single step within an `AgentPlan`.
  public struct Step: Identifiable, Hashable, Sendable {
    /// Execution status of a plan step.
    public enum Status: String, Hashable, Sendable {
      case pending
      case inProgress
      case completed
      case failed
      case skipped
      case cancelled
    }

    public let id: String
    public var title: String
    public var detail: String?
    public var status: Status

    public init(
      id: String = UUID().uuidString,
      title: String,
      detail: String? = nil,
      status: Status = .pending
    ) {
      self.id = id
      self.title = title
      self.detail = detail
      self.status = status
    }
  }

  public let id: String
  public var title: String
  public var steps: [Step]

  public init(
    id: String = UUID().uuidString,
    title: String,
    steps: [Step] = []
  ) {
    self.id = id
    self.title = title
    self.steps = steps
  }

  /// The number of steps whose status is `.completed`.
  public var completedCount: Int {
    steps.count(where: { $0.status == .completed })
  }
}

public typealias AgentPlanStep = AgentPlan.Step

// MARK: - Approval Request

/// Represents a human-in-the-loop (HITL) permission gate requesting user authorization.
public struct ApprovalRequest: Identifiable, Hashable, Sendable {
  /// User or system resolution decision for an approval request.
  public enum Decision: String, Hashable, Sendable {
    case pending
    case allowOnce
    case alwaysAllow
    case deny
    case cancelled
  }

  public let id: String
  public var title: String
  public var detail: String
  public var scopeIdentifier: String?
  public var decision: Decision

  public init(
    id: String = UUID().uuidString,
    title: String,
    detail: String,
    scopeIdentifier: String? = nil,
    decision: Decision = .pending
  ) {
    self.id = id
    self.title = title
    self.detail = detail
    self.scopeIdentifier = scopeIdentifier
    self.decision = decision
  }
}

public typealias AgentApprovalRequest = ApprovalRequest
public typealias AgentApprovalDecision = ApprovalRequest.Decision

// MARK: - Welcome & Starter Prompt Models

/// Determines how selecting a starter prompt chip or card hands off to the conversation.
public enum PromptHandoffBehavior: String, Hashable, Sendable {
  /// Immediately submits the prompt as a user turn with optimistic scroll anchoring.
  case immediateSend
  /// Populates the composer text field and focuses it so the user can edit before sending.
  case populateComposer
}

/// A starter prompt suggestion displayed in `ConversationWelcomeView`.
public struct PromptSuggestion: Identifiable, Hashable, Sendable {
  public let id: String
  public var title: String
  public var subtitle: String?
  public var prompt: String
  public var icon: String?
  public var category: String?

  public init(
    id: String = UUID().uuidString,
    title: String,
    subtitle: String? = nil,
    prompt: String? = nil,
    icon: String? = nil,
    category: String? = nil
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.prompt = prompt ?? title
    self.icon = icon
    self.category = category
  }
}

/// Configuration for the empty-state welcome screen (`ConversationWelcomeView`).
public struct WelcomeConfiguration: Hashable, Sendable {
  public var greetingOverride: String?
  public var userName: String?
  public var subtitle: String?
  public var suggestions: [PromptSuggestion]
  public var visibleCount: Int
  public var allowsShuffle: Bool
  public var handoff: PromptHandoffBehavior

  public init(
    greetingOverride: String? = nil,
    userName: String? = nil,
    subtitle: String? = nil,
    suggestions: [PromptSuggestion] = [],
    visibleCount: Int = 4,
    allowsShuffle: Bool = true,
    handoff: PromptHandoffBehavior = .immediateSend
  ) {
    self.greetingOverride = greetingOverride
    self.userName = userName
    self.subtitle = subtitle
    self.suggestions = suggestions
    self.visibleCount = visibleCount
    self.allowsShuffle = allowsShuffle
    self.handoff = handoff
  }

  /// Deterministically resolves the greeting string for a given date and calendar (`AC-1`).
  ///
  /// - Parameters:
  ///   - date: The reference date to evaluate (defaults to `Date()`).
  ///   - calendar: The calendar used to extract the hour component (defaults to `.current`).
  /// - Returns: A greeting string incorporating `greetingOverride` or the time of day and optional `userName`.
  public func resolvedGreeting(for date: Date = Date(), calendar: Calendar = .current) -> String {
    if let greetingOverride = greetingOverride?.trimmingCharacters(in: .whitespacesAndNewlines),
       !greetingOverride.isEmpty {
      return greetingOverride
    }

    let hour = calendar.component(.hour, from: date)
    let timeGreeting: String
    switch hour {
    case 5..<12:
      timeGreeting = "Good morning"
    case 12..<18:
      timeGreeting = "Good afternoon"
    default:
      timeGreeting = "Good evening"
    }

    if let userName = userName?.trimmingCharacters(in: .whitespacesAndNewlines),
       !userName.isEmpty {
      return "\(timeGreeting), \(userName)"
    }
    return timeGreeting
  }
}

// MARK: - Composer Models

/// Represents an AI model option selectable in `MessageComposerView`.
public struct ComposerModelOption: Identifiable, Hashable, Sendable {
  public let id: String
  public var name: String
  public var subtitle: String?
  public var icon: String?

  /// Alias for `icon` supporting SF Symbol naming conventions.
  public var symbolName: String? {
    get { icon }
    set { icon = newValue }
  }

  public init(
    id: String,
    name: String,
    subtitle: String? = nil,
    icon: String? = nil
  ) {
    self.id = id
    self.name = name
    self.subtitle = subtitle
    self.icon = icon
  }
}

/// Represents a toggleable capability chip in `MessageComposerView`.
public enum ComposerCapability: Identifiable, Hashable, Sendable {
  case think
  case search
  case image
  case custom(id: String, title: String, icon: String)

  public init(id: String, title: String, icon: String) {
    switch id {
    case "think" where title == "Think" && icon == "brain":
      self = .think
    case "search" where title == "Search" && icon == "globe":
      self = .search
    case "image" where title == "Image" && icon == "photo.badge.plus":
      self = .image
    default:
      self = .custom(id: id, title: title, icon: icon)
    }
  }

  public var id: String {
    switch self {
    case .think:
      return "think"
    case .search:
      return "search"
    case .image:
      return "image"
    case .custom(let id, _, _):
      return id
    }
  }

  public var title: String {
    switch self {
    case .think:
      return "Think"
    case .search:
      return "Search"
    case .image:
      return "Image"
    case .custom(_, let title, _):
      return title
    }
  }

  public var icon: String {
    switch self {
    case .think:
      return "brain"
    case .search:
      return "globe"
    case .image:
      return "photo.badge.plus"
    case .custom(_, _, let icon):
      return icon
    }
  }

  /// Alias for `icon` supporting SF Symbol naming conventions.
  public var symbolName: String {
    icon
  }
}

/// Represents a structured `/` slash command or `@` mention token chip in `MessageComposerView`.
public struct ComposerTokenChip: Identifiable, Hashable, Sendable {
  public enum Kind: String, Hashable, Sendable {
    case slashCommand
    case mention
  }

  public let id: String
  public var kind: Kind
  public var trigger: String
  public var title: String
  public var value: String
  public var icon: String?

  /// Alias for `title`.
  public var label: String {
    get { title }
    set { title = newValue }
  }

  public init(
    id: String = UUID().uuidString,
    kind: Kind,
    trigger: String,
    title: String,
    value: String? = nil,
    icon: String? = nil
  ) {
    self.id = id
    self.kind = kind
    self.trigger = trigger
    self.title = title
    self.value = value ?? title
    self.icon = icon
  }

  public init(
    id: String = UUID().uuidString,
    kind: Kind,
    trigger: String,
    label: String,
    value: String,
    icon: String? = nil
  ) {
    self.init(
      id: id,
      kind: kind,
      trigger: trigger,
      title: label,
      value: value,
      icon: icon
    )
  }
}

/// Enriched submission payload carrying the user message alongside composer attachments,
/// active capabilities, resolved token chips, and selected model identifier (`[MF-1]`).
public struct MessageSubmission<MessageType: Message, AttachmentType: Attachment> {
  public let message: MessageType
  public let attachments: [AttachmentType]
  public let activeCapabilities: Set<ComposerCapability>
  public let tokens: [ComposerTokenChip]
  public let selectedModelID: String?

  public init(
    message: MessageType,
    attachments: [AttachmentType] = [],
    activeCapabilities: Set<ComposerCapability> = [],
    tokens: [ComposerTokenChip] = [],
    selectedModelID: String? = nil
  ) {
    self.message = message
    self.attachments = attachments
    self.activeCapabilities = activeCapabilities
    self.tokens = tokens
    self.selectedModelID = selectedModelID
  }
}

extension MessageSubmission: Sendable where MessageType: Sendable, AttachmentType: Sendable {}
extension MessageSubmission: Equatable where MessageType: Equatable, AttachmentType: Equatable {}
extension MessageSubmission: Hashable where MessageType: Hashable, AttachmentType: Hashable {}
