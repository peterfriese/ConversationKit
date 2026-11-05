//
//  A2UIMessageRowView.swift
//  A2UIConversationDemo
//
//  Composes ConversationKit's MessageView with inline interactive A2UI surfaces.
//  Follows the Liquid Glass scrolling cell rule: no Liquid Glass inside ScrollView cells.
//

import A2UICore
import A2UISwiftUI
import ConversationKit
import SwiftUI

public struct A2UIMessageRowView: View {
  public let message: A2UIChatMessage
  public let viewModel: A2UIConversationViewModel
  public let onInspectSurface: (String) -> Void

  public init(
    message: A2UIChatMessage,
    viewModel: A2UIConversationViewModel,
    onInspectSurface: @escaping (String) -> Void
  ) {
    self.message = message
    self.viewModel = viewModel
    self.onInspectSurface = onInspectSurface
  }

  public var body: some View {
    VStack(alignment: message.participant == .user ? .trailing : .leading, spacing: 10) {
      if message.participant == .user, let badge = message.actionBadge {
        HStack(spacing: 4) {
          Image(systemName: "bolt.horizontal.fill")
            .font(.caption2)
          Text(badge)
            .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.quaternary, in: .capsule)
      }

      MessageView(message: message)

      if message.participant == .other && !message.surfaceIDs.isEmpty {
        ForEach(message.surfaceIDs, id: \.self) { surfaceID in
          if let surfaceVM = viewModel.surfaceViewModel(for: surfaceID),
            surfaceVM.rootNode != nil || message.isStreaming
          {
            A2UIInlineSurfaceCard(
              surfaceID: surfaceID,
              surfaceViewModel: surfaceVM,
              catalogs: viewModel.catalogs,
              isStreaming: message.isStreaming,
              onInspect: { onInspectSurface(surfaceID) }
            )
          }
        }
      }
    }
  }
}

// MARK: - Inline A2UI Surface Container

private struct A2UIInlineSurfaceCard: View {
  let surfaceID: String
  let surfaceViewModel: SurfaceViewModel
  let catalogs: [Catalog<ComponentImplementation>]
  let isStreaming: Bool
  let onInspect: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Surface Header Bar
      HStack(spacing: 8) {
        Image(systemName: "rectangle.3.group.bubble")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tint)

        Text(surfaceID)
          .font(.caption.monospaced().weight(.medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Spacer()

        Button(action: onInspect) {
          Label("Inspect JSON", systemImage: "curlybraces")
            .font(.caption2.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.mini)
        .accessibilityIdentifier("a2ui.inspect.\(surfaceID)")
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(.quaternary.opacity(0.45))

      Divider()

      // Live Interactive A2UI Surface
      if surfaceViewModel.rootNode != nil {
        A2UISwiftUI.Surface(
          viewModel: surfaceViewModel,
          catalogs: catalogs
        )
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
      } else if isStreaming {
        HStack(spacing: 8) {
          ProgressView()
            .controlSize(.small)
          Text("Assembling A2UI v1.0 component hierarchy…")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .background(.background.secondary)
    .clipShape(.rect(cornerRadius: 16))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .strokeBorder(.separator.opacity(0.6), lineWidth: 0.75)
    )
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("a2ui.surface.\(surfaceID)")
  }
}
