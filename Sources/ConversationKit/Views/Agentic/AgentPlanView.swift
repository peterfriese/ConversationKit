//
// AgentPlanView.swift
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

/// Renders a multi-step agent execution checklist with live step status icons and completion progress (`FR-3.2`, `AC-11`).
public struct AgentPlanView: View {
  public let plan: AgentPlan

  public init(plan: AgentPlan) {
    self.plan = plan
  }

  /// Deterministically formats the progress summary string (`AC-11`).
  public static func progressSummary(for plan: AgentPlan) -> String {
    "\(plan.completedCount) of \(plan.steps.count) completed"
  }

  /// Deterministically resolves the SF Symbol name for a step status (`AC-11`).
  public static func iconName(for status: AgentPlan.Step.Status) -> String {
    switch status {
    case .pending:
      return "circle"
    case .inProgress:
      return "arrow.triangle.2.circlepath.circle.fill"
    case .completed:
      return "checkmark.circle.fill"
    case .failed:
      return "exclamationmark.triangle.fill"
    case .skipped:
      return "minus.circle"
    case .cancelled:
      return "slash.circle"
    }
  }

  private var progressFraction: Double {
    guard !plan.steps.isEmpty else { return 0 }
    return Double(plan.completedCount) / Double(plan.steps.count)
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Label(plan.title, systemImage: "checklist")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)

        Spacer()

        Text(Self.progressSummary(for: plan))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
          .accessibilityIdentifier("agent_plan_progress")
      }

      ProgressView(value: progressFraction)
        .tint(Color.accentColor)

      VStack(alignment: .leading, spacing: 8) {
        ForEach(plan.steps) { step in
          HStack(alignment: .top, spacing: 8) {
            stepIndicator(for: step.status)
              .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
              Text(step.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(step.status == .skipped || step.status == .cancelled ? .secondary : .primary)
                .strikethrough(step.status == .skipped || step.status == .cancelled)

              if let detail = step.detail, !detail.isEmpty {
                Text(detail)
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              }
            }

            Spacer(minLength: 0)
          }
          .accessibilityIdentifier("agent_plan_step_\(step.id)")
        }
      }
    }
    .padding(12)
    .background(Color.platformSecondaryBackground)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(Color.platformSeparator, lineWidth: 0.5)
    )
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("agent_plan_view")
  }

  @ViewBuilder
  private func stepIndicator(for status: AgentPlan.Step.Status) -> some View {
    switch status {
    case .inProgress:
      ProgressView()
        .controlSize(.mini)
    case .pending:
      Image(systemName: Self.iconName(for: status))
        .font(.caption)
        .foregroundStyle(.secondary)
    case .completed:
      Image(systemName: Self.iconName(for: status))
        .font(.caption)
        .foregroundStyle(.green)
    case .failed:
      Image(systemName: Self.iconName(for: status))
        .font(.caption)
        .foregroundStyle(.red)
    case .skipped, .cancelled:
      Image(systemName: Self.iconName(for: status))
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  AgentPlanView(
    plan: AgentPlan(
      title: "Migrate Views to vNext Sub-Surfaces",
      steps: [
        AgentPlan.Step(title: "Create Timeline, Composer, Welcome, and Agentic folders", status: .completed),
        AgentPlan.Step(title: "Implement ThinkingStateView & ToolCallsGroupView", status: .inProgress),
        AgentPlan.Step(title: "Wire Agentic views into MessageView", status: .pending),
        AgentPlan.Step(title: "Legacy UIKit fallback", status: .skipped)
      ]
    )
  )
  .padding()
}
