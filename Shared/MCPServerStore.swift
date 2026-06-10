import SwiftUI
import WidgetKit

/// Observable source of truth for the configured MCP servers, backed by the
/// shared App Group store. The UI binds to this; it reloads when the app becomes
/// active so changes made by App Intents (which write directly to storage) appear.
@MainActor
@Observable
final class MCPServerStore {
  private(set) var servers: [MCPServer]

  init() {
    servers = MCPServerStorage.load()
  }

  func reload() {
    servers = MCPServerStorage.load()
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
  }
}
