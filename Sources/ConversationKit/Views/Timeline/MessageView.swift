//
//  MessageView.swift
//  ConversationKit
//
//  Asymmetric participant message router: right-aligned UserMessageBubbleStyle for .user
//  prompts vs. full-width background canvas for .other (assistant) responses with
//  agentic primitives, multimodal collage/document cards, inline error retry, and action bar
//  (F-3, F-4, F-7, AC-5, AC-6, AC-10, AC-11, AC-18).
//

import Foundation
import QuickLook
import SwiftUI

// MARK: - Accessibility Identifier Extensions

extension ConversationAccessibilityID {
  /// Accessibility identifier for a failed message's inline Retry button (`message.retry.<id>`).
  public static func messageRetryButton(_ id: String) -> String {
    "message.retry.\(id)"
  }

  /// Accessibility identifier for a message's attachments grid (`message.attachments.<id>`).
  public static func messageAttachmentsGrid(_ id: String) -> String {
    "message.attachments.\(id)"
  }
}

// MARK: - MessageView (`F-3`, `F-4`, `F-7`, `AC-5`, `AC-6`, `AC-10`, `AC-11`, `AC-18`)

/// Asymmetric timeline cell view rendering a single `Message` (`F-3`, `AC-5`, `AC-10`).
///
/// - **User (`.user`) Messages:** Right-aligned with a minimum `48pt` leading margin, delegating
///   bubble chrome to `@Environment(\.userMessageBubbleStyle)` (`TailedBubbleUserMessageStyle` by default).
/// - **Assistant (`.other`) Messages:** Left-aligned and full-width **directly on the background canvas
///   with no enclosing bubble (`F-3`, `AC-5`)**, orchestrating `ThinkingStateView` (collapsed by default),
///   `ToolCallsGroupView`, `AgentPlanView`, `AgentApprovalView`, `MessageAttachmentsGridView`,
///   `StreamingMarkdownView`, inline error/retry cards, `SourceStackView`, and `MessageActionBarView`.
/// - **Zero Liquid Glass in Scrolling Cells (`AC-10`):** Never applies Liquid Glass modifiers inside timeline rows.
@MainActor
public struct MessageView<MessageType: Message>: View {
  /// The message model to render.
  public let message: MessageType

  @Environment(\.userMessageBubbleStyle) private var userMessageBubbleStyle
  @Environment(\.messageActions) private var customMessageActions
  @Environment(\.onRetryMessage) private var onRetryMessage
  @Environment(\.onRegenerateMessage) private var onRegenerateMessage
  @Environment(\.streamingHaptics) private var streamingHaptics
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var didTriggerFirstTokenMilestone: Bool = false

  /// Creates a `MessageView` for the given `Message`.
  public init(message: MessageType) {
    self.message = message
  }

