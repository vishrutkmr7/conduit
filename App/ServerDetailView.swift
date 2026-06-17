import AppIntents
import SwiftUI

//
//  ServerDetailView.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

struct ServerDetailView: View {
  @Environment(MCPServerStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let server: MCPServer

  @State private var model = ServerDetailModel()
  @FocusState private var taskFieldFocused: Bool
  @AppStorage private var showsSiriTip: Bool

  init(server: MCPServer) {
    self.server = server
    _showsSiriTip = AppStorage(wrappedValue: true, "showsSiriTip-\(server.id.uuidString)")
  }

  private var current: MCPServer {
    store.servers.first { $0.id == server.id } ?? server
  }

  private var runIntent: RunAgentTaskIntent {
    let intent = RunAgentTaskIntent()
    intent.server = current.entity
    return intent
  }

  var body: some View {
    Form {
      Section {
        serverHeader
      }

      Section("Run") {
        agentControls
      }

      if model.ideasState != .unavailable {
        Section("Ideas") {
          ideasContent
        }
      }

      Section("Tools") {
        toolsContent
      }

      Section("Connection") {
        LabeledContent("Auth", value: current.authKind.label)
        LabeledContent("Endpoint", value: current.urlString)
        if current.authKind != .none {
          Button("Open Provider Sign-in", systemImage: "safari") {
            model.isShowingBrowser = true
          }
        }
      }

      Section("Siri & Shortcuts") {
        Text("Add Conduit actions to shortcuts, then pipe results into Apple Intelligence model actions.")
          .foregroundStyle(.secondary)
        SiriTipView(intent: runIntent, isVisible: $showsSiriTip)
        ShortcutsLink()
      }
    }
    .navigationTitle(current.name)
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    .toolbar {
      ToolbarItem(placement: .destructiveAction) {
        Button("Remove", systemImage: "trash", role: .destructive) {
          store.remove(current)
          dismiss()
        }
      }
    }
    .sheet(isPresented: $model.isShowingBrowser) {
      if let url = current.url {
        WebBrowserView(url: url)
      }
    }
    .task(id: current.id) {
      await model.loadTools(for: current)
    }
    .onDisappear {
      model.cancel()
    }
  }

  private var serverHeader: some View {
    HStack(spacing: 12) {
      ServerLogo(logoURLString: current.logoURLString, host: current.host, symbol: current.symbol, size: 48)
      VStack(alignment: .leading, spacing: 4) {
        Text(current.host)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        HealthStatusLabel(health: store.health(for: current))
          .font(.subheadline)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var agentControls: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let unavailable = ConduitAgent.unavailableMessage {
        Label(unavailable, systemImage: "exclamationmark.triangle")
          .foregroundStyle(.orange)
      }

      TextField("Task", text: $model.task, prompt: Text("Summarize my open issues"), axis: .vertical)
        .lineLimit(1...4)
        .focused($taskFieldFocused)

      Button {
        model.runTask(on: current)
      } label: {
        if model.agentState.isRunning {
          Label("Working", systemImage: "hourglass")
        } else {
          Label("Run Task", systemImage: "play.fill")
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(model.task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.agentState.isRunning || ConduitAgent.unavailableMessage != nil)

      switch model.agentState {
      case .idle, .running:
        EmptyView()
      case .success(let output):
        ResultBox(text: output, isError: false)
      case .failure(let message):
        ResultBox(text: message, isError: true)
      }
    }
  }

  @ViewBuilder
  private var ideasContent: some View {
    switch model.ideasState {
    case .idle, .loading:
      ProgressView("Generating ideas")
    case .loaded(let ideas):
      if ideas.isEmpty {
        ContentUnavailableView("No Ideas", systemImage: "lightbulb", description: Text("No task ideas are available for this server yet."))
      } else {
        ForEach(ideas) { idea in
          IdeaButton(idea: idea) {
            model.select(idea)
            taskFieldFocused = true
          }
        }
        Button("Regenerate Ideas", systemImage: "arrow.clockwise") {
          model.regenerateIdeas(for: current)
        }
      }
    case .failed(let message):
      ResultBox(text: message, isError: true)
    case .unavailable:
      EmptyView()
    }
  }

  @ViewBuilder
  private var toolsContent: some View {
    switch model.toolsState {
    case .idle, .loading:
      ProgressView("Connecting")
    case .failed(let message):
      ResultBox(text: message, isError: true)
    case .loaded:
      if model.tools.isEmpty {
        ContentUnavailableView("No Tools", systemImage: "wrench.and.screwdriver", description: Text("This server did not report any tools."))
      } else {
        ForEach(model.tools) { tool in
          VStack(alignment: .leading, spacing: 4) {
            Label(tool.name, systemImage: tool.risk.symbol)
              .font(.subheadline)
            if !tool.summary.isEmpty {
              Text(tool.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Text(tool.risk.label)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .accessibilityElement(children: .combine)
        }
      }
    }
  }
}
