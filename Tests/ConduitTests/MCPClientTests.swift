import Foundation
import Testing
@testable import Conduit

//
//  MCPClientTests.swift
//  ConduitTests
//
//  Created by Vishrut Jha on 6/16/26.
//

struct MCPClientTests {
  @Test func decodesServerSentEventJSONRPCPayload() throws {
    let payload = """
    event: message
    data: {"jsonrpc":"2.0","result":{"tools":[]}}

    """
    let response = try MCPClient.decodeRPC(Data(payload.utf8))
    #expect(response.result?.objectValue?["tools"]?.arrayValue?.isEmpty == true)
  }

  @Test func rejectsNonObjectArguments() throws {
    #expect(throws: MCPClientError.decoding) {
      _ = try JSONValue.parseObject("[]")
    }
  }
}
