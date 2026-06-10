import Foundation

/// Shared App Group used by the app, its App Intents, and the widget extension to
/// read and write the list of configured MCP servers.
enum AppGroup {
  static let id = "group.app.bitrig.new.ab738821-49ee-4307-a78e-c657a08541a1"

  static var defaults: UserDefaults {
    UserDefaults(suiteName: id) ?? .standard
  }
}
