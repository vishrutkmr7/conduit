import SwiftUI

@main
struct ConduitApp: App {
  @State private var store = MCPServerStore()
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(store)
        .onChange(of: scenePhase) { _, phase in
          // App Intents write directly to shared storage, so refresh on activation.
          if phase == .active { store.reload() }
        }
    }
  }
}
