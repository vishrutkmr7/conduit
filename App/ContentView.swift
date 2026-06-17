import SwiftUI

//
//  ContentView.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

struct ContentView: View {
  @Environment(MCPServerStore.self) private var store
  @State private var isAddingServer = false
  @State private var selectedServerID: MCPServer.ID?

  private var selectedServer: MCPServer? {
    guard let selectedServerID else { return store.servers.first }
    return store.servers.first { $0.id == selectedServerID }
  }

  var body: some View {
    NavigationSplitView {
      List(selection: $selectedServerID) {
        if store.servers.isEmpty {
          ContentUnavailableView {
            Label("No Servers", systemImage: "point.3.connected.trianglepath.dotted")
          } description: {
            Text("Add an MCP server to expose its tools to Conduit, Siri, Shortcuts, widgets, and Spotlight.")
          } actions: {
            Button("Add Server", systemImage: "plus", action: showAddServer)
          }
        } else {
          Section("Servers") {
            ForEach(store.servers) { server in
              NavigationLink(value: server.id) {
                ServerListRow(server: server, health: store.health(for: server), toolCount: store.toolCount(for: server))
              }
            }
          }
        }
      }
      .navigationTitle("Conduit")
      .refreshable { await store.refreshHealth() }
      .task(id: store.servers) { await store.refreshHealth() }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Add Server", systemImage: "plus", action: showAddServer)
        }
      }
    } detail: {
      if let selectedServer {
        ServerDetailView(server: selectedServer)
      } else {
        ContentUnavailableView("Select a Server", systemImage: "server.rack", description: Text("Choose a server to inspect its tools and run tasks."))
      }
    }
    .sheet(isPresented: $isAddingServer) {
      AddServerView()
    }
  }

  private func showAddServer() {
    isAddingServer = true
  }
}
