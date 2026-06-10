import SwiftUI

/// Grid tile representing a configured server.
struct ServerCard: View {
  let server: MCPServer

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        ServerLogo(logoURLString: server.logoURLString, symbol: server.symbol, tint: server.tint, size: 44, cornerRadius: 12)
        Spacer()
        AuthBadge(server: server)
      }
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

  var body: some View {
    HStack(spacing: 14) {
      ServerLogo(logoURLString: server.logoURLString, symbol: server.symbol, tint: server.tint, size: 40, cornerRadius: 10)
      VStack(alignment: .leading, spacing: 2) {
        Text(server.name)
          .font(.headline)
        Text(server.host)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Spacer()
      AuthBadge(server: server)
      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
    }
    .padding(14)
    .background(.background.secondary, in: .rect(cornerRadius: 14))
  }
}

/// Small pill indicating whether the server is ready to use.
struct AuthBadge: View {
  let server: MCPServer

  var body: some View {
    Label(server.isAuthenticated ? "Connected" : "Sign in", systemImage: server.isAuthenticated ? "checkmark.circle.fill" : "lock.fill")
      .labelStyle(.iconOnly)
      .font(.subheadline)
      .foregroundStyle(server.isAuthenticated ? AnyShapeStyle(.green) : AnyShapeStyle(.orange))
      .accessibilityLabel(server.isAuthenticated ? "Connected" : "Needs sign in")
  }
}
