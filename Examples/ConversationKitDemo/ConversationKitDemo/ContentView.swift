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
import SwiftUI

struct ContentView: View {
  @State private var messages: [DefaultMessage] = []
  @State private var attachments: [ConversationAttachment] = []
  @State private var tokens: [ComposerToken] = []

  @State private var selectedModel: ComposerModelOption? = DemoSampleData.availableModels.first
  @State private var activeCapabilities: Set<ComposerCapability> = [.think, .search]
  @State private var composerStyleOption: DemoComposerStyleOption = {
    if ProcessInfo.processInfo.arguments.contains("-cardGlass") {
      return .cardGlass
    }
    if ProcessInfo.processInfo.arguments.contains("-compactGlass") {
      return .compactGlass
    }
    return .classicGlass
  }()
  @State private var thinkingStyleOption: DemoThinkingStyleOption = .collapsibleHeader
  @State private var bubbleStyleOption: DemoBubbleStyleOption = .tailedBubble
  @State private var streamingHapticsOption: DemoStreamingHapticsOption = .punchy

  private var initialUserPrompt: String {
    if let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-prompt"),
       idx + 1 < ProcessInfo.processInfo.arguments.count {
      return ProcessInfo.processInfo.arguments[idx + 1]
    }
    return ""
  }

  var body: some View {
    NavigationStack {
      ConversationView(messages: $messages, attachments: $attachments, userPrompt: initialUserPrompt)
        .onSendMessage { submission in
          await handleSubmission(submission)
        }
        .suggestionChips(DemoSampleData.suggestions(for: messages))
        .slashCommands(DemoSampleData.availableCommands)
        .resourceMentions(DemoSampleData.availableMentions)
        .composerModels(DemoSampleData.availableModels, selection: $selectedModel)
        .composerCapabilities([.think, .search, .image], active: $activeCapabilities)
        .composerTokens($tokens)
        .messageComposerStyle(composerStyleOption.anyStyle)
        .thinkingStateStyle(thinkingStyleOption.anyStyle)
        .userMessageBubbleStyle(bubbleStyleOption.anyStyle)
        .streamingHaptics(streamingHapticsOption.configuration)
        .emptyConversationView {
          emptyPlaceholder
        }
        .attachmentActions {
          Button("Sample Diagram Image", systemImage: "photo") {
            if let imageAttachment = DemoSampleData.makeSampleImageAttachment() {
              attachments.append(imageAttachment)
            }
          }
          Button("Sample Architecture PDF", systemImage: "doc.richtext") {
            attachments.append(DemoSampleData.makeSamplePDFAttachment())
          }
          Button("Sample Swift Source File", systemImage: "chevron.left.forwardslash.chevron.right") {
            attachments.append(DemoSampleData.makeSampleSwiftAttachment())
          }
          Button("Simulate Uploading Attachment", systemImage: "arrow.up.doc") {
            attachSimulatedUploadingFile()
          }
        }
        .messageActions { message in
          if let content = message.content, !content.isEmpty {
            ShareLink(item: content) {
              Label("Share", systemImage: "square.and.arrow.up")
            }
            .labelStyle(.iconOnly)
          }
        }
        .onApprovalDecision { request, decision in
          resolveApproval(request: request, decision: decision)
        }
        .onToolCallRetry { failedToolCall in
          await retryToolCall(failedToolCall)
        }
        .onMessageFeedback { messageID, feedback in
          if let index = messages.firstIndex(where: { $0.id == messageID }) {
            messages[index].feedback = feedback
          }
        }
        .onRegenerateMessage { messageID in
          await regenerateMessage(id: messageID)
        }
        .onRetryMessage { messageID in
          await regenerateMessage(id: messageID)
        }
        .conversationDisclaimer("Simulated responses for demonstration purposes.")
        .navigationTitle("ConversationKit")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
          ToolbarItemGroup(placement: .primaryAction) {
            styleAndSamplesMenu
            clearConversationButton
          }
        }
    }
  }

  private var emptyPlaceholder: some View {
    VStack(spacing: 14) {
      Image(systemName: "bubble.left.and.text.bubble.right")
        .font(.system(size: 40, weight: .semibold))
        .foregroundStyle(.tint)
        .padding(16)
        .background(Color.accentColor.opacity(0.12), in: Circle())

      Text("What would you like to explore?")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)

      Text("Pick a suggestion below, or type / for commands and @ to mention files.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 420)
    }
    .padding(.vertical, 24)
  }

  private var styleAndSamplesMenu: some View {
    Menu {
      Section("Composer Style") {
        Picker("Composer Style", selection: $composerStyleOption) {
          ForEach(DemoComposerStyleOption.allCases) { option in
            Label(option.rawValue, systemImage: option.symbolName).tag(option)
          }
        }
      }
      Section("Thinking Style") {
        Picker("Thinking Style", selection: $thinkingStyleOption) {
          ForEach(DemoThinkingStyleOption.allCases) { option in
            Text(option.rawValue).tag(option)
          }
        }
      }
      Section("User Bubble Style") {
        Picker("User Bubble Style", selection: $bubbleStyleOption) {
          ForEach(DemoBubbleStyleOption.allCases) { option in
            Text(option.rawValue).tag(option)
          }
        }
      }
      Section("Streaming Haptics") {
        Picker("Streaming Haptics", selection: $streamingHapticsOption) {
          ForEach(DemoStreamingHapticsOption.allCases) { option in
            Label(option.rawValue, systemImage: option.symbolName).tag(option)
          }
        }
      }
      Section("Sample Attachments") {
        Button("Attach Sample Image", systemImage: "photo") {
          if let imageAttachment = DemoSampleData.makeSampleImageAttachment() {
            attachments.append(imageAttachment)
          }
        }
        Button("Attach Sample PDF", systemImage: "doc.richtext") {
          attachments.append(DemoSampleData.makeSamplePDFAttachment())
        }
        Button("Attach Sample Swift Code", systemImage: "chevron.left.forwardslash.chevron.right") {
          attachments.append(DemoSampleData.makeSampleSwiftAttachment())
        }
        Button("Simulate Upload Progress Ring", systemImage: "clock.arrow.2.circlepath") {
          attachSimulatedUploadingFile()
        }
      }
    } label: {
      Label("Composer Style", systemImage: "slider.horizontal.3")
    }
    .accessibilityIdentifier("attachSampleButton")
  }

  private var clearConversationButton: some View {
    Button {
      withAnimation(.snappy(duration: 0.25)) {
        messages.removeAll()
        attachments.removeAll()
        tokens.removeAll()
      }
    } label: {
      Label("New Chat", systemImage: "square.and.pencil")
    }
    .accessibilityIdentifier("clearConversationButton")
  }

  private func attachSimulatedUploadingFile() {
    let id = UUID().uuidString
    attachments.append(DemoSampleData.makeUploadingPDFAttachment(id: id))
    Task { @MainActor in
      for step in 2...10 {
        try? await Task.sleep(for: .milliseconds(180))
        guard let index = attachments.firstIndex(where: { $0.id == id }) else { return }
        attachments[index].uploadState = step < 10 ? .uploading(progress: Double(step) / 10.0) : .ready
      }
    }
  }

  @MainActor
  private func handleSubmission(_ submission: ConversationSubmission<DefaultMessage>) async {
    messages.append(submission.message)

    let turnCount = messages.filter { $0.participant == .user }.count
    let topic = DemoResponseTopic.resolve(
      from: submission.text,
      commandTrigger: submission.command?.trigger,
      hasAttachments: !submission.attachments.isEmpty,
      turnCount: turnCount
    )
    let hasTools = topic == .agenticTools
      || submission.command?.trigger == "code"
      || submission.command?.trigger == "benchmark"

    let responseID = UUID().uuidString
    let startedAt = Date.now
    var assistantMessage = DefaultMessage(
      id: responseID,
      content: nil,
      participant: .other,
      selectedModelID: submission.selectedModel?.id,
      thinkingTrace: DemoSampleData.makeInitialThinkingTrace(for: topic, startedAt: startedAt),
      toolCalls: hasTools ? DemoSampleData.makeInitialToolCalls(responseID: responseID, startedAt: startedAt) : [],
      isStreaming: true
    )
    messages.append(assistantMessage)

    do {
      try await Task.sleep(for: .milliseconds(320))
      try Task.checkCancellation()

      assistantMessage.thinkingTrace = DemoSampleData.makeCompletedThinkingTrace(
        id: assistantMessage.thinkingTrace?.id ?? UUID().uuidString,
        for: topic
      )
      if hasTools {
        assistantMessage.toolCalls = DemoSampleData.makeCompletedToolCalls(responseID: responseID)
        assistantMessage.plan = DemoSampleData.makeAgentPlan()
        assistantMessage.approvalRequest = DemoSampleData.makeApprovalRequest()
      }
      updateMessage(assistantMessage)

      let fullMarkdown = DemoSampleData.buildResponseMarkdown(
        for: submission,
        topic: topic,
        turnCount: turnCount
      )
      var accumulated = ""
      let characters = Array(fullMarkdown)
      for chunkStart in stride(from: 0, to: characters.count, by: 18) {
        try Task.checkCancellation()
        let chunkEnd = min(chunkStart + 18, characters.count)
        accumulated.append(contentsOf: characters[chunkStart..<chunkEnd])
        assistantMessage.content = accumulated
        updateMessage(assistantMessage)
        try await Task.sleep(for: .milliseconds(28))
      }

      assistantMessage.isStreaming = false
      assistantMessage.citations = DemoSampleData.makeCitations(for: topic)
      updateMessage(assistantMessage)
    } catch is CancellationError {
      assistantMessage.isStreaming = false
      if case .thinking = assistantMessage.thinkingTrace?.status {
        assistantMessage.thinkingTrace?.status = .cancelled(
          duration: max(0.1, Date.now.timeIntervalSince(startedAt))
        )
      }
      updateMessage(assistantMessage)
    } catch {
      assistantMessage.isStreaming = false
      assistantMessage.messageError = MessageError(message: error.localizedDescription, isRetryable: true)
      updateMessage(assistantMessage)
    }
  }

  private func updateMessage(_ updated: DefaultMessage) {
    if let index = messages.firstIndex(where: { $0.id == updated.id }) {
      messages[index] = updated
    }
  }

  private func resolveApproval(request: ApprovalRequest, decision: ApprovalRequest.Decision) {
    guard let index = messages.firstIndex(where: { $0.approvalRequest?.id == request.id }) else { return }
    messages[index].approvalRequest?.decision = decision
    if (decision == .allowOnce || decision == .alwaysAllow),
       var plan = messages[index].plan, !plan.steps.isEmpty {
      plan.steps[plan.steps.count - 1].status = .completed
      messages[index].plan = plan
    }
  }

  private func retryToolCall(_ failedCall: ToolCall) async {
    guard let msgIndex = messages.firstIndex(where: { $0.toolCalls.contains(where: { $0.id == failedCall.id }) }),
          let toolIndex = messages[msgIndex].toolCalls.firstIndex(where: { $0.id == failedCall.id })
    else { return }
    messages[msgIndex].toolCalls[toolIndex].status = .running(startedAt: .now)
    try? await Task.sleep(for: .milliseconds(350))
    messages[msgIndex].toolCalls[toolIndex].status = .succeeded(duration: 0.35)
  }

  private func regenerateMessage(id messageID: String) async {
    guard let index = messages.firstIndex(where: { $0.id == messageID }) else { return }
    messages[index].messageError = nil
    messages[index].isStreaming = true
    try? await Task.sleep(for: .milliseconds(250))
    messages[index].isStreaming = false
  }
}

#Preview {
  ContentView()
}
