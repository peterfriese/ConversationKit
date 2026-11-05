//
//  ContentView.swift
//  A2UIConversationDemo
//
//  Main ConversationKit v2 + A2UI v1.0 host view with Liquid Glass composer styles,
//  Gemini 3 / Local A2A model switching, slash commands, and surface inspector sheets.
//

import ConversationKit
import SwiftUI

public enum ComposerGlassStylePreset: String, CaseIterable, Identifiable {
  case cardGlass = "Card Glass"
  case classicGlass = "Classic Glass"
  case compactGlass = "Compact Glass"

  public var id: String { rawValue }

  public var anyStyle: AnyMessageComposerStyle {
    switch self {
    case .cardGlass:
      return AnyMessageComposerStyle(.cardGlass)
    case .classicGlass:
      return AnyMessageComposerStyle(.classicGlass)
    case .compactGlass:
      return AnyMessageComposerStyle(.compactGlass)
    }
  }
}

private struct InspectedSurfaceTarget: Identifiable {
  let id: String
}

public struct ContentView: View {
  @State private var viewModel = A2UIConversationViewModel()
  @State private var composerStyle: ComposerGlassStylePreset = .cardGlass
  @State private var showingCatalogSheet = false
  @State private var inspectedSurface: InspectedSurfaceTarget?

  public init() {}

  private var activeSuggestions: [PromptSuggestion] {
    viewModel.messages.count <= 1
      ? A2UIDemoPresets.starterSuggestions
      : A2UIDemoPresets.followUpSuggestions
  }

  public var body: some View {
    NavigationStack {
      ConversationView(
        messages: $viewModel.messages,
        attachments: $viewModel.attachments
      ) { message in
        A2UIMessageRowView(
          message: message,
          viewModel: viewModel,
          onInspectSurface: { surfaceID in
            inspectedSurface = InspectedSurfaceTarget(id: surfaceID)
          }
        )
      }
      .onSendMessage { submission in
        await viewModel.sendSubmission(submission)
      }
      .messageComposerStyle(composerStyle.anyStyle)
      .thinkingStateStyle(.collapsibleHeader)
      .userMessageBubbleStyle(.tailedBubble)
      .composerModels(
        A2UIDemoPresets.availableModels,
        selection: $viewModel.selectedModel
      )
      .slashCommands(A2UIDemoPresets.slashCommands)
      .suggestionChips(activeSuggestions, handoff: .immediateSend)
      .navigationTitle("A2UI × ConversationKit")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          Button {
            showingCatalogSheet = true
          } label: {
            Label("Catalog & A2A", systemImage: "square.grid.2x2")
          }
          .accessibilityIdentifier("toolbar.catalogButton")

          Menu {
            Picker("Composer Style", selection: $composerStyle) {
              ForEach(ComposerGlassStylePreset.allCases) { preset in
                Text(preset.rawValue).tag(preset)
              }
            }

            Divider()

            Button(role: .destructive) {
              viewModel.resetConversation()
            } label: {
              Label("Reset Conversation", systemImage: "arrow.counterclockwise")
            }
          } label: {
            Label("Options", systemImage: "slider.horizontal.3")
          }
          .accessibilityIdentifier("toolbar.optionsMenu")
        }
      }
      .sheet(isPresented: $showingCatalogSheet) {
        A2UICatalogAndSettingsSheet(viewModel: viewModel)
      }
      .sheet(item: $inspectedSurface) { target in
        A2UISurfaceInspectorSheet(
          surfaceID: target.id,
          viewModel: viewModel
        )
      }
    }
  }
}

#Preview {
  ContentView()
}
