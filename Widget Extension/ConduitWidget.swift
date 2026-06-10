import WidgetKit
import SwiftUI

struct ServerSnapshot: TimelineEntry {
  let date: Date
  let total: Int
  let connected: Int
  let names: [String]
}

struct ConduitProvider: TimelineProvider {
  func placeholder(in context: Context) -> ServerSnapshot {
    ServerSnapshot(date: .now, total: 3, connected: 2, names: ["GitHub", "Linear", "Notion"])
  }

  func getSnapshot(in context: Context, completion: @escaping (ServerSnapshot) -> Void) {
    completion(snapshot())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ServerSnapshot>) -> Void) {
    completion(Timeline(entries: [snapshot()], policy: .never))
  }

  private func snapshot() -> ServerSnapshot {
    let servers = MCPServerStorage.load()
    return ServerSnapshot(
      date: .now,
      total: servers.count,
      connected: servers.filter(\.isAuthenticated).count,
      names: servers.map(\.name)
    )
  }
}

struct ConduitWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "ConduitWidget", provider: ConduitProvider()) { entry in
      ConduitWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Connected Servers")
    .description("See how many MCP servers are connected and ready for Apple Intelligence.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct ConduitWidgetView: View {
  var entry: ServerSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "point.3.connected.trianglepath.dotted")
          .foregroundStyle(.teal)
        Text("Conduit")
          .font(.caption.weight(.semibold))
        Spacer()
      }

      if entry.total == 0 {
        Spacer()
        Text("No servers")
          .font(.headline)
        Text("Tap to connect one")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Spacer()
      } else {
        Spacer()
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("\(entry.connected)")
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(.teal)
          Text("/ \(entry.total)")
            .font(.headline)
            .foregroundStyle(.secondary)
        }
        Text("connected")
          .font(.caption)
          .foregroundStyle(.secondary)
        if !entry.names.isEmpty {
          Text(entry.names.prefix(3).joined(separator: " · "))
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
        }
        Spacer()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
