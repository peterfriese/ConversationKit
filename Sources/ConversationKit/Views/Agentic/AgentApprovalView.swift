//
//  AgentApprovalView.swift
//  ConversationKit
//
//  Human-in-the-loop permission request card with risk classification badge,
//  scope pill, monospaced change preview, and Allow Once / Always Allow / Deny actions (AC-10, AC-18).
//

import Foundation
import SwiftUI

// MARK: - AgentApprovalView

/// Renders a human-in-the-loop `ApprovalRequest` card inside an assistant turn (`F-7`, `AC-10`, `AC-18`).
///
/// Displays the operation `title`, a severity `riskLevel` badge (`Low`, `Medium`, `High`), `detail`,
/// an optional `scopeIdentifier` pill, an optional monospaced `changePreview` block, and—while
/// `decision == .pending`—three resolution actions (**Allow once**, **Always allow**, **Deny**)
/// routed through `@Environment(\.onApprovalDecision)`.
@MainActor
public struct AgentApprovalView: View {
  /// The approval request model to display.
  public let request: ApprovalRequest

  @State private var localDecisionOverride: ApprovalRequest.Decision?
  @State private var didCopyPreview: Bool = false

  @Environment(\.onApprovalDecision) private var onApprovalDecision
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Creates an `AgentApprovalView` for the given `ApprovalRequest`.
  public init(
    request: ApprovalRequest
  ) {
    self.request = request
  }

  /// Effective decision reflecting either the model's resolved `decision` or an immediate local resolution.
  private var effectiveDecision: ApprovalRequest.Decision {
    if request.decision != .pending {
      return request.decision
    }
    return localDecisionOverride ?? .pending
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      headerRow

      if !request.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Text(request.detail)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      if let scope = request.scopeIdentifier,
        !scope.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        scopePill(scope)
      }

