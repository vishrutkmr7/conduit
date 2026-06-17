import Foundation
import WidgetKit

//
//  MCPServerStorage.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

/// Low-level, actor-agnostic persistence for the configured servers. Both the
/// observable store, widgets, and App Intents read and write through here so an
/// intent always mutates the latest saved state rather than a stale in-memory copy.
nonisolated enum MCPServerStorage {
  static let key = "configured_servers"
  private static let repository = ConduitRepository()

  static func load(includeCredentials: Bool = true) -> [MCPServer] {
    repository.fetchServers(includeCredentials: includeCredentials)
  }

  static func save(_ servers: [MCPServer]) {
    repository.saveServers(servers)
    WidgetCenter.shared.reloadAllTimelines()
  }

  /// Read-modify-write a single server by id, used by intents to avoid clobbering
  /// concurrent edits made in the UI.
  static func upsert(_ server: MCPServer) {
    repository.upsertServer(server)
    WidgetCenter.shared.reloadAllTimelines()
  }

  static func remove(_ server: MCPServer) {
    repository.removeServer(server)
    WidgetCenter.shared.reloadAllTimelines()
  }

  static func server(named name: String) -> MCPServer? {
    repository.server(named: name)
  }

  static func server(id: UUID) -> MCPServer? {
    repository.server(id: id)
  }

  static func cachedTools(for serverID: UUID) -> [MCPTool] {
    repository.cachedTools(for: serverID)
  }

  static func tool(id: String) -> MCPTool? {
    repository.tool(id: id)
  }

  static func replaceTools(_ tools: [MCPTool], for serverID: UUID) {
    repository.replaceTools(tools, for: serverID)
    WidgetCenter.shared.reloadAllTimelines()
  }
}
