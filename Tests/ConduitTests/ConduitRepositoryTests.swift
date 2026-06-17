import Foundation
import SwiftData
import Testing
@testable import Conduit

//
//  ConduitRepositoryTests.swift
//  ConduitTests
//
//  Created by Vishrut Jha on 6/16/26.
//

struct ConduitRepositoryTests {
  @Test func repositoryStoresServerSnapshots() throws {
    let container = try ConduitModelContainer.makeContainer(isStoredInMemoryOnly: true)
    let repository = ConduitRepository(container: container)
    let server = MCPServer(name: "Local", urlString: "https://example.com/mcp", authKind: .none)

    repository.upsertServer(server)

    let stored = try #require(repository.fetchServers(includeCredentials: false).first)
    #expect(stored.name == "Local")
    #expect(stored.credential == nil)
  }

  @Test func repositoryCachesToolsByServer() throws {
    let container = try ConduitModelContainer.makeContainer(isStoredInMemoryOnly: true)
    let repository = ConduitRepository(container: container)
    let server = MCPServer(name: "Local", urlString: "https://example.com/mcp")
    let tool = MCPTool(serverID: server.id, name: "issues.list", summary: "List issues", risk: .readOnly)

    repository.upsertServer(server)
    repository.replaceTools([tool], for: server.id)

    let cached = try #require(repository.cachedTools(for: server.id).first)
    #expect(cached.name == "issues.list")
    #expect(cached.risk == .readOnly)
  }

  @Test func repositoryCoalescesDuplicateCloudKitRows() throws {
    let container = try ConduitModelContainer.makeContainer(isStoredInMemoryOnly: true)
    let context = ModelContext(container)
    let repository = ConduitRepository(container: container)
    let serverID = UUID()
    let older = Date(timeIntervalSince1970: 100)
    let newer = Date(timeIntervalSince1970: 200)

    context.insert(ServerHealthModel(
      serverID: serverID,
      record: ServerHealthRecord(health: .unknown, checkedAt: older, detail: nil, toolCount: nil)
    ))
    context.insert(ServerHealthModel(
      serverID: serverID,
      record: ServerHealthRecord(health: .connected, checkedAt: newer, detail: nil, toolCount: 4)
    ))
    try context.save()

    let health = try #require(repository.healthRecords()[serverID])
    #expect(health.health == .connected)
    #expect(health.toolCount == 4)
  }
}
