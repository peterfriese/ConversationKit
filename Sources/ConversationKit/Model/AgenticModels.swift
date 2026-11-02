//
//  AgenticModels.swift
//  ConversationKit
//
//  Agentic timeline models: ThinkingTrace, ToolCall, Citation, AgentPlan,
//  ApprovalRequest, MessageFeedback, and MessageError.
//

import Foundation

// MARK: - ThinkingTrace

/// Represents a chain-of-thought reasoning trace rendered by `ThinkingStateView` (`F-7`, `AC-11`).
///
/// `ThinkingTrace.defaultExpanded` is strictly `false` so reasoning blocks always start collapsed
/// in the timeline unless expanded by the user.
///
/// Equality (`==`) and hashing (`hash(into:)`) implement an $O(1)$ fast path comparing `id`, `status`,
/// `summary?.utf8.count`, and `transcript.utf8.count` before falling back to full string equality,
/// ensuring 120Hz streaming updates never stall `@MainActor`.
public struct ThinkingTrace: Identifiable, Hashable, Sendable, Codable {

  /// Lifecycle status of the reasoning phase.
  public enum Status: Sendable, Hashable, Codable {
    /// Actively streaming reasoning tokens since `startedAt`.
    case thinking(startedAt: Date)
    /// Completed reasoning after `duration` seconds.
    case completed(duration: TimeInterval)
    /// Reasoning was interrupted/cancelled after `duration` seconds.
    case cancelled(duration: TimeInterval)
  }

  /// Canonical default expansion state (`false`) enforced by `ThinkingStateView` (`F-7`, `AC-11`).
  public static let defaultExpanded: Bool = false

  /// Stable unique identifier for the trace.
  public let id: String

  /// Current reasoning status.
  public var status: Status

  /// Optional concise summary headline (e.g., `"Analyzing scroll geometry invariants"`).
  public var summary: String?

  /// Full reasoning transcript text.
  public var transcript: String

  /// Returns `true` while `status` is `.thinking`.
  public var isStreaming: Bool {
    if case .thinking = status {
      return true
    }
    return false
  }

  /// Completed or cancelled duration in seconds, or `nil` while `.thinking`.
  public var duration: TimeInterval? {
    switch status {
    case .thinking:
      return nil
    case .completed(let duration), .cancelled(let duration):
      return duration
    }
  }

  /// Creates a `ThinkingTrace` using `status`, `summary`, and `transcript`.
  public init(
    id: String = UUID().uuidString,
    status: Status = .thinking(startedAt: .now),
    summary: String? = nil,
    transcript: String = ""
  ) {
    self.id = id
    self.status = status
    self.summary = summary
    self.transcript = transcript
  }

  // MARK: $O(1)$ Fast-Path Equatable & Hashable

  /// $O(1)$ fast-path equality check comparing `id`, `status`, UTF-8 byte lengths, and bounded prefix/suffix slices.
  public static func == (lhs: ThinkingTrace, rhs: ThinkingTrace) -> Bool {
    guard
      lhs.id == rhs.id,
      lhs.status == rhs.status,
       fastOptionalUTF8Equal(lhs.summary, rhs.summary),
      fastUTF8Equal(lhs.transcript, rhs.transcript)
    else {
      return false
    }
    return true
  }

  /// $O(1)$ hashing using `id`, `status`, and UTF-8 byte counts.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(status)
    hasher.combine(summary?.utf8.count)
    hasher.combine(transcript.utf8.count)
  }
}

// MARK: - ToolCall

/// Represents an individual agentic tool invocation rendered inside `ToolCallsGroupView` (`F-7`, `AC-18`).
///
/// Includes an $O(1)$ fast-path `==` and `hash(into:)` implementation that checks UTF-8 byte counts
/// on JSON and summary strings before performing character-by-character comparisons.
public struct ToolCall: Identifiable, Hashable, Sendable, Codable {

