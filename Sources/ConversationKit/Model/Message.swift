//
//  Message.swift
//  ConversationKit
//
//  Core Message protocol, DefaultMessage with O(1) streaming diffing fast path,
//  ConversationSubmission, and ConversationTurn grouping engine.
//

import Foundation

// MARK: - Participant

/// Identifies the author role of a message in the conversation timeline.
public enum Participant: String, Sendable, Hashable, Codable, CaseIterable {
  /// The human user interacting with the conversation.
  case user
  /// The AI assistant, agent, or remote participant.
  case other
}

// MARK: - Message Protocol

/// Core protocol representing a single message in `ConversationView`.
///
/// Following **Stratos Progressive Disclosure**, only `id`, `content`, `participant`, `createdAt`,
/// and `makeUserMessage(...)` are required by the protocol; all multimodal and agentic properties
/// provide sensible empty/nil defaults via protocol extension.
///
/// ### Usage
/// ```swift
/// // Layer 1 (Troposphere): Use built-in DefaultMessage
/// @State private var messages: [DefaultMessage] = [
///   DefaultMessage(content: "Hello! How can I help you today?", participant: .other)
/// ]
///
/// // Layer 4 (Thermosphere): Conform a custom domain model to Message
/// struct ChatItem: Message {
///   let id: String
///   var content: String?
///   let participant: Participant
///   let createdAt: Date
///
///   static func makeUserMessage(
///     id: String,
///     content: String?,
///     attachments: [ConversationAttachment],
///     tokens: [ComposerToken],
///     selectedModelID: String?
///   ) -> ChatItem {
///     ChatItem(id: id, content: content, participant: .user, createdAt: .now)
///   }
/// }
/// ```
public protocol Message: Identifiable, Hashable, Sendable where ID == String {
  /// Stable unique identifier for the message.
  var id: String { get }

  /// Text or Markdown content of the message (`nil` or empty on `.other` renders the initial thinking/loading state).
  var content: String? { get set }

  /// Author role (`.user` or `.other`).
  var participant: Participant { get }

  /// Creation timestamp of the message.
  var createdAt: Date { get }

  // MARK: Multimodal & Composer Context

  /// Multimodal attachments associated with this message.
  var attachments: [ConversationAttachment] { get }

  /// Structured `/command` and `@mention` tokens submitted with this message.
  var tokens: [ComposerToken] { get }

  /// Identifier of the `ComposerModelOption` active when this message was created, if any.
  var selectedModelID: String? { get }

  // MARK: Agentic & Reasoning Primitives

  /// Reasoning / chain-of-thought trace rendered by `ThinkingStateView` (collapsed by default).
  var thinkingTrace: ThinkingTrace? { get }

  /// Agentic tool calls rendered by `ToolCallsGroupView`.
  var toolCalls: [ToolCall] { get }

  /// External source citations rendered by `SourceStackView`.
  var citations: [Citation] { get }

  /// Step-by-step execution plan rendered by `AgentPlanView`.
  var plan: AgentPlan? { get }

  /// Human-in-the-loop permission request rendered by `ApprovalRequestView` / `AgentApprovalView`.
  var approvalRequest: ApprovalRequest? { get }

  // MARK: Lifecycle, Feedback & Error State

  /// Indicates whether the message is actively streaming tokens (`true`) or settled (`false`).
  var isStreaming: Bool { get }

  /// Optional user feedback rating (`.thumbsUp` or `.thumbsDown`).
  var feedback: MessageFeedback? { get }

  /// Structured value-type error associated with the message, if failed.
  var messageError: MessageError? { get }

  /// Existential `Error` representation of a failure on this message, if any.
  var error: (any Error)? { get }

  /// Factory method used by `ConversationView` to construct a strongly-typed user message
  /// synchronously on submission without requiring `as?` downcasting (`AC-19`).
  static func makeUserMessage(
    id: String,
    content: String?,
    attachments: [ConversationAttachment],
    tokens: [ComposerToken],
    selectedModelID: String?
  ) -> Self
}

