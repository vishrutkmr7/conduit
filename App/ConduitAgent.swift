import Foundation
import FoundationModels

enum ConduitAgentError: LocalizedError {
  case modelUnavailable
  case noTools

  var errorDescription: String? {
    switch self {
    case .modelUnavailable:
      "Apple Intelligence isn't available on this device. Enable it in Settings, or try on a supported device."
    case .noTools:
      "This server didn't report any tools to work with."
    }
  }
}

/// Drives an agentic task: connects to an MCP server, exposes its tools to the
/// on-device model, and lets the model call them to accomplish the user's request.
enum ConduitAgent {
  static func run(task: String, on server: MCPServer) async throws -> String {
    let model = SystemLanguageModel.default
    guard case .available = model.availability else {
      throw ConduitAgentError.modelUnavailable
    }

    let client = MCPClient(server: server)
    let mcpTools = try await client.listTools()
    guard !mcpTools.isEmpty else { throw ConduitAgentError.noTools }

    // The model performs best with a handful of tools; cap the exposed set.
    let tools: [any Tool] = mcpTools.prefix(5).map { MCPBridgeTool(tool: $0, client: client) }

    let instructions = """
    You are Conduit, an assistant that completes tasks using tools from the \
    "\(server.name)" service. Call the provided tools when they help answer the \
    request. Each tool takes a single "argumentsJSON" string that must be a valid \
    JSON object of the tool's parameters (use "{}" when none are needed). After \
    gathering results, reply with a concise, helpful summary for the user.
    """

    let session = LanguageModelSession(tools: tools, instructions: instructions)
    let response = try await session.respond(to: task)
    return response.content
  }
}

/// Wraps a single MCP tool as a Foundation Models `Tool`. Arguments are passed as
/// a JSON string so one type can represent every dynamically discovered tool.
private struct MCPBridgeTool: Tool {
  let name: String
  let description: String
  private let mcpName: String
  private let client: MCPClient

  init(tool: MCPTool, client: MCPClient) {
    self.mcpName = tool.name
    self.name = MCPBridgeTool.sanitize(tool.name)
    self.client = client
    var text = tool.description.isEmpty ? "Tool \(tool.name)." : tool.description
    if let schema = tool.schema {
      text += "\nArguments JSON schema: \(schema)"
    }
    self.description = String(text.prefix(900))
  }

  @Generable
  struct Arguments {
    @Guide(description: "A JSON object string of the tool's arguments, or {} if none are needed.")
    var argumentsJSON: String
  }

  func call(arguments: Arguments) async throws -> String {
    let raw = arguments.argumentsJSON.trimmingCharacters(in: .whitespacesAndNewlines)
    let json = raw.isEmpty ? "{}" : raw
    let dict = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any] ?? [:]
    let result = try await client.callTool(mcpName, arguments: dict)
    return String(result.prefix(4000))
  }

  /// Tool names must be identifier-like for the model; keep a clean version.
  private static func sanitize(_ name: String) -> String {
    let cleaned = name.map { $0.isLetter || $0.isNumber || $0 == "_" ? $0 : "_" }
    let result = String(cleaned)
    return result.isEmpty ? "tool" : result
  }
}