  public var body: some View {
    VStack(alignment: message.participant == .user ? .trailing : .leading, spacing: 0) {
      switch message.participant {
      case .user:
        userMessageBranch

      case .other:
        assistantMessageBranch
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(
      message.participant == .user
        ? ConversationAccessibilityID.userMessage(message.id)
        : ConversationAccessibilityID.assistantMessage(message.id)
    )
  }

  // MARK: - `.user` Branch (Right-Aligned Stylable Bubble)

  private var userMessageBranch: some View {
    let trimmedText = (message.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let hasText = !trimmedText.isEmpty
    let hasAttachments = !message.attachments.isEmpty
    let hasTokens = !message.tokens.isEmpty

    let configuration = UserMessageBubbleStyleConfiguration(
      content: AnyView(
        Text(message.content ?? "")
          .font(.body)
          .textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true)
      ),
      attachmentsContent: hasAttachments
        ? AnyView(
          MessageAttachmentsGridView(
            attachments: message.attachments,
            messageID: message.id,
            alignment: .trailing
          )
        )
        : nil,
      tokensContent: hasTokens
        ? AnyView(UserMessageTokensRowView(tokens: message.tokens))
        : nil,
      hasText: hasText,
      hasAttachments: hasAttachments,
      hasTokens: hasTokens
    )

    return HStack(alignment: .bottom, spacing: 0) {
      Spacer(minLength: 48)

      VStack(alignment: .trailing, spacing: 6) {
        userMessageBubbleStyle.makeBody(configuration: configuration)

        if hasError {
          inlineErrorCard
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }

  // MARK: - `.other` Branch (Full-Width AI Canvas with NO Bubble, `F-3`, `AC-5`)

  private var hasNonEmptyText: Bool {
    !(message.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var assistantMessageBranch: some View {
    let textContent = message.content ?? ""
    let hasNonEmptyText = self.hasNonEmptyText

    return VStack(alignment: .leading, spacing: 12) {
      // 1. Reasoning trace (collapsed by default per F-7 & AC-11)
      if let thinkingTrace = message.thinkingTrace {
        ThinkingStateView(trace: thinkingTrace)
      }

      // 2. Agentic tool execution group
      if !message.toolCalls.isEmpty {
        ToolCallsGroupView(
          toolCalls: message.toolCalls,
          messageID: message.id
        )
      }

      // 3. Step-by-step execution plan
      if let plan = message.plan {
        AgentPlanView(plan: plan)
      }

      // 4. Human-in-the-loop approval request card
      if let approval = message.approvalRequest {
        AgentApprovalView(request: approval)
      }

      // 5. Multimodal attachments grid / document cards
      if !message.attachments.isEmpty {
        MessageAttachmentsGridView(
          attachments: message.attachments,
          messageID: message.id,
          alignment: .leading
        )
      }

      // 6. Incremental block-committed Markdown or initial breathing indicator
      if hasNonEmptyText {
        StreamingMarkdownView(
          markdown: textContent,
          isStreaming: message.isStreaming
        )
      } else if shouldShowInitialBreathingIndicator {
        AssistantBreathingIndicatorView(reduceMotion: reduceMotion)
      }

      // 7. Inline error card with Retry button
      if hasError {
        inlineErrorCard
      }

      // 8. Source citations stack (http/https allowlisted)
      if !message.citations.isEmpty {
        SourceStackView(
          citations: message.citations,
          messageID: message.id
        )
      }

      // 9. Action bar (shown when settled, error-free, and non-empty)
      if !message.isStreaming && !hasError && hasNonEmptyText {
        if let customMessageActions {
          HStack(alignment: .center, spacing: 12) {
            MessageActionBarView(
              messageID: message.id,
              content: textContent,
              feedback: message.feedback
            )
            customMessageActions(message)
          }
        } else {
          MessageActionBarView(
            messageID: message.id,
            content: textContent,
            feedback: message.feedback
          )
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onChange(of: hasNonEmptyText) { oldValue, newValue in
      if !oldValue && newValue && !didTriggerFirstTokenMilestone {
        didTriggerFirstTokenMilestone = true
        if message.isStreaming && !reduceMotion && streamingHaptics.triggersMilestones {
          _ = PlatformHaptics.triggerStreamingMilestone(
            configuration: streamingHaptics,
            isCompletion: false
          )
        }
      }
    }
    .onChange(of: message.thinkingTrace?.status) { oldStatus, newStatus in
      if case .thinking = oldStatus, case .completed = newStatus {
        if message.isStreaming && !reduceMotion && streamingHaptics.triggersMilestones {
          _ = PlatformHaptics.triggerStreamingMilestone(
            configuration: streamingHaptics,
            isCompletion: false
          )
        }
      }
    }
    .onChange(of: message.isStreaming) { wasStreaming, isNowStreaming in
      if wasStreaming && !isNowStreaming {
        didTriggerFirstTokenMilestone = false
        if !hasError && !reduceMotion && streamingHaptics.triggersMilestones {
          _ = PlatformHaptics.triggerStreamingMilestone(
            configuration: streamingHaptics,
            isCompletion: true
          )
        }
      }
    }
  }

  // MARK: - Error & Breathing State Helpers

  private var hasError: Bool {
    message.messageError != nil || message.error != nil
  }

  private var resolvedErrorText: String {
    if let messageError = message.messageError {
      return messageError.message
    }
    if let err = message.error {
      return err.localizedDescription
    }
    return "An unexpected error occurred."
  }

  private var isErrorRetryable: Bool {
    message.messageError?.isRetryable ?? true
  }

  private var shouldShowInitialBreathingIndicator: Bool {
    let hasNoText = (message.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let hasNoAgenticBlocks =
      message.thinkingTrace == nil
      && message.toolCalls.isEmpty
      && message.plan == nil
      && message.approvalRequest == nil
      && message.attachments.isEmpty
    return hasNoText && hasNoAgenticBlocks && !hasError
  }

  private var inlineErrorCard: some View {
    HStack(alignment: .center, spacing: 10) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.red)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(resolvedErrorText)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.primary)
          .fixedSize(horizontal: false, vertical: true)

        if let detail = message.messageError?.detail,
          !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
          Text(detail)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer(minLength: 8)

      if isErrorRetryable {
        Button {
          PlatformHapticEvent.triggerHaptic(.selection)
          let targetID = message.id
          if let onRetryMessage {
            Task { @MainActor in
              await onRetryMessage(targetID)
            }
          } else if let onRegenerateMessage {
            Task { @MainActor in
              await onRegenerateMessage(targetID)
            }
          }
        } label: {
          Label("Retry", systemImage: "arrow.clockwise")
            .font(.caption.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(.red)
        .accessibilityIdentifier(ConversationAccessibilityID.messageRetryButton(message.id))
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      Color.red.opacity(0.08),
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Color.red.opacity(0.32), lineWidth: 0.75)
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(ConversationAccessibilityID.messageErrorBanner(message.id))
  }
}

// MARK: - UserMessageTokensRowView

/// Displays committed `/command` and `@mention` token chips inside a sent user message bubble.
private struct UserMessageTokensRowView: View {
  let tokens: [ComposerToken]

  var body: some View {
    HStack(spacing: 6) {
      ForEach(tokens) { token in
        HStack(spacing: 4) {
          Image(systemName: token.symbolName)
            .font(.system(size: 10, weight: .semibold))

          Text(token.displayText)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
        }
        .foregroundStyle(tokenTintColor(for: token))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
          tokenTintColor(for: token).opacity(0.14),
          in: Capsule()
        )
        .overlay {
          Capsule()
            .strokeBorder(tokenTintColor(for: token).opacity(0.30), lineWidth: 0.5)
        }
      }
    }
  }

  private func tokenTintColor(for token: ComposerToken) -> Color {
    switch token.kind {
    case .command:
      return .accentColor
    case .mention:
      return .indigo
    }
  }
}

// MARK: - AssistantBreathingIndicatorView

/// Subtle pulsing indicator shown when an assistant message has started streaming (`content == nil` or `""`)
/// before the first reasoning block, tool call, or Markdown token arrives.
private struct AssistantBreathingIndicatorView: View {
  let reduceMotion: Bool

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "sparkles")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.tint)
        .symbolEffect(
          .pulse.byLayer,
          options: .repeating,
          isActive: !reduceMotion
        )

      Text("Thinking…")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Assistant is thinking")
  }
}

// MARK: - MessageAttachmentsGridView (`F-4`, `AC-6`)

/// Renders sent multimodal attachments inside a message row:
/// - **Image Collage (`1–4` photos):** Displays up to 4 downsampled thumbnails (`maxPixelSize: 320`)
///   with a `+N` overflow badge on the 4th tile when more than 4 images are attached.
/// - **Document Cards (`PDF`, `audio`, `video`, `code`, `document`):** Displays structured file chips
///   with extension badges, formatted byte sizes, and off-main-actor PDF/file thumbnails.
/// - **Native QuickLook Preview:** Tapping any image or document card resolves a sanitized local `URL`
///   via `attachment.resolveQuickLookURL()` and presents `.quickLookPreview`.
@MainActor
public struct MessageAttachmentsGridView: View {
  public let attachments: [ConversationAttachment]
  public let messageID: String
  public let alignment: HorizontalAlignment

  @State private var quickLookURL: URL?

  public init(
    attachments: [ConversationAttachment],
    messageID: String = "",
    alignment: HorizontalAlignment = .leading
  ) {
    self.attachments = attachments
    self.messageID = messageID
    self.alignment = alignment
  }

  private var imageAttachments: [ConversationAttachment] {
    attachments.filter { $0.kind == .image }
  }

  private var documentAttachments: [ConversationAttachment] {
    attachments.filter { $0.kind != .image }
  }

  public var body: some View {
    VStack(alignment: alignment, spacing: 8) {
      if !imageAttachments.isEmpty {
        imageCollageGrid
      }

      if !documentAttachments.isEmpty {
        VStack(alignment: alignment, spacing: 6) {
          ForEach(documentAttachments) { doc in
            SentDocumentAttachmentCard(attachment: doc) {
              openQuickLook(for: doc)
            }
          }
        }
      }
    }
    .quickLookPreview($quickLookURL)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(
      ConversationAccessibilityID.messageAttachmentsGrid(
        messageID.isEmpty ? (attachments.first?.id ?? "default") : messageID
      )
    )
  }

  // MARK: - Multi-Photo Collage (Up to 4 Thumbnails + `+N` Overflow Badge)

  @ViewBuilder
  private var imageCollageGrid: some View {
    let visibleImages = Array(imageAttachments.prefix(4))
    let overflowCount = max(0, imageAttachments.count - 4)

    switch visibleImages.count {
    case 1:
      SentImageCollageTile(
        attachment: visibleImages[0],
        size: CGSize(width: 220, height: 168),
        overflowCount: 0
      ) {
        openQuickLook(for: visibleImages[0])
      }

    case 2:
      HStack(spacing: 6) {
        ForEach(visibleImages) { item in
          SentImageCollageTile(
            attachment: item,
            size: CGSize(width: 118, height: 118),
            overflowCount: 0
          ) {
            openQuickLook(for: item)
          }
        }
      }

    case 3:
      HStack(spacing: 6) {
        SentImageCollageTile(
          attachment: visibleImages[0],
          size: CGSize(width: 124, height: 162),
          overflowCount: 0
        ) {
          openQuickLook(for: visibleImages[0])
        }

        VStack(spacing: 6) {
          SentImageCollageTile(
            attachment: visibleImages[1],
            size: CGSize(width: 110, height: 78),
            overflowCount: 0
          ) {
            openQuickLook(for: visibleImages[1])
          }

          SentImageCollageTile(
            attachment: visibleImages[2],
            size: CGSize(width: 110, height: 78),
            overflowCount: 0
          ) {
            openQuickLook(for: visibleImages[2])
          }
        }
      }

    default:
      VStack(spacing: 6) {
        HStack(spacing: 6) {
          SentImageCollageTile(
            attachment: visibleImages[0],
            size: CGSize(width: 116, height: 96),
            overflowCount: 0
          ) {
            openQuickLook(for: visibleImages[0])
          }

          SentImageCollageTile(
            attachment: visibleImages[1],
            size: CGSize(width: 116, height: 96),
            overflowCount: 0
          ) {
            openQuickLook(for: visibleImages[1])
          }
        }

        HStack(spacing: 6) {
          SentImageCollageTile(
            attachment: visibleImages[2],
            size: CGSize(width: 116, height: 96),
            overflowCount: 0
          ) {
            openQuickLook(for: visibleImages[2])
          }

          SentImageCollageTile(
            attachment: visibleImages[3],
            size: CGSize(width: 116, height: 96),
            overflowCount: overflowCount
          ) {
            openQuickLook(for: visibleImages[3])
          }
        }
      }
    }
  }

  private func openQuickLook(for attachment: ConversationAttachment) {
    PlatformHapticEvent.triggerHaptic(.selection)
    Task { @MainActor in
      if let resolvedURL = try? await attachment.resolveQuickLookURL() {
        quickLookURL = resolvedURL
      }
    }
  }
}

// MARK: - SentImageCollageTile

private struct SentImageCollageTile: View {
  let attachment: ConversationAttachment
  let size: CGSize
  let overflowCount: Int
  let onTap: @MainActor () -> Void

  @State private var thumbnailBox: PlatformImageBox?

  var body: some View {
    Button(action: onTap) {
      ZStack {
        Color.platformTertiaryBackground

        if let thumbnailBox {
          thumbnailBox.swiftUIImage
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
        } else {
          Image(systemName: "photo")
            .font(.title3)
            .foregroundStyle(.secondary)
        }

        if overflowCount > 0 {
          Color.black.opacity(0.52)

          Text("+\(overflowCount)")
            .font(.title3.weight(.bold).monospacedDigit())
            .foregroundStyle(.white)
        }
      }
      .frame(width: size.width, height: size.height)
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      overflowCount > 0
        ? "\(attachment.filename), plus \(overflowCount) more images"
        : attachment.filename
    )
    .accessibilityHint("Double-tap to preview image with QuickLook")
    .task(id: attachment.id) {
      thumbnailBox = await attachment.generateThumbnail(maxPixelSize: 320)
    }
  }
}

// MARK: - SentDocumentAttachmentCard

private struct SentDocumentAttachmentCard: View {
  let attachment: ConversationAttachment
  let onTap: @MainActor () -> Void

  @State private var thumbnailBox: PlatformImageBox?

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 10) {
        ZStack {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(attachment.kind.accentColor.opacity(0.12))

          if let thumbnailBox {
            thumbnailBox.swiftUIImage
              .resizable()
              .scaledToFill()
              .frame(width: 38, height: 48)
              .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
          } else {
            Image(systemName: attachment.symbolName)
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(attachment.kind.accentColor)
          }
        }
        .frame(width: 38, height: 48)

        VStack(alignment: .leading, spacing: 3) {
          Text(attachment.filename)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .truncationMode(.middle)

          Text(attachment.formattedSubtitle)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer(minLength: 4)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .frame(minWidth: 180, maxWidth: 260)
      .background(
        Color.platformSecondaryBackground,
        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(attachment.filename), \(attachment.formattedSubtitle)")
    .accessibilityHint("Double-tap to preview document with QuickLook")
    .task(id: attachment.id) {
      thumbnailBox = await attachment.generateThumbnail(maxPixelSize: 320)
    }
  }
}

#Preview("MessageView - User & Assistant") {
  ScrollView {
    VStack(spacing: 24) {
      MessageView(
        message: DefaultMessage(
          id: "user-1",
          content: "Audit our v2 scroll physics and Liquid Glass placement rules.",
          participant: .user,
          tokens: [
            .command(SlashCommand(trigger: "audit", title: "Audit")),
            .mention(ResourceMention(queryHandle: "ADR-0001", title: "ADR-0001.md"))
          ]
        )
      )

      MessageView(
        message: DefaultMessage(
          id: "assistant-1",
          content: "All timeline cells use semantic fills and reserve **Liquid Glass** strictly for floating chrome inside `.safeAreaBar(edge: .bottom)`.",
          participant: .other,
          thinkingTrace: ThinkingTrace(
            status: .completed(duration: 3.4),
            summary: "Verified AC-2, AC-4, and AC-10 invariants",
            transcript: "Checked every file in Views/Timeline and Views/Agentic."
          ),
          citations: [
            Citation(
              index: 1,
              title: "Applying Liquid Glass to custom views",
              domain: "developer.apple.com",
              urlString: "https://developer.apple.com/documentation/SwiftUI"
            )
          ]
        )
      )
    }
    .padding()
  }
}