// MARK: - Message Default Implementations

extension Message {
  public var createdAt: Date { .distantPast }
  public var attachments: [ConversationAttachment] { [] }
  public var tokens: [ComposerToken] { [] }
  public var selectedModelID: String? { nil }
  public var thinkingTrace: ThinkingTrace? { nil }
  public var toolCalls: [ToolCall] { [] }
  public var citations: [Citation] { [] }
  public var plan: AgentPlan? { nil }
  public var approvalRequest: ApprovalRequest? { nil }
  public var isStreaming: Bool { false }
  public var feedback: MessageFeedback? { nil }
  public var messageError: MessageError? { nil }
  public var error: (any Error)? { messageError }

  /// Convenience error description extracted from `messageError` or `error`.
  public var errorMessage: String? {
    messageError?.message ?? error?.localizedDescription
  }
}

// MARK: - DefaultMessage

/// Batteries-included concrete `Message` implementation supporting full multimodal attachments,
/// structured composer tokens, and agentic primitives (`ThinkingTrace`, `ToolCall`, `Citation`,
/// `AgentPlan`, `ApprovalRequest`, `MessageError`).
///
/// `DefaultMessage` implements an $O(1)$ fast path for `Equatable` and `Hashable` by checking
/// scalar properties, `content?.utf8.count`, `messageError`, and `error != nil` fingerprint first,
/// making 120Hz ProMotion streaming diffs ultra-fast even on multi-thousand-word responses.
public struct DefaultMessage: Message, Codable {

  public var id: String
  public var content: String?
  public var participant: Participant
  public var createdAt: Date
  public var attachments: [ConversationAttachment]
  public var tokens: [ComposerToken]
  public var selectedModelID: String?
  public var thinkingTrace: ThinkingTrace?
  public var toolCalls: [ToolCall]
  public var citations: [Citation]
  public var plan: AgentPlan?
  public var approvalRequest: ApprovalRequest?
  public var isStreaming: Bool
  public var feedback: MessageFeedback?
  public var messageError: MessageError?

  private var underlyingError: (any Error)?

  /// Existential `Error` associated with this message, backed by either an arbitrary `any Error`
  /// or `messageError`.
  public var error: (any Error)? {
    get {
      underlyingError ?? messageError
    }
    set {
      underlyingError = newValue
      if let newValue {
        if let msgErr = newValue as? MessageError {
          messageError = msgErr
        } else if messageError == nil {
          messageError = MessageError(error: newValue)
        }
      } else {
        messageError = nil
      }
    }
  }

  /// Convenience string accessor/mutator for `messageError?.message`.
  public var errorMessage: String? {
    get { messageError?.message ?? underlyingError?.localizedDescription }
    set {
      if let newValue {
        let updated = MessageError(message: newValue)
        messageError = updated
        underlyingError = updated
      } else {
        messageError = nil
        underlyingError = nil
      }
    }
  }

  // MARK: Initializers

  /// Creates a `DefaultMessage` with full multimodal and agentic metadata support.
  public init(
    id: String = UUID().uuidString,
    content: String? = nil,
    participant: Participant = .user,
    createdAt: Date = .now,
    attachments: [ConversationAttachment] = [],
    tokens: [ComposerToken] = [],
    selectedModelID: String? = nil,
    thinkingTrace: ThinkingTrace? = nil,
    toolCalls: [ToolCall] = [],
    citations: [Citation] = [],
    plan: AgentPlan? = nil,
    approvalRequest: ApprovalRequest? = nil,
    isStreaming: Bool = false,
    feedback: MessageFeedback? = nil,
    messageError: MessageError? = nil,
    error: (any Error)? = nil
  ) {
    self.id = id
    self.content = content
    self.participant = participant
    self.createdAt = createdAt
    self.attachments = attachments
    self.tokens = tokens
    self.selectedModelID = selectedModelID
    self.thinkingTrace = thinkingTrace
    self.toolCalls = toolCalls
    self.citations = citations
    self.plan = plan
    self.approvalRequest = approvalRequest
    self.isStreaming = isStreaming
    self.feedback = feedback

    if let messageError {
      self.messageError = messageError
      self.underlyingError = error ?? messageError
    } else if let error {
      self.underlyingError = error
      self.messageError = (error as? MessageError) ?? MessageError(error: error)
    } else {
      self.messageError = nil
      self.underlyingError = nil
    }
  }