  /// Execution lifecycle state of a `ToolCall`.
  public enum Status: Sendable, Hashable, Codable {
    /// Queued and waiting to execute.
    case pending
    /// Actively executing since `startedAt`.
    case running(startedAt: Date)
    /// Completed successfully in `duration` seconds.
    case succeeded(duration: TimeInterval)
    /// Failed with an error message and optional elapsed `duration`.
    case failed(error: String, duration: TimeInterval? = nil)
    /// Cancelled before completion with optional elapsed `duration`.
    case cancelled(duration: TimeInterval? = nil)
  }

  /// Stable unique identifier for the tool call.
  public let id: String

  /// Programmatic or display name of the tool (e.g., `"web_search"` or `"Search Docs"`).
  public var name: String

  /// SF Symbol name representing the tool.
  public var symbolName: String

  /// Current execution status.
  public var status: Status

  /// Optional concise summary of the tool arguments (e.g., `"query: iOS 26 Liquid Glass"`).
  public var argumentsSummary: String?

  /// Optional concise summary of the tool result (e.g., `"12 documents matched"`).
  public var resultSummary: String?

  /// Optional raw or pretty-printed JSON arguments string shown in the expandable inspector.
  public var argumentsJSON: String?

  /// Optional raw or pretty-printed JSON result string shown in the expandable inspector.
  public var resultJSON: String?

  /// Returns `true` when `status` is `.pending` or `.running`.
  public var isActive: Bool {
    switch status {
    case .pending, .running:
      return true
    case .succeeded, .failed, .cancelled:
      return false
    }
  }

  /// Creates a `ToolCall`.
  public init(
    id: String = UUID().uuidString,
    name: String,
    symbolName: String = "wrench.and.screwdriver",
    status: Status = .pending,
    argumentsSummary: String? = nil,
    resultSummary: String? = nil,
    argumentsJSON: String? = nil,
    resultJSON: String? = nil
  ) {
    self.id = id
    self.name = name
    self.symbolName = symbolName
    self.status = status
    self.argumentsSummary = argumentsSummary
    self.resultSummary = resultSummary
    self.argumentsJSON = argumentsJSON
    self.resultJSON = resultJSON
  }

  // MARK: $O(1)$ Fast-Path Equatable & Hashable

  /// $O(1)$ fast-path equality check comparing scalar properties, UTF-8 byte counts, and bounded prefix/suffix slices.
  public static func == (lhs: ToolCall, rhs: ToolCall) -> Bool {
    guard
      lhs.id == rhs.id,
      lhs.name == rhs.name,
      lhs.symbolName == rhs.symbolName,
      lhs.status == rhs.status,
      fastOptionalUTF8Equal(lhs.argumentsSummary, rhs.argumentsSummary),
      fastOptionalUTF8Equal(lhs.resultSummary, rhs.resultSummary),
      fastOptionalUTF8Equal(lhs.argumentsJSON, rhs.argumentsJSON),
      fastOptionalUTF8Equal(lhs.resultJSON, rhs.resultJSON)
    else {
      return false
    }
    return true
  }

  /// $O(1)$ hashing using scalar identifiers, `status`, and UTF-8 byte counts.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(symbolName)
    hasher.combine(status)
    hasher.combine(argumentsSummary?.utf8.count)
    hasher.combine(resultSummary?.utf8.count)
    hasher.combine(argumentsJSON?.utf8.count)
    hasher.combine(resultJSON?.utf8.count)
  }
}

// MARK: - Citation

/// Represents an external source citation rendered inside `SourceStackView` with strict URL allowlisting (`AC-18`, `[MF-5]`).
public struct Citation: Identifiable, Hashable, Sendable, Codable {

  /// Stable unique identifier.
  public let id: String

  /// Optional 1-based citation footnote index (e.g., `1`, `2`, `3`).
  public var index: Int?

  /// Display title of the cited page or document.
  public var title: String

  /// Host domain label displayed in the source badge (e.g., `"developer.apple.com"`).
  public var domain: String

