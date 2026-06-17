import Foundation
import SwiftData

//
//  ConduitRepository.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

nonisolated struct ConduitRepository {
  private static let legacyServerKey = "configured_servers"
  private static let legacyHealthKey = "server_health"
  private static let migrationID = "legacy-app-group-json-v1"

  var container: ModelContainer

  init(container: ModelContainer = ConduitModelContainer.shared) {
    self.container = container
  }

  func fetchServers(includeCredentials: Bool = true) -> [MCPServer] {
    let context = migratedContext()
    let descriptor = FetchDescriptor<MCPServerRecord>(
      sortBy: [SortDescriptor(\.dateAdded), SortDescriptor(\.name)]
    )
    return (try? context.fetch(descriptor))?.map { $0.snapshot(includeCredential: includeCredentials) } ?? []
  }

  func saveServers(_ servers: [MCPServer]) {
    let context = migratedContext()
    let existing = fetchServerRecords(context: context)
    let serverIDs = Set(servers.map(\.id))

    for record in existing where !serverIDs.contains(record.id) {
      if let account = record.credentialReference {
        ConduitKeychain.deleteCredential(for: account)
      }
      context.delete(record)
      deleteTools(for: record.id, context: context)
    }

    for server in servers {
      upsert(server, context: context)
    }

    try? context.save()
  }

  func upsertServer(_ server: MCPServer) {
    let context = migratedContext()
    upsert(server, context: context)
    try? context.save()
  }

  func removeServer(_ server: MCPServer) {
    let context = migratedContext()
    if let record = fetchServerRecord(id: server.id, context: context) {
      if let account = record.credentialReference {
        ConduitKeychain.deleteCredential(for: account)
      }
      context.delete(record)
    }
    deleteHealth(for: server.id, context: context)
    deleteTools(for: server.id, context: context)
    try? context.save()
  }

  func server(named name: String) -> MCPServer? {
    fetchServers().first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
  }

  func server(id: UUID) -> MCPServer? {
    fetchServers().first { $0.id == id }
  }

  func cachedTools(for serverID: UUID) -> [MCPTool] {
    let context = migratedContext()
    let descriptor = FetchDescriptor<MCPToolRecord>(
      predicate: #Predicate { $0.serverID == serverID },
      sortBy: [SortDescriptor(\.name)]
    )
    return (try? context.fetch(descriptor))?.map(\.snapshot) ?? []
  }

  func tool(id: String) -> MCPTool? {
    let context = migratedContext()
    let descriptor = FetchDescriptor<MCPToolRecord>(predicate: #Predicate { $0.id == id })
    return (try? context.fetch(descriptor))?.first?.snapshot
  }

  func replaceTools(_ tools: [MCPTool], for serverID: UUID) {
    let context = migratedContext()
    deleteTools(for: serverID, context: context)
    for tool in tools {
      context.insert(MCPToolRecord(serverID: serverID, tool: tool))
    }
    try? context.save()
  }

  func healthRecords() -> [UUID: ServerHealthRecord] {
    let context = migratedContext()
    let records = (try? context.fetch(FetchDescriptor<ServerHealthModel>())) ?? []
    return Dictionary(uniqueKeysWithValues: records.map { ($0.serverID, $0.snapshot) })
  }

  func setHealthRecords(_ records: [UUID: ServerHealthRecord]) {
    let context = migratedContext()
    for (serverID, record) in records {
      if let existing = fetchHealth(serverID: serverID, context: context) {
        existing.update(from: record)
      } else {
        context.insert(ServerHealthModel(serverID: serverID, record: record))
      }
    }
    try? context.save()
  }

  func pruneHealth(keeping ids: [UUID]) {
    let context = migratedContext()
    let kept = Set(ids)
    let records = (try? context.fetch(FetchDescriptor<ServerHealthModel>())) ?? []
    for record in records where !kept.contains(record.serverID) {
      context.delete(record)
    }
    try? context.save()
  }

  private func migratedContext() -> ModelContext {
    let context = ModelContext(container)
    migrateLegacyDataIfNeeded(context: context)
    return context
  }

  private func migrateLegacyDataIfNeeded(context: ModelContext) {
    let migrationID = Self.migrationID
    let markerDescriptor = FetchDescriptor<ConduitMigrationRecord>(
      predicate: #Predicate { $0.id == migrationID }
    )
    guard (try? context.fetch(markerDescriptor).isEmpty) != false else { return }

    if let data = AppGroup.defaults.data(forKey: Self.legacyServerKey),
       let servers = try? JSONDecoder().decode([MCPServer].self, from: data) {
      for server in servers {
        upsert(server, context: context)
      }
      AppGroup.defaults.removeObject(forKey: Self.legacyServerKey)
    }

    if let data = AppGroup.defaults.data(forKey: Self.legacyHealthKey),
       let records = try? JSONDecoder().decode([UUID: ServerHealthRecord].self, from: data) {
      for (serverID, record) in records {
        context.insert(ServerHealthModel(serverID: serverID, record: record))
      }
      AppGroup.defaults.removeObject(forKey: Self.legacyHealthKey)
    }

    context.insert(ConduitMigrationRecord(id: Self.migrationID))
    try? context.save()
  }

  private func upsert(_ server: MCPServer, context: ModelContext) {
    let account = server.keychainAccount
    if let credential = server.credential, !credential.isEmpty {
      ConduitKeychain.setCredential(credential, for: account)
    } else if server.authKind == .none {
      ConduitKeychain.deleteCredential(for: account)
    }

    var persisted = server
    persisted.credentialReference = account
    persisted.credential = nil

    if let record = fetchServerRecord(id: server.id, context: context) {
      record.update(from: persisted)
    } else {
      context.insert(MCPServerRecord(server: persisted))
    }
  }

  private func fetchServerRecords(context: ModelContext) -> [MCPServerRecord] {
    (try? context.fetch(FetchDescriptor<MCPServerRecord>())) ?? []
  }

  private func fetchServerRecord(id: UUID, context: ModelContext) -> MCPServerRecord? {
    let descriptor = FetchDescriptor<MCPServerRecord>(predicate: #Predicate { $0.id == id })
    return try? context.fetch(descriptor).first
  }

  private func fetchHealth(serverID: UUID, context: ModelContext) -> ServerHealthModel? {
    let descriptor = FetchDescriptor<ServerHealthModel>(predicate: #Predicate { $0.serverID == serverID })
    return try? context.fetch(descriptor).first
  }

  private func deleteTools(for serverID: UUID, context: ModelContext) {
    let descriptor = FetchDescriptor<MCPToolRecord>(predicate: #Predicate { $0.serverID == serverID })
    for record in (try? context.fetch(descriptor)) ?? [] {
      context.delete(record)
    }
  }

  private func deleteHealth(for serverID: UUID, context: ModelContext) {
    if let record = fetchHealth(serverID: serverID, context: context) {
      context.delete(record)
    }
  }
}