  // MARK: Factory Requirement

  /// Constructs a `DefaultMessage` for a newly submitted user prompt.
  public static func makeUserMessage(
    id: String = UUID().uuidString,
    content: String?,
    attachments: [ConversationAttachment] = [],
    tokens: [ComposerToken] = [],
    selectedModelID: String? = nil
  ) -> DefaultMessage {
    DefaultMessage(
      id: id,
      content: content,
      participant: .user,
      createdAt: .now,
      attachments: attachments,
      tokens: tokens,
      selectedModelID: selectedModelID
    )
  }

  // MARK: $O(1)$ Fast-Path Equatable & Hashable

  /// Fast-path equality comparing scalar properties, `content?.utf8.count`, `messageError`,
  /// and `error != nil` fingerprint before inspecting full string or collection contents.
  public static func == (lhs: DefaultMessage, rhs: DefaultMessage) -> Bool {
    guard
      lhs.id == rhs.id,
      lhs.participant == rhs.participant,
      lhs.isStreaming == rhs.isStreaming,
      fastOptionalUTF8Equal(lhs.content, rhs.content),
      lhs.createdAt == rhs.createdAt,
      lhs.selectedModelID == rhs.selectedModelID,
      lhs.feedback == rhs.feedback,
      lhs.messageError == rhs.messageError,
      (lhs.underlyingError != nil) == (rhs.underlyingError != nil),
      lhs.attachments.count == rhs.attachments.count,
      lhs.tokens.count == rhs.tokens.count,
      lhs.toolCalls.count == rhs.toolCalls.count,
      lhs.citations.count == rhs.citations.count,
      lhs.thinkingTrace == rhs.thinkingTrace,
      lhs.plan == rhs.plan,
      lhs.approvalRequest == rhs.approvalRequest,
      (lhs.attachments.isEmpty || lhs.attachments == rhs.attachments),
      (lhs.tokens.isEmpty || lhs.tokens == rhs.tokens),
      (lhs.toolCalls.isEmpty || lhs.toolCalls == rhs.toolCalls),
      (lhs.citations.isEmpty || lhs.citations == rhs.citations)
    else {
      return false
    }

    if let lhsErr = lhs.underlyingError, let rhsErr = rhs.underlyingError {
      guard
        String(reflecting: type(of: lhsErr)) == String(reflecting: type(of: rhsErr)),
        lhsErr.localizedDescription == rhsErr.localizedDescription
      else {
        return false
      }
    }

    return true
  }