  /// Optional excerpt snippet from the cited source.
  public var snippet: String?

  /// Raw unvalidated `URL` associated with the citation.
  public var url: URL?

  /// Validated `URL` returned if and only if `url?.isAllowedConversationURL == true` (`http`/`https` with non-empty host).
  ///
  /// Rejects `javascript:`, `file:`, `data:`, `vbscript:`, and custom schemes (`AC-18`).
  public var sanitizedURL: URL? {
    url?.isAllowedConversationURL == true ? url : nil
  }

  /// Creates a `Citation` with an optional `URL` and automatic domain extraction when `domain` is omitted.
  public init(
    id: String = UUID().uuidString,
    index: Int? = nil,
    title: String,
    domain: String? = nil,
    snippet: String? = nil,
    url: URL? = nil
  ) {
    self.id = id
    self.index = index
    self.title = title
    self.snippet = snippet
    self.url = url
    if let domain, !domain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      self.domain = domain
    } else if let host = url?.host(), !host.isEmpty {
      self.domain = Self.stripWWWPrefix(from: host)
    } else {
      self.domain = "source"
    }
  }

  /// Convenience initializer accepting a raw `urlString: String`.
  public init(
    id: String = UUID().uuidString,
    index: Int? = nil,
    title: String,
    domain: String? = nil,
    urlString: String,
    snippet: String? = nil
  ) {
    let parsedURL = URL(string: urlString)
    self.init(
      id: id,
      index: index,
      title: title,
      domain: domain,
      snippet: snippet,
      url: parsedURL
    )
  }

  private static func stripWWWPrefix(from host: String) -> String {
    if host.lowercased().hasPrefix("www.") && host.count > 4 {
      return String(host.dropFirst(4))
    }
    return host
  }
}

// MARK: - AgentPlan

/// Represents a multi-step agent execution plan rendered by `AgentPlanView` (`F-7`).
public struct AgentPlan: Identifiable, Hashable, Sendable, Codable {

  /// A single step within an `AgentPlan`.
  public struct Step: Identifiable, Hashable, Sendable, Codable {

    /// Execution status of an individual plan step.
    public enum Status: String, Sendable, Hashable, Codable, CaseIterable {
      case pending
      case inProgress
      case completed
      case failed
      case skipped
      case cancelled
    }

    /// Stable unique identifier for the step.
    public let id: String
    /// Headline description of the step.
    public var title: String
    /// Optional secondary detail or note.
    public var detail: String?
    /// Current step status.
    public var status: Status

    /// Creates an `AgentPlan.Step`.
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

  /// Stable unique identifier for the plan.
  public let id: String

  /// Title of the execution plan.
  public var title: String

  /// Ordered steps comprising the plan.
  public var steps: [Step]

  /// Number of steps whose `status` is `.completed`.
  public var completedCount: Int {
    steps.reduce(into: 0) { count, step in
      if step.status == .completed {
        count += 1
      }
    }
  }

  /// Normalized completion progress in `0.0...1.0`.
  public var progressFraction: Double {
    guard !steps.isEmpty else { return 0.0 }
    return Double(completedCount) / Double(steps.count)
  }

  /// Creates an `AgentPlan`.
  public init(
    id: String = UUID().uuidString,
    title: String,
    steps: [Step] = []
  ) {
    self.id = id
    self.title = title
    self.steps = steps
  }
}

// MARK: - ApprovalRequest

/// Represents a human-in-the-loop permission request rendered by `AgentApprovalView` (`F-7`, `AC-18`).
public struct ApprovalRequest: Identifiable, Hashable, Sendable, Codable {

  /// Severity / risk classification of the requested operation.
  public enum RiskLevel: String, Sendable, Hashable, Codable, CaseIterable {
    case low
    case medium
    case high
  }

  /// User or system decision state for the approval request.
  public enum Decision: String, Sendable, Hashable, Codable, CaseIterable {
    case pending
    case allowOnce
    case alwaysAllow
    case deny
    case cancelled
  }

