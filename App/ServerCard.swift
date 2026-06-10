import SwiftUI

/// Uniform tile height so every card in the grid lines up.
let serverCardHeight: CGFloat = 132

/// Grid tile representing a configured server.
struct ServerCard: View {
  let server: MCPServer
  var health: ServerHealth = .unknown

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top) {
        ServerLogo(logoURLString: server.logoURLString, host: server.host, symbol: server.symbol, tint: server.tint, size: 44, cornerRadius: 12)
        Spacer()
        StatusDot(health: health)
      }
      Spacer(minLength: 0)
      VStack(alignment: .leading, spacing: 2) {
        Text(server.name)
          .font(.headline)
          .lineLimit(1)
        Text(server.host)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(height: serverCardHeight)
    .padding(16)
    .background(.background.secondary, in: .rect(cornerRadius: 18))
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .strokeBorder(.separator.opacity(0.5))
    )
  }
}

/// List row representing a configured server.
struct ServerRow: View {
  let server: MCPServer
  var health: ServerHealth = .unknown

  var body: some View {
    HStack(spacing: 14) {
      ServerLogo(logoURLString: server.logoURLString, host: server.host, symbol: server.symbol, tint: server.tint, size: 40, cornerRadius: 10)
      VStack(alignment: .leading, spacing: 2) {
        Text(server.name)
          .font(.headline)
        Text(server.host)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Spacer()
      StatusDot(health: health)
      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
    }
    .padding(14)
    .frame(height: 68)
    .background(.background.secondary, in: .rect(cornerRadius: 14))
  }
}

/// Colored dot reflecting a server's connection health.
struct StatusDot: View {
  let health: ServerHealth
  var diameter: CGFloat = 12

  var body: some View {
    Circle()
      .fill(health.color.gradient)
      .frame(width: diameter, height: diameter)
      .overlay(Circle().strokeBorder(.background, lineWidth: diameter * 0.18))
      .accessibilityLabel(health.label)
  }
}