  /// Fast-path hashing combining scalar properties, `content?.utf8.count`, `messageError`,
  /// and `error != nil` without scanning the full `content` string buffer.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(participant)
    hasher.combine(isStreaming)
    hasher.combine(content?.utf8.count)
    hasher.combine(createdAt)
    hasher.combine(selectedModelID)
    hasher.combine(feedback)
    hasher.combine(messageError)
    hasher.combine(error != nil)
    hasher.combine(attachments)
    hasher.combine(tokens)
    hasher.combine(thinkingTrace)
    hasher.combine(toolCalls)
    hasher.combine(citations)
    hasher.combine(plan)
    hasher.combine(approvalRequest)
  }

  // MARK: Codable

  private enum CodingKeys: String, CodingKey {
    case id
    case content
    case participant
    case createdAt
    case attachments
    case tokens
    case selectedModelID
    case thinkingTrace
    case toolCalls
    case citations
    case plan
    case approvalRequest
    case isStreaming
    case feedback
    case messageError
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(String.self, forKey: .id)
    self.content = try container.decodeIfPresent(String.self, forKey: .content)
    self.participant = try container.decode(Participant.self, forKey: .participant)
    self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    self.attachments = try container.decodeIfPresent([ConversationAttachment].self, forKey: .attachments) ?? []
    self.tokens = try container.decodeIfPresent([ComposerToken].self, forKey: .tokens) ?? []
    self.selectedModelID = try container.decodeIfPresent(String.self, forKey: .selectedModelID)
    self.thinkingTrace = try container.decodeIfPresent(ThinkingTrace.self, forKey: .thinkingTrace)
    self.toolCalls = try container.decodeIfPresent([ToolCall].self, forKey: .toolCalls) ?? []
    self.citations = try container.decodeIfPresent([Citation].self, forKey: .citations) ?? []
    self.plan = try container.decodeIfPresent(AgentPlan.self, forKey: .plan)
    self.approvalRequest = try container.decodeIfPresent(ApprovalRequest.self, forKey: .approvalRequest)
    self.isStreaming = try container.decodeIfPresent(Bool.self, forKey: .isStreaming) ?? false
    self.feedback = try container.decodeIfPresent(MessageFeedback.self, forKey: .feedback)
    self.messageError = try container.decodeIfPresent(MessageError.self, forKey: .messageError)
    self.underlyingError = self.messageError
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encodeIfPresent(content, forKey: .content)
    try container.encode(participant, forKey: .participant)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(attachments, forKey: .attachments)
    try container.encode(tokens, forKey: .tokens)
    try container.encodeIfPresent(selectedModelID, forKey: .selectedModelID)
    try container.encodeIfPresent(thinkingTrace, forKey: .thinkingTrace)
    try container.encode(toolCalls, forKey: .toolCalls)
    try container.encode(citations, forKey: .citations)
    try container.encodeIfPresent(plan, forKey: .plan)
    try container.encodeIfPresent(approvalRequest, forKey: .approvalRequest)
    try container.encode(isStreaming, forKey: .isStreaming)
    try container.encodeIfPresent(feedback, forKey: .feedback)
    try container.encodeIfPresent(messageError, forKey: .messageError)
  }
}

// MARK: - ConversationSubmission

/// Strongly-typed submission payload emitted by `ConversationView` when a user sends a prompt (`AC-19`).
///
/// Eliminates all `any Message` existential downcasting by carrying `message: MessageType` directly
/// alongside the stripped `text`, `attachments`, structured `command`/`mentions`/`tokens`, `selectedModel`,
/// and `activeCapabilities`.
public struct ConversationSubmission<MessageType: Message>: Identifiable, Sendable, Hashable {
  /// Stable submission identifier (defaults to `message.id`).
  public let id: String

  /// The newly constructed user message with a stable `id` matching the optimistic UI turn anchor.
  public let message: MessageType

  /// Plain-text prompt with the internal `\u{200B}` zero-width sentinel stripped.
  public let text: String

  /// Attached files, photos, PDFs, or data blobs at the time of submission.
  public let attachments: [ConversationAttachment]

  /// Primary `/` slash command attached to this submission, if any.
  public let command: SlashCommand?

  /// `@` resource mentions attached to this submission.
  public let mentions: [ResourceMention]

  /// All structured `/command` and `@mention` tokens attached to this submission.
  public let tokens: [ComposerToken]

  /// The active `ComposerModelOption` selected in the composer at submission time, if configured.
  public let selectedModel: ComposerModelOption?

  /// The set of active `ComposerCapability` toggles (`Think`, `Search`, `Image`, etc.).
  public let activeCapabilities: Set<ComposerCapability>

