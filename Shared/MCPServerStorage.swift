import Foundation
import WidgetKit

/// Low-level, actor-agnostic persistence for the configured servers. Both the
/// observable store (UI) and App Intents read and write through here so an intent
/// always mutates the latest saved state rather than a stale in-memory copy.
enum MCPServerStorage {
  static let key = "configured_servers"

  static func load() -> [MCPServer] {
    guard let data = AppGroup.defaults.data(forKey: key) else { return [] }
    return (try? JSONDecoder().decode([MCPServer].self, from: data)) ?? []
  }

  static func save(_ servers: [MCPServer]) {
    if let data = try? JSONEncoder().encode(servers) {
      AppGroup.defaults.set(data, forKey: key)
    }
    WidgetCenter.shared.reloadAllTimelines()
  }

  /// Read-modify-write a single server by id, used by intents to avoid clobbering
  /// concurrent edits made in the UI.
  static func upsert(_ server: MCPServer) {
    var servers = load()
    if let index = servers.firstIndex(where: { $0.id == server.id }) {
      servers[index] = server
    } else {
      servers.append(server)
    }
    save(servers)
  }

  static func server(named name: String) -> MCPServer? {
    load().first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
  }
}
