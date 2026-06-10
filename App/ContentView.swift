import SwiftUI

struct ContentView: View {
  @Environment(MCPServerStore.self) private var store
  @State private var isAddingServer = false
  @State private var layout: ServerLayout = .grid

  private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

  var body: some View {
    NavigationStack {
      ScrollView {
        if store.servers.isEmpty {
          emptyState
        } else if layout == .grid {
          LazyVGrid(columns: columns, spacing: 16) {
            ForEach(store.servers) { server in
              NavigationLink(value: server) {
                ServerCard(server: server)
              }
              .buttonStyle(.plain)
            }
          }
          .padding()
        } else {
          LazyVStack(spacing: 12) {
            ForEach(store.servers) { server in
              NavigationLink(value: server) {
                ServerRow(server: server)
              }
              .buttonStyle(.plain)
            }
          }
          .padding()
        }
      }
      .navigationTitle("Conduit")
      .navigationDestination(for: MCPServer.self) { server in
        ServerDetailView(server: server)
      }
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          if !store.servers.isEmpty {
            Picker("Layout", selection: $layout) {
              Label("Grid", systemImage: "square.grid.2x2").tag(ServerLayout.grid)
              Label("List", systemImage: "list.bullet").tag(ServerLayout.list)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
          }
          Button("Add Server", systemImage: "plus") {
            isAddingServer = true
          }
        }
      }
      .sheet(isPresented: $isAddingServer) {
        AddServerView()
      }
    }
  }

  private var emptyState: some View {
    ContentUnavailableView {
      Label("No Servers Yet", systemImage: "point.3.connected.trianglepath.dotted")
    } description: {
      Text("Connect a remote MCP server so Siri and Apple Intelligence can use it for agentic tasks.")
    } actions: {
      Button("Add a Server", systemImage: "plus") {
        isAddingServer = true
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(.top, 80)
  }
}

enum ServerLayout: String {
  case grid
  case list
}
