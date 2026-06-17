import AppIntents
import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

//
//  ConduitEntities.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

struct ConduitServerEntity: AppEntity, IndexedEntity {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "MCP Server")
  static let defaultQuery = ConduitServerQuery()

  var id: UUID
  var name: String
  var host: String
  var symbol: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)", subtitle: "\(host)", image: .init(systemName: symbol))
  }

  var attributeSet: CSSearchableItemAttributeSet {
    let attributes = CSSearchableItemAttributeSet(contentType: .content)
    attributes.title = name
    attributes.contentDescription = "MCP server, \(host)"
    attributes.keywords = ["MCP", "server", name, host]
    return attributes
  }
}

struct ConduitToolEntity: AppEntity, IndexedEntity {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "MCP Tool")
  static let defaultQuery = ConduitToolQuery()

  var id: String
  var serverID: UUID
  var serverName: String
  var name: String
  var summary: String
  var risk: MCPToolRisk

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)", subtitle: "\(serverName)", image: .init(systemName: risk.symbol))
  }

  var attributeSet: CSSearchableItemAttributeSet {
    let attributes = CSSearchableItemAttributeSet(contentType: .content)
    attributes.title = name
    attributes.contentDescription = summary.isEmpty ? "MCP tool in \(serverName)" : summary
    attributes.keywords = ["MCP", "tool", serverName, name]
    return attributes
  }
}

nonisolated enum ServerSpotlightIndexer {
  static func reindex() async {
    let servers = MCPServerStorage.load(includeCredentials: false)
    let serverEntities = servers.map(\.entity)
    let toolEntities = servers.flatMap { server in
      MCPServerStorage.cachedTools(for: server.id).map { $0.entity(server: server) }
    }
    try? await CSSearchableIndex.default().indexAppEntities(serverEntities)
    try? await CSSearchableIndex.default().indexAppEntities(toolEntities)
  }
}

extension MCPServer {
  nonisolated var entity: ConduitServerEntity {
    ConduitServerEntity(id: id, name: name, host: host, symbol: symbol)
  }
}

extension MCPTool {
  nonisolated func entity(server: MCPServer) -> ConduitToolEntity {
    ConduitToolEntity(
      id: "\(server.id.uuidString)|\(name)",
      serverID: server.id,
      serverName: server.name,
      name: name,
      summary: summary,
      risk: risk
    )
  }
}

struct ConduitServerQuery: EnumerableEntityQuery, EntityStringQuery {
  func allEntities() async throws -> [ConduitServerEntity] {
    MCPServerStorage.load(includeCredentials: false).map(\.entity)
  }

  func entities(for identifiers: [UUID]) async throws -> [ConduitServerEntity] {
    let ids = Set(identifiers)
    return MCPServerStorage.load(includeCredentials: false)
      .filter { ids.contains($0.id) }
      .map(\.entity)
  }

  func entities(matching string: String) async throws -> [ConduitServerEntity] {
    MCPServerStorage.load(includeCredentials: false)
      .filter { $0.name.localizedStandardContains(string) || $0.host.localizedStandardContains(string) }
      .map(\.entity)
  }

  func defaultResult() async -> ConduitServerEntity? {
    MCPServerStorage.load(includeCredentials: false).first?.entity
  }
}

struct ConduitToolQuery: EnumerableEntityQuery, EntityStringQuery {
  func allEntities() async throws -> [ConduitToolEntity] {
    MCPServerStorage.load(includeCredentials: false).flatMap { server in
      MCPServerStorage.cachedTools(for: server.id).map { $0.entity(server: server) }
    }
  }

  func entities(for identifiers: [String]) async throws -> [ConduitToolEntity] {
    let ids = Set(identifiers)
    return try await allEntities().filter { ids.contains($0.id) }
  }

  func entities(matching string: String) async throws -> [ConduitToolEntity] {
    try await allEntities().filter {
      $0.name.localizedStandardContains(string)
        || $0.serverName.localizedStandardContains(string)
        || $0.summary.localizedStandardContains(string)
    }
  }

  func defaultResult() async -> ConduitToolEntity? {
    try? await allEntities().first
  }
}
