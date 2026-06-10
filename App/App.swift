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
        .task { ConduitShortcuts.updateAppShortcutParameters() }
        .onChange(of: store.servers) {
          // Refresh the per-server App Shortcut phrases when the list changes.
          ConduitShortcuts.updateAppShortcutParameters()
        }
        .onChange(of: scenePhase) { _, phase in
          // App Intents write directly to shared storage, so refresh on activation.
          if phase == .active { store.reload() }
        }
    }
  }
}
