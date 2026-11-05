//
//  A2UIChatMessage.swift
//  A2UIConversationDemo
//
//  Custom ConversationKit Message model carrying embedded A2UI surface IDs,
//  raw A2UI JSON envelopes, and agentic timeline metadata.
//

import ConversationKit
import Foundation

// MARK: - A2UIChatMessage

/// A conversational timeline message that can embed one or more live interactive A2UI surfaces
/// alongside `ConversationKit` v2's streaming Markdown and agentic primitives.
public struct A2UIChatMessage: Message, Identifiable, Hashable, Sendable {
  public let id: String
  public var content: String?
  public var participant: Participant
  public var createdAt: Date
  public var isStreaming: Bool
  public var attachments: [ConversationAttachment]
  public var tokens: [ComposerToken]
  public var selectedModelID: String?
  public var thinkingTrace: ThinkingTrace?
  public var toolCalls: [ToolCall]
  public var citations: [Citation]
  public var plan: AgentPlan?
  public var approvalRequest: ApprovalRequest?
  public var feedback: MessageFeedback?
  public var messageError: MessageError?

  /// Ordered list of A2UI `surfaceId` values rendered inline inside this turn.
  public var surfaceIDs: [String]

  /// Raw A2UI JSON messages processed for this turn (for live inspection).
  public var rawA2UIMessages: [String]

  /// Optional badge text when a user turn was synthesized from an A2UI surface interaction.
  public var actionBadge: String?

  public init(
    id: String = UUID().uuidString,
    content: String? = nil,
    participant: Participant = .user,
    createdAt: Date = .now,
    isStreaming: Bool = false,
    attachments: [ConversationAttachment] = [],
    tokens: [ComposerToken] = [],
    selectedModelID: String? = nil,
    thinkingTrace: ThinkingTrace? = nil,
    toolCalls: [ToolCall] = [],
    citations: [Citation] = [],
    plan: AgentPlan? = nil,
    approvalRequest: ApprovalRequest? = nil,
    feedback: MessageFeedback? = nil,
    messageError: MessageError? = nil,
    surfaceIDs: [String] = [],
    rawA2UIMessages: [String] = [],
    actionBadge: String? = nil
  ) {
    self.id = id
    self.content = content
    self.participant = participant
    self.createdAt = createdAt
    self.isStreaming = isStreaming
    self.attachments = attachments
    self.tokens = tokens
    self.selectedModelID = selectedModelID
    self.thinkingTrace = thinkingTrace
    self.toolCalls = toolCalls
    self.citations = citations
    self.plan = plan
    self.approvalRequest = approvalRequest
    self.feedback = feedback
    self.messageError = messageError
    self.surfaceIDs = surfaceIDs
    self.rawA2UIMessages = rawA2UIMessages
    self.actionBadge = actionBadge
  }

  public static func makeUserMessage(
    id: String,
    content: String?,
    attachments: [ConversationAttachment],
    tokens: [ComposerToken],
    selectedModelID: String?
  ) -> A2UIChatMessage {
    A2UIChatMessage(
      id: id,
      content: content,
      participant: .user,
      createdAt: .now,
      isStreaming: false,
      attachments: attachments,
      tokens: tokens,
      selectedModelID: selectedModelID
    )
  }
}

// MARK: - A2UIEventLog

/// Diagnostic log entry recorded when an A2UI surface dispatches an action or validation event.
public struct A2UIEventLog: Identifiable, Hashable, Sendable {
  public enum Kind: String, Sendable {
    case action = "Action"
    case surface = "Surface"
    case error = "Error"
  }

  public let id = UUID()
  public let timestamp = Date()
  public let kind: Kind
  public let surfaceID: String
  public let summary: String
  public let payloadJSON: String?
}

// MARK: - Demo Presets & Composer Configuration

public enum A2UIDemoPresets {
  /// Model options exposed in ConversationKit's Liquid Glass model selector pill.
  public static let availableModels: [ComposerModelOption] = [
    ComposerModelOption(
      id: "gemini-3-flash-preview",
      name: "Gemini 3 Flash",
      subtitle: "Firebase AI Logic · Frontier speed & A2UI generation",
      badge: "Default",
      symbolName: "bolt.fill",
      category: "Firebase AI Logic"
    ),
    ComposerModelOption(
      id: "gemini-3.1-pro-preview",
      name: "Gemini 3.1 Pro",
      subtitle: "Firebase AI Logic · Deep agentic UI synthesis",
      badge: "Pro",
      symbolName: "wand.and.stars",
      category: "Firebase AI Logic"
    ),
    ComposerModelOption(
      id: "gemini-3.1-flash-lite-preview",
      name: "Gemini 3.1 Flash Lite",
      subtitle: "Firebase AI Logic · Ultra-low latency UI streaming",
      badge: "Lite",
      symbolName: "hare.fill",
      category: "Firebase AI Logic"
    ),
    ComposerModelOption(
      id: "a2a-local-agent",
      name: "Local A2UI Agent (A2A)",
      subtitle: "http://localhost:10002/a2a/json-rpc (Node / Python ADK)",
      badge: "A2A",
      symbolName: "network",
      category: "Local Agent Server"
    ),
  ]

