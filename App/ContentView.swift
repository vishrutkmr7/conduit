import SwiftUI

struct ContentView: View {
  @Environment(MCPServerStore.self) private var store
  @State private var isAddingServer = false
  @State private var quickAddServer: KnownServer?
  @State private var layout: ServerLayout = .grid

  private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16, alignment: .top)]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          FeaturedServersStrip { quickAddServer = $0 }
            .padding(.top, 8)

          if store.servers.isEmpty {
            emptyState
          } else if layout == .grid {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
              ForEach(store.servers) { server in
                NavigationLink(value: server) {
                  ServerCard(server: server, health: store.health(for: server), toolCount: store.toolCount(for: server))
                }
                .buttonStyle(.plain)
              }
            }
            .padding(.horizontal)
          } else {
            LazyVStack(spacing: 12) {
              ForEach(store.servers) { server in
                NavigationLink(value: server) {
                  ServerRow(server: server, health: store.health(for: server), toolCount: store.toolCount(for: server))
                }
                .buttonStyle(.plain)
              }
            }
            .padding(.horizontal)
          }
        }
        .padding(.bottom)
      }
      .navigationTitle("Conduit")
      .refreshable { await store.refreshHealth() }
      .task(id: store.servers) { await store.refreshHealth() }
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
          .tint(.accentColor)
        }
      }
      .sheet(isPresented: $isAddingServer) {
        AddServerView()
      }
      .sheet(item: $quickAddServer) { known in
        NavigationStack {
          ServerSetupView(known: known) { quickAddServer = nil }
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") { quickAddServer = nil }
                  .labelStyle(.iconOnly)
                  .tint(.accentColor)
              }
            }
        }
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
      .buttonStyle(.glassProminent)
      .controlSize(.large)
      .tint(.teal)
    }
    .padding(.top, 48)
  }
}

enum ServerLayout: String {
  case grid
  case list
}
