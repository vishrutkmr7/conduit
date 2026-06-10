import SwiftUI
import WidgetKit

/// Observable source of truth for the configured MCP servers, backed by the
/// shared App Group store. The UI binds to this; it reloads when the app becomes
/// active so changes made by App Intents (which write directly to storage) appear.
@MainActor
@Observable
final class MCPServerStore {
  private(set) var servers: [MCPServer]
  /// Latest connection health per server, mirrored from the shared store so the UI
  /// can show the same colored status the widgets do.
  private(set) var health: [UUID: ServerHealthRecord]

  init() {
    servers = MCPServerStorage.load()
    health = ServerHealthStore.load()
  }

  func reload() {
    servers = MCPServerStorage.load()
    health = ServerHealthStore.load()
  }

  func health(for server: MCPServer) -> ServerHealth {
    health[server.id]?.health ?? .unknown
  }

  /// Tools advertised by the server on its last successful connection, if known.
  func toolCount(for server: MCPServer) -> Int? {
    health[server.id]?.toolCount
  }

  /// Re-checks every server's reachability and refreshes the published health.
  func refreshHealth() async {
    await ServerHealthChecker.checkAll(servers)
    health = ServerHealthStore.load()
  }

  func contains(_ urlString: String) -> Bool {
    servers.contains { $0.urlString == urlString }
  }

  func add(_ server: MCPServer) {
    guard !servers.contains(where: { $0.id == server.id }) else {
      update(server)
      return
    }
    servers.append(server)
    persist()
  }

  func update(_ server: MCPServer) {
    guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }
    servers[index] = server
    persist()
  }

  func remove(_ server: MCPServer) {
    servers.removeAll { $0.id == server.id }
    persist()
  }

  func remove(atOffsets offsets: IndexSet) {
    servers.remove(atOffsets: offsets)
    persist()
  }

  private func persist() {
    MCPServerStorage.save(servers)
    ServerHealthStore.prune(keeping: servers.map(\.id))
    health = ServerHealthStore.load()
  }
}
