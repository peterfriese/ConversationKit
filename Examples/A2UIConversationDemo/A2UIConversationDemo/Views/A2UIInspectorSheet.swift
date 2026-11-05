//
//  A2UIInspectorSheet.swift
//  A2UIConversationDemo
//
//  Interactive inspector for live A2UI DataModel state, raw protocol messages,
//  dispatched action logs, A2A server configuration, and the 35+ bundled v1.0 catalog examples.
//

import Combine
import SwiftUI

public struct A2UISurfaceInspectorSheet: View {
  public let surfaceID: String
  public let viewModel: A2UIConversationViewModel

  @Environment(\.dismiss) private var dismiss
  @State private var liveDataModelText: String = "{}"
  @State private var selectedTab: InspectorTab = .dataModel

  private enum InspectorTab: String, CaseIterable, Identifiable {
    case dataModel = "Data Model"
    case protocolMessages = "A2UI Messages"
    case actionLogs = "Event Log"

    var id: String { rawValue }
  }

  public init(surfaceID: String, viewModel: A2UIConversationViewModel) {
    self.surfaceID = surfaceID
    self.viewModel = viewModel
  }

  private var matchingRawMessages: [String] {
    viewModel.messages
      .first(where: { $0.surfaceIDs.contains(surfaceID) })?
      .rawA2UIMessages ?? []
  }

  public var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        Picker("Inspector Tab", selection: $selectedTab) {
          ForEach(InspectorTab.allCases) { tab in
            Text(tab.rawValue).tag(tab)
          }
        }
        .pickerStyle(.segmented)
        .padding()

        Divider()

        switch selectedTab {
        case .dataModel:
          ScrollView {
            VStack(alignment: .leading, spacing: 12) {
              Text("Live Bound `DataModel` for `\(surfaceID)`")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

              Text(liveDataModelText)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.background.secondary)
                .clipShape(.rect(cornerRadius: 12))
            }
            .padding()
          }

        case .protocolMessages:
          List {
            ForEach(Array(matchingRawMessages.enumerated()), id: \.offset) { index, rawJSON in
              VStack(alignment: .leading, spacing: 6) {
                Text("Step \(index + 1)")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.secondary)
                Text(prettyPrintedJSON(rawJSON))
                  .font(.system(.caption2, design: .monospaced))
                  .textSelection(.enabled)
              }
              .padding(.vertical, 4)
            }
          }
          .listStyle(.insetGrouped)

        case .actionLogs:
          A2UIEventLogListView(logs: viewModel.eventLogs)
        }
      }
      .navigationTitle(surfaceID)
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
      .onAppear {
        liveDataModelText = viewModel.formattedDataModelJSON(for: surfaceID)
      }
    }
  }

  private func prettyPrintedJSON(_ raw: String) -> String {
    guard
      let data = raw.data(using: .utf8),
      let obj = try? JSONSerialization.jsonObject(with: data),
      let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
      let str = String(data: pretty, encoding: .utf8)
    else {
      return raw
    }
    return str
  }
}

// MARK: - Catalog Browser & A2A Settings Sheet

public struct A2UICatalogAndSettingsSheet: View {
  @Bindable public var viewModel: A2UIConversationViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var searchText: String = ""

  public init(viewModel: A2UIConversationViewModel) {
    self.viewModel = viewModel
  }

  private var filteredExamples: [BundledA2UIExample] {
    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return viewModel.bundledExamples
    }
    let query = searchText.lowercased()
    return viewModel.bundledExamples.filter {
      $0.title.lowercased().contains(query)
        || $0.slug.lowercased().contains(query)
        || $0.summary.lowercased().contains(query)
    }
  }

  public var body: some View {
    NavigationStack {
      List {
        Section("Local A2A Agent Server") {
          TextField("http://localhost:10002", text: $viewModel.a2aServerURL)
            .font(.system(.subheadline, design: .monospaced))
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            #endif
            .autocorrectionDisabled()

          Text("Used when **Local A2UI Agent (A2A)** is selected in the composer model pill.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        if !viewModel.eventLogs.isEmpty {
          Section("Recent A2UI Surface Events (\(viewModel.eventLogs.count))") {
            ForEach(viewModel.eventLogs.prefix(5)) { entry in
              VStack(alignment: .leading, spacing: 4) {
                HStack {
                  Text(entry.kind.rawValue)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.kind == .error ? Color.red.opacity(0.15) : Color.accentColor.opacity(0.15), in: .capsule)
                  Text(entry.surfaceID)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                }
                Text(entry.summary)
                  .font(.caption)
              }
            }
          }
        }

        Section("Bundled A2UI v1.0 Basic Catalog (\(filteredExamples.count))") {
          ForEach(filteredExamples) { example in
            Button {
              let chosen = example
              dismiss()
              Task { @MainActor in
                await viewModel.sendBundledExample(chosen)
              }
            } label: {
              VStack(alignment: .leading, spacing: 4) {
                HStack {
                  Text(example.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                  Spacer()
                  Text("\(example.rawMessages.count) msgs")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                }
                Text(example.summary)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(2)
              }
              .padding(.vertical, 2)
            }
          }
        }
      }
      .searchable(text: $searchText, prompt: "Filter A2UI v1.0 catalog surfaces...")
      .navigationTitle("A2UI Catalog & Settings")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

// MARK: - Shared Event Log List

private struct A2UIEventLogListView: View {
  let logs: [A2UIEventLog]

  var body: some View {
    if logs.isEmpty {
      ContentUnavailableView(
        "No Surface Events Yet",
        systemImage: "bolt.horizontal.circle",
        description: Text("Interact with buttons or inputs on any A2UI surface to inspect dispatched events.")
      )
    } else {
      List(logs) { entry in
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text(entry.kind.rawValue)
              .font(.caption2.weight(.bold))
            Text("· \(entry.surfaceID)")
              .font(.caption2.monospaced())
              .foregroundStyle(.secondary)
            Spacer()
            Text(entry.timestamp, style: .time)
              .font(.caption2)
              .foregroundStyle(.tertiary)
          }
          Text(entry.summary)
            .font(.caption.weight(.medium))
          if let payload = entry.payloadJSON {
            Text(payload)
              .font(.system(.caption2, design: .monospaced))
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
          }
        }
        .padding(.vertical, 4)
      }
    }
  }
}
