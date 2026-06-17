import AppIntentsTesting
import XCTest

//
//  ConduitAppIntentsTests.swift
//  ConduitAppIntentsTests
//
//  Created by Vishrut Jha on 6/16/26.
//

final class ConduitAppIntentsTests: XCTestCase {
  func testIntentDefinitionsLoad() throws {
    let definitions = IntentDefinitions(bundleIdentifier: "app.bitrig.vishrutjha.conduit")
    _ = definitions.intents["RunAgentTaskIntent"]
    _ = definitions.intents["RunMCPToolIntent"]
    _ = definitions.entities["ConduitServerEntity"]
    _ = definitions.entities["ConduitToolEntity"]
  }
}
