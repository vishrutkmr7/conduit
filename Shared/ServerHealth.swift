import Foundation
import SwiftUI
import WidgetKit

/// Connection health for a server, surfaced as a colored status dot in the app
/// and the widgets. Green = connected, yellow = needs attention, red = issue.
enum ServerHealth: String, Codable, Sendable {
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
struct ServerHealthRecord: Codable, Sendable {
  var health: ServerHealth
  var checkedAt: Date
  var detail: String?
  /// Number of tools the server advertised on the last successful connection.
  /// Optional so older stored records decode without it.
  var toolCount: Int?
}

/// Shared persistence for the latest health reading of each server, written by the
/// app and read by the widgets. Keyed by server id so the widget can color each tile.
enum ServerHealthStore {
  static let key = "server_health"

  static func load() -> [UUID: ServerHealthRecord] {
    guard let data = AppGroup.defaults.data(forKey: key) else { return [:] }
    return (try? JSONDecoder().decode([UUID: ServerHealthRecord].self, from: data)) ?? [:]
  }

  static func record(for id: UUID) -> ServerHealthRecord? { load()[id] }

  static func set(_ record: ServerHealthRecord, for id: UUID) {
    var all = load()
    all[id] = record
    save(all)
  }

  static func save(_ records: [UUID: ServerHealthRecord]) {
    if let data = try? JSONEncoder().encode(records) {
      AppGroup.defaults.set(data, forKey: key)
    }
    WidgetCenter.shared.reloadAllTimelines()
  }

  /// Drops readings for servers that no longer exist.
  static func prune(keeping ids: [UUID]) {
    let all = load()
    let kept = all.filter { ids.contains($0.key) }
    if kept.count != all.count { save(kept) }
  }
}

/// Performs lightweight connection checks and records the result so the colored
/// status follows the server's real reachability rather than just its credentials.
enum ServerHealthChecker {
  @discardableResult
  static func check(_ server: MCPServer) async -> ServerHealth {
    let health: ServerHealth
    var detail: String?
    var toolCount: Int?

    if !server.isAuthenticated {
      health = .needsAuth
    } else {
      do {
        let tools = try await MCPClient(server: server).listTools()
        toolCount = tools.count
        health = .connected
      } catch {
        health = .error
        detail = error.localizedDescription
      }
    }

    ServerHealthStore.set(
      ServerHealthRecord(health: health, checkedAt: .now, detail: detail, toolCount: toolCount),
      for: server.id
    )
    return health
  }

  /// Checks every server in parallel, then prunes stale readings.
  static func checkAll(_ servers: [MCPServer]) async {
    await withTaskGroup(of: Void.self) { group in
      for server in servers {
        group.addTask { _ = await check(server) }
      }
    }
    ServerHealthStore.prune(keeping: servers.map(\.id))
  }
}
