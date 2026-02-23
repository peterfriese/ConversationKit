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

/// Cross-platform corner specification replacing UIRectCorner.
struct RectCorner: OptionSet, Sendable {
  let rawValue: Int
  static let topLeft = RectCorner(rawValue: 1 << 0)
  static let topRight = RectCorner(rawValue: 1 << 1)
  static let bottomLeft = RectCorner(rawValue: 1 << 2)
  static let bottomRight = RectCorner(rawValue: 1 << 3)
  static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

/// Cross-platform rounded corner shape using pure SwiftUI Path.
struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: RectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let tl = corners.contains(.topLeft) ? radius : 0
    let tr = corners.contains(.topRight) ? radius : 0
    let bl = corners.contains(.bottomLeft) ? radius : 0
    let br = corners.contains(.bottomRight) ? radius : 0

    var path = Path()
    path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
    path.addArc(
      tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
      tangent2End: CGPoint(x: rect.maxX, y: rect.minY + tr),
      radius: tr)
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
    path.addArc(
      tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
      tangent2End: CGPoint(x: rect.maxX - br, y: rect.maxY),
      radius: br)
    path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
    path.addArc(
      tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
      tangent2End: CGPoint(x: rect.minX, y: rect.maxY - bl),
      radius: bl)
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
    path.addArc(
      tangent1End: CGPoint(x: rect.minX, y: rect.minY),
      tangent2End: CGPoint(x: rect.minX + tl, y: rect.minY),
      radius: tl)
    return path
  }
}

extension View {
  func roundedCorner(_ radius: CGFloat, corners: RectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

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
        Image(systemName: "cloud.circle.fill")
          .font(.title)
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
          if let message {
            Markdown(message)
          }
        }
      }
      .padding()
      .if(fullWidth) { view in
        view.frame(maxWidth: .infinity, alignment: .leading)
      }
      .background {
        participant == .other
          ? Color.platformSecondaryBackground
          : Color.platformGray4
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