  /// Slash commands available in the composer when typing `/`.
  public static let slashCommands: [SlashCommand] = [
    SlashCommand(
      id: "coffee",
      trigger: "coffee",
      title: "Coffee Order Card",
      description: "Render an interactive coffee order card with live item templating",
      symbolName: "cup.and.saucer.fill",
      category: "A2UI Surfaces"
    ),
    SlashCommand(
      id: "restaurants",
      trigger: "restaurants",
      title: "Find NYC Restaurants",
      description: "Query restaurants and render interactive booking cards",
      symbolName: "fork.knife",
      category: "A2UI Surfaces"
    ),
    SlashCommand(
      id: "invitation",
      trigger: "invitation",
      title: "Live Invitation Builder",
      description: "Two-way reactive form bound to a live preview card",
      symbolName: "envelope.open.fill",
      category: "A2UI Surfaces"
    ),
    SlashCommand(
      id: "dashboard",
      trigger: "dashboard",
      title: "Incremental Dashboard",
      description: "Stream a multi-stage system dashboard with progressive updates",
      symbolName: "gauge.with.dots.needle.67percent",
      category: "Streaming"
    ),
    SlashCommand(
      id: "workout",
      trigger: "workout",
      title: "Workout Summary",
      description: "Render a fitness activity summary card with metrics",
      symbolName: "figure.run",
      category: "A2UI Surfaces"
    ),
    SlashCommand(
      id: "music",
      trigger: "music",
      title: "Music Player Surface",
      description: "Render an A2UI media card with playback controls",
      symbolName: "music.note.list",
      category: "A2UI Surfaces"
    ),
  ]

  /// Starter suggestion chips displayed above the Liquid Glass composer.
  public static let starterSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "suggest-coffee",
      title: "Order Sunrise Coffee",
      prompt: "Build me an interactive coffee order card for Sunrise Coffee with an Oat Milk Latte and a Warmed Chocolate Croissant.",
      symbolName: "cup.and.saucer",
      category: "Interactive Order"
    ),
    PromptSuggestion(
      id: "suggest-restaurants",
      title: "Top NYC Restaurants",
      prompt: "Show me the top Chinese restaurants in New York with an interactive booking button.",
      symbolName: "fork.knife",
      category: "A2A & Gemini 3"
    ),
    PromptSuggestion(
      id: "suggest-invitation",
      title: "Live Invitation Builder",
      prompt: "/invitation Customize a Summer Gala invitation with live two-way data binding.",
      symbolName: "sparkles",
      category: "Two-Way Binding"
    ),
    PromptSuggestion(
      id: "suggest-custom-trip",
      title: "Tokyo Flight & Hotel Planner",
      prompt: "Design an interactive Tokyo trip customizer card with a cabin class picker, budget slider, travel date input, and a Book Trip button.",
      symbolName: "airplane",
      category: "Generative A2UI"
    ),
  ]

  /// Follow-up suggestion chips after a turn completes.
  public static let followUpSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
      id: "followup-custom-form",
      title: "Conference Registration Form",
      prompt: "Create an interactive conference registration surface with Name, Email, Workshop track picker, dietary notes, and a Register button.",
      symbolName: "person.badge.plus",
      category: "Generative A2UI"
    ),
    PromptSuggestion(
      id: "followup-dashboard",
      title: "Stream Incremental Dashboard",
      prompt: "/dashboard Stream an incremental analytics and logs dashboard.",
      symbolName: "chart.bar.xaxis",
      category: "Streaming"
    ),
    PromptSuggestion(
      id: "followup-workout",
      title: "Workout Summary Card",
      prompt: "/workout Show my morning trail run workout summary card.",
      symbolName: "figure.run",
      category: "Catalog"
    ),
    PromptSuggestion(
      id: "followup-coffee",
      title: "Coffee Order Card",
      prompt: "/coffee Show my Sunrise Coffee cart.",
      symbolName: "cup.and.saucer",
      category: "Catalog"
    ),
  ]
}
