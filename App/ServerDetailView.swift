import SwiftUI
import AppIntents

struct ServerDetailView: View {
  @Environment(MCPServerStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let server: MCPServer

  @State private var tools: [MCPTool] = []
  @State private var toolsState: LoadState = .idle
  @State private var task = ""
  @State private var agentState: AgentState = .idle
  @State private var isShowingBrowser = false
  /// Scoped per server so dismissing the tip on one doesn't hide it for the rest.
  @AppStorage private var showsSiriTip: Bool

  init(server: MCPServer) {
    self.server = server
    _showsSiriTip = AppStorage(wrappedValue: true, "showsSiriTip-\(server.id.uuidString)")
  }

  /// Use the latest stored copy so credential edits elsewhere are reflected.
  private var current: MCPServer {
    store.servers.first { $0.id == server.id } ?? server
  }

  /// A run intent preconfigured with this server so the Siri tip is scoped to it.
  private var runIntent: RunAgentTaskIntent {
    let intent = RunAgentTaskIntent()
    intent.server = current.entity
    return intent
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        header
        agentSection
        toolsSection
        connectionSection
        shortcutsSection
      }
      .padding()
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
    .sheet(isPresented: $isShowingBrowser) {
      if let url = current.url {
        WebBrowserView(url: url)
      }
    }
    .task(id: current.id) { await loadTools() }
  }

  // MARK: - Sections

  private var header: some View {
    VStack(spacing: 12) {
      ServerLogo(logoURLString: current.logoURLString, host: current.host, symbol: current.symbol, tint: current.tint, size: 76, cornerRadius: 18)
      Text(current.host)
        .font(.callout)
        .foregroundStyle(.secondary)
      HealthStatusPill(health: store.health(for: current))
    }
    .frame(maxWidth: .infinity)
  }

  private var agentSection: some View {
    GroupBox {
      VStack(alignment: .leading, spacing: 12) {
        Label("Run with Apple Intelligence", systemImage: "sparkles")
          .font(.headline)
        Text("Describe a task. The on-device model picks tools from this server and runs them for you.")
          .font(.caption)
          .foregroundStyle(.secondary)

        TextField("e.g. Summarize my open issues", text: $task, axis: .vertical)
          .textFieldStyle(.roundedBorder)
          .lineLimit(1...4)

        Button {
          runTask()
        } label: {
          if case .running = agentState {
            HStack {
              ProgressView()
              Text("Working…")
            }
            .frame(maxWidth: .infinity)
          } else {
            Label("Run Task", systemImage: "play.fill")
              .frame(maxWidth: .infinity)
          }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(task.trimmingCharacters(in: .whitespaces).isEmpty || agentState.isRunning)

        switch agentState {
        case .idle, .running:
          EmptyView()
        case .success(let output):
          ResultBox(text: output, isError: false)
        case .failure(let message):
          ResultBox(text: message, isError: true)
        }
      }
    }
  }

  private var toolsSection: some View {
    GroupBox {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Label("Available Tools", systemImage: "wrench.and.screwdriver")
            .font(.headline)
          Spacer()
          if case .loading = toolsState { ProgressView() }
        }

        switch toolsState {
        case .idle, .loading:
          Text("Connecting…")
            .font(.caption)
            .foregroundStyle(.secondary)
        case .failed(let message):
          ResultBox(text: message, isError: true)
        case .loaded:
          if tools.isEmpty {
            Text("No tools reported by this server.")
              .font(.caption)
              .foregroundStyle(.secondary)
          } else {
            ForEach(tools) { tool in
              VStack(alignment: .leading, spacing: 2) {
                Text(tool.name)
                  .font(.subheadline.weight(.medium))
                if !tool.description.isEmpty {
                  Text(tool.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              if tool.id != tools.last?.id { Divider() }
            }
          }
        }
      }
    }
  }

  private var connectionSection: some View {
    GroupBox {
      VStack(alignment: .leading, spacing: 12) {
        Label("Connection", systemImage: current.authKind.symbol)
          .font(.headline)
        LabeledContent("Auth", value: current.authKind.label)
        LabeledContent("Endpoint", value: current.urlString)
          .lineLimit(1)
        if current.authKind != .none {
          Button("Open Provider Sign-in", systemImage: "safari") {
            isShowingBrowser = true
          }
          .buttonStyle(.bordered)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var shortcutsSection: some View {
    GroupBox {
      VStack(alignment: .leading, spacing: 12) {
        Label("Siri & Shortcuts", systemImage: "wand.and.stars")
          .font(.headline)
        Text("Add a Conduit action to a shortcut, then pipe its result into the Apple Intelligence model action in the Shortcuts app to build your own automations.")
          .font(.caption)
          .foregroundStyle(.secondary)

        SiriTipView(intent: runIntent, isVisible: $showsSiriTip)

        ShortcutsLink()
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  // MARK: - Actions

  private func loadTools() async {
    toolsState = .loading
    do {
      let loaded = try await MCPClient(server: current).listTools()
      tools = loaded
      toolsState = .loaded
    } catch {
      toolsState = .failed(error.localizedDescription)
    }
  }

  private func runTask() {
    let prompt = task.trimmingCharacters(in: .whitespaces)
    guard !prompt.isEmpty else { return }
    agentState = .running
    Task {
      do {
        let output = try await ConduitAgent.run(task: prompt, on: current)
        agentState = .success(output)
      } catch {
        agentState = .failure(error.localizedDescription)
      }
    }
  }

  enum LoadState: Equatable {
    case idle, loading, loaded
    case failed(String)
  }

  enum AgentState {
    case idle
    case running
    case success(String)
    case failure(String)

    var isRunning: Bool { if case .running = self { true } else { false } }
  }
}

private struct HealthStatusPill: View {
  let health: ServerHealth
  var body: some View {
    Label(health.label, systemImage: health.symbol)
      .font(.caption.weight(.medium))
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(health.color.opacity(0.15), in: .capsule)
      .foregroundStyle(health.color)
  }
}

private struct ResultBox: View {
  let text: String
  let isError: Bool
  var body: some View {
    Text(text)
      .font(.callout)
      .textSelection(.enabled)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background((isError ? Color.red : Color.teal).opacity(0.1), in: .rect(cornerRadius: 10))
      .foregroundStyle(isError ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
  }
}
