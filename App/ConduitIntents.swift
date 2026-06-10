import AppIntents

/// Runs an agentic task against a chosen MCP server using Apple Intelligence.
struct RunAgentTaskIntent: AppIntent {
  static let title: LocalizedStringResource = "Run Task on Server"
  static let description = IntentDescription(
    "Use Apple Intelligence to perform a task with one of your connected MCP servers."
  )

  @Parameter(title: "Server")
  var server: MCPServerEntity

  @Parameter(title: "Task", requestValueDialog: "What would you like to do?")
  var task: String

  static var parameterSummary: some ParameterSummary {
    Summary("Run \(\.$task) on \(\.$server)")
  }

  /// Returns the result as a value so it can be piped into other Shortcuts
  /// actions — for example the Apple Intelligence model action.
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    guard let model = MCPServerStorage.load().first(where: { $0.id == server.id }) else {
      throw AppIntentError.serverMissing
    }
    let output = try await ConduitAgent.run(task: task, on: model)
    return .result(value: output, dialog: IntentDialog(stringLiteral: output))
  }
}

/// Lists the servers currently connected in Conduit.
struct ListServersIntent: AppIntent {
  static let title: LocalizedStringResource = "List Connected Servers"
  static let description = IntentDescription("Show the MCP servers connected in Conduit.")

  func perform() async throws -> some IntentResult & ReturnsValue<[MCPServerEntity]> & ProvidesDialog {
    let servers = MCPServerStorage.load()
    let entities = servers.map(\.entity)
    let dialog: IntentDialog = servers.isEmpty
      ? "You haven't connected any servers yet."
      : "You have \(servers.count) connected: \(servers.map(\.name).joined(separator: ", "))."
    return .result(value: entities, dialog: dialog)
  }
}

enum AppIntentError: Error, CustomLocalizedStringResourceConvertible {
  case serverMissing

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .serverMissing: "That server is no longer connected in Conduit."
    }
  }
}

struct ConduitShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: RunAgentTaskIntent(),
      phrases: [
        "Run a task in \(.applicationName)",
        "Run a task on \(\.$server) in \(.applicationName)",
        "Ask \(.applicationName) to use \(\.$server)"
      ],
      shortTitle: "Run Task",
      systemImageName: "sparkles"
    )
    AppShortcut(
      intent: ListServersIntent(),
      phrases: [
        "List my servers in \(.applicationName)",
        "What's connected in \(.applicationName)"
      ],
      shortTitle: "List Servers",
      systemImageName: "point.3.connected.trianglepath.dotted"
    )
  }
}
