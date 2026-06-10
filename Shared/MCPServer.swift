import Foundation

/// How a remote MCP server expects the client to authenticate.
enum MCPAuthKind: String, Codable, CaseIterable, Identifiable, Sendable {
  case none
  case oauth
  case apiKey
  case bearer

  var id: String { rawValue }

  var label: String {
    switch self {
    case .none: "No authentication"
    case .oauth: "OAuth (in-app browser)"
    case .apiKey: "API key header"
    case .bearer: "Bearer token"
    }
  }

  var symbol: String {
    switch self {
    case .none: "lock.open"
    case .oauth: "person.badge.key"
    case .apiKey: "key"
    case .bearer: "key.horizontal"
    }
  }
}

/// A remote MCP server the user has configured in Conduit.
struct MCPServer: Codable, Identifiable, Hashable, Sendable {
  var id: UUID
  var name: String
  /// Endpoint for the streamable-HTTP MCP transport.
  var urlString: String
  var symbol: String
  var tint: String
  var authKind: MCPAuthKind
  /// Stored credential (API key, bearer, or OAuth access token) when present.
  var credential: String?
  /// Name of the header used for `apiKey` auth (e.g. `Authorization`, `X-Api-Key`).
  var headerName: String
  var isCustom: Bool
  var dateAdded: Date

  init(
    id: UUID = UUID(),
    name: String,
    urlString: String,
    symbol: String = "server.rack",
    tint: String = "teal",
    authKind: MCPAuthKind = .none,
    credential: String? = nil,
    headerName: String = "Authorization",
    isCustom: Bool = true,
    dateAdded: Date = .now
  ) {
    self.id = id
    self.name = name
    self.urlString = urlString
    self.symbol = symbol
    self.tint = tint
    self.authKind = authKind
    self.credential = credential
    self.headerName = headerName
    self.isCustom = isCustom
    self.dateAdded = dateAdded
  }

  var url: URL? { URL(string: urlString) }

  /// Whether the server has the credentials it needs to connect.
  var isAuthenticated: Bool {
    switch authKind {
    case .none: true
    case .oauth, .apiKey, .bearer: !(credential ?? "").isEmpty
    }
  }

  var host: String {
    url?.host() ?? urlString
  }
}