      if let preview = request.changePreview,
        !preview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        changePreviewBlock(preview)
      }

      Divider()
        .overlay(Color.platformSeparator.opacity(0.45))

      if effectiveDecision == .pending {
        actionButtonsRow
          .transition(
            reduceMotion
              ? .opacity
              : .opacity.combined(with: .scale(scale: 0.98, anchor: .topLeading))
          )
      } else {
        resolvedDecisionBadge(for: effectiveDecision)
          .transition(.opacity)
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
        .strokeBorder(borderColor, lineWidth: 0.75)
    }
    .onChange(of: request.decision) { _, newDecision in
      if newDecision != .pending {
        localDecisionOverride = newDecision
      } else {
        localDecisionOverride = nil
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(ConversationAccessibilityID.agentApproval(request.id))
  }

  // MARK: Header & Risk Badge

  private var headerRow: some View {
    HStack(alignment: .center, spacing: 8) {
      Image(systemName: headerSymbolName)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(riskColor)
        .contentTransition(.symbolEffect(.replace))
        .accessibilityHidden(true)

      Text(request.title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .lineLimit(2)

      Spacer(minLength: 8)

      riskBadge
    }
  }

  private var riskBadge: some View {
    Text(riskTitle)
      .font(.caption2.weight(.semibold))
      .foregroundStyle(riskColor)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(
        riskColor.opacity(0.14),
        in: Capsule()
      )
      .overlay {
        Capsule()
          .strokeBorder(riskColor.opacity(0.32), lineWidth: 0.5)
      }
      .accessibilityLabel("\(riskTitle) risk")
  }

  private var riskTitle: String {
    switch request.riskLevel {
    case .low:
      return "Low"
    case .medium:
      return "Medium"
    case .high:
      return "High"
    }
  }

  private var riskColor: Color {
    switch request.riskLevel {
    case .low:
      return .blue
    case .medium:
      return .orange
    case .high:
      return .red
    }
  }

  private var headerSymbolName: String {
    switch effectiveDecision {
    case .pending:
      return request.riskLevel == .high
        ? "exclamationmark.shield.fill"
        : "hand.raised.fill"
    case .allowOnce, .alwaysAllow:
      return "checkmark.shield.fill"
    case .deny:
      return "xmark.shield.fill"
    case .cancelled:
      return "slash.circle.fill"
    }
  }

  private var borderColor: Color {
    if effectiveDecision == .pending && request.riskLevel == .high {
      return Color.red.opacity(0.45)
    }
    return Color.platformSeparator.opacity(0.45)
  }

  // MARK: Scope Pill & Change Preview

  private func scopePill(_ scope: String) -> some View {
    HStack(spacing: 5) {
      Image(systemName: "scope")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)

      Text(scope)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      Color.platformTertiaryBackground,
      in: Capsule()
    )
    .overlay {
      Capsule()
        .strokeBorder(Color.platformSeparator.opacity(0.4), lineWidth: 0.5)
    }
  }

  private func changePreviewBlock(_ preview: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text("Preview")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)

        Spacer()

        Button {
          PlatformPasteboard.copyText(preview)
          PlatformHapticEvent.triggerHaptic(.copySuccess)
          didCopyPreview = true
          Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            didCopyPreview = false
          }
        } label: {
          HStack(spacing: 3) {
            Image(systemName: didCopyPreview ? "checkmark" : "doc.on.doc")
              .font(.caption2.weight(.semibold))
              .contentTransition(.symbolEffect(.replace))
            Text(didCopyPreview ? "Copied" : "Copy")
              .font(.caption2.weight(.medium))
          }
          .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(didCopyPreview ? "Copied preview" : "Copy preview")
      }

      ScrollView(.horizontal, showsIndicators: false) {
        Text(preview)
          .font(.caption.monospaced())
          .foregroundStyle(.primary)
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
          .strokeBorder(Color.platformSeparator.opacity(0.4), lineWidth: 0.5)
      }
    }
  }

  // MARK: Action Buttons & Resolved Badge

  private var actionButtonsRow: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 8) {
        allowOnceButton
        alwaysAllowButton
        Spacer(minLength: 4)
        denyButton
      }

      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 8) {
          allowOnceButton
          alwaysAllowButton
        }
        denyButton
      }
    }
  }

  private var allowOnceButton: some View {
    Button {
      submitDecision(.allowOnce)
    } label: {
      Label("Allow once", systemImage: "checkmark.circle")
        .font(.caption.weight(.semibold))
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.small)
  }

  private var alwaysAllowButton: some View {
    Button {
      submitDecision(.alwaysAllow)
    } label: {
      Label("Always allow", systemImage: "checkmark.seal")
        .font(.caption.weight(.semibold))
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
  }

  private var denyButton: some View {
    Button(role: .destructive) {
      submitDecision(.deny)
    } label: {
      Label("Deny", systemImage: "xmark.circle")
        .font(.caption.weight(.semibold))
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
    .tint(.red)
  }

  private func resolvedDecisionBadge(for decision: ApprovalRequest.Decision) -> some View {
    let metadata = Self.decisionBadgeMetadata(for: decision)

    return HStack(spacing: 6) {
      Image(systemName: metadata.symbol)
        .font(.caption.weight(.semibold))
        .foregroundStyle(metadata.color)
        .accessibilityHidden(true)

      Text(metadata.label)
        .font(.caption.weight(.semibold))
        .foregroundStyle(metadata.color)

      Spacer(minLength: 0)
    }
    .padding(.vertical, 2)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Decision: \(metadata.label)")
  }

  @MainActor
  private func submitDecision(_ decision: ApprovalRequest.Decision) {
    PlatformHapticEvent.triggerHaptic(.selection)

    let animation: Animation = reduceMotion
      ? .easeOut(duration: 0.15)
      : .snappy(duration: 0.22)

    withAnimation(animation) {
      localDecisionOverride = decision
    }

    if let onApprovalDecision {
      Task { @MainActor in
        await onApprovalDecision(request, decision)
      }
    }
  }

  private static func decisionBadgeMetadata(
    for decision: ApprovalRequest.Decision
  ) -> (label: String, symbol: String, color: Color) {
    switch decision {
    case .pending:
      return ("Pending approval", "clock", .secondary)
    case .allowOnce:
      return ("Allowed once", "checkmark.circle.fill", .green)
    case .alwaysAllow:
      return ("Always allowed", "checkmark.seal.fill", .green)
    case .deny:
      return ("Denied", "xmark.circle.fill", .red)
    case .cancelled:
      return ("Cancelled", "slash.circle.fill", .secondary)
    }
  }
}
