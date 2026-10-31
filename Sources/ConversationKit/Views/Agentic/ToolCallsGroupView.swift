//
// ToolCallsGroupView.swift
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

import SwiftUI

/// Collapsible group view rendering one or more `ToolCall` invocations within an assistant turn (`FR-3.1`, `AC-9`, `AC-10`).
public struct ToolCallsGroupView: View {
  @Environment(\.onRetryToolCallAction) private var onRetryToolCallAction

  public let toolCalls: [ToolCall]

  @State private var isExpanded: Bool
  @State private var userOverrodeExpansion: Bool = false

  public init(toolCalls: [ToolCall]) {
    self.toolCalls = toolCalls
    self._isExpanded = State(
      initialValue: Self.shouldAutoExpand(for: toolCalls, userOverrodeExpansion: false)
    )
  }

  /// Deterministically computes whether `ToolCallsGroupView` should be expanded for a given list of tool calls (`AC-9`).
  public static func shouldAutoExpand(
    for toolCalls: [ToolCall],
    userOverrodeExpansion: Bool
  ) -> Bool {
    guard !toolCalls.isEmpty else { return false }
    if toolCalls.contains(where: { $0.status == .failed }) {
      return true
    }
    if toolCalls.contains(where: { $0.status == .running }) {
      return true
    }
    if toolCalls.allSatisfy({ $0.status == .succeeded }) {
      return userOverrodeExpansion
    }
    return userOverrodeExpansion
  }

  /// Deterministically formats the aggregate header title for a list of tool calls (`AC-9`).
  public static func summaryTitle(for toolCalls: [ToolCall]) -> String {
    guard !toolCalls.isEmpty else { return "No tools" }

    if toolCalls.contains(where: { $0.status == .failed }) {
      return "Tool execution failed"
    }
    if toolCalls.contains(where: { $0.status == .running }) {
      return "Running tools…"
    }
    if toolCalls.contains(where: { $0.status == .cancelled }) {
      return "Tool execution cancelled"
    }
    if toolCalls.allSatisfy({ $0.status == .succeeded }) {
      let totalDuration = toolCalls.compactMap(\.durationSeconds).reduce(0, +)
      let formattedDuration = totalDuration.formatted(.number.precision(.fractionLength(1)))
      let noun = toolCalls.count == 1 ? "tool" : "tools"
      return "Used \(toolCalls.count) \(noun) · \(formattedDuration)s"
    }
    return "Pending tools…"
  }

  private var anyRunning: Bool {
    toolCalls.contains(where: { $0.status == .running })
  }

  private var anyFailed: Bool {
    toolCalls.contains(where: { $0.status == .failed })
  }

