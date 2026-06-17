import Foundation
import SwiftUI
import WidgetKit

//
//  ServerHealth.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

/// Connection health for a server, surfaced as a colored status dot in the app
/// and the widgets. Green = connected, yellow = needs attention, red = issue.
nonisolated enum ServerHealth: String, Codable, Sendable {
  case unknown    // gray — never checked yet
  case connected  // green — reachable and ready
  case needsAuth  // yellow — missing or incomplete credentials
  case error      // red — failed to connect or returned an error

  var color: Color {
    switch self {
    case .unknown: .gray
    case .connected: .green
    case .needsAuth: .yellow
    case .error: .red
    }
  }

  var label: String {
    switch self {
    case .unknown: "Not checked"
    case .connected: "Connected"
    case .needsAuth: "Needs sign in"
    case .error: "Connection issue"
    }
  }

  var symbol: String {
    switch self {
    case .unknown: "questionmark.circle.fill"
    case .connected: "checkmark.circle.fill"
    case .needsAuth: "lock.fill"
    case .error: "exclamationmark.triangle.fill"
    }
  }
}

/// A single health reading for a server, with the time it was taken.
nonisolated struct ServerHealthRecord: Codable, Sendable {
  var health: ServerHealth
  var checkedAt: Date
  var detail: String?
  /// Number of tools the server advertised on the last successful connection.
  /// Optional so older stored records decode without it.
  var toolCount: Int?
}

/// Shared persistence for the latest health reading of each server, written by the
/// app and read by the widgets. Keyed by server id so the widget can color each tile.
nonisolated enum ServerHealthStore {
  static let key = "server_health"
  private static let repository = ConduitRepository()

  static func load() -> [UUID: ServerHealthRecord] {
    repository.healthRecords()
  }

  static func record(for id: UUID) -> ServerHealthRecord? { load()[id] }

  static func set(_ record: ServerHealthRecord, for id: UUID) {
    repository.setHealthRecords([id: record])
    WidgetCenter.shared.reloadAllTimelines()
  }

  static func save(_ records: [UUID: ServerHealthRecord]) {
    repository.setHealthRecords(records)
    WidgetCenter.shared.reloadAllTimelines()
  }

  /// Drops readings for servers that no longer exist.
  static func prune(keeping ids: [UUID]) {
    repository.pruneHealth(keeping: ids)
    WidgetCenter.shared.reloadAllTimelines()
  }
}

/// Performs lightweight connection checks and records the result so the colored
/// status follows the server's real reachability rather than just its credentials.
nonisolated enum ServerHealthChecker {
  @discardableResult
  static func check(_ server: MCPServer) async -> (UUID, ServerHealthRecord, [MCPTool]) {
    let health: ServerHealth
    var detail: String?
    var toolCount: Int?
    var discoveredTools: [MCPTool] = []

    if !server.isAuthenticated {
      health = .needsAuth
    } else {
      do {
        let tools = try await MCPClient(server: server).listTools()
        discoveredTools = tools
        toolCount = tools.count
        health = .connected
      } catch {
        health = .error
        detail = error.localizedDescription
      }
    }

    return (
      server.id,
      ServerHealthRecord(health: health, checkedAt: .now, detail: detail, toolCount: toolCount),
      discoveredTools
    )
  }

  /// Checks every server in parallel, then prunes stale readings.
  static func checkAll(_ servers: [MCPServer]) async {
    let (records, toolsByServer) = await withTaskGroup(of: (UUID, ServerHealthRecord, [MCPTool]).self) { group in
      for server in servers {
        group.addTask { await check(server) }
      }

      var records: [UUID: ServerHealthRecord] = [:]
      var toolsByServer: [UUID: [MCPTool]] = [:]
      for await (id, record, tools) in group {
        records[id] = record
        if !tools.isEmpty {
          toolsByServer[id] = tools
        }
      }
      return (records, toolsByServer)
    }
    for (serverID, tools) in toolsByServer {
      MCPServerStorage.replaceTools(tools, for: serverID)
    }
    ServerHealthStore.save(records)
    ServerHealthStore.prune(keeping: servers.map(\.id))
  }
}
