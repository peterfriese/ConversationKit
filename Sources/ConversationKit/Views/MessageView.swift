//
// MessageView.swift
// ConversationKit
//
// Created by Peter Friese on 04.07.25.
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
import MarkdownUI

public struct MessageView: View {
  @Environment(\.presentErrorAction) var presentErrorAction

  let message: String?
  let imageURL: String?
  let fullWidth: Bool = false
  let participant: Participant
  let error: Error?

  public init(message: String?, imageURL: String?, participant: Participant, error: Error? = nil) {
    self.message = message
    self.imageURL = imageURL
    self.participant = participant
    self.error = error
  }

  public var body: some View {
    HStack(alignment: .top) {
      if participant == .user {
        Spacer()
      }
      else {
        Image(systemName: "sparkles")
          .font(.title2)
          .foregroundColor(.accentColor)
      }
      VStack(alignment: participant == .user ? .trailing : .leading) {
        if let error {
          HStack {
            Text("An error occurred.")
            Button("More information", systemImage: "info.circle") {
              presentErrorAction?(error)
            }
            .labelStyle(.iconOnly)
          }
          .padding()
        }
        else {
          if let imageURL {
            if let url = URL(string: imageURL) {
              Spacer()
              AsyncImage(url: url) { phase in
                if let image = phase.image {
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                  Image(systemName: "icloud.slash")
                } else {
                  ProgressView()
                }
              }
              .cornerRadius(8.0)
            }
          }
          if let message, !message.isEmpty {
            Markdown(message)
              .if(participant == .user) { view in
                view.padding()
              }
          } else if participant == .other {
            // Loading state for AI messages
            TypingIndicator()
          }
        }
      }
      .if(fullWidth) { view in
        view.frame(maxWidth: .infinity, alignment: .leading)
      }
      .if(participant == .user) { view in
        view
          .background(Color.platformGray4)
          .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 20,
            bottomLeadingRadius: 20,
            bottomTrailingRadius: 8,
            topTrailingRadius: 20
          ))
      }
      if participant == .other {
        Spacer()
      }
    }
    .listRowSeparator(.hidden)
  }
}

struct TypingIndicator: View {
  @State private var offset: CGFloat = 0

  var body: some View {
    HStack(spacing: 4) {
      Circle()
        .fill(Color.secondary)
        .frame(width: 6, height: 6)
        .offset(y: offset)
        .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.0), value: offset)
      Circle()
        .fill(Color.secondary)
        .frame(width: 6, height: 6)
        .offset(y: offset)
        .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.2), value: offset)
      Circle()
        .fill(Color.secondary)
        .frame(width: 6, height: 6)
        .offset(y: offset)
        .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.4), value: offset)
    }
    .padding(.vertical, 8)
    .onAppear {
      offset = -4
    }
  }
}
