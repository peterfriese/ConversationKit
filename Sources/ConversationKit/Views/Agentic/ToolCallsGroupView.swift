//
//  ToolCallsGroupView.swift
//  ConversationKit
//
//  Collapsible agentic tool execution timeline with auto-expand/auto-fold state machine,
//  leaf-scoped 10Hz elapsed timers, expandable JSON inspector, and per-tool retry (AC-10, AC-18).
//

import Foundation
import SwiftUI

// MARK: - ToolCallsGroupView

/// Renders a collapsible group of agentic `ToolCall` invocations inside an assistant turn (`F-7`, `AC-10`, `AC-18`).
///
/// ### Auto-Expand & Auto-Fold Lifecycle
/// - Automatically expands (`isExpanded = true`) when any tool transitions to `.running`.
/// - Automatically folds (`isExpanded = false`) when all tools reach `.succeeded`, unless the user
///   manually toggled the group header or any tool is `.failed`.
/// - Uses semantic opaque/tinted backgrounds (`Color.platformSecondaryBackground`, `Color.platformTertiaryBackground`,
///   `Color.platformSeparator`) and never applies Liquid Glass inside scrolling cells (`AC-10`).
@MainActor
public struct ToolCallsGroupView: View {
  /// Ordered list of tool calls executed in this group.
  public let toolCalls: [ToolCall]

  /// Identifier of the parent message owning this tool call group.
  public let messageID: String

  /// Optional external binding for controlling group expansion state.
  private var externalIsExpanded: Binding<Bool>?

  @State private var internalIsExpanded: Bool
  @State private var hasUserManuallyToggled: Bool = false
  @State private var expandedToolRowIDs: Set<String> = []

  @Environment(\.onToolCallRetry) private var onToolCallRetry
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Creates a `ToolCallsGroupView`.
  ///
  /// - Parameters:
  ///   - toolCalls: Ordered collection of `ToolCall` items.
  ///   - messageID: Optional parent message ID used for accessibility identification.
  ///   - isExpanded: Optional external binding overriding internal auto-expand/auto-fold state.
  public init(
    toolCalls: [ToolCall],
    messageID: String = "",
    isExpanded: Binding<Bool>? = nil
  ) {
    self.toolCalls = toolCalls
    self.messageID = messageID
    self.externalIsExpanded = isExpanded
    self._internalIsExpanded = State(initialValue: Self.initialExpandedState(for: toolCalls))
  }

  private var isExpanded: Bool {
    externalIsExpanded?.wrappedValue ?? internalIsExpanded
  }

  private var groupAccessibilityID: String {
    let resolvedID = messageID.isEmpty ? (toolCalls.first?.id ?? "default") : messageID
    return ConversationAccessibilityID.toolCallsGroup(resolvedID)
  }

