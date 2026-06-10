import Foundation

/// A description of a tool advertised by a remote MCP server.
struct MCPTool: Identifiable, Hashable, Sendable {
  var id: String { name }
  var name: String
  var description: String
  /// Raw JSON schema string for the tool's arguments, when provided.
  var schema: String?
}

enum MCPClientError: LocalizedError {
  case badURL
  case transport(String)
  case rpc(String)
  case decoding

  var errorDescription: String? {
    switch self {
    case .badURL: "The server URL is not valid."
    case .transport(let message): message
    case .rpc(let message): message
    case .decoding: "The server returned an unexpected response."
    }
  }
}

/// Minimal client for the MCP "streamable HTTP" transport: JSON-RPC requests are
/// POSTed to the endpoint and responses arrive as JSON or an SSE stream.
actor MCPClient {
  private let server: MCPServer
  private var sessionID: String?
  private var nextID = 1

  init(server: MCPServer) {
    self.server = server
  }

  /// Connects, negotiates a session, and returns the tools the server exposes.
  func listTools() async throws -> [MCPTool] {
    try await initializeIfNeeded()
    let result = try await send(method: "tools/list", params: [:])
    guard let tools = result["tools"] as? [[String: Any]] else { return [] }
    return tools.map { tool in
      let schemaData = (tool["inputSchema"]).flatMap { try? JSONSerialization.data(withJSONObject: $0) }
      return MCPTool(
        name: tool["name"] as? String ?? "tool",
        description: tool["description"] as? String ?? "",
        schema: schemaData.flatMap { String(data: $0, encoding: .utf8) }
      )
    }
  }

  /// Calls a tool with the given arguments and returns its textual result.
  func callTool(_ name: String, arguments: [String: Any]) async throws -> String {
    try await initializeIfNeeded()
    let result = try await send(method: "tools/call", params: [
      "name": name,
      "arguments": arguments
    ])
    guard let content = result["content"] as? [[String: Any]] else {
      return Self.prettyPrinted(result)
    }
    let text = content.compactMap { $0["text"] as? String }.joined(separator: "\n")
    return text.isEmpty ? Self.prettyPrinted(result) : text
  }

  // MARK: - Transport

  private func initializeIfNeeded() async throws {
    guard sessionID == nil else { return }
    _ = try await send(method: "initialize", params: [
      "protocolVersion": "2025-06-18",
      "capabilities": [:],
      "clientInfo": ["name": "Conduit", "version": "1.0"]
    ])
    // Notify the server that initialization is complete (fire-and-forget).
    try? await notify(method: "notifications/initialized")
  }

  private func send(method: String, params: [String: Any]) async throws -> [String: Any] {
    let id = nextID
    nextID += 1
    let body: [String: Any] = ["jsonrpc": "2.0", "id": id, "method": method, "params": params]
    let (data, response) = try await perform(body: body)

    if let http = response as? HTTPURLResponse,
       let session = http.value(forHTTPHeaderField: "Mcp-Session-Id") {
      sessionID = session
    }

    guard let json = Self.decodeRPC(data) else { throw MCPClientError.decoding }
    if let error = json["error"] as? [String: Any] {
      throw MCPClientError.rpc(error["message"] as? String ?? "Unknown server error.")
    }
    return json["result"] as? [String: Any] ?? [:]
  }

  private func notify(method: String) async throws {
    let body: [String: Any] = ["jsonrpc": "2.0", "method": method]
    _ = try await perform(body: body)
  }

  private func perform(body: [String: Any]) async throws -> (Data, URLResponse) {
    guard let url = server.url else { throw MCPClientError.badURL }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 30
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
    if let sessionID {
      request.setValue(sessionID, forHTTPHeaderField: "Mcp-Session-Id")
    }
    applyAuth(to: &request)
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
        throw MCPClientError.transport("Server responded with status \(http.statusCode).")
      }
      return (data, response)
    } catch let error as MCPClientError {
      throw error
    } catch {
      throw MCPClientError.transport(error.localizedDescription)
    }
  }

  private func applyAuth(to request: inout URLRequest) {
    guard let credential = server.credential, !credential.isEmpty else { return }
    switch server.authKind {
    case .none:
      break
    case .oauth, .bearer:
      request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization")
    case .apiKey:
      let value = server.headerName.caseInsensitiveCompare("Authorization") == .orderedSame
        ? "Bearer \(credential)" : credential
      request.setValue(value, forHTTPHeaderField: server.headerName)
    }
  }

  // MARK: - Parsing

  /// Handles both a plain JSON-RPC body and an SSE stream containing `data:` lines.
  private static func decodeRPC(_ data: Data) -> [String: Any]? {
    if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      return object
    }
    guard let text = String(data: data, encoding: .utf8) else { return nil }
    for line in text.split(whereSeparator: \.isNewline) {
      guard line.hasPrefix("data:") else { continue }
      let payload = line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
      if let payloadData = payload.data(using: .utf8),
         let object = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
        return object
      }
    }
    return nil
  }

  private static func prettyPrinted(_ object: [String: Any]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
          let string = String(data: data, encoding: .utf8) else {
      return String(describing: object)
    }
    return string
  }
}
