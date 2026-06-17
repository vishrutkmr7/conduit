//
//  App.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

import SwiftUI
import AppIntents

@main
struct ConduitApp: App {
  @State private var store = MCPServerStore()
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(store)
        .task(id: store.servers) {
          // Refresh the per-server App Shortcut phrases and Spotlight index,
          // debouncing rapid edits so frequent server changes don't repeatedly
          // hit the main actor.
          try? await Task.sleep(for: .milliseconds(500))
          guard !Task.isCancelled else { return }
          ConduitShortcuts.updateAppShortcutParameters()
          await ServerSpotlightIndexer.reindex()
        }
        .onChange(of: scenePhase) { _, phase in
          // App Intents write directly to shared storage, so refresh on activation.
          if phase == .active { store.reload() }
        }
    }
  }
}
