import Foundation
import SwiftData

//
//  ConduitModelContainer.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

nonisolated enum ConduitModelContainer {
  static let schema = Schema([
    MCPServerRecord.self,
    MCPToolRecord.self,
    ServerHealthModel.self,
    ConduitMigrationRecord.self
  ])

  static let shared: ModelContainer = {
    do {
      return try makeContainer()
    } catch {
      return try! makeContainer(isStoredInMemoryOnly: true)
    }
  }()

  static func makeContainer(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
    let configuration = ModelConfiguration(
      "Conduit",
      schema: schema,
      isStoredInMemoryOnly: isStoredInMemoryOnly,
      allowsSave: true,
      groupContainer: .identifier(AppGroup.id),
      cloudKitDatabase: .none
    )
    return try ModelContainer(for: schema, configurations: [configuration])
  }
}
