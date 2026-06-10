import AppIntents
import CoreSpotlight
import UniformTypeIdentifiers

/// Exposes a configured MCP server to the App Intents system so it can be chosen
/// in the Shortcuts app and by Siri. Conforming to `IndexedEntity` also lets each
/// server be indexed into Spotlight so it's searchable by name.
struct MCPServerEntity: AppEntity, IndexedEntity {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "MCP Server")
  static let defaultQuery = MCPServerQuery()

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
    attributes.contentDescription = "MCP server · \(host)"
    attributes.keywords = ["MCP", "server", name, host]
    return attributes
  }
}

/// Keeps Spotlight's index in sync with the configured servers.
enum ServerSpotlightIndexer {
  static func reindex() async {
    let entities = MCPServerStorage.load().map(\.entity)
    try? await CSSearchableIndex.default().indexAppEntities(entities)
  }
}

extension MCPServer {
  var entity: MCPServerEntity {
    MCPServerEntity(id: id, name: name, host: host, symbol: symbol)
  }
}

/// The configured servers are few and stored locally, so we expose the full set
/// to the system. Conforming to `EnumerableEntityQuery` keeps the parameterized
/// App Shortcut phrases in sync, and `EntityStringQuery` lets Siri match a server
/// the user names out loud.
struct MCPServerQuery: EnumerableEntityQuery, EntityStringQuery {
  func allEntities() async throws -> [MCPServerEntity] {
    MCPServerStorage.load().map(\.entity)
  }

  func entities(for identifiers: [UUID]) async throws -> [MCPServerEntity] {
    MCPServerStorage.load().filter { identifiers.contains($0.id) }.map(\.entity)
  }

  func entities(matching string: String) async throws -> [MCPServerEntity] {
    MCPServerStorage.load()
      .filter { $0.name.localizedCaseInsensitiveContains(string) || $0.host.localizedCaseInsensitiveContains(string) }
      .map(\.entity)
  }

  func defaultResult() async -> MCPServerEntity? {
    MCPServerStorage.load().first?.entity
  }
}
