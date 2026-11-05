//
//  A2UIConversationDemoApp.swift
//  A2UIConversationDemo
//
//  Main entry point for the A2UI + ConversationKit v2 showcase app.
//

import SwiftUI

@main
struct A2UIConversationDemoApp: App {
  init() {
    A2UIConversationViewModel.configureFirebaseIfNeeded()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
