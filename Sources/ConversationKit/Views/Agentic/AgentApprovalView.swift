//
// AgentApprovalView.swift
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

/// Renders an inline human-in-the-loop (HITL) permission gate with `Allow once`, `Always`, and `Deny` actions (`FR-3.3`, `AC-12`).
public struct AgentApprovalView: View {
  @Environment(\.onAgentApprovalAction) private var onAgentApprovalAction

  public let request: ApprovalRequest

  @State private var localDecision: ApprovalRequest.Decision?

  public init(request: ApprovalRequest) {
    self.request = request
  }

  private var effectiveDecision: ApprovalRequest.Decision {
    localDecision ?? request.decision
  }

  /// Deterministically formats the resolution badge label for a decision state (`AC-12`).
  public static func resolutionLabel(for decision: ApprovalRequest.Decision) -> String {
    switch decision {
    case .pending:
      return "Approval required"
    case .allowOnce:
      return "Allowed once"
    case .alwaysAllow:
      return "Always allowed"
    case .deny:
      return "Denied"
    case .cancelled:
      return "Approval cancelled"
    }
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if effectiveDecision == .pending {
        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 6) {
            Image(systemName: "hand.raised.fill")
              .font(.subheadline)
              .foregroundStyle(.orange)

            Text(request.title)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.primary)

            Spacer(minLength: 0)
          }

          Text(request.detail)
            .font(.caption)
            .foregroundStyle(.secondary)

          if let scope = request.scopeIdentifier, !scope.isEmpty {
            Text("Scope: \(scope)")
              .font(.system(.caption2, design: .monospaced))
              .foregroundStyle(.secondary)
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(Color.platformTertiaryBackground)
              .clipShape(Capsule())
              .accessibilityIdentifier("approval_scope_badge")
          }
        }

        HStack(spacing: 8) {
          Button {
            resolve(.allowOnce)
          } label: {
            Text("Allow once")
              .font(.caption.weight(.semibold))
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)
          .accessibilityIdentifier("approval_allow_once_button")

          Button {
            resolve(.alwaysAllow)
          } label: {
            Text("Always")
              .font(.caption.weight(.semibold))
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .accessibilityIdentifier("approval_always_allow_button")
          .accessibilityHint(
            request.scopeIdentifier.map { Text("Always allow for scope \($0)") } ?? Text("Always allow")
          )

          Button(role: .destructive) {
            resolve(.deny)
          } label: {
            Text("Deny")
              .font(.caption.weight(.semibold))
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .accessibilityIdentifier("approval_deny_button")
        }
      } else {
        HStack(spacing: 6) {
          Image(systemName: resolvedIconName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(resolvedIconColor)

          Text("\(request.title) · \(Self.resolutionLabel(for: effectiveDecision))")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)

          Spacer(minLength: 0)
        }
        .accessibilityIdentifier("approval_resolved_badge")
      }
    }
    .padding(12)
    .background(Color.platformSecondaryBackground)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(
          effectiveDecision == .pending ? Color.orange.opacity(0.45) : Color.platformSeparator,
          lineWidth: 0.75
        )
    )
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("agent_approval_view")
    .onChange(of: request.decision) { _, newDecision in
      if newDecision != .pending {
        localDecision = newDecision
      }
    }
  }

  @MainActor
  private func resolve(_ decision: ApprovalRequest.Decision) {
    withAnimation(.snappy(duration: 0.2)) {
      localDecision = decision
    }
    guard let onAgentApprovalAction else { return }
    Task { @MainActor in
      await onAgentApprovalAction(request, decision)
    }
  }

  private var resolvedIconName: String {
    switch effectiveDecision {
    case .pending:
      return "hand.raised.fill"
    case .allowOnce, .alwaysAllow:
      return "checkmark.shield.fill"
    case .deny:
      return "xmark.shield.fill"
    case .cancelled:
      return "slash.circle"
    }
  }

  private var resolvedIconColor: Color {
    switch effectiveDecision {
    case .pending:
      return .orange
    case .allowOnce, .alwaysAllow:
      return .green
    case .deny:
      return .red
    case .cancelled:
      return .secondary
    }
  }
}

#Preview("Pending Approval") {
  AgentApprovalView(
    request: ApprovalRequest(
      title: "Write file to workspace",
      detail: "The agent wants to modify Sources/ConversationKit/Views/Timeline/ConversationView.swift.",
      scopeIdentifier: "mcp:filesystem/write",
      decision: .pending
    )
  )
  .padding()
}

#Preview("Resolved Approval") {
  AgentApprovalView(
    request: ApprovalRequest(
      title: "Write file to workspace",
      detail: "The agent wants to modify Sources/ConversationKit/Views/Timeline/ConversationView.swift.",
      scopeIdentifier: "mcp:filesystem/write",
      decision: .allowOnce
    )
  )
  .padding()
}
