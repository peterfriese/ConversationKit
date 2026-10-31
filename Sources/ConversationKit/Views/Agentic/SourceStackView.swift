//
// SourceStackView.swift
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

/// Renders a stacked source badge pill that expands to reveal grounded citation cards (`FR-3.4`, `AC-13`).
///
/// Enforces URL scheme allowlisting via `Citation.safeWebURL` (`http`/`https` only per `[SF-2]`).
public struct SourceStackView: View {
  public let citations: [Citation]

  @State private var isExpanded: Bool = false

  public init(citations: [Citation]) {
    self.citations = citations
  }

  /// Deterministically formats the collapsed source count badge title (`AC-13`).
  public static func badgeTitle(for citations: [Citation]) -> String {
    let noun = citations.count == 1 ? "source" : "sources"
    return "\(citations.count) \(noun)"
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button {
        withAnimation(.snappy(duration: 0.25)) {
          isExpanded.toggle()
        }
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "link")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)

          Text(Self.badgeTitle(for: citations))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)

          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.platformSecondaryBackground)
        .clipShape(Capsule())
        .overlay(
          Capsule()
            .stroke(Color.platformSeparator, lineWidth: 0.5)
        )
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("source_stack_toggle")

      if isExpanded {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(Array(citations.enumerated()), id: \.element.id) { index, citation in
            citationCard(for: citation, index: index + 1)
          }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("source_stack_view")
  }

  @ViewBuilder
  private func citationCard(for citation: Citation, index: Int) -> some View {
    if let safeURL = citation.safeWebURL {
      Link(destination: safeURL) {
        citationCardBody(for: citation, index: index, isInteractive: true)
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("citation_card_\(citation.id)")
    } else {
      citationCardBody(for: citation, index: index, isInteractive: false)
        .accessibilityIdentifier("citation_card_\(citation.id)")
    }
  }

  private func citationCardBody(
    for citation: Citation,
    index: Int,
    isInteractive: Bool
  ) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Text("[\(index)]")
        .font(.system(.caption2, design: .monospaced).weight(.semibold))
        .foregroundStyle(Color.accentColor)

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(citation.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)

          if isInteractive {
            Image(systemName: "arrow.up.right.square")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }

        if let domain = citation.domain, !domain.isEmpty {
          Text(domain)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }

        if let snippet = citation.snippet, !snippet.isEmpty {
          Text(snippet)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(10)
    .background(Color.platformSecondaryBackground)
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(Color.platformSeparator, lineWidth: 0.5)
    )
  }
}

#Preview {
  SourceStackView(
    citations: [
      Citation(
        id: "1",
        title: "SwiftUI ScrollViewReader Documentation",
        url: URL(string: "https://developer.apple.com/documentation/swiftui/scrollviewreader"),
        snippet: "A view that provides programmatic scrolling by working with a proxy."
      ),
      Citation(
        id: "2",
        title: "Local Untrusted Reference",
        url: URL(string: "javascript:alert(1)"),
        snippet: "Non-http/https links are rendered as non-interactive cards."
      )
    ]
  )
  .padding()
}