  private var allSucceeded: Bool {
    !toolCalls.isEmpty && toolCalls.allSatisfy({ $0.status == .succeeded })
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button {
        userOverrodeExpansion = true
        withAnimation(.snappy(duration: 0.25)) {
          isExpanded.toggle()
        }
      } label: {
        HStack(spacing: 8) {
          headerIcon

          Text(Self.summaryTitle(for: toolCalls))
            .font(.subheadline.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(anyFailed ? Color.red : Color.secondary)

          Spacer(minLength: 4)

          Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.platformSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(anyFailed ? Color.red.opacity(0.4) : Color.platformSeparator, lineWidth: 0.5)
        )
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("tool_calls_group_header")

      if isExpanded {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(toolCalls) { tool in
            ToolCallRowView(tool: tool, onRetry: onRetryToolCallAction)
          }
        }
        .padding(.leading, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("tool_calls_group")
    .onChange(of: toolCalls) { _, updatedTools in
      if updatedTools.contains(where: { $0.status == .failed }) {
        withAnimation(.snappy(duration: 0.25)) {
          isExpanded = true
        }
      } else if updatedTools.contains(where: { $0.status == .running }), !userOverrodeExpansion {
        withAnimation(.snappy(duration: 0.25)) {
          isExpanded = true
        }
      }
    }
    .task(id: allSucceeded) {
      guard allSucceeded, !userOverrodeExpansion else { return }
      try? await Task.sleep(for: .milliseconds(400))
      guard !Task.isCancelled, !userOverrodeExpansion else { return }
      withAnimation(.snappy(duration: 0.25)) {
        isExpanded = false
      }
    }
  }

  @ViewBuilder
  private var headerIcon: some View {
    if anyRunning {
      ProgressView()
        .controlSize(.small)
    } else if anyFailed {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.subheadline)
        .foregroundStyle(.red)
    } else if allSucceeded {
      Image(systemName: "checkmark.circle.fill")
        .font(.subheadline)
        .foregroundStyle(.green)
    } else {
      Image(systemName: "wrench.and.screwdriver")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }
}

/// Renders an individual `ToolCall` row with lazy JSON payload expansion and retry support (`AC-9`, `AC-10`).
public struct ToolCallRowView: View {
  public let tool: ToolCall
  let onRetry: OnRetryToolCallAction?

  @State private var isInspectingPayload: Bool = false
  @State private var isSensitiveRevealed: Bool = false

  public init(tool: ToolCall, onRetry: OnRetryToolCallAction? = nil) {
    self.tool = tool
    self.onRetry = onRetry
  }

  private var hasPayload: Bool {
    tool.inputJSON != nil || tool.outputJSON != nil || tool.errorMessage != nil
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Button {
          guard hasPayload else { return }
          withAnimation(.snappy(duration: 0.2)) {
            isInspectingPayload.toggle()
          }
        } label: {
          HStack(spacing: 8) {
            Image(systemName: tool.icon ?? "wrench.and.screwdriver")
              .font(.caption.weight(.semibold))
              .foregroundStyle(Color.accentColor)
              .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
              Text(tool.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)

              if let summary = tool.argumentsSummary, !summary.isEmpty {
                Text(summary)
                  .font(.caption2)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }
            }

            Spacer(minLength: 4)

            if let duration = tool.durationSeconds {
              Text("\(duration, format: .number.precision(.fractionLength(1)))s")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            statusBadge
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tool_call_row_\(tool.id)")

        if tool.status == .failed, let onRetry {
          Button {
            Task { @MainActor in
              await onRetry(tool)
            }
          } label: {
            Label("Retry", systemImage: "arrow.clockwise")
              .font(.caption2.weight(.semibold))
          }
          .buttonStyle(.bordered)
          .controlSize(.mini)
          .accessibilityIdentifier("tool_call_retry_button")
        }
      }

      if isInspectingPayload && hasPayload {
        VStack(alignment: .leading, spacing: 6) {
          if tool.isSensitive && !isSensitiveRevealed {
            HStack {
              Image(systemName: "lock.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
              Text("Sensitive payload hidden")
                .font(.caption2)
                .foregroundStyle(.secondary)
              Spacer()
              Button("Reveal") {
                isSensitiveRevealed = true
              }
              .font(.caption2.weight(.semibold))
              .buttonStyle(.borderless)
              .accessibilityIdentifier("tool_call_reveal_sensitive_button")
            }
          } else {
            if let inputJSON = tool.inputJSON, !inputJSON.isEmpty {
              Text("Input:")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
              Text(inputJSON)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
            }

            if let outputJSON = tool.outputJSON, !outputJSON.isEmpty {
              Text("Output:")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
              Text(outputJSON)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
            }

            if let errorMessage = tool.errorMessage, !errorMessage.isEmpty {
              Text(errorMessage)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.red)
                .textSelection(.enabled)
            }
          }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.platformTertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tool_call_json_payload")
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Color.platformSecondaryBackground.opacity(0.6))
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }

  @ViewBuilder
  private var statusBadge: some View {
    switch tool.status {
    case .pending:
      Image(systemName: "clock")
        .font(.caption2)
        .foregroundStyle(.secondary)
    case .running:
      ProgressView()
        .controlSize(.mini)
    case .succeeded:
      Image(systemName: "checkmark.circle.fill")
        .font(.caption2)
        .foregroundStyle(.green)
    case .failed:
      Image(systemName: "exclamationmark.circle.fill")
        .font(.caption2)
        .foregroundStyle(.red)
    case .cancelled:
      Image(systemName: "slash.circle")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  ToolCallsGroupView(
    toolCalls: [
      ToolCall(
        name: "search_docs",
        icon: "magnifyingglass",
        argumentsSummary: "query: \"ScrollViewReader anchor top\"",
        resultSummary: "Found 3 matches",
        durationSeconds: 1.2,
        inputJSON: "{\"query\": \"ScrollViewReader anchor top\"}",
        outputJSON: "{\"matches\": 3}",
        status: .succeeded
      ),
      ToolCall(
        name: "run_tests",
        icon: "hammer",
        argumentsSummary: "target: ConversationKitTests",
        durationSeconds: 2.0,
        errorMessage: "Exit code 1",
        status: .failed
      )
    ]
  )
  .padding()
}
