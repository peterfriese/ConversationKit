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

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

extension View {
  func roundedCorner(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

public struct MessageView: View {
  let message: String?
  let imageURL: String?
  let fullWidth: Bool = false
  let participant: Participant

  public var body: some View {
    HStack(alignment: .top) {
      if participant == .user {
        Spacer()
      }
      else {
        Image(systemName: "cloud.circle.fill")
          .font(.title)
      }
      VStack(alignment: participant == .user ? .trailing : .leading) {
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
//            .frame(width: .infinity, height: .infinity, alignment: .center)
            .cornerRadius(8.0)
          }
        }
        if let message {
          Markdown(message)
//          Text(message)
        }
      }
      .padding()
      .if(fullWidth) { view in
        view.frame(maxWidth: .infinity, alignment: .leading)
      }
      .background {
        Color(uiColor: participant == .other
              ? .secondarySystemBackground
              : .systemGray4)
      }
      .roundedCorner(8, corners: participant == .other ? .topLeft : .topRight)
      .roundedCorner(20, corners: participant == .other ? [.topRight, .bottomLeft, .bottomRight] : [.topLeft, .bottomLeft, .bottomRight])
      if participant == .other {
        Spacer()
      }
      else {
        Image(systemName: "person.circle.fill")
          .font(.title)
      }
    }
    .listRowSeparator(.hidden)
  }
}