  /// Stable unique identifier for the approval request.
  public let id: String

  /// Headline title describing the action requiring approval (e.g., `"Run shell command"`).
  public var title: String

  /// Detailed explanation of why permission is requested and its impact.
  public var detail: String

  /// Severity level of the operation.
  public var riskLevel: RiskLevel

  /// Optional tool, file, or permission scope identifier (e.g., `"shell.exec"` or `"/etc/hosts"`).
  public var scopeIdentifier: String?

  /// Optional monospaced command or diff preview shown inside the approval card.
  public var changePreview: String?

  /// Current resolution decision (defaults to `.pending`).
  public var decision: Decision

  /// Returns `true` when `decision != .pending`.
  public var isResolved: Bool {
    decision != .pending
  }

  /// Creates an `ApprovalRequest`.
  public init(
    id: String = UUID().uuidString,
    title: String,
    detail: String,
    riskLevel: RiskLevel = .medium,
    scopeIdentifier: String? = nil,
    changePreview: String? = nil,
    decision: Decision = .pending
  ) {
    self.id = id
    self.title = title
    self.detail = detail
    self.riskLevel = riskLevel
    self.scopeIdentifier = scopeIdentifier
    self.changePreview = changePreview
    self.decision = decision
  }
}

// MARK: - MessageFeedback

/// User rating feedback on an assistant message (`MessageActionBarView`).
public enum MessageFeedback: String, Sendable, Hashable, Codable, CaseIterable {
  case thumbsUp
  case thumbsDown
}

// MARK: - MessageError

/// Structured, value-typed error representation attached to a failed `Message` (`AC-18`).
public struct MessageError: Identifiable, Hashable, Sendable, Codable, Error, LocalizedError {
  /// Stable unique identifier for the error occurrence.
  public let id: String

  /// Primary user-facing error message.
  public var message: String

  /// Optional secondary diagnostic or recovery detail.
  public var detail: String?

  /// Indicates whether the failed turn or message can be retried by tapping Retry.
  public var isRetryable: Bool

  /// LocalizedError conformance returning `message`.
  public var errorDescription: String? {
    message
  }

  /// Creates a `MessageError`.
  public init(
    id: String = UUID().uuidString,
    message: String,
    detail: String? = nil,
    isRetryable: Bool = true
  ) {
    self.id = id
    self.message = message
    self.detail = detail
    self.isRetryable = isRetryable
  }

  /// Creates a `MessageError` wrapping an arbitrary Swift `Error`.
  public init(
    id: String = UUID().uuidString,
    error: any Error,
    detail: String? = nil,
    isRetryable: Bool = true
  ) {
    if let existing = error as? MessageError {
      self = existing
      return
    }
    self.id = id
    self.message = error.localizedDescription
    self.detail = detail
    self.isRetryable = isRetryable
  }
}

// MARK: - Internal $O(1)$ UTF-8 String Comparison Helpers (`[MF-4]`)

@inlinable
internal func fastUTF8Equal(_ lhs: String, _ rhs: String) -> Bool {
  let lhsUTF8 = lhs.utf8
  let rhsUTF8 = rhs.utf8
  let count = lhsUTF8.count
  guard count == rhsUTF8.count else { return false }
  guard count > 0 else { return true }
  return lhsUTF8[lhsUTF8.startIndex] == rhsUTF8[rhsUTF8.startIndex]
    && lhsUTF8[lhsUTF8.index(before: lhsUTF8.endIndex)] == rhsUTF8[rhsUTF8.index(before: rhsUTF8.endIndex)]
}

@inlinable
internal func fastOptionalUTF8Equal(_ lhs: String?, _ rhs: String?) -> Bool {
  switch (lhs, rhs) {
  case (.none, .none):
    return true
  case (.some(let l), .some(let r)):
    return fastUTF8Equal(l, r)
  default:
    return false
  }
}