  public var body: some View {
    if !toolCalls.isEmpty {
      VStack(alignment: .leading, spacing: 0) {
        headerButton

        if isExpanded {
          Divider()
            .overlay(Color.platformSeparator.opacity(0.45))

          VStack(alignment: .leading, spacing: 0) {
            ForEach(toolCalls) { toolCall in
              ToolCallRowView(
                toolCall: toolCall,
                isInspectorExpanded: expandedToolRowIDs.contains(toolCall.id),
                onToggleInspector: {
                  toggleRowInspector(for: toolCall.id)
                },
                onRetry: makeRetryClosure(for: toolCall)
              )
              .accessibilityIdentifier(ConversationAccessibilityID.toolCallRow(toolCall.id))

              if toolCall.id != toolCalls.last?.id {
                Divider()
                  .overlay(Color.platformSeparator.opacity(0.3))
                  .padding(.leading, 36)
              }
            }
          }
          .transition(
            reduceMotion
              ? .opacity
              : .opacity.combined(with: .move(edge: .top))
          )
        }
      }
      .background(
        Color.platformSecondaryBackground,
        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier(groupAccessibilityID)
      .onChange(of: toolCalls) { oldCalls, newCalls in
        handleToolCallsStatusTransition(from: oldCalls, to: newCalls)
      }
    }
  }

  // MARK: Header Button

  private var headerButton: some View {
    Button(action: toggleGroupExpansion) {
      HStack(alignment: .center, spacing: 8) {
        GroupStatusIconView(toolCalls: toolCalls)

        Text(Self.summaryHeadline(for: toolCalls))
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.primary)
          .monospacedDigit()
          .contentTransition(.numericText())
          .lineLimit(1)

        Spacer(minLength: 8)

        Image(systemName: "chevron.right")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
          .animation(
            reduceMotion ? nil : .snappy(duration: 0.22),
            value: isExpanded
          )
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(.isButton)
    .accessibilityHint(
      isExpanded
        ? Text("Double-tap to collapse tool calls")
        : Text("Double-tap to expand tool calls")
    )
  }

  // MARK: Expansion & Auto-Fold Logic

  @MainActor
  private func makeRetryClosure(for toolCall: ToolCall) -> (@MainActor () -> Void)? {
    guard let retryAction = onToolCallRetry else { return nil }
    return { @MainActor in
      PlatformHapticEvent.triggerHaptic(.selection)
      Task { @MainActor in
        await retryAction(toolCall)
      }
    }
  }

  @MainActor
  private func toggleGroupExpansion() {
    hasUserManuallyToggled = true
    PlatformHapticEvent.triggerHaptic(.selection)
    setExpanded(!isExpanded)
  }

  @MainActor
  private func toggleRowInspector(for toolCallID: String) {
    PlatformHapticEvent.triggerHaptic(.selection)
    let animation: Animation = reduceMotion
      ? .easeOut(duration: 0.15)
      : .snappy(duration: 0.22)

    withAnimation(animation) {
      if expandedToolRowIDs.contains(toolCallID) {
        expandedToolRowIDs.remove(toolCallID)
      } else {
        expandedToolRowIDs.insert(toolCallID)
      }
    }
  }

  @MainActor
  private func setExpanded(_ newValue: Bool) {
    let animation: Animation = reduceMotion
      ? .easeOut(duration: 0.15)
      : .snappy(duration: 0.24)

    withAnimation(animation) {
      if let externalIsExpanded {
        externalIsExpanded.wrappedValue = newValue
      } else {
        internalIsExpanded = newValue
      }
    }
  }

  @MainActor
  private func handleToolCallsStatusTransition(from oldCalls: [ToolCall], to newCalls: [ToolCall]) {
    guard !hasUserManuallyToggled, !newCalls.isEmpty else { return }

    let hadRunning = oldCalls.contains { call in
      if case .running = call.status { return true }
      return false
    }
    let hasRunningNow = newCalls.contains { call in
      if case .running = call.status { return true }
      return false
    }
    let hasFailedNow = newCalls.contains { call in
      if case .failed = call.status { return true }
      return false
    }
    let allSucceededNow = newCalls.allSatisfy { call in
      if case .succeeded = call.status { return true }
      return false
    }

    if hasRunningNow && (!hadRunning || !isExpanded) {
      setExpanded(true)
    } else if hasFailedNow {
      setExpanded(true)
    } else if allSucceededNow {
      setExpanded(false)
    }
  }

  private static func initialExpandedState(for toolCalls: [ToolCall]) -> Bool {
    guard !toolCalls.isEmpty else { return false }
    let hasRunningOrFailed = toolCalls.contains { call in
      switch call.status {
      case .running, .failed:
        return true
      case .pending, .succeeded, .cancelled:
        return false
      }
    }
    return hasRunningOrFailed
  }

  // MARK: Summary Headline Formatting

  /// Computes the summary header title for a collection of `ToolCall` values:
  /// - While running: `"Running tools… (2/4)"`
  /// - When any failed: `"Tool execution failed"`
  /// - When cancelled: `"Tool execution stopped"`
  /// - When all succeeded: `"Used N tools · X.Xs"`
  public nonisolated static func summaryHeadline(for toolCalls: [ToolCall]) -> String {
    guard !toolCalls.isEmpty else {
      return "No tools executed"
    }

    let total = toolCalls.count
    var runningCount = 0
    var pendingCount = 0
    var succeededCount = 0
    var failedCount = 0
    var cancelledCount = 0
    var totalDuration: TimeInterval = 0

    for call in toolCalls {
      switch call.status {
      case .pending:
        pendingCount += 1
      case .running:
        runningCount += 1
      case .succeeded(let duration):
        succeededCount += 1
        totalDuration += max(0, duration)
      case .failed(_, let duration):
        failedCount += 1
        if let duration {
          totalDuration += max(0, duration)
        }
      case .cancelled(let duration):
        cancelledCount += 1
        if let duration {
          totalDuration += max(0, duration)
        }
      }
    }

    if runningCount > 0 || (pendingCount > 0 && failedCount == 0 && cancelledCount == 0) {
      let finishedCount = succeededCount + failedCount + cancelledCount
      let activeIndex = min(total, max(1, finishedCount + max(1, runningCount)))
      return "Running tools… (\(activeIndex)/\(total))"
    }

    if failedCount > 0 {
      return "Tool execution failed"
    }

    if cancelledCount > 0 {
      return "Tool execution stopped"
    }

    let formattedDuration = totalDuration.formatted(.number.precision(.fractionLength(1)))
    let noun = total == 1 ? "tool" : "tools"
    return "Used \(total) \(noun) · \(formattedDuration)s"
  }
}

// MARK: - GroupStatusIconView

private struct GroupStatusIconView: View {
  let toolCalls: [ToolCall]

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private enum AggregateState: Equatable {
    case running
    case failed
    case cancelled
    case succeeded
  }

  private var aggregateState: AggregateState {
    if toolCalls.contains(where: \.isActive) {
      return .running
    }
    if toolCalls.contains(where: {
      if case .failed = $0.status { return true }
      return false
    }) {
      return .failed
    }
    if toolCalls.contains(where: {
      if case .cancelled = $0.status { return true }
      return false
    }) {
      return .cancelled
    }
    return .succeeded
  }

  private var symbolName: String {
    switch aggregateState {
    case .running:
      return "gearshape.2.fill"
    case .failed:
      return "exclamationmark.triangle.fill"
    case .cancelled:
      return "stop.circle.fill"
    case .succeeded:
      return "checkmark.circle.fill"
    }
  }

  private var symbolColor: Color {
    switch aggregateState {
    case .running:
      return .accentColor
    case .failed:
      return .red
    case .cancelled:
      return .secondary
    case .succeeded:
      return .green
    }
  }

  var body: some View {
    Image(systemName: symbolName)
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(symbolColor)
      .contentTransition(.symbolEffect(.replace))
      .symbolEffect(
        .pulse,
        options: .repeating,
        isActive: aggregateState == .running && !reduceMotion
      )
      .accessibilityHidden(true)
  }
}

// MARK: - ToolCallRowView

private struct ToolCallRowView: View {
  let toolCall: ToolCall
  let isInspectorExpanded: Bool
  let onToggleInspector: @MainActor () -> Void
  let onRetry: (@MainActor () -> Void)?

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var hasInspectablePayload: Bool {
    let hasArgs = toolCall.argumentsJSON?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    let hasResult = toolCall.resultJSON?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    let hasError = errorString != nil
    return hasArgs || hasResult || hasError
  }

  private var errorString: String? {
    if case .failed(let error, _) = toolCall.status,
      !error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return error
    }
    return nil
  }

  private var isFailed: Bool {
    if case .failed = toolCall.status {
      return true
    }
    return false
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .center, spacing: 8) {
        Button(action: onToggleInspector) {
          HStack(alignment: .center, spacing: 8) {
            Image(systemName: toolCall.symbolName)
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
              .frame(width: 20, height: 20)
              .contentTransition(.symbolEffect(.replace))

            VStack(alignment: .leading, spacing: 2) {
              HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(toolCall.name)
                  .font(.subheadline.monospaced().weight(.medium))
                  .foregroundStyle(.primary)
                  .lineLimit(1)

                if let summary = toolCall.argumentsSummary,
                  !summary.isEmpty,
                  summary != toolCall.name
                {
                  Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
              }

              if let resultSummary = toolCall.resultSummary, !resultSummary.isEmpty {
                Text(resultSummary)
                  .font(.caption2)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              } else if let errorString {
                Text(errorString)
                  .font(.caption2)
                  .foregroundStyle(.red)
                  .lineLimit(1)
              }
            }

            Spacer(minLength: 6)

            ToolCallStatusBadgeView(status: toolCall.status)

            if hasInspectablePayload {
              Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isInspectorExpanded ? 90 : 0))
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if isFailed, let onRetry {
          Button("Retry", systemImage: "arrow.clockwise", action: onRetry)
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .tint(.red)
        }
      }

      if isInspectorExpanded && hasInspectablePayload {
        ToolCallJSONInspectorView(
          argumentsJSON: toolCall.argumentsJSON,
          resultJSON: toolCall.resultJSON,
          errorMessage: errorString
        )
        .transition(
          reduceMotion
            ? .opacity
            : .opacity.combined(with: .move(edge: .top))
        )
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
  }
}

// MARK: - ToolCallStatusBadgeView (Leaf TimelineView Isolation)

/// Leaf-scoped status and elapsed duration badge for an individual `ToolCall`.
///
/// Isolates the `0.1s` `TimelineView` strictly to the running timer text so 120Hz ProMotion
/// scrolling never re-evaluates the tool row or JSON inspector on timer ticks.
private struct ToolCallStatusBadgeView: View {
  let status: ToolCall.Status

  var body: some View {
    switch status {
    case .pending:
      HStack(spacing: 4) {
        Image(systemName: "clock")
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .contentTransition(.symbolEffect(.replace))
        Text("Pending")
          .font(.caption.monospacedDigit())
          .foregroundStyle(.tertiary)
      }

    case .running(let startedAt):
      TimelineView(.periodic(from: startedAt, by: 0.1)) { context in
        let elapsed = max(0, context.date.timeIntervalSince(startedAt))
        let formatted = elapsed.formatted(.number.precision(.fractionLength(1)))

        HStack(spacing: 4) {
          Image(systemName: "rays")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.tint)
            .contentTransition(.symbolEffect(.replace))

          Text("\(formatted)s")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .contentTransition(.numericText(countsDown: false))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Running, \(formatted) seconds")
      }

    case .succeeded(let duration):
      let formatted = max(0, duration).formatted(.number.precision(.fractionLength(1)))
      HStack(spacing: 4) {
        Image(systemName: "checkmark.circle.fill")
          .font(.caption2)
          .foregroundStyle(.green)
          .contentTransition(.symbolEffect(.replace))

        Text("\(formatted)s")
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
          .contentTransition(.numericText())
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel("Succeeded in \(formatted) seconds")

    case .failed(_, let duration):
      HStack(spacing: 4) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.caption2)
          .foregroundStyle(.red)
          .contentTransition(.symbolEffect(.replace))

        if let duration {
          let formatted = max(0, duration).formatted(.number.precision(.fractionLength(1)))
          Text("\(formatted)s")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.red)
        } else {
          Text("Failed")
            .font(.caption.weight(.medium))
            .foregroundStyle(.red)
        }
      }

    case .cancelled(let duration):
      HStack(spacing: 4) {
        Image(systemName: "stop.circle.fill")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .contentTransition(.symbolEffect(.replace))

        if let duration {
          let formatted = max(0, duration).formatted(.number.precision(.fractionLength(1)))
          Text("\(formatted)s")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        } else {
          Text("Stopped")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}

// MARK: - ToolCallJSONInspectorView

private struct ToolCallJSONInspectorView: View {
  let argumentsJSON: String?
  let resultJSON: String?
  let errorMessage: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let argumentsJSON, !argumentsJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        JSONBlockSectionView(title: "Arguments", payload: argumentsJSON)
      }

      if let resultJSON, !resultJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        JSONBlockSectionView(title: "Result", payload: resultJSON)
      }

      if let errorMessage, !errorMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        JSONBlockSectionView(title: "Error", payload: errorMessage, isError: true)
      }
    }
    .padding(.leading, 28)
    .padding(.top, 2)
  }
}

private struct JSONBlockSectionView: View {
  let title: String
  let payload: String
  var isError: Bool = false

  @State private var didCopy: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(title)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(isError ? .red : .secondary)

        Spacer()

        Button {
          PlatformPasteboard.copyText(payload)
          PlatformHapticEvent.triggerHaptic(.copySuccess)
          didCopy = true
          Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            didCopy = false
          }
        } label: {
          HStack(spacing: 3) {
            Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
              .font(.caption2.weight(.semibold))
              .contentTransition(.symbolEffect(.replace))
            Text(didCopy ? "Copied" : "Copy")
              .font(.caption2.weight(.medium))
          }
          .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(didCopy ? "Copied \(title)" : "Copy \(title)")
      }

      ScrollView(.horizontal, showsIndicators: false) {
        Text(payload)
          .font(.caption.monospaced())
          .foregroundStyle(isError ? .red : .primary)
          .textSelection(.enabled)
          .padding(8)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(
        Color.platformTertiaryBackground,
        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .strokeBorder(
            isError ? Color.red.opacity(0.35) : Color.platformSeparator.opacity(0.4),
            lineWidth: 0.5
          )
      }
    }
  }
}
