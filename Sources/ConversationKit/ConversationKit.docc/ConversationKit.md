# ``ConversationKit``

A native SwiftUI conversational AI and agentic chat interface framework for iOS 26+, macCatalyst 26+, and macOS 26+.

## Overview

ConversationKit provides a cross-platform SwiftUI interface for building conversational AI assistants and multi-step agentic workflows. Every model, view, and style protocol is designed for strict Swift 6 concurrency compliance, 120Hz ProMotion streaming responsiveness, and native Apple platform ergonomics across iOS 26+, macCatalyst 26+, and macOS 26+.

### Progressive disclosure architecture

ConversationKit organizes its public surface around the 4-layer Stratos Progressive Disclosure model so you only adopt the complexity your app requires:

1. **Layer 1 (Troposphere):** Pass a binding to an array of ``DefaultMessage`` items into ``ConversationView`` and handle prompts with `onSendMessage(_:)`. ConversationKit manages attachment state, turn grouping, and timeline rendering automatically.
2. **Layer 2 (Stratosphere):** Configure first-turn ``PromptSuggestion`` chips, `/` ``SlashCommand`` and `@` ``ResourceMention`` autocomplete, ``ComposerModelOption`` and ``ComposerCapability`` selectors, adaptive ``StreamingHapticsConfiguration`` presets, and built-in style presets through declarative view modifiers.
3. **Layer 3 (Mesosphere):** Compose standalone timeline and composer components such as ``MessageComposerView``, ``StreamingMarkdownView``, ``ThinkingStateView``, ``ToolCallsGroupView``, ``SourceStackView``, ``AgentPlanView``, and ``AgentApprovalView`` directly in custom layouts.
4. **Layer 4 (Thermosphere):** Conform your own domain models to ``Message`` and implement custom ``MessageComposerStyle``, ``ThinkingStateStyle``, and ``UserMessageBubbleStyle`` types.

### Top-floating turn scroll physics

Instead of snapping a submitted message to the bottom of the screen or jumping during token generation, ``ConversationView`` partitions the flat message array into deterministic ``ConversationTurn`` values via ``ConversationTurn/group(_:)``. Each turn pairs a user prompt with its subsequent assistant responses.

When the user submits a prompt, ``ConversationView`` inserts an optimistic anchor in the same layout transaction, reserves an unoccluded viewport runway for the active turn, and scrolls the new turn to the top edge once. As the assistant streams tokens below, the user's prompt stays pinned at the top with zero vertical jitter until the response overflows downward.

### Liquid Glass composer chrome

``ConversationView`` hosts ``MessageComposerView`` inside a bottom safe area bar styled through ``MessageComposerStyle``. Built-in styles (``ClassicGlassMessageComposerStyle``, ``CardGlassMessageComposerStyle``, and ``CompactGlassMessageComposerStyle``) apply iOS 26+ and macOS 26+ Liquid Glass exclusively to floating chrome controls such as the composer bar, ``SuggestionChipsBar``, ``ComposerPopupView``, and ``ScrollToBottomButton``, while keeping scrolling timeline cells free of glass materials to maintain 120Hz scrolling performance.

### Agentic timeline primitives

Assistant turns natively render structured reasoning and tool execution metadata attached to any ``Message``:

- **Chain-of-thought reasoning:** ``ThinkingTrace`` and ``ThinkingStateView`` render collapsible reasoning transcripts (collapsed by default) with a leaf-scoped elapsed timer.
- **Tool execution groups:** ``ToolCall`` and ``ToolCallsGroupView`` display live status indicators, expandable JSON argument and result inspectors, and per-tool retry actions.
- **Grounded citations:** ``Citation`` and ``SourceStackView`` present domain badges and expandable source cards guarded by strict `http` and `https` URL allowlisting.
- **Execution plans and human-in-the-loop approvals:** ``AgentPlan`` (rendered by ``AgentPlanView``) tracks multi-step progress, while ``ApprovalRequest`` (rendered by ``AgentApprovalView``) presents risk-classified permission cards with interactive allow and deny actions.

### Adaptive streaming haptics

``ConversationView`` and ``StreamingMarkdownView`` provide adaptive haptic feedback synchronized with token arrival and agentic lifecycle milestones through ``StreamingHapticsConfiguration`` and ``PlatformHaptics``. By default, ``ConversationView`` uses the ``StreamingHapticsConfiguration/punchy`` preset for tactile token cadence and boundary accents. Customize the tactile profile with `.streamingHaptics(_:)` using built-in presets such as ``StreamingHapticsConfiguration/punchy``, ``StreamingHapticsConfiguration/typewriter``, ``StreamingHapticsConfiguration/subtle``, ``StreamingHapticsConfiguration/milestonesOnly``, or ``StreamingHapticsConfiguration/disabled``, or toggle haptics directly with `.streamingHapticsEnabled(_:)`.

