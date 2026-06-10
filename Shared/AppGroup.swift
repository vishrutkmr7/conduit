import Foundation

/// Shared App Group used by the app, its App Intents, and the widget extension to
/// read and write the list of configured MCP servers.
enum AppGroup {
  static let id = "group.app.bitrig.vishrutjha.conduit"

  static var defaults: UserDefaults {
    UserDefaults(suiteName: id) ?? .standard
  }
}
