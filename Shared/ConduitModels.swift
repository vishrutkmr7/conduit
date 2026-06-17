import Foundation
import SwiftData

//
//  ConduitModels.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

@Model
final class MCPServerRecord {
  #Index<MCPServerRecord>([\.id], [\.name], [\.urlString], [\.dateAdded])

  var id: UUID
  var name: String
  var urlString: String
  var symbol: String
  var logoURLString: String?
  var authKindRawValue: String
  var credentialReference: String?
  var headerName: String
  var isCustom: Bool
  var dateAdded: Date

  init(server: MCPServer) {
    id = server.id
    name = server.name
    urlString = server.urlString
    symbol = server.symbol
    logoURLString = server.logoURLString
    authKindRawValue = server.authKind.rawValue
    credentialReference = server.keychainAccount
    headerName = server.headerName
    isCustom = server.isCustom
    dateAdded = server.dateAdded
  }

  func update(from server: MCPServer) {
    name = server.name
    urlString = server.urlString
    symbol = server.symbol
    logoURLString = server.logoURLString
    authKindRawValue = server.authKind.rawValue
    credentialReference = server.keychainAccount
    headerName = server.headerName
    isCustom = server.isCustom
    dateAdded = server.dateAdded
  }

  func snapshot(includeCredential: Bool) -> MCPServer {
    let authKind = MCPAuthKind(rawValue: authKindRawValue) ?? .none
    let account = credentialReference ?? "server-\(id.uuidString)"
    return MCPServer(
      id: id,
      name: name,
      urlString: urlString,
      symbol: symbol,
      logoURLString: logoURLString,
      authKind: authKind,
      credential: includeCredential ? ConduitKeychain.credential(for: account) : nil,
      credentialReference: account,
      headerName: headerName,
      isCustom: isCustom,
      dateAdded: dateAdded
    )
  }
}

@Model
final class MCPToolRecord {
  #Index<MCPToolRecord>([\.id], [\.serverID], [\.name], [\.lastSeenAt])

  var id: String
  var serverID: UUID
  var name: String
  var toolSummary: String
  var schema: String?
  var riskRawValue: String
  var lastSeenAt: Date

  init(serverID: UUID, tool: MCPTool) {
    id = "\(serverID.uuidString)|\(tool.name)"
    self.serverID = serverID
    name = tool.name
    toolSummary = tool.summary
    schema = tool.schema
    riskRawValue = tool.risk.rawValue
    lastSeenAt = tool.lastSeenAt
  }

  func update(from tool: MCPTool) {
    name = tool.name
    toolSummary = tool.summary
    schema = tool.schema
    riskRawValue = tool.risk.rawValue
    lastSeenAt = tool.lastSeenAt
  }

  var snapshot: MCPTool {
    MCPTool(
      serverID: serverID,
      name: name,
      summary: toolSummary,
      schema: schema,
      risk: MCPToolRisk(rawValue: riskRawValue) ?? .unknown,
      lastSeenAt: lastSeenAt
    )
  }
}

@Model
final class ServerHealthModel {
  #Index<ServerHealthModel>([\.serverID], [\.checkedAt])

  var serverID: UUID
  var healthRawValue: String
  var checkedAt: Date
  var detail: String?
  var toolCount: Int?

  init(serverID: UUID, record: ServerHealthRecord) {
    self.serverID = serverID
    healthRawValue = record.health.rawValue
    checkedAt = record.checkedAt
    detail = record.detail
    toolCount = record.toolCount
  }

  func update(from record: ServerHealthRecord) {
    healthRawValue = record.health.rawValue
    checkedAt = record.checkedAt
    detail = record.detail
    toolCount = record.toolCount
  }

  var snapshot: ServerHealthRecord {
    ServerHealthRecord(
      health: ServerHealth(rawValue: healthRawValue) ?? .unknown,
      checkedAt: checkedAt,
      detail: detail,
      toolCount: toolCount
    )
  }
}

@Model
final class ConduitMigrationRecord {
  #Index<ConduitMigrationRecord>([\.id])

  var id: String
  var completedAt: Date

  init(id: String, completedAt: Date = .now) {
    self.id = id
    self.completedAt = completedAt
  }
}
