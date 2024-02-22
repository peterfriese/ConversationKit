//
// SwiftUIView.swift
//
//
// Created by Peter Friese on 22.02.24.
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

struct SwiftUIView: View {
  let message: String = "Officia cupidatat voluptate laboris consequat irure cillum. Consequat cillum adipisicing aute anim. Lorem consequat reprehenderit esse esse nostrud labore. Nostrud ullamco magna nostrud ullamco do officia. Ut eu esse aute excepteur duis cupidatat velit tempor excepteur laborum anim laborum."
  @State private var visibleText = ""
  @State private var dotOffset: CGFloat = 0

  var body: some View {
    VStack(alignment: .leading) {
      Text(visibleText)
      HStack(spacing: 4) { // Typing Indicator Dots
        ForEach(0..<3) { index in
          Circle()
            .fill(Color.gray)
            .frame(width: 6, height: 6)
            .offset(y: dotOffset)
//            .animation(Animation.easeInOut(duration: 0.4)
//              .repeatForever()
//              .delay(Double(index) * 0.2), value: true)
        }
      }
    }
    .onAppear {
      animateTextReveal()
    }
  }

  private func animateTextReveal() {
    for (index, character) in message.enumerated() {
      DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) {
        visibleText.append(character) // Adjust delay (0.08) for desired speed
      }
    }
  }
}

#Preview {
  SwiftUIView()
}
