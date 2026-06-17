import Foundation

//
//  MCPTool.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

nonisolated enum MCPToolRisk: String, Codable, CaseIterable, Identifiable, Sendable {
  case readOnly
  case unknown

  var id: String { rawValue }

  var label: String {
    switch self {
    case .readOnly: "Read-only"
    case .unknown: "Confirm before running"
    }
  }

  var symbol: String {
    switch self {
    case .readOnly: "eye"
    case .unknown: "exclamationmark.shield"
    }
  }
}

/// A description of a tool advertised by a remote MCP server.
nonisolated struct MCPTool: Identifiable, Hashable, Sendable {
  var id: String { name }
  var serverID: UUID?
  var name: String
  var summary: String
  var schema: String?
  var risk: MCPToolRisk
  var lastSeenAt: Date

  init(
    serverID: UUID? = nil,
    name: String,
    summary: String,
    schema: String? = nil,
    risk: MCPToolRisk = .unknown,
    lastSeenAt: Date = .now
  ) {
    self.serverID = serverID
    self.name = name
    self.summary = summary
    self.schema = schema
    self.risk = risk
    self.lastSeenAt = lastSeenAt
  }
}
