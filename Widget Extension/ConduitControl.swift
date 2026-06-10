import WidgetKit
import SwiftUI
import AppIntents

/// A Control Center control that opens Conduit to manage MCP servers.
struct ConduitControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "app.bitrig.vishrutjha.conduit.open-control") {
      ControlWidgetButton(action: OpenConduitIntent()) {
        Label("Conduit", systemImage: "point.3.connected.trianglepath.dotted")
      }
    }
    .displayName("Open Conduit")
    .description("Open Conduit to manage your MCP servers.")
  }
}
