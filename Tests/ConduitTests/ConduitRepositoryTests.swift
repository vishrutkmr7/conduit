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
}
