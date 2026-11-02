//
//  AgentPlanView.swift
//  ConversationKit
//
//  Step-by-step agent execution checklist with determinate progress bar and
//  semantic status glyphs (AC-10, AC-18).
//

import Foundation
import SwiftUI

// MARK: - AgentPlanView

/// Renders a structured multi-step `AgentPlan` card inside an assistant turn (`F-7`, `AC-10`, `AC-18`).
///
/// Displays the plan title, a tabular progress counter (`"\(plan.completedCount) of \(plan.steps.count) completed"`),
/// a determinate progress bar, and ordered step rows with status glyphs (`.pending`, `.inProgress`,
/// `.completed`, `.failed`, `.skipped`, `.cancelled`).
@MainActor
public struct AgentPlanView: View {
  /// The execution plan to render.
  public let plan: AgentPlan

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Creates an `AgentPlanView` for the given `AgentPlan`.
  public init(plan: AgentPlan) {
    self.plan = plan
  }

  private var progressSummaryText: String {
    "\(plan.completedCount) of \(plan.steps.count) completed"
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      headerRow
      progressBar

      if !plan.steps.isEmpty {
        Divider()
          .overlay(Color.platformSeparator.opacity(0.45))

        VStack(alignment: .leading, spacing: 8) {
          ForEach(plan.steps.enumerated(), id: \.element.id) { index, step in
            AgentPlanStepRowView(
              stepNumber: index + 1,
              step: step
            )
          }
        }
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      Color.platformSecondaryBackground,
      in: RoundedRectangle(cornerRadius: 14, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(Color.platformSeparator.opacity(0.45), lineWidth: 0.5)
    }
    .animation(
      reduceMotion ? nil : .snappy(duration: 0.24),
      value: plan.steps
    )
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(ConversationAccessibilityID.agentPlan(plan.id))
  }

  // MARK: Subviews

  private var headerRow: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Image(systemName: "checklist")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.tint)
        .accessibilityHidden(true)

      Text(plan.title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .lineLimit(2)

      Spacer(minLength: 8)

      Text(progressSummaryText)
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .contentTransition(.numericText())
    }
  }

  private var progressBar: some View {
    ProgressView(value: min(max(plan.progressFraction, 0.0), 1.0), total: 1.0)
      .progressViewStyle(.linear)
      .tint(planHasFailedStep ? .red : (plan.progressFraction >= 1.0 ? .green : .accentColor))
      .accessibilityLabel("Plan progress")
      .accessibilityValue(progressSummaryText)
  }

  private var planHasFailedStep: Bool {
    plan.steps.contains { $0.status == .failed }
  }
}

// MARK: - AgentPlanStepRowView

private struct AgentPlanStepRowView: View {
  let stepNumber: Int
  let step: AgentPlan.Step

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      statusGlyph
        .frame(width: 18, height: 18)
        .padding(.top, 1)

      VStack(alignment: .leading, spacing: 2) {
        Text(step.title)
          .font(.subheadline.weight(step.status == .inProgress ? .medium : .regular))
          .foregroundStyle(titleColor)
          .strikethrough(
            step.status == .skipped || step.status == .cancelled,
            color: .secondary
          )
          .fixedSize(horizontal: false, vertical: true)

        if let detail = step.detail,
          !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
          Text(detail)
            .font(.caption)
            .foregroundStyle(step.status == .failed ? Color.red : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Step \(stepNumber): \(step.title), \(statusAccessibilityLabel)")
  }

  private var statusGlyph: some View {
    Image(systemName: symbolName)
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(glyphColor)
      .contentTransition(.symbolEffect(.replace))
      .symbolEffect(
        .pulse,
        options: .repeating,
        isActive: step.status == .inProgress && !reduceMotion
      )
      .accessibilityHidden(true)
  }

  private var symbolName: String {
    switch step.status {
    case .pending:
      return "circle"
    case .inProgress:
      return "arrow.trianglehead.2.clockwise.rotate.90.circle.fill"
    case .completed:
      return "checkmark.circle.fill"
    case .failed:
      return "exclamationmark.circle.fill"
    case .skipped:
      return "arrow.uturn.right.circle"
    case .cancelled:
      return "xmark.circle"
    }
  }

  private var glyphColor: Color {
    switch step.status {
    case .pending:
      return .secondary.opacity(0.6)
    case .inProgress:
      return .accentColor
    case .completed:
      return .green
    case .failed:
      return .red
    case .skipped, .cancelled:
      return .secondary
    }
  }

  private var titleColor: Color {
    switch step.status {
    case .pending:
      return .primary.opacity(0.85)
    case .inProgress, .completed:
      return .primary
    case .failed:
      return .red
    case .skipped, .cancelled:
      return .secondary
    }
  }

  private var statusAccessibilityLabel: String {
    switch step.status {
    case .pending:
      return "pending"
    case .inProgress:
      return "in progress"
    case .completed:
      return "completed"
    case .failed:
      return "failed"
    case .skipped:
      return "skipped"
    case .cancelled:
      return "cancelled"
    }
  }
}
