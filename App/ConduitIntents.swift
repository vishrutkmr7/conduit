import AppIntents
import Foundation

//
//  ConduitIntents.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

struct RunAgentTaskIntent: AppIntent {
  static let title: LocalizedStringResource = "Run Task on Server"
  static let description = IntentDescription("Use Apple Intelligence to perform a task with one of your connected MCP servers.")
  static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }
  static var supportedModes: IntentModes { .background }

  @Parameter(title: "Server")
  var server: ConduitServerEntity

  @Parameter(title: "Task", requestValueDialog: "What would you like to do?")
  var task: String

  static var parameterSummary: some ParameterSummary {
    Summary("Run \(\.$task) on \(\.$server)")
  }

  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    guard let model = MCPServerStorage.server(id: server.id) else {
      throw AppIntentError.serverMissing
    }
    let output = try await ConduitAgent.run(task: task, on: model)
    return .result(value: output, dialog: IntentDialog(stringLiteral: output))
  }
}

struct RunMCPToolIntent: AppIntent {
  static let title: LocalizedStringResource = "Run MCP Tool"
  static let description = IntentDescription("Run a selected tool from a connected MCP server.")
  static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }
  static var supportedModes: IntentModes { .background }

  @Parameter(title: "Server")
  var server: ConduitServerEntity

  @Parameter(title: "Tool")
  var tool: ConduitToolEntity

  @Parameter(title: "Arguments JSON", default: "{}", requestValueDialog: "What JSON arguments should Conduit send?")
  var argumentsJSON: String

  static var parameterSummary: some ParameterSummary {
    Summary("Run \(\.$tool) on \(\.$server)")
  }

  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    guard let model = MCPServerStorage.server(id: server.id) else {
      throw AppIntentError.serverMissing
    }
    guard tool.serverID == server.id else {
      throw AppIntentError.toolMissing
    }
    if tool.risk != .readOnly {
      try await requestConfirmation(
        actionName: .continue,
        dialog: "Run \(tool.name) on \(server.name)?"
      )
    }
    let output = try await MCPClient(server: model).callTool(tool.name, argumentsJSON: argumentsJSON)
    return .result(value: output, dialog: IntentDialog(stringLiteral: output))
  }
}

struct ListServersIntent: AppIntent {
  static let title: LocalizedStringResource = "List Connected Servers"
  static let description = IntentDescription("Show the MCP servers connected in Conduit.")
  static var supportedModes: IntentModes { .background }

  func perform() async throws -> some IntentResult & ReturnsValue<[ConduitServerEntity]> & ProvidesDialog {
    let servers = MCPServerStorage.load(includeCredentials: false)
    let entities = servers.map(\.entity)
    let dialog: IntentDialog = servers.isEmpty
      ? "You have not connected any servers yet."
      : "You have \(servers.count) connected: \(servers.map(\.name).joined(separator: ", "))."
    return .result(value: entities, dialog: dialog)
  }
}

struct ListToolsIntent: AppIntent {
  static let title: LocalizedStringResource = "List Server Tools"
  static let description = IntentDescription("Show cached tools for a connected MCP server.")
  static var supportedModes: IntentModes { .background }

  @Parameter(title: "Server")
  var server: ConduitServerEntity

  static var parameterSummary: some ParameterSummary {
    Summary("List tools on \(\.$server)")
  }

  func perform() async throws -> some IntentResult & ReturnsValue<[ConduitToolEntity]> & ProvidesDialog {
    guard let model = MCPServerStorage.server(id: server.id) else {
      throw AppIntentError.serverMissing
    }
    let entities = MCPServerStorage.cachedTools(for: model.id).map { $0.entity(server: model) }
    let dialog: IntentDialog = entities.isEmpty
      ? "No cached tools for \(model.name). Refresh tools first."
      : "\(model.name) has \(entities.count) cached tools."
    return .result(value: entities, dialog: dialog)
  }
}

struct RefreshToolsIntent: AppIntent {
  static let title: LocalizedStringResource = "Refresh Server Tools"
  static let description = IntentDescription("Connect to a server and refresh its MCP tool catalog.")
  static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }
  static var supportedModes: IntentModes { .background }

  @Parameter(title: "Server")
  var server: ConduitServerEntity

  static var parameterSummary: some ParameterSummary {
    Summary("Refresh tools on \(\.$server)")
  }

  func perform() async throws -> some IntentResult & ReturnsValue<[ConduitToolEntity]> & ProvidesDialog {
    guard let model = MCPServerStorage.server(id: server.id) else {
      throw AppIntentError.serverMissing
    }
    let tools = try await MCPClient(server: model).listTools()
    MCPServerStorage.replaceTools(tools, for: model.id)
    ServerHealthStore.set(
      ServerHealthRecord(health: .connected, checkedAt: .now, detail: nil, toolCount: tools.count),
      for: model.id
    )
    let entities = tools.map { $0.entity(server: model) }
    return .result(value: entities, dialog: "Refreshed \(tools.count) tools for \(model.name).")
  }
}

struct OpenServerIntent: OpenIntent {
  static let title: LocalizedStringResource = "Open Server"
  static let description = IntentDescription("Open a connected MCP server in Conduit.")
  static var supportedModes: IntentModes { .foreground(.dynamic) }

  @Parameter(title: "Server")
  var target: ConduitServerEntity
}

enum AppIntentError: Error, CustomLocalizedStringResourceConvertible {
  case serverMissing
  case toolMissing

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .serverMissing: "That server is no longer connected in Conduit."
    case .toolMissing: "That tool is not available on the selected server."
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
      intent: RunMCPToolIntent(),
      phrases: [
        "Run \(\.$tool) in \(.applicationName)",
        "Use a tool in \(.applicationName)"
      ],
      shortTitle: "Run Tool",
      systemImageName: "wrench.and.screwdriver"
    )
    AppShortcut(
      intent: ListServersIntent(),
      phrases: [
        "List my servers in \(.applicationName)",
        "What is connected in \(.applicationName)"
      ],
      shortTitle: "List Servers",
      systemImageName: "point.3.connected.trianglepath.dotted"
    )
    AppShortcut(
      intent: ListToolsIntent(),
      phrases: [
        "List tools in \(.applicationName)",
        "Show tools on \(\.$server) in \(.applicationName)"
      ],
      shortTitle: "List Tools",
      systemImageName: "list.bullet.rectangle"
    )
  }
}
