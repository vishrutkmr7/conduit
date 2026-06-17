import Foundation

//
//  MCPClient.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

nonisolated protocol MCPTransport: Sendable {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

nonisolated struct URLSessionMCPTransport: MCPTransport {
  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    try await URLSession.shared.data(for: request)
  }
}

nonisolated enum MCPClientError: LocalizedError, Equatable {
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

private nonisolated struct JSONRPCRequest: Encodable {
  var jsonrpc = "2.0"
  var id: Int?
  var method: String
  var params: JSONValue
}

nonisolated struct JSONRPCResponse: Decodable {
  var result: JSONValue?
  var error: JSONRPCError?
}

nonisolated struct JSONRPCError: Decodable {
  var message: String
}

/// Minimal client for the MCP streamable-HTTP transport.
actor MCPClient {
  private let server: MCPServer
  private let transport: any MCPTransport
  private var sessionID: String?
  private var nextID = 1

  init(server: MCPServer, transport: any MCPTransport = URLSessionMCPTransport()) {
    self.server = server
    self.transport = transport
  }

  /// Connects, negotiates a session, and returns the tools the server exposes.
  func listTools() async throws -> [MCPTool] {
    try await initializeIfNeeded()
    let result = try await send(method: "tools/list", params: .object([:]))
    guard let tools = result.objectValue?["tools"]?.arrayValue else { return [] }
    return tools.compactMap { tool in
      guard let object = tool.objectValue else { return nil }
      let name = object["name"]?.stringValue ?? "tool"
      let summary = object["description"]?.stringValue ?? ""
      return MCPTool(
        serverID: server.id,
        name: name,
        summary: summary,
        schema: object["inputSchema"]?.prettyPrinted()
      )
    }
  }

  /// Calls a tool with a JSON object string and returns its textual result.
  func callTool(_ name: String, argumentsJSON: String) async throws -> String {
    try await initializeIfNeeded()
    let raw = argumentsJSON.trimmingCharacters(in: .whitespacesAndNewlines)
    let arguments = try JSONValue.parseObject(raw.isEmpty ? "{}" : raw)
    let result = try await send(
      method: "tools/call",
      params: .object([
        "name": .string(name),
        "arguments": arguments
      ])
    )

    guard let content = result.objectValue?["content"]?.arrayValue else {
      return result.prettyPrinted()
    }

    let text = content.compactMap { $0.objectValue?["text"]?.stringValue }.joined(separator: "\n")
    return text.isEmpty ? result.prettyPrinted() : text
  }

  private func initializeIfNeeded() async throws {
    guard sessionID == nil else { return }
    _ = try await send(
      method: "initialize",
      params: .object([
        "protocolVersion": .string("2025-06-18"),
        "capabilities": .object([:]),
        "clientInfo": .object([
          "name": .string("Conduit"),
          "version": .string("1.0")
        ])
      ])
    )
    try? await notify(method: "notifications/initialized")
  }

  private func send(method: String, params: JSONValue) async throws -> JSONValue {
    let id = nextID
    nextID += 1
    let body = JSONRPCRequest(id: id, method: method, params: params)
    let (data, response) = try await perform(body: body)

    if let http = response as? HTTPURLResponse,
       let session = http.value(forHTTPHeaderField: "Mcp-Session-Id") {
      sessionID = session
    }

    let decoded = try Self.decodeRPC(data)
    if let error = decoded.error {
      throw MCPClientError.rpc(error.message)
    }
    return decoded.result ?? .object([:])
  }

  private func notify(method: String) async throws {
    let body = JSONRPCRequest(id: nil, method: method, params: .object([:]))
    _ = try await perform(body: body)
  }

  private func perform(body: JSONRPCRequest) async throws -> (Data, URLResponse) {
    try Task.checkCancellation()
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
    request.httpBody = try JSONEncoder().encode(body)

    do {
      let (data, response) = try await transport.data(for: request)
      if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
        throw MCPClientError.transport("Server responded with status \(http.statusCode).")
      }
      return (data, response)
    } catch is CancellationError {
      throw CancellationError()
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

  static func decodeRPC(_ data: Data) throws -> JSONRPCResponse {
    if let response = try? JSONDecoder().decode(JSONRPCResponse.self, from: data) {
      return response
    }
    guard let text = String(data: data, encoding: .utf8) else { throw MCPClientError.decoding }
    for line in text.split(whereSeparator: \.isNewline) {
      guard line.hasPrefix("data:") else { continue }
      let payload = line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
      if let payloadData = payload.data(using: .utf8),
         let response = try? JSONDecoder().decode(JSONRPCResponse.self, from: payloadData) {
        return response
      }
    }
    throw MCPClientError.decoding
  }
}
