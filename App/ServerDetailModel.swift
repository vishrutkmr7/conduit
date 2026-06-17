import Foundation
import Observation

//
//  ServerDetailModel.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

@MainActor
@Observable
final class ServerDetailModel {
  var tools: [MCPTool] = []
  var toolsState: LoadState = .idle
  var task = ""
  var agentState: AgentState = .idle
  var ideasState: IdeasState = .idle
  var isShowingBrowser = false

  private var agentTask: Task<Void, Never>?
  private var ideasTask: Task<Void, Never>?

  func loadTools(for server: MCPServer) async {
    let cached = MCPServerStorage.cachedTools(for: server.id)
    if !cached.isEmpty {
      tools = cached
      toolsState = .loaded
    } else {
      toolsState = .loading
    }

    do {
      let loaded = try await MCPClient(server: server).listTools()
      tools = loaded
      toolsState = .loaded
      MCPServerStorage.replaceTools(loaded, for: server.id)
      await generateIdeas(for: server)
    } catch is CancellationError {
      if tools.isEmpty {
        toolsState = .idle
      }
    } catch {
      toolsState = .failed(error.localizedDescription)
    }
  }

  func select(_ idea: ShortcutIdea) {
    task = idea.prompt
  }

  func regenerateIdeas(for server: MCPServer) {
    ideasTask?.cancel()
    ideasTask = Task { [weak self] in
      await self?.generateIdeas(for: server)
    }
  }

  func runTask(on server: MCPServer) {
    let prompt = task.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !prompt.isEmpty else { return }

    agentTask?.cancel()
    agentState = .running
    agentTask = Task { [weak self] in
      do {
        let output = try await ConduitAgent.run(task: prompt, on: server)
        guard !Task.isCancelled else { return }
        self?.agentState = .success(output)
      } catch is CancellationError {
        self?.agentState = .idle
      } catch {
        self?.agentState = .failure(error.localizedDescription)
      }
    }
  }

  func cancel() {
    agentTask?.cancel()
    ideasTask?.cancel()
  }

  private func generateIdeas(for server: MCPServer) async {
    guard ConduitAgent.unavailableMessage == nil, !tools.isEmpty else {
      ideasState = .unavailable
      return
    }

    ideasState = .loading
    do {
      let ideas = try await ConduitAgent.suggestShortcuts(for: server, tools: tools)
      guard !Task.isCancelled else { return }
      ideasState = .loaded(ideas)
    } catch is CancellationError {
      ideasState = .idle
    } catch {
      ideasState = .failed(error.localizedDescription)
    }
  }
}
