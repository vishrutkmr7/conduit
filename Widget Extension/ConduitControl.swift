import WidgetKit
import SwiftUI
import AppIntents

/// A Control Center control that opens Conduit to manage MCP servers.
struct ConduitControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "app.bitrig.new.ab738821-49ee-4307-a78e-c657a08541a1.open-control") {
      ControlWidgetButton(action: OpenConduitIntent()) {
        Label("Conduit", systemImage: "point.3.connected.trianglepath.dotted")
      }
    }
    .displayName("Open Conduit")
    .description("Open Conduit to manage your MCP servers.")
  }
}