```swift
import ConversationKit
import SwiftUI

struct AssistantChatView: View {
    @State private var messages: [DefaultMessage] = [
        DefaultMessage(
            content: "Hello! How can I help with your Swift package today?",
            participant: .other
        )
    ]

    var body: some View {
        NavigationStack {
            ConversationView(messages: $messages)
                .onSendMessage { (submission: ConversationSubmission<DefaultMessage>) in
                    messages.append(submission.message)

                    let replyID = UUID().uuidString
                    messages.append(
                        DefaultMessage(
                            id: replyID,
                            content: "Analyzing **\(submission.text)**...",
                            participant: .other,
                            thinkingTrace: ThinkingTrace(
                                status: .completed(duration: 1.4),
                                summary: "Inspected package targets",
                                transcript: "Checked Package.swift and public symbol exports."
                            ),
                            isStreaming: false
                        )
                    )
                }
                .messageComposerStyle(.cardGlass)
                .thinkingStateStyle(.collapsibleHeader)
                .userMessageBubbleStyle(.tailedBubble)
                .streamingHaptics(.punchy)
                .navigationTitle("Assistant")
        }
    }
}
```

## Topics

### Essentials

- ``ConversationView``
- ``Message``
- ``DefaultMessage``
- ``Participant``
- ``ConversationSubmission``
- ``ConversationTurn``

### Message Composer & Structured Prompting

- ``MessageComposerView``
- ``PromptSuggestion``
- ``PromptHandoffBehavior``
- ``SlashCommand``
- ``ResourceMention``
- ``ResourceMentionProvider``
- ``ComposerToken``
- ``ComposerModelOption``
- ``ComposerCapability``
- ``ComposerTextBuffer``
- ``SuggestionChipsBar``
- ``ComposerPopupView``
- ``ComposerPopupItem``
- ``AttachmentTrayView``
- ``AttachmentPreviewCard``
- ``ComposerTokensBar``
- ``ComposerModelSelectorMenu``

### Multimodal Attachments & Platform Abstractions

- ``ConversationAttachment``
- ``PlatformImage``
- ``PlatformImageBox``
- ``PlatformThumbnailGenerator``
- ``PlatformThumbnailError``
- ``PlatformPasteboard``
- ``StreamingHapticsConfiguration``
- ``PlatformHaptics``
- ``PlatformHapticEvent``

### Agentic Timeline Views & Models

- ``MessageView``
- ``MessageAttachmentsGridView``
- ``StreamingMarkdownView``
- ``MarkdownBlock``
- ``StreamingTailTextRenderer``
- ``ScrollToBottomButton``
- ``MessageActionBarView``
- ``ThinkingTrace``
- ``ThinkingStateView``
- ``ToolCall``
- ``ToolCallsGroupView``
- ``Citation``
- ``SourceStackView``
- ``AgentPlan``
- ``AgentPlanView``
- ``ApprovalRequest``
- ``AgentApprovalView``
- ``MessageFeedback``
- ``MessageError``

### Styling & Customization

- ``MessageComposerStyle``
- ``MessageComposerStyleConfiguration``
- ``ClassicGlassMessageComposerStyle``
- ``CardGlassMessageComposerStyle``
- ``CompactGlassMessageComposerStyle``
- ``AnyMessageComposerStyle``
- ``ThinkingStateStyle``
- ``ThinkingStateStyleConfiguration``
- ``CollapsibleHeaderThinkingStateStyle``
- ``PillThinkingStateStyle``
- ``MinimalThinkingStateStyle``
- ``AnyThinkingStateStyle``
- ``UserMessageBubbleStyle``
- ``UserMessageBubbleStyleConfiguration``
- ``TailedBubbleUserMessageStyle``
- ``RoundedCardUserMessageStyle``
- ``CapsuleUserMessageStyle``
- ``AnyUserMessageBubbleStyle``

### Environment & Actions

- ``ConversationAccessibilityID``
- ``AttachmentUploadAction``
- ``AttachmentRetryAction``
- ``ToolCallRetryAction``
- ``ApprovalDecisionAction``
- ``RegenerateMessageAction``
- ``MessageFeedbackAction``
- ``RetryMessageAction``
- ``AttachmentActionsBuilder``
- ``MessageActionsBuilder``
- ``EmptyConversationViewBuilder``
- ``ConversationDisclaimerBuilder``
- ``EnvironmentBindingBox``