  /// Creates a `ConversationSubmission`.
  ///
  /// When `command` or `mentions` are omitted, they are automatically derived from `tokens`.
  public init(
    id: String? = nil,
    message: MessageType,
    text: String,
    attachments: [ConversationAttachment] = [],
    command: SlashCommand? = nil,
    mentions: [ResourceMention]? = nil,
    tokens: [ComposerToken] = [],
    selectedModel: ComposerModelOption? = nil,
    activeCapabilities: Set<ComposerCapability> = []
  ) {
    self.id = id ?? message.id
    self.message = message
    self.text = ComposerTextBuffer.cleanText(text)
    self.attachments = attachments
    self.tokens = tokens
    self.command = command ?? tokens.lazy.compactMap(\.command).first
    self.mentions = mentions ?? tokens.compactMap(\.mention)
    self.selectedModel = selectedModel
    self.activeCapabilities = activeCapabilities
  }
}

// MARK: - ConversationTurn (`§3.4.1`)

/// A deterministic conversational turn grouping a user prompt (`userMessage`) with its subsequent
/// assistant response messages (`assistantMessages`).
///
/// `ConversationView` groups flat `messages` into `ConversationTurn` values so the active (final) turn
/// can reserve the unoccluded viewport runway (`activeTurnMinHeight`) and anchor the user's prompt at
/// the top edge of the viewport with $\Delta Y = 0\text{pt}$ throughout streaming overflow (`F-1`, `F-2`, `[MF-3]`).
public struct ConversationTurn<MessageType: Message>: Identifiable, Hashable, Sendable {
  /// Stable turn identifier equal to `userMessage?.id ?? assistantMessages.first?.id`.
  public let id: String

  /// The user message that initiated this turn, or `nil` if the conversation began with an assistant greeting.
  public var userMessage: MessageType?

  /// Ordered assistant (`.other`) messages belonging to this turn.
  public var assistantMessages: [MessageType]

  /// All messages in this turn in chronological order (`userMessage` followed by `assistantMessages`).
  public var allMessages: [MessageType] {
    var result: [MessageType] = []
    result.reserveCapacity((userMessage != nil ? 1 : 0) + assistantMessages.count)
    if let userMessage {
      result.append(userMessage)
    }
    result.append(contentsOf: assistantMessages)
    return result
  }

  /// Returns `true` if any message in this turn is currently streaming.
  public var isStreaming: Bool {
    if userMessage?.isStreaming == true {
      return true
    }
    return assistantMessages.contains(where: \.isStreaming)
  }

  /// Creates a `ConversationTurn`.
  public init(
    id: String? = nil,
    userMessage: MessageType? = nil,
    assistantMessages: [MessageType] = []
  ) {
    self.id = id ?? userMessage?.id ?? assistantMessages.first?.id ?? UUID().uuidString
    self.userMessage = userMessage
    self.assistantMessages = assistantMessages
  }

  /// Deterministically partitions a flat sequence of messages into ordered `ConversationTurn` units (`§3.4.1`).
  ///
  /// - Every `.user` message starts a new `ConversationTurn` with `id == userMessage.id`.
  /// - Subsequent `.other` messages are appended to the current turn's `assistantMessages` until the next `.user` message.
  /// - Leading `.other` messages before the first `.user` message are grouped into an initial turn with `userMessage == nil`.
  public static func group(_ messages: [MessageType]) -> [ConversationTurn<MessageType>] {
    guard !messages.isEmpty else { return [] }

    var turns: [ConversationTurn<MessageType>] = []
    turns.reserveCapacity(max(1, messages.count / 2))

    for message in messages {
      switch message.participant {
      case .user:
        turns.append(
          ConversationTurn(
            id: message.id,
            userMessage: message,
            assistantMessages: []
          )
        )
      case .other:
        if !turns.isEmpty {
          turns[turns.count - 1].assistantMessages.append(message)
        } else {
          turns.append(
            ConversationTurn(
              id: message.id,
              userMessage: nil,
              assistantMessages: [message]
            )
          )
        }
      }
    }

    return turns
  }
}
