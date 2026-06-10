import AppIntents

/// Exposes a configured MCP server to the App Intents system so it can be chosen
/// in the Shortcuts app and by Siri.
struct MCPServerEntity: AppEntity {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "MCP Server")
  static let defaultQuery = MCPServerQuery()

  var id: UUID
  var name: String
  var host: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)", subtitle: "\(host)")
  }
}

extension MCPServer {
  var entity: MCPServerEntity {
    MCPServerEntity(id: id, name: name, host: host)
  }
}

struct MCPServerQuery: EntityQuery {
  func entities(for identifiers: [UUID]) async throws -> [MCPServerEntity] {
    MCPServerStorage.load().filter { identifiers.contains($0.id) }.map(\.entity)
  }

  func suggestedEntities() async throws -> [MCPServerEntity] {
    MCPServerStorage.load().map(\.entity)
  }

  func defaultResult() async -> MCPServerEntity? {
    MCPServerStorage.load().first?.entity
  }
}
