import WidgetKit
import SwiftUI

/// A lightweight, render-ready snapshot of one server for the widget grid. Widgets
/// render without live networking, so tiles use the tinted symbol plus the last
/// recorded health color rather than fetching remote logos.
struct ServerGlance: Identifiable {
  let id: UUID
  let name: String
  let symbol: String
  let tint: String
  let health: ServerHealth

  init(server: MCPServer, health: ServerHealth) {
    self.id = server.id
    self.name = server.name
    self.symbol = server.symbol
    self.tint = server.tint
    self.health = health
  }

  init(id: UUID = UUID(), name: String, symbol: String, tint: String, health: ServerHealth) {
    self.id = id
    self.name = name
    self.symbol = symbol
    self.tint = tint
    self.health = health
  }
}

struct ServerSnapshot: TimelineEntry {
  let date: Date
  let servers: [ServerGlance]

  var connected: Int { servers.filter { $0.health == .connected }.count }
  var hasIssues: Bool { servers.contains { $0.health == .error } }

  static let sample = ServerSnapshot(date: .now, servers: [
    ServerGlance(name: "GitHub", symbol: "chevron.left.forwardslash.chevron.right", tint: "purple", health: .connected),
    ServerGlance(name: "Linear", symbol: "checklist", tint: "indigo", health: .connected),
    ServerGlance(name: "Notion", symbol: "doc.richtext", tint: "gray", health: .needsAuth),
    ServerGlance(name: "Sentry", symbol: "ladybug", tint: "orange", health: .error)
  ])
}

struct ConduitProvider: TimelineProvider {
  func placeholder(in context: Context) -> ServerSnapshot { .sample }

  func getSnapshot(in context: Context, completion: @escaping (ServerSnapshot) -> Void) {
    completion(context.isPreview ? .sample : current())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ServerSnapshot>) -> Void) {
    // The app re-checks health and reloads timelines, so we don't poll on our own.
    completion(Timeline(entries: [current()], policy: .never))
  }

  private func current() -> ServerSnapshot {
    let health = ServerHealthStore.load()
    let servers = MCPServerStorage.load().map {
      ServerGlance(server: $0, health: health[$0.id]?.health ?? .unknown)
    }
    return ServerSnapshot(date: .now, servers: servers)
  }
}

struct ConduitWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "ConduitWidget", provider: ConduitProvider()) { entry in
      ConduitWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Servers")
    .description("Your MCP servers and their connection status at a glance.")
    .supportedFamilies([
      .systemSmall, .systemMedium, .systemLarge,
      .accessoryRectangular, .accessoryCircular, .accessoryInline
    ])
  }
}

struct ConduitWidgetView: View {
  @Environment(\.widgetFamily) private var family
  var entry: ServerSnapshot

  var body: some View {
    switch family {
    case .accessoryInline:
      Label(inlineSummary, systemImage: "point.3.connected.trianglepath.dotted")
    case .accessoryCircular:
      circular
    case .accessoryRectangular:
      rectangular
    default:
      systemWidget
    }
  }

  // MARK: - System widgets (grid)

  private var systemWidget: some View {
    VStack(alignment: .leading, spacing: 10) {
      header
      if entry.servers.isEmpty {
        emptyState
      } else {
        ServerGrid(servers: entry.servers, family: family)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var header: some View {
    HStack(spacing: 6) {
      Image(systemName: "point.3.connected.trianglepath.dotted")
        .foregroundStyle(.teal)
      Text("Conduit")
        .font(.caption.weight(.semibold))
      Spacer()
      if !entry.servers.isEmpty {
        Text("\(entry.connected)/\(entry.servers.count)")
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
          .accessibilityLabel("\(entry.connected) of \(entry.servers.count) connected")
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 4) {
      Spacer()
      Text("No servers yet")
        .font(.headline)
      Text("Tap to connect one")
        .font(.caption2)
        .foregroundStyle(.secondary)
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Accessory widgets

  private var inlineSummary: String {
    entry.servers.isEmpty ? "No servers" : "\(entry.connected)/\(entry.servers.count) connected"
  }

  private var circular: some View {
    Gauge(value: Double(entry.connected), in: 0...Double(max(entry.servers.count, 1))) {
      Image(systemName: "point.3.connected.trianglepath.dotted")
    } currentValueLabel: {
      Text("\(entry.connected)")
    }
    .gaugeStyle(.accessoryCircular)
  }

  private var rectangular: some View {
    VStack(alignment: .leading, spacing: 2) {
      Label("Conduit", systemImage: "point.3.connected.trianglepath.dotted")
        .font(.caption.weight(.semibold))
      if entry.servers.isEmpty {
        Text("No servers connected")
          .font(.caption2)
      } else {
        Text("\(entry.connected) of \(entry.servers.count) connected")
          .font(.caption2)
        Text(entry.servers.prefix(3).map(\.name).joined(separator: ", "))
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// Fixed-height grid of server tiles, sized per widget family so rows always align.
private struct ServerGrid: View {
  let servers: [ServerGlance]
  let family: WidgetFamily

  private var columnCount: Int {
    switch family {
    case .systemSmall: 3
    case .systemLarge: 4
    default: 5
    }
  }

  private var maxItems: Int {
    switch family {
    case .systemSmall: 6
    case .systemMedium: 5
    case .systemLarge: 16
    default: 6
    }
  }

  private var tileSize: CGFloat {
    switch family {
    case .systemSmall: 40
    case .systemLarge: 52
    default: 44
    }
  }

  private var showsLabels: Bool { family == .systemLarge }

  private var visible: [ServerGlance] { Array(servers.prefix(maxItems)) }
  private var overflow: Int { max(0, servers.count - visible.count) }

  private var columns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: columnCount)
  }

  var body: some View {
    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
      ForEach(visible) { server in
        cell(for: server)
      }
      if overflow > 0 {
        overflowTile
      }
    }
  }

  private func cell(for server: ServerGlance) -> some View {
    VStack(spacing: 4) {
      WidgetServerTile(glance: server, size: tileSize)
      if showsLabels {
        Text(server.name)
          .font(.caption2)
          .lineLimit(1)
          .frame(maxWidth: .infinity)
      }
    }
    .frame(height: showsLabels ? tileSize + 18 : tileSize)
  }

  private var overflowTile: some View {
    VStack(spacing: 4) {
      RoundedRectangle(cornerRadius: tileSize * 0.27)
        .fill(.quaternary)
        .frame(width: tileSize, height: tileSize)
        .overlay(
          Text("+\(overflow)")
            .font(.system(size: tileSize * 0.32, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
        )
      if showsLabels {
        Text("more").font(.caption2).foregroundStyle(.secondary)
      }
    }
    .frame(height: showsLabels ? tileSize + 18 : tileSize)
  }
}

/// A single server tile: tinted symbol with a health-colored status dot.
private struct WidgetServerTile: View {
  let glance: ServerGlance
  var size: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: size * 0.27)
      .fill(ServerTint.color(glance.tint).gradient)
      .frame(width: size, height: size)
      .overlay(
        Image(systemName: glance.symbol)
          .font(.system(size: size * 0.42))
          .foregroundStyle(.white)
      )
      .overlay(alignment: .topTrailing) {
        Circle()
          .fill(glance.health.color)
          .frame(width: size * 0.28, height: size * 0.28)
          .overlay(Circle().strokeBorder(.background, lineWidth: size * 0.05))
          .offset(x: size * 0.08, y: -size * 0.08)
      }
      .accessibilityLabel("\(glance.name), \(glance.health.label)")
  }
}
